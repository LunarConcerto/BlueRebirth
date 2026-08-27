using System.Text.Json;
using System.Text.Json.Nodes;
using BlueOath.Core;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

internal sealed record EquipmentModDefinition(
    int Id,
    int SourceTemplateId,
    JsonObject Overrides,
    string ModId);

internal sealed record EquipmentModCatalog(
    IReadOnlyList<EquipmentModDefinition> Equipment,
    IReadOnlyList<GmGoodConfig> Goods)
{
    public static EquipmentModCatalog Empty { get; } = new([], []);
}

/// <summary>
/// Loads server-side equipment definitions from enabled Mods. The matching Lua
/// entry injects the same template into the client configManager; this catalog
/// makes the server authoritative paths (shop, enhance, rise-star, dismantle)
/// recognize that template as well.
/// </summary>
internal static class EquipmentModLoader
{
    private sealed record Manifest(
        string Id,
        string[]? TargetClients,
        bool Enabled = true);

    private sealed record EquipmentFile(
        IReadOnlyList<EquipmentEntry>? Equipment,
        IReadOnlyList<GmGoodConfig>? Goods);

    private sealed record EquipmentEntry(
        int Id,
        int SourceTemplateId,
        JsonObject? Overrides);

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        PropertyNameCaseInsensitive = true,
    };

    internal static string ResolveModsRoot(string clientPath)
    {
        if (string.IsNullOrWhiteSpace(clientPath))
            return Path.Combine(AppContext.BaseDirectory, "Mods");
        string fullClientPath = Path.GetFullPath(clientPath);
        return Path.Combine(Directory.GetParent(fullClientPath)?.FullName ?? fullClientPath, "Mods");
    }

    internal static EquipmentModCatalog Load(string modsRoot, string clientId)
    {
        if (!Directory.Exists(modsRoot)) return EquipmentModCatalog.Empty;

        var equipment = new List<EquipmentModDefinition>();
        var goods = new List<GmGoodConfig>();
        var equipmentIds = new HashSet<int>();
        var goodIds = new HashSet<int>();

        foreach (string path in Directory.EnumerateFiles(
                     modsRoot, "equipment.json", SearchOption.AllDirectories).OrderBy(x => x))
        {
            string directory = Path.GetDirectoryName(path)!;
            string manifestPath = Path.Combine(directory, "mod.json");
            try
            {
                if (!File.Exists(manifestPath))
                    throw new InvalidDataException("mod.json is missing");
                Manifest manifest = JsonSerializer.Deserialize<Manifest>(
                    File.ReadAllText(manifestPath), JsonOptions)
                    ?? throw new InvalidDataException("mod.json is empty");
                if (!manifest.Enabled || manifest.TargetClients is { Length: > 0 } targets &&
                    !targets.Contains(clientId, StringComparer.OrdinalIgnoreCase))
                    continue;

                EquipmentFile file = JsonSerializer.Deserialize<EquipmentFile>(
                    File.ReadAllText(path), JsonOptions)
                    ?? throw new InvalidDataException("equipment.json is empty");
                var localEquipment = (file.Equipment ?? [])
                    .Select(entry => new EquipmentModDefinition(
                        entry.Id,
                        entry.SourceTemplateId,
                        entry.Overrides ?? new JsonObject(),
                        manifest.Id))
                    .ToList();
                var localGoods = (file.Goods ?? []).ToList();

                if (localEquipment.Any(x => x.Id <= 0 || x.SourceTemplateId <= 0))
                    throw new InvalidDataException("equipment ids must be positive");
                if (localEquipment.Select(x => x.Id).Distinct().Count() != localEquipment.Count)
                    throw new InvalidDataException("equipment.json contains duplicate equipment ids");
                if (localGoods.Any(x => x.GoodId <= 0 || x.ShopId <= 0 ||
                                        x.Type != GameServices.GoodsTypeEquip || x.Num <= 0))
                    throw new InvalidDataException("equipment shop goods are invalid");
                if (localGoods.Select(x => x.GoodId).Distinct().Count() != localGoods.Count)
                    throw new InvalidDataException("equipment.json contains duplicate good ids");
                if (localGoods.Any(x => localEquipment.All(e => e.Id != x.ItemId)))
                    throw new InvalidDataException("equipment shop good references an unknown mod equipment id");
                if (localEquipment.Any(x => equipmentIds.Contains(x.Id)) ||
                    localGoods.Any(x => goodIds.Contains(x.GoodId)))
                    throw new InvalidDataException("equipment or shop good id conflicts with another mod");

                equipment.AddRange(localEquipment);
                goods.AddRange(localGoods);
                equipmentIds.UnionWith(localEquipment.Select(x => x.Id));
                goodIds.UnionWith(localGoods.Select(x => x.GoodId));
                Console.Error.WriteLine(
                    $"[equipment-mod] loaded {localEquipment.Count} equipment / {localGoods.Count} goods from {manifest.Id}");
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"[equipment-mod] ignored {path}: {ex.Message}");
            }
        }

        return new EquipmentModCatalog(equipment, goods);
    }

    internal static ConfigEquip BuildConfig(ConfigEquip source, EquipmentModDefinition definition)
    {
        JsonObject root = JsonSerializer.SerializeToNode(source, JsonOptions)?.AsObject()
            ?? throw new InvalidDataException("source equipment cannot be serialized");
        foreach ((string key, JsonNode? value) in definition.Overrides)
            root[key] = value?.DeepClone();
        root["e_id"] = definition.Id;
        return root.Deserialize<ConfigEquip>(JsonOptions)
            ?? throw new InvalidDataException("mod equipment cannot be deserialized");
    }

    internal static GmGoodsConfig MergeGoods(
        GmGoodsConfig current,
        EquipmentModCatalog catalog,
        Action<string>? log = null)
    {
        var result = current.Goods.ToList();
        var usedIds = result.Select(x => x.GoodId).ToHashSet();
        foreach (GmGoodConfig good in catalog.Goods)
        {
            if (!usedIds.Add(good.GoodId))
            {
                log?.Invoke($"equipment mod good {good.GoodId} conflicts with the base catalog and was skipped");
                continue;
            }
            result.Add(good);
        }
        return current with { Goods = result };
    }
}
