using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>抽卡/掉落池服务：buildship.BuildShip 的抽取逻辑 + 图鉴动作 illustrate.AddBehaviour。</summary>
internal sealed class BuildShipService(GameServices services)
{
    /// <summary>
    /// 处理 illustrate.AddBehaviour：保留客户端上报兼容性，但将对应图鉴条目直接扩展为
    /// 客户端配置中的全部动作，并持久化到账号。
    /// 返回 TILLUSTRATELIST（field 1 = 更新后的 IllustrateList），客户端据此刷新图鉴。
    /// </summary>
    internal async Task<byte[]> BuildAddBehaviourRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        var items = ProtocolDecoder.DecodeAddBehaviourArg(request.Args);
        if (items.Count == 0) return [];

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        var illustrate = account.Illustrate ?? new PlayerIllustrate([]);
        List<IllustrateEntry> entries = illustrate.Entries.ToList();
        IReadOnlyList<int> allBehaviourIds = HandbookBehaviourLoader.AllBehaviourIds;
        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());

        foreach (var (illustrateId, behaviourIds) in items)
        {
            if (behaviourIds.Count == 0) continue;
            int idx = entries.FindIndex(e => e.IllustrateId == illustrateId);
            IReadOnlyList<int> unlocked = allBehaviourIds.Count > 0
                ? allBehaviourIds
                : behaviourIds.Distinct().OrderBy(id => id).ToList();
            if (idx >= 0)
            {
                entries[idx] = entries[idx] with { BehaviourList = unlocked };
            }
            else
            {
                entries.Add(new IllustrateEntry(illustrateId, unlocked));
            }
        }

        account = account with { Illustrate = new PlayerIllustrate(entries) };
        await services.SaveAccountAsync(account, ct);

        // 构建 TILLUSTRATELIST：仅 IllustrateList（field 1）。Encode(IllustrateInfoRet)
        // 在 HeroMemoryList/IllustrateEquipList 为 null 时只写 field 1，正好匹配。
        var infoList = entries
            .Select(e => GameServices.BuildUnlockedIllustrateInfo(e.IllustrateId, now))
            .ToList();
        return PlayerDataCodec.Encode(new IllustrateInfoRet(IllustrateList: infoList));
    }

    /// <summary>扁平化后的掉落池条目（已递归展开 GoodsType.DROP）。</summary>
    internal sealed record DropPoolEntry(int GoodsType, int ConfigId, int MinNum, int MaxNum, int Weight)
    {
        public override string ToString()
        {
            string goodsName = "No";
            if (GoodsType == GameServices.GoodsTypeShip)
            {
                string shipName = ShipHandbookLoader.GetShipName(ConfigId);
                goodsName = shipName;
            }

            return
                $"{nameof(GoodsType)}: {GoodsType}, goodsName: {goodsName}, {nameof(ConfigId)}: {ConfigId}, {nameof(MinNum)}: {MinNum}, {nameof(MaxNum)}: {MaxNum}, {nameof(Weight)}: {Weight}";
        }
    }

    /// <summary>
    /// 处理 buildship.BuildShip：按 config_extract_ship → config_drop_item 标准流程抽取。
    /// 抽取到的舰娘加入船坞，返回 TBuildShipRet{BuildShipResult=[TCommonReward]}。
    /// 10 连保底至少一个 SR（quality>=3）。
    /// </summary>
    internal async Task<byte[]> BuildBuildShipRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return [];
        BuildShipArg arg = ProtocolDecoder.DecodeBuildShipArg(request.Args);
        int num = arg.Num;
        if (num <= 0) num = 1;
        if (num > 10) num = 10;

        if (!services.ExtractShips.TryGetValue(arg.Id, out var extractConfig))
            return [];

        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        List<CommonReward> rewards = new();
        services.LastBuildHeroIds.Clear();

        var entries = FlattenDropPool((int)extractConfig.DropItemId);
        if (entries.Count == 0)
            return [];

        // Console.WriteLine(string.Join(",\n", entries));

        long extractType = extractConfig.ExtractType;

        for (int i = 0; i < num; i++)
        {
            var entry = WeightedPick(entries);
            (account, CommonReward reward) = GrantDropReward(account, entry, now);
            rewards.Add(reward);
        }

        // 10 连保底：至少一个 SR（quality>=3）。仅对舰船类型卡池生效。
        if (num == 10 && (extractType == GameServices.ExtractTypeShip || extractType == GameServices.ExtractTypeLimitShip))
        {
            bool hasSR = rewards.Any(r => r.Type == GameServices.GoodsTypeShip && GetShipRarity(r.ConfigId) >= GameServices.RaritySR);
            if (!hasSR)
            {
                var srPlusEntries = entries.Where(
                    e => e.GoodsType == GameServices.GoodsTypeShip && GetShipRarity(e.ConfigId) >= GameServices.RaritySR).ToList();
                if (srPlusEntries.Count > 0)
                {
                    // 从后往前找到最后一个舰船奖励并替换
                    for (int i = rewards.Count - 1; i >= 0; i--)
                    {
                        if (rewards[i].Type == GameServices.GoodsTypeShip)
                        {
                            var newEntry = WeightedPick(srPlusEntries);
                            uint oldHeroId = (uint)rewards[i].Id;
                            account = GameServices.RemoveHero(account, oldHeroId);
                            services.LastBuildHeroIds.Remove(oldHeroId);
                            uint newHeroId = services.NextHeroId();
                            account = services.AddShip(account, newHeroId, newEntry.ConfigId, now);
                            services.LastBuildHeroIds.Add(newHeroId);
                            rewards[i] = new CommonReward(GameServices.GoodsTypeShip, newEntry.ConfigId, newEntry.MinNum, (int)newHeroId);
                            break;
                        }
                    }
                }
            }
        }

        if (rewards.Count > 0)
        {
            // 累计该池抽数（用于 20/100 连累计奖励判断）。
            var buildState = account.BuildState ?? new PlayerBuildState(
                new Dictionary<int, int>(), new Dictionary<int, IReadOnlyList<int>>(), new Dictionary<int, IReadOnlyList<int>>());
            var drawCount = buildState.DrawCount.ToDictionary(kv => kv.Key, kv => kv.Value);
            drawCount[arg.Id] = drawCount.GetValueOrDefault(arg.Id) + num;
            account = account with { BuildState = buildState with { DrawCount = drawCount } };
            await services.SaveAccountAsync(account, ct);
        }

        return ProtocolEncoder.EncodeBuildShipRet(rewards);
    }

    /// <summary>处理 buildship.BuildShipBox：领取累计抽数宝箱奖励（twenty_drop / ChooseShip）。
    /// 从 config_extract_ship.twenty_drop 找到 limitCount 对应的 dropId，发放掉落表内全部物品，
    /// 并记录到 UsedBoxInfo（客户端据此判断是否已领取）。返回 TBuildShipRet。</summary>
    internal async Task<byte[]> BuildBuildShipBoxRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        BuildShipArg arg = ProtocolDecoder.DecodeBuildShipArg(request.Args);
        if (!services.ExtractShips.TryGetValue(arg.Id, out var extractConfig))
            return [];

        // twenty_drop 形如 [[limitCount, dropId], ...]
        long dropId = 0;
        if (extractConfig.TwentyDrop is { Count: > 0 } twentyDrop)
            foreach (var entry in twentyDrop)
                if (entry is { Count: >= 2 } && entry[0] == arg.Num)
                {
                    dropId = entry[1];
                    break;
                }
        if (dropId == 0) return [];

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        // 校验已抽次数足够且未领取过该档位。
        var buildState = account.BuildState ?? new PlayerBuildState(
            new Dictionary<int, int>(), new Dictionary<int, IReadOnlyList<int>>(), new Dictionary<int, IReadOnlyList<int>>());
        int drawCount = buildState.DrawCount.GetValueOrDefault(arg.Id);
        if (drawCount < arg.Num) return [];
        var usedBox = buildState.UsedBoxInfo.ToDictionary(kv => kv.Key, kv => kv.Value.ToList());
        if (usedBox.TryGetValue(arg.Id, out var claimedList) && claimedList.Contains(arg.Num))
            return [];

        // 发放掉落表内全部物品（与抽卡一致，按类型处理 SHIP/EQUIP/CURRENCY/ITEM）。
        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        List<CommonReward> rewards = [];
        services.LastBuildHeroIds.Clear();
        foreach (var entry in FlattenDropPool((int)dropId))
        {
            (account, CommonReward reward) = GrantDropReward(account, entry, now);
            rewards.Add(reward);
        }

        // 记录已领取。
        if (!usedBox.ContainsKey(arg.Id)) usedBox[arg.Id] = [];
        usedBox[arg.Id].Add(arg.Num);
        account = account with { BuildState = buildState with {
            UsedBoxInfo = usedBox.ToDictionary(kv => kv.Key, kv => (IReadOnlyList<int>)kv.Value) } };
        await services.SaveAccountAsync(account, ct);
        return ProtocolEncoder.EncodeBuildShipRet(rewards);
    }

    /// <summary>处理 buildship.BuildShipReward：领取累计抽数次奖励（hundred_reward）。
    /// 从 config_extract_ship.hundred_reward 找到 limitCount 对应的 [itemType, itemId, count]，
    /// 发放该道具，并记录到 UsedRewardInfo。返回 TBuildShipRet。</summary>
    internal async Task<byte[]> BuildBuildShipRewardRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        BuildShipArg arg = ProtocolDecoder.DecodeBuildShipArg(request.Args);
        if (!services.ExtractShips.TryGetValue(arg.Id, out var extractConfig))
            return [];

        long itemType = 0, itemId = 0, count = 0;
        if (extractConfig.HundredReward is { Count: > 0 } hundredReward)
            foreach (var entry in hundredReward)
                if (entry is { Count: >= 4 } && entry[0] == arg.Num)
                {
                    itemType = entry[1];
                    itemId = entry[2];
                    count = entry[3];
                    break;
                }
        if (itemType == 0) return [];

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        var buildState = account.BuildState ?? new PlayerBuildState(
            new Dictionary<int, int>(), new Dictionary<int, IReadOnlyList<int>>(), new Dictionary<int, IReadOnlyList<int>>());
        int drawCount = buildState.DrawCount.GetValueOrDefault(arg.Id);
        if (drawCount < arg.Num) return [];
        var usedReward = buildState.UsedRewardInfo.ToDictionary(kv => kv.Key, kv => kv.Value.ToList());
        if (usedReward.TryGetValue(arg.Id, out var claimedList) && claimedList.Contains(arg.Num))
            return [];

        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        int num = count > 0 ? (int)count : 1;
        services.LastBuildHeroIds.Clear();
        // 与抽卡/宝箱发放走同一套 GrantDropReward：SHIP 创建舰娘实例入船坞、
        // EQUIP 创建装备实例入装备仓库，避免把舰船模板当背包道具塞进背包。
        var dropEntry = new DropPoolEntry((int)itemType, (int)itemId, num, num, 1);
        (account, CommonReward reward) = GrantDropReward(account, dropEntry, now);
        List<CommonReward> rewards = [reward];

        if (!usedReward.ContainsKey(arg.Id)) usedReward[arg.Id] = [];
        usedReward[arg.Id].Add(arg.Num);
        account = account with { BuildState = buildState with {
            UsedRewardInfo = usedReward.ToDictionary(kv => kv.Key, kv => (IReadOnlyList<int>)kv.Value) } };
        await services.SaveAccountAsync(account, ct);
        return ProtocolEncoder.EncodeBuildShipRet(rewards);
    }

    /// <summary>按 GoodsType 发放掉落奖励（与抽卡一致）：SHIP 走 AddShip，EQUIP 走 AddEquip，
    /// CURRENCY 走 AddCurrency，其余走 AddBagItem。返回更新后的账号与该条奖励。</summary>
    private (PlayerAccount Account, CommonReward Reward) GrantDropReward(PlayerAccount account, DropPoolEntry entry, int now)
    {
        if (entry.GoodsType == GameServices.GoodsTypeShip)
        {
            uint heroId = services.NextHeroId();
            account = services.AddShip(account, heroId, entry.ConfigId, now);
            services.LastBuildHeroIds.Add(heroId);
            return (account, new CommonReward(GameServices.GoodsTypeShip, entry.ConfigId, entry.MinNum, (int)heroId));
        }
        if (entry.GoodsType == GameServices.GoodsTypeEquip)
        {
            (account, uint equipId) = AddEquip(account, entry.ConfigId, now);
            return (account, new CommonReward(GameServices.GoodsTypeEquip, entry.ConfigId, entry.MinNum, (int)equipId));
        }
        if (entry.GoodsType == GameServices.GoodsTypeCurrency)
            return (GameServices.AddCurrency(account, entry.ConfigId, entry.MinNum),
                new CommonReward(entry.GoodsType, entry.ConfigId, entry.MinNum));
        return (GameServices.AddBagItem(account, entry.ConfigId, entry.MinNum),
            new CommonReward(entry.GoodsType, entry.ConfigId, entry.MinNum));
    }

    /// <summary>按 GoodsType 发放累计奖励。舰船和装备必须创建实例，并把实例 id
    /// 写入 TCommonReward.Id；否则客户端会把模板当背包道具解析，领奖演出和船坞都会损坏。
    /// 由 <see cref="GrantDropReward"/> 统一处理（本方法已废弃合并）。</summary>

    /// <summary>递归展开 config_drop_item 掉落池，将 GoodsType.DROP 嵌套条目展开为最终物品列表。</summary>
    private List<DropPoolEntry> FlattenDropPool(int dropItemId, int countMul = 1)
    {
        var result = new List<DropPoolEntry>();
        if (!services.DropItems.TryGetValue(dropItemId, out var dropItem))
            return result;

        if (dropItem.DropRate > 0 && dropItem.Drop is { Count: > 0 })
            FlattenDropEntries(dropItem.Drop, countMul, result);

        if (dropItem.DropAloneCount > 0 && dropItem.DropAlone is { Count: > 0 })
            FlattenDropEntries(dropItem.DropAlone, (int)dropItem.DropAloneCount * countMul, result);

        return result;
    }

    private void FlattenDropEntries(List<List<long>> entries, int countMul, List<DropPoolEntry> result)
    {
        foreach (var entry in entries)
        {
            if (entry.Count < 5) continue;
            int goodsType = (int)entry[0];
            int configId = (int)entry[1];
            int minNum = (int)entry[2] * countMul;
            int maxNum = (int)entry[3] * countMul;
            int weight = (int)entry[4];
            if (weight == 0) continue;

            if (goodsType == GameServices.GoodsTypeDrop)
            {
                var nested = FlattenDropPool(configId, countMul);
                result.AddRange(nested);
            }
            else
            {
                result.Add(new DropPoolEntry(goodsType, configId, minNum, maxNum, weight));
            }
        }
    }

    /// <summary>按权重随机抽取一个掉落池条目。</summary>
    private DropPoolEntry WeightedPick(List<DropPoolEntry> entries)
    {
        int totalWeight = entries.Sum(e => e.Weight);
        if (totalWeight <= 0) return entries[0];
        int roll = services.Rng.Next(totalWeight);
        int cumulative = 0;
        foreach (var e in entries)
        {
            cumulative += e.Weight;
            if (roll < cumulative)
                return e;
        }
        return entries[^1];
    }

    /// <summary>通过 ship_info_id 获取舰娘稀有度（quality）。</summary>
    private int GetShipRarity(int templateId)
    {
        int siId = (templateId - 1) / 10;
        return services.ShipInfos.TryGetValue(siId, out var info) ? (int)info.Quality : 0;
    }

    /// <summary>装备加入仓库：创建装备实例（EquipId 自增）存入装备仓库，返回更新后的账号与 EquipId。</summary>
    internal (PlayerAccount Account, uint EquipId) AddEquip(PlayerAccount account, int templateId, int now)
    {
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        var items = equip.Items.ToList();
        uint equipId = services.NextEquipId();
        items.Add(new EquipItem(EquipId: equipId, TemplateId: templateId));
        account = account with { Equip = equip with { Items = items } };
        return (account, equipId);
    }
}
