using Microsoft.Data.Sqlite;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

static class ConfigDatabaseTool
{
    private const byte XorKey = 0x55;

    public static async Task<int> RunAsync(string[] args)
    {
        var root = FindRoot();
        var query = ReadArg(args, "--config-query=");
        if (!string.IsNullOrWhiteSpace(query)) return Query(root, query);
        var search = ReadArg(args, "--config-search=");
        if (!string.IsNullOrWhiteSpace(search)) return Search(root, search);
        var output = ReadArg(args, "--config-output=") ?? Path.Combine(root, "docs", "config-catalog");
        Directory.CreateDirectory(output);

        var clients = new[]
        {
            new ClientConfig("jp-1.4.0", Path.Combine(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config")),
            new ClientConfig("cn-1.5.20", Path.Combine(root, "苍蓝誓约", "clsy", "clsy_Data", "StreamingAssets", "config"))
        };

        var results = new List<ClientResult>();
        foreach (var client in clients)
            results.Add(AnalyzeClient(client));

        var rewardTypes = clients.Select(AnalyzeRewardTypes).ToList();
        var differences = AnalyzeDifferences(clients[0], clients[1], results[0], results[1]);
        var catalog = new ConfigCatalog("1.2", DateTimeOffset.UtcNow, XorKey, results, rewardTypes, differences);
        var jsonOptions = new JsonSerializerOptions { WriteIndented = true };
        await File.WriteAllTextAsync(Path.Combine(output, "catalog.json"),
            JsonSerializer.Serialize(catalog, jsonOptions), new UTF8Encoding(false));
        await WriteCsvAsync(Path.Combine(output, "tables.csv"), results);
        await WriteDifferencesCsvAsync(Path.Combine(output, "cross-version-differences.csv"), differences);
        await File.WriteAllTextAsync(Path.Combine(output, "README.zh-CN.md"),
            BuildReport(catalog), new UTF8Encoding(false));

        Console.WriteLine(JsonSerializer.Serialize(new
        {
            complete = true,
            output = Path.GetFullPath(output),
            clients = results.Select(x => new
            {
                x.Id,
                tables = x.Tables.Count,
                rows = x.Tables.Sum(t => t.RowCount),
                validJson = x.Tables.Sum(t => t.ValidJsonCount),
                invalid = x.Tables.Sum(t => t.InvalidCount)
            })
        }));
        return results.Any(x => x.Tables.Any(t => t.InvalidCount > 0)) ? 2 : 0;
    }

    private static int Query(string root, string query)
    {
        var parts = query.Split(':', 3, StringSplitOptions.TrimEntries);
        if (parts.Length != 3) throw new ArgumentException("--config-query expects <jp|cn>:<table>:<id>");
        var clientRoot = parts[0].ToLowerInvariant() switch
        {
            "jp" => Path.Combine(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"),
            "cn" => Path.Combine(root, "苍蓝誓约", "clsy", "clsy_Data", "StreamingAssets", "config"),
            _ => throw new ArgumentException("Config client must be jp or cn")
        };
        if (!parts[1].StartsWith("config_", StringComparison.Ordinal) ||
            parts[1].IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
            throw new ArgumentException("Config table must be a config_* database name without extension");
        var path = Path.Combine(clientRoot, parts[1] + ".db");
        if (!File.Exists(path)) throw new FileNotFoundException("Config database not found", path);

        var builder = new SqliteConnectionStringBuilder { DataSource = path, Mode = SqliteOpenMode.ReadOnly, Pooling = false };
        using var connection = new SqliteConnection(builder.ConnectionString);
        connection.Open();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT id, indexid, jsonbytes FROM DBObject WHERE CAST(id AS TEXT) = $id ORDER BY indexid";
        command.Parameters.AddWithValue("$id", parts[2]);
        using var reader = command.ExecuteReader();
        var found = false;
        while (reader.Read())
        {
            found = true;
            var id = reader.IsDBNull(0) ? null : Convert.ToString(reader.GetValue(0));
            var indexId = reader.IsDBNull(1) ? null : Convert.ToString(reader.GetValue(1));
            var decoded = Xor(ReadBytes(reader, 2));
            using var document = JsonDocument.Parse(decoded);
            Console.WriteLine(JsonSerializer.Serialize(new
            {
                client = parts[0].ToLowerInvariant(),
                table = parts[1],
                id,
                indexId,
                data = document.RootElement
            }));
        }
        if (!found) Console.Error.WriteLine($"No row found for {parts[1]} id={parts[2]}");
        return found ? 0 : 3;
    }

    private static int Search(string root, string search)
    {
        var parts = search.Split(':', 4, StringSplitOptions.TrimEntries);
        if (parts.Length != 4) throw new ArgumentException("--config-search expects <jp|cn>:<table|*>:<field>:<json-value>");
        var clientRoot = ClientConfigRoot(root, parts[0]);
        using var expectedDocument = JsonDocument.Parse(parts[3]);
        var expected = expectedDocument.RootElement;
        var paths = parts[1] == "*"
            ? Directory.EnumerateFiles(clientRoot, "config_*.db")
            : [Path.Combine(clientRoot, parts[1] + ".db")];
        var matches = 0;
        foreach (var path in paths.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
        {
            if (!File.Exists(path)) continue;
            var builder = new SqliteConnectionStringBuilder { DataSource = path, Mode = SqliteOpenMode.ReadOnly, Pooling = false };
            using var connection = new SqliteConnection(builder.ConnectionString);
            connection.Open();
            using var command = connection.CreateCommand();
            command.CommandText = "SELECT id, indexid, jsonbytes FROM DBObject WHERE CAST(id AS TEXT) <> 'nill' ORDER BY id, indexid";
            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                using var document = JsonDocument.Parse(Xor(ReadBytes(reader, 2)));
                if (document.RootElement.ValueKind != JsonValueKind.Object ||
                    !document.RootElement.TryGetProperty(parts[2], out var actual) || !JsonEquals(actual, expected)) continue;
                matches++;
                Console.WriteLine(JsonSerializer.Serialize(new
                {
                    client = parts[0].ToLowerInvariant(),
                    table = Path.GetFileNameWithoutExtension(path),
                    id = reader.IsDBNull(0) ? null : Convert.ToString(reader.GetValue(0)),
                    indexId = reader.IsDBNull(1) ? null : Convert.ToString(reader.GetValue(1)),
                    data = document.RootElement
                }));
            }
        }
        if (matches == 0) Console.Error.WriteLine($"No rows found where {parts[2]}={parts[3]}");
        return matches > 0 ? 0 : 3;
    }

    private static bool JsonEquals(JsonElement left, JsonElement right) =>
        left.ValueKind == right.ValueKind && left.GetRawText() == right.GetRawText();

    private static string ClientConfigRoot(string root, string client) => client.ToLowerInvariant() switch
    {
        "jp" => Path.Combine(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"),
        "cn" => Path.Combine(root, "苍蓝誓约", "clsy", "clsy_Data", "StreamingAssets", "config"),
        _ => throw new ArgumentException("Config client must be jp or cn")
    };

    private static ClientResult AnalyzeClient(ClientConfig client)
    {
        if (!Directory.Exists(client.ConfigRoot))
            throw new DirectoryNotFoundException($"Config directory not found: {client.ConfigRoot}");

        var tables = new List<TableResult>();
        foreach (var path in Directory.EnumerateFiles(client.ConfigRoot, "config_*.db").OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
            tables.Add(AnalyzeDatabase(path));
        return new ClientResult(client.Id, client.ConfigRoot, tables);
    }

    private static ClientRewardAnalysis AnalyzeRewardTypes(ClientConfig client)
    {
        var candidates = new[]
        {
            new RewardTarget("item", "config_item_info", "id"),
            new RewardTarget("equipment", "config_equip", "e_id"),
            new RewardTarget("ship", "config_ship_main", "sm_id"),
            new RewardTarget("currency", "config_currency", "id"),
            new RewardTarget("fashion", "config_fashion", "id"),
            new RewardTarget("player_head_frame", "config_player_head_frame", "id"),
            new RewardTarget("interaction_item", "config_interaction_item_bag", "id")
        };
        var targetKeys = candidates.ToDictionary(x => x, x => ReadJsonKeys(
            Path.Combine(client.ConfigRoot, x.Table + ".db"), x.Field));
        var references = new Dictionary<int, List<long>>();
        foreach (var row in ReadJsonRows(Path.Combine(client.ConfigRoot, "config_rewards.db")))
        {
            if (!row.TryGetProperty("rewards", out var rewards) || rewards.ValueKind != JsonValueKind.Array) continue;
            foreach (var reward in rewards.EnumerateArray())
            {
                if (reward.ValueKind != JsonValueKind.Array || reward.GetArrayLength() < 2) continue;
                var values = reward.EnumerateArray().ToArray();
                if (!values[0].TryGetInt32(out var type) || !values[1].TryGetInt64(out var target)) continue;
                if (!references.TryGetValue(type, out var targets)) references[type] = targets = [];
                targets.Add(target);
            }
        }

        var types = new List<RewardTypeResult>();
        foreach (var (type, targets) in references.OrderBy(x => x.Key))
        {
            var matches = candidates.Select(candidate => new RewardTargetMatch(candidate.Semantic,
                    candidate.Table, candidate.Field, targets.Count(x => targetKeys[candidate].Contains(x))))
                .Where(x => x.MatchCount > 0).OrderByDescending(x => x.MatchCount).ThenBy(x => x.Table).ToList();
            var best = matches.FirstOrDefault();
            var unresolved = targets.Where(target => best is null || !targetKeys[candidates.First(x =>
                    x.Table == best.Table && x.Field == best.Field)].Contains(target))
                .Distinct().Take(20).ToList();
            types.Add(new RewardTypeResult(type, targets.Count, targets.Distinct().Count(),
                best?.Semantic, best is null ? 0 : (double)best.MatchCount / targets.Count,
                matches, unresolved));
        }
        return new ClientRewardAnalysis(client.Id, types);
    }

    private static CrossVersionDifferences AnalyzeDifferences(ClientConfig japan, ClientConfig china,
        ClientResult japanResult, ClientResult chinaResult)
    {
        var japanTables = japanResult.Tables.ToDictionary(x => x.Name, StringComparer.Ordinal);
        var chinaTables = chinaResult.Tables.ToDictionary(x => x.Name, StringComparer.Ordinal);
        var names = japanTables.Keys.Union(chinaTables.Keys, StringComparer.Ordinal).OrderBy(x => x, StringComparer.Ordinal);
        var tables = new List<TableDifference>();
        foreach (var name in names)
        {
            if (!japanTables.TryGetValue(name, out var jp))
            {
                tables.Add(new TableDifference(name, "cn-only", 0, chinaTables[name].ValidJsonCount,
                    0, 0, 0, [], chinaTables[name].Fields, chinaTables[name].ValidJsonCount));
                continue;
            }
            if (!chinaTables.TryGetValue(name, out var cn))
            {
                tables.Add(new TableDifference(name, "jp-only", jp.ValidJsonCount, 0,
                    0, 0, 0, jp.Fields, [], null));
                continue;
            }
            var jpRows = ReadRowHashes(Path.Combine(japan.ConfigRoot, name + ".db"));
            var cnRows = ReadRowHashes(Path.Combine(china.ConfigRoot, name + ".db"));
            var common = jpRows.Keys.Intersect(cnRows.Keys, StringComparer.Ordinal).ToArray();
            var identical = common.Count(key => jpRows[key] == cnRows[key]);
            var changed = common.Length - identical;
            var jpOnly = jpRows.Keys.Except(cnRows.Keys, StringComparer.Ordinal).Count();
            var cnOnly = cnRows.Keys.Except(jpRows.Keys, StringComparer.Ordinal).Count();
            var fieldsJpOnly = jp.Fields.Except(cn.Fields, StringComparer.Ordinal).ToList();
            var fieldsCnOnly = cn.Fields.Except(jp.Fields, StringComparer.Ordinal).ToList();
            var status = fieldsJpOnly.Count > 0 || fieldsCnOnly.Count > 0 ? "schema-different" :
                jpOnly > 0 || cnOnly > 0 ? "records-different" : changed > 0 ? "content-different" : "identical";
            tables.Add(new TableDifference(name, status, jpRows.Count, cnRows.Count, identical, changed,
                jpOnly, fieldsJpOnly, fieldsCnOnly, cnOnly));
        }
        return new CrossVersionDifferences(tables);
    }

    private static Dictionary<string, string> ReadRowHashes(string path)
    {
        var rows = new Dictionary<string, string>(StringComparer.Ordinal);
        var builder = new SqliteConnectionStringBuilder { DataSource = path, Mode = SqliteOpenMode.ReadOnly, Pooling = false };
        using var connection = new SqliteConnection(builder.ConnectionString);
        connection.Open();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT id, indexid, jsonbytes FROM DBObject WHERE CAST(id AS TEXT) <> 'nill'";
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            var id = reader.IsDBNull(0) ? string.Empty : Convert.ToString(reader.GetValue(0)) ?? string.Empty;
            var indexId = reader.IsDBNull(1) ? string.Empty : Convert.ToString(reader.GetValue(1)) ?? string.Empty;
            rows[id + "\u001f" + indexId] = Convert.ToHexString(SHA256.HashData(Xor(ReadBytes(reader, 2))));
        }
        return rows;
    }

    private static HashSet<long> ReadJsonKeys(string path, string field)
    {
        var keys = new HashSet<long>();
        if (!File.Exists(path)) return keys;
        foreach (var row in ReadJsonRows(path))
            if (row.TryGetProperty(field, out var value) && value.TryGetInt64(out var key)) keys.Add(key);
        return keys;
    }

    private static IEnumerable<JsonElement> ReadJsonRows(string path)
    {
        var builder = new SqliteConnectionStringBuilder { DataSource = path, Mode = SqliteOpenMode.ReadOnly, Pooling = false };
        using var connection = new SqliteConnection(builder.ConnectionString);
        connection.Open();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT jsonbytes FROM DBObject WHERE CAST(id AS TEXT) <> 'nill'";
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            using var document = JsonDocument.Parse(Xor(ReadBytes(reader, 0)));
            yield return document.RootElement.Clone();
        }
    }

    private static TableResult AnalyzeDatabase(string path)
    {
        var fields = new SortedSet<string>(StringComparer.Ordinal);
        var samples = new List<RowSample>();
        var rowCount = 0;
        var metadataCount = 0;
        var validJson = 0;
        var invalid = 0;
        string? firstError = null;

        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = path,
            Mode = SqliteOpenMode.ReadOnly,
            Pooling = false
        };
        using var connection = new SqliteConnection(builder.ConnectionString);
        connection.Open();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT id, indexid, jsonbytes FROM DBObject ORDER BY id, indexid";
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            rowCount++;
            var id = reader.IsDBNull(0) ? null : Convert.ToString(reader.GetValue(0));
            var indexId = reader.IsDBNull(1) ? null : Convert.ToString(reader.GetValue(1));
            var encoded = ReadBytes(reader, 2);
            var decoded = Xor(encoded);
            if (string.Equals(id, "nill", StringComparison.OrdinalIgnoreCase))
            {
                metadataCount++;
                continue;
            }
            try
            {
                using var document = JsonDocument.Parse(decoded);
                validJson++;
                if (document.RootElement.ValueKind == JsonValueKind.Object)
                    foreach (var property in document.RootElement.EnumerateObject()) fields.Add(property.Name);
                if (samples.Count < 3)
                    samples.Add(new RowSample(id, indexId, encoded.Length, Preview(document.RootElement)));
            }
            catch (Exception exception) when (exception is JsonException or DecoderFallbackException)
            {
                invalid++;
                firstError ??= $"row id={id}, indexid={indexId}: {exception.Message}";
            }
        }

        return new TableResult(Path.GetFileNameWithoutExtension(path), Path.GetFileName(path),
            Sha256(path), rowCount, metadataCount, validJson, invalid, fields.ToList(), samples, firstError);
    }

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

    internal static byte[] Xor(ReadOnlySpan<byte> source)
    {
        var result = new byte[source.Length];
        for (var index = 0; index < source.Length; index++) result[index] = (byte)(source[index] ^ XorKey);
        return result;
    }

    private static string Preview(JsonElement element)
    {
        var json = element.GetRawText();
        return json.Length <= 2000 ? json : json[..2000] + "...";
    }

    private static string Sha256(string path)
    {
        using var stream = File.OpenRead(path);
        return Convert.ToHexString(SHA256.HashData(stream));
    }

    private static async Task WriteCsvAsync(string path, IEnumerable<ClientResult> clients)
    {
        var lines = new List<string> { "client,table,file,sha256,rows,metadataRows,validJson,invalid,fields,firstError" };
        foreach (var client in clients)
            foreach (var table in client.Tables)
                lines.Add(string.Join(',', Csv(client.Id), Csv(table.Name), Csv(table.File), Csv(table.Sha256),
                    table.RowCount, table.MetadataCount, table.ValidJsonCount, table.InvalidCount, Csv(string.Join(';', table.Fields)), Csv(table.FirstError)));
        await File.WriteAllLinesAsync(path, lines, new UTF8Encoding(false));
    }

    private static async Task WriteDifferencesCsvAsync(string path, CrossVersionDifferences differences)
    {
        var lines = new List<string>
        {
            "table,status,jpRows,cnRows,identicalRows,changedRows,jpOnlyRows,cnOnlyRows,jpOnlyFields,cnOnlyFields"
        };
        foreach (var table in differences.Tables)
            lines.Add(string.Join(',', Csv(table.Table), Csv(table.Status), table.JapanRows, table.ChinaRows,
                table.IdenticalRows, table.ChangedRows, table.JapanOnlyRows, table.ChinaOnlyRows ?? 0,
                Csv(string.Join(';', table.JapanOnlyFields)), Csv(string.Join(';', table.ChinaOnlyFields))));
        await File.WriteAllLinesAsync(path, lines, new UTF8Encoding(false));
    }

    private static string BuildReport(ConfigCatalog catalog)
    {
        var report = new StringBuilder();
        report.AppendLine("# 苍蓝誓约客户端配置目录");
        report.AppendLine();
        report.AppendLine($"> 生成时间 `{catalog.GeneratedUtc:O}`。所有数据库均以只读方式访问，原始客户端文件未修改。");
        report.AppendLine();
        report.AppendLine("## 已确认的解码规则");
        report.AppendLine();
        report.AppendLine("`DBObject.jsonbytes` 的每个字节与 `0x55` 异或后解析为 JSON：");
        report.AppendLine();
        report.AppendLine("```text");
        report.AppendLine("decoded[i] = encoded[i] XOR 0x55");
        report.AppendLine("```");
        report.AppendLine();
        report.AppendLine("## 扫描结果");
        report.AppendLine();
        report.AppendLine("| 客户端 | 数据库 | 总行数 | 元数据行 | 有效 JSON | 解码失败 |");
        report.AppendLine("| --- | ---: | ---: | ---: | ---: | ---: |");
        foreach (var client in catalog.Clients)
            report.AppendLine($"| `{client.Id}` | {client.Tables.Count} | {client.Tables.Sum(x => x.RowCount)} | {client.Tables.Sum(x => x.MetadataCount)} | {client.Tables.Sum(x => x.ValidJsonCount)} | {client.Tables.Sum(x => x.InvalidCount)} |");
        report.AppendLine();
        report.AppendLine("## 奖励类型推断");
        report.AppendLine();
        foreach (var client in catalog.RewardTypes)
        {
            report.AppendLine($"### {client.Client}");
            report.AppendLine();
            report.AppendLine("| 类型 | 引用数 | 不同目标 | 最佳语义 | 覆盖率 | 未解析样本 |");
            report.AppendLine("| ---: | ---: | ---: | --- | ---: | --- |");
            foreach (var type in client.Types)
                report.AppendLine($"| {type.Type} | {type.ReferenceCount} | {type.DistinctTargetCount} | `{type.BestSemantic ?? "unresolved"}` | {type.BestCoverage:P1} | `{string.Join(", ", type.UnresolvedSamples)}` |");
            report.AppendLine();
        }
        report.AppendLine("## 日服/国服差异摘要");
        report.AppendLine();
        report.AppendLine("| 状态 | 表数量 |");
        report.AppendLine("| --- | ---: |");
        foreach (var group in catalog.Differences.Tables.GroupBy(x => x.Status).OrderBy(x => x.Key))
            report.AppendLine($"| `{group.Key}` | {group.Count()} |");
        report.AppendLine();
        report.AppendLine($"- 日服独有业务记录：{catalog.Differences.Tables.Sum(x => x.JapanOnlyRows)}");
        report.AppendLine($"- 国服独有业务记录：{catalog.Differences.Tables.Sum(x => x.ChinaOnlyRows ?? 0)}");
        report.AppendLine($"- 两服键相同但内容不同：{catalog.Differences.Tables.Sum(x => x.ChangedRows)}");
        report.AppendLine($"- 两服完全相同记录：{catalog.Differences.Tables.Sum(x => x.IdenticalRows)}");
        report.AppendLine();
        report.AppendLine("完整逐表差异见 `cross-version-differences.csv` 和 `catalog.json`。");
        report.AppendLine();
        report.AppendLine("## 首期关卡相关表");
        report.AppendLine();
        foreach (var client in catalog.Clients)
        {
            report.AppendLine($"### {client.Id}");
            report.AppendLine();
            foreach (var table in client.Tables.Where(x => x.Name is "config_copy" or "config_chapter" or "config_copy_enemy" or "config_ship" or "config_ship_enemy"))
                report.AppendLine($"- `{table.Name}`：{table.RowCount} 行（含 {table.MetadataCount} 行元数据），{table.ValidJsonCount} 行有效 JSON；字段 `{string.Join("`, `", table.Fields)}`");
            report.AppendLine();
        }
        report.AppendLine("完整逐表结果见 `tables.csv`，机器可读字段与样本见 `catalog.json`。");
        report.AppendLine();
        report.AppendLine("## 首个离线闭环基准关卡");
        report.AppendLine();
        report.AppendLine("当前固定序章 `0-4`（日服“初阵”、国服“初战”）作为首个战斗基准。两服关键 ID 一致、等级限制为 1，普通分支只有一个敌方舰队和一艘敌舰。");
        report.AppendLine();
        report.AppendLine("```text");
        report.AppendLine("config_chapter 1 -> level_list 包含 4");
        report.AppendLine("config_copy_display 4 -> copy_index 0-4, first_reward 509035");
        report.AppendLine("config_copy 40 -> scene_id 10000, fleet_id [200401]");
        report.AppendLine("config_fleet 200401 -> copy_enemys [100000]");
        report.AppendLine("config_ship_enemy 100000 -> level 1, hp 238, attack 1, defense 5");
        report.AppendLine("config_assist_fleet 1 -> formation 1, assist_ship_info [10002101]");
        report.AppendLine("config_assist_ship_info 10002101 -> level 10 story-only Oakland");
        report.AppendLine("config_rewards 509035 -> ship reward [[3, 20210111, 1]] -> 天龙 x1");
        report.AppendLine("```");
        report.AppendLine();
        report.AppendLine("完整机器可读定义见 `baseline-stage.json`。类型 `1/2/3/5` 已分别以 100% 目标表覆盖率映射为道具、装备、船只和货币。");
        return report.ToString();
    }

    private static string Csv(string? value) => '"' + (value ?? string.Empty).Replace("\"", "\"\"") + '"';

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

    private static string? ReadArg(IEnumerable<string> args, string prefix) =>
        args.FirstOrDefault(x => x.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))?[prefix.Length..];

    private sealed record ClientConfig(string Id, string ConfigRoot);
    private sealed record ConfigCatalog(string SchemaVersion, DateTimeOffset GeneratedUtc, byte XorKey,
        List<ClientResult> Clients, List<ClientRewardAnalysis> RewardTypes, CrossVersionDifferences Differences);
    private sealed record ClientResult(string Id, string ConfigRoot, List<TableResult> Tables);
    private sealed record TableResult(string Name, string File, string Sha256, int RowCount, int MetadataCount, int ValidJsonCount,
        int InvalidCount, List<string> Fields, List<RowSample> Samples, string? FirstError);
    private sealed record RowSample(string? Id, string? IndexId, int EncodedBytes, string JsonPreview);
    private sealed record RewardTarget(string Semantic, string Table, string Field);
    private sealed record ClientRewardAnalysis(string Client, List<RewardTypeResult> Types);
    private sealed record RewardTypeResult(int Type, int ReferenceCount, int DistinctTargetCount,
        string? BestSemantic, double BestCoverage, List<RewardTargetMatch> Matches, List<long> UnresolvedSamples);
    private sealed record RewardTargetMatch(string Semantic, string Table, string Field, int MatchCount);
    private sealed record CrossVersionDifferences(List<TableDifference> Tables);
    private sealed record TableDifference(string Table, string Status, int JapanRows, int ChinaRows,
        int IdenticalRows, int ChangedRows, int JapanOnlyRows, List<string> JapanOnlyFields,
        List<string> ChinaOnlyFields, int? ChinaOnlyRows);
}
