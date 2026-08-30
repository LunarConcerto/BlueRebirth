using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>每日副本状态、跨日刷新与通关进度服务。</summary>
internal sealed class DailyCopyService(GameServices services)
{
    private const int ChinaUtcOffsetSeconds = 8 * 60 * 60;

    internal async Task<PlayerAccount> GetRefreshedAccountAsync(
        string profileId, int now, CancellationToken ct)
    {
        using IDisposable accountLock = await services.LockAccountAsync(profileId, ct);
        return await GetRefreshedAccountLockedAsync(profileId, now, ct);
    }

    private async Task<PlayerAccount> GetRefreshedAccountLockedAsync(
        string profileId, int now, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        (account, bool changed) = Normalize(account, now);
        if (changed) await services.SaveAccountAsync(account, ct);
        return account;
    }

    internal async Task<PlayerAccount> SetSelectExAsync(
        string profileId, int chapterId, bool selectEx, int now, CancellationToken ct)
    {
        using IDisposable accountLock = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await GetRefreshedAccountLockedAsync(profileId, now, ct);
        PlayerDailyCopyProgress state = account.DailyCopy!;
        List<DailyCopyChapterProgress> chapters = state.Chapters!.ToList();
        int index = chapters.FindIndex(x => x.ChapterId == chapterId);
        if (index >= 0 && chapters[index].SelectEx != selectEx)
        {
            chapters[index] = chapters[index] with { SelectEx = selectEx };
            account = account with { DailyCopy = state with { Chapters = chapters } };
            await services.SaveAccountAsync(account, ct);
        }
        return account;
    }

    internal DailyCopyPassMutation RecordPass(
        PlayerAccount account, int copyId, int grade, int now)
    {
        (account, _) = Normalize(account, now);
        int chapterId = ChapterCopyLoader.GetDailyChapterId(copyId);
        if (chapterId == 0 || grade <= 0) return new(account, false, []);

        PlayerDailyCopyProgress state = account.DailyCopy!;
        List<DailyCopyChapterProgress> chapters = state.Chapters!.ToList();
        int chapterIndex = chapters.FindIndex(x => x.ChapterId == chapterId);
        if (chapterIndex < 0) return new(account, false, []);

        DailyCopyChapterProgress chapter = chapters[chapterIndex];
        bool isTreaty = ChapterCopyLoader.IsDailyTreatyCopy(copyId);
        List<int> passed = (chapter.PassCopy ?? []).Distinct().ToList();
        bool firstPass = !passed.Contains(copyId);
        if (firstPass) passed.Add(copyId);
        int exStar = isTreaty ? Math.Clamp(grade, 0, 6) : chapter.ExStar;
        DailyCopyChapterProgress updatedChapter = chapter with
        {
            ChallengeTimes = checked(chapter.ChallengeTimes + 1),
            PassCopy = passed,
            SelectEx = isTreaty || chapter.SelectEx,
            ExStar = isTreaty ? Math.Max(chapter.ExStar, exStar) : chapter.ExStar,
        };
        chapters[chapterIndex] = updatedChapter;

        int groupId = ChapterCopyLoader.GetDailyGroupId(chapterId);
        List<DailyCopyGroupProgress> groups = state.Groups!.ToList();
        int groupIndex = groups.FindIndex(x => x.DailyGroupId == groupId);
        if (groupIndex >= 0)
            groups[groupIndex] = groups[groupIndex] with
            {
                SuccessTimes = checked(groups[groupIndex].SuccessTimes + 1),
            };

        account = account with
        {
            DailyCopy = state with { Chapters = chapters, Groups = groups },
        };
        List<CommonReward> rewards = ResolveRewards(
            ref account, chapterId, copyId, firstPass, isTreaty, exStar);
        return new(account, firstPass, rewards);
    }

    private List<CommonReward> ResolveRewards(
        ref PlayerAccount account, int chapterId, int copyId, bool firstPass,
        bool isTreaty, int exStar)
    {
        int groupId = ChapterCopyLoader.GetDailyGroupId(chapterId);
        ConfigDailyGroup? group = DailyCopyRewardCatalog.GetGroup(groupId);
        if (group is null) return [];

        List<(int Type, int ConfigId, int Num)> pending = [];
        if (isTreaty)
        {
            if (firstPass) AppendReward(group.TreatyPassDrop, pending);
            if (group.TreatyBasicDropBase > 0)
                DrawDropPool(checked((int)group.TreatyBasicDropBase), pending, [], 0);
            if (group.TreatyBasicDropStar is { Count: > 0 } starDrops)
            {
                int starIndex = Math.Clamp(exStar, 0, starDrops.Count - 1);
                DrawDropPool(checked((int)starDrops[starIndex]), pending, [], 0);
            }
        }
        else
        {
            List<int> levels = ChapterCopyLoader.GetDailyCopyIds(chapterId);
            int levelIndex = levels.IndexOf(copyId);
            if (levelIndex < 0) return [];

            if (firstPass && group.FirstDrop is { } firstDrops && levelIndex < firstDrops.Count)
                AppendReward(firstDrops[levelIndex], pending);

            if (group.BasicDrop is { } basicDrops && levelIndex < basicDrops.Count)
                foreach (long dropId in basicDrops[levelIndex])
                    DrawDropPool(checked((int)dropId), pending, [], 0);
        }

        List<CommonReward> result = [];
        foreach ((int type, int configId, int num) in pending)
        {
            if (type == GameServices.GoodsTypeCurrency)
            {
                account = GameServices.AddCurrency(account, configId, num);
                result.Add(new CommonReward(type, configId, num));
            }
            else if (type == GameServices.GoodsTypeEquip)
            {
                for (int i = 0; i < num; i++)
                {
                    uint equipId = services.NextEquipId();
                    PlayerEquip equip = account.Equip ?? new PlayerEquip([], 2000);
                    List<EquipItem> items = equip.Items.ToList();
                    items.Add(new EquipItem(equipId, configId));
                    account = account with { Equip = equip with { Items = items } };
                    result.Add(new CommonReward(type, configId, 1, checked((int)equipId)));
                }
            }
            else
            {
                account = GameServices.AddBagItem(account, configId, num);
                result.Add(new CommonReward(type, configId, num));
            }
        }
        return result;
    }

    private static void AppendReward(
        long rewardId, List<(int Type, int ConfigId, int Num)> pending)
    {
        if (rewardId <= 0 ||
            DailyCopyRewardCatalog.GetReward(checked((int)rewardId)) is not { Rewards: { } rewards })
            return;
        foreach (List<long> entry in rewards)
            if (entry.Count >= 3 && entry[2] > 0)
                pending.Add((checked((int)entry[0]), checked((int)entry[1]), checked((int)entry[2])));
    }

    private bool DrawDropPool(
        int dropId, List<(int Type, int ConfigId, int Num)> result, HashSet<int> path, int depth)
    {
        if (depth >= 16 || !path.Add(dropId) || !services.DropItems.TryGetValue(dropId, out var pool))
            return false;
        try
        {
            if (pool.DropRate > 0 && pool.Drop is { Count: > 0 })
                for (int i = 0; i < Math.Max(1, checked((int)pool.DropCount)); i++)
                    if (WeightedPick(pool.Drop) is { } entry)
                        ResolveDropEntry(entry, result, path, depth + 1);
            if (pool.DropAloneCount > 0 && pool.DropAlone is { Count: > 0 })
                for (int i = 0; i < pool.DropAloneCount; i++)
                    if (WeightedPick(pool.DropAlone) is { } entry)
                        ResolveDropEntry(entry, result, path, depth + 1);
            return true;
        }
        finally
        {
            path.Remove(dropId);
        }
    }

    private void ResolveDropEntry(
        List<long> entry, List<(int Type, int ConfigId, int Num)> result, HashSet<int> path, int depth)
    {
        if (entry.Count < 5) return;
        int type = checked((int)entry[0]);
        int configId = checked((int)entry[1]);
        int min = checked((int)entry[2]);
        int max = checked((int)entry[3]);
        if (min <= 0 || max < min) return;
        int num = min == max ? min : services.Rng.Next(min, checked(max + 1));
        if (type == GameServices.GoodsTypeDrop)
        {
            for (int i = 0; i < num; i++) DrawDropPool(configId, result, path, depth);
            return;
        }
        result.Add((type, configId, num));
    }

    private List<long>? WeightedPick(List<List<long>> entries)
    {
        List<List<long>> candidates = entries.Where(x => x.Count >= 5 && x[4] > 0).ToList();
        long total = candidates.Sum(x => x[4]);
        if (total <= 0) return null;
        long roll = services.Rng.NextInt64(total);
        long cumulative = 0;
        foreach (List<long> entry in candidates)
        {
            cumulative += entry[4];
            if (roll < cumulative) return entry;
        }
        return candidates[^1];
    }

    internal static byte[] EncodeSnapshot(PlayerDailyCopyProgress? rawState, int now)
    {
        PlayerAccount shell = PlayerAccountFactory.CreateDefault("dailycopy-codec", now) with
        {
            DailyCopy = rawState,
        };
        (shell, _) = Normalize(shell, now);
        PlayerDailyCopyProgress state = shell.DailyCopy!;
        return PlayerDataCodec.Encode(new UserDailyCopyInfo(
            ArrDailyCopyInfo: state.Chapters!.Select(x => new DailyCopyInfo(
                x.ChapterId, x.ChallengeTimes, x.PassCopy ?? [], x.SelectEx, x.ExStar)).ToList(),
            ArrDailyGroupInfo: state.Groups!.Select(x =>
                new DailyCopyGroupInfo(x.DailyGroupId, x.SuccessTimes)).ToList(),
            ArrDailyUpGroupInfo: state.ExtraGroups!.Select(x =>
                new DailyCopyGroupInfo(x.DailyGroupId, x.SuccessTimes)).ToList()));
    }

    internal static byte[] BuildUpdatePush(PlayerDailyCopyProgress? state, uint now)
        => TMessageCodec.EncodeResponse(new TResponse(
            Method: "dailycopy.UpdateDailyCopyData",
            Ret: EncodeSnapshot(state, checked((int)now)),
            Time: now));

    private static (PlayerAccount Account, bool Changed) Normalize(PlayerAccount account, int now)
    {
        int resetDay = GetResetDay(now);
        PlayerDailyCopyProgress? old = account.DailyCopy;
        bool reset = old is null || old.ResetDay != resetDay;
        Dictionary<int, DailyCopyChapterProgress> chapterMap = (old?.Chapters ?? [])
            .GroupBy(x => x.ChapterId)
            .ToDictionary(x => x.Key, x => x.Last());
        Dictionary<int, DailyCopyGroupProgress> groupMap = (old?.Groups ?? [])
            .GroupBy(x => x.DailyGroupId)
            .ToDictionary(x => x.Key, x => x.Last());
        Dictionary<int, DailyCopyGroupProgress> extraMap = (old?.ExtraGroups ?? [])
            .GroupBy(x => x.DailyGroupId)
            .ToDictionary(x => x.Key, x => x.Last());

        List<DailyCopyChapterProgress> chapters = ChapterCopyLoader.GetDailyChapterIds()
            .Select(chapterId => chapterMap.TryGetValue(chapterId, out var existing)
                ? existing with
                {
                    ChallengeTimes = reset ? 0 : Math.Max(0, existing.ChallengeTimes),
                    PassCopy = (existing.PassCopy ?? []).Distinct().ToList(),
                }
                : new DailyCopyChapterProgress(chapterId, PassCopy: []))
            .ToList();
        List<DailyCopyGroupProgress> groups = ChapterCopyLoader.GetDailyGroupIds()
            .Select(groupId => new DailyCopyGroupProgress(groupId,
                reset ? 0 : Math.Max(0, groupMap.GetValueOrDefault(groupId)?.SuccessTimes ?? 0)))
            .ToList();
        List<DailyCopyGroupProgress> extras = ChapterCopyLoader.GetDailyGroupIds()
            .Select(groupId => new DailyCopyGroupProgress(groupId,
                Math.Max(0, extraMap.GetValueOrDefault(groupId)?.SuccessTimes ?? 0)))
            .ToList();

        PlayerDailyCopyProgress normalized = new(chapters, groups, extras, resetDay);
        bool changed = old is null || reset || old.Chapters?.Count != chapters.Count ||
                       old.Groups?.Count != groups.Count || old.ExtraGroups?.Count != extras.Count;
        return (account with { DailyCopy = normalized }, changed);
    }

    private static int GetResetDay(int now)
        => checked((now + ChinaUtcOffsetSeconds) / 86_400);
}

internal sealed record DailyCopyPassMutation(
    PlayerAccount Account,
    bool FirstPass,
    IReadOnlyList<CommonReward> Rewards);
