using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 离线基地服务：维护建筑新建、升级、完成、降级与舰娘派驻。
/// 生产、材料扣除和心情消耗仍保持关闭。
/// </summary>
internal sealed class BuildingService(GameServices services)
{
    private const int Idle = 1;
    private const int Adding = 2;
    private const int Upgrading = 4;

    internal sealed record Mutation(PlayerAccount Account, int BuildingId = 0, int Err = 0, string ErrMsg = "")
    {
        internal bool Success => Err == 0;
    }

    /// <summary>生产/合成结果：已发放的道具列表（用于 TReceiveRet.ItemInfo）。</summary>
    internal sealed record ProduceResult(
        PlayerAccount Account,
        IReadOnlyList<CommonReward> Rewards,
        int Err = 0,
        string ErrMsg = "")
    {
        internal bool Success => Err == 0;
    }

    /// <summary>原料/产出里的 STRENGTH（工人体力）货币 id（CurrencyType.STRENGTH）。</summary>
    private const int CurrencyStrength = 21;

    /// <summary>building.ProduceItem：按 config_recipe 合成物品。校验建筑存在、配方有效、
    /// 材料/体力足够，扣原料并立即产出 item（耗时配方离线服直接产出）。</summary>
    internal async Task<ProduceResult> ProduceItemAsync(
        string profileId, int buildingId, int recipeId, int count, int now, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerBuilding state = account.Building ?? PlayerAccountFactory.DefaultBuilding(now);
        if (count <= 0) return Fail(account, "Invalid produce count");
        if (!state.Buildings.Any(b => b.Id == buildingId))
            return Fail(account, $"Building {buildingId} is not owned");
        ConfigRecipe? recipe = RecipeConfigLoader.GetProduce(recipeId);
        if (recipe is null || recipe.Item is not { Count: >= 3 })
            return Fail(account, $"Unknown produce recipe {recipeId}");

        return await ExecuteRecipeAsync(
            profileId, account, state,
            [recipe.Rawmaterial1, recipe.Rawmaterial2],
            recipe.Item, count, ct);
    }

    /// <summary>building.ComposeItem：按 config_recipe_compose 即时合成物品，逻辑同 ProduceItem
    /// 但不涉及生产时长。</summary>
    internal async Task<ProduceResult> ComposeItemAsync(
        string profileId, int buildingId, int recipeId, int count, int now, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerBuilding state = account.Building ?? PlayerAccountFactory.DefaultBuilding(now);
        if (count <= 0) return Fail(account, "Invalid compose count");
        if (!state.Buildings.Any(b => b.Id == buildingId))
            return Fail(account, $"Building {buildingId} is not owned");
        ConfigRecipeCompose? recipe = RecipeConfigLoader.GetCompose(recipeId);
        if (recipe is null || recipe.Item is not { Count: >= 3 })
            return Fail(account, $"Unknown compose recipe {recipeId}");

        return await ExecuteRecipeAsync(
            profileId, account, state,
            [recipe.Rawmaterial1, recipe.Rawmaterial2],
            recipe.Item, count, ct);
    }

    /// <summary>校验并扣除原料（rawmaterial = [type,id,num]，type1=道具、type5=货币含 STRENGTH 体力），
    /// 然后发放产出 item=[type,id,num]。STRENGTH 从基地工人体力 WorkerStrength 扣除。</summary>
    private async Task<ProduceResult> ExecuteRecipeAsync(
        string profileId,
        PlayerAccount account,
        PlayerBuilding state,
        IReadOnlyList<IReadOnlyList<long>?> rawMaterials,
        IReadOnlyList<long> item,
        int count,
        CancellationToken ct)
    {
        int strength = state.WorkerStrength;
        PlayerAccount after = account;

        foreach (IReadOnlyList<long>? raw in rawMaterials)
        {
            if (raw is not { Count: >= 3 } || raw[0] <= 0 || raw[2] <= 0) continue;
            int matType = checked((int)raw[0]);
            int matId = checked((int)raw[1]);
            int matNum = checked((int)raw[2]) * count;

            if (matType == GameServices.GoodsTypeCurrency && matId == CurrencyStrength)
            {
                if (strength < matNum) return Fail(account, "Not enough worker strength");
                strength -= matNum;
                continue;
            }
            if (matType == GameServices.GoodsTypeCurrency)
            {
                if (!HasCurrency(after, matId, matNum)) return Fail(account, $"Not enough currency {matId}");
                after = GameServices.AddCurrency(after, matId, -matNum);
                continue;
            }
            int bag = after.Bag?.Items.FirstOrDefault(i => i.TemplateId == matId)?.Num ?? 0;
            if (bag < matNum) return Fail(account, $"Not enough material {matId}");
            after = GameServices.AddBagItem(after, matId, -matNum);
        }

        int itemType = checked((int)item[0]);
        int itemId = checked((int)item[1]);
        int itemNum = checked((int)item[2]) * count;
        after = itemType == GameServices.GoodsTypeCurrency
            ? GameServices.AddCurrency(after, itemId, itemNum)
            : GameServices.AddBagItem(after, itemId, itemNum);

        // 若有 STRENGTH 消耗，写回基地体力。
        if (strength != state.WorkerStrength)
            after = after with { Building = state with { WorkerStrength = strength } };

        await services.SaveAccountAsync(after, ct);
        return new ProduceResult(after, [new CommonReward(itemType, itemId, itemNum)]);
    }

    private static bool HasCurrency(PlayerAccount account, int id, int num)
    {
        long owned = id switch
        {
            1 => account.Character.Gold,
            5 => account.Character.Supply,
            12 => account.Character.Retire,
            _ => -1,
        };
        return owned >= num;
    }

    private static ProduceResult Fail(PlayerAccount account, string message) =>
        new(account, [], Err: 1, ErrMsg: message);

    internal async Task<Mutation> AddBuildingAsync(
        string profileId, AddBuildingArg arg, int now, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerBuilding state = account.Building ?? PlayerAccountFactory.DefaultBuilding(now);
        ConfigBuildinginfo? info = BuildingConfigLoader.GetInfo(arg.Tid);
        ConfigBuilding? land = BuildingConfigLoader.GetLand(arg.Index);
        if (info is null || info.Level != 1 || info.Type is < 2 or > 7)
            return Error(account, $"Invalid level-1 building tid {arg.Tid}");
        if (land is null || state.Lands.Any(item => item.Index == arg.Index))
            return Error(account, $"Land {arg.Index} is unavailable");

        PlayerBuildingEntry? office = FindOffice(state);
        ConfigBuildinginfo? officeInfo = office is null ? null : BuildingConfigLoader.GetInfo(office.Tid);
        if (office is null || officeInfo is null || land.Officelevel > office.Level)
            return Error(account, $"Land {arg.Index} is locked");
        if (land.BuildinggroupId?.Contains(info.Type) != true)
            return Error(account, $"Building type {info.Type} is not allowed on land {arg.Index}");

        int maxCount = GetTypeLimit(officeInfo, checked((int)info.Type));
        int currentCount = state.Buildings.Count(item => BuildingConfigLoader.GetInfo(item.Tid)?.Type == info.Type);
        if (maxCount <= 0 || currentCount >= maxCount)
            return Error(account, $"Building type {info.Type} has reached its limit");

        int buildingId = state.Buildings.Count == 0 ? 1 : state.Buildings.Max(item => item.Id) + 1;
        int duration = GetBuildDuration(arg.Tid);
        var entry = new PlayerBuildingEntry(
            Id: buildingId,
            Tid: arg.Tid,
            Level: 1,
            HeroIds: [],
            Status: duration > 0 ? Adding : Idle,
            LastUpdateTime: now,
            LastBuildUpdateTime: now);
        PlayerBuilding updatedState = state with
        {
            Buildings = [.. state.Buildings, entry],
            Lands = [.. state.Lands, new PlayerBuildingLand(arg.Index, buildingId)],
        };
        return await SaveAsync(account, updatedState, buildingId, ct);
    }

    internal async Task<Mutation> UpgradeBuildingAsync(
        string profileId, int buildingId, int now, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerBuilding state = account.Building ?? PlayerAccountFactory.DefaultBuilding(now);
        PlayerBuildingEntry? building = state.Buildings.FirstOrDefault(item => item.Id == buildingId);
        ConfigBuildinginfo? current = building is null ? null : BuildingConfigLoader.GetInfo(building.Tid);
        if (building is null || current is null || building.Status is Adding or Upgrading)
            return Error(account, $"Building {buildingId} cannot be upgraded");

        int targetLevel = building.Level + 1;
        ConfigBuildinginfo? target = BuildingConfigLoader.GetInfo(checked((int)current.Type), targetLevel);
        if (target is null) return Error(account, $"Building {buildingId} is already at max level");

        PlayerBuildingEntry? office = FindOffice(state);
        if (current.Type != 1 && (office is null || targetLevel > office.Level))
            return Error(account, $"Office level is too low for building {buildingId}");

        int duration = GetBuildDuration(checked((int)target.Id));
        PlayerBuildingEntry updated = duration > 0
            ? building with { Status = Upgrading, LastBuildUpdateTime = now }
            : building with
            {
                Tid = checked((int)target.Id),
                Level = targetLevel,
                Status = Idle,
                LastUpdateTime = now,
                LastBuildUpdateTime = now,
            };
        return await SaveAsync(account, Replace(state, updated), buildingId, ct);
    }

    internal async Task<Mutation> FinishBuildingAsync(
        string profileId, int buildingId, int now, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerBuilding state = account.Building ?? PlayerAccountFactory.DefaultBuilding(now);
        PlayerBuildingEntry? building = state.Buildings.FirstOrDefault(item => item.Id == buildingId);
        if (building is null) return Error(account, $"Unknown building {buildingId}");
        if (building.Status is not (Adding or Upgrading))
            return new Mutation(account, buildingId);

        ConfigBuildinginfo? current = BuildingConfigLoader.GetInfo(building.Tid);
        int targetLevel = building.Status == Adding ? 1 : building.Level + 1;
        ConfigBuildinginfo? target = current is null
            ? null
            : BuildingConfigLoader.GetInfo(checked((int)current.Type), targetLevel);
        if (target is null) return Error(account, $"Building {buildingId} has no completion target");
        int duration = GetBuildDuration(checked((int)target.Id));
        if (now < building.LastBuildUpdateTime + duration)
            return Error(account, $"Building {buildingId} is not finished yet");

        PlayerBuildingEntry updated = building with
        {
            Tid = checked((int)target.Id),
            Level = targetLevel,
            Status = Idle,
            LastUpdateTime = now,
            LastBuildUpdateTime = now,
        };
        return await SaveAsync(account, Replace(state, updated), buildingId, ct);
    }

    internal async Task<Mutation> DegradeBuildingAsync(
        string profileId, int buildingId, int now, CancellationToken ct)
    {
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerBuilding state = account.Building ?? PlayerAccountFactory.DefaultBuilding(now);
        PlayerBuildingEntry? building = state.Buildings.FirstOrDefault(item => item.Id == buildingId);
        ConfigBuildinginfo? current = building is null ? null : BuildingConfigLoader.GetInfo(building.Tid);
        if (building is null || current is null || building.Status is Adding or Upgrading || building.Level <= 1)
            return Error(account, $"Building {buildingId} cannot be degraded", 3409);

        int targetLevel = building.Level - 1;
        ConfigBuildinginfo? target = BuildingConfigLoader.GetInfo(checked((int)current.Type), targetLevel);
        if (target is null || building.HeroIds.Count > target.Heronumber)
            return Error(account, $"Building {buildingId} cannot fit its current heroes after degradation", 3409);
        if (current.Type == 1 && !CanDegradeOffice(state, target))
            return Error(account, "Office degradation would lock an occupied land or exceed a building limit", 3409);

        PlayerBuildingEntry updated = building with
        {
            Tid = checked((int)target.Id),
            Level = targetLevel,
            Status = Idle,
            LastUpdateTime = now,
            LastBuildUpdateTime = now,
        };
        return await SaveAsync(account, Replace(state, updated), buildingId, ct);
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
                return Error(account, $"Unknown building {buildingId}");
            if (building.Status is Adding or Upgrading || heroIds.Count > GetCapacity(building))
                return Error(account, $"Building {buildingId} cannot accept these heroes");
        }

        uint[] assignedHeroIds = assignments.Values.SelectMany(ids => ids).ToArray();
        if (assignedHeroIds.Distinct().Count() != assignedHeroIds.Length)
            return Error(account, "A hero cannot be assigned to more than one building");

        HashSet<uint> ownedHeroIds = account.Dock.Heroes.Select(hero => hero.HeroId).ToHashSet();
        if (assignedHeroIds.Any(heroId => heroId == 0 || !ownedHeroIds.Contains(heroId)))
            return Error(account, "The assignment contains a hero not owned by this profile");

        HashSet<uint> movingHeroIds = assignedHeroIds.ToHashSet();
        var buildings = new List<PlayerBuildingEntry>(state.Buildings.Count);
        foreach (PlayerBuildingEntry building in state.Buildings)
        {
            IReadOnlyList<uint> heroIds = assignments.TryGetValue(building.Id, out IReadOnlyList<uint>? replacement)
                ? replacement.ToArray()
                : building.HeroIds.Where(heroId => !movingHeroIds.Contains(heroId)).ToArray();
            buildings.Add(building with { HeroIds = heroIds, LastUpdateTime = now });
        }

        return await SaveAsync(account, state with { Buildings = buildings }, 0, ct);
    }

    internal static UserBuildingInfo ToProtocol(PlayerBuilding? state, int now)
    {
        state ??= PlayerAccountFactory.DefaultBuilding(now);
        int officeLevel = FindOffice(state)?.Level ?? 1;
        int fullWorkerStrength = BuildingConfigLoader.GetMaxWorkerStrength(officeLevel) * 10_000;
        return new UserBuildingInfo(
            BuildingInfos: state.Buildings
                .OrderBy(building => building.Id)
                .Select(building => new BuildingInfo(
                    Id: building.Id,
                    Tid: building.Tid,
                    Level: building.Level,
                    HeroList: building.HeroIds,
                    Status: building.Status,
                    // Refreshing this timestamp prevents client-side mood/resource simulation.
                    LastUpdateTime: now,
                    LastBuildUpdateTime: building.LastBuildUpdateTime))
                .ToArray(),
            LandList: state.Lands
                .OrderBy(land => land.Index)
                .Select(land => new BuildingLandInfo(land.Index, land.BuildingId))
                .ToArray(),
            WorkerStrength: fullWorkerStrength,
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

    private static Mutation Error(PlayerAccount account, string message, int err = 1) =>
        new(account, Err: err, ErrMsg: message);

    private async Task<Mutation> SaveAsync(
        PlayerAccount account, PlayerBuilding state, int buildingId, CancellationToken ct)
    {
        PlayerAccount updated = account with { Building = state };
        await services.SaveAccountAsync(updated, ct);
        return new Mutation(updated, buildingId);
    }

    private static PlayerBuilding Replace(PlayerBuilding state, PlayerBuildingEntry replacement) =>
        state with
        {
            Buildings = state.Buildings
                .Select(item => item.Id == replacement.Id ? replacement : item)
                .ToArray(),
        };

    private static PlayerBuildingEntry? FindOffice(PlayerBuilding state) =>
        state.Buildings.FirstOrDefault(item => BuildingConfigLoader.GetInfo(item.Tid)?.Type == 1)
        ?? state.Buildings.FirstOrDefault(item => item.Tid is >= 1 and <= 5);

    private static int GetBuildDuration(int tid) =>
        checked((int)(BuildingConfigLoader.GetLevelUp(tid)?.Leveluptime ?? 0));

    private static int GetCapacity(PlayerBuildingEntry building) =>
        checked((int)(BuildingConfigLoader.GetInfo(building.Tid)?.Heronumber ?? (building.Tid switch
        {
            >= 41 and <= 45 => 5,
            >= 1 and <= 5 => building.Level,
            _ => 0,
        })));

    private static int GetTypeLimit(ConfigBuildinginfo officeInfo, int type)
    {
        int index = type - 2;
        return officeInfo.Buildquantity is { } limits && index >= 0 && index < limits.Count
            ? checked((int)limits[index])
            : 0;
    }

    private static bool CanDegradeOffice(PlayerBuilding state, ConfigBuildinginfo targetOffice)
    {
        foreach (PlayerBuildingLand occupied in state.Lands)
        {
            ConfigBuilding? land = BuildingConfigLoader.GetLand(occupied.Index);
            if (land is not null && land.Officelevel > targetOffice.Level) return false;
        }
        foreach (IGrouping<long, PlayerBuildingEntry> group in state.Buildings
                     .Where(item => BuildingConfigLoader.GetInfo(item.Tid)?.Type is >= 2 and <= 7)
                     .GroupBy(item => BuildingConfigLoader.GetInfo(item.Tid)!.Type))
        {
            if (group.Count() > GetTypeLimit(targetOffice, checked((int)group.Key))) return false;
            if (group.Any(item => item.Level > targetOffice.Level)) return false;
        }
        return true;
    }
}
