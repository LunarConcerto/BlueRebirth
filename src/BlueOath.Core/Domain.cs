using BlueOath.Protocol;

namespace BlueOath.Core;

public sealed record Ship(int Id, string Name, int Level, int Power);
public sealed record Formation(IReadOnlyList<int> ShipIds);
public sealed record PlayerState(string ProfileId, string Name, int Level, int Fuel, int Coins, IReadOnlyList<Ship> Ships, Formation Formation, int CompletedStages);
public sealed record Stage(int Id, string Name, IReadOnlyList<Ship> Enemies, int FuelCost, int CoinReward);
public sealed record BattleOutcome(bool Victory, int FuelSpent, int CoinsGained, int CompletedStages, string Message);

/// <summary>战斗结算结果：结算后的玩家状态 + 战斗结算明细。</summary>
public sealed record BattleResolution(PlayerState State, BattleOutcome Outcome);

public interface IGameRepository
{
    Task<PlayerState?> LoadAsync(string profileId, CancellationToken ct = default);
    Task SaveAsync(PlayerState state, CancellationToken ct = default);
    Task<IReadOnlyList<string>> ListProfilesAsync(CancellationToken ct = default);
    Task CreateAsync(string profileId, string name, CancellationToken ct = default);
    Task BackupAsync(string profileId, string destination, CancellationToken ct = default);
    Task ResetAsync(string profileId, CancellationToken ct = default);

    /// <summary>加载玩家账号（角色 + 船坞）；不存在时返回 null。</summary>
    Task<PlayerAccount?> LoadAccountAsync(string profileId, CancellationToken ct = default);

    /// <summary>持久化玩家账号（角色 + 船坞）。</summary>
    Task SaveAccountAsync(PlayerAccount account, CancellationToken ct = default);
}

public sealed class GameService(IGameRepository repository, ProtocolProfile profile)
{
    public ProtocolProfile Profile { get; } = profile;

    public Task<PlayerState?> GetStateAsync(string profileId, CancellationToken ct = default) => repository.LoadAsync(profileId, ct);

    public async Task<PlayerState> SetFormationAsync(string profileId, IReadOnlyList<int> shipIds, CancellationToken ct = default)
    {
        var state = await RequireState(profileId, ct);
        if (shipIds.Count is < 1 or > 6 || shipIds.Distinct().Count() != shipIds.Count || shipIds.Any(id => state.Ships.All(s => s.Id != id)))
            throw new InvalidOperationException("Formation contains invalid ships");
        var updated = state with { Formation = new Formation(shipIds) };
        await repository.SaveAsync(updated, ct);
        return updated;
    }

    public async Task<Stage> EnterStageAsync(string profileId, int stageId, CancellationToken ct = default)
    {
        var state = await RequireState(profileId, ct);
        var stage = StageCatalog.Get(stageId);
        if (state.Formation.ShipIds.Count == 0) throw new InvalidOperationException("Formation is empty");
        if (state.Fuel < stage.FuelCost) throw new InvalidOperationException("Not enough fuel");
        return stage;
    }

    public async Task<BattleResolution> ResolveBattleAsync(string profileId, int stageId, bool win, CancellationToken ct = default)
    {
        var state = await RequireState(profileId, ct);
        var stage = StageCatalog.Get(stageId);
        if (state.Fuel < stage.FuelCost) throw new InvalidOperationException("Not enough fuel");
        var completed = Math.Max(state.CompletedStages, win ? stage.Id : state.CompletedStages);
        var updated = state with { Fuel = state.Fuel - stage.FuelCost, Coins = state.Coins + (win ? stage.CoinReward : 0), CompletedStages = completed };
        await repository.SaveAsync(updated, ct);
        return new BattleResolution(updated, new BattleOutcome(win, stage.FuelCost, win ? stage.CoinReward : 0, completed, win ? "Victory" : "Defeat"));
    }

    private async Task<PlayerState> RequireState(string id, CancellationToken ct) => await repository.LoadAsync(id, ct) ?? throw new KeyNotFoundException("Profile not found");
}

public static class StageCatalog
{
    private static readonly IReadOnlyDictionary<int, Stage> Stages = new Dictionary<int, Stage>
    {
        [1] = new(1, "Tutorial Waters", [new Ship(9001, "Training Target", 1, 20)], 10, 100)
    };
    public static Stage Get(int id) => Stages.TryGetValue(id, out var stage) ? stage : throw new KeyNotFoundException("Stage not found");
}
