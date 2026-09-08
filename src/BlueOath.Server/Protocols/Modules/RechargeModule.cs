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

        var pending = new List<(int Type, int ConfigId, int Num)>();

        // 固定奖励：config_rewards[Reward].Rewards。
        if (cfg.Reward > 0 && DailyCopyRewardCatalog.GetReward(checked((int)cfg.Reward)) is { Rewards: { } rewardEntries })
            foreach (List<long> entry in rewardEntries)
                if (entry.Count >= 3 && entry[0] > 0 && entry[2] > 0)
                    pending.Add((checked((int)entry[0]), checked((int)entry[1]), checked((int)entry[2])));

        // 随机掉落：config_drop_item[Drop] / [DropReward] 加权抽取（含 drop_alone 保底）。
        // 部分礼包无固定 reward（reward=-1），全部内容来自 DropReward 掉落表。
        if (cfg.Drop > 0)
            DrawDropPool(checked((int)cfg.Drop), pending, new HashSet<int>(), 0);
        if (cfg.DropReward > 0)
            DrawDropPool(checked((int)cfg.DropReward), pending, new HashSet<int>(), 0);

        services.FileLogger.LogInformation(
            "recharge.DirectBuyItem rechargeId={Id} reward={Reward} drop={Drop} pendingCount={Count}",
            rechargeId, cfg.Reward, cfg.Drop, pending.Count);

        var rewards = new List<CommonReward>();
        foreach ((int type, int configId, int num) in pending)
        {
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

    /// <summary>递归展开 config_drop_item 掉落池，把结果追加到 pending。</summary>
    private void DrawDropPool(
        int dropId, List<(int Type, int ConfigId, int Num)> result, HashSet<int> path, int depth)
    {
        if (depth >= 16 || !path.Add(dropId) || !services.DropItems.TryGetValue(dropId, out var pool))
            return;
        try
        {
            if (pool.DropRate > 0 && pool.Drop is { Count: > 0 })
                for (int i = 0; i < Math.Max(1, checked((int)pool.DropCount)); i++)
                    if (WeightedPick(pool.Drop) is { } entry)
                        ResolveDropEntry(entry, result, path, depth + 1);
            if (pool.DropAloneCount > 0 && pool.DropAlone is { Count: > 0 })
                for (int i = 0; i < pool.DropAloneCount; i++)
                    if (WeightedPick(pool.DropAlone) is { } entry)
                        ResolveDropEntry(entry, result, path, depth + 1);
        }
        finally
        {
            path.Remove(dropId);
        }
    }

    private void ResolveDropEntry(
        List<long> entry, List<(int Type, int ConfigId, int Num)> result, HashSet<int> path, int depth)
    {
        if (entry.Count < 5) return;
        int type = checked((int)entry[0]);
        int configId = checked((int)entry[1]);
        int min = checked((int)entry[2]);
        int max = checked((int)entry[3]);
        if (min <= 0 || max < min) return;
        int num = min == max ? min : services.Rng.Next(min, checked(max + 1));
        if (type == GameServices.GoodsTypeDrop)
        {
            for (int i = 0; i < num; i++) DrawDropPool(configId, result, path, depth);
            return;
        }
        result.Add((type, configId, num));
    }

    private List<long>? WeightedPick(List<List<long>> entries)
    {
        int totalWeight = entries.Sum(e => e.Count > 4 ? checked((int)e[4]) : 0);
        if (totalWeight <= 0) return entries.Count > 0 ? entries[0] : null;
        int roll = services.Rng.Next(totalWeight);
        int cumulative = 0;
        foreach (List<long> e in entries)
        {
            int w = e.Count > 4 ? checked((int)e[4]) : 0;
            cumulative += w;
            if (roll < cumulative) return e;
        }
        return entries[^1];
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