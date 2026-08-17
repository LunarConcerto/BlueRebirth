using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using BlueOath.Protocol;
using BlueOath.Server.Hosting;
using BlueOath.Server.Protocols;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Listeners;

/// <summary>
/// KCP/UDP 上的游戏登录端点。接收 KCP 数据报，为每个会话运行 ARQ 可靠性层，
/// 并对从重组出的应用层流中解码出的登录/C2S 消息做出响应。
/// </summary>
internal sealed class KcpGameLoginListener : BackgroundService
{
    private readonly ServerOptions _options;
    private readonly ServerEndpoints _endpoints;
    private readonly GameLoginMessageHandler _handler;
    private readonly ILogger<KcpGameLoginListener> _logger;
    private readonly ConcurrentDictionary<uint, KcpPeer> _peers = [];
    private UdpClient? _listener;

    public KcpGameLoginListener(
        ServerOptions options,
        ServerEndpoints endpoints,
        GameLoginMessageHandler handler,
        ILogger<KcpGameLoginListener> logger)
    {
        _options = options;
        _endpoints = endpoints;
        _handler = handler;
        _logger = logger;
    }

    public override Task StartAsync(CancellationToken cancellationToken)
    {
        // 未指定 --kcp-game-login-port 时该端点不启用。
        if (_options.KcpGameLoginPort is not { } port)
            return Task.CompletedTask;

        var listener = new UdpClient(new IPEndPoint(IPAddress.Loopback, port));
        _listener = listener;
        _endpoints.KcpGameLoginPort = ((IPEndPoint)listener.Client.LocalEndPoint!).Port;
        return base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var listener = _listener;
        if (listener is null)
            return;

        try
        {
            // 独立的发送刷新循环：周期性地重传/推送每个 KCP 连接待发送的数据报。
            var flushTask = FlushConnectionsAsync(listener, stoppingToken);
            try
            {
                while (!stoppingToken.IsCancellationRequested)
                {
                    var result = await listener.ReceiveAsync(stoppingToken);
                    await HandleDatagramAsync(listener, result.Buffer, result.RemoteEndPoint, stoppingToken);
                }
            }
            catch (OperationCanceledException)
            {
            }
            finally
            {
                await flushTask;
            }
        }
        finally
        {
            listener.Dispose();
        }
    }

    private async Task FlushConnectionsAsync(UdpClient listener, CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(100, ct);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            var now = NowMs();
            foreach (var peer in _peers.Values)
            {
                foreach (var datagram in peer.Connection.Flush(now))
                {
                    try { await listener.SendAsync(datagram, peer.Endpoint, ct); }
                    catch (Exception) { break; }
                }
            }
        }
    }

    private async Task HandleDatagramAsync(UdpClient listener, byte[] datagram, IPEndPoint remote, CancellationToken ct)
    {
        try
        {
            var now = NowMs();
            KcpPeer? touched = null;
            var offset = 0;
            // 一个 UDP 数据报可能粘包携带多个 KCP 包，逐个解码处理。
            while (offset < datagram.Length &&
                   KcpCodec.TryDecode(datagram.AsSpan(offset), out var packet, out var consumed))
            {
                offset += consumed;
                // 以 conv 为键复用/创建对应会话。
                var peer = _peers.GetOrAdd(packet.Conv, conv => new KcpPeer(new KcpConnection(conv), remote));
                touched = peer;
                foreach (var message in peer.Connection.Input(packet, now))
                {
                    var response = await BuildLoginResponseAsync(message, ct);
                    if (response.Length == 0)
                        continue;
                    peer.Connection.Send(response, now);
                }
            }

            // 立刻尝试发送该会话待发数据（其余会话由周期刷新循环处理）。
            if (touched is not null)
            {
                foreach (var output in touched.Connection.Flush(now))
                    await listener.SendAsync(output, touched.Endpoint, ct);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "kcp-game-login failed from {Remote}", remote);
        }
    }

    private async Task<byte[]> BuildLoginResponseAsync(byte[] message, CancellationToken ct)
    {
        var frame = ClientGameWireCodec.DecodeClientRequest(message);
        _logger.LogInformation(
            "kcp-game-login decoded channel={Channel} operation={Operation} session={SessionId} state={State}",
            frame.Channel, frame.Operation, frame.SessionId, frame.State);
        if (frame.Channel != ClientGameWireCodec.DefaultChannel)
            return [];
        // 按操作码路由：登录走 BuildLoginPayloadAsync，C2S 走 BuildC2SResponse。
        var (operation, payload) = frame.Operation switch
        {
            GameOperationCodes.Login => await _handler.BuildLoginPayloadAsync(frame.Payload, ct),
            GameOperationCodes.C2S => _handler.BuildC2SResponse(frame.Payload),
            _ => (0, Array.Empty<byte>())
        };
        return operation == 0 ? [] : ClientGameWireCodec.EncodeServerResponse((byte)operation, payload);
    }

    private static uint NowMs() => (uint)DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

    private sealed class KcpPeer(KcpConnection connection, IPEndPoint endpoint)
    {
        public KcpConnection Connection { get; } = connection;
        public IPEndPoint Endpoint { get; set; } = endpoint;
    }
}
