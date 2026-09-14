using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

public struct DropEntry
{
    public int Type;
    public int ConfigId;
    public int Num;

    public DropEntry(int type, int configId, int num)
    {
        Type = type;
        ConfigId = configId;
        Num = num;
    }
}

/// <summary>
/// config_drop_item 掉落池的统一解析器（原 DailyCopyService / BattleService /
/// ShopService / RechargeModule 各自实现了一份，行为一致，抽到此处复用）。
///
/// 语义：
/// - <c>drop</c>：随机掉落池。<c>drop_rate &gt; 0</c> 时门控，抽取
///   <c>max(1, drop_count)</c> 次权重随机条目。
/// - <c>drop_alone</c>：独立掉落。每条按 <c>weight / 10000</c> 概率独立判定
///   （10000=必掉、8000=80%），<c>drop_alone_count</c> 为每条判定次数。
/// - 条目格式 <c>[type, configId, minNum, maxNum, weight]</c>；<c>type == GoodsType.Drop(4)</c>
///   时递归展开子池。
/// </summary>
internal static class DropPoolResolver
{
    private const int MaxDepth = 16;

    /// <summary>drop_alone 权重基准：10000 = 100%。</summary>
    private const int WeightBase = 10_000;

    /// <summary>物品/货币的「大量掉落」加成（仅作用于可堆叠类型）。</summary>
    private const int BulkMinBonus = 600;
    private const int BulkMaxBonus = 2000;

    /// <summary>
    /// 是否为可堆叠、适合「大量掉落」的物品/货币；排除装备(2)/舰船(3)/嵌套掉落(4)。
    /// </summary>
    private static bool IsBulkGoods(int type)
        => type is not (GameServices.GoodsTypeEquip or GameServices.GoodsTypeShip or GameServices.GoodsTypeDrop);

    /// <summary>解析一个掉落池，返回展开后的奖励列表（Type, ConfigId, Num）。</summary>
    public static List<DropEntry> Resolve(
        int dropId, IReadOnlyDictionary<int, ConfigDropItem> pools, Random rng)
    {
        var result = new List<DropEntry>();
        Draw(dropId, pools, rng, result, [], 0);
        return result;
    }

    private static bool Draw(
        int dropId, IReadOnlyDictionary<int, ConfigDropItem> pools, Random rng,
        List<DropEntry> result, HashSet<int> path, int depth)
    {
        if (depth >= MaxDepth || !path.Add(dropId) || !pools.TryGetValue(dropId, out ConfigDropItem? pool))
            return false;
        try
        {
            if (pool.DropRate > 0 && pool.Drop is { Count: > 0 })
                for (int i = 0; i < Math.Max(1, checked((int)pool.DropCount)); i++)
                    if (WeightedPick(pool.Drop, rng) is { } entry)
                        ResolveEntry(entry, pools, rng, result, path, depth + 1);

            if (pool.DropAlone is { Count: > 0 })
            {
                int trials = Math.Max(1, checked((int)pool.DropAloneCount));
                foreach (List<long> entry in pool.DropAlone)
                {
                    if (entry.Count < 5) continue;
                    int weight = checked((int)entry[4]);
                    if (weight <= 0) continue;
                    for (int i = 0; i < trials; i++)
                        if (weight >= WeightBase || rng.Next(WeightBase) < weight)
                            ResolveEntry(entry, pools, rng, result, path, depth + 1);
                }
            }
            return true;
        }
        finally
        {
            path.Remove(dropId);
        }
    }

    private static void ResolveEntry(
        List<long> entry, IReadOnlyDictionary<int, ConfigDropItem> pools, Random rng,
        List<DropEntry> result, HashSet<int> path, int depth)
    {
        if (entry.Count < 5) return;
        int type = checked((int)entry[0]);
        int configId = checked((int)entry[1]);
        int min = checked((int)entry[2]);
        int max = checked((int)entry[3]);

        // 「增加大量掉落资源」：仅对可堆叠的物品/货币给固定加成。舰船(3)、装备(2)
        // 与嵌套掉落(4)保持配置原值——它们会创建独立实例或递归展开，加成会让一次
        // 结算产出成百上千个实例，客户端会卡在加载。
        if (IsBulkGoods(type))
        {
            min += BulkMinBonus;
            max += BulkMaxBonus;
        }

        if (min <= 0 || max < min) return;
        int num = min == max ? min : rng.Next(min, checked(max + 1));
        if (type == GameServices.GoodsTypeDrop)
        {
            for (int i = 0; i < num; i++) Draw(configId, pools, rng, result, path, depth);
            return;
        }
        result.Add(new DropEntry(type, configId, num));
    }

    private static List<long>? WeightedPick(List<List<long>> entries, Random rng)
    {
        List<List<long>> candidates = entries.Where(x => x.Count >= 5 && x[4] > 0).ToList();
        long total = candidates.Sum(x => x[4]);
        if (total <= 0) return null;
        long roll = rng.NextInt64(total);
        long cumulative = 0;
        foreach (List<long> entry in candidates)
        {
            cumulative += entry[4];
            if (roll < cumulative) return entry;
        }
        return candidates[^1];
    }
}
