using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;
using System.Text.Json;

namespace BlueOath.Server.Protocols;

/// <summary>舰娘服务：hero.* / tactic.* 的领域逻辑（换装/升星/改造/结婚/经验/锁定/退役/改名/好感度）。</summary>
internal sealed class HeroService(GameServices services)
{
    internal sealed record RetireResult(
        byte[] Ret,
        IReadOnlyList<uint> RetiredHeroIds,
        IReadOnlyList<uint> RemovedEquipIds,
        bool Changed);

    internal sealed record AddAffectionResult(
        byte[] Ret,
        Hero? UpdatedHero,
        bool Changed,
        string Error);

    internal sealed record ChangeNameResult(
        byte[] Ret,
        Hero? UpdatedHero,
        bool Changed,
        string Error);

    internal sealed record MarryResult(
        byte[] Ret,
        Hero? UpdatedHero,
        bool Changed,
        string Error);

    internal sealed record RemouldResult(
        byte[] Ret,
        Hero? UpdatedHero,
        bool Changed,
        string Error);

    internal sealed record IntensifyResult(
        byte[] Ret,
        Hero? UpdatedHero,
        IReadOnlyList<uint> ConsumedHeroIds,
        bool Changed,
        string Error,
        int SpentDiamond = 0);

    internal sealed record AdvanceResult(
        byte[] Ret,
        Hero? UpdatedHero,
        IReadOnlyList<uint> ConsumedHeroIds,
        bool Changed);

    internal async Task<byte[]> BuildChangeEquipRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return [];
        HeroChangeEquipArgs arg = TMessageCodec.DecodeHeroChangeEquipArgs(request.Args);
        // Lua 客户端发送 1-based 索引，C# 数组是 0-based，需要转换。
        int index = arg.Index - 1;
        if (index < 0 || index >= 6)
            return [];
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0)
            return [];
        Hero hero = heroList[heroIdx];

        // 获取当前装备槽数组
        uint[] slots = (hero.EquipSlots ?? new uint[] { 0, 0, 0, 0, 0, 0 }).ToArray();

        // 如果旧槽有装备，先卸下
        uint oldEquipId = slots[index];
        if (oldEquipId != 0)
        {
            account = GameServices.SetEquipHeroId(account, oldEquipId, 0);
            slots[index] = 0;
        }

        // 新装备上装
        if (arg.EquipId != 0)
        {
            account = GameServices.SetEquipHeroId(account, arg.EquipId, arg.HeroId);
            slots[index] = arg.EquipId;
        }

        heroList[heroIdx] = hero with { EquipSlots = slots };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);

        return [];
    }

    internal async Task<MarryResult> BuildMarryRetAsync(
        TRequest request, string profileId, int now, CancellationToken ct)
    {
        if (request.Args is null)
            return new([], null, false, "marriage request is missing");
        MarryArg arg = ProtocolDecoder.DecodeMarryArg(request.Args);
        if (arg.HeroId == 0 || arg.MarryType is < 1 or > 2)
            return new([], null, false, "marriage request is invalid");

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        List<Hero> heroes = account.Dock.Heroes.ToList();
        int heroIdx = heroes.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0)
            return new([], null, false, "hero was not found");

        Hero hero = heroes[heroIdx];
        if (hero.MarryTime != 0)
            return new([], null, false, "hero is already married");

        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> bagItems = bag.Items.ToList();
        int ringIdx = bagItems.FindIndex(i => i.TemplateId == 10180);
        if (ringIdx < 0 || bagItems[ringIdx].Num < 1)
            return new([], null, false, "an oath ring is required");

        Hero updatedHero = hero with { MarryTime = now, MarryType = arg.MarryType };
        heroes[heroIdx] = updatedHero;
        // 保留 Num=0 作为 bag.UpdateBagData 的删除标记，客户端会据此清掉旧缓存。
        bagItems[ringIdx] = bagItems[ringIdx] with { Num = bagItems[ringIdx].Num - 1 };
        account = account with
        {
            Dock = account.Dock with { Heroes = heroes },
            Character = account.Character with { MarriedNum = account.Character.MarriedNum + 1 },
            Bag = bag with { Items = bagItems },
        };

        await services.SaveAccountAsync(account, ct);
        // TMarryRet 没有客户端需要读取的字段；业务错误由外层 TResponse.Err 返回。
        return new([], updatedHero, true, "");
    }

    internal async Task<byte[]> BuildAddExpRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        HeroAddExpArg arg = ProtocolDecoder.DecodeHeroAddExp(request.Args);
        if (arg.HeroId == 0 || arg.Items.Count == 0) return [];

        using var _ = await services.LockAccountAsync(profileId, ct);

        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0) return [];
        Hero hero = heroList[heroIdx];

        int totalExp = 0;
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> bagItems = bag.Items.ToList();
        foreach (ItemCount item in arg.Items)
        {
            if (!services.ExpPerItem.TryGetValue(item.Id, out int perExp)) continue;
            totalExp += perExp * item.Num;
            int bagIdx = bagItems.FindIndex(i => i.TemplateId == item.Id);
            if (bagIdx >= 0)
            {
                int newNum = bagItems[bagIdx].Num - item.Num;
                if (newNum <= 0) bagItems.RemoveAt(bagIdx);
                else bagItems[bagIdx] = bagItems[bagIdx] with { Num = newNum };
            }
        }

        if (totalExp == 0) return [];

        int level = hero.Level;
        int exp = hero.Exp + totalExp;
        int maxLevel = 200;
        while (level < maxLevel)
        {
            int needExp = services.ExpNeeded.GetValueOrDefault(level, 500);
            if (exp < needExp) break;
            exp -= needExp;
            level++;
        }

        heroList[heroIdx] = hero with { Level = level, Exp = exp };
        account = account with { Dock = dock with { Heroes = heroList }, Bag = bag with { Items = bagItems } };
        await services.SaveAccountAsync(account, ct);

        return ProtocolEncoder.EncodeHeroAddExpRet(arg.HeroId, arg.Items);
    }

    internal async Task<byte[]> BuildGetHerosTacticAsync(string profileId, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerFleet fleet = account.Fleet ?? PlayerAccountFactory.DefaultFleet();
        return ProtocolEncoder.EncodeFleet(fleet);
    }

    internal async Task<byte[]> BuildSetHerosTacticAsync(TRequest request, string profileId, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        List<FleetEntry> entries = ProtocolDecoder.DecodeSetHerosTactic(request.Args ?? []);
        PlayerFleet newFleet = new(entries);
        PlayerAccount updated = account with { Fleet = newFleet };
        await services.SaveAccountAsync(updated, ct);
        return ProtocolEncoder.EncodeFleet(newFleet);
    }

    internal async Task<byte[]> BuildLockHeroRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        LockHeroArg arg = ProtocolDecoder.DecodeLockHeroArg(request.Args);

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0) return [];
        heroList[heroIdx] = heroList[heroIdx] with { Lock = arg.Lock };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);
        return ProtocolEncoder.EncodeLockHeroRet(arg.HeroId);
    }

    internal async Task<RetireResult> BuildRetireHeroRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return new([], [], [], false);
        RetireHeroArg arg = ProtocolDecoder.DecodeRetireHeroArg(request.Args);
        HashSet<uint> requestedIds = arg.HeroIds.Where(id => id != 0).ToHashSet();
        if (requestedIds.Count == 0) return new([], [], [], false);

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> retiredHeroes = dock.Heroes.Where(h => requestedIds.Contains(h.HeroId)).ToList();
        if (retiredHeroes.Count == 0) return new([], [], [], false);

        HashSet<uint> retiredIds = retiredHeroes.Select(h => h.HeroId).ToHashSet();
        List<Hero> remainingHeroes = dock.Heroes.Where(h => !retiredIds.Contains(h.HeroId)).ToList();

        // 退役奖励来自 config_ship_main.break_down_get：每项为 [GoodsType, ConfigId, Num]。
        Dictionary<(int Type, int ConfigId), int> rewardMap = new();
        foreach (Hero retired in retiredHeroes)
        {
            Configs.ConfigShipMain? config = ShipMainLoader.Get(retired.TemplateId);
            if (config?.BreakDownGet is not { Count: > 0 } entries) continue;
            foreach (List<long> entry in entries)
            {
                if (entry.Count < 3 || entry[0] <= 0 || entry[2] <= 0) continue;
                var key = (checked((int)entry[0]), checked((int)entry[1]));
                rewardMap[key] = checked(rewardMap.GetValueOrDefault(key) + (int)entry[2]);
            }
        }

        List<CommonReward> rewards = new();
        foreach (var ((type, configId), num) in rewardMap)
        {
            if (type == GameServices.GoodsTypeCurrency)
                account = GameServices.AddCurrency(account, configId, num);
            else
                account = GameServices.AddBagItem(account, configId, num);
            rewards.Add(new CommonReward(type, configId, num));
        }

        // 客户端退役成功后会询问是否继续分解舰娘原装备。普通退役需先卸下装备；
        // IsDisEquip=true 时才直接删除，并通过删除标记同步装备缓存。
        PlayerEquip equip = account.Equip ?? new PlayerEquip([], 2000);
        List<EquipItem> equipItems = equip.Items.ToList();
        List<uint> removedEquipIds = equipItems
            .Where(e => retiredIds.Contains(e.HeroId))
            .Select(e => e.EquipId)
            .ToList();
        if (arg.IsDisEquip)
            equipItems.RemoveAll(e => retiredIds.Contains(e.HeroId));
        else
            for (int i = 0; i < equipItems.Count; i++)
                if (retiredIds.Contains(equipItems[i].HeroId))
                    equipItems[i] = equipItems[i] with { HeroId = 0 };

        PlayerFleet? fleet = account.Fleet;
        if (fleet is not null)
        {
            List<FleetEntry> tactics = fleet.Tactics.Select(entry => entry with
            {
                HeroInfo = entry.HeroInfo?.Where(id => id <= 0 || !retiredIds.Contains((uint)id)).ToList(),
                ExHeroInfo = entry.ExHeroInfo?.Where(id => id <= 0 || !retiredIds.Contains((uint)id)).ToList(),
            }).ToList();
            fleet = fleet with { Tactics = tactics };
        }

        PlayerBath? bath = account.Bath;
        if (bath is not null)
            bath = bath with { HeroList = bath.HeroList.Where(h => !retiredIds.Contains(h.HeroId)).ToList() };

        PlayerCharacter character = account.Character;
        if (retiredIds.Contains(character.SecretaryId))
            character = character with { SecretaryId = remainingHeroes.FirstOrDefault()?.HeroId ?? 0 };

        account = account with
        {
            Character = character,
            Dock = dock with { Heroes = remainingHeroes },
            Equip = equip with { Items = equipItems },
            Fleet = fleet,
            Bath = bath,
        };
        await services.SaveAccountAsync(account, ct);
        return new(
            ProtocolEncoder.EncodeRetireHeroRet(rewards),
            retiredHeroes.Select(h => h.HeroId).ToList(),
            arg.IsDisEquip ? removedEquipIds : [],
            true);
    }

    internal async Task<ChangeNameResult> BuildChangeNameRetAsync(
        TRequest request, string profileId, int now, CancellationToken ct)
    {
        if (request.Args is null)
            return new([], null, false, "rename request is missing");
        ChangeHeroNameArg arg = ProtocolDecoder.DecodeChangeHeroNameArg(request.Args);
        // 空字符串是客户端“重置”按钮的合法语义：清除自定义名并恢复本地语言名称。
        if (arg.HeroId == 0)
            return new([], null, false, "rename request is invalid");

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0)
            return new([], null, false, "hero was not found");

        Hero updatedHero = heroList[heroIdx] with { Name = arg.Name, ChangeNameTime = now };
        heroList[heroIdx] = updatedHero;
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);
        return new([], updatedHero, true, "");
    }

    internal async Task<AddAffectionResult> BuildAddAffectionRetAsync(
        TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return new([], null, false, "gift request is missing");
        HeroAddAffectionArg arg = ProtocolDecoder.DecodeHeroAddAffectionArg(request.Args);
        if (arg.HeroId == 0 || arg.TemplateId <= 0 || arg.Num <= 0)
            return new([], null, false, "gift request is invalid");

        ConfigAffectionItem? gift = services.GetAffectionItem(arg.TemplateId);
        if (gift is null || gift.AffectionExp <= 0)
            return new([], null, false, "gift configuration was not found");

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0)
            return new([], null, false, "hero was not found");

        Hero hero = heroList[heroIdx];
        int maxAffection = hero.MarryTime == 0
            ? PlayerAccountFactory.UnmarriedMaxAffection
            : PlayerAccountFactory.MarriedMaxAffection;
        int remainingAffection = maxAffection - hero.Affection;
        if (remainingAffection <= 0)
            return new([], null, false, "affection is already at its current limit");

        // 客户端通常会限制滑块；服务端也只消耗达到当前上限实际需要的数量，
        // 避免旧档单位异常或并发刷新时多扣礼物。
        int giftsNeeded = checked((int)(((long)remainingAffection + gift.AffectionExp - 1) / gift.AffectionExp));
        int giftsToConsume = Math.Min(arg.Num, giftsNeeded);

        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> bagItems = bag.Items.ToList();
        int bagIdx = bagItems.FindIndex(i => i.TemplateId == arg.TemplateId);
        if (bagIdx < 0 || bagItems[bagIdx].Num < giftsToConsume)
            return new([], null, false, "not enough gifts");

        long requestedAffection = checked((long)hero.Affection + (long)gift.AffectionExp * giftsToConsume);
        int affection = checked((int)Math.Min(requestedAffection, maxAffection));

        Hero updatedHero = hero with { Affection = affection };
        heroList[heroIdx] = updatedHero;
        bagItems[bagIdx] = bagItems[bagIdx] with { Num = bagItems[bagIdx].Num - giftsToConsume };
        account = account with
        {
            Dock = dock with { Heroes = heroList },
            Bag = bag with { Items = bagItems },
        };
        await services.SaveAccountAsync(account, ct);
        return new(
            ProtocolEncoder.EncodeHeroAddAffectionRet(arg.HeroId, updatedHero.Affection),
            updatedHero,
            true,
            "");
    }

    internal async Task<byte[]> BuildGetHeroInfoRetAsync(string profileId, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        List<HeroGrid> heroes = account.Dock.Heroes.Select(GameServices.ToHeroGrid).ToList();
        return PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize));
    }

    internal async Task<byte[]> BuildGetHeroInfoByHeroIdArrayRetAsync(string profileId, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        List<HeroGrid> heroes = account.Dock.Heroes.Select(GameServices.ToHeroGrid).ToList();
        return PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize));
    }

    /// <summary>处理 hero.HeroAdvance：按 config_ship_break 校验并执行突破。</summary>
    /// <summary>同 enhance_type 素材的强化值加成，config_parameter[110] match_enhance_ratio = 15000（×1e-4）。</summary>
    private const double IntensifyMatchRatio = 1.5;

    /// <summary>钻石强化（SuperIntensify）的强化值倍率，strengthen_page 的 data.ratio。</summary>
    private const int SuperIntensifyRatio = 2;

    /// <summary>钻石强化每条素材的钻石花费，config_parameter[31] diamond_num_per_girl = 5。</summary>
    private const int SuperIntensifyDiamondPerMaterial = 5;

    /// <summary>
    /// 处理 hero.HeroIntensify（舰船强化）：消耗素材舰娘，按属性累加强化值。
    /// 数值口径以客户端 Strengthen_Page.GenPropertyData 为准：
    ///   提供量 = Σ int(provide_power_exp[attr] × (素材与目标同 enhance_type ? 1.5 : 1))
    ///   钻石强化再 ×2，并按每条素材扣 5 钻石
    ///   总量   = IntensifyLvl × need + CurExp + 提供量，上限 max_power_prop[attr] × need
    ///   新等级 = 总量 / need，余量 = 总量 % need
    /// 客户端 HeroAttr:_GetIntensify 按 AddAttr(AttrType, IntensifyLvl) 加算属性，即 1 级 = 1 点。
    /// 三张表的键都是随突破变化的 TemplateId（sm_id），必须按舰娘当前模板取。
    /// </summary>
    internal async Task<IntensifyResult> BuildIntensifyRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return new([], null, [], false, "");
        var (heroId, consumedHeros, superIntensify) = ProtocolDecoder.DecodeIntensifyArg(request.Args);

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        List<Hero> heroList = account.Dock.Heroes.ToList();
        if (heroList.Count(h => h.HeroId == heroId) != 1)
            return new([], null, [], false, "intensify target not found");
        Hero hero = heroList.First(h => h.HeroId == heroId);

        ConfigShipNeedPowerExp? need = ShipIntensifyLoader.GetNeed(hero.TemplateId);
        ConfigShipMaxPower? max = ShipIntensifyLoader.GetMax(hero.TemplateId);
        if (need?.NeedPowerExp is null || max?.MaxPowerProp is null)
            return new([], null, [], false, "intensify config missing");

        // 素材校验与突破一致：非零、不重复、不含目标本身、实际存在、未上锁、未被占用。
        // Lvl/Advance/已有强化进度三项对应客户端 Strengthen_PageLogic:ScreenShip 中无条件
        // 生效的筛选；同型与稀有度两项受界面开关影响，不在服务端强制。
        if (consumedHeros.Count == 0 || consumedHeros.Any(id => id == 0) ||
            consumedHeros.Distinct().Count() != consumedHeros.Count || consumedHeros.Contains(heroId))
            return new([], null, [], false, "invalid intensify materials");
        HashSet<uint> consumedIdSet = consumedHeros.ToHashSet();
        List<Hero> materials = heroList.Where(h => consumedIdSet.Contains(h.HeroId)).ToList();
        if (materials.Count != consumedHeros.Count ||
            materials.Any(m => m.Lock || m.Level != 1 || m.Advance > 1 ||
                m.Intensify is { Count: > 0 } || IsHeroInUse(account, m.HeroId)))
            return new([], null, [], false, "invalid intensify materials");

        int diamondCost = superIntensify ? SuperIntensifyDiamondPerMaterial * materials.Count : 0;
        if (diamondCost > 0 && account.Character.Diamond < diamondCost)
            return new([], null, [], false, "not enough diamond");

        long targetType = need.EnhanceType;
        Dictionary<int, int> maxLevels = ToAttrMap(max.MaxPowerProp);
        Dictionary<int, AttrIntensify> current = (hero.Intensify ?? [])
            .GroupBy(entry => entry.AttrType)
            .ToDictionary(group => group.Key, group => group.First());

        var updated = new List<AttrIntensify>();
        bool anyGain = false;
        foreach (List<long> entry in need.NeedPowerExp)
        {
            if (entry is not { Count: >= 2 }) continue;
            int attrType = checked((int)entry[0]);
            long perLevel = entry[1];
            AttrIntensify existing = current.TryGetValue(attrType, out AttrIntensify? found)
                ? found
                : new AttrIntensify(attrType);
            // need 为 0 的属性无法换算等级（基础包里确有此类行），保持原样不动。
            if (perLevel <= 0 || !maxLevels.TryGetValue(attrType, out int maxLevel) || maxLevel <= 0)
            {
                updated.Add(existing);
                continue;
            }

            long gain = 0;
            foreach (Hero material in materials)
            {
                ConfigShipProvidePowerExp? provide = ShipIntensifyLoader.GetProvide(material.TemplateId);
                if (provide?.ProvidePowerExp is null) continue;
                bool sameType = ShipIntensifyLoader.GetNeed(material.TemplateId)?.EnhanceType == targetType;
                double factor = sameType ? IntensifyMatchRatio : 1.0;
                foreach (List<long> provided in provide.ProvidePowerExp)
                    if (provided is { Count: >= 2 } && provided[0] == attrType)
                        gain = (long)(gain + provided[1] * factor);
            }
            if (superIntensify) gain *= SuperIntensifyRatio;

            long total = (long)existing.IntensifyLvl * perLevel + existing.CurExp + gain;
            long cap = (long)maxLevel * perLevel;
            if (total > cap) total = cap;
            var next = new AttrIntensify(attrType, checked((int)(total / perLevel)), checked((int)(total % perLevel)));
            if (next.IntensifyLvl != existing.IntensifyLvl || next.CurExp != existing.CurExp) anyGain = true;
            updated.Add(next);
        }

        // 全属性均已满级时客户端本就用 _CheckNoGains 拦住，这里再兜一层，避免白吃素材。
        if (!anyGain) return new([], null, [], false, "intensify produced no gain");

        List<uint> consumedIds = materials.Select(m => m.HeroId).ToList();
        heroList.RemoveAll(h => consumedIdSet.Contains(h.HeroId));
        Hero updatedHero = hero with { Intensify = updated };
        int updatedIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (updatedIdx < 0) return new([], null, [], false, "intensify target not found");
        heroList[updatedIdx] = updatedHero;

        // 素材可能携带装备，与突破同样先安全卸下，避免 EquipItem.HeroId 指向已不存在的舰娘。
        PlayerEquip equip = account.Equip ?? new PlayerEquip([], 2000);
        List<EquipItem> equipItems = equip.Items
            .Select(item => consumedIdSet.Contains(item.HeroId) ? item with { HeroId = 0 } : item).ToList();

        account = account with
        {
            Dock = account.Dock with { Heroes = heroList },
            Equip = equip with { Items = equipItems },
        };
        if (diamondCost > 0) account = GameServices.AddCurrency(account, 2, -diamondCost);

        await services.SaveAccountAsync(account, ct);
        return new([], updatedHero, consumedIds, true, "", diamondCost);
    }

    /// <summary>把 [[attr, value], ...] 形式的配置列摊平成字典，重复项取先出现的一条。</summary>
    private static Dictionary<int, int> ToAttrMap(List<List<long>> pairs)
    {
        var map = new Dictionary<int, int>();
        foreach (List<long> pair in pairs)
            if (pair is { Count: >= 2 })
                map.TryAdd(checked((int)pair[0]), checked((int)pair[1]));
        return map;
    }

    internal async Task<AdvanceResult> BuildAdvanceRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return new([], null, [], false);
        var (heroId, consumedHeros, consumeItems) = ProtocolDecoder.DecodeAdvanceArg(request.Args);

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0 || heroList.Count(h => h.HeroId == heroId) != 1)
            return new([], null, [], false);

        Hero hero = heroList[heroIdx];
        ConfigShipBreak? config = ShipBreakLoader.Get(hero.TemplateId);
        if (config is null || hero.Level < config.MinLevel ||
            !int.TryParse(config.BreakTo, out int newTemplateId) || newTemplateId <= 0 ||
            !TryGetAdvanceRequirements(config, out HashSet<int> allowedHeroTemplates,
                out HashSet<int> allowedHeroQualities, out int requiredHeroCount,
                out HashSet<int> allowedItemTemplates, out int requiredItemCount,
                out int currencyId, out int currencyCost))
            return new([], null, [], false);

        // 请求只能选择配置允许且实际存在的素材；零值、重复实例、额外素材与缺失素材均拒绝。
        if (consumedHeros.Any(id => id == 0) || consumedHeros.Distinct().Count() != consumedHeros.Count ||
            consumedHeros.Count != requiredHeroCount || consumedHeros.Contains(heroId))
            return new([], null, [], false);
        HashSet<uint> consumedIdSet = consumedHeros.ToHashSet();
        List<Hero> consumedHeroes = heroList.Where(h => consumedIdSet.Contains(h.HeroId)).ToList();
        if (consumedHeroes.Count != requiredHeroCount ||
            consumedHeroes.Any(material => material.Lock ||
                !IsAllowedAdvanceMaterial(material, allowedHeroTemplates, allowedHeroQualities) ||
                IsHeroInUse(account, material.HeroId)))
            return new([], null, [], false);

        // 道具列表按“每个实例一个模板 ID”编码，必须与配置数量完全一致。
        if (consumeItems.Any(id => id == 0 || id > int.MaxValue) ||
            consumeItems.Count != requiredItemCount ||
            consumeItems.Any(id => !allowedItemTemplates.Contains((int)id)))
            return new([], null, [], false);
        Dictionary<int, int> requestedItems = consumeItems
            .GroupBy(id => (int)id)
            .ToDictionary(group => group.Key, group => group.Count());
        foreach ((int templateId, int count) in requestedItems)
        {
            int owned = account.Bag?.Items.FirstOrDefault(item => item.TemplateId == templateId)?.Num ?? 0;
            if (owned < count) return new([], null, [], false);
        }
        if (currencyId != 1 || currencyCost < 0 || account.Character.Gold < currencyCost)
            return new([], null, [], false);

        int newAdvance = hero.Advance + 1;
        List<uint> consumedIds = consumedHeroes.Select(h => h.HeroId).ToList();
        heroList.RemoveAll(h => consumedIdSet.Contains(h.HeroId));

        // 删除素材会改变列表下标，必须按实例 ID 重新定位主英雄。使用删除前的 heroIdx
        // 会在素材位于主英雄之前时覆盖相邻舰娘，并留下两个相同 HeroId 的主英雄副本。
        Hero updatedHero = hero with { Advance = newAdvance, TemplateId = newTemplateId };
        int updatedHeroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (updatedHeroIdx < 0)
            return new([], null, [], false);
        heroList[updatedHeroIdx] = updatedHero;

        // 素材舰娘可能携带抽卡时发放的默认装备。消耗舰娘时保留装备实例并安全卸下，
        // 避免 EquipItem.HeroId 指向已经不存在的舰娘。
        PlayerEquip equip = account.Equip ?? new PlayerEquip([], 2000);
        List<EquipItem> equipItems = equip.Items.Select(item =>
            consumedIdSet.Contains(item.HeroId) ? item with { HeroId = 0 } : item).ToList();

        account = account with
        {
            Dock = dock with { Heroes = heroList },
            Equip = equip with { Items = equipItems },
        };

        foreach ((int templateId, int count) in requestedItems)
            account = GameServices.AddBagItem(account, templateId, -count);
        account = GameServices.AddCurrency(account, currencyId, -currencyCost);

        await services.SaveAccountAsync(account, ct);
        return new([], updatedHero, consumedIds, true);
    }

    /// <summary>
    /// 处理 hero.HeroAdvanceMUB（彩色船突破）：按 config_ship_break 校验，消耗
    /// TAdvanceMubItemInfo{ItemId,ItemNum} 道具（碎片）与货币，Advance+1、TemplateId=break_to。
    /// 与普通突破的区别：不消耗重复舰娘，只消耗道具。
    /// </summary>
    internal async Task<AdvanceResult> BuildAdvanceMubRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return new([], null, [], false);
        var (heroId, consumeItems) = ProtocolDecoder.DecodeAdvanceMubArg(request.Args);

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return new([], null, [], false);

        Hero hero = heroList[heroIdx];
        ConfigShipBreak? config = ShipBreakLoader.Get(hero.TemplateId);
        if (config is null || hero.Level < config.MinLevel ||
            !int.TryParse(config.BreakTo, out int newTemplateId) || newTemplateId <= 0)
            return new([], null, [], false);

        // 道具要求可选：配置了 break_item_mub 才校验并消耗道具；未配置（null/空）则不要求。
        if (config.BreakItemMub is { Count: > 0 } itemReq)
        {
            if (itemReq.Count != 2 || itemReq[0] <= 0 || itemReq[1] <= 0 ||
                itemReq[0] > int.MaxValue || itemReq[1] > int.MaxValue)
                return new([], null, [], false);

            int requiredFragmentId = (int)itemReq[0];
            int requiredItemCount = (int)itemReq[1];
            HashSet<int> allowedItems = [requiredFragmentId];
            foreach (long usableId in config.BreakUsableitemMub ?? [])
                if (usableId > 0 && usableId <= int.MaxValue) allowedItems.Add((int)usableId);

            // 校验消耗道具：每个 ItemId 必须在 break_item_mub / break_usableitem_mub 允许范围内，
            // 按转换率折算成碎片等效数量后总和必须等于配置要求（对应 Lua GetMuboSelectBreakItemCount）。
            int totalItems = 0;
            foreach ((uint itemId, int itemNum) in consumeItems)
            {
                if (itemId == 0 || itemNum <= 0 || itemId > int.MaxValue || !allowedItems.Contains((int)itemId))
                    return new([], null, [], false);
                int effective = (int)itemId == requiredFragmentId
                    ? itemNum
                    : itemNum * MubConversionLoader.GetConversion((int)itemId);
                totalItems += effective;
            }
            if (totalItems != requiredItemCount) return new([], null, [], false);

            foreach ((uint itemId, int itemNum) in consumeItems)
            {
                int owned = account.Bag?.Items.FirstOrDefault(i => i.TemplateId == (int)itemId)?.Num ?? 0;
                if (owned < itemNum) return new([], null, [], false);
            }
        }

        // 货币（config.currency_cost = [GoodsType, CurrencyId, Cost]）。
        int currencyId = 1, currencyCost = 0;
        if (config.CurrencyCost is { Count: 3 } currency && currency[0] == GameServices.GoodsTypeCurrency)
        {
            if (currency[1] <= 0 || currency[1] > int.MaxValue || currency[2] < 0 || currency[2] > int.MaxValue)
                return new([], null, [], false);
            currencyId = (int)currency[1];
            currencyCost = (int)currency[2];
        }
        if (currencyId != 1 || currencyCost < 0 || account.Character.Gold < currencyCost)
            return new([], null, [], false);

        int newAdvance = hero.Advance + 1;
        Hero updatedHero = hero with { Advance = newAdvance, TemplateId = newTemplateId };
        heroList[heroIdx] = updatedHero;
        account = account with { Dock = dock with { Heroes = heroList } };

        foreach ((uint itemId, int itemNum) in consumeItems)
            account = GameServices.AddBagItem(account, (int)itemId, -itemNum);
        account = GameServices.AddCurrency(account, currencyId, -currencyCost);

        await services.SaveAccountAsync(account, ct);
        return new([], updatedHero, [], true);
    }

    private static bool TryGetAdvanceRequirements(
        ConfigShipBreak config,
        out HashSet<int> allowedHeroTemplates,
        out HashSet<int> allowedHeroQualities,
        out int requiredHeroCount,
        out HashSet<int> allowedItemTemplates,
        out int requiredItemCount,
        out int currencyId,
        out int currencyCost)
    {
        allowedHeroTemplates = [];
        allowedHeroQualities = [];
        requiredHeroCount = 0;
        allowedItemTemplates = [];
        requiredItemCount = 0;
        currencyId = 0;
        currencyCost = 0;

        if (config.BreakItem is { Count: > 0 } heroRequirement)
        {
            if (heroRequirement.Count != 2 ||
                !TryReadIntList(heroRequirement[0], out allowedHeroTemplates) ||
                !TryReadInt(heroRequirement[1], out requiredHeroCount) ||
                allowedHeroTemplates.Count == 0 || requiredHeroCount <= 0)
                return false;
        }

        // 特殊第七次突破的 break_item_optional 是允许作为单个素材的舰娘品质列表
        // （当前配置为 4=SR / 5=SSR），而不是实例 ID 或消耗数量。
        if (config.BreakItemOptional is { Count: > 0 } optionalQualities)
        {
            if (requiredHeroCount != 0 || optionalQualities.Any(quality => quality <= 0 || quality > int.MaxValue))
                return false;
            allowedHeroQualities.UnionWith(optionalQualities.Select(quality => (int)quality));
            requiredHeroCount = 1;
        }

        if (config.BreakItemMub is { Count: > 0 } itemRequirement)
        {
            if (itemRequirement.Count != 2 || itemRequirement[0] <= 0 || itemRequirement[1] <= 0 ||
                itemRequirement[0] > int.MaxValue || itemRequirement[1] > int.MaxValue)
                return false;
            allowedItemTemplates.Add((int)itemRequirement[0]);
            foreach (long usableItemId in config.BreakUsableitemMub ?? [])
            {
                if (usableItemId <= 0 || usableItemId > int.MaxValue) return false;
                allowedItemTemplates.Add((int)usableItemId);
            }
            requiredItemCount = (int)itemRequirement[1];
        }

        if (config.CurrencyCost is not { Count: 3 } currency ||
            currency[0] != GameServices.GoodsTypeCurrency || currency[1] <= 0 || currency[1] > int.MaxValue ||
            currency[2] < 0 || currency[2] > int.MaxValue)
            return false;
        currencyId = (int)currency[1];
        currencyCost = (int)currency[2];
        return true;
    }

    private bool IsAllowedAdvanceMaterial(
        Hero material,
        IReadOnlySet<int> allowedTemplates,
        IReadOnlySet<int> allowedQualities)
    {
        if (allowedTemplates.Contains(material.TemplateId)) return true;
        if (allowedQualities.Count == 0) return false;
        ConfigShipMain? ship = ShipMainLoader.Get(material.TemplateId);
        return ship is not null && ship.ShipInfoId > 0 && ship.ShipInfoId <= int.MaxValue &&
            services.ShipInfos.TryGetValue((int)ship.ShipInfoId, out ConfigShipInfo? info) &&
            info.Quality > 0 && info.Quality <= int.MaxValue && allowedQualities.Contains((int)info.Quality);
    }

    private static bool TryReadInt(object value, out int result)
    {
        if (value is JsonElement json && json.TryGetInt32(out result)) return true;
        return int.TryParse(Convert.ToString(value), out result);
    }

    private static bool TryReadIntList(object value, out HashSet<int> values)
    {
        values = [];
        if (value is not JsonElement { ValueKind: JsonValueKind.Array } json) return false;
        foreach (JsonElement item in json.EnumerateArray())
        {
            if (!item.TryGetInt32(out int templateId) || templateId <= 0) return false;
            values.Add(templateId);
        }
        return values.Count > 0;
    }

    private static bool IsHeroInUse(PlayerAccount account, uint heroId)
    {
        if (account.Character.SecretaryId == heroId) return true;
        if (account.Fleet?.Tactics.Any(entry =>
                (entry.HeroInfo?.Any(id => id > 0 && (uint)id == heroId) ?? false) ||
                (entry.ExHeroInfo?.Any(id => id > 0 && (uint)id == heroId) ?? false)) == true)
            return true;
        if (account.Bath?.HeroList.Any(hero => hero.HeroId == heroId) == true) return true;
        return account.Building?.Buildings.Any(building => building.HeroIds.Contains(heroId)) == true;
    }

    /// <summary>处理 hero.StudySkill：技能升级。SkillId 对应 PSkillId，Level 递增。</summary>
    internal async Task<byte[]> BuildStudySkillRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        var (heroId, skillId) = ProtocolDecoder.DecodeStudySkillArg(request.Args);

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];

        Hero hero = heroList[heroIdx];
        List<PSkillEntry> skills = (hero.PSkills ?? []).ToList();
        int skillIdx = skills.FindIndex(s => s.PSkillId == skillId);

        Console.WriteLine(skillIdx);

        if (skillIdx < 0)
            skills.Add(new PSkillEntry((uint)skillId, level: 1));
        else
            skills[skillIdx].Level += 1;

        heroList[heroIdx] = hero with { PSkills = skills };
        account = account with { Dock = dock with { Heroes = heroList } };

        await services.SaveAccountAsync(account, ct);
        byte[] ret = EncodeStudySkillRet(heroId, skillId);
        return ret;
    }

    /// <summary>
    /// 处理 hero.HeroRemould：校验当前阶段、前置节点、等级/突破与全部消耗，随后原子写入
    /// 改造节点、阶段进度和技能新增/替换结果。
    /// </summary>
    internal async Task<RemouldResult> BuildHeroRemouldRetAsync(
        TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return new([], null, false, "remould request is missing");

        HeroRemouldArg arg = ProtocolDecoder.DecodeHeroRemouldArg(request.Args);
        if (arg.HeroId == 0 || arg.EffectId <= 0)
            return new([], null, false, "remould request is invalid");

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        List<Hero> heroes = account.Dock.Heroes.ToList();
        int heroIndex = heroes.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIndex < 0)
            return new([], null, false, "hero was not found");

        Hero hero = heroes[heroIndex];
        int shipInfoId = GameServices.ToIllustrateId(hero.TemplateId);
        if (!services.ShipInfos.TryGetValue(shipInfoId, out ConfigShipInfo? shipInfo) ||
            shipInfo.RemouldTemplate is not { Count: > 0 } stageIds)
            return new([], null, false, "this hero cannot be remoulded");
        if (hero.Level < shipInfo.MinLevel)
            return new([], null, false, "hero level is too low for remoulding");

        ConfigShipRemouldEffect? effect = RemouldConfigLoader.GetEffect(arg.EffectId);
        if (effect is null)
            return new([], null, false, "remould effect was not found");

        int effectStage = FindEffectStage(stageIds, arg.EffectId);
        if (effectStage < 0)
            return new([], null, false, "remould effect does not belong to this hero");

        HashSet<int> completed = (hero.RemouldEffects ?? []).Where(id => id > 0).ToHashSet();
        if (completed.Contains(arg.EffectId))
            return new([], null, false, "remould effect is already active");

        int currentStage = CalculateRemouldLevel(stageIds, completed);
        if (currentStage >= stageIds.Count || effectStage != currentStage)
            return new([], null, false, "remould effect is not in the current stage");

        List<long> prerequisites = effect.RemouldPrev?.Where(id => id > 0).ToList() ?? [];
        // 客户端 GetRemouldEffectData 的定义是：多个前置节点中完成任意一个即可解锁。
        if (prerequisites.Count > 0 && !prerequisites.Any(id => completed.Contains(checked((int)id))))
            return new([], null, false, "remould prerequisite is not complete");
        if (hero.Level < effect.LimitLevel)
            return new([], null, false, "hero level is too low for this remould effect");
        int advance = Math.Max(hero.Advance,
            checked((int)(ShipMainLoader.Get(hero.TemplateId)?.BreakLevel ?? 0)));
        if (advance < effect.LimitStar)
            return new([], null, false, "hero advance level is too low for this remould effect");

        if (!TryBuildRemouldCosts(effect.Cost, out Dictionary<(int Type, int Id), long> costs,
                out string costError))
            return new([], null, false, costError);

        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        foreach (var (key, amount) in costs)
        {
            if (key.Type == GameServices.GoodsTypeCurrency)
            {
                if (!GameServices.TryGetCurrency(account, key.Id, out int current) || current < amount)
                    return new([], null, false, "not enough currency for remoulding");
            }
            else
            {
                int current = bag.Items.FirstOrDefault(i => i.TemplateId == key.Id)?.Num ?? 0;
                if (current < amount)
                    return new([], null, false, "not enough items for remoulding");
            }
        }

        foreach (var (key, amount) in costs)
        {
            int delta = checked(-(int)amount);
            account = key.Type == GameServices.GoodsTypeCurrency
                ? GameServices.AddCurrency(account, key.Id, delta)
                : GameServices.AddBagItem(account, key.Id, delta);
        }

        completed.Add(arg.EffectId);
        List<int> remouldEffects = [.. completed.OrderBy(id => id)];
        int remouldLevel = CalculateRemouldLevel(stageIds, completed);
        List<PSkillEntry> skills = ApplyRemouldSkills(hero.PSkills, effect.RemouldEffectType);
        Hero updatedHero = hero with
        {
            RemouldEffects = remouldEffects,
            RemouldLevel = remouldLevel,
            PSkills = skills,
        };
        heroes[heroIndex] = updatedHero;
        account = account with { Dock = account.Dock with { Heroes = heroes } };
        await services.SaveAccountAsync(account, ct);
        return new([], updatedHero, true, "");
    }

    private static int FindEffectStage(IReadOnlyList<long> stageIds, int effectId)
    {
        for (int i = 0; i < stageIds.Count; i++)
        {
            ConfigShipRemouldTemplate? stage = RemouldConfigLoader.GetTemplate(checked((int)stageIds[i]));
            if (stage?.RemouldItemGroup?.Contains(effectId) == true) return i;
        }
        return -1;
    }

    /// <summary>返回从第一阶段起连续完成的阶段数；尾部空阶段也视为完成。</summary>
    private static int CalculateRemouldLevel(IReadOnlyList<long> stageIds, HashSet<int> completed)
    {
        int level = 0;
        foreach (long stageId in stageIds)
        {
            ConfigShipRemouldTemplate? stage = RemouldConfigLoader.GetTemplate(checked((int)stageId));
            if (stage is null) break;
            List<long> group = stage.RemouldItemGroup?.Where(id => id > 0).ToList() ?? [];
            if (group.Count > 0 && !group.All(id => completed.Contains(checked((int)id)))) break;
            level++;
        }
        return level;
    }

    private static bool TryBuildRemouldCosts(
        IReadOnlyList<List<long>>? configured,
        out Dictionary<(int Type, int Id), long> costs,
        out string error)
    {
        costs = [];
        error = "";
        foreach (List<long> cost in configured ?? [])
        {
            if (cost.Count < 3 || cost[0] <= 0 || cost[1] <= 0 || cost[2] <= 0 ||
                cost[0] > int.MaxValue || cost[1] > int.MaxValue || cost[2] > int.MaxValue)
            {
                error = "remould cost configuration is invalid";
                return false;
            }
            int type = (int)cost[0];
            int id = (int)cost[1];
            // 舰船和装备是实例型资产，不能按背包堆叠直接扣除；当前配置不应使用这两类。
            if (type is 2 or 3)
            {
                error = "unsupported remould cost type";
                return false;
            }
            var key = (Type: type, Id: id);
            try { costs[key] = checked(costs.GetValueOrDefault(key) + cost[2]); }
            catch (OverflowException)
            {
                error = "remould cost is too large";
                return false;
            }
        }
        return true;
    }

    private static List<PSkillEntry> ApplyRemouldSkills(
        IReadOnlyList<PSkillEntry>? current,
        IReadOnlyList<List<long>>? effects)
    {
        List<PSkillEntry> skills = (current ?? [])
            .Select(skill => new PSkillEntry(skill.PSkillId, skill.PSkillExp, skill.Level, skill.Replace))
            .ToList();
        foreach (List<long> item in effects ?? [])
        {
            if (item.Count < 2) continue;
            int type = checked((int)item[0]);
            if (type == 4 && item[1] is > 0 and <= uint.MaxValue)
            {
                uint skillId = checked((uint)item[1]);
                if (skills.All(skill => skill.PSkillId != skillId))
                    skills.Add(new PSkillEntry(skillId, level: 1));
            }
            else if (type == 5 && item.Count >= 3 &&
                     item[1] is > 0 and <= uint.MaxValue && item[2] is > 0 and <= int.MaxValue)
            {
                uint oldSkillId = checked((uint)item[1]);
                int newSkillId = checked((int)item[2]);
                PSkillEntry? skill = skills.FirstOrDefault(value => value.PSkillId == oldSkillId);
                if (skill is null)
                    skills.Add(new PSkillEntry(oldSkillId, level: 1, replace: newSkillId));
                else
                    skill.Replace = newSkillId;
            }
        }
        return skills;
    }

    /// <summary>编码 hero.StudySkill 响应 (THeroSkill): HeroId(1, uint32), SkillId(2, int32)。</summary>
    private static byte[] EncodeStudySkillRet(uint heroId, int skillId)
    {
        using var ms = new System.IO.MemoryStream();
        if (heroId != 0) { ms.WriteByte(0x08); ProtocolPackage.WriteVarint(ms, heroId); }
        if (skillId != 0) { ms.WriteByte(0x10); ProtocolPackage.WriteVarint(ms, unchecked((ulong)skillId)); }
        return ms.ToArray();
    }
}
