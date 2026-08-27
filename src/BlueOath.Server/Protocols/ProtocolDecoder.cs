using System.Text;
using BlueOath.Core;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 服务端 protobuf 解码器：把客户端请求的 arg 字节解码为实体/元组，供各服务使用。
/// 低层字段遍历基于 <see cref="ProtoReader"/>（ref struct，零分配）。
/// </summary>
internal static class ProtocolDecoder
{
    /// <summary>读取原始 varint 编码的 ulong（整段数据就是一个 varint，如 guide.PlotReward 参数）。</summary>
    internal static ulong DecodeVarint(ReadOnlySpan<byte> data)
    {
        ulong value = 0;
        for (int shift = 0; shift < 64 && shift / 7 < data.Length; shift += 7)
            value |= (ulong)(data[shift / 7] & 0x7f) << shift;
        return value;
    }

    /// <summary>取指定 varint 字段（wire type 0）的值，缺失返回 0。</summary>
    internal static ulong DecodeVarintField(ReadOnlySpan<byte> data, int field)
    {
        ProtoReader reader = new(data);
        while (reader.TryReadField(out int f, out int wire))
        {
            if (f == field && wire == 0) return reader.ReadVarint();
            reader.Skip(wire);
        }

        return 0;
    }

    /// <summary>取指定 string 字段（wire type 2）的值，缺失返回 null。</summary>
    internal static string? DecodeStringField(ReadOnlySpan<byte> data, int field)
    {
        ProtoReader reader = new(data);
        while (reader.TryReadField(out int f, out int wire))
        {
            if (f == field && wire == 2) return reader.ReadString();
            reader.Skip(wire);
        }

        return null;
    }

    /// <summary>解码 hero.Marry 参数：HeroId(1, uint32), MarryType(2, int32)。</summary>
    internal static MarryArg DecodeMarryArg(ReadOnlySpan<byte> payload)
    {
        ProtoReader reader = new(payload);
        uint heroId = 0;
        int marryType = 1;
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break;
                case 2 when wire == 0: marryType = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        return new MarryArg(heroId, marryType);
    }

    /// <summary>解码 hero.HeroRemould 参数：HeroId(1, uint32), EffectId(2, int32)。</summary>
    internal static HeroRemouldArg DecodeHeroRemouldArg(ReadOnlySpan<byte> payload)
    {
        ProtoReader reader = new(payload);
        uint heroId = 0;
        int effectId = 0;
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break;
                case 2 when wire == 0: effectId = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        return new HeroRemouldArg(heroId, effectId);
    }

    /// <summary>解码 TBuildShipArg: Id(1, int32), Num(2, int32), CacheId(3, string)。</summary>
    internal static BuildShipArg DecodeBuildShipArg(ReadOnlySpan<byte> payload)
    {
        ProtoReader reader = new(payload);
        int id = 0, num = 1;
        string cacheId = "";
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: id = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 0: num = checked((int)reader.ReadVarint()); break;
                case 3 when wire == 2: cacheId = reader.ReadString(); break;
                default: reader.Skip(wire); break;
            }

        return new BuildShipArg(id, num, cacheId);
    }

    /// <summary>解码 build.BuildingByFormula 的重复 TBuildProject。</summary>
    internal static ConstructionProjectsArg DecodeConstructionProjectsArg(ReadOnlySpan<byte> payload)
    {
        List<ConstructionProjectArg> projects = [];
        ProtoReader reader = new(payload);
        while (reader.TryReadField(out int field, out int wire))
        {
            if (field != 1 || wire != 2)
            {
                reader.Skip(wire);
                continue;
            }

            ProtoReader projectReader = new(reader.ReadBytes());
            List<ConstructionItemArg> items = [];
            int gold = 0;
            while (projectReader.TryReadField(out int projectField, out int projectWire))
            {
                if (projectField == 1 && projectWire == 2)
                {
                    ProtoReader itemReader = new(projectReader.ReadBytes());
                    int resId = 0, count = 0;
                    while (itemReader.TryReadField(out int itemField, out int itemWire))
                        if (itemField == 1 && itemWire == 0)
                            resId = checked((int)itemReader.ReadVarint());
                        else if (itemField == 2 && itemWire == 0)
                            count = checked((int)itemReader.ReadVarint());
                        else
                            itemReader.Skip(itemWire);
                    items.Add(new ConstructionItemArg(resId, count));
                }
                else if (projectField == 2 && projectWire == 0)
                {
                    gold = checked((int)projectReader.ReadVarint());
                }
                else
                {
                    projectReader.Skip(projectWire);
                }
            }
            projects.Add(new ConstructionProjectArg(items, gold));
        }
        return new ConstructionProjectsArg(projects);
    }

    /// <summary>解码 build.BuildReceive / BuildQuicklyFinish 的 1-based 重复索引。</summary>
    internal static ConstructionIndexArg DecodeConstructionIndexArg(ReadOnlySpan<byte> payload)
    {
        List<int> indexes = [];
        ProtoReader reader = new(payload);
        while (reader.TryReadField(out int field, out int wire))
        {
            if (field == 1 && wire == 0)
                indexes.Add(checked((int)reader.ReadVarint()));
            else if (field == 1 && wire == 2)
            {
                ProtoReader packed = new(reader.ReadBytes());
                while (packed.HasRemaining)
                    indexes.Add(checked((int)packed.ReadVarint()));
            }
            else
                reader.Skip(wire);
        }
        return new ConstructionIndexArg(indexes);
    }

    /// <summary>解码 hero.AddExp 参数：HeroId(1, uint32), Items(2, repeated {ItemId(2), Num(3)})。</summary>
    internal static HeroAddExpArg DecodeHeroAddExp(ReadOnlySpan<byte> data)
    {
        ProtoReader reader = new(data);
        uint heroId = 0;
        List<ItemCount> items = new();
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 0)
            {
                heroId = checked((uint)reader.ReadVarint());
            }
            else if (field == 2 && wire == 2)
            {
                ReadOnlySpan<byte> itemBytes = reader.ReadBytes();
                ProtoReader itemReader = new(itemBytes);
                int curId = 0, curNum = 0;
                while (itemReader.TryReadField(out int f, out int w))
                    if (f == 2 && w == 0) curId = checked((int)itemReader.ReadVarint());
                    else if (f == 3 && w == 0) curNum = checked((int)itemReader.ReadVarint());
                    else itemReader.Skip(w);
                if (curId > 0 && curNum > 0) items.Add(new ItemCount(curId, curNum));
            }
            else
            {
                reader.Skip(wire);
            }

        return new HeroAddExpArg(heroId, items);
    }

    /// <summary>解码 hero.HeroAdvance 参数：HeroId(1, uint32), ConsumedHeros(2, repeated uint32), ConsumeItems(3, repeated uint32)。</summary>
    internal static (uint HeroId, List<uint> ConsumedHeros, List<uint> ConsumeItems) DecodeAdvanceArg(byte[] args)
    {
        ProtoReader reader = new(args);
        uint heroId = 0;
        List<uint> consumedHeros = [];
        List<uint> consumeItems = [];
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break;
                case 2 when wire == 0: consumedHeros.Add(checked((uint)reader.ReadVarint())); break;
                case 3 when wire == 0: consumeItems.Add(checked((uint)reader.ReadVarint())); break;
                default: reader.Skip(wire); break;
            }
        return (heroId, consumedHeros, consumeItems);
    }

    /// <summary>解码 equip.Dismantle 参数：ConsumeIds(1, repeated uint32)。</summary>
    internal static List<uint> DecodeEquipDismantle(byte[] args)
    {
        ProtoReader reader = new(args);
        List<uint> consumeIds = [];
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 0) consumeIds.Add(checked((uint)reader.ReadVarint()));
            else reader.Skip(wire);
        return consumeIds;
    }

    /// <summary>解码 hero.StudySkill 参数：HeroId(1, uint32), SkillId(2, int32)。</summary>
    internal static (uint HeroId, int SkillId) DecodeStudySkillArg(byte[] args)
    {
        ProtoReader reader = new(args);
        uint heroId = 0;
        int skillId = 0;
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break;
                case 2 when wire == 0: skillId = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        return (heroId, skillId);
    }

    /// <summary>解码 copy.StartBase 请求的 CopyId（仅 field 2）。</summary>
    internal static int DecodeStartBaseCopyId(byte[] args)
    {
        ProtoReader reader = new(args);
        int copyId = 0;
        while (reader.TryReadField(out int field, out int wire))
            if (field == 2 && wire == 0) copyId = checked((int)reader.ReadVarint());
            else reader.Skip(wire);
        return copyId;
    }

    /// <summary>
    /// 解码 copy.StartBase 请求的 TStartBaseArg，提取：
    ///  - CopyId(2)
    ///  - 关卡出战舰队 HeroList(13) 中第一个 TStartBaseHeroList 的 HeroIdList(1, repeated uint32)
    /// 客户端在请求里已指定本关可出战的舰船（剧情关限制），服务端必须回环它而非自行猜测。
    /// </summary>
    internal static StartBaseArg DecodeStartBaseArg(byte[] args)
    {
        ProtoReader reader = new(args);
        int copyId = 0;
        List<int>? deployHeroIds = null;
        bool isRunningFight = false;
        int battleMode = 0;
        int matchType = 0;
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 2 when wire == 0:
                    copyId = checked((int)reader.ReadVarint());
                    break;
                case 3 when wire == 0:
                    isRunningFight = reader.ReadVarint() != 0;
                    break;
                case 9 when wire == 0:
                    battleMode = checked((int)reader.ReadVarint());
                    break;
                case 15 when wire == 0:
                    matchType = checked((int)reader.ReadVarint());
                    break;
                case 13 when wire == 2:
                    // TStartBaseHeroList: HeroIdList(1, repeated uint32) Index(2) StrategyId(3)
                    ProtoReader sub = new(reader.ReadBytes());
                    List<int> ids = new();
                    while (sub.TryReadField(out int f2, out int w2))
                        if (f2 == 1 && w2 == 0) ids.Add(checked((int)sub.ReadVarint()));
                        else sub.Skip(w2);
                    if (ids.Count > 0) deployHeroIds = ids;
                    break;
                default:
                    reader.Skip(wire);
                    break;
            }

        return new StartBaseArg(copyId, deployHeroIds, isRunningFight, battleMode, matchType);
    }

    /// <summary>
    /// 解码 copy.PassBase 请求的 TPassBaseArg 全部字段，返回完整实体对象。
    /// 字段对照 copy_pb.lua TPassBaseArg: BaseId(1)/Rid(2)/CacheId(3)/RunningTime(4)/
    /// MaxTimeScale(5)/IsFlyAttack(6)/IsRunningFight(7)/Grade(8)/MvpHeroId(9)/
    /// BattleString(10)/Evaluate(11)/BattleTime(12)/LBPoint(13)/IsSupport(14)/
    /// BattleType(15)/Operation(16)/FleetInfo(17)/HerosInfo(18)/IsFinishMission(19)/
    /// EnemyFleets(20)。
    /// </summary>
    public static PassBaseArg DecodePassBaseArgAll(byte[] args)
    {
        ProtoReader reader = new(args);
        int baseId = 0, rid = 0, runningTime = 0, grade = 0, battleTime = 0, lbPoint = 0, battleType = 0;
        string cacheId = "", battleString = "";
        float maxTimeScale = 0f;
        bool isFlyAttack = false, isRunningFight = false, isSupport = false, isFinishMission = false;
        ulong mvpHeroId = 0;
        List<PassEvaluate>? evaluate = null;
        ArchiveCopyOperation? operation = null;
        List<PassFleetInfo>? fleetInfo = null;
        List<BaseHeroInfo>? herosInfo = null;
        List<BattleEnemyFleet>? enemyFleets = null;

        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: baseId = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 0: rid = checked((int)reader.ReadVarint()); break;
                case 3 when wire == 2: cacheId = reader.ReadString(); break;
                case 4 when wire == 0: runningTime = checked((int)reader.ReadVarint()); break;
                case 5 when wire == 5:
                    {
                        uint bits = checked((uint)reader.ReadFixed32());
                        maxTimeScale = BitConverter.Int32BitsToSingle(checked((int)bits));
                        break;
                    }
                case 6 when wire == 0: isFlyAttack = reader.ReadVarint() != 0; break;
                case 7 when wire == 0: isRunningFight = reader.ReadVarint() != 0; break;
                case 8 when wire == 0: grade = checked((int)reader.ReadVarint()); break;
                case 9 when wire == 0: mvpHeroId = reader.ReadVarint(); break;
                case 10 when wire == 2: battleString = reader.ReadString(); break;
                case 11 when wire == 2:
                    evaluate ??= new List<PassEvaluate>();
                    evaluate.Add(DecodePassEvaluate(reader.ReadBytes()));
                    break;
                case 12 when wire == 0: battleTime = checked((int)reader.ReadVarint()); break;
                case 13 when wire == 0: lbPoint = checked((int)reader.ReadVarint()); break;
                case 14 when wire == 0: isSupport = reader.ReadVarint() != 0; break;
                case 15 when wire == 0: battleType = checked((int)reader.ReadVarint()); break;
                case 16 when wire == 2:
                    operation = DecodeArchiveCopyOperation(reader.ReadBytes());
                    break;
                case 17 when wire == 2:
                    fleetInfo ??= new List<PassFleetInfo>();
                    fleetInfo.Add(DecodePassFleetInfo(reader.ReadBytes()));
                    break;
                case 18 when wire == 2:
                    herosInfo ??= new List<BaseHeroInfo>();
                    herosInfo.Add(DecodeBaseHeroInfo(reader.ReadBytes()));
                    break;
                case 19 when wire == 0: isFinishMission = reader.ReadVarint() != 0; break;
                case 20 when wire == 2:
                    enemyFleets ??= new List<BattleEnemyFleet>();
                    enemyFleets.Add(DecodeBattleEnemyFleet(reader.ReadBytes()));
                    break;
                default: reader.Skip(wire); break;
            }

        return new PassBaseArg(baseId, rid, cacheId, runningTime, maxTimeScale,
            isFlyAttack, isRunningFight, grade, mvpHeroId, battleString, evaluate,
            battleTime, lbPoint, isSupport, battleType, operation, fleetInfo,
            herosInfo, isFinishMission, enemyFleets);
    }

    private static PassEvaluate DecodePassEvaluate(ReadOnlySpan<byte> data)
    {
        ProtoReader sub = new(data);
        int type = 0, value = 0;
        while (sub.TryReadField(out int f, out int w))
            switch (f)
            {
                case 1 when w == 0: type = checked((int)sub.ReadVarint()); break;
                case 2 when w == 0: value = checked((int)sub.ReadVarint()); break;
                default: sub.Skip(w); break;
            }
        return new PassEvaluate(type, value);
    }

    private static PassKvInfo DecodePassKvInfo(ReadOnlySpan<byte> data)
    {
        ProtoReader sub = new(data);
        int type = 0, value = 0;
        while (sub.TryReadField(out int f, out int w))
            switch (f)
            {
                case 1 when w == 0: type = checked((int)sub.ReadVarint()); break;
                case 2 when w == 0: value = checked((int)sub.ReadVarint()); break;
                default: sub.Skip(w); break;
            }
        return new PassKvInfo(type, value);
    }

    private static BaseHeroInfo DecodeBaseHeroInfo(ReadOnlySpan<byte> data)
    {
        ProtoReader sub = new(data);
        uint heroId = 0;
        ulong hp = 0, ownerUid = 0;
        bool isMvp = false, isBattle = false;
        int breakStatus = 0;
        List<PassKvInfo>? exHeroInfo = null;
        while (sub.TryReadField(out int f, out int w))
            switch (f)
            {
                case 1 when w == 0: heroId = checked((uint)sub.ReadVarint()); break;
                case 2 when w == 0: hp = sub.ReadVarint(); break;
                case 3 when w == 0: isMvp = sub.ReadVarint() != 0; break;
                case 4 when w == 0: isBattle = sub.ReadVarint() != 0; break;
                case 5 when w == 0: breakStatus = checked((int)sub.ReadVarint()); break;
                case 6 when w == 2:
                    exHeroInfo ??= new List<PassKvInfo>();
                    exHeroInfo.Add(DecodePassKvInfo(sub.ReadBytes()));
                    break;
                case 7 when w == 0: ownerUid = sub.ReadVarint(); break;
                default: sub.Skip(w); break;
            }
        return new BaseHeroInfo(heroId, hp, isMvp, isBattle, breakStatus, exHeroInfo, ownerUid);
    }

    private static PassFleetInfo DecodePassFleetInfo(ReadOnlySpan<byte> data)
    {
        ProtoReader sub = new(data);
        int enemyId = 0;
        List<BaseHeroInfo>? enemyInfo = null;
        while (sub.TryReadField(out int f, out int w))
            switch (f)
            {
                case 1 when w == 0: enemyId = checked((int)sub.ReadVarint()); break;
                case 2 when w == 2:
                    enemyInfo ??= new List<BaseHeroInfo>();
                    enemyInfo.Add(DecodeBaseHeroInfo(sub.ReadBytes()));
                    break;
                default: sub.Skip(w); break;
            }
        return new PassFleetInfo(enemyId, enemyInfo);
    }

    private static ArchiveCopyOperation DecodeArchiveCopyOperation(ReadOnlySpan<byte> data)
    {
        ProtoReader sub = new(data);
        int frameNumber = 0;
        ReadOnlyMemory<byte> bytes = default;
        while (sub.TryReadField(out int f, out int w))
            switch (f)
            {
                case 1 when w == 0: frameNumber = checked((int)sub.ReadVarint()); break;
                case 2 when w == 2: bytes = sub.ReadBytes().ToArray(); break;
                default: sub.Skip(w); break;
            }
        return new ArchiveCopyOperation(frameNumber, bytes);
    }

    private static HeroAttr DecodeHeroAttr(ReadOnlySpan<byte> data)
    {
        ProtoReader sub = new(data);
        int attrId = 0, attrValue = 0;
        while (sub.TryReadField(out int f, out int w))
            switch (f)
            {
                case 1 when w == 0: attrId = checked((int)sub.ReadVarint()); break;
                case 2 when w == 0: attrValue = checked((int)sub.ReadVarint()); break;
                default: sub.Skip(w); break;
            }
        return new HeroAttr(attrId, attrValue);
    }

    private static BattleEnemyShip DecodeBattleEnemyShip(ReadOnlySpan<byte> data)
    {
        ProtoReader sub = new(data);
        int shipId = 0;
        List<HeroAttr>? attr = null;
        List<int>? pSkill = null;
        while (sub.TryReadField(out int f, out int w))
            switch (f)
            {
                case 1 when w == 0: shipId = checked((int)sub.ReadVarint()); break;
                case 2 when w == 2:
                    attr ??= new List<HeroAttr>();
                    attr.Add(DecodeHeroAttr(sub.ReadBytes()));
                    break;
                case 3 when w == 0:
                    pSkill ??= new List<int>();
                    pSkill.Add(checked((int)sub.ReadVarint()));
                    break;
                default: sub.Skip(w); break;
            }
        return new BattleEnemyShip(shipId, attr, pSkill);
    }

    private static BattleEnemyFleet DecodeBattleEnemyFleet(ReadOnlySpan<byte> data)
    {
        ProtoReader sub = new(data);
        int fleetId = 0, state = 0;
        List<BattleEnemyShip>? ships = null;
        while (sub.TryReadField(out int f, out int w))
            switch (f)
            {
                case 1 when w == 0: fleetId = checked((int)sub.ReadVarint()); break;
                case 2 when w == 0: state = checked((int)sub.ReadVarint()); break;
                case 3 when w == 2:
                    ships ??= new List<BattleEnemyShip>();
                    ships.Add(DecodeBattleEnemyShip(sub.ReadBytes()));
                    break;
                default: sub.Skip(w); break;
            }
        return new BattleEnemyFleet(fleetId, state, ships);
    }

    /// <summary>解码 copy.PassBase 请求的 BaseId（仅 field 1）。</summary>
    public static int DecodePassBaseCopyId(byte[] args)
    {
        ProtoReader reader = new(args);
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 0) return checked((int)reader.ReadVarint());
            else reader.Skip(wire);
        return 0;
    }

    /// <summary>解码 SetHerosTactic 请求为 FleetEntry 列表。</summary>
    public static List<FleetEntry> DecodeSetHerosTactic(byte[] args)
    {
        List<FleetEntry> entries = new();
        ProtoReader reader = new(args);
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 2) // tactics
            {
                ProtoReader inner = new(reader.ReadBytes());
                int modeId = 0;
                int type = 1;
                string tacticName = "";
                List<int> heroInfo = new();
                List<int> exHeroInfo = new();
                int strategyId = 0;
                int formationId = 2;
                while (inner.TryReadField(out int f, out int w))
                    switch (f)
                    {
                        case 1 when w == 2: tacticName = inner.ReadString(); break;
                        case 2 when w == 0: heroInfo.Add(checked((int)inner.ReadVarint())); break;
                        case 3 when w == 0: modeId = checked((int)inner.ReadVarint()); break;
                        case 4 when w == 0: strategyId = checked((int)inner.ReadVarint()); break;
                        case 5 when w == 0: formationId = checked((int)inner.ReadVarint()); break;
                        case 6 when w == 0: type = checked((int)inner.ReadVarint()); break;
                        case 7 when w == 0: exHeroInfo.Add(checked((int)inner.ReadVarint())); break;
                        default: inner.Skip(w); break;
                    }

                entries.Add(new FleetEntry(modeId, type, tacticName, heroInfo, exHeroInfo, strategyId, formationId));
            }
            else
            {
                reader.Skip(wire);
            }

        return entries;
    }

    /// <summary>解码 hero.LockHero 参数：HeroId(1, uint32), Lock(2, bool)。</summary>
    internal static LockHeroArg DecodeLockHeroArg(ReadOnlySpan<byte> data)
    {
        ProtoReader reader = new(data);
        uint heroId = 0;
        bool isLock = false;
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break;
                case 2 when wire == 0: isLock = reader.ReadVarint() != 0; break;
                default: reader.Skip(wire); break;
            }
        return new LockHeroArg(heroId, isLock);
    }

    /// <summary>
    /// 解码 hero.RetireHero 参数：HeroIds(1, repeated uint32), IsDisEquip(2, bool)。
    /// repeated uint32 同时兼容 proto2 常见的 unpacked 与 packed 编码。
    /// </summary>
    internal static RetireHeroArg DecodeRetireHeroArg(ReadOnlySpan<byte> data)
    {
        ProtoReader reader = new(data);
        List<uint> heroIds = new();
        bool isDisEquip = false;
        while (reader.TryReadField(out int field, out int wire))
        {
            if (field == 1 && wire == 0)
            {
                heroIds.Add(checked((uint)reader.ReadVarint()));
            }
            else if (field == 1 && wire == 2)
            {
                ProtoReader packed = new(reader.ReadBytes());
                while (packed.HasRemaining)
                    heroIds.Add(checked((uint)packed.ReadVarint()));
            }
            else if (field == 2 && wire == 0)
            {
                isDisEquip = reader.ReadVarint() != 0;
            }
            else
            {
                reader.Skip(wire);
            }
        }
        return new RetireHeroArg(heroIds, isDisEquip);
    }

    /// <summary>解码 hero.ChangeName 参数：HeroId(1, uint32), Name(2, string)。</summary>
    internal static ChangeHeroNameArg DecodeChangeHeroNameArg(ReadOnlySpan<byte> data)
    {
        ProtoReader reader = new(data);
        uint heroId = 0;
        string name = "";
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break;
                case 2 when wire == 2: name = reader.ReadString(); break;
                default: reader.Skip(wire); break;
            }
        return new ChangeHeroNameArg(heroId, name);
    }

    /// <summary>解码 hero.AddAffection 参数：HeroId(1, uint32), TemplateId(2, int32), Num(3, int32)。</summary>
    internal static HeroAddAffectionArg DecodeHeroAddAffectionArg(ReadOnlySpan<byte> data)
    {
        ProtoReader reader = new(data);
        uint heroId = 0;
        int templateId = 0, num = 0;
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break;
                case 2 when wire == 0: templateId = checked((int)reader.ReadVarint()); break;
                case 3 when wire == 0: num = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        return new HeroAddAffectionArg(heroId, templateId, num);
    }

    /// <summary>
    /// 低层 protobuf 字段遍历器（ref struct，作用于 ReadOnlySpan，零分配）。
    /// 覆盖 varint / fixed32 / fixed64 / length-delimited 四种 wire type。
    /// </summary>
    internal ref struct ProtoReader
    {
        private readonly ReadOnlySpan<byte> _data;
        private int _offset;

        public ProtoReader(ReadOnlySpan<byte> data)
        {
            _data = data;
            _offset = 0;
        }

        public bool HasRemaining => _offset < _data.Length;

        public bool TryReadField(out int field, out int wire)
        {
            if (_offset >= _data.Length)
            {
                field = wire = 0;
                return false;
            }

            ulong key = ReadVarint();
            field = checked((int)(key >> 3));
            wire = (int)(key & 7);
            return true;
        }

        public ulong ReadVarint()
        {
            ulong value = 0;
            for (int shift = 0; shift < 64; shift += 7)
            {
                if (_offset >= _data.Length) throw new EndOfStreamException();
                byte cur = _data[_offset++];
                value |= (ulong)(cur & 0x7f) << shift;
                if ((cur & 0x80) == 0) return value;
            }

            throw new InvalidDataException();
        }

        public string ReadString()
        {
            return Encoding.UTF8.GetString(ReadBytes());
        }

        public ReadOnlySpan<byte> ReadBytes()
        {
            int len = checked((int)ReadVarint());
            ReadOnlySpan<byte> val = _data.Slice(_offset, len);
            _offset += len;
            return val;
        }

        public uint ReadFixed32()
        {
            uint value = BitConverter.ToUInt32(_data.Slice(_offset, 4));
            _offset += 4;
            return value;
        }

        public void Skip(int wire)
        {
            switch (wire)
            {
                case 0: ReadVarint(); break;
                case 1: _offset += 8; break;
                case 2: ReadBytes(); break;
                case 5: _offset += 4; break;
                default: throw new InvalidDataException();
            }
        }
    }
}
