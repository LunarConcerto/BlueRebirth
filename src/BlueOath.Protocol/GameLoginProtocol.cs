using System.Text;
using System.Buffers.Binary;

namespace BlueOath.Protocol;

public static class GameOperationCodes
{
    public const int Login = 2;
    public const int C2S = 5;
    public const int S2C = 6;
}

public sealed record TRequest(string Method = "", byte[]? Args = null, uint CallbackHandler = 0, string Token = "");

public sealed record TResponse(int Err = 0, string ErrMsg = "", string Method = "", byte[]? Ret = null,
    uint CallbackHandler = 0, uint Time = 0, string Token = "", uint Seq = 0, int IsResponse = 0);

/// <summary>
/// user.GetUserInfo / user.UpdateUserInfo 的完整用户信息字段（TGetUserInfoRet）。
/// 包含全部持久货币字段（CurrencyType → UserInfo 字段号映射见 EncodeRetGetUserInfo）。
/// </summary>
public sealed record UserInfoFields(
    ulong Uid = 0, string Uname = "", int Level = 0, int Class = 0, uint SecretaryId = 1,
    int CreateTime = 0, int Gold = 0, int Diamond = 0, int Supply = 0, int Bath = 0,
    int MainGun = 0, int Torpedo = 0, int Plane = 0, int Other = 0,
    int Retire = 0, int Strategy = 0, int Medal = 0, int Tower = 0,
    int CopyTrainPoint = 0, int FashionPoint = 0, int GuildContri = 0,
    int Lucky = 0, int TeacherMedal = 0, int TeacherPrestige = 0,
    int BattlePassExp = 0, int BattlePassGold = 0, int PvePt = 0,
    int GuildCoinII = 0, int UrEquipCoin = 0, int ActivityBattlePassExp = 0,
    int GetHeroCount = 0, int AttackCount = 0, int MarriedNum = 0,
    int Head = 1021051, int HeadFrame = 0, string Message = "");

public static class TMessageCodec
{
    public static byte[] EncodeRequest(TRequest value)
    {
        using var output = new MemoryStream();
        if (!string.IsNullOrEmpty(value.Method)) WriteBytes(output, 1, Encoding.UTF8.GetBytes(value.Method));
        if (value.Args is not null) WriteBytes(output, 2, value.Args);
        if (value.CallbackHandler != 0) WriteVarintField(output, 3, value.CallbackHandler);
        if (!string.IsNullOrEmpty(value.Token)) WriteBytes(output, 4, Encoding.UTF8.GetBytes(value.Token));
        return output.ToArray();
    }

    public static TRequest DecodeRequest(ReadOnlySpan<byte> payload)
    {
        var reader = new PbReader(payload);
        var method = string.Empty;
        byte[]? args = null;
        uint callbackHandler = 0;
        var token = string.Empty;
        while (reader.TryReadField(out var field, out var wire))
        {
            switch (field)
            {
                case 1 when wire == 2: method = reader.ReadString(); break;
                case 2 when wire == 2: args = reader.ReadBytes().ToArray(); break;
                case 3 when wire == 0: callbackHandler = checked((uint)reader.ReadVarint()); break;
                case 4 when wire == 2: token = reader.ReadString(); break;
                default: reader.Skip(wire); break;
            }
        }
        return new TRequest(method, args, callbackHandler, token);
    }

    public static byte[] EncodeResponse(TResponse value)
    {
        using var output = new MemoryStream();
        if (value.Err != 0) WriteVarintField(output, 1, unchecked((uint)value.Err));
        if (!string.IsNullOrEmpty(value.ErrMsg)) WriteBytes(output, 2, Encoding.UTF8.GetBytes(value.ErrMsg));
        if (!string.IsNullOrEmpty(value.Method)) WriteBytes(output, 3, Encoding.UTF8.GetBytes(value.Method));
        if (value.Ret is not null) WriteBytes(output, 4, value.Ret);
        if (value.CallbackHandler != 0) WriteVarintField(output, 5, value.CallbackHandler);
        if (value.Time != 0) WriteVarintField(output, 6, value.Time);
        if (!string.IsNullOrEmpty(value.Token)) WriteBytes(output, 7, Encoding.UTF8.GetBytes(value.Token));
        if (value.Seq != 0) WriteVarintField(output, 8, value.Seq);
        if (value.IsResponse != 0) WriteVarintField(output, 9, unchecked((uint)value.IsResponse));
        return output.ToArray();
    }

    public static TResponse DecodeResponse(ReadOnlySpan<byte> payload)
    {
        var reader = new PbReader(payload);
        var err = 0;
        var errMsg = string.Empty;
        var method = string.Empty;
        byte[]? ret = null;
        uint callbackHandler = 0;
        uint time = 0;
        var token = string.Empty;
        uint seq = 0;
        var isResponse = 0;
        while (reader.TryReadField(out var field, out var wire))
        {
            switch (field)
            {
                case 1 when wire == 0: err = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 2: errMsg = reader.ReadString(); break;
                case 3 when wire == 2: method = reader.ReadString(); break;
                case 4 when wire == 2: ret = reader.ReadBytes().ToArray(); break;
                case 5 when wire == 0: callbackHandler = checked((uint)reader.ReadVarint()); break;
                case 6 when wire == 0: time = checked((uint)reader.ReadVarint()); break;
                case 7 when wire == 2: token = reader.ReadString(); break;
                case 8 when wire == 0: seq = checked((uint)reader.ReadVarint()); break;
                case 9 when wire == 0: isResponse = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        }
        return new TResponse(err, errMsg, method, ret, callbackHandler, time, token, seq, isResponse);
    }

    public static byte[] EncodeRetUserLogin(string ret, string banMsg, int banTime)
    {
        using var output = new MemoryStream();
        if (!string.IsNullOrEmpty(ret)) WriteBytes(output, 1, Encoding.UTF8.GetBytes(ret));
        if (!string.IsNullOrEmpty(banMsg)) WriteBytes(output, 2, Encoding.UTF8.GetBytes(banMsg));
        if (banTime != 0) WriteVarintField(output, 3, unchecked((uint)banTime));
        return output.ToArray();
    }

    public static string DecodeRetUserLogin(ReadOnlySpan<byte> payload)
    {
        var reader = new PbReader(payload);
        var ret = string.Empty;
        while (reader.TryReadField(out var field, out var wire))
        {
            if (field == 1 && wire == 2) ret = reader.ReadString();
            else reader.Skip(wire);
        }
        return ret;
    }

    public static byte[] EncodeRetGetSvrTime(int nowTime, int svrStartTime)
    {
        using var output = new MemoryStream();
        if (nowTime != 0) WriteVarintField(output, 1, unchecked((uint)nowTime));
        if (svrStartTime != 0) WriteVarintField(output, 2, unchecked((uint)svrStartTime));
        return output.ToArray();
    }

    // TUserLoginTime: LoginTime(field 1) / LoginTimePre(field 2)。用于
    // user.UpdateLoginTime 推送，填充 userdata.loginTime/loginTimePre，
    // 避免 IsFirstLoginToday 里 os.date("*t", 0) 报 "time result cannot be represented"。
    public static byte[] EncodeRetUpdateLoginTime(int loginTime, int loginTimePre)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, unchecked((uint)loginTime));
        WriteVarintField(output, 2, unchecked((uint)loginTimePre));
        return output.ToArray();
    }

    public static byte[] EncodeRetGetUserInfo(ulong uid, string uname, int level, int cls, uint secretaryId = 1,
        int createTime = 0, int bath = 0, int gold = 99999999, int diamond = 999999, int supply = 9999) =>
        EncodeRetGetUserInfo(new UserInfoFields(Uid: uid, Uname: uname, Level: level, Class: cls,
            SecretaryId: secretaryId, CreateTime: createTime, Gold: gold, Diamond: diamond,
            Supply: supply, Bath: bath, PvePt: 100));

    /// <summary>
    /// 编码 TGetUserInfoRet。货币字段无条件编码（值为 0 也写），客户端 GetCurrency 读到
    /// 0 而不是 nil，避免特定页面做算术/比较时崩溃。字段号取自 user_pb.lua TGetUserInfoRet。
    /// </summary>
    public static byte[] EncodeRetGetUserInfo(UserInfoFields v)
    {
        using var output = new MemoryStream();
        if (v.Uid != 0) WriteVarintField(output, 1, v.Uid);
        if (!string.IsNullOrEmpty(v.Uname)) WriteBytes(output, 2, Encoding.UTF8.GetBytes(v.Uname));
        if (v.Head != 0) WriteVarintField(output, 4, unchecked((uint)v.Head));
        if (v.HeadFrame != 0) WriteVarintField(output, 5, unchecked((uint)v.HeadFrame));  // HeadFrame
        if (v.Class != 0) WriteVarintField(output, 7, unchecked((uint)v.Class));
        if (v.Level != 0) WriteVarintField(output, 10, unchecked((uint)v.Level));
        WriteVarintField(output, 11, unchecked((uint)0));        // Exp (HomePage:_PlayerData 读，缺则 nil 崩)
        WriteVarintField(output, 12, unchecked((uint)v.Diamond));    // Diamond
        WriteVarintField(output, 13, unchecked((uint)v.Gold));       // Gold
        WriteVarintField(output, 14, unchecked((uint)v.Supply));     // Supply (vigour)
        WriteVarintField(output, 15, unchecked((uint)v.MainGun));    // MainGun (CurrencyType.MAINGUN)
        WriteVarintField(output, 16, unchecked((uint)v.Torpedo));    // Torpedo (CurrencyType.TORPEDO)
        WriteVarintField(output, 17, unchecked((uint)v.Plane));      // Plane (CurrencyType.PLANE)
        WriteVarintField(output, 18, unchecked((uint)v.Other));      // Other (CurrencyType.OTHER)
        // CreateTime（field 22）无条件编码：PeriodManager calTime 里 type=CREATE 的 period
        // 需要 GetCreateTime，缺则 os.date(nil) 报 "attempt to compare nil with number"。
        WriteVarintField(output, 22, unchecked((uint)v.CreateTime));
        WriteVarintField(output, 23, v.SecretaryId);                 // SecretaryId (hero instance id)
        WriteVarintField(output, 26, unchecked((uint)0));            // BuyGoldNum (BuyResourcePage 读)
        WriteVarintField(output, 27, unchecked((uint)0));            // BuyGoldTime (isSameDay 算术，缺则 nil 崩)
        WriteVarintField(output, 28, unchecked((uint)0));            // BuySupplyNum
        WriteVarintField(output, 29, unchecked((uint)0));            // BuySupplyTime (isSameDay 算术，缺则 nil 崩)
        WriteVarintField(output, 30, unchecked((uint)v.Retire));     // Retire (CurrencyType.RETIRE)
        WriteVarintField(output, 35, unchecked((uint)v.Bath));       // Bath (SPA 温泉币，CurrencyType.SPA)
        WriteVarintField(output, 37, unchecked((uint)v.Strategy));   // Strategy (CurrencyType.STRATEGY)
        WriteVarintField(output, 39, unchecked((uint)v.Medal));      // Medal (CurrencyType.MEDAL)
        WriteVarintField(output, 44, unchecked((uint)0));            // HeadShow (_ReverseMask,_SetSecretary 检查)
        WriteVarintField(output, 46, unchecked((uint)7));            // NewTaskStage (ActivityLogic:IsCanShowRedDot 读，缺则 nil 崩；0 触发新手引导)
        WriteVarintField(output, 47, unchecked((uint)v.CopyTrainPoint)); // CopyTrainPoint (CurrencyType.EXERCISES)
        WriteVarintField(output, 48, unchecked((uint)v.Tower));      // Tower (CurrencyType.TOWER)
        WriteVarintField(output, 49, unchecked((uint)v.FashionPoint));   // FashionPoint (CurrencyType.FASHION)
        WriteVarintField(output, 50, unchecked((uint)v.Lucky));      // Lucky (CurrencyType.LUCKY)
        WriteVarintField(output, 51, unchecked((uint)v.TeacherMedal));   // TeacherMedal (CurrencyType.TEACHINGMERITS)
        WriteVarintField(output, 52, unchecked((uint)v.TeacherPrestige)); // TeacherPrestige (CurrencyType.TEACHINGPOP)
        WriteVarintField(output, 53, unchecked((uint)v.GuildContri)); // GuildContri (CurrencyType.CONTRIBUTE)
        WriteVarintField(output, 56, unchecked((uint)1));            // ServerId (HomePage:_PlayerData 读，缺则 nil 崩)
        WriteVarintField(output, 58, unchecked((uint)v.BattlePassExp));  // BattlePassExp (CurrencyType.BATTLEPASSEXP)
        WriteVarintField(output, 59, unchecked((uint)v.BattlePassGold)); // BattlePassGold (CurrencyType.BATTLEPASSGOLD)
        WriteVarintField(output, 62, unchecked((uint)v.PvePt));      // PvePt (CurrencyType.PVEPT)
        WriteVarintField(output, 63, unchecked((uint)v.GuildCoinII)); // GuildCoinII (CurrencyType.GUILD_COIN_II)
        WriteVarintField(output, 64, unchecked((uint)v.UrEquipCoin)); // UrEquipCoin (CurrencyType.UREQUIPCOIN)
        WriteVarintField(output, 65, unchecked((uint)v.ActivityBattlePassExp)); // ActivityBattlePassExp
        WriteVarintField(output, 40, unchecked((uint)v.AttackCount));       // AttackCount (recordpage 统计)
        WriteVarintField(output, 41, unchecked((uint)v.GetHeroCount));      // GetHeroCount (recordpage 统计)
        WriteVarintField(output, 45, unchecked((uint)v.MarriedNum));        // MarriedNum (recordpage 统计)
        // 非致命字段，不编码 MedalAcquiredTime（空 repeated 表示无勋章）
        if (!string.IsNullOrEmpty(v.Message)) WriteBytes(output, 25, Encoding.UTF8.GetBytes(v.Message));
        return output.ToArray();
    }

    // TBuyGoodsArg: ShopId(1)/GoodId(2)/BuyNum(3)/PriceIndex(5)。
    public static BuyGoodsArg DecodeBuyGoodsArg(ReadOnlySpan<byte> payload)
    {
        var reader = new PbReader(payload);
        int shopId = 0, goodId = 0, buyNum = 0, priceIndex = 0;
        while (reader.TryReadField(out var field, out var wire))
        {
            switch (field)
            {
                case 1 when wire == 0: shopId = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 0: goodId = checked((int)reader.ReadVarint()); break;
                case 3 when wire == 0: buyNum = checked((int)reader.ReadVarint()); break;
                case 5 when wire == 0: priceIndex = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        }
        return new BuyGoodsArg(shopId, goodId, buyNum, priceIndex);
    }

    // TFetchMailArg/TOpenMailArg/TDeleteMailArg: Mid(1, uint64)。
    public static ulong DecodeMailMid(ReadOnlySpan<byte> payload)
    {
        var reader = new PbReader(payload);
        ulong mid = 0;
        while (reader.TryReadField(out var field, out var wire))
        {
            if (field == 1 && wire == 0) mid = reader.ReadVarint();
            else reader.Skip(wire);
        }
        return mid;
    }

    // THeroChangeEquipArgs: HeroId(1, uint32), Index(2, int32), EquipId(3, uint32), Type(4, int32)。
    public static HeroChangeEquipArgs DecodeHeroChangeEquipArgs(ReadOnlySpan<byte> payload)
    {
        var reader = new PbReader(payload);
        uint heroId = 0, equipId = 0;
        int index = 0, type = 0;
        while (reader.TryReadField(out var field, out var wire))
        {
            switch (field)
            {
                case 1 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break;
                case 2 when wire == 0: index = checked((int)reader.ReadVarint()); break;
                case 3 when wire == 0: equipId = checked((uint)reader.ReadVarint()); break;
                case 4 when wire == 0: type = checked((int)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        }
        return new HeroChangeEquipArgs(heroId, index, equipId, type);
    }

    public static EquipEnhanceArgs DecodeEquipEnhanceArgs(ReadOnlySpan<byte> payload)
    {
        var reader = new PbReader(payload);
        uint equipId = 0;
        var items = new List<EquipEnhanceItem>();
        while (reader.TryReadField(out var field, out var wire))
        {
            if (field == 1 && wire == 0) { equipId = checked((uint)reader.ReadVarint()); continue; }
            if (field == 2 && wire == 2)
            {
                var itemReader = new PbReader(reader.ReadBytes());
                uint templateId = 0, itemNum = 0;
                while (itemReader.TryReadField(out var itemField, out var itemWire))
                {
                    switch (itemField)
                    {
                        case 1 when itemWire == 0: templateId = checked((uint)itemReader.ReadVarint()); break;
                        case 2 when itemWire == 0: itemNum = checked((uint)itemReader.ReadVarint()); break;
                        default: itemReader.Skip(itemWire); break;
                    }
                }
                items.Add(new EquipEnhanceItem(templateId, itemNum));
                continue;
            }
            reader.Skip(wire);
        }
        return new EquipEnhanceArgs(equipId, items);
    }

    // TEquipEnhanceRet: EquipId(1) / EquipEnhanceLevel(2) / EquipEnhanceExp(3)。
    // 三个字段均无条件编码；客户端把零长度 Ret 当作 nil，不会触发强化成功回调。
    public static byte[] EncodeEquipEnhanceRet(uint equipId, int enhanceLevel, int enhanceExp)
    {
        using var output = new MemoryStream();
        WriteVarintField(output, 1, equipId);
        WriteVarintField(output, 2, unchecked((uint)enhanceLevel));
        WriteVarintField(output, 3, unchecked((uint)enhanceExp));
        return output.ToArray();
    }

    // TEquipRiseStarArgs: EquipId(1) / ConsumeIds(2, repeated uint32)。
    public static EquipRiseStarArgs DecodeEquipRiseStarArgs(ReadOnlySpan<byte> payload)
    {
        var reader = new PbReader(payload);
        uint equipId = 0;
        var consumeIds = new List<uint>();
        while (reader.TryReadField(out var field, out var wire))
        {
            if (field == 1 && wire == 0) equipId = checked((uint)reader.ReadVarint());
            else if (field == 2 && wire == 0) consumeIds.Add(checked((uint)reader.ReadVarint()));
            else reader.Skip(wire);
        }
        return new EquipRiseStarArgs(equipId, consumeIds);
    }

    // TBuyGoodsRet: Reward(1, repeated TCommonReward)/GoodId(2)/BuyNum(3)。
    public static byte[] EncodeBuyGoodsRet(CommonReward reward, int goodId, int buyNum)
    {
        using var output = new MemoryStream();
        WriteBytes(output, 1, PlayerDataCodec.Encode(reward));
        if (goodId != 0) WriteVarintField(output, 2, unchecked((uint)goodId));
        if (buyNum != 0) WriteVarintField(output, 3, unchecked((uint)buyNum));
        return output.ToArray();
    }

    // TQualityBuyGoodsArg: ShopId(1)/GoodIdList(2, repeated int32)。
    public static QualityBuyGoodsArg DecodeQualityBuyGoodsArg(ReadOnlySpan<byte> payload)
    {
        var reader = new PbReader(payload);
        int shopId = 0;
        var goodIds = new List<int>();
        while (reader.TryReadField(out var field, out var wire))
        {
            switch (field)
            {
                case 1 when wire == 0: shopId = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 0: goodIds.Add(checked((int)reader.ReadVarint())); break;
                default: reader.Skip(wire); break;
            }
        }
        return new QualityBuyGoodsArg(shopId, goodIds);
    }

    // TQualityBuyGoodsRet: Reward(1, repeated TCommonReward)/GoodIdList(2, repeated int32)。
    public static byte[] EncodeQualityBuyGoodsRet(IReadOnlyList<CommonReward> rewards, IReadOnlyList<int> goodIds)
    {
        using var output = new MemoryStream();
        foreach (var r in rewards) WriteBytes(output, 1, PlayerDataCodec.Encode(r));
        foreach (var id in goodIds) WriteVarintField(output, 2, unchecked((uint)id));
        return output.ToArray();
    }

    private static void WriteBytes(Stream output, int field, ReadOnlySpan<byte> value)
    {
        WriteVarint(output, (ulong)((field << 3) | 2));
        WriteVarint(output, (ulong)value.Length);
        output.Write(value);
    }

    private static void WriteVarintField(Stream output, int field, uint value)
    {
        WriteVarint(output, (ulong)(field << 3));
        WriteVarint(output, value);
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

    private ref struct PbReader
    {
        private readonly ReadOnlySpan<byte> _data;
        private int _offset;
        public PbReader(ReadOnlySpan<byte> data) { _data = data; _offset = 0; }

        public bool TryReadField(out int field, out int wire)
        {
            if (_offset >= _data.Length) { field = wire = 0; return false; }
            var key = ReadVarint();
            field = checked((int)(key >> 3));
            wire = (int)(key & 7);
            return true;
        }

        public ulong ReadVarint()
        {
            ulong value = 0;
            for (var shift = 0; shift < 64; shift += 7)
            {
                if (_offset >= _data.Length) throw new EndOfStreamException("Truncated protobuf varint");
                var current = _data[_offset++];
                value |= (ulong)(current & 0x7f) << shift;
                if ((current & 0x80) == 0) return value;
            }
            throw new InvalidDataException("Protobuf varint is too long");
        }

        public string ReadString() => Encoding.UTF8.GetString(ReadBytes());

        public ReadOnlySpan<byte> ReadBytes()
        {
            var length = checked((int)ReadVarint());
            if (length < 0 || _offset + length > _data.Length) throw new EndOfStreamException("Truncated protobuf value");
            var value = _data.Slice(_offset, length);
            _offset += length;
            return value;
        }

        public void Skip(int wire)
        {
            switch (wire)
            {
                case 0: ReadVarint(); break;
                case 1: Advance(8); break;
                case 2: Advance(checked((int)ReadVarint())); break;
                case 5: Advance(4); break;
                default: throw new InvalidDataException($"Unsupported protobuf wire type {wire}");
            }
        }

        private void Advance(int length)
        {
            if (length < 0 || _offset + length > _data.Length) throw new EndOfStreamException("Truncated protobuf field");
            _offset += length;
        }
    }
}

public sealed record TSampleInfo(
    string Uuid = "", string Model = "", string Release = "", string Network = "",
    string Platform = "", string PkgName = "");

public sealed record TArgLogin(
    string Pid = "", int Timestamp = 0, string OpenDateTime = "", string Hash = "",
    TSampleInfo? SampleInfo = null);

public sealed record TRetLogin(string Ret = "", string FeignRoleId = "", int ErrCode = 0);

public static class GameLoginCodec
{
    internal static void WriteInt32(Stream output, int field, int value) => ProtoWriter.Int32(output, field, value);
    internal static void WriteBytes(Stream output, int field, ReadOnlySpan<byte> value) => ProtoWriter.Bytes(output, field, value);

    public static byte[] Encode(TArgLogin value)
    {
        using var output = new MemoryStream();
        ProtoWriter.String(output, 1, value.Pid);
        ProtoWriter.Int32(output, 2, value.Timestamp);
        ProtoWriter.String(output, 3, value.OpenDateTime);
        ProtoWriter.String(output, 4, value.Hash);
        if (value.SampleInfo is not null) ProtoWriter.Bytes(output, 5, Encode(value.SampleInfo));
        return output.ToArray();
    }

    public static TArgLogin DecodeLogin(ReadOnlySpan<byte> payload)
    {
        var reader = new ProtoReader(payload);
        var pid = string.Empty;
        var timestamp = 0;
        var openDateTime = string.Empty;
        var hash = string.Empty;
        TSampleInfo? sample = null;
        while (reader.TryReadField(out var field, out var wire))
        {
            switch (field)
            {
                case 1 when wire == 2: pid = reader.ReadString(); break;
                case 2 when wire == 0: timestamp = checked((int)reader.ReadVarint()); break;
                case 3 when wire == 2: openDateTime = reader.ReadString(); break;
                case 4 when wire == 2: hash = reader.ReadString(); break;
                case 5 when wire == 2: sample = DecodeSampleInfo(reader.ReadBytes()); break;
                default: reader.Skip(wire); break;
            }
        }
        return new TArgLogin(pid, timestamp, openDateTime, hash, sample);
    }

    public static byte[] Encode(TRetLogin value)
    {
        using var output = new MemoryStream();
        ProtoWriter.String(output, 1, value.Ret);
        ProtoWriter.String(output, 2, value.FeignRoleId);
        // ErrCode (field 3) is checked explicitly by the client (msg.ErrCode == 0), so it
        // must be written even when its value is 0 (protobuf would otherwise omit it).
        ProtoWriter.Varint(output, 3u << 3);
        ProtoWriter.Varint(output, unchecked((ulong)(long)value.ErrCode));
        return output.ToArray();
    }

    public static TRetLogin DecodeLoginResponse(ReadOnlySpan<byte> payload)
    {
        var reader = new ProtoReader(payload);
        var ret = string.Empty;
        var role = string.Empty;
        while (reader.TryReadField(out var field, out var wire))
        {
            switch (field)
            {
                case 1 when wire == 2: ret = reader.ReadString(); break;
                case 2 when wire == 2: role = reader.ReadString(); break;
                default: reader.Skip(wire); break;
            }
        }
        return new TRetLogin(ret, role);
    }

    private static byte[] Encode(TSampleInfo value)
    {
        using var output = new MemoryStream();
        ProtoWriter.String(output, 1, value.Uuid);
        ProtoWriter.String(output, 2, value.Model);
        ProtoWriter.String(output, 3, value.Release);
        ProtoWriter.String(output, 4, value.Network);
        ProtoWriter.String(output, 5, value.Platform);
        ProtoWriter.String(output, 6, value.PkgName);
        return output.ToArray();
    }

    private static TSampleInfo DecodeSampleInfo(ReadOnlySpan<byte> payload)
    {
        var values = new string[6];
        var reader = new ProtoReader(payload);
        while (reader.TryReadField(out var field, out var wire))
        {
            if (field is >= 1 and <= 6 && wire == 2) values[field - 1] = reader.ReadString();
            else reader.Skip(wire);
        }
        return new TSampleInfo(values[0], values[1], values[2], values[3], values[4], values[5]);
    }

    private static class ProtoWriter
    {
        public static void String(Stream output, int field, string value)
        {
            if (string.IsNullOrEmpty(value)) return;
            Bytes(output, field, Encoding.UTF8.GetBytes(value));
        }

        public static void Int32(Stream output, int field, int value)
        {
            if (value == 0) return;
            Varint(output, (ulong)(field << 3));
            Varint(output, unchecked((ulong)(long)value));
        }

        public static void Bytes(Stream output, int field, ReadOnlySpan<byte> value)
        {
            Varint(output, (ulong)((field << 3) | 2));
            Varint(output, (ulong)value.Length);
            output.Write(value);
        }

        internal static void Varint(Stream output, ulong value)
        {
            while (value >= 0x80)
            {
                output.WriteByte((byte)(value | 0x80));
                value >>= 7;
            }
            output.WriteByte((byte)value);
        }
    }

    internal ref struct ProtoReader
    {
        private ReadOnlySpan<byte> _data;
        private int _offset;
        public ProtoReader(ReadOnlySpan<byte> data) => _data = data;

        public bool TryReadField(out int field, out int wire)
        {
            if (_offset >= _data.Length) { field = wire = 0; return false; }
            var key = ReadVarint();
            field = checked((int)(key >> 3));
            wire = (int)(key & 7);
            if (field <= 0) throw new InvalidDataException("Invalid protobuf field number");
            return true;
        }

        public ulong ReadVarint()
        {
            ulong value = 0;
            for (var shift = 0; shift < 64; shift += 7)
            {
                if (_offset >= _data.Length) throw new EndOfStreamException("Truncated protobuf varint");
                var current = _data[_offset++];
                value |= (ulong)(current & 0x7f) << shift;
                if ((current & 0x80) == 0) return value;
            }
            throw new InvalidDataException("Protobuf varint is too long");
        }

        public string ReadString() => Encoding.UTF8.GetString(ReadBytes());

        public ReadOnlySpan<byte> ReadBytes()
        {
            var length = checked((int)ReadVarint());
            if (length < 0 || _offset + length > _data.Length) throw new EndOfStreamException("Truncated protobuf value");
            var value = _data.Slice(_offset, length);
            _offset += length;
            return value;
        }

        public void Skip(int wire)
        {
            switch (wire)
            {
                case 0: ReadVarint(); break;
                case 1: Advance(8); break;
                case 2: Advance(checked((int)ReadVarint())); break;
                case 5: Advance(4); break;
                default: throw new InvalidDataException($"Unsupported protobuf wire type {wire}");
            }
        }

        private void Advance(int length)
        {
            if (length < 0 || _offset + length > _data.Length) throw new EndOfStreamException("Truncated protobuf field");
            _offset += length;
        }
    }
}

public sealed record GameLoginFrame(int Operation, byte[] Payload);

public sealed record ClientGameMessage(byte Channel, byte Operation, long SessionId, byte State, byte[] Payload);

public sealed record TUserInfo(ulong Uid = 0, string Uname = "舰长", int Level = 0, int Class = 0);

public static class UserInfoCodec
{
    public static byte[] Encode(TUserInfo value)
    {
        using var output = new MemoryStream();
        if (value.Uid != 0) { WriteKey(output, 1, 0); WriteVarint(output, value.Uid); }
        if (!string.IsNullOrEmpty(value.Uname)) { WriteKey(output, 2, 2); WriteStringBody(output, value.Uname); }
        if (value.Level != 0) { WriteKey(output, 3, 0); WriteVarint(output, unchecked((ulong)(long)value.Level)); }
        if (value.Class != 0) { WriteKey(output, 4, 0); WriteVarint(output, unchecked((ulong)(long)value.Class)); }
        return output.ToArray();
    }

    private static void WriteKey(Stream output, int field, int wire) => WriteVarint(output, (ulong)((field << 3) | wire));

    private static void WriteVarint(Stream output, ulong value)
    {
        while (value >= 0x80) { output.WriteByte((byte)(value | 0x80)); value >>= 7; }
        output.WriteByte((byte)value);
    }

    private static void WriteStringBody(Stream output, string value)
    {
        var bytes = Encoding.UTF8.GetBytes(value);
        WriteVarint(output, (ulong)bytes.Length);
        output.Write(bytes);
    }
}

public static class ClientGameWireCodec
{
    public const byte DefaultChannel = 0;
    public const byte ServerMessageHandler = 5;
    public const int ClientHeaderLength = 11;

    public static byte[] EncodeClientRequest(byte operation, ReadOnlySpan<byte> payload,
        long sessionId = 0, byte state = 0)
    {
        var result = new byte[ClientHeaderLength + payload.Length];
        result[0] = DefaultChannel;
        result[1] = operation;
        BinaryPrimitives.WriteInt64LittleEndian(result.AsSpan(2, 8), sessionId);
        result[10] = state;
        payload.CopyTo(result.AsSpan(ClientHeaderLength));
        return result;
    }

    public static ClientGameMessage DecodeClientRequest(ReadOnlySpan<byte> packet)
    {
        if (packet.Length < ClientHeaderLength) throw new InvalidDataException("Truncated client game packet");
        return new ClientGameMessage(packet[0], packet[1],
            BinaryPrimitives.ReadInt64LittleEndian(packet.Slice(2, 8)), packet[10],
            packet[ClientHeaderLength..].ToArray());
    }

    public static byte[] EncodeServerResponse(byte operation, ReadOnlySpan<byte> payload,
        int ackId = 0, int frame = 0, int index = 0)
    {
        using var netOperation = new MemoryStream();
        GameLoginCodec.WriteInt32(netOperation, 1, frame);
        GameLoginCodec.WriteInt32(netOperation, 2, index);
        GameLoginCodec.WriteInt32(netOperation, 3, operation);
        GameLoginCodec.WriteBytes(netOperation, 4, payload);

        using var ackPack = new MemoryStream();
        GameLoginCodec.WriteInt32(ackPack, 1, ackId);
        GameLoginCodec.WriteBytes(ackPack, 2, netOperation.ToArray());
        var envelope = ackPack.ToArray();
        var packet = new byte[2 + envelope.Length];
        packet[0] = DefaultChannel;
        packet[1] = ServerMessageHandler;
        envelope.CopyTo(packet.AsSpan(2));
        return packet;
    }

    public static GameLoginFrame DecodeServerResponse(ReadOnlySpan<byte> packet)
    {
        if (packet.Length < 2 || packet[0] != DefaultChannel || packet[1] != ServerMessageHandler)
            throw new InvalidDataException("Invalid server game packet header");
        var ack = new ProtoEnvelopeReader(packet[2..]);
        ReadOnlySpan<byte> operation = default;
        while (ack.TryReadField(out var field, out var wire))
        {
            if (field == 2 && wire == 2) { operation = ack.ReadBytes(); break; }
            ack.Skip(wire);
        }
        if (operation.IsEmpty) throw new InvalidDataException("Server packet has no operation");
        var op = new ProtoEnvelopeReader(operation);
        var operationCode = 0;
        byte[] payload = [];
        while (op.TryReadField(out var field, out var wire))
        {
            if (field == 3 && wire == 0) operationCode = checked((int)op.ReadVarint());
            else if (field == 4 && wire == 2) payload = op.ReadBytes().ToArray();
            else op.Skip(wire);
        }
        return new GameLoginFrame(operationCode, payload);
    }

    private ref struct ProtoEnvelopeReader
    {
        private ReadOnlySpan<byte> _data;
        private int _offset;
        public ProtoEnvelopeReader(ReadOnlySpan<byte> data) => _data = data;
        public bool TryReadField(out int field, out int wire)
        {
            if (_offset >= _data.Length) { field = wire = 0; return false; }
            var key = ReadVarint(); field = checked((int)(key >> 3)); wire = (int)(key & 7); return true;
        }
        public ulong ReadVarint()
        {
            ulong value = 0;
            for (var shift = 0; shift < 64; shift += 7)
            {
                if (_offset >= _data.Length) throw new EndOfStreamException("Truncated protobuf varint");
                var current = _data[_offset++]; value |= (ulong)(current & 0x7f) << shift;
                if ((current & 0x80) == 0) return value;
            }
            throw new InvalidDataException("Protobuf varint is too long");
        }
        public ReadOnlySpan<byte> ReadBytes()
        {
            var length = checked((int)ReadVarint());
            if (_offset + length > _data.Length) throw new EndOfStreamException("Truncated protobuf value");
            var value = _data.Slice(_offset, length); _offset += length; return value;
        }
        public void Skip(int wire)
        {
            if (wire == 0) { ReadVarint(); return; }
            if (wire == 2) { ReadBytes(); return; }
            var length = wire == 1 ? 8 : wire == 5 ? 4 : throw new InvalidDataException($"Unsupported wire type {wire}");
            if (_offset + length > _data.Length) throw new EndOfStreamException("Truncated protobuf field");
            _offset += length;
        }
    }
}

public static class GameLoginFrameCodec
{
    public static async Task WriteAsync(Stream stream, GameLoginFrame frame, CancellationToken ct = default)
    {
        if (frame.Payload.Length > 4 * 1024 * 1024) throw new InvalidDataException("Game login frame is too large");
        var header = new byte[8];
        BinaryPrimitives.WriteInt32BigEndian(header, checked(frame.Payload.Length + 4));
        BinaryPrimitives.WriteInt32BigEndian(header.AsSpan(4), frame.Operation);
        await stream.WriteAsync(header, ct);
        await stream.WriteAsync(frame.Payload, ct);
        await stream.FlushAsync(ct);
    }

    public static async Task<GameLoginFrame?> ReadAsync(Stream stream, CancellationToken ct = default)
    {
        var header = new byte[8];
        if (!await ReadExactAsync(stream, header, ct)) return null;
        var length = BinaryPrimitives.ReadInt32BigEndian(header);
        if (length is < 4 or > 4 * 1024 * 1024) throw new InvalidDataException("Invalid game login frame length");
        var payload = new byte[length - 4];
        if (!await ReadExactAsync(stream, payload, ct)) throw new EndOfStreamException("Truncated game login frame");
        return new GameLoginFrame(BinaryPrimitives.ReadInt32BigEndian(header.AsSpan(4)), payload);
    }

    public static byte[] Encode(GameLoginFrame frame)
    {
        if (frame.Payload.Length > 4 * 1024 * 1024) throw new InvalidDataException("Game login frame is too large");
        var result = new byte[8 + frame.Payload.Length];
        BinaryPrimitives.WriteInt32BigEndian(result, checked(frame.Payload.Length + 4));
        BinaryPrimitives.WriteInt32BigEndian(result.AsSpan(4), frame.Operation);
        frame.Payload.CopyTo(result, 8);
        return result;
    }

    public static GameLoginFrame Decode(ReadOnlySpan<byte> packet)
    {
        if (packet.Length < 8) throw new InvalidDataException("Truncated game login frame");
        var length = BinaryPrimitives.ReadInt32BigEndian(packet);
        if (length is < 4 || packet.Length < length + 4) throw new InvalidDataException("Invalid game login frame length");
        var operation = BinaryPrimitives.ReadInt32BigEndian(packet.Slice(4));
        return new GameLoginFrame(operation, packet.Slice(8, length - 4).ToArray());
    }

    private static async Task<bool> ReadExactAsync(Stream stream, byte[] buffer, CancellationToken ct)
    {
        var offset = 0;
        while (offset < buffer.Length)
        {
            var read = await stream.ReadAsync(buffer.AsMemory(offset), ct);
            if (read == 0) return offset == 0;
            offset += read;
        }
        return true;
    }
}
