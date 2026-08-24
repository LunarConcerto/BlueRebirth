using Microsoft.Data.Sqlite;
using System.Text;
using System.Text.Json;

const byte XorKey = 0x55;

var root = FindRoot();
var jpDbPath = Path.Combine(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config", "config_language.db");
var cnDbPath = Path.Combine(root, "苍蓝誓约", "clsy", "clsy_Data", "StreamingAssets", "config", "config_language.db");

if (!File.Exists(jpDbPath)) { Console.Error.WriteLine($"JP db not found: {jpDbPath}"); return 1; }
if (!File.Exists(cnDbPath)) { Console.Error.WriteLine($"CN db not found: {cnDbPath}"); return 1; }

// Backup JP database
var backupDir = Path.Combine(root, "config-backup", DateTime.Now.ToString("yyyyMMdd-HHmmss"));
Directory.CreateDirectory(backupDir);
var backupPath = Path.Combine(backupDir, "config_language.db");
File.Copy(jpDbPath, backupPath, overwrite: true);
Console.WriteLine($"Backup: {backupPath}");

// Read all rows from both databases
var jpRows = ReadAllJpRows(jpDbPath);
var cnRows = ReadAllRows(cnDbPath);

Console.WriteLine($"JP rows: {jpRows.Count}, CN rows: {cnRows.Count}");

// Match by id+indexid
var replacedCount = 0;
var unmatched = new List<JpRow>();
var matchedIds = new HashSet<string>();

foreach (var jpRow in jpRows)
{
    var key = jpRow.Id + "\u001f" + jpRow.IndexId;
    if (cnRows.TryGetValue(key, out var cnRow))
    {
        // Replace JP jsonbytes with CN jsonbytes (both already decoded)
        // We need to re-encode the CN bytes with XOR
        jpRow.RawEncoded = Xor(cnRow.DecodedBytes);
        replacedCount++;
        matchedIds.Add(key);
    }
    else
    {
        unmatched.Add(jpRow);
    }
}

Console.WriteLine($"Matched and replaced: {replacedCount}");
Console.WriteLine($"Unmatched (need AI translation): {unmatched.Count}");

// Write unmatched rows info
var unmatchedPath = Path.Combine(root, "unmatched_language.json");
var unmatchedInfo = unmatched.Select(r => new
{
    r.Id,
    r.IndexId,
    Json = r.DecodedJson
}).ToList();
await File.WriteAllTextAsync(unmatchedPath,
    JsonSerializer.Serialize(unmatchedInfo, new JsonSerializerOptions { WriteIndented = true }),
    new UTF8Encoding(false));
Console.WriteLine($"Unmatched rows written to: {unmatchedPath}");

// Write back modified JP database
WriteDatabase(jpDbPath, jpRows);
Console.WriteLine($"JP database updated with {replacedCount} replacements");

// Show sample of unmatched rows
if (unmatched.Count > 0)
{
    Console.WriteLine("\n--- Sample unmatched rows (first 10) ---");
    foreach (var row in unmatched.Take(10))
    {
        Console.WriteLine($"ID={row.Id}, JSON={Truncate(row.DecodedJson, 200)}");
    }
}

return 0;

static string FindRoot()
{
    var current = new DirectoryInfo(Environment.CurrentDirectory);
    while (current is not null)
    {
        if (File.Exists(Path.Combine(current.FullName, "BlueOath.Local.sln"))) return current.FullName;
        current = current.Parent;
    }
    throw new DirectoryNotFoundException("Could not locate BlueOath.Local.sln");
}

static byte[] Xor(ReadOnlySpan<byte> source)
{
    var result = new byte[source.Length];
    for (var index = 0; index < source.Length; index++) result[index] = (byte)(source[index] ^ XorKey);
    return result;
}

static Dictionary<string, CnRow> ReadAllRows(string path)
{
    var rows = new Dictionary<string, CnRow>(StringComparer.Ordinal);
    var builder = new SqliteConnectionStringBuilder { DataSource = path, Mode = SqliteOpenMode.ReadOnly, Pooling = false };
    using var connection = new SqliteConnection(builder.ConnectionString);
    connection.Open();
    using var command = connection.CreateCommand();
    command.CommandText = "SELECT id, indexid, jsonbytes FROM DBObject ORDER BY rowid";
    using var reader = command.ExecuteReader();
    while (reader.Read())
    {
        var id = reader.IsDBNull(0) ? string.Empty : Convert.ToString(reader.GetValue(0)) ?? string.Empty;
        var indexId = reader.IsDBNull(1) ? string.Empty : Convert.ToString(reader.GetValue(1)) ?? string.Empty;
        var decoded = Xor(ReadBytes(reader, 2));
        var key = id + "\u001f" + indexId;
        rows[key] = new CnRow(decoded);
    }
    return rows;
}

static List<JpRow> ReadAllJpRows(string path)
{
    var rows = new List<JpRow>();
    var builder = new SqliteConnectionStringBuilder { DataSource = path, Mode = SqliteOpenMode.ReadOnly, Pooling = false };
    using var connection = new SqliteConnection(builder.ConnectionString);
    connection.Open();
    using var command = connection.CreateCommand();
    command.CommandText = "SELECT id, indexid, jsonbytes FROM DBObject ORDER BY rowid";
    using var reader = command.ExecuteReader();
    while (reader.Read())
    {
        var id = reader.IsDBNull(0) ? string.Empty : Convert.ToString(reader.GetValue(0)) ?? string.Empty;
        var indexId = reader.IsDBNull(1) ? string.Empty : Convert.ToString(reader.GetValue(1)) ?? string.Empty;
        var encoded = ReadBytes(reader, 2);
        var decoded = Xor(encoded);
        var decodedJson = Encoding.UTF8.GetString(decoded);
        rows.Add(new JpRow(id, indexId, encoded, decoded, decodedJson));
    }
    return rows;
}

static void WriteDatabase(string path, List<JpRow> rows)
{
    // Write to temp file first, then replace
    var tmp = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
    try
    {
        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = tmp,
            Mode = SqliteOpenMode.ReadWriteCreate,
            Pooling = false
        };
        using var connection = new SqliteConnection(builder.ConnectionString);
        connection.Open();
        using (var ddl = connection.CreateCommand())
        {
            ddl.CommandText = "CREATE TABLE \"DBObject\"(\"id\" varchar primary key not null,\"indexid\" varchar,\"jsonbytes\" blob)";
            ddl.ExecuteNonQuery();
            ddl.CommandText = "CREATE INDEX \"DBObject_indexid\" on \"DBObject\"(\"indexid\")";
            ddl.ExecuteNonQuery();
        }

        using var insert = connection.CreateCommand();
        insert.CommandText = "INSERT INTO DBObject(id, indexid, jsonbytes) VALUES($id, $indexid, $jsonbytes)";
        var idParam = insert.Parameters.Add("$id", SqliteType.Text);
        var indexIdParam = insert.Parameters.Add("$indexid", SqliteType.Text);
        var jsonParam = insert.Parameters.Add("$jsonbytes", SqliteType.Blob);

        foreach (var row in rows)
        {
            idParam.Value = row.Id;
            indexIdParam.Value = row.IndexId;
            jsonParam.Value = row.RawEncoded;
            insert.ExecuteNonQuery();
        }
    }
    catch
    {
        if (File.Exists(tmp)) File.Delete(tmp);
        throw;
    }

    if (File.Exists(path))
    {
        var attrs = File.GetAttributes(path);
        if ((attrs & FileAttributes.ReadOnly) != 0) File.SetAttributes(path, attrs & ~FileAttributes.ReadOnly);
        File.Delete(path);
    }
    File.Move(tmp, path);
}

static byte[] ReadBytes(SqliteDataReader reader, int ordinal)
{
    if (reader.IsDBNull(ordinal)) return [];
    var value = reader.GetValue(ordinal);
    return value switch
    {
        byte[] bytes => bytes,
        string text => Encoding.UTF8.GetBytes(text),
        _ => throw new InvalidDataException($"Unsupported jsonbytes SQLite type: {value.GetType().FullName}")
    };
}

static string Truncate(string text, int maxLen) =>
    text.Length <= maxLen ? text : text[..maxLen] + "...";

sealed record CnRow(byte[] DecodedBytes);
sealed class JpRow
{
    public string Id { get; }
    public string IndexId { get; }
    public byte[] RawEncoded { get; set; }
    public byte[] DecodedBytes { get; }
    public string DecodedJson { get; }

    public JpRow(string id, string indexId, byte[] rawEncoded, byte[] decodedBytes, string decodedJson)
    {
        Id = id;
        IndexId = indexId;
        RawEncoded = rawEncoded;
        DecodedBytes = decodedBytes;
        DecodedJson = decodedJson;
    }
}