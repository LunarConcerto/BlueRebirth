using System.Net.Sockets;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Infrastructure;
using BlueOath.Server.Protocols;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Sessions;

/// <summary>
/// 游戏登录 TCP 端点的每个连接处理器（承载 protobuf <c>TMessage</c> 请求/响应层的
/// NetSocket 帧）。会话内跟踪当前 profileId，并把所有请求交给 <see cref="MessageRouter"/>
/// 分发到对应模块；按「前置推送 → 应答 → 后置推送」写回客户端。
/// </summary>
internal sealed class GameLoginSession(MessageRouter router, ILoggerFactory loggerFactory)
{
    private readonly MessageRouter _router = router;
    private readonly ILogger _fileLogger = loggerFactory.CreateLogger(GameLoginFileLoggerProvider.Category);
    private readonly ILogger _messageLogger = loggerFactory.CreateLogger("SocketSession");

    public async Task HandleAsync(TcpClient client, int connectionId, CancellationToken ct)
    {
        using (client)
        {
            var profileId = PlayerAccountFactory.DefaultProfileId;
            var remote = client.Client.RemoteEndPoint?.ToString() ?? "unknown";
            _fileLogger.LogInformation("game-login[{ConnectionId}] accepted remote={Remote}", connectionId, remote);
            try
            {
                var stream = client.GetStream();
                while (!ct.IsCancellationRequested)
                {
                    var frame = await NetSocketFrameCodec.ReadAsync(stream, ct);
                    if (frame is null)
                        break;
                    var (type, payload) = frame.Value;
                    _fileLogger.LogInformation(
                        "game-login[{ConnectionId}] netsocket type={Type} len={Length} preview={Preview}",
                        connectionId, type, payload.Length,
                        Convert.ToHexString(payload.AsSpan(0, Math.Min(payload.Length, 16))));
                    // 心跳帧直接原样回 ping。
                    if (type == NetSocketFrameCodec.TypePing)
                    {
                        await NetSocketFrameCodec.WriteAsync(stream, ReadOnlyMemory<byte>.Empty,
                            NetSocketFrameCodec.TypePing, ct);
                        continue;
                    }
                    if (payload.Length == 0)
                        continue;

                    var request = TMessageCodec.DecodeRequest(payload);
                    _messageLogger.Log(LogLevel.Information, "GameSession received request method={Method}", request.Method);

                    // player.Login 先解析 pid，更新会话的 profileId，后续请求按该账号读取。
                    if (request.Method == "player.Login")
                        profileId = _router.ResolveLoginProfileId(request);

                    var result = await _router.DispatchAsync(request, profileId, ct);

                    foreach (var push in result.PrePushes)
                    {
                        await NetSocketFrameCodec.WriteAsync(stream, push, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push (before response) bytes={Bytes}",
                            connectionId, push.Length);
                    }

                    // 每个请求都回一个 TResponse 信封（即使 Ret 为空），客户端按方法名接收。
                    var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                    var response = new TResponse(Err: result.Err, ErrMsg: result.ErrMsg,
                        Method: request.Method, Ret: result.Ret,
                        CallbackHandler: request.CallbackHandler, Time: now,
                        Token: request.Token, Seq: 0, IsResponse: 1);
                    var encoded = TMessageCodec.EncodeResponse(response);
                    await NetSocketFrameCodec.WriteAsync(stream, encoded, NetSocketFrameCodec.TypeData, ct);
                    _fileLogger.LogInformation(
                        "game-login[{ConnectionId}] response bytes={Bytes} hex={Hex}",
                        connectionId, encoded.Length, Convert.ToHexString(encoded));

                    foreach (var push in result.PostPushes)
                    {
                        await NetSocketFrameCodec.WriteAsync(stream, push, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push (after response) bytes={Bytes}",
                            connectionId, push.Length);
                    }
                }
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
            }
            catch (Exception ex)
            {
                _fileLogger.LogInformation("game-login[{ConnectionId}] failed: {Error}", connectionId, ex);
            }
        }
    }
}
