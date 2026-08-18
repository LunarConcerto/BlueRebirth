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
    int ActivityBattlePassExp = 0);

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
    int CurHp = 0,
    int Mood = 0,
    int MarryType = 0);

/// <summary>
/// 船坞（玩家拥有的全部舰娘）。对应 <c>hero.UpdateHeroBagData</c> 的 HeroBag
/// （HeroInfo + HeroBagSize）。
/// </summary>
public sealed record HeroDock(
    IReadOnlyList<Hero> Heroes,
    int BagSize = 100);

/// <summary>仓库中的单个道具堆叠（TGridInfo）。</summary>
public sealed record BagItem(int TemplateId, int Num);

/// <summary>玩家仓库（道具/材料等）。对应 bag.GetBagInfo / bag.UpdateBagData 的 TBagInfoRet。</summary>
public sealed record PlayerBag(IReadOnlyList<BagItem> Items, int BagSize = 100);

/// <summary>时装解锁项（TFashionInfo：船型 SfId + 已解锁时装列表）。</summary>
public sealed record FashionEntry(int SfId, IReadOnlyList<int> FashionTids);

/// <summary>玩家已解锁时装（通用解锁状态，对船坞里同 SfId 的所有角色生效）。</summary>
public sealed record PlayerFashion(IReadOnlyList<FashionEntry> Entries);

/// <summary>
/// 玩家账号聚合（角色 + 船坞 + 仓库 + 时装）。存档数据库中实际存在的实体根，
/// 后续如需加入建造/浴室/建筑等玩家域数据，可在此扩展新的成员（保持向后兼容：
/// 新增可选字段或子实体）。
/// </summary>
public sealed record PlayerAccount(
    string ProfileId,
    PlayerCharacter Character,
    HeroDock Dock,
    PlayerBag? Bag = null,
    PlayerFashion? Fashion = null);

/// <summary>
/// 账号实体的默认工厂：集中定义新档案的初始角色与船坞，便于后续调整默认数值。
/// </summary>
public static class PlayerAccountFactory
{
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

    /// <summary>创建新档案的默认账号（角色 + 含一只秘书舰的船坞 + 空仓库/时装）。</summary>
    public static PlayerAccount CreateDefault(string profileId, int nowSeconds)
    {
        var character = new PlayerCharacter(Uid: 1, Name: profileId, Level: 1, Class: 1, SecretaryId: 1,
            CreateTime: nowSeconds, Gold: DefaultGold, Diamond: DefaultDiamond, Supply: DefaultSupply,
            PvePt: 100);
        var hero = new Hero(
            HeroId: 1,
            TemplateId: DefaultHeroTemplateId,
            Level: 1,
            Fashioning: DefaultHeroFashioning,
            Exp: 0,
            CreateTime: nowSeconds,
            UpdateTime: nowSeconds,
            Affection: 1000,
            MarryTime: 0,
            CurHp: 1000,
            Mood: 0,
            MarryType: 0);
        var dock = new HeroDock([hero], BagSize: 100);
        var bag = new PlayerBag([], BagSize: 100);
        var fashion = new PlayerFashion([]);
        return new PlayerAccount(profileId, character, dock, bag, fashion);
    }
}

/// <summary>单个 GM 商品配置（数据驱动，来自 gm-goods.json）。</summary>
public sealed record GmGoodConfig(int GoodId, int ShopId, int Type, int ItemId, int Num);

/// <summary>GM 商品配置集合（商品列表 + 时装 FashionTid→SfId 映射）。</summary>
public sealed record GmGoodsConfig(
    IReadOnlyList<GmGoodConfig> Goods,
    IReadOnlyDictionary<int, int> FashionSfId);

/// <summary>单封 GM 邮件配置（数据驱动，来自 gm-mails.json）。</summary>
public sealed record GmMailConfig(ulong Mid, int CurrencyType, int Num, string Subject, string Content);

/// <summary>GM 邮件配置集合。</summary>
public sealed record GmMailsConfig(IReadOnlyList<GmMailConfig> Mails);
