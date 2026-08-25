namespace BlueOath.Protocol;

/// <summary>TBuyGoodsArg: ShopId(1, int32) / GoodId(2, int32) / BuyNum(3, int32) / PriceIndex(5, int32)。</summary>
public sealed record BuyGoodsArg(int ShopId = 0, int GoodId = 0, int BuyNum = 0, int PriceIndex = 0);

/// <summary>TQualityBuyGoodsArg: ShopId(1, int32) / GoodIdList(2, repeated int32)。</summary>
public sealed record QualityBuyGoodsArg(int ShopId = 0, IReadOnlyList<int> GoodIdList = null!);

/// <summary>THeroChangeEquipArgs: HeroId(1, uint32) / Index(2, int32) / EquipId(3, uint32) / Type(4, int32)。</summary>
public sealed record HeroChangeEquipArgs(uint HeroId = 0, int Index = 0, uint EquipId = 0, int Type = 0);
