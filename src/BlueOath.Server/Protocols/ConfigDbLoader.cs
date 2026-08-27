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
    /// 直接由启动参数传入的客户端路径计算游戏配置目录
    /// （<c>{clientPath}/blueoath_Data/StreamingAssets/config</c>），不再向上逐级查找。
    /// </summary>
    public static string BuildConfigDir(string clientPath)
    {
        if (string.IsNullOrEmpty(clientPath)) return "";
        return Path.Combine(clientPath, "blueoath_Data", "StreamingAssets", "config");
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