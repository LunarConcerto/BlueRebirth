using Microsoft.Data.Sqlite;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

const byte XorKey = 0x55;

var root = FindRoot();
var jpDir = Path.Combine(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config");
var translationsPath = Path.Combine(root, "jp_only_translations.json");

if (!File.Exists(translationsPath)) { Console.Error.WriteLine($"Translations not found: {translationsPath}"); return 1; }

var translations = JsonSerializer.Deserialize<List<Translation>>(File.ReadAllText(translationsPath), new JsonSerializerOptions { PropertyNameCaseInsensitive = true })!;
Console.WriteLine($"Loaded {translations.Count} translations");

var byTable = translations.GroupBy(t => t.Table).ToDictionary(g => g.Key, g => g.ToList(), StringComparer.OrdinalIgnoreCase);
Console.WriteLine($"Tables: {byTable.Count}");

var totalUpdated = 0;
foreach (var (table, entries) in byTable)
{
    var tablePath = Path.Combine(jpDir, table + ".db");
    if (!File.Exists(tablePath))
    {
        Console.WriteLine($"  SKIP {table}: file not found");
        continue;
    }

    // Build lookup: key = id + \u001f + indexid, value = list of field updates
    var lookup = new Dictionary<string, List<(string Field, string Content)>>(StringComparer.Ordinal);
    foreach (var e in entries)
    {
        var key = e.Id + "\u001f" + e.IndexId;
        if (!lookup.TryGetValue(key, out var list))
            lookup[key] = list = new List<(string, string)>();
        list.Add((e.Field, e.Content));
    }

    var rows = ReadDbRows(tablePath);
    var updated = 0;

    foreach (var (key, row) in rows)
    {
        if (!lookup.TryGetValue(key, out var fieldUpdates)) continue;

        var modified = row.RawJson;
        var changed = false;

        foreach (var (field, newContent) in fieldUpdates)
        {
            // Try to replace the field value in the raw JSON string
            // Pattern: fieldname:"old_value" or fieldname:value
            var pattern = $@"({Regex.Escape(field)}\s*:\s*)([""'])(.*?)(\2)";
            var match = Regex.Match(modified, pattern);
            if (match.Success)
            {
                var oldVal = match.Groups[3].Value;
                if (oldVal != newContent)
                {
                    // Escape the new content for the raw JSON format
                    // The raw JSON uses double quotes for strings
                    var escaped = newContent.Replace("\\", "\\\\").Replace("\"", "\\\"");
                    modified = Regex.Replace(modified, pattern, $"$1\"{escaped}\"");
                    changed = true;
                }
            }
            else
            {
                // Try without quotes: fieldname:value (for numeric/boolean)
                var unquotedPattern = $@"({Regex.Escape(field)}\s*:\s*)([^,}}]*)";
                var unquotedMatch = Regex.Match(modified, unquotedPattern);
                if (unquotedMatch.Success)
                {
                    var oldVal = unquotedMatch.Groups[2].Value.Trim();
                    if (oldVal != newContent)
                    {
                        var escaped = newContent.Replace("\\", "\\\\").Replace("\"", "\\\"");
                        modified = Regex.Replace(modified, unquotedPattern, $"$1\"{escaped}\"");
                        changed = true;
                    }
                }
            }
        }

        if (changed)
        {
            row.EncodedBytes = Xor(Encoding.UTF8.GetBytes(modified));
            updated++;
        }
    }

    if (updated > 0)
    {
        WriteDbRows(tablePath, rows.Values.ToList());
        Console.WriteLine($"  {table}: {updated} updated");
        totalUpdated += updated;
    }
    else
    {
        Console.WriteLine($"  {table}: 0 updated");
    }
}

Console.WriteLine($"\nTotal updated: {totalUpdated}/{translations.Count}");

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

static Dictionary<string, DbRow> ReadDbRows(string path)
{
    var rows = new Dictionary<string, DbRow>(StringComparer.Ordinal);
    var builder = new SqliteConnectionStringBuilder { DataSource = path, Mode = SqliteOpenMode.ReadOnly, Pooling = false };
    using (var connection = new SqliteConnection(builder.ConnectionString))
    {
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
            var json = Encoding.UTF8.GetString(decoded);
            var key = id + "\u001f" + indexId;
            rows[key] = new DbRow(id, indexId, encoded, json);
        }
    }
    SqliteConnection.ClearAllPools();
    return rows;
}

static void WriteDbRows(string path, List<DbRow> rows)
{
    var tmp = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
    try
    {
        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = tmp,
            Mode = SqliteOpenMode.ReadWriteCreate,
            Pooling = false
        };
        using (var connection = new SqliteConnection(builder.ConnectionString))
        {
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
                jsonParam.Value = row.EncodedBytes;
                insert.ExecuteNonQuery();
            }
        }
    }
    catch
    {
        if (File.Exists(tmp)) File.Delete(tmp);
        throw;
    }

    SqliteConnection.ClearAllPools();
    GC.Collect();
    GC.WaitForPendingFinalizers();
    File.Move(tmp, path, overwrite: true);
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

sealed record Translation(string Table, string Id, string IndexId, string Field, string Content);
sealed class DbRow
{
    public string Id { get; }
    public string IndexId { get; }
    public byte[] EncodedBytes { get; set; }
    public string RawJson { get; }

    public DbRow(string id, string indexId, byte[] encodedBytes, string rawJson)
    {
        Id = id;
        IndexId = indexId;
        EncodedBytes = encodedBytes;
        RawJson = rawJson;
    }
}