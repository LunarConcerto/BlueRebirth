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
        (uint heroId, int luaIndex, uint equipId, _) = TMessageCodec.DecodeHeroChangeEquipArgs(request.Args);
        // Lua 客户端发送 1-based 索引，C# 数组是 0-based，需要转换。
        int index = luaIndex - 1;
        if (index < 0 || index >= 6)
            return [];
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);

        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
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
        if (equipId != 0)
        {
            account = GameServices.SetEquipHeroId(account, equipId, heroId);
            slots[index] = equipId;
        }

        heroList[heroIdx] = hero with { EquipSlots = slots };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);

        return [];
    }

    internal async Task<byte[]> BuildMarryRetAsync(TRequest request, string profileId, int now, CancellationToken ct)
    {
        var (heroId, marryType) = GameServices.DecodeMarryArg(request.Args ?? []);
        var account = await services.GetOrCreateAccountAsync(profileId, ct);

        var heroes = account.Dock.Heroes.ToList();
        var heroIdx = heroes.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return TMessageCodec.EncodeResponse(new TResponse(Err: 1, ErrMsg: "hero not found"));

        var hero = heroes[heroIdx];
        if (hero.MarryTime != 0) return TMessageCodec.EncodeResponse(new TResponse(Err: 2, ErrMsg: "already married"));

        heroes[heroIdx] = hero with { MarryTime = now, MarryType = marryType };
        account = account with { Dock = account.Dock with { Heroes = heroes } };
        account = account with { Character = account.Character with { MarriedNum = account.Character.MarriedNum + 1 } };
        account = GameServices.AddBagItem(account, 10180, -1);

        await services.SaveAccountAsync(account, ct);
        return TMessageCodec.EncodeResponse(new TResponse(Method: "hero.Marry", Time: checked((uint)now)));
    }

    internal async Task<byte[]> BuildAddExpRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        (uint heroId, List<(int Id, int Num)> items) = GameServices.DecodeHeroAddExp(request.Args);
        if (heroId == 0 || items.Count == 0) return [];

        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];
        Hero hero = heroList[heroIdx];

        int totalExp = 0;
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> bagItems = bag.Items.ToList();
        foreach ((int itemId, int num) in items)
        {
            if (!services.ExpPerItem.TryGetValue(itemId, out int perExp)) continue;
            totalExp += perExp * num;
            int bagIdx = bagItems.FindIndex(i => i.TemplateId == itemId);
            if (bagIdx >= 0)
            {
                int newNum = bagItems[bagIdx].Num - num;
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

        return GameServices.EncodeHeroAddExpRet(heroId, items);
    }

    internal async Task<byte[]> BuildGetHerosTacticAsync(string profileId, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerFleet fleet = account.Fleet ?? PlayerAccountFactory.DefaultFleet();
        return GameServices.EncodeFleet(fleet);
    }

    internal async Task<byte[]> BuildSetHerosTacticAsync(TRequest request, string profileId, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        List<FleetEntry> entries = GameServices.DecodeSetHerosTactic(request.Args ?? []);
        PlayerFleet newFleet = new(entries);
        PlayerAccount updated = account with { Fleet = newFleet };
        await services.SaveAccountAsync(updated, ct);
        return GameServices.EncodeFleet(newFleet);
    }

    internal async Task<byte[]> BuildLockHeroRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        (uint heroId, bool isLock) = GameServices.DecodeLockHeroArg(request.Args);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];
        heroList[heroIdx] = heroList[heroIdx] with { Lock = isLock };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);
        return [];
    }

    internal async Task<byte[]> BuildRetireHeroRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        List<uint> heroIds = GameServices.DecodeRetireHeroArg(request.Args);
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
        (uint heroId, string name) = GameServices.DecodeChangeHeroNameArg(request.Args);
        if (heroId == 0 || string.IsNullOrEmpty(name)) return [];
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];
        heroList[heroIdx] = heroList[heroIdx] with { Name = name };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ct);
        return [];
    }

    internal async Task<byte[]> BuildAddAffectionRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        (uint heroId, _, int num) = GameServices.DecodeHeroAddAffectionArg(request.Args);
        if (heroId == 0 || num <= 0) return [];
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];
        Hero hero = heroList[heroIdx];
        heroList[heroIdx] = hero with { Affection = hero.Affection + num * 10000 };
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
}
