using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>抽卡/掉落池服务：buildship.BuildShip 的抽取逻辑。</summary>
internal sealed class BuildShipService(GameServices services)
{
    /// <summary>扁平化后的掉落池条目（已递归展开 GoodsType.DROP）。</summary>
    internal sealed record DropPoolEntry(int GoodsType, int ConfigId, int MinNum, int MaxNum, int Weight);

    /// <summary>
    /// 处理 buildship.BuildShip：按 config_extract_ship → config_drop_item 标准流程抽取。
    /// 抽取到的舰娘加入船坞，返回 TBuildShipRet{BuildShipResult=[TCommonReward]}。
    /// 10 连保底至少一个 SR（quality>=3）。
    /// </summary>
    internal async Task<byte[]> BuildBuildShipRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return [];
        (int extractId, int num, _) = GameServices.DecodeBuildShipArg(request.Args);
        if (num <= 0) num = 1;
        if (num > 10) num = 10;

        if (!services.ExtractShips.TryGetValue(extractId, out var extractConfig))
            return [];

        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        List<CommonReward> rewards = new();
        services.LastBuildHeroIds.Clear();

        var entries = FlattenDropPool((int)extractConfig.DropItemId);
        if (entries.Count == 0)
            return [];

        long extractType = extractConfig.ExtractType;

        for (int i = 0; i < num; i++)
        {
            var entry = WeightedPick(entries);
            if (entry.GoodsType == GameServices.GoodsTypeShip)
            {
                uint heroId = services.NextHeroId();
                account = GameServices.AddShip(account, heroId, entry.ConfigId, now);
                services.LastBuildHeroIds.Add(heroId);
                rewards.Add(new CommonReward(GameServices.GoodsTypeShip, entry.ConfigId, entry.MinNum, (int)heroId));
            }
            else if (entry.GoodsType == GameServices.GoodsTypeEquip)
            {
                uint equipId = AddEquip(account, entry.ConfigId, now);
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
                            account = GameServices.AddShip(account, newHeroId, newEntry.ConfigId, now);
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

        return GameServices.EncodeBuildShipRet(rewards);
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

    /// <summary>装备加入仓库（简化实现：作为 CommonReward 返回，不实际加入装备仓库）。</summary>
    internal uint AddEquip(PlayerAccount account, int templateId, int now)
    {
        return 0;
    }
}
