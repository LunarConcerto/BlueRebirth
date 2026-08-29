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
            if (entry.GoodsType == GameServices.GoodsTypeShip)
            {
                uint heroId = services.NextHeroId();
                account = services.AddShip(account, heroId, entry.ConfigId, now);
                services.LastBuildHeroIds.Add(heroId);
                rewards.Add(new CommonReward(GameServices.GoodsTypeShip, entry.ConfigId, entry.MinNum, (int)heroId));
            }
            else if (entry.GoodsType == GameServices.GoodsTypeEquip)
            {
                (account, uint equipId) = AddEquip(account, entry.ConfigId, now);
                rewards.Add(new CommonReward(GameServices.GoodsTypeEquip, entry.ConfigId, entry.MinNum, (int)equipId));
            }
            else
            {
                rewards.Add(new CommonReward(entry.GoodsType, entry.ConfigId, entry.MinNum));
            }
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
            await services.SaveAccountAsync(account, ct);

        return ProtocolEncoder.EncodeBuildShipRet(rewards);
    }

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
