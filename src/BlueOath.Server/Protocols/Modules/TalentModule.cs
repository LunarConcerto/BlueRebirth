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
                return await ChangeTalentAsync(request, ctx);
            case "talentTree.UpgradeTalent":
                return await ChangeTalentAsync(request, ctx);
            default:
                return ModuleResult.Empty;
        }
    }

    /// <summary>talentTree.GetTalentData：返回 TGetTalentDataRet{TalentData=TTalentData}。</summary>
    private Task<byte[]> BuildGetTalentDataAsync(TRequest request, GameContext ctx)
    {
        int talentId = request.Args is null ? 0 : ProtocolDecoder.DecodeTalentIdArg(request.Args);
        ConfigTalent? cfg = TalentConfigLoader.Get(talentId);
        if (cfg is null) return Task.FromResult(Array.Empty<byte>());

        var pre = cfg.Precondition?.Select(p => checked((int)p)).ToList() ?? [];
        ProtocolPackage ret = new();
        ret.Write(0x0A, ProtocolEncoder.EncodeTalentData(checked((int)cfg.Id), pre, 1)); // TalentData(1)
        return Task.FromResult(ret.ToArray());
    }

    /// <summary>
    /// talentTree.UnLockTalent / UpgradeTalent：把请求的天赋设为所在链的激活天赋并持久化，
    /// 应答前推送 talentTree.TalentChange 刷新客户端。
    /// </summary>
    private async Task<ModuleResult> ChangeTalentAsync(TRequest request, GameContext ctx)
    {
        if (request.Args is null) return ModuleResult.Ok([]);
        int talentId = ProtocolDecoder.DecodeTalentIdArg(request.Args);
        ConfigTalent? cfg = TalentConfigLoader.Get(talentId);
        if (cfg is null) return ModuleResult.Ok([]);

        using var _ = await services.LockAccountAsync(ctx.ProfileId, ctx.Ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(ctx.ProfileId, ctx.Ct);

        // 定位根天赋：belongtalent=0 时根即自身，否则 belongtalent 为根。
        int rootId = cfg.Belongtalent == 0 ? checked((int)cfg.Id) : checked((int)cfg.Belongtalent);
        var active = (account.Talent?.ActiveTalents ?? new Dictionary<int, int>())
            .ToDictionary(kv => kv.Key, kv => kv.Value);
        active[rootId] = talentId;
        account = account with { Talent = new PlayerTalent(active) };
        await services.SaveAccountAsync(account, ctx.Ct);

        // 推送变更：被激活的天赋 + 所在链其它天赋（IsOperate 0）以刷新树状态。
        var pre = cfg.Precondition?.Select(p => checked((int)p)).ToList() ?? [];
        byte[] changePush = TMessageCodec.EncodeResponse(new TResponse(
            Method: "talentTree.TalentChange",
            Ret: ProtocolEncoder.EncodeTalentChange([(talentId, pre, 1)]),
            Time: (uint)ctx.Now));
        return new ModuleResult { Ret = [], PrePushes = [changePush] };
    }
}