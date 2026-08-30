using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>客户端任务配置的只读索引。</summary>
internal static class TaskConfigCatalog
{
    internal const int TypeMain = 1;
    internal const int TypeDaily = 2;
    internal const int TypeWeekly = 3;
    internal const int TypeGrow = 4;
    internal const int TypeAchieve = 5;
    internal const int TypeActivity = 6;
    internal const int TypeTeachingDaily = 8;
    internal const int TypeTeachingStage = 9;
    internal const int TypeTreaty = 10;
    internal const int TypeReturn = 12;

    private static Dictionary<(int Type, int Id), TaskDefinition> _definitions = [];
    private static Dictionary<int, ConfigRewards> _rewards = [];
    private static Dictionary<int, ConfigTeachingAchievement> _teachingAchievements = [];
    private static bool _loaded;

    internal static void Load(string configDir)
    {
        if (_loaded) return;

        Dictionary<(int Type, int Id), TaskDefinition> definitions = [];
        AddNormal(definitions, TypeMain,
            ConfigDbLoader.LoadAll<ConfigTaskMain>(configDir, "config_task_main.db")
                .Values.Select(x => (x.Id, x.Goal, x.CountType, x.Rewards, x.NextTaskId,
                    x.PlayerLevelMin, x.PlayerLevelMax, 0L)));
        AddNormal(definitions, TypeDaily,
            ConfigDbLoader.LoadAll<ConfigTaskDaily>(configDir, "config_task_daily.db")
                .Values.Select(x => (x.Id, x.Goal, x.CountType, x.Rewards, x.NextTaskId,
                    x.PlayerLevelMin, x.PlayerLevelMax, 0L)));
        AddNormal(definitions, TypeWeekly,
            ConfigDbLoader.LoadAll<ConfigTaskWeekly>(configDir, "config_task_weekly.db")
                .Values.Select(x => (x.Id, x.Goal, x.CountType, x.Rewards, x.NextTaskId,
                    x.PlayerLevelMin, x.PlayerLevelMax, 0L)));
        AddNormal(definitions, TypeGrow,
            ConfigDbLoader.LoadAll<ConfigTaskGrow>(configDir, "config_task_grow.db")
                .Values.Select(x => (x.Id, x.Goal, x.CountType, x.Rewards, x.NextTaskId,
                    x.PlayerLevelMin, x.PlayerLevelMax, x.Abandoned)));
        AddNormal(definitions, TypeReturn,
            ConfigDbLoader.LoadAll<ConfigTaskReturn>(configDir, "config_task_return.db")
                .Values.Select(x => (x.Id, x.Goal, x.CountType, x.Rewards, x.NextTaskId,
                    x.PlayerLevelMin, x.PlayerLevelMax, 0L)));

        foreach (ConfigAchievement x in ConfigDbLoader
                     .LoadAll<ConfigAchievement>(configDir, "config_achievement.db").Values)
        {
            if (!TryCreate(TypeAchieve, x.Id, x.Goal, x.CountType, x.Rewards,
                    0, 0, x.Abandoned, out TaskDefinition definition))
                continue;
            definitions[(TypeAchieve, definition.Id)] = definition with
            {
                PreviousTaskId = checked((int)x.LastAchievement),
                Point = checked((int)x.Point),
                MedalId = checked((int)x.MedalId),
            };
        }

        Dictionary<int, ConfigTaskTeaching> teaching = ConfigDbLoader
            .LoadAll<ConfigTaskTeaching>(configDir, "config_task_teaching.db");
        foreach (ConfigTaskTeachingGroup group in ConfigDbLoader
                     .LoadAll<ConfigTaskTeachingGroup>(configDir, "config_task_teaching_group.db").Values)
        {
            AddTeaching(definitions, teaching, group.TaskDailyId, TypeTeachingDaily);
            AddTeaching(definitions, teaching, group.TaskAssessId, TypeTeachingStage);
        }

        foreach (ConfigTaskActivity x in ConfigDbLoader
                     .LoadAll<ConfigTaskActivity>(configDir, "config_task_activity.db").Values)
            if (TryCreate(TypeActivity, x.Id, x.Goal, x.CountType, x.Rewards,
                    0, 0, 0, out TaskDefinition definition))
                definitions[(TypeActivity, definition.Id)] = definition with
                {
                    PreviousTaskId = checked((int)x.LastTaskClient),
                };

        foreach (ConfigTaskTreaty x in ConfigDbLoader
                     .LoadAll<ConfigTaskTreaty>(configDir, "config_task_treaty.db").Values)
            if (TryCreate(TypeTreaty, x.Id, x.Goal, 1, x.Rewards,
                    0, 0, 0, out TaskDefinition definition))
                definitions[(TypeTreaty, definition.Id)] = definition;

        // 普通任务表只记录 next_task_id，这里反向补出前置任务。
        foreach (IGrouping<int, TaskDefinition> group in definitions.Values
                     .Where(x => x.NextTaskId > 0)
                     .GroupBy(x => x.TaskType))
        {
            Dictionary<int, int> previous = group
                .GroupBy(x => x.NextTaskId)
                .ToDictionary(x => x.Key, x => x.First().Id);
            foreach (TaskDefinition definition in definitions.Values
                         .Where(x => x.TaskType == group.Key && previous.ContainsKey(x.Id)).ToList())
                definitions[(definition.TaskType, definition.Id)] = definition with
                {
                    PreviousTaskId = previous[definition.Id],
                };
        }

        _definitions = definitions;
        _rewards = ConfigDbLoader.LoadAll<ConfigRewards>(configDir, "config_rewards.db");
        _teachingAchievements = ConfigDbLoader
            .LoadAll<ConfigTeachingAchievement>(configDir, "config_teaching_achievement.db");
        _loaded = true;
    }

    internal static TaskDefinition? Get(int taskType, int taskId) =>
        _definitions.GetValueOrDefault((taskType, taskId));

    internal static IReadOnlyList<TaskDefinition> GetSnapshotDefinitions(PlayerAccount account)
    {
        HashSet<(int Type, int Id)> claimed = (account.Tasks?.Records ?? [])
            .Where(x => x.RewardTime > 0)
            .Select(x => (x.TaskType, x.TaskId))
            .ToHashSet();
        int level = account.Character.Level;
        return _definitions.Values
            .Where(x => x.TaskType is TypeMain or TypeDaily or TypeWeekly or TypeGrow or
                TypeAchieve or TypeTeachingDaily or TypeTeachingStage)
            .Where(x => x.Abandoned == 0)
            .Where(x => (x.PlayerLevelMin <= 0 || level >= x.PlayerLevelMin) &&
                        (x.PlayerLevelMax <= 0 || level <= x.PlayerLevelMax))
            .Where(x => x.TaskType is TypeDaily or TypeWeekly or TypeTeachingDaily or TypeTeachingStage ||
                        x.PreviousTaskId <= 0 || claimed.Contains((x.TaskType, x.PreviousTaskId)) ||
                        claimed.Contains((x.TaskType, x.Id)))
            .OrderBy(x => x.TaskType)
            .ThenBy(x => x.Id)
            .ToList();
    }

    internal static IReadOnlyList<CommonReward> GetRewards(TaskDefinition definition)
    {
        if (definition.RewardId <= 0 || !_rewards.TryGetValue(definition.RewardId, out ConfigRewards? reward) ||
            reward.Rewards is null)
            return [];
        return reward.Rewards
            .Where(x => x.Count >= 3 && x[0] > 0 && x[1] > 0 && x[2] > 0)
            .Select(x => new CommonReward(checked((int)x[0]), checked((int)x[1]), checked((int)x[2])))
            .ToList();
    }

    internal static ConfigTeachingAchievement? GetTeachingAchievement(int id) =>
        _teachingAchievements.GetValueOrDefault(id);

    internal static int GetAchievePoint(PlayerAccount account)
    {
        HashSet<int> claimed = (account.Tasks?.Records ?? [])
            .Where(x => x.TaskType == TypeAchieve && x.RewardTime > 0)
            .Select(x => x.TaskId)
            .ToHashSet();
        return _definitions.Values
            .Where(x => x.TaskType == TypeAchieve && claimed.Contains(x.Id))
            .Sum(x => x.Point);
    }

    private static void AddNormal(
        Dictionary<(int Type, int Id), TaskDefinition> target,
        int taskType,
        IEnumerable<(long Id, List<long>? Goal, long CountType, long Rewards, long NextTaskId,
            long PlayerLevelMin, long PlayerLevelMax, long Abandoned)> source)
    {
        foreach (var x in source)
            if (TryCreate(taskType, x.Id, x.Goal, x.CountType, x.Rewards,
                    x.PlayerLevelMin, x.PlayerLevelMax, x.Abandoned, out TaskDefinition definition))
                target[(taskType, definition.Id)] = definition with
                {
                    NextTaskId = checked((int)x.NextTaskId),
                };
    }

    private static void AddTeaching(
        Dictionary<(int Type, int Id), TaskDefinition> target,
        IReadOnlyDictionary<int, ConfigTaskTeaching> teaching,
        IReadOnlyList<long>? ids,
        int taskType)
    {
        foreach (long rawId in ids ?? [])
        {
            int id = checked((int)rawId);
            if (!teaching.TryGetValue(id, out ConfigTaskTeaching? x) ||
                !TryCreate(taskType, x.Id, x.Goal, x.CountType, x.Rewards,
                    0, 0, 0, out TaskDefinition definition))
                continue;
            target[(taskType, definition.Id)] = definition;
        }
    }

    private static bool TryCreate(
        int taskType,
        long rawId,
        IReadOnlyList<long>? goal,
        long countType,
        long rewardId,
        long playerLevelMin,
        long playerLevelMax,
        long abandoned,
        out TaskDefinition definition)
    {
        definition = null!;
        if (rawId <= 0 || goal is not { Count: > 0 }) return false;
        definition = new TaskDefinition(
            taskType,
            checked((int)rawId),
            checked((int)goal[0]),
            checked((int)Math.Max(1, goal[^1])),
            checked((int)countType),
            checked((int)rewardId),
            checked((int)playerLevelMin),
            checked((int)playerLevelMax),
            checked((int)abandoned));
        return true;
    }
}

internal sealed record TaskDefinition(
    int TaskType,
    int Id,
    int EventType,
    int Goal,
    int CountType,
    int RewardId,
    int PlayerLevelMin = 0,
    int PlayerLevelMax = 0,
    int Abandoned = 0,
    int NextTaskId = 0,
    int PreviousTaskId = 0,
    int Point = 0,
    int MedalId = 0);
