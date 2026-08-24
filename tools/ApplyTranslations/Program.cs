using Microsoft.Data.Sqlite;
using System.Text;
using System.Text.Json;

const byte XorKey = 0x55;

var root = FindRoot();
var jpDbPath = Path.Combine(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config", "config_language.db");
var translationsPath = Path.Combine(root, "translations.json");

if (!File.Exists(translationsPath)) { Console.Error.WriteLine($"Translations not found: {translationsPath}"); return 1; }

var translations = JsonSerializer.Deserialize<List<TranslationItem>>(File.ReadAllText(translationsPath), new JsonSerializerOptions { PropertyNameCaseInsensitive = true })!;
var translationMap = translations.ToDictionary(t => t.Id, t => t.Content, StringComparer.Ordinal);
Console.WriteLine($"Loaded {translationMap.Count} translations");

// Read all JP rows
var rows = ReadAllRows(jpDbPath);
var updated = 0;

foreach (var row in rows)
{
    if (translationMap.TryGetValue(row.Id, out var translatedContent))
    {
        // Parse the original JSON, replace content, re-serialize
        try
        {
            using var doc = JsonDocument.Parse(row.DecodedJson);
            var rootElement = doc.RootElement;
            var newJson = new Dictionary<string, JsonElement>();
            foreach (var prop in rootElement.EnumerateObject())
            {
                if (prop.Name == "content")
                    newJson[prop.Name] = JsonDocument.Parse($"\"{JsonEncodedText.Encode(translatedContent)}\"").RootElement;
                else
                    newJson[prop.Name] = prop.Value.Clone();
            }
            var options = new JsonWriterOptions { Indented = false };
            using var ms = new MemoryStream();
            using var writer = new Utf8JsonWriter(ms, options);
            writer.WriteStartObject();
            foreach (var kvp in newJson)
            {
                writer.WritePropertyName(kvp.Key);
                kvp.Value.WriteTo(writer);
            }
            writer.WriteEndObject();
            writer.Flush();
            var decoded = ms.ToArray();
            row.RawEncoded = Xor(decoded);
            updated++;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error processing ID {row.Id}: {ex.Message}");
        }
    }
}

Console.WriteLine($"Updated {updated} rows with AI translations");

// Write back
WriteDatabase(jpDbPath, rows);
Console.WriteLine("Database updated successfully");

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

static List<DbRow> ReadAllRows(string path)
{
    var rows = new List<DbRow>();
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
        rows.Add(new DbRow(id, indexId, encoded, decodedJson));
    }
    return rows;
}

static void WriteDatabase(string path, List<DbRow> rows)
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

sealed record TranslationItem(string Id, string Content);
sealed class DbRow
{
    public string Id { get; }
    public string IndexId { get; }
    public byte[] RawEncoded { get; set; }
    public string DecodedJson { get; }

    public DbRow(string id, string indexId, byte[] rawEncoded, string decodedJson)
    {
        Id = id;
        IndexId = indexId;
        RawEncoded = rawEncoded;
        DecodedJson = decodedJson;
    }
}