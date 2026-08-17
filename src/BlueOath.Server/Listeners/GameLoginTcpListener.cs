using System.Net;
using System.Net.Sockets;
using BlueOath.Server.Hosting;
using BlueOath.Server.Sessions;
using Microsoft.Extensions.Hosting;

namespace BlueOath.Server.Listeners;

/// <summary>
/// 游戏登录 TCP 端点（NetSocket 帧）。只监听回环地址，把每个连接交给
/// <see cref="GameLoginSession"/> 处理。
/// </summary>
internal sealed class GameLoginTcpListener : BackgroundService
{
    private readonly ServerOptions _options;
    private readonly ServerEndpoints _endpoints;
    private readonly GameLoginSession _session;
    private TcpListener? _listener;

    public GameLoginTcpListener(ServerOptions options, ServerEndpoints endpoints, GameLoginSession session)
    {
        _options = options;
        _endpoints = endpoints;
        _session = session;
    }

    public override Task StartAsync(CancellationToken cancellationToken)
    {
        // 未指定 --game-login-port 时该端点不启用。
        if (_options.GameLoginPort is not { } port)
            return Task.CompletedTask;

        var listener = new TcpListener(IPAddress.Loopback, port);
        listener.Start();
        _listener = listener;
        _endpoints.GameLoginPort = ((IPEndPoint)listener.LocalEndpoint).Port;
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
                _ = _session.HandleAsync(client, Interlocked.Increment(ref connectionId), stoppingToken);
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
}
