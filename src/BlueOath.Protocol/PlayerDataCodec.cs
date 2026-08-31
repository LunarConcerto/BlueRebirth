using System.Text;

namespace BlueOath.Protocol;

/// <summary>单个技能记录（PSkillId → Level/Exp）。</summary>
public sealed class PSkillEntry
{
    public uint PSkillId { get; set; }
    public uint PSkillExp { get; set; }
    public int Level { get; set; }
    public int Replace { get; set; }

    public PSkillEntry() { }
    public PSkillEntry(uint pSkillId, uint pSkillExp = 0, int level = 0, int replace = 0)
    {
        PSkillId = pSkillId;
        PSkillExp = pSkillExp;
        Level = level;
        Replace = replace;
    }

    public override string ToString() {
        return
            $"{nameof(PSkillId)}: {PSkillId}, {nameof(PSkillExp)}: {PSkillExp}, {nameof(Level)}: {Level}, {nameof(Replace)}: {Replace}";
    }
}

/// <summary>Resources consumed by a single traditional build formula.</summary>
public sealed record BuildItem(int ResId = 0, int Count = 0);

/// <summary>A traditional build formula containing item materials and gold.</summary>
public sealed record BuildProject(IReadOnlyList<BuildItem>? Items = null, int Gold = 0);

/// <summary>A single ship-building formula (building / builded / waiting).</summary>
public sealed record BuildFormula(long EndTime = 0, BuildProject? Project = null, int HeroId = 0);

/// <summary>建造配方墙单条记录（buildnotes.GetNotesList）。</summary>
public sealed record NotesInfo(
    string Name = "",
    BuildFormula? BuildedInfo = null,
    int Count = 0,
    int Head = 0,
    ulong Uid = 0);

/// <summary>建造配方墙（buildnotes.GetNotesList / GiveLike 响应）。</summary>
public sealed record NotesListRet(IReadOnlyList<NotesInfo>? List = null);

/// <summary>图鉴评价单条评论（discuss_pb.TMsgInfo）。</summary>
public sealed record DiscussMsgInfo(
    string Name = "",
    string Msg = "",
    int LikeNum = 0,
    int MsgID = 0,
    long LikeTime = 0,
    long IsLiked = 0,
    long IsDisLiked = 0,
    int Level = 0);

/// <summary>图鉴评价数据（discuss_pb.TGetDiscussRet）。</summary>
public sealed record DiscussRet(
    int DisLikeNum = 0,
    long DisLikeTime = 0,
    long MsgTime = 0,
    int HeroLikeNum = 0,
    IReadOnlyList<DiscussMsgInfo>? MsgInfo = null);

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

/// <summary>基地地图上的单个地块（TLandInfo）。</summary>
public sealed record BuildingLandInfo(int Index = 0, int BuildingId = 0);

/// <summary>基地中的单栋建筑（TBuildingInfo）。当前离线切片不启用生产字段。</summary>
public sealed record BuildingInfo(
    int Id = 0,
    int Tid = 0,
    int Level = 0,
    IReadOnlyList<uint>? HeroList = null,
    int Status = 1,
    long LastUpdateTime = 0,
    long LastBuildUpdateTime = 0);

/// <summary>building.UpdateBuildingInfo 的完整基地快照（TUserBuildingInfo）。</summary>
public sealed record UserBuildingInfo(
    IReadOnlyList<BuildingInfo>? BuildingInfos = null,
    IReadOnlyList<BuildingLandInfo>? LandList = null,
    int WorkerStrength = 1_000_000,
    int WorkerRecover = 10,
    int FoodMax = 100,
    int ElectricMax = 100,
    long WorkerUpdateTime = 0);

/// <summary>building.SetHero 请求（TSetHeroArg）。</summary>
public sealed record SetBuildingHeroArg(int BuildingId, IReadOnlyList<uint> HeroIds);

/// <summary>building.SetBuildingListHero 请求（TSetBuildingListHeroArg）。HeroIds 以 -1 分隔每栋建筑。</summary>
public sealed record SetBuildingListHeroArg(IReadOnlyList<int> BuildingIds, IReadOnlyList<int> HeroIds);

/// <summary>building.AddBuilding 请求（TAddBuildingArg）。</summary>
public sealed record AddBuildingArg(int Tid, int Index);

/// <summary>One hero owned by the player (THeroGrid). Extend with Equips/PSkill/CurHp/etc. as needed.</summary>
public sealed record HeroGrid(uint HeroId = 0, int TemplateId = 0, int Lvl = 0, int Fashioning = 0,
    int Exp = 0, int CreateTime = 0, int UpdateTime = 0, int Affection = 0, int MarryTime = 0,
    long CurHp = 0, int Mood = 0, int MarryType = 0, IReadOnlyList<uint>? EquipSlots = null, string Name = "",
    int ChangeNameTime = 0, bool Lock = false, int Advance = 0, int AdvLv = 0,
    IReadOnlyList<PSkillEntry>? PSkills = null, IReadOnlyList<int>? ArrRemouldEffect = null,
    int RemouldLV = 0);

/// <summary>Payload for the <c>hero.UpdateHeroBagData</c> server message (THeroInfo).</summary>
public sealed record HeroBag(IReadOnlyList<HeroGrid>? HeroInfo = null, int HeroBagSize = 0);

/// <summary>单个图鉴条目（TIllustrateInfo）。IllustrateId 即 config_ship_handbook 的 key = ship_info_id。</summary>
public sealed record IllustrateInfo(int IllustrateId = 0, long GetTime = 0, long LikeTime = 0,
    bool NewHero = false, IReadOnlyList<int>? BehaviourList = null, int MarryCount = 0);

/// <summary>图鉴装备条目（TIllustrateEquipInfo）。</summary>
public sealed record IllustrateEquipInfo(int EquipTemplateId = 0, long GetEquipTime = 0, bool NewEquip = false);

/// <summary>已解锁的个人剧情（THeroMemory）。HeroId 对应 config_building_character_story.ship_fleet_id。</summary>
public sealed record HeroMemory(uint HeroId = 0, int PlotId = 0);

/// <summary>活动剧情回顾进度（TMemoryInfo）。Index 为该章节已解锁的剧情节点数。</summary>
public sealed record ChapterMemory(int ChapterId = 0, int Index = 0);

/// <summary>活动剧情回顾列表（TMemoryList）。</summary>
public sealed record StoryMemoryList(IReadOnlyList<ChapterMemory>? MemoryList = null);

/// <summary>图鉴信息推送（TIllustrateInfoRet）。</summary>
public sealed record IllustrateInfoRet(
    IReadOnlyList<IllustrateInfo>? IllustrateList = null,
    IReadOnlyList<IllustrateEquipInfo>? IllustrateEquipList = null,
    IReadOnlyList<HeroMemory>? HeroMemoryList = null);

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

/// <summary>每日副本单章节数据（dailycopy_pb.TDailyCopyInfo）。</summary>
public sealed record DailyCopyInfo(
    int ChapterId = 0,
    int ChallengeTimes = 0,
    IReadOnlyList<int>? PassCopy = null,
    bool SelectEx = false,
    int ExStar = 0);

/// <summary>每日副本组计数（dailycopy_pb.TDailyGroupInfo）。</summary>
public sealed record DailyCopyGroupInfo(int DailyGroupId = 0, int SuccessTimes = 0);

/// <summary>每日副本完整快照（dailycopy_pb.TUserDailyCopyInfo）。</summary>
public sealed record UserDailyCopyInfo(
    IReadOnlyList<DailyCopyInfo>? ArrDailyCopyInfo = null,
    IReadOnlyList<DailyCopyGroupInfo>? ArrDailyGroupInfo = null,
    IReadOnlyList<DailyCopyGroupInfo>? ArrDailyUpGroupInfo = null);

/// <summary>仓库格子（TGridInfo）。</summary>
public sealed record BagGridInfo(int TemplateId = 0, int Num = 0);

/// <summary>仓库信息（TBagInfoRet）。bagType=BagType.ITEM_BAG/EQUIP_BAG。</summary>
public sealed record BagInfoRet(int BagType = 0, int BagSize = 0, IReadOnlyList<BagGridInfo>? BagInfo = null);

/// <summary>普通宝箱使用参数（TBagNormalTreasureInfoArg）。</summary>
public sealed record BagNormalTreasureInfoArg(int TreasureId = 0, int TreasureNum = 0);

/// <summary>宝箱开启结果（TBagTreasureInfoRet）。</summary>
public sealed record BagTreasureInfoRet(
    IReadOnlyList<CommonReward>? TreasuresInfo = null, int TreasureId = 0);

/// <summary>单个船型的时装解锁信息（TFashionInfo）。</summary>
public sealed record FashionInfo(int SfId = 0, IReadOnlyList<int>? FashionTid = null);

/// <summary>时装列表（TFashionList）。</summary>
public sealed record FashionList(IReadOnlyList<FashionInfo>? FashionInfo = null);

/// <summary>单个装备实例（TEquipInfo）。字段号取自 equip_pb.lua。</summary>
public sealed record EquipInfo(uint EquipId = 0, int TemplateId = 0, int EnhanceLv = 0,
    int Star = 0, uint HeroId = 0, int EnhanceExp = 0);

/// <summary>装备仓库推送（TEquipList）。EquipNum 可选，客户端补零。</summary>
public sealed record EquipList(int EquipBagSize = 0,
    IReadOnlyList<EquipInfo>? EquipInfo = null,
    IReadOnlyList<EquipNum>? EquipNum = null);

/// <summary>装备数量统计（TEquipNum）。</summary>
public sealed record EquipNum(int TemplateId = 0, int Num = 0);

/// <summary>HeroGrid 装备槽信息（EquipsInfo）。EquipsId=0 表示空槽。</summary>
public sealed record EquipsInfo(uint EquipsId = 0, int State = 0);

/// <summary>HeroGrid 按舰队类型分组的装备列表（EquipsInfoByType）。</summary>
public sealed record EquipsInfoByType(int Type = 1, IReadOnlyList<EquipsInfo>? Equip = null);

/// <summary>邮件附件条目（TMailItem）。Type 对应 GoodsType，Id 对应货币/物品 id。</summary>
public sealed record MailItem(int Type = 0, int Id = 0, int Num = 0);

/// <summary>单封邮件（MailList）。TempLateId=0 时直接显示 Subject/Content。</summary>
public sealed record MailList(ulong Mid = 0, int TempLateId = 0, string Subject = "", string Content = "",
    long ReceiveTime = 0, long ReadTime = 0, int IsGotReawrd = 0,
    IReadOnlyList<MailItem>? Items = null, int DeleteTime = 0);

/// <summary>邮件列表响应（TMailListRet）。Reward 为领取后发放的奖励。</summary>
public sealed record MailListRet(int MailNum = 0, int ExpireNum = 0,
    IReadOnlyList<MailList>? List = null, IReadOnlyList<CommonReward>? Reward = null);

/// <summary>
/// Encodes the player-scope data pushed to the client after login (build queue, bathroom, ...).
/// Field numbers are taken from build_pb.lua / bathroom_pb.lua.
/// </summary>
public static class PlayerDataCodec
{
    /// <summary>编码 dailycopy.UpdateDailyCopyData 的完整玩家快照。</summary>
    public static byte[] Encode(UserDailyCopyInfo value)
    {
        using var output = new MemoryStream();
        if (value.ArrDailyCopyInfo is not null)
            foreach (DailyCopyInfo chapter in value.ArrDailyCopyInfo)
                WriteMessage(output, 1, Encode(chapter));
        if (value.ArrDailyGroupInfo is not null)
            foreach (DailyCopyGroupInfo group in value.ArrDailyGroupInfo)
                WriteMessage(output, 2, Encode(group));
        if (value.ArrDailyUpGroupInfo is not null)
            foreach (DailyCopyGroupInfo group in value.ArrDailyUpGroupInfo)
                WriteMessage(output, 3, Encode(group));
        return output.ToArray();
    }

    public static byte[] Encode(DailyCopyInfo value)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, unchecked((ulong)value.ChapterId));
        WriteVarintField(output, 2, unchecked((ulong)value.ChallengeTimes));
        if (value.PassCopy is not null)
            foreach (int copyId in value.PassCopy)
                WriteVarintField(output, 3, unchecked((ulong)copyId));
        WriteVarintField(output, 4, value.SelectEx ? 1UL : 0UL);
        WriteVarintField(output, 5, unchecked((ulong)value.ExStar));
        return output.ToArray();
    }

    public static byte[] Encode(DailyCopyGroupInfo value)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, unchecked((ulong)value.DailyGroupId));
        WriteVarintField(output, 2, unchecked((ulong)value.SuccessTimes));
        return output.ToArray();
    }

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

    /// <summary>编码 buildnotes.GetNotesList 响应（TNotesListRet: List(1, repeated TNotesInfo)）。</summary>
    public static byte[] Encode(NotesListRet value)
    {
        using var output = new MemoryStream();
        if (value.List is not null)
            foreach (NotesInfo note in value.List) WriteMessage(output, 1, Encode(note));
        return output.ToArray();
    }

    /// <summary>编码单条配方墙记录（TNotesInfo: Name(1)/BuildedInfo(2)/Count(3)/Head(4)/Uid(5)）。
    /// Count/Head/Uid 必须无条件编码：客户端 _LoadNotes 里 math.modf(Count) 对 nil 会崩。</summary>
    public static byte[] Encode(NotesInfo value)
    {
        using var output = new MemoryStream();
        if (!string.IsNullOrEmpty(value.Name)) WriteStringField(output, 1, value.Name);
        if (value.BuildedInfo is not null) WriteMessage(output, 2, Encode(value.BuildedInfo));
        WriteVarintField(output, 3, unchecked((ulong)value.Count));
        WriteVarintField(output, 4, unchecked((ulong)value.Head));
        WriteVarintField(output, 5, value.Uid);
        return output.ToArray();
    }

    /// <summary>编码图鉴评价响应（TGetDiscussRet: DisLikeNum(1)/DisLikeTime(2)/MsgTime(3)/HeroLikeNum(4)/MsgInfo(5)）。</summary>
    public static byte[] Encode(DiscussRet value)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, unchecked((ulong)value.DisLikeNum));
        WriteVarintField(output, 2, unchecked((ulong)value.DisLikeTime));
        WriteVarintField(output, 3, unchecked((ulong)value.MsgTime));
        WriteVarintField(output, 4, unchecked((ulong)value.HeroLikeNum));
        if (value.MsgInfo is not null)
            foreach (DiscussMsgInfo m in value.MsgInfo) WriteMessage(output, 5, Encode(m));
        return output.ToArray();
    }

    /// <summary>编码单条评论（TMsgInfo: Name(1)/Msg(2)/LikeNum(3)/MsgID(4)/LikeTime(5)/IsLiked(6)/IsDisLiked(7)/Level(8)）。
    /// 数值字段全部无条件编码，客户端 _getUILikeNum/IsLiked 比较对 nil 会崩。</summary>
    public static byte[] Encode(DiscussMsgInfo value)
    {
        using var output = new MemoryStream();
        if (!string.IsNullOrEmpty(value.Name)) WriteStringField(output, 1, value.Name);
        if (!string.IsNullOrEmpty(value.Msg)) WriteStringField(output, 2, value.Msg);
        WriteVarintField(output, 3, unchecked((ulong)value.LikeNum));
        WriteVarintField(output, 4, unchecked((ulong)value.MsgID));
        WriteVarintField(output, 5, unchecked((ulong)value.LikeTime));
        WriteVarintField(output, 6, unchecked((ulong)value.IsLiked));
        WriteVarintField(output, 7, unchecked((ulong)value.IsDisLiked));
        WriteVarintField(output, 8, unchecked((ulong)value.Level));
        return output.ToArray();
    }

    public static byte[] Encode(BuildProject value)
    {
        using var output = new MemoryStream();
        if (value.Items is not null)
            foreach (BuildItem item in value.Items) WriteMessage(output, 1, Encode(item));
        // 客户端会直接读取 Project.Gold，即使为 0 也必须显式编码。
        WriteVarintField(output, 2, unchecked((ulong)value.Gold));
        return output.ToArray();
    }

    public static byte[] Encode(BuildItem value)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, unchecked((ulong)value.ResId));
        WriteVarintField(output, 2, unchecked((ulong)value.Count));
        return output.ToArray();
    }

    public static byte[] Encode(BathroomInfo value)
    {
        using var output = new MemoryStream();
        // HeroList(field 1) must always be encoded (even empty) so SetData
        // receives a non-nil table; pairs(nil) crashes via readonlymeta.lua.
        if (value.HeroList is { Count: > 0 })
            foreach (var item in value.HeroList) WriteMessage(output, 1, Encode(item));
        else
            WriteMessage(output, 1, []); // encode empty HeroList to prevent nil
        if (value.IsAllAuto != 0) WriteVarintField(output, 2, unchecked((ulong)value.IsAllAuto));
        return output.ToArray();
    }

    public static byte[] Encode(BathHeroInfo value)
    {
        using var output = new MemoryStream();
        // HeroId/StartTime/BuffId 无条件编码：客户端 GetBathAttrBuff 用 `heroBath.BuffId == 0`
        // 判断，缺失字段解码为 nil 时 `nil == 0` 为 false，会误入 else 分支查 config_value_effect(nil) 崩溃。
        // BathTime/BuffTime 在算术中出现（`heroBath.BuffTime + buffInfo.time`），nil 也会崩。
        WriteVarintField(output, 1, value.HeroId);
        if (value.Pos != 0) WriteVarintField(output, 2, unchecked((ulong)value.Pos));
        if (value.IsAuto != 0) WriteVarintField(output, 3, unchecked((ulong)value.IsAuto));
        WriteVarintField(output, 4, unchecked((ulong)value.StartTime));
        WriteVarintField(output, 5, unchecked((ulong)value.BathTime));
        WriteVarintField(output, 6, unchecked((ulong)value.BuffId));
        WriteVarintField(output, 7, unchecked((ulong)value.BuffTime));
        if (value.Power != 0) WriteVarintField(output, 8, unchecked((ulong)value.Power));
        return output.ToArray();
    }

    // ── Building snapshot encoding / C2S argument decoding ──

    public static byte[] Encode(UserBuildingInfo value)
    {
        using var output = new MemoryStream();
        if (value.BuildingInfos is not null)
            foreach (BuildingInfo building in value.BuildingInfos)
                WriteMessage(output, 1, Encode(building));
        if (value.LandList is not null)
            foreach (BuildingLandInfo land in value.LandList)
                WriteMessage(output, 2, Encode(land));

        WriteVarintField(output, 3, unchecked((ulong)value.WorkerStrength));
        WriteVarintField(output, 4, unchecked((ulong)value.WorkerRecover));
        WriteVarintField(output, 5, 0); // Food: no offline upkeep.
        WriteVarintField(output, 6, unchecked((ulong)value.FoodMax));
        WriteVarintField(output, 7, 0); // Electric: no offline consumption.
        WriteVarintField(output, 8, unchecked((ulong)value.ElectricMax));
        WriteVarintField(output, 9, unchecked((ulong)value.WorkerUpdateTime));
        WriteVarintField(output, 10, unchecked((ulong)value.WorkerUpdateTime));
        return output.ToArray();
    }

    public static byte[] Encode(BuildingInfo value)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, unchecked((ulong)value.Id));
        WriteVarintField(output, 2, unchecked((ulong)value.Tid));
        WriteVarintField(output, 3, unchecked((ulong)value.Level));
        if (value.HeroList is not null)
            foreach (uint heroId in value.HeroList)
                WriteVarintField(output, 4, heroId);
        WriteVarintField(output, 5, 0); // Productivity
        WriteVarintField(output, 6, 0); // ProduceSpeed
        WriteVarintField(output, 7, 0); // ProductCount
        WriteVarintField(output, 8, unchecked((ulong)value.Status));
        WriteVarintField(output, 9, unchecked((ulong)value.LastUpdateTime));
        WriteVarintField(output, 10, 0); // RecipeId
        WriteVarintField(output, 11, 0); // ItemCount
        WriteVarintField(output, 12, unchecked((ulong)value.LastUpdateTime));
        WriteVarintField(output, 13, unchecked((ulong)value.LastBuildUpdateTime));
        WriteVarintField(output, 15, 0); // RecipeTime
        WriteVarintField(output, 16, 0); // FloatCount
        return output.ToArray();
    }

    public static byte[] Encode(BuildingLandInfo value)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, unchecked((ulong)value.Index));
        WriteVarintField(output, 2, unchecked((ulong)value.BuildingId));
        return output.ToArray();
    }

    public static SetBuildingHeroArg DecodeSetBuildingHeroArg(ReadOnlySpan<byte> payload)
    {
        int buildingId = 0;
        var heroIds = new List<uint>();
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
        {
            switch (field)
            {
                case 1 when wire == 0:
                    buildingId = checked((int)reader.ReadVarint());
                    break;
                case 2 when wire == 0:
                    heroIds.Add(checked((uint)reader.ReadVarint()));
                    break;
                case 2 when wire == 2:
                    ReadPackedInt32(reader.ReadBytes(), value => heroIds.Add(checked((uint)value)));
                    break;
                default:
                    reader.Skip(wire);
                    break;
            }
        }
        return new SetBuildingHeroArg(buildingId, heroIds);
    }

    public static SetBuildingListHeroArg DecodeSetBuildingListHeroArg(ReadOnlySpan<byte> payload)
    {
        var buildingIds = new List<int>();
        var heroIds = new List<int>();
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
        {
            switch (field)
            {
                case 1 when wire == 0:
                    buildingIds.Add(checked((int)reader.ReadVarint()));
                    break;
                case 1 when wire == 2:
                    ReadPackedInt32(reader.ReadBytes(), buildingIds.Add);
                    break;
                case 2 when wire == 0:
                    heroIds.Add(unchecked((int)reader.ReadVarint()));
                    break;
                case 2 when wire == 2:
                    ReadPackedInt32(reader.ReadBytes(), heroIds.Add);
                    break;
                default:
                    reader.Skip(wire);
                    break;
            }
        }
        return new SetBuildingListHeroArg(buildingIds, heroIds);
    }

    public static AddBuildingArg DecodeAddBuildingArg(ReadOnlySpan<byte> payload)
    {
        int tid = 0;
        int index = 0;
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
        {
            switch (field)
            {
                case 1 when wire == 0: tid = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 0: index = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        }
        return new AddBuildingArg(tid, index);
    }

    public static int DecodeBuildingIdArg(ReadOnlySpan<byte> payload)
    {
        int buildingId = 0;
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
        {
            if (field == 1 && wire == 0) buildingId = checked((int)reader.ReadVarint());
            else reader.Skip(wire);
        }
        return buildingId;
    }

    public static byte[] EncodeAddBuildingRet(int buildingId)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, unchecked((ulong)buildingId));
        return output.ToArray();
    }

    private static void ReadPackedInt32(ReadOnlySpan<byte> payload, Action<int> add)
    {
        int offset = 0;
        while (offset < payload.Length)
        {
            ulong value = 0;
            int shift = 0;
            byte current;
            do
            {
                if (offset >= payload.Length || shift >= 64)
                    throw new InvalidDataException("Invalid packed protobuf int32");
                current = payload[offset++];
                value |= (ulong)(current & 0x7f) << shift;
                shift += 7;
            } while ((current & 0x80) != 0);
            add(unchecked((int)value));
        }
    }

    // ── Bathroom C2S argument decoding ──

    public static TBathStartArg DecodeBathStartArg(ReadOnlySpan<byte> payload)
    {
        uint heroId = 0; int pos = 0;
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
            switch (field) { case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break; case 2 when wire == 0: pos = checked((int)reader.ReadVarint()); break; default: reader.Skip(wire); break; }
        return new TBathStartArg(heroId, pos);
    }

    public static uint DecodeBathEndArg(ReadOnlySpan<byte> payload)
    {
        uint heroId = 0;
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
            switch (field) { case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break; default: reader.Skip(wire); break; }
        return heroId;
    }

    public static TBathServiceArg DecodeBathServiceArg(ReadOnlySpan<byte> payload)
    {
        uint heroId = 0; int giftId = 0;
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
            switch (field) { case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break; case 2 when wire == 0: giftId = checked((int)reader.ReadVarint()); break; default: reader.Skip(wire); break; }
        return new TBathServiceArg(heroId, giftId);
    }

    public static TBathAutoArg DecodeBathAutoArg(ReadOnlySpan<byte> payload)
    {
        uint heroId = 0; int status = 0;
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
            switch (field) { case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break; case 2 when wire == 0: status = checked((int)reader.ReadVarint()); break; default: reader.Skip(wire); break; }
        return new TBathAutoArg(heroId, status);
    }

    public static TBathChangeHeroArg DecodeBathChangeHeroArg(ReadOnlySpan<byte> payload)
    {
        uint heroId = 0, newHeroId = 0;
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
            switch (field) { case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break; case 2 when wire == 0: newHeroId = checked((uint)reader.ReadVarint()); break; default: reader.Skip(wire); break; }
        return new TBathChangeHeroArg(heroId, newHeroId);
    }

    public static int DecodeBathAllAutoArg(ReadOnlySpan<byte> payload)
    {
        int status = 0;
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
            switch (field) { case 1 when wire == 0: status = checked((int)reader.ReadVarint()); break; default: reader.Skip(wire); break; }
        return status;
    }

    public static IReadOnlyList<TBathStartArg> DecodeBathStartAllArg(ReadOnlySpan<byte> payload)
    {
        var list = new List<TBathStartArg>();
var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out int field, out int wire))
        {
            switch (field)
            {
                case 1 when wire == 2:
                    var subMsg = reader.ReadBytes();
                    var sub = new GameLoginCodec.ProtoReader(subMsg);
                    uint heroId = 0; int pos = 0;
                    while (sub.TryReadField(out int sf, out int sw))
                        switch (sf) { case 1 when sw == 0: heroId = checked((uint)sub.ReadVarint()); break; case 2 when sw == 0: pos = checked((int)sub.ReadVarint()); break; default: sub.Skip(sw); break; }
                    list.Add(new TBathStartArg(heroId, pos));
                    break;
                default: reader.Skip(wire); break;
            }
        }
        return list;
    }

    // ── Bathroom response encoding ──

    public static byte[] EncodeBathEndRet(BathHeroInfo hero)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, 0); // AddExp = 0
        WriteVarintField(output, 2, unchecked((ulong)hero.BathTime));
        WriteVarintField(output, 3, hero.HeroId);
        return output.ToArray();
    }

    public static byte[] EncodeBathServiceRet(BathHeroInfo hero, int buffId, bool isCrit)
    {
        using var output = new MemoryStream();
        if (hero.Pos != 0) WriteVarintField(output, 1, unchecked((ulong)hero.Pos));
        WriteVarintField(output, 2, hero.HeroId);
        // BuffId 无条件编码：客户端 _SendGiftRet 把 shipInfo.BuffId = param.BuffId，
        // nil 时 GetBathAttrBuff 的 `heroBath.BuffId == 0` 判断为 false 会崩。
        WriteVarintField(output, 3, unchecked((ulong)buffId));
        if (isCrit) WriteVarintField(output, 4, 1);
        return output.ToArray();
    }

    public static byte[] EncodeBathStartAllRet(IReadOnlyList<BathHeroInfo> heroes)
    {
        using var output = new MemoryStream();
        foreach (var h in heroes)
            WriteMessage(output, 1, EncodeBathEndRet(h));
        return output.ToArray();
    }

    // ── Bathroom argument records ──

    public readonly record struct TBathStartArg(uint HeroId, int Pos);
    public readonly record struct TBathServiceArg(uint HeroId, int GiftId);
    public readonly record struct TBathAutoArg(uint HeroId, int Status);
    public readonly record struct TBathChangeHeroArg(uint HeroId, uint NewHeroId);

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
        // TemplateId=0 is the deletion marker consumed by herodata.SetData. The Lua protobuf
        // runtime leaves an omitted optional scalar as nil (rather than applying a zero default),
        // so omitting this field makes a retired hero enter the normal update branch and aborts
        // the remaining client-side refresh before its equipment can be shown for dismantling.
        WriteVarintField(output, 2, unchecked((ulong)value.TemplateId));
        // Equips (field 3, repeated)：每个 FleetType 编码一个 EquipsInfoByType。
        // EquipsId 无条件编码 0：RefreshHeroEquipData 里 `equip.EquipsId > 0` 判断，nil 会崩。
        var slots = value.EquipSlots;
        var equipInfos = new List<EquipsInfo>(6);
        for (var i = 0; i < 6; i++)
        {
            var slotId = slots != null && i < slots.Count ? slots[i] : 0u;
            equipInfos.Add(new EquipsInfo(slotId));
        }
        WriteMessage(output, 3, Encode(new EquipsInfoByType(1, equipInfos)));
        if (value.Lvl != 0) WriteVarintField(output, 4, unchecked((ulong)value.Lvl));
        // Exp 必须无条件编码：girlinfo GirlShowPage._LoadPropertInfo 里
        // math.tointeger(Exp) .. "/" .. needExp 拼接，Exp 为 nil 会崩。
        WriteVarintField(output, 5, unchecked((ulong)value.Exp));
        if (value.CreateTime != 0) WriteVarintField(output, 8, unchecked((ulong)value.CreateTime));
        if (value.CurHp != 0) WriteVarintField(output, 9, unchecked((ulong)value.CurHp));
        // PSkill (field 13, repeated TMapFiledPSkillExp)：编码所有实际技能数据。
        if (value.PSkills is { Count: > 0 } skills)
        {
            foreach (PSkillEntry sk in skills)
            {
                uint psId = sk.PSkillId != 0 ? sk.PSkillId : 41210;
                byte[] psBody = BuildPSkillBytes(psId, sk.PSkillExp, sk.Level, sk.Replace);
                WriteVarint(output, 0x6A);
                WriteVarint(output, (ulong)psBody.Length);
                output.Write(psBody);
            }
        }
        else
        {
            output.Write(new byte[] { 0x6A, 0x0A, 0x08, 0xFA, 0xC1, 0x02, 0x10, 0x00, 0x18, 0x00, 0x20, 0x00 });
        }
        if (value.Affection != 0) WriteVarintField(output, 17, unchecked((ulong)value.Affection));
        // Mood/MarryTime/MarryType 必须无条件编码：值为 0 时客户端读到 nil，
        // GetMoodNum/GetLoveInfo 里的算术/比较会崩溃。
        WriteVarintField(output, 18, unchecked((ulong)value.Mood));
        WriteVarintField(output, 19, unchecked((ulong)value.MarryTime));
        if (value.UpdateTime != 0) WriteVarintField(output, 20, unchecked((ulong)value.UpdateTime));
        WriteVarintField(output, 21, unchecked((ulong)value.MarryType));
        if (value.Fashioning != 0) WriteVarintField(output, 22, unchecked((ulong)value.Fashioning));
        // ArrRemouldEffect / RemouldLV 对应改造页的节点集合与已完成阶段数。
        if (value.ArrRemouldEffect is { Count: > 0 } remouldEffects)
            foreach (int effectId in remouldEffects)
                WriteVarintField(output, 23, unchecked((ulong)effectId));
        // 即使尚未完成第一阶段也显式编码 0，避免 Lua 侧拿到 nil 后参与数值比较。
        WriteVarintField(output, 24, unchecked((ulong)value.RemouldLV));
        // AdvLv 是协议中独立于 Advance 的字段，改造详情也会读取它。
        WriteVarintField(output, 25, unchecked((ulong)value.AdvLv));
        // Advance (field 6, int32)：突破等级，必须编码，nil 会导致 break_page 星级计算崩溃。
        WriteVarintField(output, 6, unchecked((ulong)value.Advance));
        WriteStringField(output, 15, value.Name);
        // ChangeNamePage 会直接用该值参与冷却时间加法；即使尚未改名也必须编码 0，
        // 否则 Lua protobuf 返回 nil，点击确认时会在发送请求前中断。
        WriteVarintField(output, 16, unchecked((ulong)value.ChangeNameTime));
        // Lock 必须无条件编码。解锁时若省略 false，客户端增量合并后可能继续保留旧的 true。
        WriteVarintField(output, 12, value.Lock ? 1UL : 0UL);
        return output.ToArray();
    }

    public static byte[] Encode(IllustrateInfoRet value)
    {
        using var output = new MemoryStream();
        if (value.IllustrateList is not null)
            foreach (var item in value.IllustrateList) WriteMessage(output, 1, Encode(item));
        if (value.HeroMemoryList is not null)
            foreach (var item in value.HeroMemoryList) WriteMessage(output, 8, Encode(item));
        if (value.IllustrateEquipList is not null)
            foreach (var item in value.IllustrateEquipList) WriteMessage(output, 9, Encode(item));
        return output.ToArray();
    }

    public static byte[] Encode(HeroMemory value)
    {
        using var output = new MemoryStream();
        if (value.HeroId != 0) WriteVarintField(output, 1, value.HeroId);
        if (value.PlotId != 0) WriteVarintField(output, 2, unchecked((ulong)value.PlotId));
        return output.ToArray();
    }

    public static byte[] Encode(StoryMemoryList value)
    {
        using var output = new MemoryStream();
        if (value.MemoryList is not null)
            foreach (var item in value.MemoryList) WriteMessage(output, 1, Encode(item));
        return output.ToArray();
    }

    public static byte[] Encode(ChapterMemory value)
    {
        using var output = new MemoryStream();
        if (value.ChapterId != 0) WriteVarintField(output, 1, unchecked((ulong)value.ChapterId));
        if (value.Index != 0) WriteVarintField(output, 2, unchecked((ulong)value.Index));
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
        // Num=0 is the client's deletion marker. The bundled Lua protobuf decoder omits
        // absent scalar fields, so suppressing zero here produces `num=nil`; BagData then
        // keeps a phantom item and pages such as MarryBookPage crash on math.tointeger(nil).
        // Always writing field 2 also makes zero-count sentinels in older saves self-heal
        // as soon as the inventory is synchronized.
        WriteVarintField(output, 2, unchecked((ulong)value.Num));
        return output.ToArray();
    }

    public static BagNormalTreasureInfoArg DecodeBagNormalTreasureInfoArg(ReadOnlySpan<byte> payload)
    {
        var treasureId = 0;
        var treasureNum = 0;
        var reader = new GameLoginCodec.ProtoReader(payload);
        while (reader.TryReadField(out var field, out var wire))
        {
            switch (field)
            {
                case 1 when wire == 0: treasureId = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 0: treasureNum = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        }
        return new BagNormalTreasureInfoArg(treasureId, treasureNum);
    }

    public static byte[] Encode(BagTreasureInfoRet value)
    {
        using var output = new MemoryStream();
        if (value.TreasuresInfo is not null)
            foreach (var reward in value.TreasuresInfo)
                WriteMessage(output, 1, Encode(reward));
        if (value.TreasureId != 0)
            WriteVarintField(output, 2, unchecked((ulong)value.TreasureId));
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

    public static byte[] Encode(MailListRet value)
    {
        using var output = new MemoryStream();
        if (value.MailNum != 0) WriteVarintField(output, 1, unchecked((ulong)value.MailNum));
        if (value.ExpireNum != 0) WriteVarintField(output, 2, unchecked((ulong)value.ExpireNum));
        if (value.List is not null)
            foreach (var item in value.List) WriteMessage(output, 3, Encode(item));
        if (value.Reward is not null)
            foreach (var item in value.Reward) WriteMessage(output, 4, Encode(item));
        return output.ToArray();
    }

    public static byte[] Encode(MailList value)
    {
        using var output = new MemoryStream();
        if (value.Mid != 0) WriteVarintField(output, 1, value.Mid);
        // TempLateId 无条件编码：emaillogic.ParseEmail 里 `mail.TempLateId > 0` 比较，nil 会崩。
        WriteVarintField(output, 2, unchecked((ulong)value.TempLateId));
        if (!string.IsNullOrEmpty(value.Subject)) WriteMessage(output, 9, Encoding.UTF8.GetBytes(value.Subject));
        if (!string.IsNullOrEmpty(value.Content)) WriteMessage(output, 10, Encoding.UTF8.GetBytes(value.Content));
        // ReceiveTime/ReadTime/IsGotReawrd/DeleteTime 无条件编码：客户端对这些字段做 == 比较
        // （ReadTime==0 判新邮件、IsGotReawrd==0 判可领取、DeleteTime==0 判不过期），nil 会误判。
        WriteVarintField(output, 7, unchecked((ulong)value.ReceiveTime));
        WriteVarintField(output, 8, unchecked((ulong)value.ReadTime));
        WriteVarintField(output, 11, unchecked((ulong)value.IsGotReawrd));
        // Items 必须非 nil：emaildata.lua SetMailList 里 #v.Items 计数，nil 会崩。
        if (value.Items is not null)
            foreach (var item in value.Items) WriteMessage(output, 13, Encode(item));
        WriteVarintField(output, 14, unchecked((ulong)value.DeleteTime));
        return output.ToArray();
    }

    public static byte[] Encode(MailItem value)
    {
        using var output = new MemoryStream();
        if (value.Type != 0) WriteVarintField(output, 1, unchecked((ulong)value.Type));
        if (value.Id != 0) WriteVarintField(output, 2, unchecked((ulong)value.Id));
        if (value.Num != 0) WriteVarintField(output, 3, unchecked((ulong)value.Num));
        return output.ToArray();
    }

    public static byte[] Encode(EquipList value)
    {
        using var output = new MemoryStream();
        // EquipBagSize 无条件编码：equipdata.EquipBagSize 初始为 0（nil），客户端读为 0
        // 会导致装备仓库容量为 0、无法存放装备。
        WriteVarintField(output, 1, unchecked((ulong)value.EquipBagSize));
        if (value.EquipInfo is not null)
            foreach (var item in value.EquipInfo) WriteMessage(output, 2, Encode(item));
        if (value.EquipNum is not null)
            foreach (var item in value.EquipNum) WriteMessage(output, 3, Encode(item));
        return output.ToArray();
    }

    public static byte[] Encode(EquipInfo value)
    {
        using var output = new MemoryStream();
        if (value.EquipId != 0) WriteVarintField(output, 1, value.EquipId);
        // TemplateId 无条件编码（含值为 0 的"删除标记"）：equipdata.UpdateEquip 里
        // `v.TemplateId ~= 0` 分支判断，TemplateId==0 的条目表示该装备已被移除。
        WriteVarintField(output, 2, unchecked((ulong)value.TemplateId));
        // EnhanceLv/Star/HeroId/EnhanceExp 无条件编码：EquipBagOverlay 里
        // tabSortTool[Tid][Star][EnhanceLv] 索引 + `0 < HeroId` 比较 + EnhanceExp 算术，
        // nil 都会崩溃。
        WriteVarintField(output, 3, unchecked((ulong)value.EnhanceLv));
        WriteVarintField(output, 4, unchecked((ulong)value.Star));
        WriteVarintField(output, 5, value.HeroId);
        WriteVarintField(output, 6, unchecked((ulong)value.EnhanceExp));
        return output.ToArray();
    }

    public static byte[] Encode(EquipNum value)
    {
        using var output = new MemoryStream();
        if (value.TemplateId != 0) WriteVarintField(output, 1, unchecked((ulong)value.TemplateId));
        if (value.Num != 0) WriteVarintField(output, 2, unchecked((ulong)value.Num));
        return output.ToArray();
    }

    public static byte[] Encode(EquipsInfoByType value)
    {
        using var output = new MemoryStream();
        if (value.Type != 0) WriteVarintField(output, 1, unchecked((ulong)value.Type));
        if (value.Equip is not null)
            foreach (var item in value.Equip) WriteMessage(output, 2, Encode(item));
        return output.ToArray();
    }

    public static byte[] Encode(EquipsInfo value)
    {
        using var output = new MemoryStream();
        // EquipsId 无条件编码：EquipData.RefreshHeroEquipData 里
        // `equip.EquipsId > 0` 判断，nil 会崩。
        WriteVarintField(output, 1, value.EquipsId);
        if (value.State != 0) WriteVarintField(output, 2, unchecked((ulong)value.State));
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

private static void WriteStringField(Stream output, int field, string value)
    {
        var bytes = System.Text.Encoding.UTF8.GetBytes(value);
        WriteVarint(output, (ulong)((field << 3) | 2));
        WriteVarint(output, (ulong)bytes.Length);
        output.Write(bytes);
    }

private static byte[] BuildPSkillBytes(uint psId, uint exp, int level, int replace)
    {
        using var ms = new MemoryStream();
        WriteVarint(ms, 0x08);
        WriteVarint(ms, psId);
        WriteVarint(ms, 0x10);
        WriteVarint(ms, exp);
        WriteVarint(ms, 0x18);
        WriteVarint(ms, unchecked((ulong)(level > 0 ? level : 1)));
        WriteVarint(ms, 0x20);
        WriteVarint(ms, unchecked((ulong)replace));
        return ms.ToArray();
    }

}
