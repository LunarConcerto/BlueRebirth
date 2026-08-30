using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>任务协议：任务快照、单项/批量领奖和教学任务。</summary>
internal sealed class TaskModule(TaskService tasks) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["task"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        switch (request.Method)
        {
            case "task.TaskInfo":
            {
                var account = await tasks.GetSnapshotAccountAsync(ctx.ProfileId, ctx.Now, ctx.Ct);
                return ModuleResult.Ok(TaskProtocolCodec.EncodeTaskInfo(account, ctx.Now));
            }
            case "task.TaskReward":
            case "task.TaskRewardByDaysActivity":
            case "task.TaskSevenDayActivity":
            case "task.TaskRewardByReturnActivity":
            {
                (int taskId, int taskType, _) = TaskProtocolCodec.DecodeRewardArg(request.Args ?? []);
                TaskRewardMutation mutation = await tasks.ClaimAsync(
                    ctx.ProfileId, taskType, taskId, ctx.Now, ctx.Ct,
                    allowConfiguredTask: request.Method != "task.TaskReward");
                if (!mutation.Success)
                    return new ModuleResult { Err = 1, ErrMsg = mutation.Error };
                return new ModuleResult
                {
                    Ret = TaskProtocolCodec.EncodeReward(taskId, mutation.Rewards),
                    PrePushes = await tasks.BuildRefreshPushesAsync(
                        mutation.Account, (uint)ctx.Now, ctx.Ct),
                };
            }
            case "task.TaskAllReward":
            {
                int getType = TaskProtocolCodec.DecodeFirstInt(request.Args ?? []);
                TaskRewardMutation mutation = await tasks.ClaimAllAsync(
                    ctx.ProfileId, getType, ctx.Now, ctx.Ct);
                return new ModuleResult
                {
                    Ret = TaskProtocolCodec.EncodeRewardList(mutation.Rewards),
                    PrePushes = await tasks.BuildRefreshPushesAsync(
                        mutation.Account, (uint)ctx.Now, ctx.Ct),
                };
            }
            case "task.GetPtReward":
            {
                int id = TaskProtocolCodec.DecodeFirstInt(request.Args ?? []);
                TaskRewardMutation mutation = await tasks.ClaimTeachingPointAsync(
                    ctx.ProfileId, id, ctx.Now, ctx.Ct);
                if (!mutation.Success)
                    return new ModuleResult { Err = 1, ErrMsg = mutation.Error };
                return new ModuleResult
                {
                    Ret = TaskProtocolCodec.EncodeRewardList(mutation.Rewards),
                    PrePushes = await tasks.BuildRefreshPushesAsync(
                        mutation.Account, (uint)ctx.Now, ctx.Ct),
                };
            }
            case "task.GetTeachingTask":
            {
                var account = await tasks.GetSnapshotAccountAsync(ctx.ProfileId, ctx.Now, ctx.Ct);
                return ModuleResult.Ok(TaskProtocolCodec.EncodeTeachingInfo(account, ctx.Now));
            }
            case "task.TaskTrigger":
                // 离线档案中的当前任务按可领奖状态下发；触发事件仍需成功应答，
                // 否则客户端的 TaskTriggerRet 生命周期不会结束。
                return ModuleResult.Ok([]);
            default:
                return ModuleResult.Empty;
        }
    }
}
