using System.Buffers.Binary;
using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;

Console.WriteLine(A.AuthorInfo);

if (args.Contains("--analyze-protocol", StringComparer.OrdinalIgnoreCase))
    return await ProtocolCatalogTool.RunAsync(args);

if (args.Contains("--analyze-config", StringComparer.OrdinalIgnoreCase))
    return await ConfigDatabaseTool.RunAsync(args);

if (args.Contains("--analyze-wire", StringComparer.OrdinalIgnoreCase))
    return await Il2CppMetadataTool.RunWireAsync(args);

if (args.Contains("--analyze-il2cpp", StringComparer.OrdinalIgnoreCase))
    return await Il2CppMetadataTool.RunAsync(args);

if (args.Contains("--config-cs", StringComparer.OrdinalIgnoreCase))
    return ConfigClassTool.RunAsync(args);

if (args.Contains("--config-excel", StringComparer.OrdinalIgnoreCase) ||
    args.Contains("--config-excel-import", StringComparer.OrdinalIgnoreCase) ||
    args.Contains("--config-excel-backup", StringComparer.OrdinalIgnoreCase) ||
    args.Contains("--config-excel-self-test", StringComparer.OrdinalIgnoreCase))
    return await ConfigExcelTool.RunAsync(args);

return await CaptureTool.RunAsync(args);

static class A {
    
    public const string AuthorInfo = "BlueOath Rebirth Server \n By LunarConcerto && Deepseek v4" ;
    
}

static class CaptureTool
{
    private static readonly SemaphoreSlim CaptureLogGate = new(1, 1);

    public static async Task<int> RunAsync(string[] args)
    {
        if (args.Contains("--self-test", StringComparer.OrdinalIgnoreCase))
            return await RunSelfTestAsync();

        var port = ReadInt(args, "--port=", 19090, 1, 65535);
        var duration = ReadInt(args, "--duration=", 30, 1, 3600);
        var maxBytes = ReadInt(args, "--max-bytes=", 65536, 1, 16 * 1024 * 1024);
        var idleMs = ReadInt(args, "--idle-ms=", 1500, 50, 60000);
        var tlsProbe = args.Contains("--tls-probe", StringComparer.OrdinalIgnoreCase);
        var output = ReadString(args, "--output=") ??
            Path.Combine(Environment.CurrentDirectory, "runtime", "captures");
        output = Path.GetFullPath(output);
        Directory.CreateDirectory(output);

        if (tlsProbe)
            return await RunOpenSslProbeAsync(args, port, duration, output);

        using var stop = new CancellationTokenSource(TimeSpan.FromSeconds(duration));
        var listener = new TcpListener(IPAddress.Loopback, port);
        listener.Start();
        var actualPort = ((IPEndPoint)listener.LocalEndpoint).Port;
        Console.WriteLine(JsonSerializer.Serialize(new
        {
            ready = true,
            mode = "capture",
            address = "127.0.0.1",
            port = actualPort,
            durationSeconds = duration,
            maxBytes,
            output
        }));
        Console.Out.Flush();

        var tasks = new List<Task>();
        var sequence = 0;
        try
        {
            while (!stop.IsCancellationRequested)
            {
                var client = await listener.AcceptTcpClientAsync(stop.Token);
                var id = Interlocked.Increment(ref sequence);
                tasks.Add(CaptureAsync(client, id, output, maxBytes, idleMs, stop.Token));
            }
        }
        catch (OperationCanceledException) when (stop.IsCancellationRequested)
        {
        }
        finally
        {
            listener.Stop();
            await Task.WhenAll(tasks);
        }

        Console.WriteLine(JsonSerializer.Serialize(new { complete = true, connections = sequence, output }));
        return 0;
    }

    private static async Task CaptureAsync(TcpClient client, int id, string output, int maxBytes,
        int idleMs, CancellationToken stop)
    {
        using (client)
        {
            var started = DateTimeOffset.UtcNow;
            var remote = client.Client.RemoteEndPoint?.ToString() ?? "unknown";
            using var bytes = new MemoryStream(Math.Min(maxBytes, 65536));
            var buffer = new byte[Math.Min(8192, maxBytes)];
            var timedOut = false;

            while (bytes.Length < maxBytes && !stop.IsCancellationRequested)
            {
                using var idle = CancellationTokenSource.CreateLinkedTokenSource(stop);
                idle.CancelAfter(idleMs);
                try
                {
                    var remaining = maxBytes - (int)bytes.Length;
                    var read = await client.GetStream().ReadAsync(buffer.AsMemory(0, Math.Min(buffer.Length, remaining)), idle.Token);
                    if (read == 0) break;
                    await bytes.WriteAsync(buffer.AsMemory(0, read), stop);
                }
                catch (OperationCanceledException) when (!stop.IsCancellationRequested)
                {
                    timedOut = true;
                    break;
                }
                catch (OperationCanceledException) when (stop.IsCancellationRequested)
                {
                    break;
                }
                catch (IOException)
                {
                    break;
                }
            }

            var data = bytes.ToArray();
            var analysis = TrafficClassifier.Analyze(data);
            var stem = $"{started:yyyyMMdd-HHmmss.fff}-{id:D4}";
            var binaryPath = Path.Combine(output, stem + ".bin");
            await File.WriteAllBytesAsync(binaryPath, data, CancellationToken.None);
            var record = new
            {
                id,
                startedUtc = started,
                remote,
                byteCount = data.Length,
                timedOut,
                truncated = data.Length == maxBytes,
                analysis.Kind,
                analysis.Detail,
                analysis.ServerName,
                previewHex = Convert.ToHexString(data.AsSpan(0, Math.Min(data.Length, 64))),
                file = Path.GetFileName(binaryPath)
            };
            var json = JsonSerializer.Serialize(record);
            await AppendCaptureRecordAsync(Path.Combine(output, "capture.jsonl"), json);
            Console.WriteLine(json);
            Console.Out.Flush();
        }
    }

    private static async Task<int> RunOpenSslProbeAsync(string[] args, int port, int duration, string output)
    {
        var openssl = ResolveOpenSsl(ReadString(args, "--openssl="));
        using var certificate = CreateProbeCertificate();
        var certificatePath = Path.Combine(output, ".tls-probe-leaf.pem");
        var leafCerPath = Path.Combine(output, ".tls-probe-leaf.cer");
        var keyPath = Path.Combine(output, ".tls-probe-leaf-key.pem");
        var rootPemPath = Path.Combine(output, ".tls-probe-root.pem");
        var rootCerPath = Path.Combine(output, ".tls-probe-root.cer");
        var decryptedPath = Path.Combine(output, "decrypted.bin");
        var logPath = Path.Combine(output, "openssl.log");
        await File.WriteAllTextAsync(certificatePath, certificate.Certificate.ExportCertificatePem(), Encoding.ASCII);
        await File.WriteAllBytesAsync(leafCerPath, certificate.Certificate.Export(X509ContentType.Cert));
        await File.WriteAllTextAsync(keyPath, certificate.Key.ExportPkcs8PrivateKeyPem(), Encoding.ASCII);
        await File.WriteAllTextAsync(rootPemPath, certificate.RootCertificate.ExportCertificatePem(), Encoding.ASCII);
        await File.WriteAllBytesAsync(rootCerPath, certificate.RootCertificate.Export(X509ContentType.Cert));

        try
        {
            var start = new ProcessStartInfo(openssl)
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                WorkingDirectory = output
            };
            var probeArguments = new List<string>
            {
                "s_server", "-accept", $"127.0.0.1:{port}", "-cert", certificatePath,
                "-key", keyPath,
                "-tls1_2", "-quiet", "-state", "-tlsextdebug"
            };
            var leafOnly = args.Contains("--leaf-only", StringComparer.OrdinalIgnoreCase);
            if (!leafOnly)
            {
                probeArguments.Add("-cert_chain");
                probeArguments.Add(rootPemPath);
            }
            var cipher = ReadString(args, "--cipher=");
            if (!string.IsNullOrWhiteSpace(cipher))
            {
                probeArguments.Add("-cipher");
                probeArguments.Add(cipher);
            }
            foreach (var argument in probeArguments)
                start.ArgumentList.Add(argument);

            using var process = Process.Start(start) ?? throw new InvalidOperationException("Unable to start OpenSSL");
            await using (var decrypted = new FileStream(decryptedPath, FileMode.Create, FileAccess.Write, FileShare.Read))
            await using (var log = new FileStream(logPath, FileMode.Create, FileAccess.Write, FileShare.Read))
            {
                var copyOutput = process.StandardOutput.BaseStream.CopyToAsync(decrypted);
                var copyError = process.StandardError.BaseStream.CopyToAsync(log);
                Console.WriteLine(JsonSerializer.Serialize(new
                {
                    ready = true,
                    mode = "tls-probe",
                    address = "127.0.0.1",
                    port,
                    durationSeconds = duration,
                    certificateSha256 = certificate.Certificate.GetCertHashString(HashAlgorithmName.SHA256),
                    leafCertificateFile = leafCerPath,
                    rootCertificateSha256 = certificate.RootCertificate.GetCertHashString(HashAlgorithmName.SHA256),
                    rootCertificateFile = rootCerPath,
                    leafOnly,
                    openssl,
                    output
                }));
                Console.Out.Flush();

                using var stop = new CancellationTokenSource(TimeSpan.FromSeconds(duration));
                try
                {
                    await process.WaitForExitAsync(stop.Token);
                }
                catch (OperationCanceledException)
                {
                    process.Kill(entireProcessTree: true);
                    await process.WaitForExitAsync();
                }
                await Task.WhenAll(copyOutput, copyError);
            }

            var data = await File.ReadAllBytesAsync(decryptedPath);
            var analysis = TrafficClassifier.Analyze(data);
            var record = new
            {
                complete = true,
                byteCount = data.Length,
                analysis.Kind,
                analysis.Detail,
                analysis.ServerName,
                previewHex = Convert.ToHexString(data.AsSpan(0, Math.Min(data.Length, 64))),
                decryptedFile = Path.GetFileName(decryptedPath),
                logFile = Path.GetFileName(logPath),
                processExitCode = process.ExitCode,
                output
            };
            var json = JsonSerializer.Serialize(record);
            await AppendCaptureRecordAsync(Path.Combine(output, "capture.jsonl"), json);
            Console.WriteLine(json);
            return 0;
        }
        finally
        {
            File.Delete(certificatePath);
            File.Delete(leafCerPath);
            File.Delete(keyPath);
            File.Delete(rootPemPath);
            File.Delete(rootCerPath);
        }
    }

    private static async Task<int> RunSelfTestAsync()
    {
        var http = TrafficClassifier.Analyze("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"u8.ToArray());
        var tls = TrafficClassifier.Analyze(new byte[] { 0x16, 0x03, 0x01, 0x00, 0x04, 0x01, 0, 0, 0 });
        var binary = TrafficClassifier.Analyze(new byte[] { 0x08, 0x96, 0x01 });
        if (http.Kind != "http" || tls.Kind != "tls" || binary.Kind != "binary")
            throw new InvalidOperationException("Traffic classifier self-test failed");

        using var certificate = CreateProbeCertificate();
        if (!certificate.Certificate.HasPrivateKey || certificate.Certificate.NotAfter <= DateTime.UtcNow)
            throw new InvalidOperationException("TLS probe certificate self-test failed");
        using var chain = new X509Chain();
        chain.ChainPolicy.TrustMode = X509ChainTrustMode.CustomRootTrust;
        chain.ChainPolicy.CustomTrustStore.Add(certificate.RootCertificate);
        chain.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;
        if (!chain.Build(certificate.Certificate))
            throw new InvalidOperationException("TLS probe certificate chain self-test failed");
        if (!certificate.Certificate.ExportCertificatePem().Contains("BEGIN CERTIFICATE", StringComparison.Ordinal) ||
            !certificate.Key.ExportPkcs8PrivateKeyPem().Contains("BEGIN PRIVATE KEY", StringComparison.Ordinal))
            throw new InvalidOperationException("TLS probe PEM export self-test failed");

        var testDirectory = Path.Combine(Path.GetTempPath(), $"blueoath-capture-{Guid.NewGuid():N}");
        Directory.CreateDirectory(testDirectory);
        try
        {
            var logPath = Path.Combine(testDirectory, "capture.jsonl");
            const int recordCount = 64;
            await Task.WhenAll(Enumerable.Range(1, recordCount)
                .Select(id => AppendCaptureRecordAsync(logPath, JsonSerializer.Serialize(new { id }))));
            var lines = await File.ReadAllLinesAsync(logPath);
            if (lines.Length != recordCount)
                throw new InvalidOperationException($"Capture log self-test expected {recordCount} records, got {lines.Length}");
        }
        finally
        {
            Directory.Delete(testDirectory, recursive: true);
        }

        Console.WriteLine("capture classifier self-test passed");
        return 0;
    }

    private static async Task AppendCaptureRecordAsync(string path, string json)
    {
        await CaptureLogGate.WaitAsync();
        try
        {
            await File.AppendAllTextAsync(path, json + Environment.NewLine, Encoding.UTF8, CancellationToken.None);
        }
        finally
        {
            CaptureLogGate.Release();
        }
    }

    private static ProbeCertificate CreateProbeCertificate()
    {
        var rootKey = RSA.Create(2048);
        var rootRequest = new CertificateRequest(
            "CN=BlueOath Local Development Root",
            rootKey,
            HashAlgorithmName.SHA256,
            RSASignaturePadding.Pkcs1);
        rootRequest.CertificateExtensions.Add(new X509BasicConstraintsExtension(true, false, 0, true));
        rootRequest.CertificateExtensions.Add(new X509KeyUsageExtension(
            X509KeyUsageFlags.KeyCertSign | X509KeyUsageFlags.CrlSign,
            true));
        rootRequest.CertificateExtensions.Add(new X509SubjectKeyIdentifierExtension(rootRequest.PublicKey, false));
        var rootCertificate = rootRequest.CreateSelfSigned(
            DateTimeOffset.UtcNow.AddMinutes(-5),
            DateTimeOffset.UtcNow.AddDays(7));

        var leafKey = RSA.Create(2048);
        var leafRequest = new CertificateRequest(
            "CN=mapijpshipgirl.blueoath.com",
            leafKey,
            HashAlgorithmName.SHA256,
            RSASignaturePadding.Pkcs1);
        leafRequest.CertificateExtensions.Add(new X509BasicConstraintsExtension(false, false, 0, true));
        leafRequest.CertificateExtensions.Add(new X509KeyUsageExtension(
            X509KeyUsageFlags.DigitalSignature | X509KeyUsageFlags.KeyEncipherment,
            true));
        var enhancedKeyUsage = new OidCollection { new("1.3.6.1.5.5.7.3.1") };
        leafRequest.CertificateExtensions.Add(new X509EnhancedKeyUsageExtension(enhancedKeyUsage, true));
        var names = new SubjectAlternativeNameBuilder();
        names.AddDnsName("mapijpshipgirl.blueoath.com");
        names.AddDnsName("haina.blueoath.com");
        names.AddDnsName("localhost");
        names.AddIpAddress(IPAddress.Loopback);
        leafRequest.CertificateExtensions.Add(names.Build());
        leafRequest.CertificateExtensions.Add(new X509SubjectKeyIdentifierExtension(leafRequest.PublicKey, false));

        var serial = RandomNumberGenerator.GetBytes(16);
        using var unsignedLeaf = leafRequest.Create(
            rootCertificate,
            DateTimeOffset.UtcNow.AddMinutes(-5),
            DateTimeOffset.UtcNow.AddDays(7),
            serial);
        var leafCertificate = unsignedLeaf.CopyWithPrivateKey(leafKey);
        return new ProbeCertificate(rootCertificate, rootKey, leafCertificate, leafKey);
    }

    private static string ResolveOpenSsl(string? requestedPath)
    {
        if (!string.IsNullOrWhiteSpace(requestedPath) && File.Exists(requestedPath))
            return Path.GetFullPath(requestedPath);
        var gitOpenSsl = @"C:\Program Files\Git\usr\bin\openssl.exe";
        if (File.Exists(gitOpenSsl)) return gitOpenSsl;
        var fromPath = (Environment.GetEnvironmentVariable("PATH") ?? string.Empty)
            .Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries)
            .Select(path => Path.Combine(path.Trim(), "openssl.exe"))
            .FirstOrDefault(File.Exists);
        return fromPath ?? throw new FileNotFoundException(
            "OpenSSL was not found. Supply --openssl=<absolute path> for --tls-probe.");
    }

    private sealed class ProbeCertificate : IDisposable
    {
        public ProbeCertificate(X509Certificate2 rootCertificate, RSA rootKey,
            X509Certificate2 certificate, RSA key)
        {
            RootCertificate = rootCertificate;
            RootKey = rootKey;
            Certificate = certificate;
            Key = key;
        }

        public X509Certificate2 RootCertificate { get; }
        public RSA RootKey { get; }
        public X509Certificate2 Certificate { get; }
        public RSA Key { get; }

        public void Dispose()
        {
            Certificate.Dispose();
            Key.Dispose();
            RootCertificate.Dispose();
            RootKey.Dispose();
        }
    }

    private static int ReadInt(string[] args, string prefix, int fallback, int minimum, int maximum)
    {
        var text = ReadString(args, prefix);
        if (text is null) return fallback;
        if (!int.TryParse(text, out var value) || value < minimum || value > maximum)
            throw new ArgumentOutOfRangeException(prefix, text, $"Expected {minimum}..{maximum}");
        return value;
    }

    private static string? ReadString(string[] args, string prefix) =>
        args.FirstOrDefault(x => x.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))?[prefix.Length..];
}

static class TrafficClassifier
{
    internal sealed record Result(string Kind, string Detail, string? ServerName = null);

    public static Result Analyze(ReadOnlySpan<byte> data)
    {
        if (data.Length == 0) return new("empty", "connection closed without data");
        if (LooksLikeHttp(data)) return AnalyzeHttp(data);
        if (data.Length >= 5 && data[0] is >= 0x14 and <= 0x17 && data[1] == 0x03)
            return AnalyzeTls(data);
        return new("binary", $"firstByte=0x{data[0]:X2}");
    }

    private static bool LooksLikeHttp(ReadOnlySpan<byte> data)
    {
        ReadOnlySpan<byte> methods = "GET POST PUT DELETE HEAD OPTIONS CONNECT PATCH HTTP/"u8;
        var end = data.IndexOf((byte)' ');
        var token = end >= 0 ? data[..end] : data[..Math.Min(data.Length, 8)];
        return methods.IndexOf(token) >= 0;
    }

    private static Result AnalyzeHttp(ReadOnlySpan<byte> data)
    {
        var text = Encoding.ASCII.GetString(data[..Math.Min(data.Length, 4096)]);
        var firstLineEnd = text.IndexOf("\r\n", StringComparison.Ordinal);
        var firstLine = firstLineEnd >= 0 ? text[..firstLineEnd] : text;
        var host = text.Split("\r\n", StringSplitOptions.None)
            .FirstOrDefault(x => x.StartsWith("Host:", StringComparison.OrdinalIgnoreCase))?[5..]?.Trim();
        return new("http", firstLine, host);
    }

    private static Result AnalyzeTls(ReadOnlySpan<byte> data)
    {
        var version = data.Length >= 3 ? $"{data[1]}.{data[2]}" : "unknown";
        return new("tls", $"recordType=0x{data[0]:X2} version={version}", TryReadTlsServerName(data));
    }

    private static string? TryReadTlsServerName(ReadOnlySpan<byte> data)
    {
        if (data.Length < 9 || data[0] != 0x16 || data[5] != 0x01) return null;
        var offset = 9 + 2 + 32;
        if (!SkipVector8(data, ref offset) || offset + 2 > data.Length) return null;
        var cipherLength = BinaryPrimitives.ReadUInt16BigEndian(data[offset..]);
        offset += 2 + cipherLength;
        if (!SkipVector8(data, ref offset) || offset + 2 > data.Length) return null;
        var extensionsLength = BinaryPrimitives.ReadUInt16BigEndian(data[offset..]);
        offset += 2;
        var end = Math.Min(data.Length, offset + extensionsLength);
        while (offset + 4 <= end)
        {
            var type = BinaryPrimitives.ReadUInt16BigEndian(data[offset..]);
            var length = BinaryPrimitives.ReadUInt16BigEndian(data[(offset + 2)..]);
            offset += 4;
            if (offset + length > end) return null;
            if (type == 0 && length >= 5)
            {
                var listOffset = offset + 2;
                if (listOffset + 3 > offset + length || data[listOffset] != 0) return null;
                var nameLength = BinaryPrimitives.ReadUInt16BigEndian(data[(listOffset + 1)..]);
                if (listOffset + 3 + nameLength > offset + length) return null;
                return Encoding.ASCII.GetString(data.Slice(listOffset + 3, nameLength));
            }
            offset += length;
        }
        return null;
    }

    private static bool SkipVector8(ReadOnlySpan<byte> data, ref int offset)
    {
        if (offset >= data.Length) return false;
        offset += 1 + data[offset];
        return offset <= data.Length;
    }
}
