using System.Text;
using System.Text.Json;
using BlueOath.Server.Protocols;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Sessions;

/// <summary>
/// 在主端口上抓取不透明的 HTTP/TLS 流量：记录摘要、可选持久化，并对纯 HTTP 请求
/// 用对应的 SDK 引导响应回包。
/// </summary>
internal sealed class BootstrapHttpSession(BootstrapHttpResponder responder, ILogger<BootstrapHttpSession> logger)
{
    private readonly BootstrapHttpResponder _responder = responder;
    private readonly ILogger<BootstrapHttpSession> _logger = logger;

    public async Task HandleAsync(Stream stream, ReadOnlyMemory<byte> prefix,
        int connectionId, string? captureRoot, CancellationToken ct)
    {
        using var payload = new MemoryStream();
        await payload.WriteAsync(prefix, ct);
        var buffer = new byte[8192];
        var sentContinue = false;

        while (payload.Length < 64 * 1024 && !ct.IsCancellationRequested)
        {
            // 若已按 Content-Length 收满整个 HTTP 请求，则停止读取。
            if (TryGetCompleteHttpLength(payload.GetBuffer().AsSpan(0, (int)payload.Length), out var completeLength) &&
                payload.Length >= completeLength)
                break;

            // 对带 Expect: 100-continue 的请求先回 100 Continue。
            var headerSpan = payload.GetBuffer().AsSpan(0, (int)payload.Length);
            if (!sentContinue && headerSpan.IndexOf("\r\n\r\n"u8) >= 0 &&
                headerSpan.IndexOf("Expect: 100-continue"u8) >= 0)
            {
                sentContinue = true;
                await stream.WriteAsync("HTTP/1.1 100 Continue\r\n\r\n"u8.ToArray(), ct);
            }

            // 短暂空闲（500ms）后视为请求结束，避免阻塞等待后续字节。
            using var idle = CancellationTokenSource.CreateLinkedTokenSource(ct);
            idle.CancelAfter(500);
            try
            {
                var remaining = (int)Math.Min(buffer.Length, 64 * 1024 - payload.Length);
                var read = await stream.ReadAsync(buffer.AsMemory(0, remaining), idle.Token);
                if (read == 0)
                    break;
                await payload.WriteAsync(buffer.AsMemory(0, read), ct);
            }
            catch (OperationCanceledException) when (!ct.IsCancellationRequested)
            {
                break;
            }
            catch (IOException)
            {
                break;
            }
        }

        var data = payload.ToArray();
        var analysis = HttpTrafficAnalyzer.AnalyzePayload(data);
        _logger.LogInformation("capture[{ConnectionId}] kind={Kind} detail={Detail} host={ServerName}",
            connectionId, analysis.Kind, analysis.Detail, analysis.ServerName);

        // 指定抓包目录时把原始字节与元数据落盘。
        if (captureRoot is not null)
        {
            Directory.CreateDirectory(captureRoot);
            var stem = $"{DateTimeOffset.UtcNow:yyyyMMdd-HHmmss.fff}-{connectionId:D4}";
            var binPath = Path.Combine(captureRoot, stem + ".bin");
            var jsonPath = Path.Combine(captureRoot, stem + ".json");
            await File.WriteAllBytesAsync(binPath, data, CancellationToken.None);
            await File.WriteAllTextAsync(jsonPath, JsonSerializer.Serialize(new
            {
                id = connectionId,
                byteCount = data.Length,
                analysis.Kind,
                analysis.Detail,
                analysis.ServerName,
                previewHex = Convert.ToHexString(data.AsSpan(0, Math.Min(data.Length, 64))),
                file = Path.GetFileName(binPath)
            }), Encoding.UTF8, CancellationToken.None);
        }

        // 只有确认为 HTTP 请求才回引导响应（TLS 由代理终止，这里一般拿不到明文）。
        if (analysis.Kind == "http")
        {
            var response = _responder.BuildResponse(analysis.Detail, analysis.ServerName);
            var bodyBytes = Encoding.UTF8.GetBytes(response.Body);
            var responseHeader = Encoding.ASCII.GetBytes(
                $"HTTP/1.1 {response.StatusCode} {response.ReasonPhrase}\r\n" +
                $"Content-Type: {response.ContentType}\r\n" +
                $"Content-Length: {bodyBytes.Length}\r\nConnection: close\r\n\r\n");
            await stream.WriteAsync(responseHeader, ct);
            await stream.WriteAsync(bodyBytes, ct);
            await stream.FlushAsync(ct);
        }
    }

    private static bool TryGetCompleteHttpLength(ReadOnlySpan<byte> data, out int length)
    {
        length = 0;
        if (!HttpTrafficAnalyzer.LooksLikeHttp(data))
            return false;

        var headerEnd = data.IndexOf("\r\n\r\n"u8);
        if (headerEnd < 0)
            return false;

        // 解析 Content-Length，算出「头 + 正文」的完整长度。
        var bodyStart = headerEnd + 4;
        var headers = Encoding.ASCII.GetString(data[..headerEnd]);
        var contentLength = 0;
        foreach (var line in headers.Split("\r\n", StringSplitOptions.None))
        {
            if (!line.StartsWith("Content-Length:", StringComparison.OrdinalIgnoreCase))
                continue;
            if (!int.TryParse(line[15..].Trim(), out contentLength) || contentLength < 0)
                return false;
            break;
        }

        length = bodyStart + contentLength;
        return true;
    }
}
