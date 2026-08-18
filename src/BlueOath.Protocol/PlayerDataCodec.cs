using System.Text;

namespace BlueOath.Protocol;

/// <summary>
/// Resources consumed by a single build formula. Currently empty; extend with the
/// TBuildProject fields (Items/Gold) when real build data is needed.
/// </summary>
public sealed record BuildProject();

/// <summary>A single ship-building formula (building / builded / waiting).</summary>
public sealed record BuildFormula(long EndTime = 0, BuildProject? Project = null, int HeroId = 0);

/// <summary>Payload for the <c>build.BuildsInfo</c> server message.</summary>
public sealed record BuildsInfoRet(
    IReadOnlyList<BuildFormula>? BuildedList = null,
    IReadOnlyList<BuildFormula>? BuildingList = null,
    IReadOnlyList<BuildFormula>? WaitingList = null,
    BuildFormula? BuildedLast = null);

/// <summary>One hero currently taking a bath.</summary>
public sealed record BathHeroInfo(
    uint HeroId = 0, int Pos = 0, int IsAuto = 0, long StartTime = 0,
    long BathTime = 0, int BuffId = 0, long BuffTime = 0, int Power = 0);

/// <summary>Payload for the <c>bathroom.BathroomInfo</c> server message.</summary>
public sealed record BathroomInfo(IReadOnlyList<BathHeroInfo>? HeroList = null, int IsAllAuto = 0);

/// <summary>One hero owned by the player (THeroGrid). Extend with Equips/PSkill/CurHp/etc. as needed.</summary>
public sealed record HeroGrid(uint HeroId = 0, int TemplateId = 0, int Lvl = 0, int Fashioning = 0,
    int Exp = 0, int CreateTime = 0, int UpdateTime = 0, int Affection = 0, int MarryTime = 0,
    int CurHp = 0, int Mood = 0, int MarryType = 0);

/// <summary>Payload for the <c>hero.UpdateHeroBagData</c> server message (THeroInfo).</summary>
public sealed record HeroBag(IReadOnlyList<HeroGrid>? HeroInfo = null, int HeroBagSize = 0);

/// <summary>单个图鉴条目（TIllustrateInfo）。IllustrateId 即 config_ship_handbook 的 key = ship_info_id。</summary>
public sealed record IllustrateInfo(int IllustrateId = 0, long GetTime = 0, long LikeTime = 0,
    bool NewHero = false, IReadOnlyList<int>? BehaviourList = null, int MarryCount = 0);

/// <summary>图鉴装备条目（TIllustrateEquipInfo）。</summary>
public sealed record IllustrateEquipInfo(int EquipTemplateId = 0, long GetEquipTime = 0, bool NewEquip = false);

/// <summary>图鉴信息推送（TIllustrateInfoRet）。</summary>
public sealed record IllustrateInfoRet(
    IReadOnlyList<IllustrateInfo>? IllustrateList = null,
    IReadOnlyList<IllustrateEquipInfo>? IllustrateEquipList = null);

/// <summary>引导设置项（TGuideSetting，Key/Value 均为 string）。</summary>
public sealed record GuideSetting(string Key, string Value);

/// <summary>引导信息推送（TGuideInfo）。Setting 里用 GUIDE_DONE_STAGES/GUIDE_DOING_STAGE 标记引导进度。</summary>
public sealed record GuideInfo(
    IReadOnlyList<int>? FuncList = null,
    IReadOnlyList<int>? PlotList = null,
    IReadOnlyList<GuideSetting>? Setting = null);

/// <summary>商店单个商品（TShopGoodsData）。GoodsId 对应 config_shop_goods 的 id。</summary>
public sealed record ShopGoodsData(int GoodsId = 0, int Num = 0, int Status = 0);

/// <summary>商店推荐商品（TShopRecommend）。</summary>
public sealed record ShopRecommend(int Type = 0, int GoodId = 0, int Status = 0);

/// <summary>单个商店信息（TRetShopInfo）。</summary>
public sealed record RetShopInfo(int ShopId = 0, IReadOnlyList<ShopGoodsData>? ShopGoodsData = null,
    int UsedFRefreshNum = 0, int FRefreshNum = 0, int FRefreshTime = 0);

/// <summary>商店信息推送（TRetShopsInfo）。</summary>
public sealed record RetShopsInfo(
    IReadOnlyList<RetShopInfo>? ShopInfo = null,
    IReadOnlyList<ShopRecommend>? GoodList = null,
    IReadOnlyList<ShopRecommend>? CondGoodList = null);

/// <summary>通用奖励（TCommonReward）。Type 对应 GoodsType，ConfigId 对应物品/货币 id。</summary>
public sealed record CommonReward(int Type = 0, int ConfigId = 0, int Num = 0, int Id = 0);

/// <summary>仓库格子（TGridInfo）。</summary>
public sealed record BagGridInfo(int TemplateId = 0, int Num = 0);

/// <summary>仓库信息（TBagInfoRet）。bagType=BagType.ITEM_BAG/EQUIP_BAG。</summary>
public sealed record BagInfoRet(int BagType = 0, int BagSize = 0, IReadOnlyList<BagGridInfo>? BagInfo = null);

/// <summary>单个船型的时装解锁信息（TFashionInfo）。</summary>
public sealed record FashionInfo(int SfId = 0, IReadOnlyList<int>? FashionTid = null);

/// <summary>时装列表（TFashionList）。</summary>
public sealed record FashionList(IReadOnlyList<FashionInfo>? FashionInfo = null);

/// <summary>
/// Encodes the player-scope data pushed to the client after login (build queue, bathroom, ...).
/// Field numbers are taken from build_pb.lua / bathroom_pb.lua.
/// </summary>
public static class PlayerDataCodec
{
    public static byte[] Encode(BuildsInfoRet value)
    {
        using var output = new MemoryStream();
        if (value.BuildedList is not null)
            foreach (var item in value.BuildedList) WriteMessage(output, 1, Encode(item));
        if (value.BuildingList is not null)
            foreach (var item in value.BuildingList) WriteMessage(output, 2, Encode(item));
        if (value.WaitingList is not null)
            foreach (var item in value.WaitingList) WriteMessage(output, 3, Encode(item));
        if (value.BuildedLast is not null) WriteMessage(output, 4, Encode(value.BuildedLast));
        return output.ToArray();
    }

    public static byte[] Encode(BuildFormula value)
    {
        using var output = new MemoryStream();
        // EndTime is written explicitly (0 means "finished") so the client always sees a
        // number; BuildLogic.GetPushNoticeParams compares it and would error on nil.
        WriteVarintField(output, 1, unchecked((ulong)value.EndTime));
        if (value.Project is not null) WriteMessage(output, 2, Encode(value.Project));
        if (value.HeroId != 0) WriteVarintField(output, 3, unchecked((ulong)value.HeroId));
        return output.ToArray();
    }

    public static byte[] Encode(BuildProject _) => [];

    public static byte[] Encode(BathroomInfo value)
    {
        using var output = new MemoryStream();
        if (value.HeroList is not null)
            foreach (var item in value.HeroList) WriteMessage(output, 1, Encode(item));
        if (value.IsAllAuto != 0) WriteVarintField(output, 2, unchecked((ulong)value.IsAllAuto));
        return output.ToArray();
    }

    public static byte[] Encode(BathHeroInfo value)
    {
        using var output = new MemoryStream();
        // HeroId/StartTime are written explicitly so the client never sees nil; the notice
        // handler indexes args[1].HeroId and reads v.StartTime.
        WriteVarintField(output, 1, value.HeroId);
        if (value.Pos != 0) WriteVarintField(output, 2, unchecked((ulong)value.Pos));
        if (value.IsAuto != 0) WriteVarintField(output, 3, unchecked((ulong)value.IsAuto));
        WriteVarintField(output, 4, unchecked((ulong)value.StartTime));
        if (value.BathTime != 0) WriteVarintField(output, 5, unchecked((ulong)value.BathTime));
        if (value.BuffId != 0) WriteVarintField(output, 6, unchecked((ulong)value.BuffId));
        if (value.BuffTime != 0) WriteVarintField(output, 7, unchecked((ulong)value.BuffTime));
        if (value.Power != 0) WriteVarintField(output, 8, unchecked((ulong)value.Power));
        return output.ToArray();
    }

    public static byte[] Encode(HeroBag value)
    {
        using var output = new MemoryStream();
        if (value.HeroInfo is not null)
            foreach (var hero in value.HeroInfo) WriteMessage(output, 1, Encode(hero));
        if (value.HeroBagSize != 0) WriteVarintField(output, 2, unchecked((ulong)value.HeroBagSize));
        return output.ToArray();
    }

    public static byte[] Encode(HeroGrid value)
    {
        using var output = new MemoryStream();
        if (value.HeroId != 0) WriteVarintField(output, 1, value.HeroId);
        if (value.TemplateId != 0) WriteVarintField(output, 2, unchecked((ulong)value.TemplateId));
        // Equips (field 3, repeated): 1 dummy with type=0, no Equip field.
        // 不要编码空 Equip 消息(0x12 0x00)，否则被解码成一个空 EquipsInfo，
        // RefreshHeroEquipData 里 equip.EquipsId(nil) > 0 会崩溃。
        output.Write(new byte[] { 0x1A, 0x02, 0x08, 0x00 });
        if (value.Lvl != 0) WriteVarintField(output, 4, unchecked((ulong)value.Lvl));
        // Exp 必须无条件编码：girlinfo GirlShowPage._LoadPropertInfo 里
        // math.tointeger(Exp) .. "/" .. needExp 拼接，Exp 为 nil 会崩。
        WriteVarintField(output, 5, unchecked((ulong)value.Exp));
        if (value.CreateTime != 0) WriteVarintField(output, 8, unchecked((ulong)value.CreateTime));
        if (value.CurHp != 0) WriteVarintField(output, 9, unchecked((ulong)value.CurHp));
        // PSkill (field 13, repeated): 1 dummy with PSkillId=41210(valid config),
        // PSkillExp=0, Level=0, Replace=0. Replace 必须编码为 0，否则 nil ~= 0 为真，
        // GetReplaceSkillId 会 return nil，导致 GetPSkillName 里 config 查询为 nil 崩溃。
        output.Write(new byte[] { 0x6A, 0x0A, 0x08, 0xFA, 0xC1, 0x02, 0x10, 0x00, 0x18, 0x00, 0x20, 0x00 });
        if (value.Affection != 0) WriteVarintField(output, 17, unchecked((ulong)value.Affection));
        // Mood/MarryTime/MarryType 必须无条件编码：值为 0 时客户端读到 nil，
        // GetMoodNum/GetLoveInfo 里的算术/比较会崩溃。
        WriteVarintField(output, 18, unchecked((ulong)value.Mood));
        WriteVarintField(output, 19, unchecked((ulong)value.MarryTime));
        if (value.UpdateTime != 0) WriteVarintField(output, 20, unchecked((ulong)value.UpdateTime));
        WriteVarintField(output, 21, unchecked((ulong)value.MarryType));
        if (value.Fashioning != 0) WriteVarintField(output, 22, unchecked((ulong)value.Fashioning));
        return output.ToArray();
    }

    public static byte[] Encode(IllustrateInfoRet value)
    {
        using var output = new MemoryStream();
        if (value.IllustrateList is not null)
            foreach (var item in value.IllustrateList) WriteMessage(output, 1, Encode(item));
        if (value.IllustrateEquipList is not null)
            foreach (var item in value.IllustrateEquipList) WriteMessage(output, 9, Encode(item));
        return output.ToArray();
    }

    public static byte[] Encode(IllustrateInfo value)
    {
        using var output = new MemoryStream();
        if (value.IllustrateId != 0) WriteVarintField(output, 1, unchecked((ulong)value.IllustrateId));
        if (value.GetTime != 0) WriteVarintField(output, 2, unchecked((ulong)value.GetTime));
        // LikeTime 无条件编码：IsLike 里 `LikeTime ~= 0` 判断，nil ~= 0 为真会误判。
        WriteVarintField(output, 3, unchecked((ulong)value.LikeTime));
        if (value.NewHero) WriteVarintField(output, 4, 1);
        // BehaviourList (field 5, repeated int32)：至少编码一个 0 元素，避免 nil 导致 pairs(nil) 崩溃。
        if (value.BehaviourList is not null && value.BehaviourList.Count > 0)
            foreach (var id in value.BehaviourList) WriteVarintField(output, 5, unchecked((ulong)id));
        else
            WriteVarintField(output, 5, 0);
        // MarryCount 无条件编码：GetOwnShipNumByCamp 里 `0 < MarryCount`，nil 会崩。
        WriteVarintField(output, 6, unchecked((ulong)value.MarryCount));
        return output.ToArray();
    }

    public static byte[] Encode(IllustrateEquipInfo value)
    {
        using var output = new MemoryStream();
        if (value.EquipTemplateId != 0) WriteVarintField(output, 1, unchecked((ulong)value.EquipTemplateId));
        if (value.GetEquipTime != 0) WriteVarintField(output, 2, unchecked((ulong)value.GetEquipTime));
        if (value.NewEquip) WriteVarintField(output, 3, 1);
        return output.ToArray();
    }

    public static byte[] Encode(GuideInfo value)
    {
        using var output = new MemoryStream();
        // FuncList/PlotList（repeated int32）：至少一个 0 元素，避免 SetGuideData 里 #nil / pairs(nil) 崩溃。
        if (value.FuncList is not null && value.FuncList.Count > 0)
            foreach (var id in value.FuncList) WriteVarintField(output, 1, unchecked((ulong)id));
        else
            WriteVarintField(output, 1, 0);
        if (value.PlotList is not null && value.PlotList.Count > 0)
            foreach (var id in value.PlotList) WriteVarintField(output, 2, unchecked((ulong)id));
        else
            WriteVarintField(output, 2, 0);
        if (value.Setting is not null)
            foreach (var s in value.Setting) WriteMessage(output, 3, Encode(s));
        // Event（field 4, repeated TGuideEvent）：编码 Key=0,Value=0 的有效元素，
        // 空消息会解码成 [{}]，_SetGuideEventData 里 tblValue.Key=nil 报 "table index is nil"。
        WriteMessage(output, 4, new byte[] { 0x08, 0x00, 0x10, 0x00 });
        return output.ToArray();
    }

    public static byte[] Encode(GuideSetting value)
    {
        using var output = new MemoryStream();
        WriteMessage(output, 1, Encoding.UTF8.GetBytes(value.Key));
        WriteMessage(output, 2, Encoding.UTF8.GetBytes(value.Value));
        return output.ToArray();
    }

    public static byte[] Encode(RetShopsInfo value)
    {
        using var output = new MemoryStream();
        if (value.ShopInfo is not null)
            foreach (var item in value.ShopInfo) WriteMessage(output, 1, Encode(item));
        // GoodList/CondGoodList 只在有值时才编码。空消息会被解码成单个空元素（Info.Type/GoodId=nil），
        // 导致 SetShopsInfo 里 "table index is nil" 或 GetRecommendShopGoods 里 clone(nil) 崩溃。
        if (value.GoodList is not null)
            foreach (var item in value.GoodList) WriteMessage(output, 2, Encode(item));
        if (value.CondGoodList is not null)
            foreach (var item in value.CondGoodList) WriteMessage(output, 3, Encode(item));
        return output.ToArray();
    }

    public static byte[] Encode(RetShopInfo value)
    {
        using var output = new MemoryStream();
        if (value.ShopId != 0) WriteVarintField(output, 1, unchecked((ulong)value.ShopId));
        // ShopGoodsData（field 3, repeated）：必须非 nil（GetShopInfoById 里 #nil 崩溃），至少一个空元素。
        if (value.ShopGoodsData is not null && value.ShopGoodsData.Count > 0)
            foreach (var item in value.ShopGoodsData) WriteMessage(output, 3, Encode(item));
        else
            WriteMessage(output, 3, []);
        // UsedFRefreshNum/FRefreshNum/FRefreshTime 无条件编码：ShopItemShow._SetFreeRefresh 里
        // `UsedFRefreshNum < init_times` 比较，nil 会崩。
        WriteVarintField(output, 4, unchecked((ulong)value.UsedFRefreshNum));
        WriteVarintField(output, 5, unchecked((ulong)value.FRefreshNum));
        WriteVarintField(output, 6, unchecked((ulong)value.FRefreshTime));
        return output.ToArray();
    }

    public static byte[] Encode(ShopGoodsData value)
    {
        using var output = new MemoryStream();
        if (value.GoodsId != 0) WriteVarintField(output, 1, unchecked((ulong)value.GoodsId));
        // Num/Status 无条件编码：ShopItemShow._SetShopGoodsStock 里
        // math.tointeger(goodSerData.Num) 做减法，nil 会崩。
        WriteVarintField(output, 2, unchecked((ulong)value.Num));
        WriteVarintField(output, 3, unchecked((ulong)value.Status));
        return output.ToArray();
    }

    public static byte[] Encode(ShopRecommend value)
    {
        using var output = new MemoryStream();
        if (value.Type != 0) WriteVarintField(output, 1, unchecked((ulong)value.Type));
        if (value.GoodId != 0) WriteVarintField(output, 2, unchecked((ulong)value.GoodId));
        if (value.Status != 0) WriteVarintField(output, 3, unchecked((ulong)value.Status));
        return output.ToArray();
    }

    public static byte[] Encode(CommonReward value)
    {
        using var output = new MemoryStream();
        if (value.Type != 0) WriteVarintField(output, 1, unchecked((ulong)value.Type));
        if (value.ConfigId != 0) WriteVarintField(output, 2, unchecked((ulong)value.ConfigId));
        if (value.Num != 0) WriteVarintField(output, 3, unchecked((ulong)value.Num));
        if (value.Id != 0) WriteVarintField(output, 4, unchecked((ulong)value.Id));
        return output.ToArray();
    }

    public static byte[] Encode(BagInfoRet value)
    {
        using var output = new MemoryStream();
        if (value.BagType != 0) WriteVarintField(output, 1, unchecked((ulong)value.BagType));
        if (value.BagSize != 0) WriteVarintField(output, 2, unchecked((ulong)value.BagSize));
        if (value.BagInfo is not null)
            foreach (var item in value.BagInfo) WriteMessage(output, 3, Encode(item));
        return output.ToArray();
    }

    public static byte[] Encode(BagGridInfo value)
    {
        using var output = new MemoryStream();
        if (value.TemplateId != 0) WriteVarintField(output, 1, unchecked((ulong)value.TemplateId));
        if (value.Num != 0) WriteVarintField(output, 2, unchecked((ulong)value.Num));
        return output.ToArray();
    }

    public static byte[] Encode(FashionList value)
    {
        using var output = new MemoryStream();
        if (value.FashionInfo is not null)
            foreach (var item in value.FashionInfo) WriteMessage(output, 1, Encode(item));
        return output.ToArray();
    }

    public static byte[] Encode(FashionInfo value)
    {
        using var output = new MemoryStream();
        if (value.SfId != 0) WriteVarintField(output, 1, unchecked((ulong)value.SfId));
        if (value.FashionTid is not null)
            foreach (var tid in value.FashionTid) WriteVarintField(output, 2, unchecked((ulong)tid));
        return output.ToArray();
    }

    private static void WriteMessage(Stream output, int field, byte[] body)
    {
        WriteVarint(output, (ulong)((field << 3) | 2));
        WriteVarint(output, (ulong)body.Length);
        output.Write(body);
    }

    private static void WriteVarintField(Stream output, int field, ulong value)
    {
        WriteVarint(output, (ulong)(field << 3));
        WriteVarint(output, value);
    }

    private static void WriteVarint(Stream output, ulong value)
    {
        while (value >= 0x80)
        {
            output.WriteByte((byte)(value | 0x80));
            value >>= 7;
        }
        output.WriteByte((byte)value);
    }
}
