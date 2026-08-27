namespace BlueOath.Server.Protocols;

/// <summary>
/// 客户端请求参数实体（T*Arg，protobuf 解码产物）。
/// 与 <see cref="ProtocolDecoder"/> 的解码方法一一对应，字段注释标注客户端消息的 wire 字段号。
/// </summary>

/// <summary>TStartBaseArg（copy.StartBase）: CopyId(2) / IsRunningFight(3) / BattleMode(9) / MatchType(15)
/// / HeroList(13, repeated TStartBaseHeroList → HeroIdList(1))。</summary>
internal sealed record StartBaseArg(
    int CopyId = 0,
    List<int>? DeployHeroIds = null,
    bool IsRunningFight = false,
    int BattleMode = 0,
    int MatchType = 0);

/// <summary>TBuildShipArg（buildship.BuildShip）: Id(1, int32) / Num(2, int32) / CacheId(3, string)。</summary>
internal sealed record BuildShipArg(int Id = 0, int Num = 1, string CacheId = "");

/// <summary>道具 + 数量（用于 THeroAddExpArg.Items 与 hero.AddExp 响应，字段 ItemId(2)/Num(3)）。</summary>
internal sealed record ItemCount(int Id = 0, int Num = 0);

/// <summary>THeroAddExpArg（hero.AddExp）: HeroId(1, uint32) / Items(2, repeated {ItemId(2), Num(3)})。</summary>
internal sealed record HeroAddExpArg(uint HeroId = 0, List<ItemCount> Items = null!);

/// <summary>THeroMarryArg（hero.Marry）: HeroId(1, uint32) / MarryType(2, int32)。</summary>
internal sealed record MarryArg(uint HeroId = 0, int MarryType = 1);

/// <summary>TLockHeroArg（hero.LockHero）: HeroId(1, uint32) / Lock(2, bool)。</summary>
internal sealed record LockHeroArg(uint HeroId = 0, bool Lock = false);

/// <summary>TRetireHeroArg（hero.RetireHero）: HeroIds(1, repeated uint32) / IsDisEquip(2, bool)。</summary>
internal sealed record RetireHeroArg(List<uint> HeroIds, bool IsDisEquip = false);

/// <summary>TChangeHeroNameArg（hero.ChangeName）: HeroId(1, uint32) / Name(2, string)。</summary>
internal sealed record ChangeHeroNameArg(uint HeroId = 0, string Name = "");

/// <summary>THeroAddAffectionArg（hero.AddAffection）: HeroId(1, uint32) / TemplateId(2, int32) / Num(3, int32)。</summary>
internal sealed record HeroAddAffectionArg(uint HeroId = 0, int TemplateId = 0, int Num = 0);

/// <summary>TRemouldArg（hero.HeroRemould）: HeroId(1, uint32) / EffectId(2, int32)。</summary>
internal sealed record HeroRemouldArg(uint HeroId = 0, int EffectId = 0);

/// <summary>TFashionEquipArg（fashion.Equip）: FashionTid(1, int32) / EquipStatus(2, int32) / HeroId(3, uint32)。</summary>
internal sealed record FashionEquipArg(int FashionTid = 0, int EquipStatus = 0, uint HeroId = 0);
