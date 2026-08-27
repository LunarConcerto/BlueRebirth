using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>舰娘服务：hero.* / tactic.* 的领域逻辑（换装/升星/结婚/经验/锁定/退役/改名/好感度）。</summary>
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

    internal async Task<byte[]> BuildMarryRetAsync(TRequest request, string profileId, int now, CancellationToken ct)
    {
        MarryArg arg = ProtocolDecoder.DecodeMarryArg(request.Args ?? []);
        var account = await services.GetOrCreateAccountAsync(profileId, ct);

        var heroes = account.Dock.Heroes.ToList();
        var heroIdx = heroes.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0) return TMessageCodec.EncodeResponse(new TResponse(Err: 1, ErrMsg: "hero not found"));

        var hero = heroes[heroIdx];
        if (hero.MarryTime != 0) return TMessageCodec.EncodeResponse(new TResponse(Err: 2, ErrMsg: "already married"));

        heroes[heroIdx] = hero with { MarryTime = now, MarryType = arg.MarryType };
        account = account with { Dock = account.Dock with { Heroes = heroes } };
        account = account with { Character = account.Character with { MarriedNum = account.Character.MarriedNum + 1 } };
        account = GameServices.AddBagItem(account, 10180, -1);

        await services.SaveAccountAsync(account, ct);
        return TMessageCodec.EncodeResponse(new TResponse(Method: "hero.Marry", Time: checked((uint)now)));
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

        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> bagItems = bag.Items.ToList();
        int bagIdx = bagItems.FindIndex(i => i.TemplateId == arg.TemplateId);
        if (bagIdx < 0 || bagItems[bagIdx].Num < arg.Num)
            return new([], null, false, "not enough gifts");

        Hero hero = heroList[heroIdx];
        long affection = checked((long)hero.Affection + gift.AffectionExp * arg.Num);
        if (affection > int.MaxValue)
            return new([], null, false, "affection value is too large");

        Hero updatedHero = hero with { Affection = checked((int)affection) };
        heroList[heroIdx] = updatedHero;
        bagItems[bagIdx] = bagItems[bagIdx] with { Num = bagItems[bagIdx].Num - arg.Num };
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

    /// <summary>处理 hero.HeroAdvance：突破升星。消耗材料英雄，扣除金币，Advance+1，TemplateId+1。</summary>
    internal async Task<byte[]> BuildAdvanceRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        var (heroId, consumedHeros, consumeItems) = ProtocolDecoder.DecodeAdvanceArg(request.Args);

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];

        Hero hero = heroList[heroIdx];
        int newAdvance = hero.Advance + 1;
        int newTemplateId = hero.TemplateId + 1;

        // 移除消耗的英雄
        foreach (uint consumedId in consumedHeros)
            heroList.RemoveAll(h => h.HeroId == consumedId);

        // 更新主英雄
        heroList[heroIdx] = hero with { Advance = newAdvance, TemplateId = newTemplateId };

        account = account with { Dock = dock with { Heroes = heroList } };

        // 扣除消耗的道具
        foreach (uint itemId in consumeItems)
            account = GameServices.AddBagItem(account, (int)itemId, -1);

        // 扣除金币（config_ship_break.break_cost 默认约 10000）
        account = GameServices.AddCurrency(account, 1, -10000);

        await services.SaveAccountAsync(account, ct);
        return [];
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

    /// <summary>编码 hero.StudySkill 响应 (THeroSkill): HeroId(1, uint32), SkillId(2, int32)。</summary>
    private static byte[] EncodeStudySkillRet(uint heroId, int skillId)
    {
        using var ms = new System.IO.MemoryStream();
        if (heroId != 0) { ms.WriteByte(0x08); ProtocolPackage.WriteVarint(ms, heroId); }
        if (skillId != 0) { ms.WriteByte(0x10); ProtocolPackage.WriteVarint(ms, unchecked((ulong)skillId)); }
        return ms.ToArray();
    }
}
