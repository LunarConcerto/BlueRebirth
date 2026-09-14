using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 充值模块：recharge.DirectBuyItem。直购礼包按 config_recharge[RechargeId] 发放：
/// Reward（config_rewards 固定奖励）+ Drop（config_drop_item 随机掉落表）。
/// 返回 TDIRECTBUYITEMRET{Reward=[TCommonReward]}。
/// </summary>
internal sealed class RechargeModule(GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["recharge"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        switch (request.Method)
        {
            case "recharge.DirectBuyItem":
                return await BuildDirectBuyItemAsync(request, ctx);
            default:
                return ModuleResult.Empty;
        }
    }

    /// <summary>recharge.DirectBuyItem：发放直购礼包奖励（固定 + 随机掉落），返回 TDirectBuyItemRet。</summary>
    private async Task<ModuleResult> BuildDirectBuyItemAsync(TRequest request, GameContext ctx)
    {
        if (request.Args is null) return ModuleResult.Empty;
        int rechargeId = ProtocolDecoder.DecodeTalentIdArg(request.Args); // 复用单 int field1 解码
        ConfigRecharge? cfg = RechargeConfigLoader.Get(rechargeId);
        if (cfg is null)
        {
            services.FileLogger.LogInformation("recharge.DirectBuyItem rechargeId={Id} cfg=null", rechargeId);
            return ModuleResult.Empty;
        }

        using var _ = await services.LockAccountAsync(ctx.ProfileId, ctx.Ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(ctx.ProfileId, ctx.Ct);
        int now = ctx.Now;

        var pending = new List<DropEntry>();

        // 固定奖励：config_rewards[Reward].Rewards。
        if (cfg.Reward > 0 && DailyCopyRewardCatalog.GetReward(checked((int)cfg.Reward)) is { Rewards: { } rewardEntries })
            foreach (List<long> entry in rewardEntries)
                if (entry.Count >= 3 && entry[0] > 0 && entry[2] > 0)
                    pending.Add(new DropEntry(checked((int)entry[0]), checked((int)entry[1]), checked((int)entry[2])));

        // 随机掉落：config_drop_item[Drop] / [DropReward] 加权抽取（含 drop_alone 保底）。
        // 部分礼包无固定 reward（reward=-1），全部内容来自 DropReward 掉落表。
        if (cfg.Drop > 0)
            pending.AddRange(DropPoolResolver.Resolve(checked((int)cfg.Drop), services.DropItems, services.Rng));
        if (cfg.DropReward > 0)
            pending.AddRange(DropPoolResolver.Resolve(checked((int)cfg.DropReward), services.DropItems, services.Rng));

        services.FileLogger.LogInformation(
            "recharge.DirectBuyItem rechargeId={Id} reward={Reward} drop={Drop} pendingCount={Count}",
            rechargeId, cfg.Reward, cfg.Drop, pending.Count);

        var rewards = new List<CommonReward>();
        foreach (DropEntry entry in pending)
        {
            int type = entry.Type;
            int configId = entry.ConfigId;
            int num = entry.Num;
            if (type == GameServices.GoodsTypeCurrency)
            {
                account = GameServices.AddCurrency(account, configId, num);
                rewards.Add(new CommonReward(type, configId, num));
            }
            else if (type == GameServices.GoodsTypeEquip)
            {
                for (int i = 0; i < num; i++)
                {
                    (account, uint equipId) = AddEquip(account, configId);
                    rewards.Add(new CommonReward(type, configId, 1, checked((int)equipId)));
                }
            }
            else if (type == GameServices.GoodsTypeShip)
            {
                uint heroId = services.NextHeroId();
                account = services.AddShip(account, heroId, configId, now);
                rewards.Add(new CommonReward(type, configId, 1, checked((int)heroId)));
            }
            else
            {
                account = GameServices.AddBagItem(account, configId, num);
                rewards.Add(new CommonReward(type, configId, num));
            }
        }

        await services.SaveAccountAsync(account, ctx.Ct);

        uint nowU = (uint)now;
        var pushes = new List<byte[]>();
        if (rewards.Any(r => r.Type == GameServices.GoodsTypeCurrency))
            pushes.Add(await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, nowU, ctx.Ct));
        pushes.Add(services.BuildBagPush(account, nowU));
        pushes.Add(services.BuildEquipPush(account, nowU));
        if (rewards.Any(r => r.Type == GameServices.GoodsTypeShip))
        {
            var heroes = account.Dock.Heroes.Select(GameServices.ToHeroGrid).ToList();
            pushes.Add(TMessageCodec.EncodeResponse(new TResponse(
                Method: "hero.UpdateHeroBagData",
                Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                Time: nowU)));
        }

        byte[] ret = ProtocolEncoder.EncodeDirectBuyItemRet(rewards);
        return new ModuleResult { Ret = ret, PrePushes = pushes };
    }

    private (PlayerAccount Account, uint EquipId) AddEquip(PlayerAccount account, int templateId)
    {
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        var items = equip.Items.ToList();
        uint equipId = services.NextEquipId();
        items.Add(new EquipItem(EquipId: equipId, TemplateId: templateId));
        account = account with { Equip = equip with { Items = items } };
        return (account, equipId);
    }
}
