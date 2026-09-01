using ClosedXML.Excel;
using Microsoft.Data.Sqlite;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

static class ConfigExcelTool
{
    private const byte XorKey = 0x55;
    private const string ManifestVersion = "2.0";
    private const string EmptyStringMarker = "\"\"";

    public static async Task<int> RunAsync(string[] args)
    {
        if (args.Contains("--config-excel-self-test", StringComparer.OrdinalIgnoreCase))
            return await RunSelfTestAsync();
        if (args.Contains("--config-excel-backup", StringComparer.OrdinalIgnoreCase))
            return RunBackup(args);
        if (args.Contains("--config-excel-import", StringComparer.OrdinalIgnoreCase))
            return RunImport(args);
        return await RunExportAsync(args);
    }

    // ------------------------------------------------------------------
    // Export
    // ------------------------------------------------------------------

    private static async Task<int> RunExportAsync(string[] args)
    {
        var region = ReadArg(args, "--region=") ?? "jp";
        var configRoot = ResolveConfigRoot(args, region);
        var output = Path.GetFullPath(ReadArg(args, "--output=") ?? Path.Combine(FindRoot(), "config-excel", region));
        var tables = await ExportAsync(configRoot, output, region);
        Console.WriteLine(JsonSerializer.Serialize(new
        {
            complete = true,
            action = "export",
            region,
            configRoot = Path.GetFullPath(configRoot),
            output,
            tables = tables.Count,
            rows = tables.Sum(t => t.Rows),
            metadataRows = tables.Sum(t => t.MetadataRows)
        }));
        return 0;
    }

    private static async Task<List<TableSummary>> ExportAsync(string configRoot, string outputDir, string region)
    {
        if (!Directory.Exists(configRoot))
            throw new DirectoryNotFoundException($"Config directory not found: {configRoot}");
        Directory.CreateDirectory(outputDir);

        var summaries = new List<TableSummary>();
        foreach (var dbPath in Directory.EnumerateFiles(configRoot, "config_*.db")
                     .OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
            summaries.Add(ExportTable(dbPath, outputDir));

        await WriteManifestAsync(outputDir, region, configRoot, summaries);
        return summaries;
    }

    private static TableSummary ExportTable(string dbPath, string outputDir)
    {
        var table = Path.GetFileNameWithoutExtension(dbPath);
        var data = new List<ConfigRow>();
        var meta = new List<MetaRow>();
        var schema = new ConfigSchema.Node();

        using (var connection = OpenReadOnly(dbPath))
        using (var command = connection.CreateCommand())
        {
            command.CommandText = "SELECT id, indexid, jsonbytes FROM DBObject ORDER BY rowid";
            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                var id = ReadNullableString(reader, 0);
                var indexId = ReadNullableString(reader, 1);
                var decoded = Xor(ReadBytes(reader, 2));
                if (string.Equals(id, "nill", StringComparison.OrdinalIgnoreCase) || !IsValidJson(decoded))
                {
                    meta.Add(new MetaRow(id ?? "nill", indexId, decoded));
                    continue;
                }
                using var document = JsonDocument.Parse(decoded);
                ConfigSchema.Merge(schema, document.RootElement);
                data.Add(new ConfigRow(id!, indexId ?? string.Empty, Encoding.UTF8.GetString(decoded)));
            }
        }

        var columns = new List<FieldColumn>();
        var usedHeaders = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "_id", "_indexid" };
        foreach (var field in schema.Fields.Keys.OrderBy(k => k, StringComparer.Ordinal))
        {
            var header = field;
            while (!usedHeaders.Add(header)) header += "_json";
            columns.Add(new FieldColumn(header, field, ConfigSchema.Classify(schema.Fields[field])));
        }

        var outputPath = Path.Combine(outputDir, table + ".xlsx");
        using (var workbook = new XLWorkbook())
        {
            var sheet = workbook.AddWorksheet("data");
            sheet.Cell(1, 1).Value = "_id";
            sheet.Cell(1, 2).Value = "_indexid";
            for (var c = 0; c < columns.Count; c++)
                sheet.Cell(1, c + 3).Value = columns[c].Header;
            sheet.Column(1).Style.NumberFormat.Format = "@";
            sheet.Column(2).Style.NumberFormat.Format = "@";
            sheet.SheetView.FreezeRows(1);

            var rowIndex = 2;
            foreach (var row in data)
            {
                sheet.Cell(rowIndex, 1).Value = row.Id;
                sheet.Cell(rowIndex, 2).Value = row.IndexId;
                using var document = JsonDocument.Parse(row.Json);
                var element = document.RootElement;
                for (var c = 0; c < columns.Count; c++)
                {
                    if (!element.TryGetProperty(columns[c].Field, out var value)) continue;
                    WriteValue(sheet.Cell(rowIndex, c + 3), value);
                }
                rowIndex++;
            }

            var schemaSheet = workbook.AddWorksheet("_schema");
            schemaSheet.Cell(1, 1).Value = "header";
            schemaSheet.Cell(1, 2).Value = "field";
            schemaSheet.Cell(1, 3).Value = "type";
            schemaSheet.SheetView.FreezeRows(1);
            for (var c = 0; c < columns.Count; c++)
            {
                schemaSheet.Cell(c + 2, 1).Value = columns[c].Header;
                schemaSheet.Cell(c + 2, 2).Value = columns[c].Field;
                schemaSheet.Cell(c + 2, 3).Value = ConfigSchema.CSharpType(schema.Fields[columns[c].Field]);
            }

            var metaSheet = workbook.AddWorksheet("_meta");
            metaSheet.Cell(1, 1).Value = "id";
            metaSheet.Cell(1, 2).Value = "indexid";
            metaSheet.Cell(1, 3).Value = "jsonbytes_base64";
            metaSheet.SheetView.FreezeRows(1);
            var metaIndex = 2;
            foreach (var m in meta)
            {
                metaSheet.Cell(metaIndex, 1).Value = m.Id;
                metaSheet.Cell(metaIndex, 2).Value = m.IndexId ?? string.Empty;
                metaSheet.Cell(metaIndex, 3).Value = Convert.ToBase64String(m.Decoded);
                metaIndex++;
            }

            workbook.SaveAs(outputPath);
        }

        return new TableSummary(table, Path.GetFileName(outputPath), Sha256(dbPath), data.Count, meta.Count);
    }

    private static void WriteValue(IXLCell cell, JsonElement value)
    {
        switch (value.ValueKind)
        {
            case JsonValueKind.Number:
                cell.Value = value.TryGetInt64(out var integer) ? integer : value.GetDouble();
                break;
            case JsonValueKind.String:
                var text = value.GetString() ?? string.Empty;
                cell.Value = text.Length == 0 ? EmptyStringMarker : text;
                break;
            case JsonValueKind.True:
            case JsonValueKind.False:
                cell.Value = value.GetBoolean() ? "true" : "false";
                break;
            case JsonValueKind.Null:
            case JsonValueKind.Undefined:
                break;
            default:
                cell.Value = value.GetRawText();
                break;
        }
    }

    private static async Task WriteManifestAsync(string outputDir, string region, string configRoot,
        List<TableSummary> tables)
    {
        var manifest = new
        {
            schemaVersion = ManifestVersion,
            generatedUtc = DateTimeOffset.UtcNow,
            region,
            xorKey = (int)XorKey,
            sourceConfigRoot = Path.GetFullPath(configRoot),
            tables = tables.Select(t => new { t.Table, t.File, t.DbSha256, t.Rows, t.MetadataRows }).ToArray()
        };
        await File.WriteAllTextAsync(Path.Combine(outputDir, "_manifest.json"),
            JsonSerializer.Serialize(manifest, new JsonSerializerOptions { WriteIndented = true }),
            new UTF8Encoding(false));
    }

    // ------------------------------------------------------------------
    // Import
    // ------------------------------------------------------------------

    private static int RunImport(string[] args)
    {
        var region = ReadArg(args, "--region=") ?? "jp";
        var configRoot = ResolveConfigRoot(args, region);
        var input = ReadArg(args, "--input=")
            ?? throw new ArgumentException("--config-excel-import requires --input=<folder|.xlsx>");
        input = Path.GetFullPath(input);
        var outputArg = ReadArg(args, "--output=");
        var targetRoot = outputArg is null ? configRoot : Path.GetFullPath(outputArg);
        var backup = !args.Contains("--no-backup", StringComparer.OrdinalIgnoreCase);

        var result = Import(input, targetRoot, backup);
        Console.WriteLine(JsonSerializer.Serialize(new
        {
            complete = true,
            action = "import",
            region,
            input,
            targetRoot = Path.GetFullPath(targetRoot),
            result.ImportedTables,
            result.BackupDir
        }));
        return 0;
    }

    private static ImportResult Import(string input, string targetRoot, bool backup)
    {
        var files = ResolveInputFiles(input);
        if (files.Length == 0)
            throw new FileNotFoundException("No config_*.xlsx files found under input", input);
        Directory.CreateDirectory(targetRoot);

        var tableNames = files.Select(f => Path.GetFileNameWithoutExtension(f)!).ToArray();
        var backupDir = backup ? CreateBackup(targetRoot, tableNames) : null;

        foreach (var file in files)
            ImportTableFile(file, Path.Combine(targetRoot, Path.GetFileNameWithoutExtension(file) + ".db"));

        return new ImportResult(files.Length, backupDir);
    }

    private static string[] ResolveInputFiles(string input)
    {
        if (File.Exists(input) && input.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
            return [Path.GetFullPath(input)];
        if (Directory.Exists(input))
            return Directory.EnumerateFiles(input, "config_*.xlsx")
                .OrderBy(x => x, StringComparer.OrdinalIgnoreCase).ToArray();
        throw new FileNotFoundException("Input path does not exist", input);
    }

    private static void ImportTableFile(string xlsxPath, string targetDb)
    {
        var data = new List<ConfigRow>();
        var meta = new List<MetaRow>();

        using (var workbook = new XLWorkbook(xlsxPath))
        {
            var schemaSheet = FindWorksheet(workbook, "_schema");
            if (schemaSheet is not null)
                ReadExpandedData(workbook, schemaSheet, xlsxPath, data);
            else
                ReadLegacyData(workbook, xlsxPath, data);

            var metaSheet = FindWorksheet(workbook, "_meta");
            if (metaSheet is not null)
                ReadMeta(metaSheet, xlsxPath, meta);
        }

        var duplicate = data.GroupBy(x => x.Id).FirstOrDefault(g => g.Count() > 1);
        if (duplicate is not null)
            throw new InvalidDataException($"{Path.GetFileName(xlsxPath)}: duplicate id '{duplicate.Key}'");

        var tmp = targetDb + "." + Guid.NewGuid().ToString("N") + ".tmp";
        try
        {
            BuildDatabase(tmp, data, meta);
            ReplaceFile(tmp, targetDb);
        }
        finally
        {
            if (File.Exists(tmp)) File.Delete(tmp);
        }
    }

    private static void ReadExpandedData(IXLWorkbook workbook, IXLWorksheet schemaSheet, string xlsxPath,
        List<ConfigRow> data)
    {
        var fields = new List<FieldColumn>();
        var schemaLast = schemaSheet.LastRowUsed()?.RowNumber() ?? 1;
        for (var r = 2; r <= schemaLast; r++)
        {
            var header = ReadCellText(schemaSheet.Cell(r, 1)).Trim();
            var field = ReadCellText(schemaSheet.Cell(r, 2)).Trim();
            var type = ReadCellText(schemaSheet.Cell(r, 3)).Trim();
            if (header.Length == 0 && field.Length == 0) continue;
            if (field.Length == 0)
                throw new InvalidDataException($"{Path.GetFileName(xlsxPath)} _schema row {r}: empty field");
            fields.Add(new FieldColumn(header, field, DeriveKind(type)));
        }

        var sheet = FindWorksheet(workbook, "data")
            ?? workbook.Worksheets.FirstOrDefault()
            ?? throw new InvalidDataException($"{Path.GetFileName(xlsxPath)} has no data worksheet");

        var headerLast = 1;
        var maxHeaderRow = Math.Min(sheet.LastRowUsed()?.RowNumber() ?? 1, 20);
        for (var r = 1; r <= maxHeaderRow; r++)
        {
            if (string.Equals(ReadCellText(sheet.Cell(r, 1)).Trim(), "_id", StringComparison.OrdinalIgnoreCase))
            {
                headerLast = r;
                break;
            }
        }

        var headerIndex = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        for (var c = 1; c <= 1000; c++)
        {
            var header = ReadCellText(sheet.Cell(headerLast, c)).Trim();
            if (header.Length == 0) break;
            headerIndex[header] = c;
        }
        if (!headerIndex.TryGetValue("_id", out var idColumn))
            throw new InvalidDataException($"{Path.GetFileName(xlsxPath)} data sheet is missing the '_id' column");
        headerIndex.TryGetValue("_indexid", out var indexIdColumn);

        var lastRow = sheet.LastRowUsed()?.RowNumber() ?? headerLast;
        for (var r = headerLast + 1; r <= lastRow; r++)
        {
            var id = ReadCellText(sheet.Cell(r, idColumn)).Trim();
            var indexId = indexIdColumn > 0 ? ReadCellText(sheet.Cell(r, indexIdColumn)) : string.Empty;
            if (string.Equals(id, "nill", StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException($"{Path.GetFileName(xlsxPath)} row {r}: id 'nill' is reserved for metadata");

            var jsonObject = new JsonObject();
            foreach (var field in fields)
            {
                if (!headerIndex.TryGetValue(field.Header, out var column)) continue;
                var value = ReadFieldCell(sheet.Cell(r, column), field.Kind,
                    $"{Path.GetFileName(xlsxPath)} row {r} column '{field.Header}'");
                if (value is null) continue;
                jsonObject[field.Field] = value;
            }

            if (id.Length == 0 && jsonObject.Count == 0) continue;
            data.Add(new ConfigRow(id, indexId, jsonObject.ToJsonString()));
        }
    }

    private static void ReadLegacyData(IXLWorkbook workbook, string xlsxPath, List<ConfigRow> data)
    {
        var sheet = FindWorksheet(workbook, "data")
            ?? workbook.Worksheets.FirstOrDefault()
            ?? throw new InvalidDataException($"{Path.GetFileName(xlsxPath)} has no worksheet");
        var lastRow = sheet.LastRowUsed()?.RowNumber() ?? 1;
        for (var r = 2; r <= lastRow; r++)
        {
            var id = ReadCellText(sheet.Cell(r, 1)).Trim();
            var indexId = ReadCellText(sheet.Cell(r, 2));
            var json = ReadCellText(sheet.Cell(r, 3));
            if (id.Length == 0 && indexId.Length == 0 && json.Length == 0) continue;
            if (string.Equals(id, "nill", StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException($"{Path.GetFileName(xlsxPath)} row {r}: id 'nill' is reserved for metadata");
            if (!IsValidJson(Encoding.UTF8.GetBytes(json)))
                throw new InvalidDataException($"{Path.GetFileName(xlsxPath)} row {r} (id={id}): json cell is not valid JSON");
            data.Add(new ConfigRow(id, indexId, json));
        }
    }

    private static void ReadMeta(IXLWorksheet metaSheet, string xlsxPath, List<MetaRow> meta)
    {
        var metaLastRow = metaSheet.LastRowUsed()?.RowNumber() ?? 1;
        for (var r = 2; r <= metaLastRow; r++)
        {
            var id = ReadCellText(metaSheet.Cell(r, 1)).Trim();
            var indexId = ReadCellText(metaSheet.Cell(r, 2));
            var base64 = ReadCellText(metaSheet.Cell(r, 3)).Trim();
            if (id.Length == 0 && indexId.Length == 0 && base64.Length == 0) continue;
            if (base64.Length == 0)
                throw new InvalidDataException($"{Path.GetFileName(xlsxPath)} _meta row {r}: empty jsonbytes_base64");
            byte[] decoded;
            try
            {
                decoded = Convert.FromBase64String(base64);
            }
            catch (FormatException exception)
            {
                throw new InvalidDataException($"{Path.GetFileName(xlsxPath)} _meta row {r}: invalid base64", exception);
            }
            meta.Add(new MetaRow(id.Length == 0 ? "nill" : id, indexId.Length == 0 ? null : indexId, decoded));
        }
    }

    private static JsonNode? ReadFieldCell(IXLCell cell, ConfigSchema.Kind kind, string context)
    {
        if (cell.IsEmpty()) return null;
        switch (kind)
        {
            case ConfigSchema.Kind.Integer:
            case ConfigSchema.Kind.Number:
            {
                var number = ReadNumber(cell, context);
                if (kind == ConfigSchema.Kind.Integer)
                {
                    if (!double.IsFinite(number) || Math.Truncate(number) != number ||
                        number < long.MinValue || number >= 9223372036854775808.0)
                        throw new InvalidDataException($"{context}: expected an integer value");
                    return JsonValue.Create((long)number);
                }
                return JsonValue.Create(number);
            }
            case ConfigSchema.Kind.String:
            {
                var text = ReadCellText(cell);
                return JsonValue.Create(text == EmptyStringMarker ? string.Empty : text);
            }
            case ConfigSchema.Kind.Bool:
            {
                var text = ReadCellText(cell).Trim().ToLowerInvariant();
                if (text is "true" or "1") return JsonValue.Create(true);
                if (text is "false" or "0") return JsonValue.Create(false);
                throw new InvalidDataException($"{context}: expected true/false");
            }
            case ConfigSchema.Kind.Array:
            {
                var text = ReadCellText(cell);
                var node = JsonNode.Parse(text)
                    ?? throw new InvalidDataException($"{context}: empty JSON array cell");
                if (node is not JsonArray)
                    throw new InvalidDataException($"{context}: expected a JSON array like [1,2,3]");
                return node;
            }
            case ConfigSchema.Kind.Object:
            {
                var text = ReadCellText(cell);
                try
                {
                    return JsonNode.Parse(text);
                }
                catch (JsonException)
                {
                    return JsonValue.Create(text);
                }
            }
            default:
                return null;
        }
    }

    private static double ReadNumber(IXLCell cell, string context)
    {
        if (cell.DataType == XLDataType.Number)
            return cell.GetDouble();
        var text = ReadCellText(cell).Trim();
        if (double.TryParse(text, NumberStyles.Any, CultureInfo.InvariantCulture, out var value))
            return value;
        throw new InvalidDataException($"{context}: expected a number, got '{text}'");
    }

    private static ConfigSchema.Kind DeriveKind(string type)
    {
        if (type.StartsWith("List<", StringComparison.Ordinal)) return ConfigSchema.Kind.Array;
        return type switch
        {
            "long" => ConfigSchema.Kind.Integer,
            "double" => ConfigSchema.Kind.Number,
            "string" => ConfigSchema.Kind.String,
            "bool" => ConfigSchema.Kind.Bool,
            _ => ConfigSchema.Kind.Object
        };
    }

    private static void BuildDatabase(string path, IReadOnlyList<ConfigRow> rows, IReadOnlyList<MetaRow> metaRows)
    {
        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = path,
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
        var idParameter = insert.Parameters.Add("$id", SqliteType.Text);
        var indexIdParameter = insert.Parameters.Add("$indexid", SqliteType.Text);
        var jsonParameter = insert.Parameters.Add("$jsonbytes", SqliteType.Blob);

        foreach (var row in rows)
        {
            idParameter.Value = row.Id;
            indexIdParameter.Value = row.IndexId;
            jsonParameter.Value = Xor(Encoding.UTF8.GetBytes(row.Json));
            insert.ExecuteNonQuery();
        }

        foreach (var m in metaRows)
        {
            idParameter.Value = m.Id;
            indexIdParameter.Value = m.IndexId is null ? DBNull.Value : m.IndexId;
            jsonParameter.Value = Xor(m.Decoded);
            insert.ExecuteNonQuery();
        }
    }

    // ------------------------------------------------------------------
    // Backup
    // ------------------------------------------------------------------

    private static int RunBackup(string[] args)
    {
        var region = ReadArg(args, "--region=") ?? "jp";
        var configRoot = ResolveConfigRoot(args, region);
        var backupDir = BackupDirectory(configRoot, ReadArg(args, "--output="));
        Console.WriteLine(JsonSerializer.Serialize(new
        {
            complete = true,
            action = "backup",
            region,
            source = Path.GetFullPath(configRoot),
            backupDir
        }));
        return 0;
    }

    private static string BackupDirectory(string configRoot, string? explicitDir)
    {
        if (!Directory.Exists(configRoot))
            throw new DirectoryNotFoundException($"Config directory not found: {configRoot}");
        var backupDir = explicitDir is not null
            ? Path.GetFullPath(explicitDir)
            : Path.Combine(Path.GetDirectoryName(Path.GetFullPath(configRoot)) ?? configRoot,
                "config-backup", DateTime.Now.ToString("yyyyMMdd-HHmmss"));
        Directory.CreateDirectory(backupDir);
        foreach (var db in Directory.EnumerateFiles(configRoot, "config_*.db"))
            File.Copy(db, Path.Combine(backupDir, Path.GetFileName(db)), overwrite: true);
        return backupDir;
    }

    private static string CreateBackup(string targetRoot, IEnumerable<string> tableNames)
    {
        var fullTarget = Path.GetFullPath(targetRoot);
        var backupDir = Path.Combine(Path.GetDirectoryName(fullTarget) ?? fullTarget,
            "config-backup", DateTime.Now.ToString("yyyyMMdd-HHmmss"));
        Directory.CreateDirectory(backupDir);
        foreach (var table in tableNames)
        {
            var db = Path.Combine(targetRoot, table + ".db");
            if (File.Exists(db)) File.Copy(db, Path.Combine(backupDir, table + ".db"), overwrite: true);
        }
        return backupDir;
    }

    // ------------------------------------------------------------------
    // Self-test
    // ------------------------------------------------------------------

    private static async Task<int> RunSelfTestAsync()
    {
        var tmp = Path.Combine(Path.GetTempPath(), "blueoath-configexcel-" + Guid.NewGuid().ToString("N"));
        var src = Path.Combine(tmp, "config");
        var excel = Path.Combine(tmp, "excel");
        var restored = Path.Combine(tmp, "restored");
        Directory.CreateDirectory(src);
        Directory.CreateDirectory(excel);
        Directory.CreateDirectory(restored);
        try
        {
            BuildDatabase(Path.Combine(src, "config_alpha.db"), new[]
            {
                new ConfigRow("1", "", "{\"id\":\"1\",\"name\":\"ok\",\"n\":1,\"arr\":[1,2,3],\"nested_arr\":[[1,2],[3]],\"empty_str\":\"\",\"empty_arr\":[],\"flag\":true}"),
                new ConfigRow("2", "idx", "{\"id\":\"2\",\"name\":\"测试中文\",\"n\":2,\"arr\":[],\"nested_arr\":[],\"empty_str\":\"x\",\"empty_arr\":[5],\"flag\":false,\"bracket\":\"[not json\"}"),
                new ConfigRow("3", "", "{\"id\":\"3\",\"name\":\"\",\"n\":3,\"arr\":[\"a\",\"b\"],\"bracket\":\"[1,2]\",\"ratio\":1.5}"),
                new ConfigRow("4", "", "{\"id\":\"4\",\"name\":\"d\",\"n\":4,\"ratio\":2}"),
                new ConfigRow("9", "", "{\"id\":\"99\",\"name\":\"mismatch-id\",\"n\":9}")
            }, [new MetaRow("nill", null, Encoding.ASCII.GetBytes("abcdef0123456789abcdef0123456789"))]);

            BuildDatabase(Path.Combine(src, "config_beta.db"),
                [new ConfigRow("1", "", "{\"x\":1}")],
                [new MetaRow("nill", null, Encoding.ASCII.GetBytes("00112233445566778899aabbccddeeff"))]);

            var exported = await ExportAsync(src, excel, "selftest");
            if (exported.Count != 2) throw new InvalidOperationException("export produced unexpected table count");
            if (!File.Exists(Path.Combine(excel, "_manifest.json")))
                throw new InvalidOperationException("export did not write _manifest.json");
            using (var workbook = new XLWorkbook(Path.Combine(excel, "config_alpha.xlsx")))
            {
                if (FindWorksheet(workbook, "_schema") is null)
                    throw new InvalidOperationException("export did not write the _schema sheet");
                var dataSheet = workbook.Worksheet("data");
                if (!string.Equals(ReadCellText(dataSheet.Cell(1, 1)), "_id", StringComparison.Ordinal) ||
                    !string.Equals(ReadCellText(dataSheet.Cell(1, 2)), "_indexid", StringComparison.Ordinal))
                    throw new InvalidOperationException("export header row is missing _id/_indexid");
            }

            var imported = Import(excel, restored, backup: false);
            if (imported.ImportedTables != 2) throw new InvalidOperationException("import table count mismatch");

            AssertDatabasesEqual(Path.Combine(src, "config_alpha.db"), Path.Combine(restored, "config_alpha.db"));
            AssertDatabasesEqual(Path.Combine(src, "config_beta.db"), Path.Combine(restored, "config_beta.db"));

            Console.WriteLine("config-excel self-test passed (export + import round-trips JSON values)");
            return 0;
        }
        finally
        {
            if (Directory.Exists(tmp)) Directory.Delete(tmp, recursive: true);
        }
    }

    private static void AssertDatabasesEqual(string expected, string actual)
    {
        var expectedRows = ReadDatabaseRows(expected);
        var actualRows = ReadDatabaseRows(actual);
        if (expectedRows.Count != actualRows.Count)
            throw new InvalidOperationException($"{Path.GetFileName(expected)} row count {expectedRows.Count} != {actualRows.Count}");
        foreach (var (key, value) in expectedRows)
        {
            if (!actualRows.TryGetValue(key, out var actualValue))
                throw new InvalidOperationException($"{Path.GetFileName(expected)} row '{key}' missing");
            if (IsValidJson(value) && IsValidJson(actualValue))
            {
                var expectedNode = JsonNode.Parse(Encoding.UTF8.GetString(value));
                var actualNode = JsonNode.Parse(Encoding.UTF8.GetString(actualValue));
                if (!JsonNode.DeepEquals(expectedNode, actualNode))
                    throw new InvalidOperationException($"{Path.GetFileName(expected)} row '{key}' JSON value mismatch");
            }
            else if (!value.SequenceEqual(actualValue))
            {
                throw new InvalidOperationException($"{Path.GetFileName(expected)} row '{key}' raw bytes mismatch");
            }
        }
    }

    private static Dictionary<string, byte[]> ReadDatabaseRows(string path)
    {
        var rows = new Dictionary<string, byte[]>(StringComparer.Ordinal);
        using var connection = OpenReadOnly(path);
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT id, indexid, jsonbytes FROM DBObject ORDER BY rowid";
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            var id = ReadNullableString(reader, 0) ?? string.Empty;
            var indexId = ReadNullableString(reader, 1) ?? "\u0001NULL";
            rows[id + "\u0000" + indexId] = Xor(ReadBytes(reader, 2));
        }
        return rows;
    }

    // ------------------------------------------------------------------
    // Shared helpers
    // ------------------------------------------------------------------

    private static SqliteConnection OpenReadOnly(string path)
    {
        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = path,
            Mode = SqliteOpenMode.ReadOnly,
            Pooling = false
        };
        var connection = new SqliteConnection(builder.ConnectionString);
        connection.Open();
        return connection;
    }

    private static string? ReadNullableString(SqliteDataReader reader, int ordinal) =>
        reader.IsDBNull(ordinal) ? null : Convert.ToString(reader.GetValue(ordinal));

    private static byte[] ReadBytes(SqliteDataReader reader, int ordinal)
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

    private static bool IsValidJson(byte[] bytes)
    {
        try
        {
            using var document = JsonDocument.Parse(bytes);
            return true;
        }
        catch (JsonException)
        {
            return false;
        }
    }

    private static byte[] Xor(ReadOnlySpan<byte> source)
    {
        var result = new byte[source.Length];
        for (var index = 0; index < source.Length; index++)
            result[index] = (byte)(source[index] ^ XorKey);
        return result;
    }

    private static string ReadCellText(IXLCell cell)
    {
        if (cell.IsEmpty()) return string.Empty;
        return cell.GetString() ?? string.Empty;
    }

    private static IXLWorksheet? FindWorksheet(IXLWorkbook workbook, string name) =>
        workbook.Worksheets.FirstOrDefault(w => string.Equals(w.Name, name, StringComparison.OrdinalIgnoreCase));

    private static void ReplaceFile(string source, string destination)
    {
        if (File.Exists(destination))
        {
            var attributes = File.GetAttributes(destination);
            if ((attributes & FileAttributes.ReadOnly) != 0)
                File.SetAttributes(destination, attributes & ~FileAttributes.ReadOnly);
            File.Delete(destination);
        }
        File.Move(source, destination);
    }

    private static string Sha256(string path)
    {
        using var stream = File.OpenRead(path);
        return Convert.ToHexString(SHA256.HashData(stream));
    }

    private static string ResolveConfigRoot(string[] args, string region)
    {
        var custom = ReadArg(args, "--config-root=");
        if (!string.IsNullOrWhiteSpace(custom)) return Path.GetFullPath(custom);
        var root = FindRoot();
        return region.ToLowerInvariant() switch
        {
            "jp" => Path.Combine(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"),
            "cn" => Path.Combine(root, "苍蓝誓约", "clsy", "clsy_Data", "StreamingAssets", "config"),
            _ => throw new ArgumentException("--region must be jp or cn")
        };
    }

    private static string FindRoot()
    {
        var current = new DirectoryInfo(Environment.CurrentDirectory);
        while (current is not null)
        {
            if (File.Exists(Path.Combine(current.FullName, "BlueOath.Local.sln"))) return current.FullName;
            current = current.Parent;
        }
        throw new DirectoryNotFoundException("Could not locate BlueOath.Local.sln");
    }

    private static string? ReadArg(string[] args, string prefix) =>
        args.FirstOrDefault(x => x.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))?[prefix.Length..];

    private sealed record ConfigRow(string Id, string IndexId, string Json);
    private sealed record MetaRow(string Id, string? IndexId, byte[] Decoded);
    private sealed record FieldColumn(string Header, string Field, ConfigSchema.Kind Kind);
    private sealed record TableSummary(string Table, string File, string DbSha256, int Rows, int MetadataRows);
    private sealed record ImportResult(int ImportedTables, string? BackupDir);
}
