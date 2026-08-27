using System.Text;
using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;
using BlueOath.Storage;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

internal static class EmbeddedResourceHelper
{
    public static string? TryLoadEmbedded(string resourceName)
    {
        try
        {
            var assembly = System.Reflection.Assembly.GetExecutingAssembly();
            using var stream = assembly.GetManifestResourceStream(resourceName);
            if (stream is null) return null;
            using var reader = new StreamReader(stream);
            return reader.ReadToEnd();
        }
        catch
        {
            return null;
        }
    }
}

internal static class GmGoodsConfigLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static GmGoodsConfig Load(string dataRoot)
    {
        var json = EmbeddedResourceHelper.TryLoadEmbedded("BlueOath.Server.gm-goods.json");
        if (json is null)
        {
            var path = Path.Combine(dataRoot, "gm-goods.json");
            if (!File.Exists(path))
                return new GmGoodsConfig([], new Dictionary<int, int>());
            try { json = File.ReadAllText(path); }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"[gm-goods] failed to read {path}: {ex.Message}");
                return new GmGoodsConfig([], new Dictionary<int, int>());
            }
        }
        try
        {
            return JsonSerializer.Deserialize<GmGoodsConfig>(json, JsonOptions)
                ?? new GmGoodsConfig([], new Dictionary<int, int>());
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[gm-goods] failed to parse: {ex.Message}");
            return new GmGoodsConfig([], new Dictionary<int, int>());
        }
    }
}

internal static class GmMailsConfigLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static GmMailsConfig Load(string dataRoot)
    {
        var json = EmbeddedResourceHelper.TryLoadEmbedded("BlueOath.Server.gm-mails.json");
        if (json is null)
        {
            var path = Path.Combine(dataRoot, "gm-mails.json");
            if (!File.Exists(path))
                return new GmMailsConfig([]);
            try { json = File.ReadAllText(path); }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"[gm-mails] failed to read {path}: {ex.Message}");
                return new GmMailsConfig([]);
            }
        }
        try
        {
            return JsonSerializer.Deserialize<GmMailsConfig>(json, JsonOptions)
                ?? new GmMailsConfig([]);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[gm-mails] failed to parse: {ex.Message}");
            return new GmMailsConfig([]);
        }
    }
}

/// <summary>
/// 从游戏客户端 .db 配置加载抽卡系统所需的全部配置表。
/// 替代原来的手写 build-pools.json，直接使用 config_extract_ship →
/// config_drop_item → config_specialdraw 的标准流程。
/// 单个表加载失败不会中断整体流程，缺失的表返回空字典。
/// </summary>
internal static class BuildShipExtractLoader
{
    public static (
        Dictionary<int, ConfigExtractShip> ExtractShips,
        Dictionary<int, ConfigDropItem> DropItems,
        Dictionary<int, ConfigSpecialdraw> SpecialDraws,
        Dictionary<int, ConfigShipInfo> ShipInfos
    ) Load(string configDir)
    {
        var extractShips = SafeLoad<ConfigExtractShip>(configDir, "config_extract_ship.db");
        var dropItems = SafeLoad<ConfigDropItem>(configDir, "config_drop_item.db");
        var specialDraws = SafeLoad<ConfigSpecialdraw>(configDir, "config_specialdraw.db");
        var shipInfos = SafeLoad<ConfigShipInfo>(configDir, "config_ship_info.db");
        Console.Error.WriteLine($"[buildship] loaded {extractShips.Count} extract ships, {dropItems.Count} drop items, {specialDraws.Count} special draws, {shipInfos.Count} ship infos");
        return (extractShips, dropItems, specialDraws, shipInfos);
    }

    private static Dictionary<int, T> SafeLoad<T>(string configDir, string dbFile) where T : class
    {
        try
        {
            return ConfigDbLoader.LoadAll<T>(configDir, dbFile);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[buildship] failed to load {dbFile}: {ex.Message}");
            return new Dictionary<int, T>();
        }
    }
}

/// <summary>传统舰船建造所需的配方、品质与舰船包配置。</summary>
internal static class ConstructionConfigLoader
{
    private static readonly Dictionary<int, ConfigBuildFormula> _formulas = new();
    private static readonly Dictionary<int, ConfigBuildQuality> _qualities = new();
    private static readonly Dictionary<int, ConfigBuildShip> _ships = new();
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigBuildFormula>(
                         configDir, "config_build_formula.db"))
                _formulas[id] = cfg;
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigBuildQuality>(
                         configDir, "config_build_quality.db"))
                _qualities[id] = cfg;
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigBuildShip>(
                         configDir, "config_build_ship.db"))
                _ships[id] = cfg;
            Console.Error.WriteLine(
                $"[Construction] loaded {_formulas.Count} formulas / {_qualities.Count} quality rows / {_ships.Count} ship packages");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[Construction] load failed: {ex.Message}");
        }
        _loaded = true;
    }

    internal static IReadOnlyDictionary<int, ConfigBuildFormula> Formulas => _formulas;
    internal static IReadOnlyDictionary<int, ConfigBuildQuality> Qualities => _qualities;
    internal static IReadOnlyDictionary<int, ConfigBuildShip> Ships => _ships;
}

/// <summary>加载可使用道具配置（宝箱 id → 掉落池 id）。</summary>
internal static class ItemInfoLoader
{
    public static Dictionary<int, ConfigItemInfo> Load(string configDir)
    {
        return ConfigDbLoader.LoadAll<ConfigItemInfo>(configDir, "config_item_info.db");
    }
}

internal static class ShipLevelupLoader
{
    public static (Dictionary<int, int> ExpPerItem, Dictionary<int, int> ExpNeeded) Load(string configDir)
    {
        var expPerItem = new Dictionary<int, int>();
        var expNeeded = new Dictionary<int, int>();
        LoadExpItems(configDir, expPerItem);
        LoadLevelupExp(configDir, expNeeded);
        return (expPerItem, expNeeded);
    }

    private static void LoadExpItems(string configDir, Dictionary<int, int> result)
    {
        try
        {
            ConfigDbLoader.LoadRows(configDir, "config_ship_exp_item.db", (id, _, json) =>
            {
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("exp", out var exp))
                    result[id] = exp.GetInt32();
            });
        }
        catch { }
    }

    private static void LoadLevelupExp(string configDir, Dictionary<int, int> result)
    {
        try
        {
            ConfigDbLoader.LoadRows(configDir, "config_ship_levelup.db", (id, _, json) =>
            {
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("exp", out var exp))
                    result[id] = exp.GetInt32();
            });
        }
        catch { }
    }
}

internal sealed record RandomFactorEntry(int SetId, int GroupId, IReadOnlyList<int> Factors);

internal static class RandomFactorLoader
{
    public static Dictionary<int, List<RandomFactorEntry>> Load(string configDir)
    {
        var result = new Dictionary<int, List<RandomFactorEntry>>();
        try
        {
            var copyDisplay = new Dictionary<int, List<int>>();
            LoadTable(configDir, "config_copy_display.db", "random_factor_sets", copyDisplay);
            var factorSets = new Dictionary<int, List<int>>();
            LoadTable(configDir, "config_random_factor_set.db", "factor_groups", factorSets);
            var factorGroups = new Dictionary<int, List<int>>();
            LoadTable(configDir, "config_random_factor_group.db", "factor", factorGroups);
            foreach (var (copyId, setIds) in copyDisplay)
            {
                var entries = new List<RandomFactorEntry>();
                foreach (var setId in setIds)
                {
                    if (!factorSets.TryGetValue(setId, out var groupIds)) continue;
                    var factors = new List<int>();
                    foreach (var groupId in groupIds)
                        if (factorGroups.TryGetValue(groupId, out var fs))
                            factors.AddRange(fs);
                    if (factors.Count == 0) continue;
                    int firstGroup = groupIds.Count > 0 ? groupIds[0] : setId;
                    entries.Add(new RandomFactorEntry(setId, firstGroup, factors));
                }
                if (entries.Count > 0) result[copyId] = entries;
            }
        }
        catch { }
        return result;
    }

    private static void LoadTable(string configDir, string dbFile, string jsonProp, Dictionary<int, List<int>> result)
    {
        ConfigDbLoader.LoadRows(configDir, dbFile, (id, _, json) =>
        {
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty(jsonProp, out var arr) || arr.ValueKind != JsonValueKind.Array) return;
            var list = new List<int>();
            foreach (var item in arr.EnumerateArray())
                if (item.TryGetInt32(out var v)) list.Add(v);
            result[id] = list;
        });
    }
}

internal static class CopyBattleLoader{
    private static readonly Dictionary<int, int> _copyFleetMap = new();
    private static readonly Dictionary<int, int> _copyConfigIdMap = new();
    private static readonly Dictionary<int, List<int>> _copyFleetListMap = new();
    private static readonly Dictionary<int, List<int>> _fleetEnemies = new();
    private static readonly Dictionary<int, bool> _fleetHasAttached = new();
    private static readonly Dictionary<int, EnemyStat> _enemyStats = new();
    private static readonly Dictionary<int, List<int>> _copyMissions = new();
    private static bool _loaded;

    public sealed record EnemyStat(int Hp, int Attack, int Defense, int Level, int ShipInfoId,
        int Hit = 100, int Dodge = 0, int TorpedoAttack = 0, int TorpedoDefense = 0);

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            LoadCopyFleet(configDir);
            LoadFleetEnemies(configDir);
            LoadEnemyStats(configDir);
            LoadCopyMissions(configDir);
        }
        catch { }
        _loaded = true;
    }

    private static void LoadCopyFleet(string configDir)
    {
        try
        {
            var candidates = new Dictionary<int, (int fleetId, bool isDefault)>();
            ConfigDbLoader.LoadRows(configDir, "config_copy.db", (id, _, json) =>
            {
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("copy_id", out var copyIdProp)) return;
                if (!doc.RootElement.TryGetProperty("fleet_id", out var fleetIdProp)) return;
                var copyId = copyIdProp.GetInt32();
                var fleetIds = new List<int>();
                foreach (var item in fleetIdProp.EnumerateArray())
                {
                    var fleetId = item.GetInt32();
                    fleetIds.Add(fleetId);
                    var isDefault = doc.RootElement.TryGetProperty("blood_range_lower", out var brl) && brl.GetInt32() == -1
                        && doc.RootElement.TryGetProperty("random_weight", out var rw) && rw.GetInt32() == 1000;
                    if (!candidates.TryGetValue(copyId, out var cur) || (isDefault && !cur.isDefault))
                        candidates[copyId] = (fleetId, isDefault);
                    if (isDefault)
                    {
                        _copyConfigIdMap[copyId] = id;
                        _copyFleetListMap[copyId] = fleetIds;
                    }
                }
            });
            foreach (var (copyId, val) in candidates)
                _copyFleetMap[copyId] = val.fleetId;
        }
        catch { }
    }

    private static void LoadFleetEnemies(string configDir)
    {
        try
        {
            ConfigDbLoader.LoadRows(configDir, "config_fleet.db", (id, _, json) =>
            {
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("copy_enemys", out var enemies)) return;
                var list = new List<int>();
                foreach (var item in enemies.EnumerateArray())
                    list.Add(item.GetInt32());
                _fleetEnemies[id] = list;
                if (doc.RootElement.TryGetProperty("copy_attacheds", out var attached)
                    && attached.ValueKind == JsonValueKind.Array)
                {
                    var cnt = 0;
                    foreach (var item in attached.EnumerateArray())
                    {
                        if (item.ValueKind == JsonValueKind.Array && item.GetArrayLength() > 0
                            && item[0].ValueKind == JsonValueKind.Number && item[0].GetInt32() != 0)
                            cnt++;
                    }
                    _fleetHasAttached[id] = cnt > 0;
                }
            });
        }
        catch { }
    }

    private static void LoadEnemyStats(string configDir)
    {
        try
        {
            ConfigDbLoader.LoadRows(configDir, "config_ship_enemy.db", (id, _, json) =>
            {
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("hp", out var hpProp)) return;
                _enemyStats[id] = new EnemyStat(
                    hpProp.GetInt32(),
                    doc.RootElement.TryGetProperty("attack", out var atk) ? atk.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("defense", out var def) ? def.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("level", out var lv) ? lv.GetInt32() : 1,
                    doc.RootElement.TryGetProperty("ship_info_id", out var sid) ? sid.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("hit", out var hit) ? hit.GetInt32() : 100,
                    doc.RootElement.TryGetProperty("dodge", out var dodge) ? dodge.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("torpedo_attack", out var ta) ? ta.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("torpedo_defense", out var td) ? td.GetInt32() : 0);
            });
        }
        catch { }
    }

    public static int GetFleetId(int copyId)
        => _copyFleetMap.TryGetValue(copyId, out var id) ? id : copyId;

    /// <summary>关卡全部敌舰队 id（config_copy.fleet_id 完整数组）。客户端
    /// BattleStartData.enemyFleetId 是 int[]，InitNpc 逐个生成敌舰队。查不到回退单值。</summary>
    public static List<int> GetFleetIdList(int copyId)
        => _copyFleetListMap.TryGetValue(copyId, out var list) && list.Count > 0
            ? list
            : new List<int> { GetFleetId(copyId) };

    public static bool HasCopyAttacheds(int fleetId)
        => _fleetHasAttached.TryGetValue(fleetId, out var has) && has;

    public static List<int> GetMissionIdList(int copyId)
        => _copyMissions.TryGetValue(copyId, out var list) && list.Count > 0
            ? list
            : [];

    private static void LoadCopyMissions(string configDir)
    {
        try
        {
            ConfigDbLoader.LoadRows(configDir, "config_copy.db", (id, _, json) =>
            {
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("copy_id", out var copyIdProp)) return;
                if (!doc.RootElement.TryGetProperty("mission_id", out var missionProp)
                    || missionProp.ValueKind != JsonValueKind.Array) return;
                var list = new List<int>();
                foreach (var item in missionProp.EnumerateArray())
                    if (item.TryGetInt32(out var v)) list.Add(v);
                if (list.Count > 0) _copyMissions[copyIdProp.GetInt32()] = list;
            });
        }
        catch { }
    }

    public static int GetFleetIdWithAttached(int copyId)
        => GetFleetId(copyId);

    public static int GetConfigId(int copyId)
        => _copyConfigIdMap.TryGetValue(copyId, out var id) ? id : copyId;

    public static List<int> GetEnemyIds(int fleetId)
        => _fleetEnemies.TryGetValue(fleetId, out var list) ? list : [];

    public static EnemyStat? GetEnemyStat(int enemyId)
        => _enemyStats.TryGetValue(enemyId, out var stat) ? stat : null;

}

internal static class MissionChainLoader
{
    private static List<int> _defaultChain = new();
    private static bool _loaded;

    public static List<int> DefaultChain()
    {
        EnsureLoaded();
        return _defaultChain;
    }

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            var next = new Dictionary<int, List<int>>();
            var hasIncoming = new HashSet<int>();
            ConfigDbLoader.LoadRows(configDir, "config_mission.db", (id, _, json) =>
            {
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("id", out var idProp)) return;
                int mid = idProp.GetInt32();
                if (!doc.RootElement.TryGetProperty("nextmission", out var nx)
                    || nx.ValueKind != JsonValueKind.Array) return;
                var list = new List<int>();
                foreach (var item in nx.EnumerateArray())
                    if (item.TryGetInt32(out var v)) { list.Add(v); hasIncoming.Add(v); }
                next[mid] = list;
            });
            var starts = next.Keys.Where(k => !hasIncoming.Contains(k)).OrderBy(k => k).ToList();
            if (starts.Count == 0)
            {
                _defaultChain = next.Keys.OrderBy(k => k).ToList();
                return;
            }

            var chain = new List<int>();
            var visited = new HashSet<int>();
            void Walk(int node)
            {
                if (visited.Add(node)) chain.Add(node);
                if (!next.TryGetValue(node, out var children) || children.Count == 0) return;
                Walk(children[0]);
            }

            Walk(starts[0]);
            _defaultChain = chain;
        }
        catch { }
        _loaded = true;
    }

    private static void EnsureLoaded()
    {
        if (!_loaded) Load("");
    }
}

internal static class ShipMainLoader
{
    private static readonly Dictionary<int, ConfigShipMain> _ships = new();
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            ConfigDbLoader.LoadAll<ConfigShipMain>(configDir, "config_ship_main.db",
                (id, cfg) =>
                {
                    _ships[id] = cfg;
                    if (cfg.SmId != 0)
                        _ships[checked((int)cfg.SmId)] = cfg;
                });
        }
        catch { }
        _loaded = true;
    }

    public static ConfigShipMain? Get(int templateId)
        => _ships.TryGetValue(templateId, out var cfg) ? cfg : null;

    public static long Leveled(long baseValue, long levelup, int level)
        => baseValue + levelup * Math.Max(0, level - 1);
}

internal static class AssistShipLoader
{
    private static readonly Dictionary<int, ConfigAssistShipInfo> _ships = new();
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            _ships.Clear();
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigAssistShipInfo>(configDir, "config_assist_ship_info.db"))
                _ships[id] = cfg;
        }
        catch { }
        _loaded = true;
    }

    public static ConfigAssistShipInfo? Get(int id)
        => _ships.TryGetValue(id, out var cfg) ? cfg : null;
}

internal static class EquipLoader
{
    private static readonly Dictionary<int, ConfigEquip> _equips = new();
    private static readonly Dictionary<int, ConfigEquipEnhanceItem> _enhanceItems = new();
    private static readonly Dictionary<int, ConfigEquipEnhanceLevel> _enhanceLevels = new();
    private static readonly Dictionary<int, ConfigEquipEnhanceLevelUr> _enhanceLevelsUr = new();
    private static readonly Dictionary<int, ConfigEquipLevelbreakItem> _levelbreakItems = new();
    private static readonly Dictionary<int, ConfigEquipEnhanceRenovate> _renovateLevels = new();
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            _equips.Clear();
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigEquip>(configDir, "config_equip.db"))
                _equips[id] = cfg;
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigEquipEnhanceItem>(configDir, "config_equip_enhance_item.db"))
                _enhanceItems[id] = cfg;
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigEquipEnhanceLevel>(configDir, "config_equip_enhance_level.db"))
                _enhanceLevels[id] = cfg;
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigEquipEnhanceLevelUr>(configDir, "config_equip_enhance_level_ur.db"))
                _enhanceLevelsUr[checked((int)cfg.EnchanceLevel)] = cfg;
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigEquipLevelbreakItem>(configDir, "config_equip_levelbreak_item.db"))
                _levelbreakItems[id] = cfg;
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigEquipEnhanceRenovate>(configDir, "config_equip_enhance_renovate.db"))
                _renovateLevels[id] = cfg;
        }
        catch { }
        _loaded = true;
    }

    public static ConfigEquip? Get(int id)
        => _equips.TryGetValue(id, out var cfg) ? cfg : null;
    public static ConfigEquipEnhanceItem? GetEnhanceItem(int id)
        => _enhanceItems.TryGetValue(id, out var cfg) ? cfg : null;
    public static ConfigEquipEnhanceLevel? GetEnhanceLevel(int level)
        => _enhanceLevels.TryGetValue(level, out var cfg) ? cfg : null;
    public static ConfigEquipEnhanceLevelUr? GetEnhanceLevelUr(int level)
        => _enhanceLevelsUr.TryGetValue(level, out var cfg) ? cfg : null;
    public static ConfigEquipLevelbreakItem? GetLevelbreakItem(int type)
        => _levelbreakItems.TryGetValue(type, out var cfg) ? cfg : null;
    public static ConfigEquipEnhanceRenovate? GetRenovateLevel(int level)
        => _renovateLevels.TryGetValue(level, out var cfg) ? cfg : null;
}

internal static class AffectionItemLoader
{
    private static readonly Dictionary<int, ConfigAffectionItem> _items = new();
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            _items.Clear();
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigAffectionItem>(configDir, "config_affection_item.db"))
                _items[id] = cfg;
        }
        catch { }
        _loaded = true;
    }

    public static ConfigAffectionItem? Get(int id)
        => _items.TryGetValue(id, out var cfg) ? cfg : null;

    public static IReadOnlyDictionary<int, ConfigAffectionItem> All => _items;
}

/// <summary>舰船改造节点与阶段配置。</summary>
internal static class RemouldConfigLoader
{
    private static readonly Dictionary<int, ConfigShipRemouldEffect> _effects = new();
    private static readonly Dictionary<int, ConfigShipRemouldTemplate> _templates = new();
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            _effects.Clear();
            _templates.Clear();
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigShipRemouldEffect>(
                         configDir, "config_ship_remould_effect.db"))
                _effects[id] = cfg;
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigShipRemouldTemplate>(
                         configDir, "config_ship_remould_template.db"))
                _templates[id] = cfg;
            Console.Error.WriteLine(
                $"[Remould] loaded {_effects.Count} effects / {_templates.Count} stages from {configDir}");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[Remould] load failed: {ex.Message}");
        }
        _loaded = true;
    }

    public static ConfigShipRemouldEffect? GetEffect(int id)
        => _effects.TryGetValue(id, out var cfg) ? cfg : null;

    public static ConfigShipRemouldTemplate? GetTemplate(int id)
        => _templates.TryGetValue(id, out var cfg) ? cfg : null;

    public static IReadOnlyDictionary<int, ConfigShipRemouldEffect> AllEffects => _effects;
}

internal static class ChapterCopyLoader
{
    private static readonly Dictionary<int, List<int>> _chapterCopies = new();
    private static readonly Dictionary<int, int> _firstCopyMap = new();
    private static readonly List<ChapterMemory> _allChapterMemories = [];
    private static readonly Dictionary<int, List<int>> _seaChapterCopies = new();
    private static int _seaFirstChapterId = 0;
    private static readonly Dictionary<int, int> _copyTypeMap = new();
    private static int _seaFirstCopyId = 0;
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            ConfigDbLoader.LoadRows(configDir, "config_chapter.db", (id, _, json) =>
            {
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("level_list", out var levelList)) return;
                if (!doc.RootElement.TryGetProperty("class_type", out var classType)) return;
                var copies = new List<int>();
                foreach (var item in levelList.EnumerateArray())
                    copies.Add(item.GetInt32());
                if (copies.Count == 0) return;
                var ct = classType.GetInt32();
                var plotType = doc.RootElement.TryGetProperty("chapter_plot_type", out var chapterPlotType)
                    ? chapterPlotType.GetInt32()
                    : 0;
                var memoryId = doc.RootElement.TryGetProperty("memory_id", out var memory)
                    ? memory.GetInt32()
                    : 0;
                if (memoryId > 0)
                    _allChapterMemories.Add(new ChapterMemory(id, copies.Count));
                // 番外/日常剧情由 chapter_plot_type 标记；限时活动剧情由 memory_id
                // 收录进图鉴回顾。两者都可能使用 11/27/35/37 等非 1 class_type。
                if (plotType > 0 || memoryId > 0)
                {
                    _chapterCopies[id] = copies;
                    _firstCopyMap[id] = copies[0];
                    foreach (var cid in copies) _copyTypeMap[cid] = 1;
                }
                else if (ct == 2)
                {
                    _seaChapterCopies[id] = copies;
                    foreach (var cid in copies) _copyTypeMap[cid] = 2;
                    if (_seaFirstChapterId == 0 || id < _seaFirstChapterId)
                    {
                        _seaFirstChapterId = id;
                        _seaFirstCopyId = copies[0];
                    }
                }
            });
            _allChapterMemories.Sort(static (left, right) => left.ChapterId.CompareTo(right.ChapterId));
            Console.Error.WriteLine(
                $"[ChapterCopy] loaded {_chapterCopies.Count} story chapters, " +
                $"{_allChapterMemories.Count} archived activity chapters and {_seaChapterCopies.Count} sea chapters");
        }
        catch { }
        _loaded = true;
    }

    public static List<int> GetCopyIds(int chapterId)
        => _chapterCopies.TryGetValue(chapterId, out var list) ? list : [];

    public static int GetFirstCopyId(int chapterId)
        => _firstCopyMap.TryGetValue(chapterId, out var id) ? id : 0;

    public static List<int> GetAllChapterIds()
        => [.. _chapterCopies.Keys.OrderBy(x => x)];

    public static IReadOnlyList<ChapterMemory> AllChapterMemories
        => _allChapterMemories;

    public static List<int> GetSeaLevels()
    {
        var result = new List<int>();
        foreach (var chapterId in _seaChapterCopies.Keys.OrderBy(x => x))
            result.AddRange(_seaChapterCopies[chapterId]);
        return result;
    }

    public static int GetSeaFirstCopyId() => _seaFirstCopyId;

    public static int GetSeaLastCopyId()
    {
        var levels = GetSeaLevels();
        return levels.Count > 0 ? levels[^1] : _seaFirstCopyId;
    }

    public static int GetCopyType(int copyId)
        => _copyTypeMap.TryGetValue(copyId, out var ct) ? ct : 0;
}

/// <summary>从个人剧情配置生成图鉴协议所需的完整 THeroMemory 列表。</summary>
internal static class CharacterStoryLoader
{
    private static readonly List<HeroMemory> _allMemories = [];
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            _allMemories.Clear();
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigBuildingCharacterStory>(
                         configDir, "config_building_character_story.db"))
            {
                if (cfg.ShipFleetId <= 0 || id <= 0) continue;
                // 客户端以 ship_fleet_id 分组，再用配置行 id 读取剧情封面和标题。
                _allMemories.Add(new HeroMemory(checked((uint)cfg.ShipFleetId), id));
            }
            _allMemories.Sort(static (left, right) =>
            {
                var heroOrder = left.HeroId.CompareTo(right.HeroId);
                return heroOrder != 0 ? heroOrder : left.PlotId.CompareTo(right.PlotId);
            });
            Console.Error.WriteLine($"[CharacterStory] loaded {_allMemories.Count} personal stories from {configDir}");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[CharacterStory] load failed: {ex.Message}");
        }
        _loaded = true;
    }

    public static IReadOnlyList<HeroMemory> AllMemories => _allMemories;
}

internal static class ShipHandbookLoader
{
    private static readonly Dictionary<int, ConfigShipHandbook> _handbooks = new();
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            _handbooks.Clear();
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigShipHandbook>(configDir, "config_ship_handbook.db"))
                _handbooks[id] = cfg;
        }
        catch { }
        _loaded = true;
    }

    public static ConfigShipHandbook? Get(int shipInfoId)
        => _handbooks.TryGetValue(shipInfoId, out var cfg) ? cfg : null;

    public static string GetShipName(int templateId)
    {
        int shipInfoId = (templateId - 1) / 10;
        return _handbooks.TryGetValue(shipInfoId, out var cfg) ? cfg.ShipName ?? "" : "";
    }
}

/// <summary>
/// 从游戏客户端 config_fashion.db 加载全部时装，按 <c>belong_to_ship</c>（即
/// config_ship_info.sf_id）分组为 <see cref="FashionEntry"/>（SfId → FashionTid 列表）。
/// 供「创建档案即全时装解锁」与 FashionTid → SfId 映射（替代 gm-goods.json 手写白名单）。
/// </summary>
internal static class FashionConfigLoader
{
    private static readonly List<FashionEntry> _allFashion = [];
    private static readonly Dictionary<int, int> _fashionSfIdMap = new();
    private static bool _loaded;

    /// <summary>已按 SfId 分组的全部时装条目（登录/login-push 用）。</summary>
    public static IReadOnlyList<FashionEntry> AllFashion => _allFashion;

    /// <summary>FashionTid → SfId（belong_to_ship）全量映射。</summary>
    public static IReadOnlyDictionary<int, int> FashionSfIdMap => _fashionSfIdMap;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            var entries = new Dictionary<int, List<int>>();
            ConfigDbLoader.LoadAll<ConfigFashion>(configDir, "config_fashion.db",
                (id, cfg) =>
                {
                    var sfId = checked((int)cfg.BelongToShip);
                    if (!entries.TryGetValue(sfId, out var list))
                        entries[sfId] = list = [];
                    if (!list.Contains(id)) list.Add(id);
                    _fashionSfIdMap[id] = sfId;
                });
            foreach (var (sfId, tids) in entries.OrderBy(kv => kv.Key))
                _allFashion.Add(new FashionEntry(sfId, tids.OrderBy(x => x).ToList()));
            Console.Error.WriteLine($"[fashion] loaded {_fashionSfIdMap.Count} fashions / {_allFashion.Count} ships");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[fashion] failed to load config_fashion.db: {ex.Message}");
        }
        _loaded = true;
    }
}

internal static class PlotTriggerLoader
{
    private static List<int> _allPlotIds = [];
    private static bool _loaded;

    public static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            _allPlotIds.Clear();
            int count = 0;
            foreach (var (id, cfg) in ConfigDbLoader.LoadAll<ConfigPlotEpisodeTrigger>(configDir, "config_plot_episode_trigger.db"))
            {
                _allPlotIds.Add(checked((int)cfg.PlotTriggerId));
                count++;
            }
            Console.Error.WriteLine($"[PlotTrigger] loaded {count} plot trigger IDs from {configDir}");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[PlotTrigger] load failed: {ex.Message}");
        }
        _loaded = true;
    }

    public static IReadOnlyList<int> AllPlotIds => _allPlotIds;
}

/// <summary>基地建造所需的建筑、地块、等级与工人体力配置。</summary>
internal static class BuildingConfigLoader
{
    private static Dictionary<int, ConfigBuildinginfo> _infos = [];
    private static Dictionary<int, ConfigBuilding> _lands = [];
    private static Dictionary<int, ConfigBuildinglevelup> _levelUps = [];
    private static ConfigWorker? _worker;
    private static bool _loaded;

    internal static IReadOnlyDictionary<int, ConfigBuildinginfo> Infos => _infos;
    internal static IReadOnlyDictionary<int, ConfigBuilding> Lands => _lands;
    internal static IReadOnlyList<int> MaterialTemplateIds { get; private set; } = [];

    internal static void Load(string configDir)
    {
        if (_loaded) return;
        try
        {
            _infos = ConfigDbLoader.LoadAll<ConfigBuildinginfo>(configDir, "config_buildinginfo.db");
            _lands = ConfigDbLoader.LoadAll<ConfigBuilding>(configDir, "config_building.db");
            _levelUps = ConfigDbLoader.LoadAll<ConfigBuildinglevelup>(configDir, "config_buildinglevelup.db");
            MaterialTemplateIds = _levelUps.Values
                .SelectMany(GetMaterialTemplateIds)
                .Distinct()
                .OrderBy(id => id)
                .ToArray();
            _worker = ConfigDbLoader.LoadAll<ConfigWorker>(configDir, "config_worker.db")
                .Values.FirstOrDefault();
            Console.Error.WriteLine(
                $"[Building] loaded {_infos.Count} buildings / {_lands.Count} lands / " +
                $"{_levelUps.Count} levels / {MaterialTemplateIds.Count} materials");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[Building] load failed: {ex.Message}");
        }
        _loaded = true;
    }

    internal static ConfigBuildinginfo? GetInfo(int tid) =>
        _infos.TryGetValue(tid, out ConfigBuildinginfo? value) ? value : null;

    internal static ConfigBuilding? GetLand(int index) =>
        _lands.TryGetValue(index, out ConfigBuilding? value) ? value : null;

    internal static ConfigBuildinglevelup? GetLevelUp(int tid) =>
        _levelUps.TryGetValue(tid, out ConfigBuildinglevelup? value) ? value : null;

    internal static ConfigBuildinginfo? GetInfo(int type, int level) =>
        _infos.Values.FirstOrDefault(info => info.Type == type && info.Level == level);

    internal static int GetMaxWorkerStrength(int officeLevel)
    {
        if (_worker is null) return 100;
        long max = _worker.Workerhpmax;
        IReadOnlyList<long> levels = _worker.Workerhplevelup ?? [];
        for (int i = 0; i < Math.Min(officeLevel, levels.Count); i++) max += levels[i];
        return checked((int)max);
    }

    private static IEnumerable<int> GetMaterialTemplateIds(ConfigBuildinglevelup level)
    {
        int raw1 = GetItemTemplateId(level.Rawmaterial1);
        int raw2 = GetItemTemplateId(level.Rawmaterial2);
        int raw3 = GetItemTemplateId(level.Rawmaterial3);
        if (raw1 > 0) yield return raw1;
        if (raw2 > 0) yield return raw2;
        if (raw3 > 0) yield return raw3;
    }

    // 建筑物资配置格式为 [资源类型, 模板 ID, 数量]，资源类型 1 表示仓库道具。
    private static int GetItemTemplateId(IReadOnlyList<long>? material) =>
        material is { Count: >= 3 } && material[0] == 1
            ? checked((int)material[1])
            : 0;

    private static int GetItemTemplateId(IReadOnlyList<object>? material)
    {
        if (material is not { Count: >= 3 }) return 0;
        static bool TryInt64(object value, out long result)
        {
            if (value is System.Text.Json.JsonElement json && json.TryGetInt64(out result)) return true;
            return long.TryParse(Convert.ToString(value), out result);
        }
        return TryInt64(material[0], out long type) && type == 1 &&
            TryInt64(material[1], out long templateId)
                ? checked((int)templateId)
                : 0;
    }
}
