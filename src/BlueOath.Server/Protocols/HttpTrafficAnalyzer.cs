using System.Text;

namespace BlueOath.Server.Protocols;

/// <summary>抓包流量分析结果：类型、详情（请求行等）与服务器名/主机。</summary>
internal sealed record TrafficAnalysis(string Kind, string Detail, string? ServerName);

/// <summary>
/// 根据负载的前几个字节嗅探连接类型（HTTP / TLS / 空 / 二进制），
/// 供主端口区分 JSON 帧游戏协议与真实客户端的引导流量。
/// </summary>
internal static class HttpTrafficAnalyzer
{
    public static TrafficAnalysis AnalyzePayload(ReadOnlySpan<byte> data)
    {
        if (data.Length == 0)
            return new("empty", "connection closed without data", null);
        if (LooksLikeHttp(data))
            return AnalyzeHttp(data);
        if (data.Length >= 5 && data[0] is >= 0x14 and <= 0x17 && data[1] == 0x03)
            return AnalyzeTls(data);
        return new("binary", $"firstByte=0x{data[0]:X2}", null);
    }

    public static bool LooksLikeHttp(ReadOnlySpan<byte> data)
    {
        var end = data.IndexOf((byte)' ');
        if (end <= 0)
            return false;

        var token = Encoding.ASCII.GetString(data[..Math.Min(end, 8)]);
        return token is "GET" or "POST" or "PUT" or "DELETE" or "HEAD" or "OPTIONS" or "CONNECT" or "PATCH";
    }

    private static TrafficAnalysis AnalyzeHttp(ReadOnlySpan<byte> data)
    {
        var text = Encoding.ASCII.GetString(data[..Math.Min(data.Length, 4096)]);
        var firstLineEnd = text.IndexOf("\r\n", StringComparison.Ordinal);
        var firstLine = firstLineEnd >= 0 ? text[..firstLineEnd] : text;
        var host = text.Split("\r\n", StringSplitOptions.None)
            .FirstOrDefault(x => x.StartsWith("Host:", StringComparison.OrdinalIgnoreCase))?[5..]?.Trim();
        return new("http", firstLine, host);
    }

    private static TrafficAnalysis AnalyzeTls(ReadOnlySpan<byte> data)
    {
        var version = data.Length >= 3 ? $"{data[1]}.{data[2]}" : "unknown";
        return new("tls", $"recordType=0x{data[0]:X2} version={version}", null);
    }
}
