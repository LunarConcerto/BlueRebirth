using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>商店/仓库服务：bag.GetBagInfo 的领域逻辑。</summary>
internal sealed class ShopService(GameServices services)
{
    internal sealed record TreasureOpenResult(
        byte[] Ret, bool Changed, string Error, int RemovedTreasureTemplateId = 0);
    private sealed record PendingReward(int Type, int ConfigId, int Num);

    /// <summary>仓库信息响应（bag.GetBagInfo 使用）。</summary>
    internal async Task<byte[]> BuildGetBagInfoRetAsync(string profileId, CancellationToken ct)
    {
        var account = await services.GetOrCreateAccountAsync(profileId, ct);
        var bag = account.Bag ?? new PlayerBag([], 100);
        var info = bag.Items.Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList();
        return PlayerDataCodec.Encode(new BagInfoRet(BagType: 1, BagSize: bag.BagSize, BagInfo: info));
    }

    /// <summary>
    /// 开启普通宝箱：扣除宝箱道具，按 config_item_info.drop_id 递归抽取
    /// config_drop_item，并把装备奖励生成为带唯一 EquipId 的装备实例。
    /// </summary>
    internal async Task<TreasureOpenResult> BuildOpenNormalTreasureRetAsync(
        TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return new([], false, "treasure request is missing");
        BagNormalTreasureInfoArg arg = PlayerDataCodec.DecodeBagNormalTreasureInfoArg(request.Args);
        // config_parameter[54]（box_open_num_max）规定单次最多开启 99 个。
        if (arg.TreasureId <= 0 || arg.TreasureNum is <= 0 or > 99)
            return new([], false, "treasure id or count is invalid");
        if (!services.ItemInfos.TryGetValue(arg.TreasureId, out var item) || item.DropId <= 0)
            return new([], false, "treasure configuration was not found");

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        int bagIndex = bag.Items.ToList().FindIndex(x => x.TemplateId == arg.TreasureId);
        if (bagIndex < 0 || bag.Items[bagIndex].Num < arg.TreasureNum)
            return new([], false, "treasure count is insufficient");

        var pending = new List<PendingReward>();
        for (var i = 0; i < arg.TreasureNum; i++)
        {
            if (!TryDrawPool(checked((int)item.DropId), pending, [], 0))
                return new([], false, "treasure drop pool is invalid");
        }

        int newEquipCount = pending.Where(x => x.Type == GameServices.GoodsTypeEquip).Sum(x => x.Num);
        PlayerEquip equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        if (equip.Items.Count + newEquipCount > equip.EquipBagSize)
            return new([], false, "equipment bag is full");
        if (pending.Any(x => x.Type == GameServices.GoodsTypeEquip && services.GetEquipConfig(x.ConfigId) is null))
            return new([], false, "treasure contains an unknown equipment template");
        if (pending.Any(x => x.Type is GameServices.GoodsTypeShip or GameServices.GoodsTypeFashion))
            return new([], false, "treasure reward type is not supported yet");

        var bagItems = bag.Items.ToList();
        int remaining = bagItems[bagIndex].Num - arg.TreasureNum;
        if (remaining == 0) bagItems.RemoveAt(bagIndex);
        else bagItems[bagIndex] = bagItems[bagIndex] with { Num = remaining };
        account = account with { Bag = bag with { Items = bagItems } };

        var rewards = new List<CommonReward>();
        foreach (PendingReward reward in pending)
        {
            if (reward.Type == GameServices.GoodsTypeEquip)
            {
                for (var i = 0; i < reward.Num; i++)
                {
                    uint equipId = services.NextEquipId();
                    equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
                    var equipItems = equip.Items.ToList();
                    equipItems.Add(new EquipItem(equipId, reward.ConfigId));
                    account = account with { Equip = equip with { Items = equipItems } };
                    rewards.Add(new CommonReward(reward.Type, reward.ConfigId, 1, checked((int)equipId)));
                }
            }
            else if (reward.Type == GameServices.GoodsTypeCurrency)
            {
                account = GameServices.AddCurrency(account, reward.ConfigId, reward.Num);
                rewards.Add(new CommonReward(reward.Type, reward.ConfigId, reward.Num));
            }
            else
            {
                account = GameServices.AddBagItem(account, reward.ConfigId, reward.Num);
                rewards.Add(new CommonReward(reward.Type, reward.ConfigId, reward.Num));
            }
        }

        await services.SaveAccountAsync(account, ct);
        byte[] ret = PlayerDataCodec.Encode(new BagTreasureInfoRet(rewards, arg.TreasureId));
        // bag.UpdateBagData 是增量合并；完全耗尽时必须额外推送 Num=0 才会从客户端仓库删除。
        return new(ret, true, "", remaining == 0 ? arg.TreasureId : 0);
    }

    private bool TryDrawPool(int dropId, List<PendingReward> result, HashSet<int> path, int depth)
    {
        if (depth >= 16 || !path.Add(dropId) || !services.DropItems.TryGetValue(dropId, out var pool))
            return false;
        int resultCountBefore = result.Count;
        try
        {
            if (pool.DropRate > 0 && pool.Drop is { Count: > 0 })
            {
                int drawCount = Math.Max(1, checked((int)pool.DropCount));
                for (var i = 0; i < drawCount; i++)
                {
                    List<long>? entry = WeightedPick(pool.Drop);
                    if (entry is null || !ResolveEntry(entry, result, path, depth + 1)) return false;
                }
            }
            if (pool.DropAloneCount > 0 && pool.DropAlone is { Count: > 0 })
            {
                for (var i = 0; i < pool.DropAloneCount; i++)
                {
                    List<long>? entry = WeightedPick(pool.DropAlone);
                    if (entry is null || !ResolveEntry(entry, result, path, depth + 1)) return false;
                }
            }
            return result.Count > resultCountBefore;
        }
        finally
        {
            path.Remove(dropId);
        }
    }

    private bool ResolveEntry(List<long> entry, List<PendingReward> result, HashSet<int> path, int depth)
    {
        if (entry.Count < 5) return false;
        int type = checked((int)entry[0]);
        int configId = checked((int)entry[1]);
        int min = checked((int)entry[2]);
        int max = checked((int)entry[3]);
        if (min <= 0 || max < min) return false;
        int num = min == max ? min : services.Rng.Next(min, checked(max + 1));
        if (type == GameServices.GoodsTypeDrop)
        {
            for (var i = 0; i < num; i++)
                if (!TryDrawPool(configId, result, path, depth)) return false;
            return true;
        }
        result.Add(new PendingReward(type, configId, num));
        return true;
    }

    private List<long>? WeightedPick(List<List<long>> entries)
    {
        var candidates = entries.Where(x => x.Count >= 5 && x[4] > 0).ToList();
        long total = candidates.Sum(x => x[4]);
        if (total <= 0) return null;
        long roll = services.Rng.NextInt64(total);
        long cumulative = 0;
        foreach (List<long> entry in candidates)
        {
            cumulative += entry[4];
            if (roll < cumulative) return entry;
        }
        return candidates[^1];
    }
}
