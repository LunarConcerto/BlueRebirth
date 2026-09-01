using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>修理服务：repair.RepairHero 的领域逻辑（花费金币让舰娘回满血）。</summary>
internal sealed class RepairService(GameServices services)
{
    /// <summary>
    /// 处理 repair.RepairHero：对指定舰娘按缺失血量比例计费（config_ship_main.fixed_money），
    /// 扣除金币并把 CurHp 恢复为满值。返回空响应（客户端成功回调触发 getRepaireMsg）。
    /// </summary>
    internal async Task<byte[]> BuildRepairRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        var (heroIds, _) = ProtocolDecoder.DecodeRepairArg(request.Args);
        if (heroIds.Count == 0) return [];

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        long totalCost = 0;

        foreach (uint heroId in heroIds)
        {
            int idx = heroes.FindIndex(h => h.HeroId == heroId);
            if (idx < 0) continue;
            Hero hero = heroes[idx];
            // 已满血无需修理。
            if (hero.CurHp >= PlayerAccountFactory.HpCoefficient) continue;

            // 缺失血量比例：curHpPer = CurHp / HpCoefficient（与 shiplogic.GetHeroHp 一致）。
            double curHpPer = (double)Math.Max(0, hero.CurHp) / PlayerAccountFactory.HpCoefficient;
            long baseCost = ShipMainLoader.Get(hero.TemplateId)?.FixedMoney ?? 0;
            long cost = (long)Math.Ceiling(baseCost * (1 - curHpPer));
            totalCost += cost;

            heroes[idx] = hero with { CurHp = PlayerAccountFactory.HpCoefficient };
        }

        if (totalCost <= 0) return [];

        account = account with { Dock = dock with { Heroes = heroes } };
        account = GameServices.AddCurrency(account, 1, checked(-(int)Math.Min(totalCost, int.MaxValue)));
        await services.SaveAccountAsync(account, ct);
        return [];
    }
}