using System.Text;
using System.Text.Json;
using Microsoft.Data.Sqlite;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 游戏客户端配置数据库的通用加载工具。
/// 所有 config_*.db 共享同一 SQLite 结构（DBObject 表，id/jsonbytes 列），
/// jsonbytes 均以 XOR 0x55 编码。提供 <see cref="LoadAll{T}"/> 与 <see cref="LoadRows"/>
/// 两条泛型加载路径，覆盖「全实体反序列化」与「逐行自定义提取」两种模式。
/// </summary>
internal static class ConfigDbLoader
{
    /// <summary>配置数据库的 XOR 密钥（对所有 config_*.db 通用）。</summary>
    public const byte XorKey = 0x55;

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    /// <summary>
    /// 直接由启动参数传入的客户端路径计算游戏基础配置目录
    /// （<c>{clientPath}/blueoath_Data/StreamingAssets/config</c>），不再向上逐级查找。
    /// 注意实际生效的配置还要叠加热更目录，见 <see cref="ResolveDbPath"/>。
    /// </summary>
    public static string BuildConfigDir(string clientPath)
    {
        if (string.IsNullOrEmpty(clientPath)) return "";
        return Path.Combine(clientPath, "blueoath_Data", "StreamingAssets", "config");
    }

    /// <summary>
    /// 解析某张配置表的实际路径。官方启动器把热更下发的增量配置写到安装根目录的
    /// <c>config/</c>（与游戏目录平级），客户端运行时按「热更优先、StreamingAssets 兜底」
    /// 合并——热更目录只包含被改动过的表，其余仍走整包内的基础表。服务端必须遵循同一
    /// 优先级，否则会和客户端读到不同版本的配置（例如日服停服前最后一次热更新增的
    /// 舰船与突破链，在基础表里并不存在）。
    /// </summary>
    public static string ResolveDbPath(string configDir, string dbFile)
    {
        var hotpatch = BuildHotpatchPath(configDir, dbFile);
        if (hotpatch is not null && File.Exists(hotpatch)) return hotpatch;
        return Path.Combine(configDir, dbFile);
    }

    /// <summary>
    /// 由基础配置目录反推热更配置路径：
    /// <c>{install}/{client}/blueoath_Data/StreamingAssets/config</c> → <c>{install}/config/{dbFile}</c>。
    /// 目录层级不符合该形状时返回 <c>null</c>，避免对自定义配置目录做出错误推断。
    /// </summary>
    private static string? BuildHotpatchPath(string configDir, string dbFile)
    {
        var streamingAssets = Path.GetDirectoryName(configDir);
        if (streamingAssets is null || !string.Equals(
                Path.GetFileName(streamingAssets), "StreamingAssets", StringComparison.OrdinalIgnoreCase))
            return null;
        var dataDir = Path.GetDirectoryName(streamingAssets);
        var clientDir = dataDir is null ? null : Path.GetDirectoryName(dataDir);
        var installDir = clientDir is null ? null : Path.GetDirectoryName(clientDir);
        return installDir is null ? null : Path.Combine(installDir, "config", dbFile);
    }

    /// <summary>
    /// 加载整表并反序列化为 <see cref="Dictionary{TKey, TValue}"/>，键为 DBObject.id。
    /// 个别坏行会被跳过（per-row try/catch），不中断整表加载。
    /// </summary>
    public static Dictionary<int, T> LoadAll<T>(string configDir, string dbFile) where T : class
    {
        var result = new Dictionary<int, T>();
        LoadRows(configDir, dbFile, (id, _, json) =>
        {
            try
            {
                var entity = JsonSerializer.Deserialize<T>(json, JsonOptions);
                if (entity is not null) result[id] = entity;
            }
            catch { /* 跳过个别坏行 */ }
        });
        return result;
    }

    /// <summary>
    /// 加载整表并反序列化，然后对每条记录执行自定义后处理（例如双键索引、过滤）。
    /// 后处理中抛出的异常同样只会跳过当前行。
    /// </summary>
    public static void LoadAll<T>(string configDir, string dbFile, Action<int, T> postProcess) where T : class
    {
        LoadRows(configDir, dbFile, (id, _, json) =>
        {
            try
            {
                var entity = JsonSerializer.Deserialize<T>(json, JsonOptions);
                if (entity is not null) postProcess(id, entity);
            }
            catch { }
        });
    }

    /// <summary>
    /// 遍历 DBObject 所有行，逐行回调。回调参数：(id, reader, xorDecodedJson)。
    /// 回调内部可随意解析 JSON，异常由回调自行处理，遍历不会中断。
    /// </summary>
    public static void LoadRows(string configDir, string dbFile, Action<int, SqliteDataReader, string> callback)
    {
        var path = ResolveDbPath(configDir, dbFile);
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
            callback(id, r, json);
        }
    }

    /// <summary>安全读取列值：NULL 返回空，byte[] 直传，string 转 UTF-8 字节。</summary>
    public static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    /// <summary>XOR 0x55 解码，结果转为 UTF-8 字符串。</summary>
    public static string XorDecode(byte[] source)
    {
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}