using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>基地模块：建筑生命周期、舰娘派驻与持久化快照。</summary>
internal sealed class BuildingModule(BuildingService building) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["building"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        switch (request.Method)
        {
            case "building.AddBuilding":
            {
                AddBuildingArg arg = PlayerDataCodec.DecodeAddBuildingArg(request.Args ?? []);
                BuildingService.Mutation mutation = await building.AddBuildingAsync(
                    ctx.ProfileId, arg, ctx.Now, ctx.Ct);
                return ToResult(ctx, mutation, mutation.Success
                    ? PlayerDataCodec.EncodeAddBuildingRet(mutation.BuildingId)
                    : []);
            }
            case "building.UpgradeBuilding":
            {
                int buildingId = PlayerDataCodec.DecodeBuildingIdArg(request.Args ?? []);
                BuildingService.Mutation mutation = await building.UpgradeBuildingAsync(
                    ctx.ProfileId, buildingId, ctx.Now, ctx.Ct);
                return ToResult(ctx, mutation);
            }
            case "building.FinishBuilding":
            {
                int buildingId = PlayerDataCodec.DecodeBuildingIdArg(request.Args ?? []);
                BuildingService.Mutation mutation = await building.FinishBuildingAsync(
                    ctx.ProfileId, buildingId, ctx.Now, ctx.Ct);
                return ToResult(ctx, mutation);
            }
            case "building.DegradeBuilding":
            {
                int buildingId = PlayerDataCodec.DecodeBuildingIdArg(request.Args ?? []);
                BuildingService.Mutation mutation = await building.DegradeBuildingAsync(
                    ctx.ProfileId, buildingId, ctx.Now, ctx.Ct);
                return ToResult(ctx, mutation);
            }
            case "building.SetHero":
            {
                SetBuildingHeroArg arg = PlayerDataCodec.DecodeSetBuildingHeroArg(request.Args ?? []);
                var assignments = new Dictionary<int, IReadOnlyList<uint>>
                {
                    [arg.BuildingId] = arg.HeroIds,
                };
                return await MutateAsync(ctx, assignments);
            }
            case "building.SetBuildingListHero":
            {
                SetBuildingListHeroArg arg = PlayerDataCodec.DecodeSetBuildingListHeroArg(request.Args ?? []);
                if (!TrySplitAssignments(arg, out Dictionary<int, IReadOnlyList<uint>> assignments))
                    return new ModuleResult { Err = 1, ErrMsg = "Invalid building assignment payload" };
                return await MutateAsync(ctx, assignments);
            }
            case "building.UpdateHeroAddition":
            {
                var account = await ctx.GetAccountAsync();
                return new ModuleResult
                {
                    PrePushes = [BuildingService.BuildInfoPush(account.Building, (uint)ctx.Now)],
                };
            }
            default:
                // Production, resource collection and story operations intentionally remain inert.
                return ModuleResult.Empty;
        }
    }

    private async Task<ModuleResult> MutateAsync(
        GameContext ctx,
        IReadOnlyDictionary<int, IReadOnlyList<uint>> assignments)
    {
        BuildingService.Mutation mutation = await building.SetHeroesAsync(
            ctx.ProfileId, assignments, ctx.Now, ctx.Ct);
        return ToResult(ctx, mutation);
    }

    private static ModuleResult ToResult(
        GameContext ctx,
        BuildingService.Mutation mutation,
        byte[]? ret = null) =>
        mutation.Success
            ? new ModuleResult
            {
                Ret = ret ?? [],
                // 客户端在应答回调中立即读取 buildingData，因此快照必须先于应答到达。
                PrePushes = [BuildingService.BuildInfoPush(
                    mutation.Account.Building,
                    checked((uint)ctx.Now))],
            }
            : new ModuleResult { Err = mutation.Err, ErrMsg = mutation.ErrMsg };

    private static bool TrySplitAssignments(
        SetBuildingListHeroArg arg,
        out Dictionary<int, IReadOnlyList<uint>> assignments)
    {
        assignments = [];
        int cursor = 0;
        foreach (int buildingId in arg.BuildingIds)
        {
            var heroIds = new List<uint>();
            while (cursor < arg.HeroIds.Count && arg.HeroIds[cursor] != -1)
            {
                int heroId = arg.HeroIds[cursor++];
                if (heroId <= 0) return false;
                heroIds.Add(checked((uint)heroId));
            }
            if (cursor >= arg.HeroIds.Count || arg.HeroIds[cursor] != -1 || buildingId <= 0)
                return false;
            cursor++;
            if (!assignments.TryAdd(buildingId, heroIds)) return false;
        }
        return cursor == arg.HeroIds.Count;
    }
}
