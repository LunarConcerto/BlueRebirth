using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>舰娘服务：hero.* / tactic.* 的领域逻辑（换装/升星/结婚/经验/锁定/退役/改名/好感度）。</summary>
internal sealed class HeroService(GameServices services)
{
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
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0) return [];
        heroList[heroIdx] = heroList[heroIdx] with { Lock = arg.Lock };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);
        return [];
    }

    internal async Task<byte[]> BuildRetireHeroRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        List<uint> heroIds = ProtocolDecoder.DecodeRetireHeroArg(request.Args);
        if (heroIds.Count == 0) return [];
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        heroList.RemoveAll(h => heroIds.Contains(h.HeroId));
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);
        return [];
    }

    internal async Task<byte[]> BuildChangeNameRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        ChangeHeroNameArg arg = ProtocolDecoder.DecodeChangeHeroNameArg(request.Args);
        if (arg.HeroId == 0 || string.IsNullOrEmpty(arg.Name)) return [];
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0) return [];
        heroList[heroIdx] = heroList[heroIdx] with { Name = arg.Name };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);
        return [];
    }

    internal async Task<byte[]> BuildAddAffectionRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        HeroAddAffectionArg arg = ProtocolDecoder.DecodeHeroAddAffectionArg(request.Args);
        if (arg.HeroId == 0 || arg.Num <= 0) return [];
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == arg.HeroId);
        if (heroIdx < 0) return [];
        Hero hero = heroList[heroIdx];
        heroList[heroIdx] = hero with { Affection = hero.Affection + arg.Num * 10000 };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);
        return [];
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

        if (skillIdx < 0)
            skills.Add(new PSkillEntry((uint)skillId, Level: 1));
        else
            skills[skillIdx] = skills[skillIdx] with { Level = skills[skillIdx].Level + 1 };

        heroList[heroIdx] = hero with { PSkills = skills };
        account = account with { Dock = dock with { Heroes = heroList } };

        await services.SaveAccountAsync(account, ct);
        return [];
    }
}
