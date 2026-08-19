using BlueOath.Protocol;

namespace BlueOath.Server;

/// <summary>
/// 服务器启动参数（由 <c>--xxx=yyy</c> 命令行开关解析而来）。
/// </summary>
internal sealed record ServerOptions(
    int Port,
    ProtocolProfile Profile,
    string DataRoot,
    bool EnableTls,
    string? TlsOutputRoot,
    string? CaptureRoot,
    bool TlsMaterialOnly,
    int? GameLoginPort,
    int? KcpGameLoginPort,
    int? GmPort)
{
    /// <summary>解析命令行参数；未显式指定的项使用默认值（JP 服、临时端口、本地 data 目录）。</summary>
    public static ServerOptions Parse(string[] args)
    {
        var port = 0;
        var profile = ProtocolProfile.Japan;
        var dataRoot = Path.Combine(AppContext.BaseDirectory, "data");
        var enableTls = false;
        string? tlsOutputRoot = null;
        string? captureRoot = null;
        var tlsMaterialOnly = false;
        int? gameLoginPort = null;
        int? kcpGameLoginPort = null;
        int? gmPort = null;

        foreach (var arg in args)
        {
            if (arg.StartsWith("--port=", StringComparison.OrdinalIgnoreCase))
                int.TryParse(arg[7..], out port);
            else if (arg.StartsWith("--region=", StringComparison.OrdinalIgnoreCase) &&
                arg[9..].Equals("cn", StringComparison.OrdinalIgnoreCase))
                profile = ProtocolProfile.China;
            else if (arg.StartsWith("--data=", StringComparison.OrdinalIgnoreCase))
                dataRoot = arg[7..];
            else if (arg.StartsWith("--capture=", StringComparison.OrdinalIgnoreCase))
                captureRoot = Path.GetFullPath(arg[10..]);
            else if (arg.StartsWith("--tls-output=", StringComparison.OrdinalIgnoreCase))
                tlsOutputRoot = Path.GetFullPath(arg[13..]);
            else if (arg.Equals("--tls-auto", StringComparison.OrdinalIgnoreCase))
                enableTls = true;
            else if (arg.Equals("--tls-material-only", StringComparison.OrdinalIgnoreCase))
                tlsMaterialOnly = true;
            else if (arg.StartsWith("--game-login-port=", StringComparison.OrdinalIgnoreCase) &&
                int.TryParse(arg[18..], out var parsedGameLoginPort) && parsedGameLoginPort is >= 0 and <= 65535)
                gameLoginPort = parsedGameLoginPort;
            else if (arg.StartsWith("--kcp-game-login-port=", StringComparison.OrdinalIgnoreCase) &&
                int.TryParse(arg[22..], out var parsedKcpGameLoginPort) && parsedKcpGameLoginPort is >= 0 and <= 65535)
                kcpGameLoginPort = parsedKcpGameLoginPort;
            else if (arg.StartsWith("--gm-port=", StringComparison.OrdinalIgnoreCase) &&
                int.TryParse(arg[10..], out var parsedGmPort) && parsedGmPort is >= 0 and <= 65535)
                gmPort = parsedGmPort;
        }

        return new ServerOptions(port, profile, dataRoot, enableTls, tlsOutputRoot, captureRoot,
            tlsMaterialOnly, gameLoginPort, kcpGameLoginPort, gmPort);
    }
}
