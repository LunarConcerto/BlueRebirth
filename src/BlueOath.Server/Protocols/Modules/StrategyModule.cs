using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 战术模块：strategy.*。strategy.GetStrategy 返回全部战术（Level=1 解锁）；
/// strategy.Apply 把指定战术持久化到对应舰队（FleetEntry.StrategyId）；
/// Learn/Upgrade/Reset 返回成功。
/// </summary>
internal sealed class StrategyModule(GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["strategy"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        switch (request.Method)
        {
            case "strategy.GetStrategy":
                return ModuleResult.Ok(ProtocolEncoder.EncodeStrategyRet(
                    StrategyConfigLoader.All.Select(s => ((int)s.Id, 1)), resetNum: 0));
            case "strategy.Apply":
                return await BuildApplyStrategyAsync(ctx, request);
            case "strategy.Learn" or "strategy.Upgrade" or "strategy.Reset":
                return ModuleResult.Ok([]);
            default:
                return ModuleResult.Empty;
        }
    }

    /// <summary>
    /// 处理 strategy.Apply：把 Id（战术）写入 FleetId/TacticType 对应舰队的
    /// <see cref="FleetEntry.StrategyId"/>，落盘后推送最新编队数据供客户端刷新。
    /// </summary>
    private async Task<ModuleResult> BuildApplyStrategyAsync(GameContext ctx, TRequest request)
    {
        if (request.Args is null) return ModuleResult.Ok([]);
        var (id, _, fleetId, tacticType) = ProtocolDecoder.DecodeStrategyApplyArg(request.Args);
        if (id == 0 || fleetId == 0) return ModuleResult.Ok([]);

        using var _ = await services.LockAccountAsync(ctx.ProfileId, ctx.Ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(ctx.ProfileId, ctx.Ct);
        PlayerFleet fleet = account.Fleet ?? PlayerAccountFactory.DefaultFleet();
        List<FleetEntry> entries = fleet.Tactics.ToList();
        int idx = entries.FindIndex(e => e.ModeId == fleetId && e.Type == tacticType);
        if (idx >= 0)
            entries[idx] = entries[idx] with { StrategyId = id };
        account = account with { Fleet = fleet with { Tactics = entries } };
        await services.SaveAccountAsync(account, ctx.Ct);

        // 应答前推送编队数据，客户端 fleetData 的 strategyId 立即更新。
        byte[] fleetPush = TMessageCodec.EncodeResponse(new TResponse(
            Method: "tactic.GetHerosTactic",
            Ret: ProtocolEncoder.EncodeFleet(account.Fleet ?? PlayerAccountFactory.DefaultFleet()),
            Time: (uint)ctx.Now));
        return new ModuleResult { Ret = [], PrePushes = [fleetPush] };
    }
}