using System.Text;
using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;
using BlueOath.Storage;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

/// <summary>从数据目录下的 gm-goods.json 加载 GM 商品配置（数据驱动，避免硬编码）。</summary>
internal static class GmGoodsConfigLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static GmGoodsConfig Load(string dataRoot)
    {
        var path = Path.Combine(dataRoot, "gm-goods.json");
        if (!File.Exists(path))
            return new GmGoodsConfig([], new Dictionary<int, int>());
        try
        {
            return JsonSerializer.Deserialize<GmGoodsConfig>(File.ReadAllText(path), JsonOptions)
                ?? new GmGoodsConfig([], new Dictionary<int, int>());
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[gm-goods] failed to parse {path}: {ex.Message}");
            return new GmGoodsConfig([], new Dictionary<int, int>());
        }
    }
}

/// <summary>从数据目录下的 gm-mails.json 加载 GM 邮件配置（数据驱动，避免硬编码）。</summary>
internal static class GmMailsConfigLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static GmMailsConfig Load(string dataRoot)
    {
        var path = Path.Combine(dataRoot, "gm-mails.json");
        if (!File.Exists(path))
            return new GmMailsConfig([]);
        try
        {
            return JsonSerializer.Deserialize<GmMailsConfig>(File.ReadAllText(path), JsonOptions)
                ?? new GmMailsConfig([]);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[gm-mails] failed to parse {path}: {ex.Message}");
            return new GmMailsConfig([]);
        }
    }
}

/// <summary>从数据目录下的 build-pools.json 加载抽卡池配置（数据驱动，不依赖客户端 config DB）。</summary>
internal static class GmBuildPoolLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static Dictionary<int, BuildShipPool> Load(string dataRoot)
    {
        var path = Path.Combine(dataRoot, "build-pools.json");
        if (!File.Exists(path))
            return [];
        try
        {
            var config = JsonSerializer.Deserialize<GmBuildPoolsConfig>(File.ReadAllText(path), JsonOptions);
            if (config?.Pools is null) return [];
            return config.Pools.ToDictionary(p => p.PoolId, p => new BuildShipPool(p.PoolId,
                p.Ships.Select(s => new BuildShipEntry(s.TemplateId, s.Weight)).ToList()));
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[build-pools] failed to parse {path}: {ex.Message}");
            return [];
        }
    }
}

/// <summary>build-pools.json 的顶层结构。</summary>
internal sealed record GmBuildPoolsConfig(IReadOnlyList<GmBuildPoolConfig> Pools);

/// <summary>单个卡池配置。</summary>
internal sealed record GmBuildPoolConfig(int PoolId, IReadOnlyList<GmBuildShipConfig> Ships);

/// <summary>单个卡池中的船娘条目。</summary>
internal sealed record GmBuildShipConfig(int TemplateId, int Weight);

/// <summary>从 config_ship_exp_item.db 和 config_ship_levelup.db 加载升级所需数据。</summary>
internal static class ShipLevelupLoader
{
    private const byte XorKey = 0x55;

    public static (Dictionary<int, int> ExpPerItem, Dictionary<int, int> ExpNeeded) Load(string dataRoot)
    {
        var configDir = Path.GetFullPath(Path.Combine(dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
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
            var path = Path.Combine(configDir, "config_ship_exp_item.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("exp", out var exp))
                    result[id] = exp.GetInt32();
            }
        }
        catch { }
    }

    private static void LoadLevelupExp(string configDir, Dictionary<int, int> result)
    {
        try
        {
            var path = Path.Combine(configDir, "config_ship_levelup.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("exp", out var exp))
                    result[id] = exp.GetInt32();
            }
        }
        catch { }
    }

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>加载海域索敌随机因子：config_copy_display.random_factor_sets
/// → config_random_factor_set.factor_groups → config_random_factor_group.factor。
/// 供 copy.GetRandomFactors 协议与 StartBase 的 RandomFactors 字段使用。</summary>
internal static class RandomFactorLoader
{
    private const byte XorKey = 0x55;

    public static Dictionary<int, List<int>> Load(string dataRoot)
    {
        var result = new Dictionary<int, List<int>>();
        try
        {
            var configDir = ChapterCopyLoader.FindConfigDir(dataRoot);
            var copyDisplay = new Dictionary<int, List<int>>();
            LoadTable(configDir, "config_copy_display.db", "random_factor_sets", copyDisplay);
            var factorSets = new Dictionary<int, List<int>>();
            LoadTable(configDir, "config_random_factor_set.db", "factor_groups", factorSets);
            var factorGroups = new Dictionary<int, List<int>>();
            LoadTable(configDir, "config_random_factor_group.db", "factor", factorGroups);
            foreach (var (copyId, setIds) in copyDisplay)
            {
                var factors = new List<int>();
                foreach (var setId in setIds)
                {
                    if (!factorSets.TryGetValue(setId, out var groupIds)) continue;
                    foreach (var groupId in groupIds)
                        if (factorGroups.TryGetValue(groupId, out var fs))
                            factors.AddRange(fs);
                }
                if (factors.Count > 0) result[copyId] = factors;
            }
        }
        catch { }
        return result;
    }

    private static void LoadTable(string configDir, string dbFile, string jsonProp, Dictionary<int, List<int>> result)
    {
        var path = Path.Combine(configDir, dbFile);
        if (!File.Exists(path)) return;
        using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
        c.Open();
        using var cmd = c.CreateCommand();
        cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
        using var r = cmd.ExecuteReader();
        while (r.Read())
        {
            var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
            if (id == 0) continue;
            var bytes = ReadColumnBytes(r, 1);
            var json = XorDecode(bytes);
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty(jsonProp, out var arr) || arr.ValueKind != JsonValueKind.Array) continue;
            var list = new List<int>();
            foreach (var item in arr.EnumerateArray())
                if (item.TryGetInt32(out var v)) list.Add(v);
            result[id] = list;
        }
    }

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_copy / config_fleet / config_ship_enemy 加载战斗配置。</summary>
internal static class CopyBattleLoader{
    private static readonly Dictionary<int, int> _copyFleetMap = new();       // copy_id → fleet_id
    private static readonly Dictionary<int, int> _copyConfigIdMap = new();    // copy_id → config_copy DBObject id
    private static readonly Dictionary<int, List<int>> _fleetEnemies = new(); // fleet_id → enemy ship ids
    private static readonly Dictionary<int, bool> _fleetHasAttached = new();  // fleet_id → 是否带 copy_attacheds
    private static readonly Dictionary<int, EnemyStat> _enemyStats = new();   // enemy id → stats
    private static bool _loaded;

    public sealed record EnemyStat(int Hp, int Attack, int Defense, int Level, int ShipInfoId,
        int Hit = 100, int Dodge = 0, int TorpedoAttack = 0, int TorpedoDefense = 0);

    public static void Load(string dataRoot)
    {
        if (_loaded) return;
        try
        {
            var configDir = Path.GetFullPath(Path.Combine(dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
            LoadCopyFleet(configDir);
            LoadFleetEnemies(configDir);
            LoadEnemyStats(configDir);
        }
        catch { }
        _loaded = true;
    }

    private static void LoadCopyFleet(string configDir)
    {
        try
        {
            var path = Path.Combine(configDir, "config_copy.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            var candidates = new Dictionary<int, (int fleetId, bool isDefault)>();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("copy_id", out var copyIdProp)) continue;
                if (!doc.RootElement.TryGetProperty("fleet_id", out var fleetIdProp)) continue;
                var copyId = copyIdProp.GetInt32();
                foreach (var item in fleetIdProp.EnumerateArray())
                {
                    var fleetId = item.GetInt32();
                    // 默认分支: blood_range_lower == -1 且 random_weight == 1000
                    var isDefault = doc.RootElement.TryGetProperty("blood_range_lower", out var brl) && brl.GetInt32() == -1
                        && doc.RootElement.TryGetProperty("random_weight", out var rw) && rw.GetInt32() == 1000;
                    if (!candidates.TryGetValue(copyId, out var cur) || (isDefault && !cur.isDefault))
                        candidates[copyId] = (fleetId, isDefault);
                    // 记录默认分支对应的 config_copy DBObject id（客户端用该 id 查 config_copy）
                    if (isDefault) _copyConfigIdMap[copyId] = id;
                }
            }
            foreach (var (copyId, val) in candidates)
                _copyFleetMap[copyId] = val.fleetId;
        }
        catch { }
    }

    private static void LoadFleetEnemies(string configDir)
    {
        try
        {
            var path = Path.Combine(configDir, "config_fleet.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("copy_enemys", out var enemies)) continue;
                var list = new List<int>();
                foreach (var item in enemies.EnumerateArray())
                    list.Add(item.GetInt32());
                _fleetEnemies[id] = list;
                // copy_attacheds 结构为 [[attachedFleetId, formation], ...]
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
            }
        }
        catch { }
    }

    private static void LoadEnemyStats(string configDir)
    {
        try
        {
            var path = Path.Combine(configDir, "config_ship_enemy.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("hp", out var hpProp)) continue;
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
            }
        }
        catch { }
    }

    public static int GetFleetId(int copyId)
        => _copyFleetMap.TryGetValue(copyId, out var id) ? id : copyId;

    public static bool HasCopyAttacheds(int fleetId)
        => _fleetHasAttached.TryGetValue(fleetId, out var has) && has;

    /// <summary>敌人舰队锚点：直接返回 config_copy 查到的真实舰队 id。
    /// 不再因 copy_attacheds 为空回退到临时测试舰队 907（此前误判，导致所有关卡
    /// 都弹 907 的 9999999HP 伤害测试敌舰 71）。若客户端 PVEStartData 因此 NRE，再单独处理。</summary>
    public static int GetFleetIdWithAttached(int copyId)
        => GetFleetId(copyId);

    public static int GetConfigId(int copyId)
        => _copyConfigIdMap.TryGetValue(copyId, out var id) ? id : copyId;

    public static List<int> GetEnemyIds(int fleetId)
        => _fleetEnemies.TryGetValue(fleetId, out var list) ? list : [];

    public static EnemyStat? GetEnemyStat(int enemyId)
        => _enemyStats.TryGetValue(enemyId, out var stat) ? stat : null;

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        const byte XorKey = 0x55;
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_ship_main 加载玩家船基础属性（key = sm_id = 船的 TemplateId）。</summary>
internal static class ShipMainLoader
{
    private static readonly Dictionary<int, ConfigShipMain> _ships = new();
    private static bool _loaded;

    public static void Load(string dataRoot)
    {
        if (_loaded) return;
        try
        {
            var configDir = Path.GetFullPath(Path.Combine(
                dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
            var path = Path.Combine(configDir, "config_ship_main.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                try
                {
                    var cfg = JsonSerializer.Deserialize<ConfigShipMain>(XorDecode(ReadColumnBytes(r, 1)));
                    if (cfg is null) continue;
                    _ships[id] = cfg;
                    if (cfg.SmId != 0)
                        _ships[checked((int)cfg.SmId)] = cfg;
                }
                catch
                {
                    // 个别坏行（如 id=nill 的无效 JSON）跳过，不影响整表加载。
                }
            }
        }
        catch { }
        _loaded = true;
    }

    public static ConfigShipMain? Get(int templateId)
        => _ships.TryGetValue(templateId, out var cfg) ? cfg : null;

    /// <summary>属性等级成长：base + levelup × (level - 1)。</summary>
    public static long Leveled(long baseValue, long levelup, int level)
        => baseValue + levelup * Math.Max(0, level - 1);

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        const byte XorKey = 0x55;
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_assist_ship_info 加载临时/支援舰船（key = assist_ship_info id = HeroId）。</summary>
internal static class AssistShipLoader
{
    private static readonly Dictionary<int, ConfigAssistShipInfo> _ships = new();
    private static bool _loaded;

    public static void Load(string dataRoot)
    {
        if (_loaded) return;
        try
        {
            var configDir = Path.GetFullPath(Path.Combine(
                dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
            var path = Path.Combine(configDir, "config_assist_ship_info.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                try
                {
                    var cfg = JsonSerializer.Deserialize<ConfigAssistShipInfo>(XorDecode(ReadColumnBytes(r, 1)));
                    if (cfg is null) continue;
                    _ships[id] = cfg;
                }
                catch { }
            }
        }
        catch { }
        _loaded = true;
    }

    public static ConfigAssistShipInfo? Get(int id)
        => _ships.TryGetValue(id, out var cfg) ? cfg : null;

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        const byte XorKey = 0x55;
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_equip 加载装备模板（key = e_id），用于构造出战船只的装备数据。</summary>
internal static class EquipLoader
{
    private static readonly Dictionary<int, ConfigEquip> _equips = new();
    private static bool _loaded;

    public static void Load(string dataRoot)
    {
        if (_loaded) return;
        try
        {
            var configDir = Path.GetFullPath(Path.Combine(
                dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
            var path = Path.Combine(configDir, "config_equip.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                try
                {
                    var cfg = JsonSerializer.Deserialize<ConfigEquip>(XorDecode(ReadColumnBytes(r, 1)));
                    if (cfg is null) continue;
                    _equips[id] = cfg;
                }
                catch { }
            }
        }
        catch { }
        _loaded = true;
    }

    public static ConfigEquip? Get(int id)
        => _equips.TryGetValue(id, out var cfg) ? cfg : null;

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        const byte XorKey = 0x55;
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_chapter 加载章节 → 关卡列表映射。</summary>
 internal static class ChapterCopyLoader
 {
     private static readonly Dictionary<int, List<int>> _chapterCopies = new();
     private static readonly Dictionary<int, int> _firstCopyMap = new();
     private static readonly Dictionary<int, List<int>> _seaChapterCopies = new();
     private static int _seaFirstChapterId = 0;
     private static int _seaFirstCopyId = 0;
     private static bool _loaded;

     public static void Load(string dataRoot)
     {
         if (_loaded) return;
         try
         {
             var configDir = FindConfigDir(dataRoot);
             var path = Path.Combine(configDir, "config_chapter.db");
             if (!File.Exists(path)) return;
             using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
             c.Open();
             using var cmd = c.CreateCommand();
             cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
             using var r = cmd.ExecuteReader();
             while (r.Read())
             {
                 var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                 if (id == 0) continue;
                 var bytes = ReadColumnBytes(r, 1);
                 var json = XorDecode(bytes);
                 using var doc = JsonDocument.Parse(json);
                 if (!doc.RootElement.TryGetProperty("level_list", out var levelList)) continue;
                 if (!doc.RootElement.TryGetProperty("class_type", out var classType)) continue;
                 var copies = new List<int>();
                 foreach (var item in levelList.EnumerateArray())
                     copies.Add(item.GetInt32());
                 if (copies.Count == 0) continue;
                 var ct = classType.GetInt32();
                 if (ct == 1) // PlotCopy
                 {
                     _chapterCopies[id] = copies;
                     _firstCopyMap[id] = copies[0];
                 }
                 else if (ct == 2) // SeaCopy
                 {
                     _seaChapterCopies[id] = copies;
                     if (_seaFirstChapterId == 0 || id < _seaFirstChapterId)
                     {
                         _seaFirstChapterId = id;
                         _seaFirstCopyId = copies[0];
                     }
                 }
             }
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

     /// <summary>海域（SeaCopy, class_type=2）全部章节的关卡，按章节 id 升序。</summary>
     public static List<int> GetSeaLevels()
     {
         var result = new List<int>();
         foreach (var chapterId in _seaChapterCopies.Keys.OrderBy(x => x))
             result.AddRange(_seaChapterCopies[chapterId]);
         return result;
     }

     /// <summary>海域第 1 章第一关（用作 MaxCopyId，使 _getFarestId 落在第 1 章）。</summary>
     public static int GetSeaFirstCopyId() => _seaFirstCopyId;

     /// <summary>从 dataRoot 向上逐级查找游戏配置目录
     /// （blueoath/blueoath/blueoath_Data/StreamingAssets/config）。适配不同 --data 深度
     /// （如 runtime/jp 下 dataRoot/../.. 即项目根，bin/Debug/net8.0/data 需向上 6 级）。</summary>
     internal static string FindConfigDir(string dataRoot)
     {
         var dir = new DirectoryInfo(dataRoot);
         for (var i = 0; i < 8 && dir != null; i++, dir = dir.Parent)
         {
             var cand = Path.Combine(dir.FullName, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config");
             if (Directory.Exists(cand)) return cand;
         }
         return dataRoot;
     }

     private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
     {
         if (reader.IsDBNull(ordinal)) return [];
         var value = reader.GetValue(ordinal);
         return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
     }

     private static string XorDecode(byte[] source)
     {
         const byte XorKey = 0x55;
         var result = new byte[source.Length];
         for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
         return Encoding.UTF8.GetString(result);
     }
 }
