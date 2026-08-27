using System.Text.Json.Serialization;
using BlueOath.Protocol;

namespace BlueOath.Core;

/// <summary>
/// 玩家角色（账号身份）。对应登录后 <c>user.GetUserInfo</c> / <c>TUserInfo</c> 返回的
/// 角色字段（uid/uname/level/cls/secretaryId）。是存档数据库中实际存在的实体，
/// 由 <see cref="PlayerAccount"/> 聚合持有。
/// </summary>
public sealed record PlayerCharacter(
    ulong Uid,
    string Name,
    int Level,
    int Class,
    uint SecretaryId,
    int CreateTime = 0,
    int Bath = 0,
    int Gold = 0,
    int Diamond = 0,
    int Supply = 0,
    int MainGun = 0,
    int Torpedo = 0,
    int Plane = 0,
    int Other = 0,
    int Retire = 0,
    int Strategy = 0,
    int Medal = 0,
    int Tower = 0,
    int CopyTrainPoint = 0,
    int FashionPoint = 0,
    int GuildContri = 0,
    int Lucky = 0,
    int TeacherMedal = 0,
    int TeacherPrestige = 0,
    int BattlePassExp = 0,
    int BattlePassGold = 0,
    int PvePt = 0,
    int GuildCoinII = 0,
    int UrEquipCoin = 0,
    int ActivityBattlePassExp = 0,
    int GetHeroCount = 0,
    int AttackCount = 0,
    int MarriedNum = 0,
    int Head = 1021051,
    int HeadFrame = 0,
    string Message = "",
    int PlotChapterId = 1);

/// <summary>
/// 船坞中的单个舰娘实例。对应 <c>hero.UpdateHeroBagData</c> 的 THeroGrid 字段。
/// 每个 <see cref="Hero"/> 的 <see cref="HeroId"/> 是实例唯一 ID，须与秘书舰
/// <see cref="PlayerCharacter.SecretaryId"/> 一致。
/// </summary>
public sealed record Hero(
    uint HeroId,
    int TemplateId,
    int Level,
    int Fashioning = 0,
    int Exp = 0,
    int CreateTime = 0,
    int UpdateTime = 0,
    int Affection = 0,
    int MarryTime = 0,
    int Mood = 100,
    int MarryType = 0,
    long CurHp = 0,
    IReadOnlyList<uint>? EquipSlots = null,
    string Name = "",
    int ChangeNameTime = 0,
    bool Lock = false,
    int Advance = 0,
    int AdvLv = 0,
    IReadOnlyList<PSkillEntry>? PSkills = null,
    IReadOnlyList<int>? RemouldEffects = null,
    int RemouldLevel = 0);

/// <summary>
/// 船坞（玩家拥有的全部舰娘）。对应 <c>hero.UpdateHeroBagData</c> 的 HeroBag
/// （HeroInfo + HeroBagSize）。
/// </summary>
public sealed record HeroDock(
    IReadOnlyList<Hero> Heroes,
    int BagSize = 200);

/// <summary>传统舰船建造配方中的单项物资。</summary>
public sealed record ConstructionItem(int ResId, int Count);

/// <summary>传统舰船建造配方：金币 + 钢材/铝材等物资。</summary>
public sealed record ConstructionProject(
    IReadOnlyList<ConstructionItem> Items,
    int Gold);

/// <summary>建造队列中的单个任务。EndTime=0 表示仍在等待空闲建造位。</summary>
public sealed record ConstructionJob(
    long Sequence,
    int TemplateId,
    int DurationSeconds,
    long EndTime,
    bool Completed,
    ConstructionProject Project);

/// <summary>传统建造系统存档：最多十个任务、两个并行建造位及最近一次配方。</summary>
public sealed record PlayerConstruction(
    IReadOnlyList<ConstructionJob> Jobs,
    ConstructionProject? LastProject = null,
    long NextSequence = 1);

/// <summary>仓库中的单个道具堆叠（TGridInfo）。</summary>
public sealed record BagItem(int TemplateId, int Num);

/// <summary>玩家仓库（道具/材料等）。对应 bag.GetBagInfo / bag.UpdateBagData 的 TBagInfoRet。</summary>
public sealed record PlayerBag(IReadOnlyList<BagItem> Items, int BagSize = 100);

/// <summary>时装解锁项（TFashionInfo：船型 SfId + 已解锁时装列表）。</summary>
public sealed record FashionEntry(int SfId, IReadOnlyList<int> FashionTids);

/// <summary>玩家已解锁时装（通用解锁状态，对船坞里同 SfId 的所有角色生效）。</summary>
public sealed record PlayerFashion(IReadOnlyList<FashionEntry> Entries);

/// <summary>单个装备实例（TEquipInfo）。EquipId 是服务端分配的唯一实例 ID。</summary>
public sealed record EquipItem(
    uint EquipId,
    int TemplateId,
    int EnhanceLv = 0,
    int Star = 0,
    uint HeroId = 0,
    int EnhanceExp = 0);

/// <summary>装备仓库（TEquipList）。EquipBagSize 为装备仓库容量上限。</summary>
public sealed record PlayerEquip(
    IReadOnlyList<EquipItem> Items,
    int EquipBagSize = 2000);

/// <summary>单个关卡的记录（BaseId → 星级/评价/首通时间/通关次数/通关用时）。</summary>
public sealed record CopyRecord(
    int CopyId,
    int StarLevel = 0,
    int Grade = 0,
    int FirstPassTime = 0,
    int PassTime = 0,
    int PassCount = 0);

/// <summary>玩家关卡进度（所有已通关的关卡记录）。</summary>
public sealed record PlayerCopyProgress(
    IReadOnlyList<CopyRecord> Records);

/// <summary>海域关卡进度（CopyType=2 的关卡记录）。</summary>
public sealed record PlayerSeaCopyProgress(
    IReadOnlyList<CopyRecord> Records);

/// <summary>基地中的单栋建筑。Tid 对应 config_buildinginfo，Id 是存档内的建筑实例 ID。</summary>
public sealed record PlayerBuildingEntry(
    int Id,
    int Tid,
    int Level,
    IReadOnlyList<uint> HeroIds,
    int Status = 1,
    long LastUpdateTime = 0);

/// <summary>基地地图上的地块与建筑实例映射。</summary>
public sealed record PlayerBuildingLand(int Index, int BuildingId);

/// <summary>
/// 离线基地状态。当前只持久化已开放建筑与舰娘派驻关系；生产、材料和心情消耗暂不启用。
/// </summary>
public sealed record PlayerBuilding(
    IReadOnlyList<PlayerBuildingEntry> Buildings,
    IReadOnlyList<PlayerBuildingLand> Lands,
    int WorkerStrength = 1_000_000,
    int WorkerRecover = 10,
    int FoodMax = 100,
    int ElectricMax = 100);

/// <summary>
/// 玩家账号聚合（角色 + 船坞 + 仓库 + 时装 + 关卡进度）。存档数据库中实际存在的实体根，
/// 后续如需加入建造/浴室/建筑等玩家域数据，可在此扩展新的成员（保持向后兼容：
/// 新增可选字段或子实体）。
/// </summary>
public sealed record PlayerAccount(
    string ProfileId,
    PlayerCharacter Character,
    HeroDock Dock,
    PlayerBag? Bag = null,
    PlayerFashion? Fashion = null,
    PlayerEquip? Equip = null,
    PlayerFleet? Fleet = null,
    PlayerCopyProgress? CopyProgress = null,
    PlayerSeaCopyProgress? SeaProgress = null,
    IReadOnlyList<int>? PlotRewardIds = null,
    PlayerBath? Bath = null,
    PlayerConstruction? Construction = null,
    PlayerBuilding? Building = null);

/// <summary>
/// 账号实体的默认工厂：集中定义新档案的初始角色与船坞，便于后续调整默认数值。
/// </summary>
public static class PlayerAccountFactory
{
    /// <summary>好感度协议值的缩放倍率：客户端显示值 1 对应协议值 10000。</summary>
    public const int AffectionScale = 10000;

    /// <summary>config_parameter[157] affection_initial：新舰娘初始好感度 50。</summary>
    public const int DefaultAffection = 50 * AffectionScale;

    /// <summary>config_parameter[155] affection_normal_bound：未誓约好感度上限 100。</summary>
    public const int UnmarriedMaxAffection = 100 * AffectionScale;

    /// <summary>config_parameter[156] affection_marry_bound：誓约后好感度上限 200。</summary>
    public const int MarriedMaxAffection = 200 * AffectionScale;

    /// <summary>默认玩家 ID（未携带 Pid 时使用）。</summary>
    public const string DefaultProfileId = "local-player";

    /// <summary>秘书舰模板（config_parameter[17] "main_ship_girl"）。</summary>
    public const int DefaultHeroTemplateId = 10210511;

    /// <summary>秘书舰默认时装（limit_type=0 -> ship_show "u_cl_oakland"）。</summary>
    public const int DefaultHeroFashioning = 1021051;

    /// <summary>GM 默认金币（足量，避免时装等高金币商品置灰）。</summary>
    public const int DefaultGold = 99999999;

    /// <summary>GM 默认钻石。</summary>
    public const int DefaultDiamond = 999999;

    /// <summary>GM 默认体力（供应）。</summary>
    public const int DefaultSupply = 9999;

    /// <summary>HP 系数（shiplogic.lua HP_COEFFICIENT），CurHp 等于此值时满血。</summary>
    public const long HpCoefficient = 10000000000;

    /// <summary>创建新档案的默认账号（角色 + 含一只秘书舰的船坞 + 空仓库/时装）。</summary>
    public static PlayerAccount CreateDefault(string profileId, int nowSeconds)
    {
        var character = new PlayerCharacter(Uid: 1, Name: profileId, Level: 80, Class: 1, SecretaryId: 1,
            CreateTime: nowSeconds, Gold: DefaultGold, Diamond: DefaultDiamond, Supply: DefaultSupply,
            PvePt: 100, PlotChapterId: int.MaxValue);
        var hero = new Hero(
            HeroId: 1,
            TemplateId: DefaultHeroTemplateId,
            Level: 1,
            Fashioning: DefaultHeroFashioning,
            Exp: 0,
            CreateTime: nowSeconds,
            UpdateTime: nowSeconds,
            Affection: DefaultAffection,
            MarryTime: 0,
            CurHp: HpCoefficient,
            Mood: 100,
            MarryType: 0);
        var dock = new HeroDock([hero], BagSize: 200);
        var bag = new PlayerBag([], BagSize: 100);
        var fashion = new PlayerFashion([]);
        var equip = new PlayerEquip([], EquipBagSize: 2000);
        var fleet = DefaultFleet();
        return new PlayerAccount(profileId, character, dock, bag, fashion, equip, fleet,
            Building: DefaultBuilding(nowSeconds));
    }

    /// <summary>
    /// 默认开放二级办公室与一级宿舍。办公室升到二级是为了让客户端合法解锁宿舍所在的第六地块。
    /// </summary>
    public static PlayerBuilding DefaultBuilding(int nowSeconds) => new(
        Buildings:
        [
            new PlayerBuildingEntry(Id: 1, Tid: 2, Level: 2, HeroIds: [], LastUpdateTime: nowSeconds),
            new PlayerBuildingEntry(Id: 2, Tid: 41, Level: 1, HeroIds: [], LastUpdateTime: nowSeconds),
        ],
        Lands:
        [
            new PlayerBuildingLand(Index: 1, BuildingId: 1),
            new PlayerBuildingLand(Index: 6, BuildingId: 2),
        ]);

    /// <summary>创建默认5个空编队（Normal type=1, modeId 1-5）。名称留空，由客户端按当前语言本地化。</summary>
    public static PlayerFleet DefaultFleet()
    {
        var tactics = new List<FleetEntry>(5);
        for (int i = 1; i <= 5; i++)
        {
            tactics.Add(new FleetEntry(ModeId: i, Type: 1, TacticName: ""));
        }
        return new PlayerFleet(tactics);
    }
}

/// <summary>单个 GM 商品配置（数据驱动，来自 gm-goods.json）。</summary>
public sealed record GmGoodConfig(int GoodId, int ShopId, int Type, int ItemId, int Num);

/// <summary>GM 商品配置集合（商品列表 + 时装 FashionTid→SfId 映射）。</summary>
public sealed record GmGoodsConfig(
    IReadOnlyList<GmGoodConfig> Goods,
    IReadOnlyDictionary<int, int> FashionSfId);

/// <summary>GM 邮件奖励类型（标志位）：Currency = 货币，Item = 道具/材料。</summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum GmMailType
{
    Currency,
    Item,
}

/// <summary>单封 GM 邮件配置（数据驱动，来自 gm-mails.json）。
/// <see cref="Type"/> 为高级分类标志；<see cref="GoodsType"/> 是发给客户端的 GoodsType
/// （见 constants.lua，如 CURRENCY=5 / ITEM=1 / REWARD_SHIPLEVELUP_ITEM=15），客户端据此查
/// config_table_index[GoodsType].file_name 渲染图标；<see cref="ConfigId"/> 为该表内的 id。</summary>
public sealed record GmMailConfig(ulong Mid, GmMailType Type, int GoodsType, int ConfigId, int Num, string Subject, string Content);

/// <summary>GM 邮件配置集合。</summary>
public sealed record GmMailsConfig(IReadOnlyList<GmMailConfig> Mails);

/// <summary>单个编队条目（TTactic）。</summary>
public sealed record FleetEntry(
    int ModeId,
    int Type = 1,
    string TacticName = "",
    IReadOnlyList<int>? HeroInfo = null,
    IReadOnlyList<int>? ExHeroInfo = null,
    int StrategyId = 0,
    int FormationId = 2);

/// <summary>玩家编队集合（TSelfTactis）。</summary>
public sealed record PlayerFleet(
    IReadOnlyList<FleetEntry> Tactics,
    int MaxPower = 0,
    int MinPower = 0,
    bool IsSkip = false);

/// <summary>单个抽卡池中的船娘条目（TemplateId → 权重）。</summary>
public sealed record BuildShipEntry(int TemplateId, int Weight);

/// <summary>单个抽卡池配置（来自 config_build_ship）。</summary>
public sealed record BuildShipPool(int PoolId, IReadOnlyList<BuildShipEntry> Ships);

/// <summary>浴室中单个舰娘（TBathHeroInfo）。</summary>
public sealed record BathHero(
    uint HeroId,
    int Pos = 0,
    int IsAuto = 0,
    long StartTime = 0,
    long BathTime = 0,
    int BuffId = 0,
    long BuffTime = 0,
    int Power = 0);

/// <summary>浴室状态（TBathroomInfo）。</summary>
public sealed record PlayerBath(
    IReadOnlyList<BathHero> HeroList,
    int IsAllAuto = 0);
