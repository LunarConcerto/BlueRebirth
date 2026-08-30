using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>离线任务状态、刷新和奖励发放。</summary>
internal sealed class TaskService(GameServices services)
{
    private const int ChinaUtcOffsetSeconds = 8 * 60 * 60;

    internal async Task<PlayerAccount> GetSnapshotAccountAsync(
        string profileId, int now, CancellationToken ct)
    {
        using IDisposable accountLock = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        (PlayerAccount normalized, bool changed) = Normalize(account, now);
        if (changed) await services.SaveAccountAsync(normalized, ct);
        return normalized;
    }

    internal async Task<TaskRewardMutation> ClaimAsync(
        string profileId, int taskType, int taskId, int now, CancellationToken ct,
        bool allowConfiguredTask = false)
    {
        using IDisposable accountLock = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        (account, _) = Normalize(account, now);
        TaskDefinition? definition = TaskConfigCatalog.Get(taskType, taskId);
        if (definition is null || (!allowConfiguredTask && !IsClaimable(account, definition)))
            return TaskRewardMutation.Fail(account, "Task is not available");

        List<PlayerTaskRecord> records = (account.Tasks?.Records ?? []).ToList();
        if (records.Any(x => x.TaskType == taskType && x.TaskId == taskId && x.RewardTime > 0))
            return TaskRewardMutation.Fail(account, "Task reward was already claimed");

        List<CommonReward> granted = [];
        foreach (CommonReward configured in TaskConfigCatalog.GetRewards(definition))
            account = Grant(account, configured, now, granted);
        if (definition.MedalId > 0)
            granted.Add(new CommonReward(16, definition.MedalId, 1));

        records.RemoveAll(x => x.TaskType == taskType && x.TaskId == taskId);
        records.Add(new PlayerTaskRecord(taskType, taskId, now, now, definition.Goal));
        PlayerTaskProgress state = account.Tasks ?? new PlayerTaskProgress();
        account = account with { Tasks = state with { Records = records } };
        await services.SaveAccountAsync(account, ct);
        return new TaskRewardMutation(account, granted, "");
    }

    internal async Task<TaskRewardMutation> ClaimAllAsync(
        string profileId, int getType, int now, CancellationToken ct)
    {
        using IDisposable accountLock = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        (account, _) = Normalize(account, now);
        int[] allowedTypes = getType == 2
            ? [TaskConfigCatalog.TypeAchieve]
            : [TaskConfigCatalog.TypeMain, TaskConfigCatalog.TypeDaily,
                TaskConfigCatalog.TypeWeekly, TaskConfigCatalog.TypeGrow];
        HashSet<(int Type, int Id)> claimed = (account.Tasks?.Records ?? [])
            .Where(x => x.RewardTime > 0)
            .Select(x => (x.TaskType, x.TaskId))
            .ToHashSet();
        List<TaskDefinition> definitions = TaskConfigCatalog.GetSnapshotDefinitions(account)
            .Where(x => allowedTypes.Contains(x.TaskType) && !claimed.Contains((x.TaskType, x.Id)))
            .ToList();

        List<PlayerTaskRecord> records = (account.Tasks?.Records ?? []).ToList();
        List<CommonReward> granted = [];
        foreach (TaskDefinition definition in definitions)
        {
            foreach (CommonReward configured in TaskConfigCatalog.GetRewards(definition))
                account = Grant(account, configured, now, granted);
            if (definition.MedalId > 0)
                granted.Add(new CommonReward(16, definition.MedalId, 1));
            records.RemoveAll(x => x.TaskType == definition.TaskType && x.TaskId == definition.Id);
            records.Add(new PlayerTaskRecord(
                definition.TaskType, definition.Id, now, now, definition.Goal));
        }

        PlayerTaskProgress state = account.Tasks ?? new PlayerTaskProgress();
        account = account with { Tasks = state with { Records = records } };
        await services.SaveAccountAsync(account, ct);
        return new TaskRewardMutation(account, granted, "");
    }

    internal async Task<TaskRewardMutation> ClaimTeachingPointAsync(
        string profileId, int id, int now, CancellationToken ct)
    {
        using IDisposable accountLock = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        (account, _) = Normalize(account, now);
        ConfigTeachingAchievement? definition = TaskConfigCatalog.GetTeachingAchievement(id);
        if (definition is null)
            return TaskRewardMutation.Fail(account, "Teaching reward does not exist");
        List<int> claimed = (account.Tasks?.TeachingPtRewardIds ?? []).Distinct().ToList();
        if (claimed.Contains(id))
            return TaskRewardMutation.Fail(account, "Teaching reward was already claimed");

        TaskDefinition rewardDefinition = new(
            TaskConfigCatalog.TypeTeachingStage, id, 0, 1, 1, checked((int)definition.Rewards));
        List<CommonReward> granted = [];
        foreach (CommonReward configured in TaskConfigCatalog.GetRewards(rewardDefinition))
            account = Grant(account, configured, now, granted);
        claimed.Add(id);
        PlayerTaskProgress state = account.Tasks ?? new PlayerTaskProgress();
        account = account with { Tasks = state with { TeachingPtRewardIds = claimed } };
        await services.SaveAccountAsync(account, ct);
        return new TaskRewardMutation(account, granted, "");
    }

    internal async Task<IReadOnlyList<byte[]>> BuildRefreshPushesAsync(
        PlayerAccount account, uint now, CancellationToken ct)
    {
        List<HeroGrid> heroes = account.Dock.Heroes.Select(GameServices.ToHeroGrid).ToList();
        return
        [
            BuildTaskInfoPush(account, now),
            await services.BuildUpdateUserInfoPushAsync(account.ProfileId, now, ct),
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "hero.UpdateHeroBagData",
                Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                Time: now)),
            services.BuildBagPush(account, now),
            services.BuildFashionPush(account, now),
            services.BuildEquipPush(account, now),
        ];
    }

    internal static byte[] BuildTaskInfoPush(PlayerAccount account, uint now) =>
        TMessageCodec.EncodeResponse(new TResponse(
            Method: "task.TaskInfo",
            Ret: TaskProtocolCodec.EncodeTaskInfo(account, checked((int)now)),
            Time: now));

    internal static (PlayerAccount Account, bool Changed) Normalize(PlayerAccount account, int now)
    {
        int day = checked((now + ChinaUtcOffsetSeconds) / 86_400);
        // Unix epoch was Thursday; adding three makes integer week buckets start on Monday.
        int week = checked((day + 3) / 7);
        PlayerTaskProgress current = account.Tasks ?? new PlayerTaskProgress();
        List<PlayerTaskRecord> records = (current.Records ?? []).ToList();
        bool changed = account.Tasks is null || current.Records is null ||
                       current.TeachingPtRewardIds is null;
        if (current.DailyResetDay != 0 && current.DailyResetDay != day)
        {
            changed |= records.RemoveAll(x => x.TaskType is TaskConfigCatalog.TypeDaily or
                TaskConfigCatalog.TypeTeachingDaily) > 0;
        }
        if (current.WeeklyResetWeek != 0 && current.WeeklyResetWeek != week)
            changed |= records.RemoveAll(x => x.TaskType == TaskConfigCatalog.TypeWeekly) > 0;
        if (current.DailyResetDay != day || current.WeeklyResetWeek != week) changed = true;
        if (!changed) return (account, false);
        return (account with
        {
            Tasks = current with
            {
                Records = records,
                DailyResetDay = day,
                WeeklyResetWeek = week,
                TeachingPtRewardIds = current.TeachingPtRewardIds ?? [],
            },
        }, true);
    }

    private static bool IsClaimable(PlayerAccount account, TaskDefinition definition)
    {
        if (definition.TaskType is TaskConfigCatalog.TypeActivity or TaskConfigCatalog.TypeReturn or
            TaskConfigCatalog.TypeTreaty)
            return true;
        return TaskConfigCatalog.GetSnapshotDefinitions(account)
            .Any(x => x.TaskType == definition.TaskType && x.Id == definition.Id);
    }

    private PlayerAccount Grant(
        PlayerAccount account, CommonReward configured, int now, List<CommonReward> granted)
    {
        if (configured.Num <= 0) return account;
        if (configured.Type == GameServices.GoodsTypeShip)
        {
            for (int i = 0; i < configured.Num; i++)
            {
                uint heroId = services.NextHeroId();
                account = services.AddShip(account, heroId, configured.ConfigId, now);
                granted.Add(configured with { Num = 1, Id = checked((int)heroId) });
            }
            return account;
        }
        if (configured.Type == GameServices.GoodsTypeEquip)
        {
            PlayerEquip equip = account.Equip ?? new PlayerEquip([], 2000);
            List<EquipItem> items = equip.Items.ToList();
            for (int i = 0; i < configured.Num; i++)
            {
                uint equipId = services.NextEquipId();
                items.Add(new EquipItem(equipId, configured.ConfigId));
                granted.Add(configured with { Num = 1, Id = checked((int)equipId) });
            }
            return account with { Equip = equip with { Items = items } };
        }
        if (configured.Type == GameServices.GoodsTypeCurrency)
        {
            granted.Add(configured);
            return GameServices.AddCurrency(account, configured.ConfigId, configured.Num);
        }
        if (configured.Type == GameServices.GoodsTypeFashion)
        {
            PlayerFashion fashion = account.Fashion ?? new PlayerFashion([]);
            List<FashionEntry> entries = fashion.Entries.ToList();
            int sfId = services.FashionSfIdMap.GetValueOrDefault(configured.ConfigId, configured.ConfigId);
            int index = entries.FindIndex(x => x.SfId == sfId);
            if (index >= 0)
            {
                List<int> tids = entries[index].FashionTids.ToList();
                if (!tids.Contains(configured.ConfigId)) tids.Add(configured.ConfigId);
                entries[index] = entries[index] with { FashionTids = tids };
            }
            else
            {
                entries.Add(new FashionEntry(sfId, [configured.ConfigId]));
            }
            granted.Add(configured);
            return account with { Fashion = fashion with { Entries = entries } };
        }
        if (configured.Type == 16) // GoodsType.MEDAL：由 TaskInfo.MedalList 持久展示。
        {
            granted.Add(configured);
            return account;
        }
        granted.Add(configured);
        return GameServices.AddBagItem(account, configured.ConfigId, configured.Num);
    }
}

internal sealed record TaskRewardMutation(
    PlayerAccount Account,
    IReadOnlyList<CommonReward> Rewards,
    string Error)
{
    internal bool Success => string.IsNullOrEmpty(Error);
    internal static TaskRewardMutation Fail(PlayerAccount account, string error) => new(account, [], error);
}
