using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 实验室（天赋树）模块：talentTree.*。TalentTreeAllList 在登录时推送；
/// GetTalentData 返回单个天赋；UnLockTalent/UpgradeTalent 推进天赋链并推送 TalentChange。
/// </summary>
internal sealed class TalentModule(GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["talentTree"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        switch (request.Method)
        {
            case "talentTree.GetTalentData":
                return ModuleResult.Ok(await BuildGetTalentDataAsync(request, ctx));
            case "talentTree.UnLockTalent":
            case "talentTree.UpgradeTalent":
                return await ChangeTalentAsync(request, ctx);
            default:
                return ModuleResult.Empty;
        }
    }

    /// <summary>talentTree.GetTalentData：返回 TGetTalentDataRet{TalentData=TTalentData}。</summary>
    private async Task<byte[]> BuildGetTalentDataAsync(TRequest request, GameContext ctx)
    {
        int talentId = request.Args is null ? 0 : ProtocolDecoder.DecodeTalentIdArg(request.Args);
        ConfigTalent? cfg = TalentConfigLoader.Get(talentId);
        if (cfg is null) return [];

        PlayerAccount account = await services.GetOrCreateAccountAsync(ctx.ProfileId, ctx.Ct);
        int rootId = cfg.Belongtalent == 0 ? checked((int)cfg.Id) : checked((int)cfg.Belongtalent);
        int reached = account.Talent?.ActiveTalents.GetValueOrDefault(rootId) ?? 0;

        var pre = cfg.Precondition?.Select(p => checked((int)p)).ToList() ?? [];
        // IsOperate：目标天赋或已解锁天赋为 1，其余为 0。
        int isOperate = (reached == talentId) ? 1 : 0;
        ProtocolPackage ret = new();
        ret.Write(0x0A, ProtocolEncoder.EncodeTalentData(talentId, pre, isOperate)); // TalentData(1)
        return ret.ToArray();
    }

    /// <summary>
    /// talentTree.UnLockTalent / UpgradeTalent：把请求天赋设为所在链的已解锁位置并持久化，
    /// 应答前推送 talentTree.TalentChange（新的目标天赋）刷新客户端。
    /// </summary>
    private async Task<ModuleResult> ChangeTalentAsync(TRequest request, GameContext ctx)
    {
        if (request.Args is null) return ModuleResult.Ok([]);
        int talentId = ProtocolDecoder.DecodeTalentIdArg(request.Args);
        ConfigTalent? cfg = TalentConfigLoader.Get(talentId);
        if (cfg is null) return ModuleResult.Ok([]);

        int rootId = cfg.Belongtalent == 0 ? checked((int)cfg.Id) : checked((int)cfg.Belongtalent);

        using var _ = await services.LockAccountAsync(ctx.ProfileId, ctx.Ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(ctx.ProfileId, ctx.Ct);
        var reached = (account.Talent?.ActiveTalents ?? new Dictionary<int, int>())
            .ToDictionary(kv => kv.Key, kv => kv.Value);
        reached[rootId] = talentId;
        account = account with { Talent = new PlayerTalent(reached) };
        await services.SaveAccountAsync(account, ctx.Ct);

        // 推送新的目标天赋（下一级 IsOperate=0；链尾 IsOperate=1）。
        var target = GameServices.ComputeTalentTarget(rootId, talentId);
        byte[] changePush = TMessageCodec.EncodeResponse(new TResponse(
            Method: "talentTree.TalentChange",
            Ret: ProtocolEncoder.EncodeTalentChange([target]),
            Time: (uint)ctx.Now));
        return new ModuleResult { Ret = [], PrePushes = [changePush] };
    }
}