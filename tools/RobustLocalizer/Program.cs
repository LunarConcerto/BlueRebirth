using Microsoft.Data.Sqlite;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

const byte XorKey = 0x55;

var root = FindRoot();
var jpDir = Path.Combine(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config");
var cnDir = Path.Combine(root, "苍蓝誓约", "clsy", "clsy_Data", "StreamingAssets", "config");

if (!Directory.Exists(jpDir)) { Console.Error.WriteLine($"JP config not found: {jpDir}"); return 1; }
if (!Directory.Exists(cnDir)) { Console.Error.WriteLine($"CN config not found: {cnDir}"); return 1; }

// Backup
var backupDir = Path.Combine(root, "config-backup", "robust-" + DateTime.Now.ToString("yyyyMMdd-HHmmss"));
Directory.CreateDirectory(backupDir);
foreach (var db in Directory.GetFiles(jpDir, "config_*.db"))
    File.Copy(db, Path.Combine(backupDir, Path.GetFileName(db)), overwrite: true);
Console.WriteLine($"Backup: {backupDir}");

var jpTables = Directory.GetFiles(jpDir, "config_*.db").Select(f => Path.GetFileNameWithoutExtension(f)!).ToHashSet(StringComparer.OrdinalIgnoreCase);
var cnTables = Directory.GetFiles(cnDir, "config_*.db").Select(f => Path.GetFileNameWithoutExtension(f)!).ToHashSet(StringComparer.OrdinalIgnoreCase);
var commonTables = jpTables.Intersect(cnTables, StringComparer.OrdinalIgnoreCase).OrderBy(x => x, StringComparer.OrdinalIgnoreCase).ToList()!;
var jpOnlyTables = jpTables.Except(cnTables, StringComparer.OrdinalIgnoreCase).OrderBy(x => x, StringComparer.OrdinalIgnoreCase).ToList()!;

Console.WriteLine($"Common: {commonTables.Count}, JP-only: {jpOnlyTables.Count}");

var totalRowsModified = 0;

// Phase 1: Common tables
var processed = 0;
foreach (var tableName in commonTables)
{
    var jpPath = Path.Combine(jpDir, tableName + ".db");
    var cnPath = Path.Combine(cnDir, tableName + ".db");
    var jpSize = new FileInfo(jpPath).Length;
    var cnSize = new FileInfo(cnPath).Length;
    if (jpSize == cnSize) continue;

    processed++;
    Console.WriteLine($"[{processed}] {tableName}...");

    var result = ProcessCommonTable(jpPath, cnPath);
    if (result > 0)
    {
        Console.WriteLine($"  -> {result} rows");
        totalRowsModified += result;
    }
}

Console.WriteLine($"\nPhase 1 done: {totalRowsModified} rows modified");

// Phase 2: JP-only tables
var translationsPath = Path.Combine(root, "jp_only_translations.json");
if (File.Exists(translationsPath))
{
    var translations = JsonSerializer.Deserialize<List<TranslationEntry>>(
        File.ReadAllText(translationsPath),
        new JsonSerializerOptions { PropertyNameCaseInsensitive = true })!;
    Console.WriteLine($"Loaded {translations.Count} translations");

    var byTable = translations.GroupBy(t => t.Table)
        .ToDictionary(g => g.Key, g => g.ToList(), StringComparer.OrdinalIgnoreCase);

    foreach (var (table, entries) in byTable)
    {
        var tablePath = Path.Combine(jpDir, table + ".db");
        if (!File.Exists(tablePath)) continue;
        var result = ProcessJpOnlyTable(tablePath, entries);
        if (result > 0)
        {
            Console.WriteLine($"  {table}: {result} updated");
            totalRowsModified += result;
        }
    }
}

Console.WriteLine($"\nAll done. Total rows modified: {totalRowsModified}");
return 0;

// ====== Processing Functions ======

static int ProcessCommonTable(string jpPath, string cnPath)
{
    var jpRows = ReadDbRows(jpPath);
    var cnRows = ReadDbRows(cnPath);

    var format = "quoted";
    var first = jpRows.Values.FirstOrDefault();
    if (first != null) format = JsonNormalizer.DetectFormat(first.RawJson);

    var modified = 0;
    foreach (var (key, jpRow) in jpRows)
    {
        if (!cnRows.TryGetValue(key, out var cnRow)) continue;
        if (jpRow.RawJson == cnRow.RawJson) continue;

        var jpObj = JsonNormalizer.Parse(jpRow.RawJson);
        var cnObj = JsonNormalizer.Parse(cnRow.RawJson);
        if (jpObj == null || cnObj == null) continue;

        var jpDict = JsonElementToDict(jpObj.Value);
        var cnDict = JsonElementToDict(cnObj.Value);

        var replaced = new Dictionary<string, string>();
        foreach (var (fieldName, cnVal) in cnDict)
        {
            if (!jpDict.TryGetValue(fieldName, out var jpVal)) continue;
            if (jpVal == cnVal) continue;
            if (IsTextField(cnVal, jpVal))
                replaced[fieldName] = cnVal;
        }

        if (replaced.Count == 0) continue;

        jpRow.RawJson = JsonNormalizer.Serialize(jpDict, replaced, format);
        jpRow.EncodedBytes = Xor(Encoding.UTF8.GetBytes(jpRow.RawJson));
        modified++;
    }

    if (modified > 0) WriteDbRows(jpPath, jpRows.Values.ToList());
    return modified;
}

static int ProcessJpOnlyTable(string jpPath, List<TranslationEntry> entries)
{
    var lookup = new Dictionary<string, Dictionary<string, string>>(StringComparer.Ordinal);
    foreach (var e in entries)
    {
        var key = e.Id + "\u001f" + e.IndexId;
        if (!lookup.TryGetValue(key, out var map))
            lookup[key] = map = new Dictionary<string, string>(StringComparer.Ordinal);
        map[e.Field] = e.Content;
    }

    var rows = ReadDbRows(jpPath);
    var format = "quoted";
    var first = rows.Values.FirstOrDefault();
    if (first != null) format = JsonNormalizer.DetectFormat(first.RawJson);

    var updated = 0;
    foreach (var (key, row) in rows)
    {
        if (!lookup.TryGetValue(key, out var fieldMap)) continue;

        var obj = JsonNormalizer.Parse(row.RawJson);
        if (obj == null) continue;

        var dict = JsonElementToDict(obj.Value);
        var changed = false;
        foreach (var (field, newContent) in fieldMap)
        {
            if (dict.TryGetValue(field, out var oldVal) && oldVal != newContent)
            {
                dict[field] = newContent;
                changed = true;
            }
        }

        if (changed)
        {
            row.RawJson = JsonNormalizer.Serialize(dict, null, format);
            row.EncodedBytes = Xor(Encoding.UTF8.GetBytes(row.RawJson));
            updated++;
        }
    }

    if (updated > 0) WriteDbRows(jpPath, rows.Values.ToList());
    return updated;
}

static bool IsTextField(string cnValue, string jpValue)
{
    if (string.IsNullOrWhiteSpace(cnValue)) return false;
    foreach (var c in cnValue)
        if ((c >= 0x4E00 && c <= 0x9FFF) || (c >= 0x3400 && c <= 0x4DBF) || (c >= 0xF900 && c <= 0xFAFF))
            return true;
    foreach (var c in jpValue)
        if ((c >= 0x3040 && c <= 0x309F) || (c >= 0x30A0 && c <= 0x30FF) || (c >= 0x31F0 && c <= 0x31FF))
            return true;
    return false;
}

static Dictionary<string, string> JsonElementToDict(JsonElement element)
{
    var dict = new Dictionary<string, string>(StringComparer.Ordinal);
    if (element.ValueKind == JsonValueKind.Object)
        foreach (var prop in element.EnumerateObject())
            dict[prop.Name] = prop.Value.GetRawText();
    return dict;
}

// ====== Database I/O ======

static Dictionary<string, DbRow> ReadDbRows(string path)
{
    var rows = new Dictionary<string, DbRow>(StringComparer.Ordinal);
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
        var json = Encoding.UTF8.GetString(decoded);
        var key = id + "\u001f" + indexId;
        rows[key] = new DbRow(id, indexId, encoded, json);
    }
    return rows;
}

static void WriteDbRows(string path, List<DbRow> rows)
{
    var tmp = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
    try
    {
        var builder = new SqliteConnectionStringBuilder { DataSource = tmp, Mode = SqliteOpenMode.ReadWriteCreate, Pooling = false };
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
            jsonParam.Value = row.EncodedBytes;
            insert.ExecuteNonQuery();
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

static byte[] Xor(ReadOnlySpan<byte> source)
{
    var result = new byte[source.Length];
    for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
    return result;
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

// ====== Types ======

sealed class DbRow
{
    public string Id { get; }
    public string IndexId { get; }
    public byte[] EncodedBytes { get; set; }
    public string RawJson { get; set; }

    public DbRow(string id, string indexId, byte[] encodedBytes, string rawJson)
    {
        Id = id;
        IndexId = indexId;
        EncodedBytes = encodedBytes;
        RawJson = rawJson;
    }
}

sealed record TranslationEntry(string Table, string Id, string IndexId, string Field, string Content);

// ====== JSON Normalizer ======

static class JsonNormalizer
{
    private static readonly Regex UnquotedKeyRegex = new(
        @"(^|[{,])\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:",
        RegexOptions.Compiled);

    public static string DetectFormat(string raw)
    {
        var trimmed = raw.TrimStart();
        if (trimmed.Length > 1 && trimmed[1] == '"') return "quoted";
        return "unquoted";
    }

    public static JsonElement? Parse(string raw)
    {
        try { return JsonDocument.Parse(raw).RootElement; }
        catch (JsonException)
        {
            var normalized = UnquotedKeyRegex.Replace(raw, "$1\"$2\":");
            try { return JsonDocument.Parse(normalized).RootElement; }
            catch (JsonException) { return null; }
        }
    }

    public static string Serialize(Dictionary<string, string> dict, Dictionary<string, string>? replacements, string format)
    {
        if (format == "quoted")
        {
            using var ms = new MemoryStream();
            using var writer = new Utf8JsonWriter(ms, new JsonWriterOptions { Indented = false });
            writer.WriteStartObject();
            foreach (var (key, value) in dict)
            {
                writer.WritePropertyName(key);
                var finalValue = replacements != null && replacements.TryGetValue(key, out var r) ? r : value;
                WriteRawJson(writer, finalValue);
            }
            writer.WriteEndObject();
            writer.Flush();
            return Encoding.UTF8.GetString(ms.ToArray());
        }
        else
        {
            var sb = new StringBuilder();
            sb.Append('{');
            var first = true;
            foreach (var (key, value) in dict)
            {
                if (!first) sb.Append(',');
                first = false;
                sb.Append(key);
                sb.Append(':');
                var finalValue = replacements != null && replacements.TryGetValue(key, out var r) ? r : value;
                sb.Append(finalValue);
            }
            sb.Append('}');
            return sb.ToString();
        }
    }

    private static void WriteRawJson(Utf8JsonWriter writer, string rawValue)
    {
        if (rawValue == "null") writer.WriteNullValue();
        else if (rawValue == "true") writer.WriteBooleanValue(true);
        else if (rawValue == "false") writer.WriteBooleanValue(false);
        else if (rawValue.StartsWith('"') && rawValue.EndsWith('"'))
            writer.WriteStringValue(rawValue[1..^1]);
        else if (rawValue.StartsWith('[') || rawValue.StartsWith('{'))
            writer.WriteRawValue(rawValue);
        else if (long.TryParse(rawValue, out var l))
            writer.WriteNumberValue(l);
        else if (double.TryParse(rawValue, out var d))
            writer.WriteNumberValue(d);
        else
            writer.WriteStringValue(rawValue);
    }
}