using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>task_pb.lua 对应的最小完整编解码器。</summary>
internal static class TaskProtocolCodec
{
    private static readonly IReadOnlyDictionary<int, byte> SnapshotTags = new Dictionary<int, byte>
    {
        [TaskConfigCatalog.TypeMain] = 0x0A,
        [TaskConfigCatalog.TypeDaily] = 0x12,
        [TaskConfigCatalog.TypeWeekly] = 0x1A,
        [TaskConfigCatalog.TypeAchieve] = 0x22,
        [TaskConfigCatalog.TypeActivity] = 0x32,
        [TaskConfigCatalog.TypeGrow] = 0x3A,
        [TaskConfigCatalog.TypeTeachingDaily] = 0x4A,
        [TaskConfigCatalog.TypeTeachingStage] = 0x52,
        [TaskConfigCatalog.TypeTreaty] = 0x82,
        [TaskConfigCatalog.TypeReturn] = 0x8A,
    };

    internal static byte[] EncodeTaskInfo(PlayerAccount account, int now)
    {
        ProtocolPackage output = new();
        IReadOnlyList<PlayerTaskRecord> records = account.Tasks?.Records ?? [];
        Dictionary<(int Type, int Id), PlayerTaskRecord> recordMap = records
            .GroupBy(x => (x.TaskType, x.TaskId))
            .ToDictionary(x => x.Key, x => x.OrderByDescending(y => y.RewardTime).First());

        foreach (IGrouping<int, TaskDefinition> typeGroup in TaskConfigCatalog
                     .GetSnapshotDefinitions(account).GroupBy(x => x.TaskType))
        {
            if (!SnapshotTags.TryGetValue(typeGroup.Key, out byte tag)) continue;
            foreach (IGrouping<int, TaskDefinition> eventGroup in typeGroup.GroupBy(x => x.EventType))
            {
                ProtocolPackage eventInfo = new();
                eventInfo.Write(0x08, unchecked((ulong)eventGroup.Key));
                eventInfo.Write(0x10, unchecked((ulong)GetEventProgress(eventGroup, recordMap)));
                foreach (TaskDefinition definition in eventGroup)
                {
                    recordMap.TryGetValue((definition.TaskType, definition.Id), out PlayerTaskRecord? record);
                    eventInfo.Write(0x1A, EncodeTask(definition, record));
                }
                output.Write(tag, eventInfo.ToArray());
            }
        }

        foreach (int medalId in TaskConfigCatalog.GetSnapshotDefinitions(account)
                     .Where(x => x.TaskType == TaskConfigCatalog.TypeAchieve && x.MedalId > 0 &&
                                 recordMap.TryGetValue((x.TaskType, x.Id), out PlayerTaskRecord? record) &&
                                 record.RewardTime > 0)
                     .Select(x => x.MedalId).Distinct())
            output.Write(0x28, unchecked((ulong)medalId));

        foreach (int id in account.Tasks?.TeachingPtRewardIds ?? [])
            output.Write(0x58, unchecked((ulong)id));

        // TaskStageInfo：TaskType=TeachingStage, StageId=1。三个标量必须显式编码，
        // 客户端教学页会直接读取 StageId/GotStageId。
        ProtocolPackage stage = new();
        stage.Write(0x08, unchecked((ulong)TaskConfigCatalog.TypeTeachingStage));
        stage.Write(0x10, 1UL);
        output.Write(0x62, stage.ToArray());
        output.Write(0x68, 0UL); // TeachingDailyTaskCount
        return output.ToArray();
    }

    internal static byte[] EncodeTeachingInfo(PlayerAccount account, int now)
    {
        ProtocolPackage output = new();
        IReadOnlyList<PlayerTaskRecord> records = account.Tasks?.Records ?? [];
        Dictionary<(int Type, int Id), PlayerTaskRecord> recordMap = records
            .GroupBy(x => (x.TaskType, x.TaskId))
            .ToDictionary(x => x.Key, x => x.OrderByDescending(y => y.RewardTime).First());
        foreach (IGrouping<int, TaskDefinition> typeGroup in TaskConfigCatalog.GetSnapshotDefinitions(account)
                     .Where(x => x.TaskType is TaskConfigCatalog.TypeTeachingDaily or
                         TaskConfigCatalog.TypeTeachingStage)
                     .GroupBy(x => x.TaskType))
        {
            byte tag = typeGroup.Key == TaskConfigCatalog.TypeTeachingDaily ? (byte)0x0A : (byte)0x12;
            foreach (IGrouping<int, TaskDefinition> eventGroup in typeGroup.GroupBy(x => x.EventType))
            {
                ProtocolPackage eventInfo = new();
                eventInfo.Write(0x08, unchecked((ulong)eventGroup.Key));
                eventInfo.Write(0x10, unchecked((ulong)GetEventProgress(eventGroup, recordMap)));
                foreach (TaskDefinition definition in eventGroup)
                {
                    recordMap.TryGetValue((definition.TaskType, definition.Id), out PlayerTaskRecord? record);
                    eventInfo.Write(0x1A, EncodeTask(definition, record));
                }
                output.Write(tag, eventInfo.ToArray());
            }
        }
        ProtocolPackage stage = new();
        stage.Write(0x08, unchecked((ulong)TaskConfigCatalog.TypeTeachingStage));
        stage.Write(0x10, 1UL);
        output.Write(0x1A, stage.ToArray());
        output.Write(0x20, 0UL);
        return output.ToArray();
    }

    /// <summary>
    /// TTaskEventInfo.Count 表示该事件的当前累计值，不是任务目标值。任务目录通常会为同一
    /// EventType 配置多个递进目标，因此取已持久化记录中的最大进度，并限制在最高目标内。
    /// </summary>
    internal static int GetEventProgress(IEnumerable<TaskDefinition> definitions,
        IReadOnlyDictionary<(int Type, int Id), PlayerTaskRecord> records)
    {
        int progress = 0;
        int maxGoal = 0;
        foreach (TaskDefinition definition in definitions)
        {
            maxGoal = Math.Max(maxGoal, Math.Max(0, definition.Goal));
            if (records.TryGetValue((definition.TaskType, definition.Id), out PlayerTaskRecord? record))
                progress = Math.Max(progress, Math.Max(0, record.Count));
        }
        return Math.Min(progress, maxGoal);
    }

    internal static byte[] EncodeReward(int taskId, IReadOnlyList<CommonReward> rewards)
    {
        ProtocolPackage output = new();
        output.Write(0x08, unchecked((ulong)taskId));
        foreach (CommonReward reward in rewards)
            output.Write(0x12, PlayerDataCodec.Encode(reward));
        return output.ToArray();
    }

    internal static byte[] EncodeRewardList(IReadOnlyList<CommonReward> rewards)
    {
        ProtocolPackage output = new();
        foreach (CommonReward reward in rewards)
            output.Write(0x0A, PlayerDataCodec.Encode(reward));
        return output.ToArray();
    }

    internal static (int TaskId, int TaskType, int Day) DecodeRewardArg(ReadOnlySpan<byte> payload)
    {
        int taskId = 0, taskType = 0, day = 0;
        ProtocolDecoder.ProtoReader reader = new(payload);
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: taskId = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 0: taskType = checked((int)reader.ReadVarint()); break;
                case 3 when wire == 0: day = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        return (taskId, taskType, day);
    }

    internal static int DecodeFirstInt(ReadOnlySpan<byte> payload)
    {
        ProtocolDecoder.ProtoReader reader = new(payload);
        while (reader.TryReadField(out int field, out int wire))
        {
            if (field == 1 && wire == 0) return checked((int)reader.ReadVarint());
            reader.Skip(wire);
        }
        return 0;
    }

    internal static byte[] EncodeTask(TaskDefinition definition, PlayerTaskRecord? record)
    {
        ProtocolPackage task = new();
        task.Write(0x08, unchecked((ulong)definition.Id));
        task.Write(0x10, unchecked((ulong)(record?.RewardTime ?? 0)));
        task.Write(0x18, unchecked((ulong)(record?.FinishTime ?? 0)));
        task.Write(0x20, unchecked((ulong)Math.Max(0, record?.Count ?? 0)));
        task.Write(0x38, 0UL); // StartTime
        task.Write(0x40, 0UL); // FinishNum
        return task.ToArray();
    }
}
