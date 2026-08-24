using System.Net.Sockets;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Infrastructure;
using BlueOath.Server.Protocols;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Console;

namespace BlueOath.Server.Sessions;

internal sealed class GameLoginSession(GameLoginMessageHandler handler, ILoggerFactory loggerFactory)
{
    private readonly GameLoginMessageHandler _handler = handler;
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

                    if (request.Method == "player.Login")
                        profileId = _handler.ResolveLoginProfileId(request);

                    if (request.Method == "user.UserLogin")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        var account = await _handler.GetAccountAsync(profileId, ct);
                        var push = await _handler.BuildUpdateUserInfoPushAsync(profileId, now, ct);
                        await NetSocketFrameCodec.WriteAsync(stream, push, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push user.UpdateUserInfo (before LoginOk)",
                            connectionId);
                        var guidePush = _handler.BuildGuideInfoPush(now, account);
                        await NetSocketFrameCodec.WriteAsync(stream, guidePush, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push guide.GuideInfo (before LoginOk)",
                            connectionId);
                    }

                    if (request.Method == "guide.PlotReward")
                    {
                        var (_, plotPayload) = await _handler.BuildC2SResponseAsync(request, profileId, ct);
                        await NetSocketFrameCodec.WriteAsync(stream, plotPayload, NetSocketFrameCodec.TypeData, ct);
                        continue;
                    }

                    if (request.Method == "buildship.BuildShip")
                    {
                        var (_, buildPayload) = await _handler.BuildC2SResponseAsync(request, profileId, ct);
                        if (buildPayload.Length != 0)
                        {
                            var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                            var account = await _handler.GetAccountAsync(profileId, ct);
                            var newIds = _handler.GetLastBuildHeroIds();
                            var newHeroes = account.Dock.Heroes
                                .Where(h => newIds.Contains(h.HeroId))
                                .Select(h => new HeroGrid(h.HeroId, h.TemplateId, h.Level, h.Fashioning, h.Exp, h.CreateTime, h.UpdateTime, h.Affection, h.MarryTime, h.CurHp, h.Mood, h.MarryType, h.EquipSlots, Name: ShipHandbookLoader.GetShipName(h.TemplateId)))
                                .ToList();
                            if (newHeroes.Count > 0)
                            {
                                var heroPush = TMessageCodec.EncodeResponse(new TResponse(
                                    Method: "hero.UpdateHeroBagData",
                                    Ret: PlayerDataCodec.Encode(new HeroBag(newHeroes, account.Dock.BagSize)),
                                    Time: now));
                                await NetSocketFrameCodec.WriteAsync(stream, heroPush, NetSocketFrameCodec.TypeData, ct);
                                var illustratePush = TMessageCodec.EncodeResponse(new TResponse(
                                    Method: "illustrate.IllustrateInfo",
                                    Ret: PlayerDataCodec.Encode(new IllustrateInfoRet(
                                        IllustrateList: newHeroes
                                            .Select(h => new IllustrateInfo((h.TemplateId - 1) / 10, now, 0, false, null, 0))
                                            .ToList(),
                                        IllustrateEquipList: [new IllustrateEquipInfo()])),
                                    Time: now));
                                await NetSocketFrameCodec.WriteAsync(stream, illustratePush, NetSocketFrameCodec.TypeData, ct);
                                _fileLogger.LogInformation(
                                    "game-login[{ConnectionId}] push hero+ill (before build response) h={HeroBytes} i={IllBytes}",
                                    connectionId, heroPush.Length, illustratePush.Length);
                            }
                        }
                        await NetSocketFrameCodec.WriteAsync(stream, buildPayload, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] response bytes={Bytes}",
                            connectionId, buildPayload.Length);
                        continue;
                    }

                    var (_, responsePayload) = await _handler.BuildC2SResponseAsync(request, profileId, ct);
                    if (responsePayload.Length == 0)
                        continue;
                    await NetSocketFrameCodec.WriteAsync(stream, responsePayload, NetSocketFrameCodec.TypeData, ct);
                    _fileLogger.LogInformation(
                        "game-login[{ConnectionId}] response bytes={Bytes} hex={Hex}",
                        connectionId, responsePayload.Length, Convert.ToHexString(responsePayload));

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

                    if (request.Method == "mail.FetchItem" || request.Method == "mail.FetchAllItems")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        var push = await _handler.BuildUpdateUserInfoPushAsync(profileId, now, ct);
                        await NetSocketFrameCodec.WriteAsync(stream, push, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push post-mail user info bytes={Bytes} hex={Hex}",
                            connectionId, push.Length, Convert.ToHexString(push));
                    }

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

                    if (request.Method is "user.SetUserSecretary" or "user.ChangeName"
                        or "user.SetMessage" or "user.SetPlayerHeadFrame" or "user.SetHead")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        var push = await _handler.BuildUpdateUserInfoPushAsync(profileId, now, ct);
                        await NetSocketFrameCodec.WriteAsync(stream, push, NetSocketFrameCodec.TypeData, ct);
                        _fileLogger.LogInformation(
                            "game-login[{ConnectionId}] push user info after profile update bytes={Bytes}",
                            connectionId, push.Length);
                    }

                    if (request.Method == "hero.AddExp")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        var account = await _handler.GetAccountAsync(profileId, ct);
                        var heroes = account.Dock.Heroes.Select(h => new HeroGrid(h.HeroId, h.TemplateId, h.Level, h.Fashioning, h.Exp, h.CreateTime, h.UpdateTime, h.Affection, h.MarryTime, h.CurHp, h.Mood, h.MarryType, h.EquipSlots, Name: ShipHandbookLoader.GetShipName(h.TemplateId))).ToList();
                        var heroPush = TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                            Time: now));
                        var bagPush = TMessageCodec.EncodeResponse(new TResponse(
                            Method: "bag.UpdateBagData",
                            Ret: PlayerDataCodec.Encode(new BagInfoRet(BagType: 1, BagSize: (account.Bag ?? new PlayerBag([], 100)).BagSize,
                                BagInfo: (account.Bag?.Items ?? []).Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList())),
                            Time: now));
                        await NetSocketFrameCodec.WriteAsync(stream, heroPush, NetSocketFrameCodec.TypeData, ct);
                        await NetSocketFrameCodec.WriteAsync(stream, bagPush, NetSocketFrameCodec.TypeData, ct);
                    }

                    if (request.Method == "hero.Marry")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        var account = await _handler.GetAccountAsync(profileId, ct);
                        var heroes = account.Dock.Heroes.Select(h => new HeroGrid(h.HeroId, h.TemplateId, h.Level, h.Fashioning, h.Exp, h.CreateTime, h.UpdateTime, h.Affection, h.MarryTime, h.CurHp, h.Mood, h.MarryType, h.EquipSlots, Name: ShipHandbookLoader.GetShipName(h.TemplateId))).ToList();
                        var heroPush = TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                            Time: now));
                        var bagPush = TMessageCodec.EncodeResponse(new TResponse(
                            Method: "bag.UpdateBagData",
                            Ret: PlayerDataCodec.Encode(new BagInfoRet(BagType: 1, BagSize: (account.Bag ?? new PlayerBag([], 100)).BagSize,
                                BagInfo: (account.Bag?.Items ?? []).Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList())),
                            Time: now));
                        await NetSocketFrameCodec.WriteAsync(stream, heroPush, NetSocketFrameCodec.TypeData, ct);
                        await NetSocketFrameCodec.WriteAsync(stream, bagPush, NetSocketFrameCodec.TypeData, ct);
                    }

                    if (request.Method == "copy.PassBase")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                        var account = await _handler.GetAccountAsync(profileId, ct);
                        int copyId = GameLoginMessageHandler.DecodePassBaseCopyId(request.Args ?? []);
                        int copyType = ChapterCopyLoader.GetCopyType(copyId);
                        if (copyType == 2)
                        {
                            var seaPush = TMessageCodec.EncodeResponse(new TResponse(
                                Method: "copy.GetCopy",
                                Ret: GameLoginMessageHandler.EncodeSeaCopyInfo(account.SeaProgress),
                                Time: now));
                            await NetSocketFrameCodec.WriteAsync(stream, seaPush, NetSocketFrameCodec.TypeData, ct);
                        }
                        else
                        {
                            var plotPush = TMessageCodec.EncodeResponse(new TResponse(
                                Method: "copy.GetCopy",
                                Ret: GameLoginMessageHandler.EncodePlotCopyInfo(int.MaxValue, account.CopyProgress),
                                Time: now));
                            await NetSocketFrameCodec.WriteAsync(stream, plotPush, NetSocketFrameCodec.TypeData, ct);
                        }
                    }

                    // copy.StartBase 正常响应由 BuildC2SResponseAsync 统一返回（EncodeStartBaseRet）。
                    // 此前此处额外推送一条 IsResponse:0 的重复 StartBase（英雄顺序与请求不同），
                    // 客户端因 PrepareBattleMgr._CopyEnter 事件已注销而静默丢弃，已删除。
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