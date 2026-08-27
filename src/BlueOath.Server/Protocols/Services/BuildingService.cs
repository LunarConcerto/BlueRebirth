using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>离线基地服务：只维护办公室/宿舍与舰娘派驻，不启用生产和消耗。</summary>
internal sealed class BuildingService(GameServices services)
{
    internal sealed record Mutation(PlayerAccount Account, int Err = 0, string ErrMsg = "")
    {
        internal bool Success => Err == 0;
    }

    internal async Task<Mutation> SetHeroesAsync(
        string profileId,
        IReadOnlyDictionary<int, IReadOnlyList<uint>> assignments,
        int now,
        CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerBuilding state = account.Building ?? PlayerAccountFactory.DefaultBuilding(now);
        var byId = state.Buildings.ToDictionary(building => building.Id);

        foreach ((int buildingId, IReadOnlyList<uint> heroIds) in assignments)
        {
            if (!byId.TryGetValue(buildingId, out PlayerBuildingEntry? building))
                return new Mutation(account, 1, $"Unknown building {buildingId}");
            if (heroIds.Count > GetCapacity(building))
                return new Mutation(account, 1, $"Building {buildingId} is full");
        }

        uint[] assignedHeroIds = assignments.Values.SelectMany(ids => ids).ToArray();
        if (assignedHeroIds.Distinct().Count() != assignedHeroIds.Length)
            return new Mutation(account, 1, "A hero cannot be assigned to more than one building");

        HashSet<uint> ownedHeroIds = account.Dock.Heroes.Select(hero => hero.HeroId).ToHashSet();
        if (assignedHeroIds.Any(heroId => heroId == 0 || !ownedHeroIds.Contains(heroId)))
            return new Mutation(account, 1, "The assignment contains a hero not owned by this profile");

        HashSet<uint> movingHeroIds = assignedHeroIds.ToHashSet();
        var buildings = new List<PlayerBuildingEntry>(state.Buildings.Count);
        foreach (PlayerBuildingEntry building in state.Buildings)
        {
            IReadOnlyList<uint> heroIds = assignments.TryGetValue(building.Id, out IReadOnlyList<uint>? replacement)
                ? replacement.ToArray()
                : building.HeroIds.Where(heroId => !movingHeroIds.Contains(heroId)).ToArray();
            buildings.Add(building with { HeroIds = heroIds, Status = 1, LastUpdateTime = now });
        }

        PlayerAccount updated = account with
        {
            Building = state with { Buildings = buildings },
        };
        await services.SaveAccountAsync(updated, ct);
        return new Mutation(updated);
    }

    internal static UserBuildingInfo ToProtocol(PlayerBuilding? state, int now)
    {
        state ??= PlayerAccountFactory.DefaultBuilding(now);
        return new UserBuildingInfo(
            BuildingInfos: state.Buildings
                .OrderBy(building => building.Id)
                .Select(building => new BuildingInfo(
                    Id: building.Id,
                    Tid: building.Tid,
                    Level: building.Level,
                    HeroList: building.HeroIds,
                    Status: 1,
                    // Refreshing this timestamp prevents client-side mood/resource simulation.
                    LastUpdateTime: now))
                .ToArray(),
            LandList: state.Lands
                .OrderBy(land => land.Index)
                .Select(land => new BuildingLandInfo(land.Index, land.BuildingId))
                .ToArray(),
            WorkerStrength: state.WorkerStrength,
            WorkerRecover: state.WorkerRecover,
            FoodMax: state.FoodMax,
            ElectricMax: state.ElectricMax,
            WorkerUpdateTime: now);
    }

    internal static byte[] BuildInfoPush(PlayerBuilding? state, uint now) =>
        TMessageCodec.EncodeResponse(new TResponse(
            Method: "building.UpdateBuildingInfo",
            Ret: PlayerDataCodec.Encode(ToProtocol(state, checked((int)now))),
            Time: now));

    private static int GetCapacity(PlayerBuildingEntry building) => building.Tid switch
    {
        >= 41 and <= 45 => 5, // DormRoom levels 1-5 always have five slots.
        >= 1 and <= 5 => building.Level, // Office capacity follows its level.
        _ => 0,
    };
}
