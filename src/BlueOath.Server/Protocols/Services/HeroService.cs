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
                out int requiredHeroCount, out HashSet<int> allowedItemTemplates, out int requiredItemCount,
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
                !allowedHeroTemplates.Contains(material.TemplateId) || IsHeroInUse(account, material.HeroId)))
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

    private static bool TryGetAdvanceRequirements(
        ConfigShipBreak config,
        out HashSet<int> allowedHeroTemplates,
        out int requiredHeroCount,
        out HashSet<int> allowedItemTemplates,
        out int requiredItemCount,
        out int currencyId,
        out int currencyCost)
    {
        allowedHeroTemplates = [];
        requiredHeroCount = 0;
        allowedItemTemplates = [];
        requiredItemCount = 0;
        currencyId = 0;
        currencyCost = 0;

        // break_item_optional 的语义不是实例 ID 列表；在实现相应选择规则前拒绝，避免免费突破。
        if (config.BreakItemOptional is { Count: > 0 }) return false;

        if (config.BreakItem is { Count: > 0 } heroRequirement)
        {
            if (heroRequirement.Count != 2 ||
                !TryReadIntList(heroRequirement[0], out allowedHeroTemplates) ||
                !TryReadInt(heroRequirement[1], out requiredHeroCount) ||
                allowedHeroTemplates.Count == 0 || requiredHeroCount <= 0)
                return false;
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
