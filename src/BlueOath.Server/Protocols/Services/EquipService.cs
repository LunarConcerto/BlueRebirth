using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>装备服务：equip.Dismantle 的领域逻辑（分解装备返还材料）。</summary>
internal sealed class EquipService(GameServices services)
{
    /// <summary>
    /// 处理 equip.Dismantle：删除选中的装备实例，按 config_equip.dismantling_get 返还材料。
    /// 返回 (TEquipDismantleRet 字节, 被删除的装备实例 ID 列表)。
    /// </summary>
    internal async Task<(byte[] Ret, List<uint> RemovedIds)> BuildDismantleRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return ([], []);
        List<uint> consumeIds = ProtocolDecoder.DecodeEquipDismantle(request.Args);
        if (consumeIds.Count == 0) return ([], []);

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        List<EquipItem> items = equip.Items.ToList();
        List<uint> removedIds = new();
        // 合并相同 (Type, ConfigId) 的奖励（对应 Lua MergeSameRes）。
        Dictionary<(int Type, int ConfigId), int> rewardMap = new();

        foreach (uint equipId in consumeIds)
        {
            int idx = items.FindIndex(e => e.EquipId == equipId);
            if (idx < 0) continue;
            EquipItem eqItem = items[idx];

            // config_equip.no_resolve > 0 的装备不可分解（客户端 CanDelect 同样拦截）。
            ConfigEquip? cfg = EquipLoader.Get(eqItem.TemplateId);
            if (cfg is null || cfg.NoResolve > 0) continue;

            items.RemoveAt(idx);
            removedIds.Add(equipId);

            // 基础返还：dismantling_get = [Type, ConfigId, Num]
            if (cfg.DismantlingGet is { Count: >= 3 })
            {
                int type = (int)cfg.DismantlingGet[0];
                int configId = (int)cfg.DismantlingGet[1];
                long num = cfg.DismantlingGet[2];
                if (type > 0 && num > 0)
                {
                    var key = (type, configId);
                    rewardMap[key] = rewardMap.GetValueOrDefault(key) + (int)num;
                }
            }
        }

        // 装备删除后先落盘。
        account = account with { Equip = equip with { Items = items } };
        await services.SaveAccountAsync(account, ct);

        // 统一发放奖励并构建响应。
        List<CommonReward> rewards = new();
        foreach (var ((type, configId), num) in rewardMap)
        {
            ApplyReward(ref account, type, configId, num);
            rewards.Add(new CommonReward(type, configId, num));
        }
        if (rewards.Count > 0)
            await services.SaveAccountAsync(account, ct);

        return (ProtocolEncoder.EncodeEquipDismantleRet(rewards), removedIds);
    }

    internal async Task<byte[]> BuildEnhanceRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        EquipEnhanceArgs arg = TMessageCodec.DecodeEquipEnhanceArgs(request.Args);
        if (arg.EquipId == 0 || arg.ItemArr is not { Count: > 0 }) return [];
        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerEquip equip = account.Equip ?? new PlayerEquip([], 2000);
        List<EquipItem> equipItems = equip.Items.ToList();
        int equipIndex = equipItems.FindIndex(e => e.EquipId == arg.EquipId);
        if (equipIndex < 0) return [];
        EquipItem current = equipItems[equipIndex];
        ConfigEquip? config = services.GetEquipConfig(current.TemplateId);
        if (config is null) return [];
        List<EquipEnhanceItem> materials = arg.ItemArr
            .GroupBy(i => i.TemplateId)
            .Select(g => new EquipEnhanceItem(g.Key, checked((uint)g.Aggregate(0UL, (sum, i) => sum + i.ItemNum))))
            .ToList();
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> bagItems = bag.Items.ToList();
        long addedExp = 0;
        foreach (EquipEnhanceItem material in materials)
        {
            if (material.ItemNum == 0 || services.GetEquipEnhanceItem(checked((int)material.TemplateId)) is not { } item)
                return [];
            int bagIndex = bagItems.FindIndex(i => i.TemplateId == checked((int)material.TemplateId));
            if (bagIndex < 0 || bagItems[bagIndex].Num < material.ItemNum) return [];
            if (item.EnhanceLevelLimit is { Count: >= 2 } limit &&
                (current.EnhanceLv < limit[0] || current.EnhanceLv > limit[1])) return [];
            addedExp += item.Exp * material.ItemNum;
        }
        int level = current.EnhanceLv;
        long exp = current.EnhanceExp + addedExp;
        int maxLevel = checked((int)config.EnhanceLevelMax);
        while (level < maxLevel && services.GetEquipEnhanceLevel(level + 1) is { } next && exp >= next.Exp)
        {
            exp -= next.Exp;
            level++;
        }
        foreach (EquipEnhanceItem material in materials)
        {
            int index = bagItems.FindIndex(i => i.TemplateId == checked((int)material.TemplateId));
            int remaining = bagItems[index].Num - checked((int)material.ItemNum);
            if (remaining == 0) bagItems.RemoveAt(index);
            else bagItems[index] = bagItems[index] with { Num = remaining };
        }
        equipItems[equipIndex] = current with { EnhanceLv = level, EnhanceExp = checked((int)exp) };
        account = account with { Equip = equip with { Items = equipItems }, Bag = bag with { Items = bagItems } };
        await services.SaveAccountAsync(account, ct);
        return [];
    }

    private void ApplyReward(ref PlayerAccount account, int type, int configId, int num)
    {
        // CURRENCY→货币字段；ITEM / EQUIP_ENHANCE_ITEM→仓库。
        if (type == GameServices.GoodsTypeCurrency)
            account = GameServices.AddCurrency(account, configId, num);
        else if (type == 1 || type == 6) // ITEM / EQUIP_ENHANCE_ITEM
            account = GameServices.AddBagItem(account, configId, num);
    }
}
