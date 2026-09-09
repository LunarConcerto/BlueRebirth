using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>アンブラ前哨模块：outpost.*。客户端请求后通过 outpost.UpdateOutPostInfo
/// 推送同步最新状态（_UpdateOutPostInfo 写入 Data.mubarOutpostData）。</summary>
internal sealed class OutpostModule(OutpostService outpost, GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["outpost"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        uint now = (uint)ctx.Now;
        switch (request.Method)
        {
            case "outpost.GetOutPostInfo":
            {
                var account = await services.GetOrCreateAccountAsync(ctx.ProfileId, ctx.Ct);
                return PushUpdate(account, now);
            }
            case "outpost.SetHero":
            {
                (int buildingId, IReadOnlyList<uint> heroIds) = DecodeSetHero(request.Args ?? []);
                var account = await outpost.SetHeroAsync(ctx.ProfileId, buildingId, heroIds, ctx.Ct);
                return PushUpdate(account, now);
            }
            case "outpost.UpgradeBuilding":
            {
                int buildingId = DecodeBuildingId(request.Args ?? []);
                var account = await outpost.UpgradeBuildingAsync(ctx.ProfileId, buildingId, ctx.Ct);
                return PushUpdate(account, now);
            }
            case "outpost.DegradeBuilding":
                // 离线模式降级直接回当前状态，避免客户端报错。
            {
                int buildingId = DecodeBuildingId(request.Args ?? []);
                var account = await services.GetOrCreateAccountAsync(ctx.ProfileId, ctx.Ct);
                return PushUpdate(account, now);
            }
            case "outpost.SetUseCoin":
            {
                (int buildingId, int useCoin) = DecodeSetUseCoin(request.Args ?? []);
                var account = await outpost.SetUseCoinAsync(ctx.ProfileId, buildingId, useCoin, ctx.Ct);
                return PushUpdate(account, now);
            }
            case "outpost.SpeedUpProduction":
            {
                int buildingId = DecodeBuildingId(request.Args ?? []);
                var (account, rewards) = await outpost.SpeedUpProductionAsync(ctx.ProfileId, buildingId, ctx.Ct);
                return new ModuleResult
                {
                    Ret = ProtocolEncoder.EncodeOutPostReceiveRet(rewards),
                    PostPushes = await BuildRewardPushesAsync(ctx.ProfileId, account, now, ctx.Ct),
                };
            }
            case "outpost.ReceiveItem":
            {
                int buildingId = DecodeBuildingId(request.Args ?? []);
                var (account, rewards) = await outpost.ReceiveItemAsync(ctx.ProfileId, buildingId, ctx.Ct);
                return new ModuleResult
                {
                    Ret = ProtocolEncoder.EncodeOutPostReceiveRet(rewards),
                    PostPushes = await BuildRewardPushesAsync(ctx.ProfileId, account, now, ctx.Ct),
                };
            }
            case "outpost.ReceiveAll":
            {
                var (account, rewards) = await outpost.ReceiveAllAsync(ctx.ProfileId, ctx.Ct);
                return new ModuleResult
                {
                    Ret = ProtocolEncoder.EncodeOutPostReceiveRet(rewards),
                    PostPushes = await BuildRewardPushesAsync(ctx.ProfileId, account, now, ctx.Ct),
                };
            }
            default:
                return ModuleResult.Empty;
        }
    }

    private static ModuleResult PushUpdate(PlayerAccount account, uint now) => new()
    {
        Ret = [],
        PostPushes = [BuildUpdatePush(account, now)],
    };

    /// <summary>产出结算后补发背包与货币推送，使新资源立即在客户端显示（无需重启）。</summary>
    private async Task<IReadOnlyList<byte[]>> BuildRewardPushesAsync(
        string profileId, PlayerAccount account, uint now, CancellationToken ct)
    {
        List<byte[]> pushes =
        [
            BuildUpdatePush(account, now),
            await services.BuildUpdateUserInfoPushAsync(profileId, now, ct),
            services.BuildBagPush(account, now),
        ];
        return pushes;
    }

    private static byte[] BuildUpdatePush(PlayerAccount account, uint now) =>
        TMessageCodec.EncodeResponse(new TResponse(
            Method: "outpost.UpdateOutPostInfo",
            Ret: ProtocolEncoder.EncodeOutPostInfo(account.Outpost),
            Time: now));

    private static int DecodeBuildingId(byte[] args)
    {
        int id = 0;
        ProtocolDecoder.ProtoReader reader = new(args);
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 0) id = checked((int)reader.ReadVarint());
            else reader.Skip(wire);
        return id;
    }

    private static (int BuildingId, IReadOnlyList<uint> HeroIds) DecodeSetHero(byte[] args)
    {
        int buildingId = 0;
        var heroIds = new List<uint>();
        ProtocolDecoder.ProtoReader reader = new(args);
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0:
                    buildingId = checked((int)reader.ReadVarint());
                    break;
                case 2 when wire == 0:
                    heroIds.Add(checked((uint)reader.ReadVarint()));
                    break;
                default:
                    reader.Skip(wire);
                    break;
            }
        return (buildingId, heroIds);
    }

    private static (int BuildingId, int UseCoin) DecodeSetUseCoin(byte[] args)
    {
        int buildingId = 0, useCoin = 0;
        ProtocolDecoder.ProtoReader reader = new(args);
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0:
                    buildingId = checked((int)reader.ReadVarint());
                    break;
                case 2 when wire == 0:
                    useCoin = checked((int)reader.ReadVarint());
                    break;
                default:
                    reader.Skip(wire);
                    break;
            }
        return (buildingId, useCoin);
    }
}
