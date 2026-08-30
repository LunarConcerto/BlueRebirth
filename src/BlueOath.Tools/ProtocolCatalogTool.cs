using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

static partial class ProtocolCatalogTool
{
    private const string SchemaVersion = "1.2";

    public static async Task<int> RunAsync(string[] args)
    {
        var root = FindRoot();
        var output = ReadArg(args, "--catalog-output=") ?? Path.Combine(root, "docs", "protocol-catalog");
        output = Path.GetFullPath(output);
        Directory.CreateDirectory(output);

        var clients = new[]
        {
            AnalyzeClient("jp-1.4.0", "Japan", "1.4.0",
                Path.Combine(root, "blueoath", "blueoath")),
            AnalyzeClient("cn-1.5.20", "China", "1.5.20",
                Path.Combine(root, "苍蓝誓约", "clsy"))
        };
        var events = AnalyzeSdkEvents(root);
        var endpoints = AnalyzeCaptures(root);
        var catalog = BuildCatalog(clients, events, endpoints);

        var jsonOptions = new JsonSerializerOptions { WriteIndented = true };
        await File.WriteAllTextAsync(Path.Combine(output, "catalog.json"),
            JsonSerializer.Serialize(catalog, jsonOptions), new UTF8Encoding(false));
        await WriteEventsCsvAsync(Path.Combine(output, "sdk-events.csv"), events);
        await WriteMessagesCsvAsync(Path.Combine(output, "message-candidates.csv"), clients);
        foreach (var client in clients)
            await File.WriteAllTextAsync(Path.Combine(output, client.Id + ".proto"),
                BuildProtoDraft(client), new UTF8Encoding(false));
        await File.WriteAllTextAsync(Path.Combine(output, "adapter-template.json"),
            JsonSerializer.Serialize(BuildAdapterTemplate(clients), jsonOptions), new UTF8Encoding(false));
        await File.WriteAllTextAsync(Path.Combine(output, "README.md"),
            BuildReport(catalog), new UTF8Encoding(false));
        await File.WriteAllTextAsync(Path.Combine(output, "README.zh-CN.md"),
            BuildChineseReport(catalog), new UTF8Encoding(false));

        Console.WriteLine(JsonSerializer.Serialize(new
        {
            complete = true,
            schemaVersion = SchemaVersion,
            output,
            clients = clients.Select(x => new { x.Id, messages = x.Messages.Count, symbols = x.Symbols.Count }),
            sdkEvents = events.Count,
            httpEndpoints = endpoints.Count
        }));
        return 0;
    }

    private static ClientCatalog AnalyzeClient(string id, string region, string version, string clientRoot)
    {
        var dataName = region == "Japan" ? "blueoath_Data" : "clsy_Data";
        var assembly = Path.Combine(clientRoot, "GameAssembly.dll");
        var metadata = Path.Combine(clientRoot, dataName, "il2cpp_data", "Metadata", "global-metadata.dat");
        var metadataStrings = ExtractStrings(metadata, 3).Distinct(StringComparer.Ordinal).ToArray();
        var assemblyStrings = ExtractStrings(assembly, 4).Distinct(StringComparer.Ordinal).ToArray();
        var all = metadataStrings.Concat(assemblyStrings).Distinct(StringComparer.Ordinal).ToArray();
        var typeFields = ReadV24TypeFields(metadata);
        var properties = ReadV24TypeProperties(metadata);
        var resolvedTypes = Il2CppMetadataTool.ResolveTypes(assembly, metadata,
            typeFields.Values.SelectMany(x => x).Select(x => x.TypeIndex)
                .Concat(properties.Values.SelectMany(x => x).SelectMany(x => x.AttributeTypeIndices)));
        foreach (var fields in typeFields.Values)
            for (var index = 0; index < fields.Count; index++)
            {
                var field = fields[index];
                if (resolvedTypes.TryGetValue(field.TypeIndex, out var resolved))
                    fields[index] = field with
                    {
                        TypeName = resolved.Name,
                        TypeKind = resolved.Kind,
                        TypeConfidence = resolved.Confidence,
                        TypeDefinitionIndex = resolved.TypeDefinitionIndex
                    };
            }
        ApplyPropertyEvidence(typeFields, properties, resolvedTypes);

        var messageNames = all.Where(IsMessageName).OrderBy(x => x, StringComparer.Ordinal).ToArray();
        var parameterNames = all.Where(IsParameterName).OrderBy(x => x, StringComparer.Ordinal).ToArray();
        var messages = messageNames.Select(name => BuildMessage(name, messageNames, parameterNames,
            typeFields.TryGetValue(name, out var fields) ? fields : [])).ToList();
        var symbols = all.Where(IsProtocolSymbol).OrderBy(x => x, StringComparer.Ordinal).ToList();
        var hosts = all.Where(x => HostRegex().IsMatch(x)).OrderBy(x => x, StringComparer.OrdinalIgnoreCase).ToList();
        var paths = all.Where(x => x.StartsWith('/') && x.Length < 160 &&
            (x.Contains("phone", StringComparison.OrdinalIgnoreCase) ||
             x.Contains("sdk", StringComparison.OrdinalIgnoreCase) ||
             x.Contains("login", StringComparison.OrdinalIgnoreCase)))
            .OrderBy(x => x, StringComparer.Ordinal).ToList();

        return new ClientCatalog(id, region, version, "x86", Hash(assembly), Hash(metadata),
            messages, symbols, hosts, paths, metadataStrings.Length, assemblyStrings.Length);
    }

    private static MessageCandidate BuildMessage(string name, IReadOnlyCollection<string> names,
        IReadOnlyCollection<string> parameters, List<FieldEvidence> fields)
    {
        var direction = name.StartsWith("TArg", StringComparison.Ordinal) ? "C2S/request" :
            name.StartsWith("TRet", StringComparison.Ordinal) ? "S2C/response" :
            name.StartsWith("S2C", StringComparison.OrdinalIgnoreCase) ? "S2C/push" : "unknown";
        var stem = Regex.Replace(name, "^(TArg|TRet|S2C|C2S)", string.Empty, RegexOptions.IgnoreCase);
        var pairPrefix = direction.StartsWith("C2S", StringComparison.Ordinal) ? "TRet" : "TArg";
        var pair = names.FirstOrDefault(x => x.Equals(pairPrefix + stem, StringComparison.Ordinal));
        var tokens = SplitIdentifier(stem).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var likely = parameters.Where(p =>
        {
            var lower = p.ToLowerInvariant();
            return tokens.Any(t => t.Length >= 4 && lower.Contains(t.ToLowerInvariant(), StringComparison.Ordinal));
        }).Take(12).ToList();
        var actualFields = fields.Select(x => x.Name).ToList();
        var evidence = fields.Count > 0 ? "inferred" : pair is null ? "candidate" : "inferred";
        var confidence = fields.Count > 0 ? 0.85 : pair is null ? 0.35 : 0.65;
        var source = fields.Count > 0
            ? "IL2CPP v24 type definition and field ranges; wire numbers/types remain unresolved"
            : "IL2CPP metadata/binary string table";
        return new MessageCandidate(name, stem, direction, pair, actualFields, fields, likely,
            evidence, confidence, source);
    }

    private static Dictionary<string, List<FieldEvidence>> ReadV24TypeFields(string path)
    {
        var bytes = File.ReadAllBytes(path);
        if (bytes.Length < 0x110 || BitConverter.ToUInt32(bytes, 0) != 0xFAB11BAF ||
            BitConverter.ToInt32(bytes, 4) != 24) return new(StringComparer.Ordinal);
        var stringOffset = BitConverter.ToInt32(bytes, 8 + 2 * 8);
        var stringSize = BitConverter.ToInt32(bytes, 8 + 2 * 8 + 4);
        var fieldsOffset = BitConverter.ToInt32(bytes, 8 + 11 * 8);
        var fieldsSize = BitConverter.ToInt32(bytes, 8 + 11 * 8 + 4);
        var typesOffset = BitConverter.ToInt32(bytes, 8 + 19 * 8);
        var typesSize = BitConverter.ToInt32(bytes, 8 + 19 * 8 + 4);
        const int typeSize = 104;
        const int fieldSize = 16;
        if (typesSize % typeSize != 0 || fieldsSize % fieldSize != 0) return new(StringComparer.Ordinal);

        string ReadString(int index)
        {
            if (index < 0 || index >= stringSize) return string.Empty;
            var start = stringOffset + index;
            var end = start;
            while (end < stringOffset + stringSize && bytes[end] != 0) end++;
            return Encoding.UTF8.GetString(bytes, start, end - start);
        }

        var defaultValueIndices = ReadFieldDefaultValueIndices(bytes);
        var result = new Dictionary<string, List<FieldEvidence>>(StringComparer.Ordinal);
        for (var offset = typesOffset; offset < typesOffset + typesSize; offset += typeSize)
        {
            var name = ReadString(BitConverter.ToInt32(bytes, offset));
            if (!IsMessageName(name)) continue;
            var fieldStart = BitConverter.ToInt32(bytes, offset + 48);
            var fieldCount = BitConverter.ToUInt16(bytes, offset + 84);
            if (fieldStart < 0 || fieldCount > 256 || fieldStart + fieldCount > fieldsSize / fieldSize) continue;
            var fields = new List<FieldEvidence>(fieldCount);
            for (var index = 0; index < fieldCount; index++)
            {
                var fieldDefinitionIndex = fieldStart + index;
                var fieldOffset = fieldsOffset + fieldDefinitionIndex * fieldSize;
                var fieldName = ReadString(BitConverter.ToInt32(bytes, fieldOffset));
                var typeIndex = BitConverter.ToInt32(bytes, fieldOffset + 4);
                if (!string.IsNullOrWhiteSpace(fieldName))
                    fields.Add(new FieldEvidence(fieldName, fieldDefinitionIndex, typeIndex,
                        defaultValueIndices.GetValueOrDefault(fieldDefinitionIndex, -1)));
            }
            result[name] = fields;
        }
        return result;
    }

    private static Dictionary<int, int> ReadFieldDefaultValueIndices(byte[] bytes)
    {
        var offset = BitConverter.ToInt32(bytes, 8 + 7 * 8);
        var size = BitConverter.ToInt32(bytes, 8 + 7 * 8 + 4);
        const int recordSize = 12;
        var result = new Dictionary<int, int>();
        if (offset < 0 || size < 0 || size % recordSize != 0 || offset + size > bytes.Length) return result;
        for (var position = offset; position < offset + size; position += recordSize)
            result[BitConverter.ToInt32(bytes, position)] = BitConverter.ToInt32(bytes, position + 8);
        return result;
    }

    private static Dictionary<string, List<PropertyEvidence>> ReadV24TypeProperties(string path)
    {
        var bytes = File.ReadAllBytes(path);
        var stringOffset = BitConverter.ToInt32(bytes, 8 + 2 * 8);
        var stringSize = BitConverter.ToInt32(bytes, 8 + 2 * 8 + 4);
        var propertiesOffset = BitConverter.ToInt32(bytes, 8 + 4 * 8);
        var propertiesSize = BitConverter.ToInt32(bytes, 8 + 4 * 8 + 4);
        var typesOffset = BitConverter.ToInt32(bytes, 8 + 19 * 8);
        var typesSize = BitConverter.ToInt32(bytes, 8 + 19 * 8 + 4);
        var attributeRangesOffset = BitConverter.ToInt32(bytes, 8 + 27 * 8);
        var attributeRangesSize = BitConverter.ToInt32(bytes, 8 + 27 * 8 + 4);
        var attributeTypesOffset = BitConverter.ToInt32(bytes, 8 + 28 * 8);
        var attributeTypesSize = BitConverter.ToInt32(bytes, 8 + 28 * 8 + 4);
        const int typeSize = 104;
        const int propertySize = 24;
        string ReadString(int index)
        {
            if (index < 0 || index >= stringSize) return string.Empty;
            var start = stringOffset + index;
            var end = start;
            while (end < stringOffset + stringSize && bytes[end] != 0) end++;
            return Encoding.UTF8.GetString(bytes, start, end - start);
        }
        var result = new Dictionary<string, List<PropertyEvidence>>(StringComparer.Ordinal);
        for (var offset = typesOffset; offset < typesOffset + typesSize; offset += typeSize)
        {
            var typeName = ReadString(BitConverter.ToInt32(bytes, offset));
            if (!IsMessageName(typeName)) continue;
            var propertyStart = BitConverter.ToInt32(bytes, offset + 60);
            var propertyCount = BitConverter.ToUInt16(bytes, offset + 82);
            if (propertyStart < 0 || propertyCount > 256 ||
                propertyStart + propertyCount > propertiesSize / propertySize) continue;
            var items = new List<PropertyEvidence>(propertyCount);
            for (var index = 0; index < propertyCount; index++)
            {
                var propertyOffset = propertiesOffset + (propertyStart + index) * propertySize;
                var name = ReadString(BitConverter.ToInt32(bytes, propertyOffset));
                var customAttributeIndex = BitConverter.ToInt32(bytes, propertyOffset + 16);
                var attributeTypes = new List<int>();
                if (customAttributeIndex >= 0 && customAttributeIndex < attributeRangesSize / 8)
                {
                    var rangeOffset = attributeRangesOffset + customAttributeIndex * 8;
                    var attributeStart = BitConverter.ToInt32(bytes, rangeOffset);
                    var attributeCount = BitConverter.ToInt32(bytes, rangeOffset + 4);
                    if (attributeStart >= 0 && attributeCount >= 0 &&
                        attributeStart + attributeCount <= attributeTypesSize / 4)
                        for (var attribute = 0; attribute < attributeCount; attribute++)
                            attributeTypes.Add(BitConverter.ToInt32(bytes,
                                attributeTypesOffset + (attributeStart + attribute) * 4));
                }
                items.Add(new PropertyEvidence(name, propertyStart + index, customAttributeIndex, attributeTypes));
            }
            result[typeName] = items;
        }
        return result;
    }

    private static void ApplyPropertyEvidence(Dictionary<string, List<FieldEvidence>> fieldsByType,
        Dictionary<string, List<PropertyEvidence>> propertiesByType,
        IReadOnlyDictionary<int, Il2CppMetadataTool.ResolvedTypeInfo> resolvedTypes)
    {
        foreach (var (typeName, fields) in fieldsByType)
        {
            if (!propertiesByType.TryGetValue(typeName, out var properties)) continue;
            var protocolFields = fields.Where(x => x.Name != "extensionObject").ToList();
            if (protocolFields.Count != properties.Count) continue;
            for (var index = 0; index < protocolFields.Count; index++)
            {
                var field = protocolFields[index];
                var property = properties[index];
                if (!field.Name.TrimStart('_').Equals(property.Name, StringComparison.Ordinal)) continue;
                var attributeNames = property.AttributeTypeIndices
                    .Select(x => resolvedTypes.TryGetValue(x, out var resolved) ? resolved.Name : $"typeIndex:{x}")
                    .ToList();
                var hasProtoMember = attributeNames.Any(x => x.EndsWith("ProtoMemberAttribute",
                    StringComparison.Ordinal));
                var fieldIndex = fields.FindIndex(x => x.FieldDefinitionIndex == field.FieldDefinitionIndex);
                fields[fieldIndex] = field with
                {
                    PropertyName = property.Name,
                    PropertyDefinitionIndex = property.PropertyDefinitionIndex,
                    AttributeTypes = attributeNames,
                    WireTag = hasProtoMember ? index + 1 : null,
                    WireTagEvidence = hasProtoMember ? "inferred-property-order" : null
                };
            }
        }
    }

    private static List<SdkEvent> AnalyzeSdkEvents(string root)
    {
        var observed = new Dictionary<int, HashSet<string>>();
        var captures = Path.Combine(root, "runtime", "captures");
        if (Directory.Exists(captures))
        {
            foreach (var file in Directory.EnumerateFiles(captures, "payload.log", SearchOption.AllDirectories))
            {
                foreach (var line in File.ReadLines(file))
                {
                    var match = EventRegex().Match(line);
                    if (!match.Success) continue;
                    var id = int.Parse(match.Groups[1].Value, CultureInfo.InvariantCulture);
                    if (!observed.TryGetValue(id, out var samples)) observed[id] = samples = new();
                    if (match.Groups[2].Success && samples.Count < 5) samples.Add(match.Groups[2].Value);
                }
            }
        }

        var definitions = new Dictionary<int, (string Name, string Trigger, string[] Parameters)>
        {
            [1] = ("sdk_initialized", "initSDK callback", ["ActionType", "errornu"]),
            [19] = ("apple_review", "getAppleReview", ["errornu", "applereview"]),
            [27] = ("switch_state", "switch/getstate", ["errornu", "errordesc", "DNS_sw.state"]),
            [1007] = ("platform_data", "getPlData/getPlData", ["errornu", "errordesc", "data (shape unresolved)"])
        };
        return definitions.Select(item => new SdkEvent(item.Key, item.Value.Name, item.Value.Trigger,
            item.Value.Parameters, observed.TryGetValue(item.Key, out var samples) ? samples.ToList() : [],
            observed.ContainsKey(item.Key) ? "confirmed" : "inferred",
            observed.ContainsKey(item.Key) ? 0.95 : 0.65)).OrderBy(x => x.Id).ToList();
    }

    private static List<HttpEndpoint> AnalyzeCaptures(string root)
    {
        var results = new Dictionary<string, HttpEndpoint>(StringComparer.OrdinalIgnoreCase);
        var captures = Path.Combine(root, "runtime", "captures");
        if (!Directory.Exists(captures)) return [];
        foreach (var file in Directory.EnumerateFiles(captures, "*.json", SearchOption.AllDirectories))
        {
            try
            {
                using var document = JsonDocument.Parse(File.ReadAllText(file));
                var rootElement = document.RootElement;
                if (!rootElement.TryGetProperty("Kind", out var kind) || kind.GetString() != "http" ||
                    !rootElement.TryGetProperty("Detail", out var detailElement)) continue;
                var detail = detailElement.GetString() ?? string.Empty;
                var match = HttpRegex().Match(detail);
                if (!match.Success) continue;
                var method = match.Groups[1].Value;
                var path = match.Groups[2].Value;
                var host = rootElement.TryGetProperty("ServerName", out var hostElement) ? hostElement.GetString() : null;
                var key = method + " " + path;
                results[key] = new HttpEndpoint(method, path, host, "confirmed", 0.95, Path.GetRelativePath(root, file));
            }
            catch (JsonException) { }
        }
        return results.Values.OrderBy(x => x.Path, StringComparer.Ordinal).ToList();
    }

    private static ProtocolCatalog BuildCatalog(ClientCatalog[] clients, List<SdkEvent> events,
        List<HttpEndpoint> endpoints)
    {
        var jp = clients[0].Messages.Select(x => x.Name).ToHashSet(StringComparer.Ordinal);
        var cn = clients[1].Messages.Select(x => x.Name).ToHashSet(StringComparer.Ordinal);
        return new ProtocolCatalog(SchemaVersion, DateTimeOffset.UtcNow, clients, events, endpoints,
            new CrossVersion(jp.Intersect(cn).OrderBy(x => x).ToList(),
                jp.Except(cn).OrderBy(x => x).ToList(), cn.Except(jp).OrderBy(x => x).ToList()),
            new EvidencePolicy(
                "confirmed: runtime capture or directly observed callback",
                "inferred: paired names or strong static structure",
                "candidate: isolated static string; do not implement without validation"));
    }

    private static object BuildAdapterTemplate(ClientCatalog[] clients) => new
    {
        schemaVersion = SchemaVersion,
        profiles = clients.Select(x => new
        {
            id = x.Id,
            gameAssemblySha256 = x.GameAssemblySha256,
            metadataSha256 = x.MetadataSha256,
            sdkEvents = new Dictionary<string, object>(),
            messageIds = new Dictionary<string, int>(),
            framing = new { status = "unresolved", lengthEndian = (string?)null, headerBytes = (int?)null },
            transforms = new { compression = "unresolved", encryption = "unresolved" },
            capabilities = new Dictionary<string, bool>()
        })
    };

    private static string BuildReport(ProtocolCatalog catalog)
    {
        var b = new StringBuilder();
        b.AppendLine("# Blue Oath protocol and event catalog");
        b.AppendLine();
        b.AppendLine($"> Generated schema `{catalog.SchemaVersion}` at `{catalog.GeneratedUtc:O}`. Static candidates are not wire-level confirmations.");
        b.AppendLine();
        b.AppendLine("## Evidence model");
        b.AppendLine();
        b.AppendLine("- **confirmed**: directly observed in loopback runtime capture or SDK callback logs.");
        b.AppendLine("- **inferred**: supported by paired request/response names or strong static evidence.");
        b.AppendLine("- **candidate**: isolated metadata/binary string requiring call-site or runtime validation.");
        b.AppendLine();
        b.AppendLine("## Coverage");
        b.AppendLine();
        b.AppendLine("| Client | Message candidates | Protocol symbols | Hosts | Metadata strings |");
        b.AppendLine("| --- | ---: | ---: | ---: | ---: |");
        foreach (var client in catalog.Clients)
            b.AppendLine($"| `{client.Id}` | {client.Messages.Count} | {client.Symbols.Count} | {client.Hosts.Count} | {client.MetadataStringCount} |");
        b.AppendLine();
        b.AppendLine("## Confirmed SDK events");
        b.AppendLine();
        b.AppendLine("| ID | Semantic name | Trigger | Parameters | Confidence |");
        b.AppendLine("| ---: | --- | --- | --- | ---: |");
        foreach (var item in catalog.SdkEvents)
            b.AppendLine($"| {item.Id} | `{item.Name}` | `{item.Trigger}` | {string.Join(", ", item.Parameters.Select(x => $"`{x}`"))} | {item.Confidence:P0} |");
        b.AppendLine();
        b.AppendLine("## Confirmed HTTP endpoints");
        b.AppendLine();
        b.AppendLine("| Method | Path | Host | Evidence |");
        b.AppendLine("| --- | --- | --- | --- |");
        foreach (var item in catalog.HttpEndpoints)
            b.AppendLine($"| `{item.Method}` | `{item.Path}` | `{item.Host}` | `{item.EvidenceFile}` |");
        b.AppendLine();
        b.AppendLine("## Cross-version message surface");
        b.AppendLine();
        b.AppendLine($"- Shared: **{catalog.CrossVersion.Shared.Count}**");
        b.AppendLine($"- JP only: **{catalog.CrossVersion.JapanOnly.Count}**");
        b.AppendLine($"- CN only: **{catalog.CrossVersion.ChinaOnly.Count}**");
        b.AppendLine();
        b.AppendLine("See `message-candidates.csv` for the complete list and `catalog.json` for automation.");
        b.AppendLine();
        b.AppendLine("## Highest-value login candidates");
        b.AppendLine();
        foreach (var client in catalog.Clients)
        {
            b.AppendLine($"### {client.Id}");
            b.AppendLine();
            foreach (var message in client.Messages.Where(x =>
                x.Name.Contains("Login", StringComparison.OrdinalIgnoreCase) ||
                x.Name.Contains("Server", StringComparison.OrdinalIgnoreCase) ||
                x.Name.Contains("User", StringComparison.OrdinalIgnoreCase)).Take(80))
                b.AppendLine($"- `{message.Name}`: {message.Direction}; pair `{message.Pair ?? "unresolved"}`; fields `{string.Join(", ", message.ActualFields)}`; {message.Evidence} ({message.Confidence:P0})");
            b.AppendLine();
        }
        b.AppendLine("## Unresolved wire facts");
        b.AppendLine();
        b.AppendLine("- Numeric message IDs and the mapping from IDs to IL2CPP message types.");
        b.AppendLine("- Exact protobuf field numbers/types and required/default semantics.");
        b.AppendLine("- Game TCP/KCP frame header, compression, encryption and sequence fields.");
        b.AppendLine("- Event 1007 `data` object shape and its consuming callback.");
        b.AppendLine();
        b.AppendLine("These must be filled by type-layout extraction and targeted call-site analysis, then recorded in `adapter-template.json` rather than embedded as version checks in game logic.");
        return b.ToString();
    }

    private static string BuildChineseReport(ProtocolCatalog catalog)
    {
        var b = new StringBuilder();
        b.AppendLine("# 某游戏协议与事件目录");
        b.AppendLine();
        b.AppendLine($"> 由只读分析器生成，目录版本 `{catalog.SchemaVersion}`。生成时间 `{catalog.GeneratedUtc:O}`。");
        b.AppendLine();
        b.AppendLine("## 证据等级");
        b.AppendLine();
        b.AppendLine("- `confirmed`：已在本地回环捕获或 SDK 回调日志中直接观察。");
        b.AppendLine("- `inferred`：来自 IL2CPP 类型字段、成对请求/响应名称或强静态证据。");
        b.AppendLine("- `candidate`：仅发现独立字符串，必须继续确认调用点或运行时行为。");
        b.AppendLine();
        b.AppendLine("## 当前覆盖");
        b.AppendLine();
        foreach (var client in catalog.Clients)
            b.AppendLine($"- `{client.Id}`：{client.Messages.Count} 个消息候选，{client.Messages.Count(x => x.ActualFields.Count > 0)} 个具有类型级字段证据，{client.Symbols.Count} 个网络相关符号。");
        b.AppendLine($"- 两服共有消息：{catalog.CrossVersion.Shared.Count}；日服独有：{catalog.CrossVersion.JapanOnly.Count}；国服独有：{catalog.CrossVersion.ChinaOnly.Count}。");
        b.AppendLine($"- 已确认 SDK 事件：{catalog.SdkEvents.Count}；已确认 HTTP 端点：{catalog.HttpEndpoints.Count}。");
        b.AppendLine();
        b.AppendLine("## 登录相关消息与字段");
        b.AppendLine();
        foreach (var client in catalog.Clients)
        {
            b.AppendLine($"### {client.Id}");
            b.AppendLine();
            foreach (var message in client.Messages.Where(x =>
                x.Name.Contains("Login", StringComparison.OrdinalIgnoreCase) ||
                x.Name is "TRetGetSvrTime" or "TArgCreateUser"))
                b.AppendLine($"- `{message.Name}`（{message.Direction}）：{FormatFields(message.Fields)}；配对 `{message.Pair ?? "未确认"}`；置信度 {message.Confidence:P0}。");
            b.AppendLine();
        }
        b.AppendLine("## 生成物用途");
        b.AppendLine();
        b.AppendLine("- `catalog.json`：完整机器可读知识库，后续代码生成和差异检查的唯一输入。");
        b.AppendLine("- `sdk-events.csv`：SDK 事件编号、触发点和参数。");
        b.AppendLine("- `message-candidates.csv`：消息方向、请求/响应配对、实际字段和低置信参数候选。");
        b.AppendLine("- `adapter-template.json`：版本适配器配置骨架，集中保存消息 ID、帧、压缩、加密和能力开关。");
        b.AppendLine();
        b.AppendLine("## 尚未确认");
        b.AppendLine();
        b.AppendLine("- 消息数字 ID 与类型名称的映射。");
        b.AppendLine("- protobuf 字段编号、字段线型和可选/必需规则；字段 CLR/IL2CPP 类型已解析。");
        b.AppendLine("- 游戏连接的帧头、序号、压缩和加密流程。");
        b.AppendLine("- SDK 事件 1007 的 `data` 完整结构及消费函数。");
        b.AppendLine();
        b.AppendLine("以上项目不会再通过反复修改响应猜测，而应通过类型布局、调用点交叉引用和有目标的单次运行捕获补齐。每次确认后写回目录，再由版本适配器消费。");
        b.AppendLine();
        b.AppendLine("## 重新生成");
        b.AppendLine();
        b.AppendLine("```powershell");
        b.AppendLine("dotnet run --project src\\BlueOath.Tools\\BlueOath.Tools.csproj -- --analyze-protocol");
        b.AppendLine("```");
        return b.ToString();
    }

    private static async Task WriteEventsCsvAsync(string path, IEnumerable<SdkEvent> events)
    {
        var lines = new List<string> { "id,name,trigger,parameters,evidence,confidence" };
        lines.AddRange(events.Select(x => Csv(x.Id, x.Name, x.Trigger, string.Join(";", x.Parameters), x.Evidence, x.Confidence)));
        await File.WriteAllLinesAsync(path, lines, new UTF8Encoding(false));
    }

    private static async Task WriteMessagesCsvAsync(string path, IEnumerable<ClientCatalog> clients)
    {
        var lines = new List<string> { "client,name,stem,direction,pair,actualFields,fieldTypes,possibleParameters,evidence,confidence,source" };
        lines.AddRange(clients.SelectMany(c => c.Messages.Select(x => Csv(c.Id, x.Name, x.Stem, x.Direction,
            x.Pair ?? string.Empty, string.Join(";", x.ActualFields),
            string.Join(";", x.Fields.Select(f => $"{f.Name}:{f.TypeName ?? "unknown"}")),
            string.Join(";", x.PossibleParameters),
            x.Evidence, x.Confidence, x.Source))));
        await File.WriteAllLinesAsync(path, lines, new UTF8Encoding(false));
    }

    private static string FormatFields(IEnumerable<FieldEvidence> fields) => string.Join("；",
        fields.Select(x => $"`{x.Name}: {x.TypeName ?? "unknown"}{(x.WireTag is null ? string.Empty : $" = {x.WireTag}")}`"));

    private static string BuildProtoDraft(ClientCatalog client)
    {
        var text = new StringBuilder();
        text.AppendLine("syntax = \"proto2\";");
        text.AppendLine();
        text.AppendLine($"// Generated static draft for {client.Id}. Tags marked inferred are not wire-confirmed.");
        text.AppendLine("package blueoath;");
        text.AppendLine();
        foreach (var message in client.Messages.Where(x => x.Fields.Any(f => f.WireTag is not null)))
        {
            text.AppendLine($"message {message.Name} {{");
            foreach (var field in message.Fields.Where(x => x.WireTag is not null))
            {
                var protoType = ToProtoType(field.TypeName ?? "bytes");
                var repeated = protoType.StartsWith("repeated ", StringComparison.Ordinal);
                if (repeated) protoType = protoType[9..];
                text.AppendLine($"  // evidence: {field.WireTagEvidence}; IL2CPP typeIndex: {field.TypeIndex}");
                text.AppendLine($"  {(repeated ? "repeated" : "optional")} {protoType} {ToProtoName(field.PropertyName ?? field.Name)} = {field.WireTag};");
            }
            text.AppendLine("}");
            text.AppendLine();
        }
        return text.ToString();
    }

    private static string ToProtoType(string typeName)
    {
        if (typeName.StartsWith("System.Collections.Generic.List<", StringComparison.Ordinal) &&
            typeName.EndsWith('>')) return "repeated " + ToProtoType(typeName[32..^1]);
        return typeName switch
        {
            "bool" => "bool", "int" or "short" or "sbyte" => "int32",
            "uint" or "ushort" or "byte" => "uint32", "long" => "int64", "ulong" => "uint64",
            "float" => "float", "double" => "double", "string" => "string",
            _ when typeName.StartsWith("pb.", StringComparison.Ordinal) => typeName[3..],
            _ => "bytes"
        };
    }

    private static string ToProtoName(string value)
    {
        value = value.TrimStart('_');
        var name = Regex.Replace(value, "(?<!^)([A-Z])", "_$1").ToLowerInvariant();
        return ProtoKeywords.Contains(name) ? name + "_value" : name;
    }

    private static readonly HashSet<string> ProtoKeywords =
    [
        "syntax", "import", "weak", "public", "package", "option", "optional", "required",
        "repeated", "oneof", "map", "reserved", "to", "max", "enum", "message", "service",
        "rpc", "returns", "stream", "extend", "extensions", "group", "class"
    ];

    private static string Csv(params object?[] values) => string.Join(',', values.Select(value =>
        '"' + (Convert.ToString(value, CultureInfo.InvariantCulture) ?? string.Empty).Replace("\"", "\"\"") + '"'));

    private static IEnumerable<string> ExtractStrings(string path, int minimum)
    {
        var bytes = File.ReadAllBytes(path);
        var builder = new StringBuilder();
        foreach (var value in bytes)
        {
            if (value is >= 0x20 and <= 0x7e) builder.Append((char)value);
            else
            {
                if (builder.Length >= minimum && builder.Length <= 256) yield return builder.ToString();
                builder.Clear();
            }
        }
        if (builder.Length >= minimum && builder.Length <= 256) yield return builder.ToString();
    }

    private static readonly HashSet<string> EnvelopeTypeNames = new(StringComparer.Ordinal)
    {
        "NetProtocol", "TAckPack", "TNetOperation", "AckPackBean", "C2SProtocol", "S2CProtocol"
    };

    private static bool IsMessageName(string value) =>
        (MessageRegex().IsMatch(value) || EnvelopeTypeNames.Contains(value)) &&
        !value.Contains("::", StringComparison.Ordinal) && value.Length <= 96;

    private static bool IsParameterName(string value) => ParameterRegex().IsMatch(value) &&
        value.Length is >= 2 and <= 48 && !value.StartsWith("get_", StringComparison.Ordinal) &&
        !value.StartsWith("set_", StringComparison.Ordinal);

    private static bool IsProtocolSymbol(string value) => ProtocolRegex().IsMatch(value) && value.Length <= 120;

    private static IEnumerable<string> SplitIdentifier(string value) =>
        Regex.Matches(value, "[A-Z]?[a-z]+|[A-Z]+(?![a-z])|[0-9]+")
            .Select(x => x.Value).Where(x => x.Length > 1);

    private static string Hash(string path)
    {
        using var stream = File.OpenRead(path);
        return Convert.ToHexString(SHA256.HashData(stream));
    }

    private static string FindRoot()
    {
        var current = new DirectoryInfo(Environment.CurrentDirectory);
        while (current is not null && !File.Exists(Path.Combine(current.FullName, "BlueOath.Local.sln")))
            current = current.Parent;
        return current?.FullName ?? throw new DirectoryNotFoundException("BlueOath.Local.sln was not found");
    }

    private static string? ReadArg(string[] args, string prefix) =>
        args.FirstOrDefault(x => x.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))?[prefix.Length..];

    [GeneratedRegex("^(?:TArg|TRet|S2C|C2S)[A-Z][A-Za-z0-9_]{2,}$")]
    private static partial Regex MessageRegex();
    [GeneratedRegex("^[a-z][A-Za-z0-9_]{1,47}$")]
    private static partial Regex ParameterRegex();
    [GeneratedRegex("(?:Protocol|Socket|Packet|Message|ProtoBuf|KCP|Net[A-Z]|Login|ServerList)", RegexOptions.IgnoreCase)]
    private static partial Regex ProtocolRegex();
    [GeneratedRegex("^[a-zA-Z0-9.-]+\\.(?:com|net|cn|jp)(?::[0-9]+)?$")]
    private static partial Regex HostRegex();
    [GeneratedRegex("callback enter event=([0-9]+)(?: payload=\"(.*)\")?")]
    private static partial Regex EventRegex();
    [GeneratedRegex("^(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS) ([^ ]+) HTTP/")]
    private static partial Regex HttpRegex();

    private sealed record ProtocolCatalog(string SchemaVersion, DateTimeOffset GeneratedUtc,
        ClientCatalog[] Clients, List<SdkEvent> SdkEvents, List<HttpEndpoint> HttpEndpoints,
        CrossVersion CrossVersion, EvidencePolicy EvidencePolicy);
    private sealed record ClientCatalog(string Id, string Region, string Version, string Architecture,
        string GameAssemblySha256, string MetadataSha256, List<MessageCandidate> Messages,
        List<string> Symbols, List<string> Hosts, List<string> Paths,
        int MetadataStringCount, int AssemblyStringCount);
    private sealed record MessageCandidate(string Name, string Stem, string Direction, string? Pair,
        List<string> ActualFields, List<FieldEvidence> Fields, List<string> PossibleParameters,
        string Evidence, double Confidence, string Source);
    private sealed record FieldEvidence(string Name, int FieldDefinitionIndex, int TypeIndex, int DefaultValueIndex,
        string? TypeName = null, string? TypeKind = null, string? TypeConfidence = null,
        int? TypeDefinitionIndex = null, string? PropertyName = null, int? PropertyDefinitionIndex = null,
        List<string>? AttributeTypes = null, int? WireTag = null, string? WireTagEvidence = null);
    private sealed record PropertyEvidence(string Name, int PropertyDefinitionIndex, int CustomAttributeIndex,
        List<int> AttributeTypeIndices);
    private sealed record SdkEvent(int Id, string Name, string Trigger, string[] Parameters,
        List<string> ObservedSamples, string Evidence, double Confidence);
    private sealed record HttpEndpoint(string Method, string Path, string? Host,
        string Evidence, double Confidence, string EvidenceFile);
    private sealed record CrossVersion(List<string> Shared, List<string> JapanOnly, List<string> ChinaOnly);
    private sealed record EvidencePolicy(string Confirmed, string Inferred, string Candidate);
}
