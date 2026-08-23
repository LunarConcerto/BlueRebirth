namespace BlueOath.Core;

/// <summary>TPassKvInfo: Type(1, int32) / Value(2, int32)。</summary>
public sealed record PassKvInfo(int Type = 0, int Value = 0);

/// <summary>TPassEvaluate: Type(1, int32) / Value(2, int32)。</summary>
public sealed record PassEvaluate(int Type = 0, int Value = 0);

/// <summary>TBaseHeroInfo: HeroId(1, uint32) / Hp(2, uint64) / IsMvp(3, bool) / IsBattle(4, bool)
/// / BreakStatus(5, int32) / ExHeroInfo(6, repeated TPassKvInfo) / OwnerUid(7, uint64)。</summary>
public sealed record BaseHeroInfo(
    uint HeroId = 0,
    ulong Hp = 0,
    bool IsMvp = false,
    bool IsBattle = false,
    int BreakStatus = 0,
    IReadOnlyList<PassKvInfo>? ExHeroInfo = null,
    ulong OwnerUid = 0);

/// <summary>TPassFleetInfo: EnemyId(1, int32) / EnemyInfo(2, repeated TBaseHeroInfo)。</summary>
public sealed record PassFleetInfo(
    int EnemyId = 0,
    IReadOnlyList<BaseHeroInfo>? EnemyInfo = null);

/// <summary>TArchiveCopyOperation: frameNumber(1, int32) / data(2, bytes)。</summary>
public sealed record ArchiveCopyOperation(
    int FrameNumber = 0,
    ReadOnlyMemory<byte> Data = default);

/// <summary>THeroAttr: AttrId(1, int32) / AttrValue(2, int32)。</summary>
public sealed record HeroAttr(int AttrId = 0, int AttrValue = 0);

/// <summary>TBattleEnemyShip: ShipId(1, int32) / Attr(2, repeated THeroAttr) / PSkill(3, repeated int32)。</summary>
public sealed record BattleEnemyShip(
    int ShipId = 0,
    IReadOnlyList<HeroAttr>? Attr = null,
    IReadOnlyList<int>? PSkill = null);

/// <summary>TBattleEnemyFleet: FleetId(1, int32) / State(2, int32) / Ships(3, repeated TBattleEnemyShip)。</summary>
public sealed record BattleEnemyFleet(
    int FleetId = 0,
    int State = 0,
    IReadOnlyList<BattleEnemyShip>? Ships = null);

/// <summary>
/// TPassBaseArg 完整实体（客户端 → 服务器通关结算请求）。
/// 对照 copy_pb.lua 的 TPassBaseArg 所有字段。
/// </summary>
public sealed record PassBaseArg(
    int BaseId = 0,
    int Rid = 0,
    string CacheId = "",
    int RunningTime = 0,
    float MaxTimeScale = 0f,
    bool IsFlyAttack = false,
    bool IsRunningFight = false,
    int Grade = 0,
    ulong MvpHeroId = 0,
    string BattleString = "",
    IReadOnlyList<PassEvaluate>? Evaluate = null,
    int BattleTime = 0,
    int LBPoint = 0,
    bool IsSupport = false,
    int BattleType = 0,
    ArchiveCopyOperation? Operation = null,
    IReadOnlyList<PassFleetInfo>? FleetInfo = null,
    IReadOnlyList<BaseHeroInfo>? HerosInfo = null,
    bool IsFinishMission = false,
    IReadOnlyList<BattleEnemyFleet>? EnemyFleets = null);