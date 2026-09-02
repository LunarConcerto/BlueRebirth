using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

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

    /// <summary>config_item_selected.type：2 = 装备箱，3 = 道具箱（本方法处理这两类）。</summary>
    private const int SelectedTypeEquip = 2;

    private const int SelectedTypeItem = 3;

    /// <summary>
    /// 开启道具选择箱（bag.GetSelectTreasureInfo）。
    ///
    /// 客户端 SelectRandTreasurePage:_ClickSure 发来 {treasureId, position, num}，position 是
    /// config_item_selected.item_id 的下标；item_id 为空而 drop_id &gt; 0 时是随机选择箱，
    /// 客户端固定传 position=0，由服务端从掉落池抽取。
    ///
    /// 处理 type == 3 的道具箱与 type == 2 的装备箱。装备箱共 75 个（46 个带 item_id、
    /// 29 个是 drop_id 随机箱），其 558 条选项的 GoodsType 全部是 2，不存在混合类型。
    /// 舰船箱（type 1）仍未实现，返回 Changed=false 且不带错误，交由调用方保持空响应。
    /// </summary>
    internal async Task<TreasureOpenResult> BuildOpenSelectTreasureRetAsync(
        TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return new([], false, "select treasure request is missing");
        BagSelectTreasureInfoArg arg = PlayerDataCodec.DecodeBagSelectTreasureInfoArg(request.Args);
        int openNum = arg.Num <= 0 ? 1 : arg.Num;
        // config_parameter[54]（box_open_num_max）规定单次最多开启 99 个。
        if (arg.TreasureId <= 0 || openNum > 99)
            return new([], false, "select treasure id or count is invalid");
        if (!services.ItemSelected.TryGetValue(arg.TreasureId, out ConfigItemSelected? config))
            return new([], false, "select treasure configuration was not found");
        // 舰船箱尚未实现，保持原有空响应。
        if (config.Type is not (SelectedTypeItem or SelectedTypeEquip)) return new([], false, "");

        List<List<long>> options = config.ItemId ?? [];
        var pending = new List<PendingReward>();
        if (options.Count > 0)
        {
            // Position 由客户端按 Lua 表下标下发，从 1 开始计数。
            if (arg.Position < 1 || arg.Position > options.Count)
                return new([], false, "select treasure position is out of range");
            List<long> option = options[arg.Position - 1];
            if (option.Count < 3) return new([], false, "select treasure option is malformed");
            int type = checked((int)option[0]);
            int configId = checked((int)option[1]);
            int num = checked((int)option[2]);
            if (num <= 0) return new([], false, "select treasure option has a non-positive count");
            if (type == GameServices.GoodsTypeShip)
                return new([], false, "select treasure option type is not supported yet");
            for (var i = 0; i < openNum; i++) pending.Add(new PendingReward(type, configId, num));
        }
        else
        {
            if (config.DropId <= 0) return new([], false, "select treasure has neither options nor a drop pool");
            for (var i = 0; i < openNum; i++)
            {
                if (!TryDrawPool(checked((int)config.DropId), pending, [], 0))
                    return new([], false, "select treasure drop pool is invalid");
            }
            if (pending.Any(x => x.Type == GameServices.GoodsTypeShip))
                return new([], false, "select treasure reward type is not supported yet");
        }

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        int bagIndex = bag.Items.ToList().FindIndex(x => x.TemplateId == arg.TreasureId);
        if (bagIndex < 0 || bag.Items[bagIndex].Num < openNum)
            return new([], false, "select treasure count is insufficient");

        // 装备仓库容量与模板校验必须在扣除箱子之前完成，失败时不能消耗道具。
        int newEquipCount = pending.Where(x => x.Type == GameServices.GoodsTypeEquip).Sum(x => x.Num);
        if (newEquipCount > 0)
        {
            PlayerEquip equipBag = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
            if (equipBag.Items.Count + newEquipCount > equipBag.EquipBagSize)
                return new([], false, "equipment bag is full");
            if (pending.Any(x => x.Type == GameServices.GoodsTypeEquip &&
                                 services.GetEquipConfig(x.ConfigId) is null))
                return new([], false, "select treasure contains an unknown equipment template");
        }

        var bagItems = bag.Items.ToList();
        int remaining = bagItems[bagIndex].Num - openNum;
        if (remaining == 0) bagItems.RemoveAt(bagIndex);
        else bagItems[bagIndex] = bagItems[bagIndex] with { Num = remaining };
        account = account with { Bag = bag with { Items = bagItems } };

        var rewards = new List<CommonReward>();
        foreach (PendingReward reward in pending)
        {
            if (reward.Type == GameServices.GoodsTypeEquip)
            {
                // 装备是逐件生成实例的：每件分配一个 EquipsId，奖励里必须带上它，
                // 否则客户端 ShowCommonReward 拿不到实例、装备也进不了仓库。
                for (var i = 0; i < reward.Num; i++)
                {
                    uint equipId = services.NextEquipId();
                    PlayerEquip equipBag = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
                    var equipItems = equipBag.Items.ToList();
                    equipItems.Add(new EquipItem(equipId, reward.ConfigId));
                    account = account with { Equip = equipBag with { Items = equipItems } };
                    rewards.Add(new CommonReward(reward.Type, reward.ConfigId, 1, checked((int)equipId)));
                }
                continue;
            }
            if (reward.Type == GameServices.GoodsTypeCurrency)
                account = GameServices.AddCurrency(account, reward.ConfigId, reward.Num);
            else if (reward.Type == GameServices.GoodsTypeFashion)
                // 道具箱里含时装奖励；走 AddBagItem 会让客户端按道具配置解析时装模板而出错。
                for (var i = 0; i < reward.Num; i++) account = services.AddFashion(account, reward.ConfigId);
            else
                account = GameServices.AddBagItem(account, reward.ConfigId, reward.Num);
            rewards.Add(new CommonReward(reward.Type, reward.ConfigId, reward.Num));
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
