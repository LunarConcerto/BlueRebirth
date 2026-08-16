using System.Buffers.Binary;
using System.Reflection.PortableExecutable;
using System.Text;
using System.Text.Json;

static class Il2CppMetadataTool
{
    private static readonly HashSet<byte> ValidTypeEnums =
    [
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c,
        0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x18, 0x19,
        0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x41, 0x45, 0x55
    ];

    public static async Task<int> RunAsync(string[] args)
    {
        var root = FindRoot();
        var output = ReadArg(args, "--il2cpp-output=") ?? Path.Combine(root, "docs", "il2cpp-catalog");
        output = Path.GetFullPath(output);
        Directory.CreateDirectory(output);

        var clients = new[]
        {
            AnalyzeClient("jp-1.4.0", Path.Combine(root, "blueoath", "blueoath"), "blueoath_Data"),
            AnalyzeClient("cn-1.5.20", Path.Combine(root, "苍蓝誓约", "clsy"), "clsy_Data")
        };
        var catalog = new { SchemaVersion = "1.0", GeneratedUtc = DateTimeOffset.UtcNow, Clients = clients };
        var options = new JsonSerializerOptions { WriteIndented = true };
        await File.WriteAllTextAsync(Path.Combine(output, "metadata-registration-candidates.json"),
            JsonSerializer.Serialize(catalog, options), new UTF8Encoding(false));
        await File.WriteAllTextAsync(Path.Combine(output, "README.zh-CN.md"), BuildReport(clients),
            new UTF8Encoding(false));
        await File.WriteAllTextAsync(Path.Combine(output, "method-addresses.json"),
            JsonSerializer.Serialize(AnalyzeMethodAddresses(root), options), new UTF8Encoding(false));
        await File.WriteAllTextAsync(Path.Combine(output, "wire-analysis.json"),
            JsonSerializer.Serialize(AnalyzeWireMethods(root), options), new UTF8Encoding(false));

        Console.WriteLine(JsonSerializer.Serialize(new
        {
            complete = true,
            output,
            clients = clients.Select(x => new
            {
                x.Id,
                candidates = x.Candidates.Count,
                strongCandidates = x.Candidates.Count(y => y.Confidence == "strong"),
                maxFieldTypeIndex = x.MaxFieldTypeIndex
            })
        }));
        return 0;
    }

    public static async Task<int> RunWireAsync(string[] args)
    {
        var root = FindRoot();
        var output = ReadArg(args, "--il2cpp-output=") ?? Path.Combine(root, "docs", "il2cpp-catalog");
        output = Path.GetFullPath(output);
        Directory.CreateDirectory(output);
        var options = new JsonSerializerOptions { WriteIndented = true };
        await File.WriteAllTextAsync(Path.Combine(output, "wire-analysis.json"),
            JsonSerializer.Serialize(AnalyzeWireMethods(root), options), new UTF8Encoding(false));
        Console.WriteLine(JsonSerializer.Serialize(new { complete = true, output }));
        return 0;
    }

    private static object AnalyzeMethodAddresses(string root)
    {
        return new[]
        {
            AnalyzeMethodAddressesForClient("jp-1.4.0", Path.Combine(root, "blueoath", "blueoath"), "blueoath_Data"),
            AnalyzeMethodAddressesForClient("cn-1.5.20", Path.Combine(root, "苍蓝誓约", "clsy"), "clsy_Data")
        };
    }

    private static object AnalyzeWireMethods(string root)
    {
        return new[]
        {
            AnalyzeWireMethodsForClient("jp-1.4.0", Path.Combine(root, "blueoath", "blueoath"), "blueoath_Data"),
            AnalyzeWireMethodsForClient("cn-1.5.20", Path.Combine(root, "苍蓝誓约", "clsy"), "clsy_Data")
        };
    }

    private static object AnalyzeWireMethodsForClient(string id, string clientRoot, string dataName)
    {
        var assemblyPath = Path.Combine(clientRoot, "GameAssembly.dll");
        var metadataPath = Path.Combine(clientRoot, dataName, "il2cpp_data", "Metadata", "global-metadata.dat");
        var image = PeImage.Load(assemblyPath);
        var methods = ReadMethodDefinitions(metadataPath);
        var methodCount = methods.Where(x => x.MethodIndex >= 0).Select(x => x.MethodIndex).DefaultIfEmpty(-1).Max() + 1;
        var table = FindMethodPointerTables(image, methodCount).FirstOrDefault()
            ?? throw new InvalidDataException("No validated method pointer table found");
        var indexed = methods.Where(x => x.MethodIndex >= 0).Select(x => new
        {
            Method = x,
            Va = image.ReadUInt32AtFileOffset(table.TableFileOffset + x.MethodIndex * 4)
        }).Where(x => image.IsExecutableVa(x.Va)).ToList();
        var methodsByVa = indexed.GroupBy(x => x.Va)
            .ToDictionary(x => x.Key, x => x.Select(y => y.Method).ToList());
        var orderedVas = methodsByVa.Keys.OrderBy(x => x).ToArray();
        var wanted = new HashSet<string>(StringComparer.Ordinal)
        {
            "LogicSocketClient.Send", "LogicSocketClient.KcpSend", "LogicSocketClient.Dispatch",
            "LogicSocketClient.Deserialize", "LogicSocketClient.FindMessageHandler",
            "LogicSocketClient.RegisterMessageHandler", "NetProtocol.Pack", "NetProtocol.Unpack",
            "C2SProtocol.Pack", "C2SProtocol.Unpack", "S2CProtocol.Pack", "S2CProtocol.Unpack",
            "SocketService.Login", "BabelTimeSDKManager.GetServiceList",
            "BabelTimeSDKManager.SelectService", "BabelTimeSDKManager.GetLastServiceList",
            "BabelTimeSDKManager.CallWebFunction", "BabelTimeSDKManager.CallUniversalWebFunction"
        };
        foreach (var method in indexed.Select(x => x.Method).Where(x =>
                     x.TypeName is "BabelTimeSDKManager" or "SDKConfigGetter" or "PlatformWrapper"))
            wanted.Add(method.TypeName + "." + method.Name);
        var targets = indexed.Where(x => wanted.Contains(x.Method.TypeName + "." + x.Method.Name))
            .GroupBy(x => x.Va).Select(x => x.First()).OrderBy(x => x.Va).Select(x =>
            {
                var nextVa = orderedVas.FirstOrDefault(y => y > x.Va);
                var length = nextVa > x.Va ? (int)Math.Min(nextVa - x.Va, 8192u) : 512;
                if (!image.TryVaToFileOffset(x.Va, out var offset) || length <= 0 ||
                    !image.ContainsFileRange(offset, length)) length = 0;
                var bytes = length == 0 ? [] : image.ReadBytes(offset, length);
                return new WireMethod(x.Method.TypeName, x.Method.Name,
                    checked((int)(x.Va - image.ImageBase)), length, Convert.ToHexString(bytes),
                    ScanControlFlow(image, x.Va, bytes, methodsByVa));
            }).ToList();
        var registerVa = indexed.FirstOrDefault(x => x.Method.TypeName == "LogicSocketClient" &&
            x.Method.Name == "RegisterMessageHandler")?.Va ?? 0;
        return new
        {
            Id = id,
            Methods = targets,
            RegisterMessageHandlerCallSites = registerVa == 0 ? [] : FindDirectCalls(image, registerVa)
        };
    }

    private static List<ControlFlowReference> ScanControlFlow(PeImage image, uint methodVa, byte[] bytes,
        IReadOnlyDictionary<uint, List<MethodDefinitionInfo>> methodsByVa)
    {
        var result = new List<ControlFlowReference>();
        for (var i = 0; i + 5 <= bytes.Length; i++)
        {
            if (bytes[i] is not (0xe8 or 0xe9)) continue;
            var displacement = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(i + 1, 4));
            var sourceVa = methodVa + (uint)i;
            var targetVa = unchecked(sourceVa + 5 + (uint)displacement);
            var start = Math.Max(0, i - 40);
            var context = bytes.AsSpan(start, i + 5 - start).ToArray();
            methodsByVa.TryGetValue(targetVa, out var targets);
            var targetRva = (long)targetVa - image.ImageBase;
            result.Add(new ControlFlowReference(bytes[i] == 0xe8 ? "call" : "jump",
                checked((int)(sourceVa - image.ImageBase)),
                targetRva is >= int.MinValue and <= int.MaxValue ? (int)targetRva : null,
                targets?.Take(20).Select(x => x.TypeName + "." + x.Name).ToList() ?? [],
                ExtractPushImmediates(context), Convert.ToHexString(context)));
            i += 4;
        }
        return result;
    }

    private static object AnalyzeMethodAddressesForClient(string id, string clientRoot, string dataName)
    {
        var assemblyPath = Path.Combine(clientRoot, "GameAssembly.dll");
        var metadataPath = Path.Combine(clientRoot, dataName, "il2cpp_data", "Metadata", "global-metadata.dat");
        var image = PeImage.Load(assemblyPath);
        var methods = ReadMethodDefinitions(metadataPath);
        var methodCount = methods.Where(x => x.MethodIndex >= 0).Select(x => x.MethodIndex).DefaultIfEmpty(-1).Max() + 1;
        var tables = FindMethodPointerTables(image, methodCount);
        var table = tables.FirstOrDefault() ?? throw new InvalidDataException("No validated method pointer table found");
        var wanted = new HashSet<string>(StringComparer.Ordinal)
        {
            "LogicSocketClient.Send", "LogicSocketClient.KcpSend", "LogicSocketClient.Dispatch",
            "LogicSocketClient.Deserialize", "LogicSocketClient.RegisterMessageHandler",
            "NetProtocol.Pack", "NetProtocol.Unpack", "TArgLogin..ctor", "TRetLogin..ctor",
            "SocketService.Login", "VitrualSocketService.Login", "CommandServiceBase.Login",
            "Platform.login", "MtpManager.Login", "FakeMtpOperator.Login"
            , "BabelTimeSDKManager.GetServiceList", "BabelTimeSDKManager.SelectService",
            "BabelTimeSDKManager.GetLastServiceList", "BabelTimeSDKManager.CallWebFunction",
            "BabelTimeSDKManager.CallUniversalWebFunction"
        };
        foreach (var method in methods.Where(x =>
                     x.TypeName is "BabelTimeSDKManager" or "SDKConfigGetter" or "PlatformWrapper"))
            wanted.Add(method.TypeName + "." + method.Name);
        var methodsByVa = methods.Where(x => x.MethodIndex >= 0)
            .Select(x => new
            {
                Method = x,
                Va = image.ReadUInt32AtFileOffset(table.TableFileOffset + x.MethodIndex * 4)
            })
            .Where(x => image.IsExecutableVa(x.Va))
            .GroupBy(x => x.Va)
            .ToDictionary(x => x.Key, x => x.Select(y => y.Method).ToList());
        var orderedMethodVas = methodsByVa.Keys.OrderBy(x => x).ToArray();
        var addresses = methods.Where(x => wanted.Contains(x.TypeName + "." + x.Name) && x.MethodIndex >= 0)
            .Select(x =>
            {
                var va = image.ReadUInt32AtFileOffset(table.TableFileOffset + x.MethodIndex * 4);
                var rva = checked((int)(va - image.ImageBase));
                var callSites = (x.TypeName == "LogicSocketClient" && x.Name is "Send" or "KcpSend") ||
                    (x.TypeName == "TArgLogin" && x.Name == ".ctor")
                    ? FindDirectCalls(image, va).Take(512).ToList() : [];
                var outgoingCalls = AnalyzeOutgoingCalls(image, va, orderedMethodVas, methodsByVa);
                return new MethodAddress(x.TypeName, x.Name, x.MethodDefinitionIndex, x.MethodIndex,
                    rva, va, callSites, outgoingCalls);
            }).ToList();
        return new { Id = id, MethodPointersCount = methodCount, Tables = tables, Methods = addresses };
    }

    private static List<MethodPointerTable> FindMethodPointerTables(PeImage image, int methodCount)
    {
        var result = new List<MethodPointerTable>();
        foreach (var section in image.Sections)
        {
            for (var offset = section.RawOffset; offset + 8 <= section.RawOffset + section.RawSize; offset += 4)
            {
                if (image.ReadInt32AtFileOffset(offset) != methodCount) continue;
                var pointer = image.ReadUInt32AtFileOffset(offset + 4);
                if (!image.TryVaToFileOffset(pointer, out var tableOffset) ||
                    !image.ContainsFileRange(tableOffset, methodCount * 4L)) continue;
                var valid = 0;
                const int samples = 257;
                for (var i = 0; i < samples; i++)
                {
                    var index = (int)((long)(methodCount - 1) * i / (samples - 1));
                    var methodVa = image.ReadUInt32AtFileOffset(tableOffset + index * 4);
                    if (image.IsExecutableVa(methodVa)) valid++;
                }
                if (valid < samples * 0.98) continue;
                result.Add(new MethodPointerTable(image.FileOffsetToRva(offset), pointer, tableOffset,
                    samples, valid));
            }
        }
        return result.OrderByDescending(x => x.ValidSamples).ThenBy(x => x.CodeRegistrationRva).ToList();
    }

    private static List<DirectCallSite> FindDirectCalls(PeImage image, uint targetVa)
    {
        var result = new List<DirectCallSite>();
        foreach (var section in image.Sections.Where(x => x.IsExecutable))
        {
            for (var offset = section.RawOffset; offset + 5 <= section.RawOffset + section.RawSize; offset++)
            {
                if (image.ReadByteAtFileOffset(offset) != 0xe8) continue;
                var callVa = image.ImageBase + (uint)image.FileOffsetToRva(offset);
                var displacement = image.ReadInt32AtFileOffset(offset + 1);
                if (unchecked(callVa + 5 + (uint)displacement) != targetVa) continue;
                var start = Math.Max(section.RawOffset, offset - 24);
                var bytes = image.ReadBytes(start, offset + 5 - start);
                result.Add(new DirectCallSite(image.FileOffsetToRva(offset),
                    Convert.ToHexString(bytes), ExtractPushImmediates(bytes)));
            }
        }
        return result;
    }

    private static List<int> ExtractPushImmediates(byte[] bytes)
    {
        var values = new List<int>();
        for (var i = 0; i < bytes.Length - 1; i++)
        {
            if (bytes[i] == 0x6a && i + 1 < bytes.Length) values.Add(unchecked((sbyte)bytes[i + 1]));
            if (bytes[i] == 0x68 && i + 4 < bytes.Length)
            {
                values.Add(BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(i + 1, 4)));
                i += 4;
            }
        }
        return values;
    }

    private static List<OutgoingCall> AnalyzeOutgoingCalls(PeImage image, uint methodVa,
        uint[] orderedMethodVas, IReadOnlyDictionary<uint, List<MethodDefinitionInfo>> methodsByVa)
    {
        if (!image.TryVaToFileOffset(methodVa, out var methodOffset)) return [];
        var nextVa = orderedMethodVas.FirstOrDefault(x => x > methodVa);
        var length = nextVa > methodVa ? (int)Math.Min(nextVa - methodVa, 8192u) : 512;
        if (length < 5 || !image.ContainsFileRange(methodOffset, length)) return [];
        var bytes = image.ReadBytes(methodOffset, length);
        var result = new List<OutgoingCall>();
        for (var i = 0; i + 5 <= bytes.Length; i++)
        {
            if (bytes[i] != 0xe8) continue;
            var displacement = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(i + 1, 4));
            var callVa = methodVa + (uint)i;
            var targetVa = unchecked(callVa + 5 + (uint)displacement);
            if (!methodsByVa.TryGetValue(targetVa, out var targets)) continue;
            var contextStart = Math.Max(0, i - 24);
            var context = bytes.AsSpan(contextStart, i + 5 - contextStart).ToArray();
            result.Add(new OutgoingCall(checked((int)(callVa - image.ImageBase)),
                checked((int)(targetVa - image.ImageBase)),
                targets.Take(12).Select(x => x.TypeName + "." + x.Name).ToList(),
                ExtractPushImmediates(context), Convert.ToHexString(context)));
            i += 4;
        }
        return result;
    }

    private static List<MethodDefinitionInfo> ReadMethodDefinitions(string metadataPath)
    {
        var bytes = File.ReadAllBytes(metadataPath);
        var stringOffset = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 2 * 8));
        var stringSize = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 2 * 8 + 4));
        var methodsOffset = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 5 * 8));
        var methodsSize = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 5 * 8 + 4));
        var typesOffset = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 19 * 8));
        var typesSize = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 19 * 8 + 4));
        const int methodSize = 56;
        const int typeSize = 104;
        string ReadString(int index)
        {
            if (index < 0 || index >= stringSize) return string.Empty;
            var start = stringOffset + index;
            var end = start;
            while (end < stringOffset + stringSize && bytes[end] != 0) end++;
            return Encoding.UTF8.GetString(bytes, start, end - start);
        }
        var typeNames = new string[typesSize / typeSize];
        for (var i = 0; i < typeNames.Length; i++)
            typeNames[i] = ReadString(BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(typesOffset + i * typeSize)));
        var result = new List<MethodDefinitionInfo>(methodsSize / methodSize);
        for (var i = 0; i < methodsSize / methodSize; i++)
        {
            var offset = methodsOffset + i * methodSize;
            var declaringType = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(offset + 4));
            result.Add(new MethodDefinitionInfo(i,
                declaringType >= 0 && declaringType < typeNames.Length ? typeNames[declaringType] : string.Empty,
                ReadString(BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(offset))),
                BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(offset + 24))));
        }
        return result;
    }

    private static ClientResult AnalyzeClient(string id, string clientRoot, string dataName)
    {
        var assemblyPath = Path.Combine(clientRoot, "GameAssembly.dll");
        var metadataPath = Path.Combine(clientRoot, dataName, "il2cpp_data", "Metadata", "global-metadata.dat");
        var metadata = File.ReadAllBytes(metadataPath);
        var maxFieldTypeIndex = ReadMaxFieldTypeIndex(metadata);
        var image = PeImage.Load(assemblyPath);
        var candidates = ScanMetadataRegistration(image, maxFieldTypeIndex)
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.RegistrationRva)
            .Take(32)
            .ToList();
        return new ClientResult(id, image.ImageBase, image.SizeOfImage, maxFieldTypeIndex, candidates);
    }

    private static List<RegistrationCandidate> ScanMetadataRegistration(PeImage image, int maxFieldTypeIndex)
    {
        var results = new List<RegistrationCandidate>();
        foreach (var section in image.Sections.Where(x => x.RawSize >= 64))
        {
            var end = section.RawOffset + section.RawSize - 64;
            for (var offset = section.RawOffset; offset <= end; offset += 4)
            {
                var counts = new int[8];
                var pointers = new uint[8];
                var structurallyValid = true;
                for (var pair = 0; pair < 8; pair++)
                {
                    counts[pair] = image.ReadInt32AtFileOffset(offset + pair * 8);
                    pointers[pair] = image.ReadUInt32AtFileOffset(offset + pair * 8 + 4);
                    if (counts[pair] < 0 || counts[pair] > 5_000_000 ||
                        (counts[pair] > 0 && !image.TryVaToFileOffset(pointers[pair], out _)))
                    {
                        structurallyValid = false;
                        break;
                    }
                }
                if (!structurallyValid) continue;

                var typesCount = counts[3];
                if (typesCount <= maxFieldTypeIndex || typesCount > 1_000_000) continue;
                if (!image.TryVaToFileOffset(pointers[3], out var typesTableOffset)) continue;
                if (!image.ContainsFileRange(typesTableOffset, checked(typesCount * 4L))) continue;

                var validation = ValidateTypes(image, typesTableOffset, typesCount, maxFieldTypeIndex);
                if (validation.Samples < 16 || validation.ValidRatio < 0.80) continue;
                var nonZeroPairs = counts.Zip(pointers).Count(x => x.First > 0 && x.Second != 0);
                var score = validation.ValidRatio * 100 + nonZeroPairs * 3 +
                    (typesCount <= maxFieldTypeIndex + 100_000 ? 10 : 0);
                var registrationRva = image.FileOffsetToRva(offset);
                results.Add(new RegistrationCandidate(
                    registrationRva, checked(image.ImageBase + (uint)registrationRva),
                    counts[0], pointers[0], counts[1], counts[2], typesCount, pointers[3],
                    counts[4], counts[5], counts[6], counts[7], validation.Samples,
                    validation.Valid, validation.ValidRatio, validation.DistinctEnums,
                    score >= 130 && validation.ValidRatio >= 0.95 ? "strong" : "candidate", score));
            }
        }
        return results;
    }

    private static TypeValidation ValidateTypes(PeImage image, int tableOffset, int typesCount,
        int maxFieldTypeIndex)
    {
        var indices = new HashSet<int>();
        for (var i = 0; i < Math.Min(typesCount, 128); i++) indices.Add(i);
        for (var i = 1; i <= 128; i++) indices.Add((int)((long)(typesCount - 1) * i / 128));
        indices.Add(maxFieldTypeIndex);

        var valid = 0;
        var enums = new HashSet<byte>();
        foreach (var index in indices.Where(x => x >= 0 && x < typesCount))
        {
            var typeVa = image.ReadUInt32AtFileOffset(tableOffset + index * 4);
            if (!image.TryVaToFileOffset(typeVa, out var typeOffset) ||
                !image.ContainsFileRange(typeOffset, 8)) continue;
            var bits = image.ReadUInt32AtFileOffset(typeOffset + 4);
            var typeEnum = (byte)((bits >> 16) & 0xff);
            if (!ValidTypeEnums.Contains(typeEnum)) continue;
            valid++;
            enums.Add(typeEnum);
        }
        return new TypeValidation(indices.Count, valid,
            indices.Count == 0 ? 0 : Math.Round((double)valid / indices.Count, 4),
            enums.OrderBy(x => x).Select(x => $"0x{x:x2}").ToList());
    }

    private static int ReadMaxFieldTypeIndex(byte[] bytes)
    {
        if (bytes.Length < 0x110 || BinaryPrimitives.ReadUInt32LittleEndian(bytes) != 0xFAB11BAF ||
            BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(4)) != 24)
            throw new InvalidDataException("Expected IL2CPP global metadata version 24");
        var fieldsOffset = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 11 * 8));
        var fieldsSize = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 11 * 8 + 4));
        const int fieldSize = 16;
        if (fieldsOffset < 0 || fieldsSize < 0 || fieldsSize % fieldSize != 0 ||
            fieldsOffset + fieldsSize > bytes.Length) throw new InvalidDataException("Invalid field definition table");
        var max = -1;
        for (var offset = fieldsOffset; offset < fieldsOffset + fieldsSize; offset += fieldSize)
            max = Math.Max(max, BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(offset + 4)));
        return max;
    }

    internal static Dictionary<int, ResolvedTypeInfo> ResolveTypes(string assemblyPath, string metadataPath,
        IEnumerable<int> requestedTypeIndices)
    {
        var metadata = File.ReadAllBytes(metadataPath);
        var image = PeImage.Load(assemblyPath);
        var candidate = ScanMetadataRegistration(image, ReadMaxFieldTypeIndex(metadata))
            .OrderByDescending(x => x.Score).FirstOrDefault(x => x.Confidence == "strong")
            ?? throw new InvalidDataException("No strongly validated metadata registration was found");
        var definitions = ReadTypeDefinitions(metadata);
        if (!image.TryVaToFileOffset(candidate.TypesPointer, out var typesTableOffset))
            throw new InvalidDataException("Types table does not map to the PE image");

        var cache = new Dictionary<int, ResolvedTypeInfo>();
        foreach (var index in requestedTypeIndices.Distinct())
        {
            if (index < 0 || index >= candidate.TypesCount)
            {
                cache[index] = new ResolvedTypeInfo("unknown", "invalid-index", "candidate", null);
                continue;
            }
            var typeVa = image.ReadUInt32AtFileOffset(typesTableOffset + index * 4);
            cache[index] = ResolveTypeAtVa(typeVa, image, candidate, definitions, new HashSet<uint>(), 0);
        }
        return cache;
    }

    private static ResolvedTypeInfo ResolveTypeAtVa(uint typeVa, PeImage image,
        RegistrationCandidate registration, IReadOnlyList<TypeDefinitionName> definitions,
        HashSet<uint> path, int depth)
    {
        if (depth > 8 || !path.Add(typeVa) || !image.TryVaToFileOffset(typeVa, out var offset) ||
            !image.ContainsFileRange(offset, 8))
            return new ResolvedTypeInfo("unknown", "invalid-reference", "candidate", null);
        var data = image.ReadInt32AtFileOffset(offset);
        var bits = image.ReadUInt32AtFileOffset(offset + 4);
        var typeEnum = (byte)((bits >> 16) & 0xff);
        var enumName = $"0x{typeEnum:x2}";
        ResolvedTypeInfo Primitive(string name) => new(name, enumName, "strong", null);
        ResolvedTypeInfo result = typeEnum switch
        {
            0x01 => Primitive("void"), 0x02 => Primitive("bool"), 0x03 => Primitive("char"),
            0x04 => Primitive("sbyte"), 0x05 => Primitive("byte"), 0x06 => Primitive("short"),
            0x07 => Primitive("ushort"), 0x08 => Primitive("int"), 0x09 => Primitive("uint"),
            0x0a => Primitive("long"), 0x0b => Primitive("ulong"), 0x0c => Primitive("float"),
            0x0d => Primitive("double"), 0x0e => Primitive("string"), 0x18 => Primitive("nint"),
            0x19 => Primitive("nuint"), 0x1c => Primitive("object"),
            0x11 or 0x12 => ResolveDefinition(data, typeEnum, definitions),
            0x1d or 0x0f or 0x10 => ResolveElementType(unchecked((uint)data), typeEnum, image,
                registration, definitions, path, depth),
            0x15 => ResolveGenericInstance(unchecked((uint)data), image, registration, definitions, path, depth),
            0x13 => new ResolvedTypeInfo($"type-var[{data}]", enumName, "candidate", null),
            0x1e => new ResolvedTypeInfo($"method-var[{data}]", enumName, "candidate", null),
            _ => new ResolvedTypeInfo($"il2cpp-type-{enumName}[{data}]", enumName, "candidate", null)
        };
        path.Remove(typeVa);
        return result;
    }

    private static ResolvedTypeInfo ResolveDefinition(int index, byte typeEnum,
        IReadOnlyList<TypeDefinitionName> definitions)
    {
        if (index < 0 || index >= definitions.Count)
            return new ResolvedTypeInfo($"type-def[{index}]", $"0x{typeEnum:x2}", "candidate", index);
        var item = definitions[index];
        return new ResolvedTypeInfo(item.FullName, $"0x{typeEnum:x2}", "strong", index);
    }

    private static ResolvedTypeInfo ResolveElementType(uint elementVa, byte typeEnum, PeImage image,
        RegistrationCandidate registration, IReadOnlyList<TypeDefinitionName> definitions,
        HashSet<uint> path, int depth)
    {
        var element = ResolveTypeAtVa(elementVa, image, registration, definitions, path, depth + 1);
        var suffix = typeEnum == 0x1d ? "[]" : typeEnum == 0x0f ? "*" : "&";
        return new ResolvedTypeInfo(element.Name + suffix, $"0x{typeEnum:x2}", element.Confidence,
            element.TypeDefinitionIndex);
    }

    private static ResolvedTypeInfo ResolveGenericInstance(uint genericClassVa, PeImage image,
        RegistrationCandidate registration, IReadOnlyList<TypeDefinitionName> definitions,
        HashSet<uint> path, int depth)
    {
        if (!image.TryVaToFileOffset(genericClassVa, out var classOffset) ||
            !image.ContainsFileRange(classOffset, 16))
            return new ResolvedTypeInfo($"generic[0x{genericClassVa:x8}]", "0x15", "candidate", null);
        var definitionIndex = image.ReadInt32AtFileOffset(classOffset);
        var baseName = definitionIndex >= 0 && definitionIndex < definitions.Count
            ? definitions[definitionIndex].FullName : $"type-def[{definitionIndex}]";
        var classInstVa = image.ReadUInt32AtFileOffset(classOffset + 4);
        if (classInstVa == 0 || !image.TryVaToFileOffset(classInstVa, out var instOffset) ||
            !image.ContainsFileRange(instOffset, 8))
            return new ResolvedTypeInfo(baseName, "0x15", "inferred", definitionIndex);
        var argumentCount = image.ReadInt32AtFileOffset(instOffset);
        var argumentsVa = image.ReadUInt32AtFileOffset(instOffset + 4);
        if (argumentCount < 0 || argumentCount > 32 || !image.TryVaToFileOffset(argumentsVa, out var argumentsOffset) ||
            !image.ContainsFileRange(argumentsOffset, argumentCount * 4L))
            return new ResolvedTypeInfo(baseName, "0x15", "inferred", definitionIndex);
        var arguments = new List<string>();
        var confidence = "strong";
        for (var i = 0; i < argumentCount; i++)
        {
            var argumentVa = image.ReadUInt32AtFileOffset(argumentsOffset + i * 4);
            var argument = ResolveTypeAtVa(argumentVa, image, registration, definitions, path, depth + 1);
            arguments.Add(argument.Name);
            if (argument.Confidence != "strong") confidence = "inferred";
        }
        var tick = baseName.IndexOf('`');
        if (tick >= 0) baseName = baseName[..tick];
        return new ResolvedTypeInfo($"{baseName}<{string.Join(", ", arguments)}>", "0x15", confidence,
            definitionIndex);
    }

    private static List<TypeDefinitionName> ReadTypeDefinitions(byte[] bytes)
    {
        var stringOffset = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 2 * 8));
        var stringSize = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 2 * 8 + 4));
        var typesOffset = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 19 * 8));
        var typesSize = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(8 + 19 * 8 + 4));
        const int typeSize = 104;
        string ReadString(int index)
        {
            if (index < 0 || index >= stringSize) return string.Empty;
            var start = stringOffset + index;
            var end = start;
            while (end < stringOffset + stringSize && bytes[end] != 0) end++;
            return Encoding.UTF8.GetString(bytes, start, end - start);
        }
        var result = new List<TypeDefinitionName>(typesSize / typeSize);
        for (var offset = typesOffset; offset < typesOffset + typesSize; offset += typeSize)
        {
            var name = ReadString(BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(offset)));
            var ns = ReadString(BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(offset + 4)));
            result.Add(new TypeDefinitionName(name, string.IsNullOrEmpty(ns) ? name : ns + "." + name));
        }
        return result;
    }

    private static string BuildReport(IEnumerable<ClientResult> clients)
    {
        var text = new StringBuilder("# IL2CPP Metadata Registration 候选\n\n");
        text.AppendLine("本目录由 `--analyze-il2cpp` 只读生成。候选必须同时满足 x86 registration 的 8 组 count/pointer 结构、PE 地址映射和 `Il2CppType` 抽样校验。\n");
        foreach (var client in clients)
        {
            text.AppendLine($"## {client.Id}\n");
            text.AppendLine($"- ImageBase: `0x{client.ImageBase:x8}`");
            text.AppendLine($"- 最大字段 typeIndex: `{client.MaxFieldTypeIndex}`");
            text.AppendLine($"- 候选数: `{client.Candidates.Count}`，强候选: `{client.Candidates.Count(x => x.Confidence == "strong")}`\n");
            foreach (var item in client.Candidates.Take(5))
                text.AppendLine($"- `{item.Confidence}` registration RVA `0x{item.RegistrationRva:x8}`, types `{item.TypesCount}`, types VA `0x{item.TypesPointer:x8}`, 抽样 `{item.ValidTypeSamples}/{item.TypeSamples}`，score `{item.Score:F2}`");
            text.AppendLine();
        }
        text.AppendLine("`candidate` 不能直接作为注入地址；只有经过交叉引用或运行时基址验证后才能进入版本适配器。");
        return text.ToString();
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

    private sealed record ClientResult(string Id, uint ImageBase, int SizeOfImage, int MaxFieldTypeIndex,
        List<RegistrationCandidate> Candidates);
    private sealed record RegistrationCandidate(int RegistrationRva, uint RegistrationVa,
        int GenericClassesCount, uint GenericClassesPointer, int GenericInstsCount, int GenericMethodTableCount,
        int TypesCount, uint TypesPointer, int MethodSpecsCount, int FieldOffsetsCount,
        int TypeDefinitionSizesCount, int MetadataUsagesCount, int TypeSamples, int ValidTypeSamples,
        double ValidTypeRatio, List<string> DistinctTypeEnums, string Confidence, double Score);
    private sealed record TypeValidation(int Samples, int Valid, double ValidRatio, List<string> DistinctEnums);
    private sealed record TypeDefinitionName(string Name, string FullName);
    internal sealed record ResolvedTypeInfo(string Name, string Kind, string Confidence, int? TypeDefinitionIndex);
    private sealed record MethodDefinitionInfo(int MethodDefinitionIndex, string TypeName, string Name, int MethodIndex);
    private sealed record MethodPointerTable(int CodeRegistrationRva, uint TableVa, int TableFileOffset,
        int Samples, int ValidSamples);
    private sealed record MethodAddress(string TypeName, string Name, int MethodDefinitionIndex, int MethodIndex,
        int Rva, uint Va, List<DirectCallSite> DirectCallSites, List<OutgoingCall> OutgoingCalls);
    private sealed record DirectCallSite(int Rva, string ContextHex, List<int> PushImmediates);
    private sealed record OutgoingCall(int CallRva, int TargetRva, List<string> Targets,
        List<int> PushImmediates, string ContextHex);
    private sealed record WireMethod(string TypeName, string Name, int Rva, int Length,
        string Hex, List<ControlFlowReference> ControlFlow);
    private sealed record ControlFlowReference(string Kind, int SourceRva, int? TargetRva,
        List<string> Targets, List<int> PushImmediates, string ContextHex);

    private sealed class PeImage
    {
        private readonly byte[] _bytes;
        private PeImage(byte[] bytes, uint imageBase, int sizeOfImage, List<PeSection> sections)
        {
            _bytes = bytes;
            ImageBase = imageBase;
            SizeOfImage = sizeOfImage;
            Sections = sections;
        }

        public uint ImageBase { get; }
        public int SizeOfImage { get; }
        public List<PeSection> Sections { get; }

        public static PeImage Load(string path)
        {
            var bytes = File.ReadAllBytes(path);
            using var stream = new MemoryStream(bytes, writable: false);
            using var reader = new PEReader(stream);
            var headers = reader.PEHeaders;
            var pe = headers.PEHeader ?? throw new BadImageFormatException("Missing PE header");
            if (pe.Magic != PEMagic.PE32) throw new BadImageFormatException("Expected x86 PE32 image");
            var sections = headers.SectionHeaders.Select(x => new PeSection(x.Name, x.VirtualAddress,
                x.PointerToRawData, x.SizeOfRawData, Math.Max(x.VirtualSize, x.SizeOfRawData),
                (x.SectionCharacteristics & SectionCharacteristics.ContainsCode) != 0)).ToList();
            return new PeImage(bytes, checked((uint)pe.ImageBase), pe.SizeOfImage, sections);
        }

        public bool TryVaToFileOffset(uint va, out int offset)
        {
            var rva = (long)va - ImageBase;
            foreach (var section in Sections)
            {
                if (rva < section.Rva || rva >= (long)section.Rva + section.MappedSize) continue;
                var delta = rva - section.Rva;
                if (delta >= section.RawSize) break;
                offset = checked(section.RawOffset + (int)delta);
                return offset >= 0 && offset < _bytes.Length;
            }
            offset = -1;
            return false;
        }

        public int FileOffsetToRva(int offset)
        {
            var section = Sections.First(x => offset >= x.RawOffset && offset < x.RawOffset + x.RawSize);
            return section.Rva + offset - section.RawOffset;
        }

        public bool ContainsFileRange(int offset, long length) =>
            offset >= 0 && length >= 0 && offset + length <= _bytes.LongLength;
        public bool IsExecutableVa(uint va) => TryVaToFileOffset(va, out var offset) &&
            Sections.Any(x => x.IsExecutable && offset >= x.RawOffset && offset < x.RawOffset + x.RawSize);
        public byte ReadByteAtFileOffset(int offset) => _bytes[offset];
        public byte[] ReadBytes(int offset, int length) => _bytes.AsSpan(offset, length).ToArray();
        public int ReadInt32AtFileOffset(int offset) => BinaryPrimitives.ReadInt32LittleEndian(_bytes.AsSpan(offset, 4));
        public uint ReadUInt32AtFileOffset(int offset) => BinaryPrimitives.ReadUInt32LittleEndian(_bytes.AsSpan(offset, 4));
    }

    private sealed record PeSection(string Name, int Rva, int RawOffset, int RawSize, int MappedSize,
        bool IsExecutable);
}
