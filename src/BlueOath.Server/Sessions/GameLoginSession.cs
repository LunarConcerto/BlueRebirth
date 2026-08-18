using System.Net.Sockets;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Infrastructure;
using BlueOath.Server.Protocols;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Sessions;

/// <summary>
/// 游戏登录 TCP 端点的每个连接处理器（承载 protobuf <c>TMessage</c> 请求/响应层的
/// NetSocket 帧）。会话内跟踪当前 profileId，使角色/船坞数据按账号从存档读取。
/// </summary>
internal sealed class GameLoginSession(GameLoginMessageHandler handler, ILoggerFactory loggerFactory)
{
    private readonly GameLoginMessageHandler _handler = handler;
    private readonly ILogger _fileLogger = loggerFactory.CreateLogger(GameLoginFileLoggerProvider.Category);

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

                    // player.Login 先解析 pid，更新会话的 profileId，后续请求按该账号读取。
                    if (request.Method == "player.Login")
                        profileId = _handler.ResolveLoginProfileId(request);

                    // 在 user.UserLogin 应答前先推送 user.UpdateUserInfo，确保
                    // Data.userData.m_TypeNumMap 在 LoginOk 事件触发前已初始化。
                    // 同时推送 guide.GuideInfo，确保 GuideManager:init 读取到
                    // GUIDE_DONE_STAGES，避免触发新手引导。
                    if (request.Method == "user.UserLogin")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        var push = await _handler.BuildUpdateUserInfoPushAsync(profileId, now, ct);
                        await NetSocketFrameCodec.WriteAsync(stream, push, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push user.UpdateUserInfo (before LoginOk)",
                            connectionId);
                        var guidePush = _handler.BuildGuideInfoPush(now);
                        await NetSocketFrameCodec.WriteAsync(stream, guidePush, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push guide.GuideInfo (before LoginOk)",
                            connectionId);
                    }

                    var (_, responsePayload) = await _handler.BuildC2SResponseAsync(request, profileId, ct);
                    if (responsePayload.Length == 0)
                        continue;
                    await NetSocketFrameCodec.WriteAsync(stream, responsePayload, NetSocketFrameCodec.TypeData, ct);
                    _fileLogger.LogInformation(
                        "game-login[{ConnectionId}] response bytes={Bytes} hex={Hex}",
                        connectionId, responsePayload.Length, Convert.ToHexString(responsePayload));

                    // 用户信息请求应答后，再主动推送主界面所需的玩家域数据。
                    if (request.Method == "user.GetUserInfo")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());

                        var push = await _handler.BuildUpdateUserInfoPushAsync(profileId, now, ct);
                        await NetSocketFrameCodec.WriteAsync(stream, push, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push user.UpdateUserInfo bytes={Bytes} hex={Hex}",
                            connectionId, push.Length, Convert.ToHexString(push));

                        foreach (var extra in await _handler.BuildSyncPushesAsync(profileId, now, ct))
                        {
                            await NetSocketFrameCodec.WriteAsync(stream, extra, NetSocketFrameCodec.TypeData, ct);
                            _fileLogger.LogInformation(
                                "game-login[{ConnectionId}] push sync bytes={Bytes} hex={Hex}",
                                connectionId, extra.Length, Convert.ToHexString(extra));
                        }
                    }

                    // 购买应答后，推送更新后的货币/仓库/时装数据。
                    if (request.Method == "shop.BuyGoods" || request.Method == "shop.QualityBuyGoods")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        foreach (var extra in await _handler.BuildPostBuyPushesAsync(profileId, now, ct))
                        {
                            await NetSocketFrameCodec.WriteAsync(stream, extra, NetSocketFrameCodec.TypeData, ct);
                            _fileLogger.LogInformation(
                                "game-login[{ConnectionId}] push post-buy bytes={Bytes} hex={Hex}",
                                connectionId, extra.Length, Convert.ToHexString(extra));
                        }
                    }

                    // 邮件领取应答后，推送更新后的货币数据。
                    if (request.Method == "mail.FetchItem" || request.Method == "mail.FetchAllItems")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        var push = await _handler.BuildUpdateUserInfoPushAsync(profileId, now, ct);
                        await NetSocketFrameCodec.WriteAsync(stream, push, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push post-mail user info bytes={Bytes} hex={Hex}",
                            connectionId, push.Length, Convert.ToHexString(push));
                    }

                    // 装备穿脱应答后，推送更新后的英雄 + 装备数据。
                    if (request.Method == "hero.ChangeEquip")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        foreach (var extra in await _handler.BuildPostEquipPushesAsync(profileId, now, ct))
                        {
                            await NetSocketFrameCodec.WriteAsync(stream, extra, NetSocketFrameCodec.TypeData, ct);
                            _fileLogger.LogInformation(
                                "game-login[{ConnectionId}] push post-equip bytes={Bytes} hex={Hex}",
                                connectionId, extra.Length, Convert.ToHexString(extra));
                        }
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
