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
    uint SecretaryId);

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

/// <summary>
/// 玩家账号聚合（角色 + 船坞）。存档数据库中实际存在的实体根，后续如需加入建造/浴室/
/// 建筑等玩家域数据，可在此扩展新的成员（保持向后兼容：新增可选字段或子实体）。
/// </summary>
public sealed record PlayerAccount(
    string ProfileId,
    PlayerCharacter Character,
    HeroDock Dock);

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

    /// <summary>创建新档案的默认账号（角色 + 含一只秘书舰的船坞）。</summary>
    public static PlayerAccount CreateDefault(string profileId, int nowSeconds)
    {
        var character = new PlayerCharacter(Uid: 1, Name: profileId, Level: 1, Class: 1, SecretaryId: 1);
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
        return new PlayerAccount(profileId, character, dock);
    }
}
