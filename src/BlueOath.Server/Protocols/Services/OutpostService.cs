using BlueOath.Core;

namespace BlueOath.Server.Protocols;

/// <summary>アンブラ前哨领域服务：outpost.* 的状态读写与持久化。</summary>
internal sealed class OutpostService(GameServices services)
{
    internal static PlayerAccount EnsureOutpost(PlayerAccount account)
        => account.Outpost is null
            ? account with { Outpost = PlayerAccountFactory.DefaultOutpost() }
            : account;

    private static PlayerOutpost State(PlayerAccount account)
        => account.Outpost ?? PlayerAccountFactory.DefaultOutpost();

    internal async Task<PlayerAccount> SetHeroAsync(string profileId, int buildingId, IReadOnlyList<uint> heroIds, CancellationToken ct)
    {
        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerOutpost state = State(account);
        List<PlayerOutpostBuilding> buildings = state.Buildings.ToList();
        int idx = buildings.FindIndex(b => b.Id == buildingId);
        if (idx < 0) return account;
        buildings[idx] = buildings[idx] with { HeroIds = heroIds };
        account = account with { Outpost = state with { Buildings = buildings } };
        await services.SaveAccountAsync(account, ct);
        return account;
    }

    internal async Task<PlayerAccount> UpgradeBuildingAsync(string profileId, int buildingId, CancellationToken ct)
    {
        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerOutpost state = State(account);
        List<PlayerOutpostBuilding> buildings = state.Buildings.ToList();
        int idx = buildings.FindIndex(b => b.Id == buildingId);
        if (idx < 0) return account;
        int newLevel = Math.Min(buildings[idx].Level + 1, 6);
        buildings[idx] = buildings[idx] with { Level = newLevel };
        account = account with { Outpost = state with { Buildings = buildings } };
        await services.SaveAccountAsync(account, ct);
        return account;
    }

    internal async Task<PlayerAccount> SetUseCoinAsync(string profileId, int buildingId, int useCoin, CancellationToken ct)
    {
        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerOutpost state = State(account);
        List<PlayerOutpostBuilding> buildings = state.Buildings.ToList();
        int idx = buildings.FindIndex(b => b.Id == buildingId);
        if (idx < 0) return account;
        buildings[idx] = buildings[idx] with { UseCoin = useCoin };
        account = account with { Outpost = state with { Buildings = buildings } };
        await services.SaveAccountAsync(account, ct);
        return account;
    }

    /// <summary>加速产出：立即完成当前等级一轮产出，把奖励写入 ItemInfo 并返回。
    /// 离线不等待真实生产时间，直接结算一轮 config_outpost_level.reward。</summary>
    internal async Task<(PlayerAccount Account, IReadOnlyList<OutpostItem> Rewards)> SpeedUpProductionAsync(
        string profileId, int buildingId, CancellationToken ct)
    {
        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerOutpost state = State(account);
        List<PlayerOutpostBuilding> buildings = state.Buildings.ToList();
        int idx = buildings.FindIndex(b => b.Id == buildingId);
        if (idx < 0) return (account, []);
        var rewards = OutpostLevelLoader.GetReward(buildingId, buildings[idx].Level);
        var current = (buildings[idx].ItemInfo ?? []).ToList();
        foreach (var item in rewards)
        {
            var existing = current.FirstOrDefault(x => x.Type == item.Type && x.ConfigId == item.ConfigId);
            if (existing is not null)
                current[current.IndexOf(existing)] = existing with { Num = existing.Num + item.Num };
            else
                current.Add(item);
        }
        buildings[idx] = buildings[idx] with { ItemInfo = current };
        account = account with { Outpost = state with { Buildings = buildings } };
        await services.SaveAccountAsync(account, ct);
        return (account, rewards);
    }

    /// <summary>领取单前哨产出：发放 ItemInfo 到背包并清空。</summary>
    internal async Task<(PlayerAccount Account, IReadOnlyList<OutpostItem> Rewards)> ReceiveItemAsync(
        string profileId, int buildingId, CancellationToken ct)
    {
        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerOutpost state = State(account);
        List<PlayerOutpostBuilding> buildings = state.Buildings.ToList();
        int idx = buildings.FindIndex(b => b.Id == buildingId);
        if (idx < 0) return (account, []);
        var rewards = buildings[idx].ItemInfo ?? [];
        account = Grant(account, rewards);
        buildings[idx] = buildings[idx] with { ItemInfo = [] };
        account = account with { Outpost = state with { Buildings = buildings } };
        await services.SaveAccountAsync(account, ct);
        return (account, rewards);
    }

    /// <summary>一键领取全部前哨产出：发放所有 ItemInfo 并清空。</summary>
    internal async Task<(PlayerAccount Account, IReadOnlyList<OutpostItem> Rewards)> ReceiveAllAsync(
        string profileId, CancellationToken ct)
    {
        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerOutpost state = State(account);
        var allRewards = new List<OutpostItem>();
        foreach (var b in state.Buildings)
        {
            foreach (var item in b.ItemInfo ?? [])
            {
                var existing = allRewards.FirstOrDefault(x => x.Type == item.Type && x.ConfigId == item.ConfigId);
                if (existing is not null)
                    allRewards[allRewards.IndexOf(existing)] = existing with { Num = existing.Num + item.Num };
                else
                    allRewards.Add(item);
            }
        }
        account = Grant(account, allRewards);
        List<PlayerOutpostBuilding> buildings = state.Buildings
            .Select(b => b with { ItemInfo = [] })
            .ToList();
        account = account with { Outpost = state with { Buildings = buildings } };
        await services.SaveAccountAsync(account, ct);
        return (account, allRewards);
    }

    /// <summary>按 TCommonReward 发放奖励：Type=5 走货币，其余走背包。</summary>
    private static PlayerAccount Grant(PlayerAccount account, IReadOnlyList<OutpostItem> rewards)
    {
        foreach (var item in rewards)
        {
            if (item.Type == GameServices.GoodsTypeCurrency)
                account = GameServices.AddCurrency(account, item.ConfigId, item.Num);
            else if (item.Num != 0)
                account = GameServices.AddBagItem(account, item.ConfigId, item.Num);
        }
        return account;
    }
}
