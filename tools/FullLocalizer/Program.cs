using Microsoft.Data.Sqlite;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

const byte XorKey = 0x55;

// Known text field names (case-insensitive)
HashSet<string> textFieldNames = new(StringComparer.OrdinalIgnoreCase)
{
    "name", "desc", "description", "title", "tips", "content", "info", "text",
    "message", "message1", "message2", "advice", "comment", "beizhu",
    "ship_name", "country_name", "show_name", "display_name", "full_name",
    "equip_show_name", "type_name", "hero_name", "activity_name",
    "diff_name", "cn_text", "jp_text", "englishname", "plot_title",
    "talker_name", "item_name", "item_name_dawn", "item_name_night",
    "interaction_item_name", "interaction_item_desc", "skill_name", "skill_desc",
    "talent_name", "strategy_name", "strategy_dec1", "strategy_dec2", "strategy_dec3",
    "tip", "tip1", "tip2", "tip3", "buff_tips", "team_buff_name", "team_buff_desc",
    "buff_name", "battle_tip", "effect_name", "nation_text",
    "affection_describe", "affection_adddescribe", "mood_describe",
    "A_tips", "B_tips", "S_tips", "SS_tips", "SSS_tips",
    "love_letter_description", "love_letter_sign",
    "mail_title", "mail_content", "mail_title_eng",
    "nodouble_desc", "nodouble_extra_reward_desc",
    "chapter_openname", "desc_simplify", "helpinfo_title",
    "set_name", "factor_description", "safe_effect_desc",
    "profilelist", "dropdesc", "notice", "texttitle",
    "activity_effect_desc", "attr_name", "attr_display",
    "title_chi", "title_eng", "guildpost"
};

var root = FindRoot();
var jpDir = Path.Combine(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config");
var cnDir = Path.Combine(root, "苍蓝誓约", "clsy", "clsy_Data", "StreamingAssets", "config");

if (!Directory.Exists(jpDir)) { Console.Error.WriteLine($"JP config not found: {jpDir}"); return 1; }
if (!Directory.Exists(cnDir)) { Console.Error.WriteLine($"CN config not found: {cnDir}"); return 1; }

// Backup all JP config files
var backupDir = Path.Combine(root, "config-backup", "full-" + DateTime.Now.ToString("yyyyMMdd-HHmmss"));
Directory.CreateDirectory(backupDir);
foreach (var db in Directory.GetFiles(jpDir, "config_*.db"))
    File.Copy(db, Path.Combine(backupDir, Path.GetFileName(db)), overwrite: true);
Console.WriteLine($"Backup: {backupDir}");

var jpTables = Directory.GetFiles(jpDir, "config_*.db").Select(f => Path.GetFileNameWithoutExtension(f)!).ToHashSet(StringComparer.OrdinalIgnoreCase);
var cnTables = Directory.GetFiles(cnDir, "config_*.db").Select(f => Path.GetFileNameWithoutExtension(f)!).ToHashSet(StringComparer.OrdinalIgnoreCase);

var commonTables = jpTables.Intersect(cnTables, StringComparer.OrdinalIgnoreCase).OrderBy(x => x, StringComparer.OrdinalIgnoreCase).ToList()!;
var jpOnlyTables = jpTables.Except(cnTables, StringComparer.OrdinalIgnoreCase).OrderBy(x => x, StringComparer.OrdinalIgnoreCase).ToList()!;
var cnOnlyTables = cnTables.Except(jpTables, StringComparer.OrdinalIgnoreCase).OrderBy(x => x, StringComparer.OrdinalIgnoreCase).ToList()!;

Console.WriteLine($"Common tables: {commonTables.Count}, JP-only: {jpOnlyTables.Count}, CN-only: {cnOnlyTables.Count}");

// Statistics
var totalRowsReplaced = 0;
var totalFieldsReplaced = 0;
var totalTablesModified = 0;
var perTableStats = new List<TableStat>();

// Process common tables
var processed = 0;
foreach (var tableName in commonTables)
{
    var jpPath = Path.Combine(jpDir, tableName + ".db");
    var cnPath = Path.Combine(cnDir, tableName + ".db");

    // Quick skip: if file sizes match, likely identical
    var jpSize = new FileInfo(jpPath).Length;
    var cnSize = new FileInfo(cnPath).Length;
    if (jpSize == cnSize) continue;

    processed++;
    Console.WriteLine($"[{processed}] Processing {tableName} (JP: {jpSize}B, CN: {cnSize}B)...");

    var result = ProcessTable(jpPath, cnPath, tableName);
    if (result.RowsModified > 0)
    {
        totalTablesModified++;
        totalRowsReplaced += result.RowsModified;
        totalFieldsReplaced += result.FieldsModified;
        perTableStats.Add(result);
    }
}

Console.WriteLine($"\n=== Summary ===");
Console.WriteLine($"Tables modified: {totalTablesModified}/{commonTables.Count}");
Console.WriteLine($"Rows with changes: {totalRowsReplaced}");
Console.WriteLine($"Fields replaced: {totalFieldsReplaced}");

// Write detailed per-table stats
Console.WriteLine($"\n=== Per-Table Details ===");
foreach (var stat in perTableStats.OrderByDescending(x => x.FieldsModified))
    Console.WriteLine($"  {stat.TableName}: {stat.RowsModified} rows, {stat.FieldsModified} fields, fields: [{string.Join(", ", stat.ChangedFields)}]");

// Record JP-only tables for manual translation
Console.WriteLine($"\n=== JP-Only Tables ({jpOnlyTables.Count}) ===");
foreach (var t in jpOnlyTables)
    Console.WriteLine($"  {t}");

// Extract text from JP-only tables for AI translation
var jpOnlyTexts = new List<JpOnlyTextEntry>();
foreach (var tableName in jpOnlyTables)
{
    var jpPath = Path.Combine(jpDir, tableName + ".db");
    ExtractTextFields(jpPath, tableName, jpOnlyTexts);
}

var jpOnlyPath = Path.Combine(root, "jp_only_texts.json");
await File.WriteAllTextAsync(jpOnlyPath,
    JsonSerializer.Serialize(jpOnlyTexts, new JsonSerializerOptions { WriteIndented = true, Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping }),
    new UTF8Encoding(false));
Console.WriteLine($"\nJP-only texts extracted: {jpOnlyTexts.Count} entries -> {jpOnlyPath}");

return 0;

// ---- Core processing ----

TableStat ProcessTable(string jpPath, string cnPath, string tableName)
{
    var jpRows = ReadDbRows(jpPath);
    var cnRows = ReadDbRows(cnPath);

    var rowsModified = 0;
    var fieldsModified = 0;
    var changedFields = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

    foreach (var (key, jpRow) in jpRows)
    {
        if (!cnRows.TryGetValue(key, out var cnRow)) continue;
        if (jpRow.RawJson == cnRow.RawJson) continue; // identical

        // Parse both JSONs
        JsonDocument jpDoc, cnDoc;
        try { jpDoc = JsonDocument.Parse(jpRow.RawJson); }
        catch { continue; }
        try { cnDoc = JsonDocument.Parse(cnRow.RawJson); }
        catch { jpDoc.Dispose(); continue; }

        using (jpDoc)
        using (cnDoc)
        {
            if (jpDoc.RootElement.ValueKind != JsonValueKind.Object ||
                cnDoc.RootElement.ValueKind != JsonValueKind.Object)
                continue;

            var jpObj = jpDoc.RootElement;
            var cnObj = cnDoc.RootElement;

            // Collect all fields from both
            var allFields = new HashSet<string>();
            foreach (var prop in jpObj.EnumerateObject()) allFields.Add(prop.Name);
            foreach (var prop in cnObj.EnumerateObject()) allFields.Add(prop.Name);

            var replacements = new Dictionary<string, string>();
            foreach (var fieldName in allFields)
            {
                jpObj.TryGetProperty(fieldName, out var jpVal);
                cnObj.TryGetProperty(fieldName, out var cnVal);

                // Skip if CN doesn't have this field or values are same
                if (cnVal.ValueKind == JsonValueKind.Undefined) continue;
                if (jpVal.ValueKind != JsonValueKind.Undefined && jpVal.GetRawText() == cnVal.GetRawText()) continue;

                if (ShouldReplaceField(jpVal, cnVal, fieldName, textFieldNames))
                {
                    replacements[fieldName] = cnVal.GetRawText();
                }
            }

            if (replacements.Count == 0) continue;

            // Build new JSON
            var newJson = BuildNewJson(jpObj, replacements);
            var newEncoded = Xor(Encoding.UTF8.GetBytes(newJson));
            jpRow.EncodedBytes = newEncoded;

            rowsModified++;
            fieldsModified += replacements.Count;
            foreach (var f in replacements.Keys) changedFields.Add(f);
        }
    }

    if (rowsModified > 0)
    {
        WriteDbRows(jpPath, jpRows.Values.ToList());
    }

    return new TableStat(tableName, rowsModified, fieldsModified, changedFields.ToList());
}

static bool ShouldReplaceField(JsonElement jpVal, JsonElement cnVal, string fieldName, HashSet<string> textFields)
{
    // CN value must be a string
    if (cnVal.ValueKind != JsonValueKind.String) return false;
    var cnStr = cnVal.GetString()!;
    if (string.IsNullOrWhiteSpace(cnStr)) return false;

    // Check if CN value contains Chinese characters
    if (ContainsChinese(cnStr))
        return true;

    // Check if field name is a known text field
    if (textFields.Contains(fieldName))
        return true;

    // If JP value is also a string and contains Japanese kana, and CN differs
    if (jpVal.ValueKind == JsonValueKind.String)
    {
        var jpStr = jpVal.GetString()!;
        if (ContainsJapanese(jpStr) && jpStr != cnStr)
            return true;
    }

    return false;
}

static bool ContainsChinese(string text)
{
    for (int i = 0; i < text.Length; i++)
    {
        var c = text[i];
        if (c >= 0x4E00 && c <= 0x9FFF) return true;
        if (c >= 0x3400 && c <= 0x4DBF) return true; // CJK Extension A
        if (c >= 0xF900 && c <= 0xFAFF) return true; // CJK Compatibility
    }
    return false;
}

static bool ContainsJapanese(string text)
{
    for (int i = 0; i < text.Length; i++)
    {
        var c = text[i];
        // Hiragana
        if (c >= 0x3040 && c <= 0x309F) return true;
        // Katakana
        if (c >= 0x30A0 && c <= 0x30FF) return true;
        // Katakana Phonetic Extensions
        if (c >= 0x31F0 && c <= 0x31FF) return true;
    }
    return false;
}

static string BuildNewJson(JsonElement jpObj, Dictionary<string, string> replacements)
{
    var sb = new StringBuilder();
    sb.Append('{');
    var first = true;
    foreach (var prop in jpObj.EnumerateObject())
    {
        if (!first) sb.Append(',');
        first = false;
        sb.Append(JsonEncodedText.Encode(prop.Name));
        sb.Append(':');
        if (replacements.TryGetValue(prop.Name, out var newVal))
            sb.Append(newVal);
        else
            sb.Append(prop.Value.GetRawText());
    }
    sb.Append('}');
    return sb.ToString();
}

static void ExtractTextFields(string jpPath, string tableName, List<JpOnlyTextEntry> results)
{
    // Check if the table has the expected DBObject schema
    try
    {
        var builder = new SqliteConnectionStringBuilder { DataSource = jpPath, Mode = SqliteOpenMode.ReadOnly, Pooling = false };
        using var connection = new SqliteConnection(builder.ConnectionString);
        connection.Open();
        using var check = connection.CreateCommand();
        check.CommandText = "SELECT name FROM sqlite_master WHERE type='table' AND name='DBObject'";
        var hasTable = check.ExecuteScalar() != null;
        if (!hasTable) return;
    }
    catch { return; }

    var rows = ReadDbRows(jpPath);
    foreach (var (key, row) in rows)
    {
        try
        {
            using var doc = JsonDocument.Parse(row.RawJson);
            if (doc.RootElement.ValueKind != JsonValueKind.Object) continue;

            foreach (var prop in doc.RootElement.EnumerateObject())
            {
                if (prop.Value.ValueKind != JsonValueKind.String) continue;
                var text = prop.Value.GetString()!;
                if (string.IsNullOrWhiteSpace(text)) continue;
                if (!ContainsJapanese(text) && !ContainsChinese(text)) continue;

                results.Add(new JpOnlyTextEntry(tableName, row.Id, row.IndexId, prop.Name, text));
            }
        }
        catch { }
    }
}

// ---- Database I/O ----

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

static byte[] Xor(ReadOnlySpan<byte> source)
{
    var result = new byte[source.Length];
    for (var index = 0; index < source.Length; index++) result[index] = (byte)(source[index] ^ XorKey);
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

// ---- Types ----

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

sealed record TableStat(string TableName, int RowsModified, int FieldsModified, List<string> ChangedFields);
sealed record JpOnlyTextEntry(string Table, string Id, string IndexId, string Field, string Text);