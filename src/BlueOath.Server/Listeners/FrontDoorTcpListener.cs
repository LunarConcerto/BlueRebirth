using System.Buffers.Binary;
using System.Net;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;
using BlueOath.Server.Hosting;
using BlueOath.Server.Infrastructure;
using BlueOath.Server.Sessions;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Listeners;

/// <summary>
/// 主 TCP 监听器。接受连接（可选 TLS），嗅探前几个字节以区分本地 JSON 帧游戏协议与
/// 真实客户端产生的 HTTP/TLS 引导流量，并把每种连接路由到对应的会话处理器。
/// </summary>
internal sealed class FrontDoorTcpListener : BackgroundService
{
    private readonly ServerOptions _options;
    private readonly ServerEndpoints _endpoints;
    private readonly JsonGameSession _jsonSession;
    private readonly BootstrapHttpSession _bootstrapSession;
    private readonly DevelopmentTlsMaterial? _tls;
    private readonly ILogger<FrontDoorTcpListener> _logger;
    private TcpListener? _listener;

    public FrontDoorTcpListener(
        ServerOptions options,
        ServerEndpoints endpoints,
        JsonGameSession jsonSession,
        BootstrapHttpSession bootstrapSession,
        DevelopmentTlsMaterial? tls,
        ILogger<FrontDoorTcpListener> logger)
    {
        _options = options;
        _endpoints = endpoints;
        _jsonSession = jsonSession;
        _bootstrapSession = bootstrapSession;
        _tls = tls;
        _logger = logger;
    }

    public override Task StartAsync(CancellationToken cancellationToken)
    {
        var listener = new TcpListener(IPAddress.Loopback, _options.Port);
        listener.Start();
        _listener = listener;
        // 记录系统分配的真实端口（当 --port=0 时为临时端口）。
        _endpoints.Port = ((IPEndPoint)listener.LocalEndpoint).Port;
        return base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var listener = _listener;
        if (listener is null)
            return;

        try
        {
            var connectionId = 0;
            while (!stoppingToken.IsCancellationRequested)
            {
                var client = await listener.AcceptTcpClientAsync(stoppingToken);
                _ = HandleAsync(client, Interlocked.Increment(ref connectionId), stoppingToken);
            }
        }
        catch (OperationCanceledException)
        {
        }
        finally
        {
            listener.Stop();
        }
    }

    private async Task HandleAsync(TcpClient client, int connectionId, CancellationToken ct)
    {
        using var ownedClient = client;
        try
        {
            await using var stream = await OpenSessionStreamAsync(client, ct);
            // 先读 8 字节前缀（至少 4 字节）用于协议嗅探。
            var header = await ReadPrefixAsync(stream, 8, ct);
            if (header.Length == 0)
                return;

            // 前缀若是合法的大端长度帧，则视为本地 JSON 游戏协议，用回放流把头部喂回解码器。
            if (LooksLikeLocalFrame(header))
            {
                await using var replay = new ReplayPrefixStream(header, stream);
                await _jsonSession.RunAsync(replay, ct);
                return;
            }

            // 否则当作不透明的 HTTP/TLS 引导流量处理。
            await _bootstrapSession.HandleAsync(stream, header, connectionId, _options.CaptureRoot, ct);
        }
        catch (Exception e)
        {
            _logger.LogError(e, "session[{ConnectionId}] failed", connectionId);
        }
    }

    private async Task<Stream> OpenSessionStreamAsync(TcpClient client, CancellationToken ct)
    {
        Stream stream = client.GetStream();
        if (_tls is null)
            return stream;

        // 仅在 --tls-auto 时把连接升级为服务器端 TLS。
        var ssl = new SslStream(stream, leaveInnerStreamOpen: false);
        await ssl.AuthenticateAsServerAsync(new SslServerAuthenticationOptions
        {
            ServerCertificate = _tls.ServerCertificate,
            ClientCertificateRequired = false,
            EnabledSslProtocols = SslProtocols.Tls12,
            CertificateRevocationCheckMode = X509RevocationMode.NoCheck
        }, ct);
        return ssl;
    }

    private static async Task<byte[]> ReadPrefixAsync(Stream stream, int count, CancellationToken ct)
    {
        var buffer = new byte[count];
        var offset = 0;
        while (offset < buffer.Length)
        {
            var read = await stream.ReadAsync(buffer.AsMemory(offset), ct);
            if (read == 0)
                break;
            offset += read;
            if (offset >= 4)
                break;
        }

        return offset == buffer.Length ? buffer : buffer[..offset];
    }

    private static bool LooksLikeLocalFrame(ReadOnlySpan<byte> prefix)
    {
        if (prefix.Length < 4)
            return false;

        // 本地 JSON 帧协议：4 字节大端长度前缀，长度需为正且不超过 4MB。
        var length = BinaryPrimitives.ReadInt32BigEndian(prefix[..4]);
        return length is > 0 and <= 4 * 1024 * 1024;
    }
}
