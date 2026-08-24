using System.Text;
using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;
using BlueOath.Storage;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

internal sealed partial class GameLoginMessageHandler
{

    /// <summary>
    /// 处理 hero.ChangeEquip：装备穿脱（EquipId&gt;0 = 装备，EquipId=0 = 卸下）。
    /// 更新 Hero.EquipSlots 和 EquipItem.HeroId，落盘后返回空响应（客户端通过推送刷新）。
    /// </summary>
    internal async Task<byte[]> BuildChangeEquipRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return [];
        (uint heroId, int luaIndex, uint equipId, _) = TMessageCodec.DecodeHeroChangeEquipArgs(request.Args);
        // Lua 客户端发送 1-based 索引，C# 数组是 0-based，需要转换。
        int index = luaIndex - 1;
        if (index < 0 || index >= 6)
            return [];
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);

        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0)
            return [];
        Hero hero = heroList[heroIdx];

        // 获取当前装备槽数组
        uint[] slots = (hero.EquipSlots ?? new uint[] { 0, 0, 0, 0, 0, 0 }).ToArray();

        // 如果旧槽有装备，先卸下
        uint oldEquipId = slots[index];
        if (oldEquipId != 0)
        {
            account = SetEquipHeroId(account, oldEquipId, 0);
            slots[index] = 0;
        }

        // 新装备上装
        if (equipId != 0)
        {
            account = SetEquipHeroId(account, equipId, heroId);
            slots[index] = equipId;
        }

        heroList[heroIdx] = hero with { EquipSlots = slots };
        account = account with { Dock = dock with { Heroes = heroList } };
        await _repo.SaveAccountAsync(account, ct);

        return [];
    }

    /// <summary>设置装备的 HeroId（装备/卸下）。</summary>
    internal static PlayerAccount SetEquipHeroId(PlayerAccount account, uint equipId, uint heroId)
    {
        PlayerEquip equip = account.Equip ?? new PlayerEquip([], 2000);
        List<EquipItem> items = equip.Items.ToList();
        int idx = items.FindIndex(e => e.EquipId == equipId);
        if (idx >= 0)
            items[idx] = items[idx] with { HeroId = heroId };
        return account with { Equip = equip with { Items = items } };
    }

    // GoodsType 常量（constants.lua）。ITEM=1, EQUIP=2, SHIP=3, DROP=4, CURRENCY=5, FASHION=18。
    // 注：GoodsTypeCurrency/Equip/Fashion 已在 Shop.cs 中定义
    private const int GoodsTypeItem = 1;
    private const int GoodsTypeShip = 3;
    private const int GoodsTypeDrop = 4;

    // ExtractType 常量（constants.lua）
    private const int ExtractTypeEquip = 1;
    private const int ExtractTypeShip = 2;
    private const int ExtractTypeFashion = 3;
    private const int ExtractTypeLimitShip = 4;
    private const int ExtractTypeMixTure = 5;

    // HeroRarityType 常量
    private const int RaritySR = 3;
    private const int RaritySSR = 4;

    /// <summary>扁平化后的掉落池条目（已递归展开 GoodsType.DROP）。</summary>
    internal sealed record DropPoolEntry(int GoodsType, int ConfigId, int MinNum, int MaxNum, int Weight);

    /// <summary>
    /// 处理 buildship.BuildShip：按 config_extract_ship → config_drop_item 标准流程抽取。
    /// 抽取到的舰娘加入船坞，返回 TBuildShipRet{BuildShipResult=[TCommonReward]}。
    /// 10 连保底至少一个 SR（quality>=3）。
    /// </summary>
    internal async Task<byte[]> BuildBuildShipRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return [];
        (int extractId, int num, _) = DecodeBuildShipArg(request.Args);
        if (num <= 0) num = 1;
        if (num > 10) num = 10;

        if (!_extractShips.TryGetValue(extractId, out var extractConfig))
            return [];

        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        List<CommonReward> rewards = new();
        _lastBuildHeroIds = new List<uint>();

        var entries = FlattenDropPool((int)extractConfig.DropItemId);
        if (entries.Count == 0)
            return [];

        long extractType = extractConfig.ExtractType;

        for (int i = 0; i < num; i++)
        {
            var entry = WeightedPick(entries);
            if (entry.GoodsType == GoodsTypeShip)
            {
                uint heroId = _nextHeroId++;
                account = AddShip(account, heroId, entry.ConfigId, now);
                _lastBuildHeroIds.Add(heroId);
                rewards.Add(new CommonReward(GoodsTypeShip, entry.ConfigId, entry.MinNum, (int)heroId));
            }
            else if (entry.GoodsType == GoodsTypeEquip)
            {
                uint equipId = AddEquip(account, entry.ConfigId, now);
                rewards.Add(new CommonReward(GoodsTypeEquip, entry.ConfigId, entry.MinNum, (int)equipId));
            }
            else
            {
                rewards.Add(new CommonReward(entry.GoodsType, entry.ConfigId, entry.MinNum));
            }
        }

        // 10 连保底：至少一个 SR（quality>=3）。仅对舰船类型卡池生效。
        if (num == 10 && (extractType == ExtractTypeShip || extractType == ExtractTypeLimitShip))
        {
            bool hasSR = rewards.Any(r => r.Type == GoodsTypeShip && GetShipRarity(r.ConfigId) >= RaritySR);
            if (!hasSR)
            {
                var srPlusEntries = entries.Where(
                    e => e.GoodsType == GoodsTypeShip && GetShipRarity(e.ConfigId) >= RaritySR).ToList();
                if (srPlusEntries.Count > 0)
                {
                    // 从后往前找到最后一个舰船奖励并替换
                    for (int i = rewards.Count - 1; i >= 0; i--)
                    {
                        if (rewards[i].Type == GoodsTypeShip)
                        {
                            var newEntry = WeightedPick(srPlusEntries);
                            uint oldHeroId = (uint)rewards[i].Id;
                            account = RemoveHero(account, oldHeroId);
                            _lastBuildHeroIds.Remove(oldHeroId);
                            uint newHeroId = _nextHeroId++;
                            account = AddShip(account, newHeroId, newEntry.ConfigId, now);
                            _lastBuildHeroIds.Add(newHeroId);
                            rewards[i] = new CommonReward(GoodsTypeShip, newEntry.ConfigId, newEntry.MinNum, (int)newHeroId);
                            break;
                        }
                    }
                }
            }
        }

        if (rewards.Count > 0)
            await _repo.SaveAccountAsync(account, ct);

        return EncodeBuildShipRet(rewards);
    }

    /// <summary>
    /// 递归展开 config_drop_item 掉落池，将 GoodsType.DROP 嵌套条目展开为最终物品列表。
    /// </summary>
    private List<DropPoolEntry> FlattenDropPool(int dropItemId, int countMul = 1)
    {
        var result = new List<DropPoolEntry>();
        if (!_dropItems.TryGetValue(dropItemId, out var dropItem))
            return result;

        if (dropItem.DropRate > 0 && dropItem.Drop is { Count: > 0 })
            FlattenDropEntries(dropItem.Drop, countMul, result);

        if (dropItem.DropAloneCount > 0 && dropItem.DropAlone is { Count: > 0 })
            FlattenDropEntries(dropItem.DropAlone, (int)dropItem.DropAloneCount * countMul, result);

        return result;
    }

    private void FlattenDropEntries(List<List<long>> entries, int countMul, List<DropPoolEntry> result)
    {
        foreach (var entry in entries)
        {
            if (entry.Count < 5) continue;
            int goodsType = (int)entry[0];
            int configId = (int)entry[1];
            int minNum = (int)entry[2] * countMul;
            int maxNum = (int)entry[3] * countMul;
            int weight = (int)entry[4];
            if (weight == 0) continue;

            if (goodsType == GoodsTypeDrop)
            {
                var nested = FlattenDropPool(configId, countMul);
                result.AddRange(nested);
            }
            else
            {
                result.Add(new DropPoolEntry(goodsType, configId, minNum, maxNum, weight));
            }
        }
    }

    /// <summary>按权重随机抽取一个掉落池条目。</summary>
    private DropPoolEntry WeightedPick(List<DropPoolEntry> entries)
    {
        int totalWeight = entries.Sum(e => e.Weight);
        if (totalWeight <= 0) return entries[0];
        int roll = _rng.Next(totalWeight);
        int cumulative = 0;
        foreach (var e in entries)
        {
            cumulative += e.Weight;
            if (roll < cumulative)
                return e;
        }
        return entries[^1];
    }

    /// <summary>通过 ship_info_id 获取舰娘稀有度（quality）。</summary>
    private int GetShipRarity(int templateId)
    {
        int siId = (templateId - 1) / 10;
        return _shipInfos.TryGetValue(siId, out var info) ? (int)info.Quality : 0;
    }

    /// <summary>从船坞移除指定舰娘。</summary>
    internal static PlayerAccount RemoveHero(PlayerAccount account, uint heroId)
    {
        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        heroes.RemoveAll(h => h.HeroId == heroId);
        return account with { Dock = dock with { Heroes = heroes } };
    }

    /// <summary>装备加入仓库</summary>
    internal uint AddEquip(PlayerAccount account, int templateId, int now)
    {
        // 简化实现：作为 CommonReward 返回，不实际加入装备仓库
        return 0;
    }

    private List<uint> _lastBuildHeroIds = [];

    /// <summary>舰娘加入船坞：创建 Hero 实例。Affection=1000 避免 GetLoveInfo 返回 nil。</summary>
    internal static PlayerAccount AddShip(PlayerAccount account, uint heroId, int templateId, int now)
    {
        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        int fashioning = (templateId - 1) / 10;
        heroes.Add(new Hero(heroId, templateId, 1,
            fashioning, CreateTime: now, UpdateTime: now, Affection: 1000, CurHp: PlayerAccountFactory.HpCoefficient,
            Mood: 0, MarryType: 0));
        return account with { Dock = dock with { Heroes = heroes } };
    }

    internal static PlayerAccount SetAffection(PlayerAccount account, uint heroId, int amount)
    {
        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        int idx = heroes.FindIndex(h => h.HeroId == heroId);
        if (idx < 0) return account;
        int affection = amount * 10000;
        heroes[idx] = heroes[idx] with { Affection = affection };
        return account with { Dock = dock with { Heroes = heroes } };
    }

    private const int MarryRingTemplateId = 10180;

    internal async Task<byte[]> BuildMarryRetAsync(TRequest request, string profileId, int now, CancellationToken ct)
    {
        var (heroId, marryType) = DecodeMarryArg(request.Args ?? []);
        var account = await GetOrCreateAccountAsync(profileId, ct);

        var heroes = account.Dock.Heroes.ToList();
        var heroIdx = heroes.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return TMessageCodec.EncodeResponse(new TResponse(Err: 1, ErrMsg: "hero not found"));

        var hero = heroes[heroIdx];
        if (hero.MarryTime != 0) return TMessageCodec.EncodeResponse(new TResponse(Err: 2, ErrMsg: "already married"));

        heroes[heroIdx] = hero with { MarryTime = now, MarryType = marryType };
        account = account with { Dock = account.Dock with { Heroes = heroes } };
        account = account with { Character = account.Character with { MarriedNum = account.Character.MarriedNum + 1 } };
        account = AddBagItem(account, MarryRingTemplateId, -1);

        await _repo.SaveAccountAsync(account, ct);
        return TMessageCodec.EncodeResponse(new TResponse(Method: "hero.Marry", Time: checked((uint)now)));
    }

    private static (uint HeroId, int MarryType) DecodeMarryArg(ReadOnlySpan<byte> payload)
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
        return (heroId, marryType);
    }

    /// <summary>解码 TBuildShipArg: Id(1, int32), Num(2, int32), CacheId(3, string)。</summary>
    private static (int Id, int Num, string CacheId) DecodeBuildShipArg(ReadOnlySpan<byte> payload)
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

        return (id, num, cacheId);
    }

    /// <summary>编码 TBuildShipRet: BuildShipResult(1, repeated TCommonReward)。</summary>
    internal static byte[] EncodeBuildShipRet(IReadOnlyList<CommonReward> rewards)
    {
        using MemoryStream output = new();
        foreach (CommonReward r in rewards)
        {
            using MemoryStream item = new();
            if (r.Type != 0)
            {
                item.WriteByte(0x08);
                WriteVarint(item, unchecked((ulong)r.Type));
            }

            if (r.ConfigId != 0)
            {
                item.WriteByte(0x10);
                WriteVarint(item, unchecked((ulong)r.ConfigId));
            }

            if (r.Num != 0)
            {
                item.WriteByte(0x18);
                WriteVarint(item, unchecked((ulong)r.Num));
            }

            item.WriteByte(0x20);
            WriteVarint(item, unchecked((ulong)r.Id));
            byte[] body = item.ToArray();
            output.WriteByte(0x0A);
            WriteVarint(output, (ulong)body.Length);
            output.Write(body);
        }

        // SpReward(2) 和 TransReward(3) 各编码一个空元素，避免 _LoadTenCard 里
        // self.transReward[nIndex].Reward 访问 nil 崩溃。
        for (int i = 0; i < rewards.Count; i++)
        {
            output.WriteByte(0x12);
            output.WriteByte(0x00); // SpReward
            output.WriteByte(0x1A);
            output.WriteByte(0x00); // TransReward
        }

        return output.ToArray();
    }

    /// <summary>构建头像解锁列表推送（TNewHeadUnlockedList），包含船坞中所有舰娘的 sf_id。</summary>
    private static byte[] BuildHeadUnlockedListPush(PlayerAccount account)
    {
        // 收集船坞中所有舰娘的 sf_id（ship_info_id = (TemplateId - 1) / 10）
        List<int> sfIds = account.Dock.Heroes
            .Select(h => (h.TemplateId - 1) / 10)
            .Distinct()
            .ToList();
        using MemoryStream output = new();
        foreach (int sfId in sfIds)
        {
            // TNewHeadNode: ShipFleetId(1, int32), ProfileID(2, repeated int32)
            using MemoryStream node = new();
            WriteVarint(node, 0x08);
            WriteVarint(node, unchecked((ulong)sfId)); // ShipFleetId
            WriteVarint(node, 0x10);
            WriteVarint(node, unchecked((ulong)sfId)); // ProfileID = sfId
            byte[] body = node.ToArray();
            output.WriteByte(0x0A); // UnlockedList field 1, wire 2
            WriteVarint(output, (ulong)body.Length);
            output.Write(body);
        }

        return output.ToArray();
    }

    internal static void WriteVarint(Stream output, ulong value)
    {
        while (value >= 0x80)
        {
            output.WriteByte((byte)(value | 0x80));
            value >>= 7;
        }

        output.WriteByte((byte)value);
    }

    internal ref struct ProtoReader
    {
        private readonly ReadOnlySpan<byte> _data;
        private int _offset;

        public ProtoReader(ReadOnlySpan<byte> data)
        {
            _data = data;
            _offset = 0;
        }

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

    /// <summary>
    /// 处理用户档案更新（秘书舰/改名/签名/头像/头像框）。
    /// 解码对应协议的 arg，更新 PlayerCharacter，落盘，返回空响应。
    /// </summary>
    internal async Task<byte[]> BuildUserProfileUpdateAsync(TRequest request, string profileId, CancellationToken ct,
        string field)
    {
        if (request.Args is null) return [];
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        PlayerCharacter c = account.Character;

        if (field == "Secretary")
        {
            // TSetUserSecretaryArg: SecretaryId(1, uint32)
            ulong secId = DecodeVarintField(request.Args, 1);
            if (secId == 0) return [];
            c = c with { SecretaryId = (uint)secId };
        }
        else if (field == "Name")
        {
            // TUserChangeNameArg: Name(1, string)
            string? name = DecodeStringField(request.Args, 1);
            if (string.IsNullOrWhiteSpace(name)) return [];
            c = c with { Name = name };
        }
        else if (field == "Message")
        {
            // TSetUserMsgArg: Message(1, string)
            string? msg = DecodeStringField(request.Args, 1);
            c = c with { Message = msg ?? "" };
        }
        else if (field == "HeadFrame")
        {
            // TUserSetPlayerHeadFrameArg: headFrameId(1, int32)
            ulong frameId = DecodeVarintField(request.Args, 1);
            c = c with { HeadFrame = (int)frameId };
        }
        else if (field == "Head")
        {
            // TNewHeadBuyHeadArg: ShipFleetId(1, int32), ProfileID(2, int32) — 取 ProfileID
            ulong profileId_i = DecodeVarintField(request.Args, 2);
            if (profileId_i == 0) return [];
            c = c with { Head = (int)profileId_i };
        }
        else
        {
            return [];
        }

        account = account with { Character = c };
        await _repo.SaveAccountAsync(account, ct);
        return [];
    }

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

    internal async Task<byte[]> BuildAddExpRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        (uint heroId, List<(int Id, int Num)> items) = DecodeHeroAddExp(request.Args);
        if (heroId == 0 || items.Count == 0) return [];

        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];
        Hero hero = heroList[heroIdx];

        int totalExp = 0;
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> bagItems = bag.Items.ToList();
        foreach ((int itemId, int num) in items)
        {
            if (!_expPerItem.TryGetValue(itemId, out int perExp)) continue;
            totalExp += perExp * num;
            int bagIdx = bagItems.FindIndex(i => i.TemplateId == itemId);
            if (bagIdx >= 0)
            {
                int newNum = bagItems[bagIdx].Num - num;
                if (newNum <= 0) bagItems.RemoveAt(bagIdx);
                else bagItems[bagIdx] = bagItems[bagIdx] with { Num = newNum };
            }
        }

        if (totalExp == 0) return [];

        int level = hero.Level;
        int exp = hero.Exp + totalExp;
        int maxLevel = 200;
        while (level < maxLevel)
        {
            int needExp = _expNeeded.GetValueOrDefault(level, 500);
            if (exp < needExp) break;
            exp -= needExp;
            level++;
        }

        heroList[heroIdx] = hero with { Level = level, Exp = exp };
        account = account with { Dock = dock with { Heroes = heroList }, Bag = bag with { Items = bagItems } };
        await _repo.SaveAccountAsync(account, ct);

        return EncodeHeroAddExpRet(heroId, items);
    }

    private static (uint HeroId, List<(int Id, int Num)> Items) DecodeHeroAddExp(ReadOnlySpan<byte> data)
    {
        ProtoReader reader = new(data);
        uint heroId = 0;
        List<(int, int)> items = new();
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
                if (curId > 0 && curNum > 0) items.Add((curId, curNum));
            }
            else
            {
                reader.Skip(wire);
            }

        return (heroId, items);
    }

    private static byte[] EncodeHeroAddExpRet(uint heroId, List<(int Id, int Num)> items)
    {
        using MemoryStream output = new();
        if (heroId != 0)
        {
            output.WriteByte(0x08);
            WriteVarint(output, heroId);
        }

        foreach ((int id, int num) in items)
        {
            using MemoryStream item = new();
            if (id != 0)
            {
                item.WriteByte(0x10);
                WriteVarint(item, unchecked((ulong)id));
            }

            if (num != 0)
            {
                item.WriteByte(0x18);
                WriteVarint(item, unchecked((ulong)num));
            }

            byte[] body = item.ToArray();
            output.WriteByte(0x12);
            WriteVarint(output, (ulong)body.Length);
            output.Write(body);
        }

        return output.ToArray();
    }

    internal async Task<byte[]> BuildGetHerosTacticAsync(string profileId, CancellationToken ct)
    {
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        PlayerFleet fleet = account.Fleet ?? PlayerAccountFactory.DefaultFleet();
        return EncodeFleet(fleet);
    }

    internal async Task<byte[]> BuildSetHerosTacticAsync(TRequest request, string profileId, CancellationToken ct)
    {
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        List<FleetEntry> entries = DecodeSetHerosTactic(request.Args ?? []);
        PlayerFleet newFleet = new(entries);
        PlayerAccount updated = account with { Fleet = newFleet };
        await _repo.SaveAccountAsync(updated, ct);
        return EncodeFleet(newFleet);
    }

    /// <summary>推送当前章节的 copy.GetCopy 数据。markPassed=true 表示上一章已通关。</summary>
    public async Task<byte[]> BuildCopyPushAsync(string profileId, uint now, CancellationToken ct)
    {
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        int chapterId = account.Character.PlotChapterId;
        return TMessageCodec.EncodeResponse(new TResponse(
            Method: "copy.GetCopy",
            Ret: EncodePlotCopyInfo(chapterId, account.CopyProgress),
            Time: now));
    }

    internal async Task<byte[]> BuildStartBaseRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        try
        {
            PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
            byte[] args = request.Args ?? [];
            (int copyId, List<int>? deployHeroIds, bool isRunningFight, int battleMode, int matchType) =
                DecodeStartBaseArg(args);
            _fileLogger.LogInformation(
                "copy.StartBase argsLen={Len} hex={Hex} copyId={CopyId} deployHeroIds={Deploy} isRunningFight={IsRunning}",
                args.Length, Convert.ToHexString(args), copyId,
                deployHeroIds is null ? "<null>" : string.Join(",", deployHeroIds), isRunningFight);
            List<Hero> heroList = account.Dock.Heroes.ToList();
            // 关卡出战舰队必须回环客户端请求里的 HeroList（剧情关限制），
            // 而不是从玩家编队猜。请求未带时回退到全部船。
            _copyRandomFactors.TryGetValue(copyId, out List<RandomFactorEntry>? randomFactors);
            return EncodeStartBaseRet(copyId, heroList, account.Character, deployHeroIds, isRunningFight, battleMode,
                matchType, randomFactors);
        }
        catch (Exception ex)
        {
            _fileLogger.LogError(ex, "BuildStartBaseRetAsync failed");
            return [];
        }
    }

    public byte[] EncodeMutiBattleRet(int copyId, List<Hero> heroes, PlayerCharacter character)
    {
        // TBattleCreateMutiRet{ BattleId(1), Ip(2), Port(3), Arg(4=TBattleCreateMutiArg) }
        // TBattleCreateMutiArg 字段与 TStartBaseRet 相同
        using MemoryStream ms = new();
        WriteVarint(ms, 0x08);
        WriteVarint(ms, 1); // BattleId=1
        // Arg (4) = TBattleCreateMutiArg，与 TStartBaseRet 编码相同
        _copyRandomFactors.TryGetValue(copyId, out List<RandomFactorEntry>? randomFactors);
        byte[] arg = EncodeStartBaseRet(copyId, heroes, character, null, randomFactors: randomFactors);
        WriteVarint(ms, 0x22);
        WriteVarint(ms, (ulong)arg.Length);
        ms.Write(arg);
        return ms.ToArray();
    }

    internal static byte[] EncodeStartBaseRet(int copyId, List<Hero> heroes, PlayerCharacter character,
        IReadOnlyList<int>? deployHeroIds = null,
        bool isRunningFight = false, int battleMode = 1, int matchType = 0,
        IReadOnlyList<RandomFactorEntry>? randomFactors = null)
    {
        // 本关全部敌舰队 id（config_copy → fleet_id 数组）。客户端
        // BattleStartData.enemyFleetId 是 int[]，PlayerInterface.InitNpc 遍历它逐个生成
        // 敌舰队（每舰队含自身 copy_attacheds 附属舰队）。只发单个会导致关卡多舰队时
        // 只生成 1 个敌怪。查不到时回退单值。
        List<int> fleetIdList = CopyBattleLoader.GetFleetIdList(copyId);

        // 出战船只按客户端请求顺序（剧情关可能带临时/支援舰船，其 HeroId 不在玩家船坞，
        // 需从 config_assist_ship_info 加载回环，否则临时舰船丢失）。编队为空时回退到全部船。
        List<Hero> deploy;
        if (deployHeroIds is { Count: > 0 })
        {
            Dictionary<int, Hero> byId = heroes.ToDictionary(h => (int)h.HeroId);
            deploy = new List<Hero>();
            foreach (int id in deployHeroIds)
            {
                if (byId.TryGetValue(id, out Hero? hero))
                {
                    deploy.Add(hero);
                }
                else if (AssistShipLoader.Get(id) is { } assist)
                {
                    int templateId = checked((int)assist.ShipMainId);
                    deploy.Add(new Hero((uint)id, templateId, checked((int)assist.ShipLevel),
                        (templateId - 1) / 10));
                }

                if (deploy.Count >= 6) break;
            }
        }
        else
        {
            deploy = heroes.Take(6).ToList();
        }

        using MemoryStream ms = new();
        // BattlePlayer (1) — TBattlePlayerList with full fleet data
        using MemoryStream bpList = new();
        using MemoryStream bp = new();
        WriteVarint(bp, 0x08);
        WriteVarint(bp, character.Uid); // Pid
        WriteVarint(bp, 0x10);
        WriteVarint(bp, character.Uid); // Uid
        WriteString(bp, 0x1A, character.Name); // Uname
        WriteVarint(bp, 0x20);
        WriteVarint(bp, unchecked((ulong)character.Level)); // Level
        WriteVarint(bp, 0x28);
        WriteVarint(bp, 1); // PlayerCamp=1
        WriteVarint(bp, 0x30);
        WriteVarint(bp, 1); // Index=1
        // FleetInfo (7) — TBattleFleet with full ship data
        using MemoryStream fleet = new();
        WriteVarint(fleet, 0x08);
        WriteVarint(fleet, 1); // FleetId=1
        WriteVarint(fleet, 0x10);
        WriteVarint(fleet, 2); // FormationId=2
        WriteVarint(fleet, 0x18);
        WriteVarint(fleet, 1); // Index=1
        // Ships (4)
        for (int i = 0; i < deploy.Count; i++)
        {
            Hero h = deploy[i];
            using MemoryStream ship = new();
            WriteVarint(ship, 0x08);
            WriteVarint(ship, (ulong)h.HeroId);
            WriteVarint(ship, 0x10);
            WriteVarint(ship, unchecked((ulong)h.TemplateId));
            WriteVarint(ship, 0x18);
            WriteVarint(ship, unchecked((ulong)h.Level));
            WriteVarint(ship, 0x20);
            WriteVarint(ship, unchecked((ulong)i));
            // Attr (5) — 按船 TemplateId 查 config_ship_main 发真实属性（考虑等级成长），
            // 临时/支援舰船（HeroId 在 config_assist_ship_info）直接用其属性表。
            // 命中判定 __IsHit(hit, dodge) 依赖 Hit/Dodge。
            ConfigAssistShipInfo? assist = AssistShipLoader.Get(checked((int)h.HeroId));
            ConfigShipMain? cfg = ShipMainLoader.Get(h.TemplateId);
            long shipHp, attack, defense, hit, dodge, crit, antiCrit, torpedoAttack, torpedoDefense;
            long planeBomb = 0, planeTorpedo = 0, scoutNum = 1;
            if (assist is not null)
            {
                shipHp = assist.Hp;
                attack = assist.Attack;
                defense = assist.Defense;
                hit = assist.Hit;
                dodge = assist.Dodge;
                crit = assist.Crit;
                antiCrit = assist.AntiCrit;
                torpedoAttack = assist.TorpedoAttack;
                torpedoDefense = assist.TorpedoDefense;
                // 空袭伤害基础 ShipPlaneAttack(14)=舰载机轰炸攻击(ship_bomb_attack)。
                // plane_bomb 是飞机炸弹属性（经飞机装备传递），不是舰载机攻击。
                if (ShipMainLoader.Get(checked((int)assist.ShipMainId)) is { } acfg)
                {
                    planeBomb = acfg.ShipBombAttack;
                    planeTorpedo = acfg.ShipTorpedoAttack;
                    if (acfg.CarryPlaneCount > 0) scoutNum = acfg.CarryPlaneCount;
                }
            }
            else if (cfg is null)
            {
                shipHp = 1000;
                attack = 100;
                defense = 50;
                hit = 100;
                dodge = 35;
                crit = 0;
                antiCrit = 0;
                torpedoAttack = 0;
                torpedoDefense = 0;
            }
            else
            {
                shipHp = ShipMainLoader.Leveled(cfg.Hp, cfg.HpLevelup, h.Level);
                attack = ShipMainLoader.Leveled(cfg.Attack, cfg.AttackLevelup, h.Level);
                defense = ShipMainLoader.Leveled(cfg.Defense, cfg.DefenseLevelup, h.Level);
                hit = cfg.Hit;
                dodge = cfg.Dodge;
                crit = cfg.Crit;
                antiCrit = cfg.AntiCrit;
                torpedoAttack = ShipMainLoader.Leveled(cfg.TorpedoAttack, cfg.TorpedoAttackLevelup, h.Level);
                torpedoDefense = ShipMainLoader.Leveled(cfg.TorpedoDefense, cfg.TorpedoDefenseLevelup, h.Level);
                planeBomb = cfg.ShipBombAttack;
                planeTorpedo = cfg.ShipTorpedoAttack;
                if (cfg.CarryPlaneCount > 0) scoutNum = cfg.CarryPlaneCount;
            }

            foreach ((int attrId, long val) in new[]
                     {
                         (1, shipHp), (5, scoutNum), (8, attack), (9, defense),
                         (10, torpedoAttack), (11, torpedoDefense),
                         (14, planeBomb), (15, planeTorpedo),
                         (17, crit), (18, antiCrit), (19, hit), (20, dodge)
                     })
            {
                using MemoryStream attr = new();
                WriteVarint(attr, 0x08);
                WriteVarint(attr, unchecked((ulong)attrId));
                WriteVarint(attr, 0x10);
                WriteVarint(attr, unchecked((ulong)val));
                byte[] ab = attr.ToArray();
                WriteVarint(ship, 0x2A);
                WriteVarint(ship, (ulong)ab.Length);
                ship.Write(ab);
            }

            WriteVarint(ship, 0x30);
            WriteVarint(ship, PlayerAccountFactory.HpCoefficient); // CurHp(6)
            WriteVarint(ship, 0x58);
            WriteVarint(ship, 3); // EquipGridNum(11)
            WriteVarint(ship, 0x60);
            WriteVarint(ship, unchecked((ulong)h.Fashioning)); // Fashioning(12)
            // PSkill (8) — TFiledPSkillLv[], 每艘船给一个最小技能(PSkillId=1,PSkillLv=1)
            using MemoryStream pskill = new();
            WriteVarint(pskill, 0x08);
            WriteVarint(pskill, 1); // PSkillId=1
            WriteVarint(pskill, 0x10);
            WriteVarint(pskill, 1); // PSkillLv=1
            byte[] pskillBytes = pskill.ToArray();
            WriteVarint(ship, 0x42);
            WriteVarint(ship, (ulong)pskillBytes.Length);
            ship.Write(pskillBytes);
            // Equips (7) — TBattleEquip[]。临时/支援舰船用 config_assist_ship_info.equip。
            // 航母的空袭依赖飞机装备（PlaneNum），否则空袭技能不出现。
            if (assist?.Equip is { Count: > 0 })
                for (int ei = 0; ei < assist.Equip.Count; ei++)
                {
                    int eid = checked((int)assist.Equip[ei]);
                    if (eid == 0) continue;
                    ConfigEquip? ecfg = EquipLoader.Get(eid);
                    using MemoryStream eq = new();
                    WriteVarint(eq, 0x08);
                    WriteVarint(eq, unchecked((ulong)eid)); // EquipTid(1)
                    WriteVarint(eq, 0x10);
                    WriteVarint(eq, unchecked((ulong)ei)); // EquipIndex(2)
                    WriteVarint(eq, 0x18);
                    WriteVarint(eq, 100); // PlaneNum(3)
                    if (ecfg?.EquipProp is { Count: > 0 })
                        foreach (List<long> ap in ecfg.EquipProp)
                            if (ap is { Count: >= 2 })
                            {
                                using MemoryStream av = new();
                                WriteVarint(av, 0x08);
                                WriteVarint(av, unchecked((ulong)ap[0])); // propId
                                WriteVarint(av, 0x10);
                                WriteVarint(av, unchecked((ulong)ap[1])); // value
                                byte[] avb = av.ToArray();
                                WriteVarint(eq, 0x22);
                                WriteVarint(eq, (ulong)avb.Length);
                                eq.Write(avb);
                            }

                    byte[] eqb = eq.ToArray();
                    WriteVarint(ship, 0x3A);
                    WriteVarint(ship, (ulong)eqb.Length);
                    ship.Write(eqb);
                }

            byte[] sb = ship.ToArray();
            WriteVarint(fleet, 0x22);
            WriteVarint(fleet, (ulong)sb.Length);
            fleet.Write(sb);
            // HeroList (8) — one per ship
            WriteVarint(fleet, 0x40);
            WriteVarint(fleet, (ulong)h.HeroId);
        }

        WriteVarint(fleet, 0x28);
        WriteVarint(fleet, 0); // StrategyId=0
        WriteVarint(fleet, 0x38);
        WriteVarint(fleet, 0); // KillTimes=0
        WriteVarint(fleet, 0x48);
        WriteVarint(fleet, 1); // TacticType=1
        byte[] fb = fleet.ToArray();
        WriteVarint(bp, 0x3A);
        WriteVarint(bp, (ulong)fb.Length);
        bp.Write(fb);
        byte[] bpb = bp.ToArray();
        WriteVarint(bpList, 0x0A);
        WriteVarint(bpList, (ulong)bpb.Length);
        bpList.Write(bpb);
        byte[] bplb = bpList.ToArray();
        WriteVarint(ms, 0x0A);
        WriteVarint(ms, (ulong)bplb.Length);
        ms.Write(bplb);
        // RandomSeed (2) — 当前时间戳（秒），避免每次战斗相同随机序列
        WriteVarint(ms, 0x10);
        WriteVarint(ms, unchecked((ulong)(int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()));
        // Rid (3) = config_copy 的 r_id（客户端用它作 copyDictId 查 config_copy -> scene_id）
        int copyRid = CopyBattleLoader.GetConfigId(copyId);
        WriteVarint(ms, 0x18);
        WriteVarint(ms, unchecked((ulong)copyRid));
        // CopyId (6) — 客户端用它在 config_copy_display 里查配置（键=显示 id，来自请求）
        WriteVarint(ms, 0x30);
        WriteVarint(ms, unchecked((ulong)copyId));
        // CopyType (7)：剧情=1(PlotCopy)，海域=2(SeaCopy)。海域关卡战斗初始化按 CopyType 分支。
        // 海域侦察任务按 SeaCopy(2) 走索敌 3D 玩法，是正常逻辑，不能绕开（绕开会失去索敌玩法意义）。
        bool isSeaCopy = ChapterCopyLoader.GetSeaLevels().Contains(copyId);
        WriteVarint(ms, 0x38);
        WriteVarint(ms, isSeaCopy ? (ulong)2 : (ulong)1);
        // RandomFactors (12) — 海域索敌/侦察场景初始化依赖。按 copyId 查表：
        // config_copy_display.random_factor_sets → config_random_factor_set.factor_groups
        // → config_random_factor_group.factor（RandomFactorLoader）。海域 1600100 → [61]。
        // 剧情关 random_factor_sets=[] 无条目，自然不编码。
        if (randomFactors is { Count: > 0 })
        {
            foreach (RandomFactorEntry entry in randomFactors)
            {
                using MemoryStream rf = new();
                foreach (int f in entry.Factors)
                {
                    WriteVarint(rf, 0x08);
                    WriteVarint(rf, unchecked((ulong)f)); // Factors(1)
                }

                if (entry.GroupId != 0)
                {
                    WriteVarint(rf, 0x10);
                    WriteVarint(rf, unchecked((ulong)entry.GroupId)); // GroupId(2)
                }

                if (entry.SetId != 0)
                {
                    WriteVarint(rf, 0x18);
                    WriteVarint(rf, unchecked((ulong)entry.SetId)); // SetId(3)
                }

                byte[] rfb = rf.ToArray();
                WriteVarint(ms, 0x62);
                WriteVarint(ms, (ulong)rfb.Length);
                ms.Write(rfb);
            }
        }

        // CopyPass (8) = false
        // BossProgress (9) = 0
        // IsRunningFight (10) — 回环客户端请求的 IsRunningFight（请求/响应同名字段）
        if (isRunningFight)
        {
            WriteVarint(ms, 0x50);
            WriteVarint(ms, 1);
        }

        // SafeLv (13) = 0
        WriteVarint(ms, 0x68);
        WriteVarint(ms, 0);
        // BattleMode (18) = Normal=1(普通)/Exercises=2(练习)/Memory=3(记忆)/Sweep=4(扫荡)
        // 回环客户端请求的 BattleMode（请求 field 9）
        WriteVarint(ms, 0x90);
        WriteVarint(ms, unchecked((ulong)(battleMode == 0 ? 1 : battleMode)));
        // MatchType (26) = 0 — 回环客户端请求的 MatchType（请求 field 15）
        if (matchType != 0)
        {
            WriteVarint(ms, 0xD0);
            WriteVarint(ms, unchecked((ulong)matchType));
        }

        // 海域索敌：补齐未编码字段（IsFinal/AnimMode/WeatherGroupId），索敌核心初始化可能检查。
        if (isSeaCopy)
        {
            // IsFinal (19) = false
            WriteVarint(ms, 0x98);
            WriteVarint(ms, 0);
            // AnimMode (20) = 0
            WriteVarint(ms, 0xA0);
            WriteVarint(ms, 0);
            // WeatherGroupId (22) = 0 — 客户端 pb TStartBaseRet.WeatherGroupId=22（copy_pb.lua）。
            // 之前误写字段 21(0xA8)，客户端永远读到 0；改 22(0xB0)。
            WriteVarint(ms, 0xB0);
            WriteVarint(ms, 0);
        }

        // Token (16) = ""
        WriteString(ms, 0x82, "1111111111111111111111111111111111111");
        // arrRes (4) — TCopyRes[]。海域索敌 InitResPoint 遍历 copyRess（=arrRes）用元素查
        // battlefield_resource，海域 battlefield_resource[copyId] 缺失导致 GetDict null 卡死。
        // 海域 arrRes 发空（copyRess 空 → InitResPoint 跳过资源点生成）。
        if (!isSeaCopy)
        {
            using MemoryStream cr = new();
            WriteVarint(cr, 0x08);
            WriteVarint(cr, unchecked((ulong)copyId)); // id
            byte[] crb = cr.ToArray();
            WriteVarint(ms, 0x22);
            WriteVarint(ms, (ulong)crb.Length);
            ms.Write(crb);
        }

        // CopyMission (23) — repeated int32。注意：字段23 是 varint 元素（wire type 0），
        // 之前的 `0xB8 0x00` 编码出来的不是空数组而是 [0]——客户端按 0 去查 config_mission
        // 找不到 DictMission，MissionNode 拿 null 直接空引用崩溃。必须发客户端 config_mission
        // 里真实存在的任务 ID。按 copyId 查 config_copy.mission_id（官方多空），空则回退
        // config_mission 第一条完整任务链（101→102→103，ECA action 均已配置）。
        foreach (int mid in CopyBattleLoader.GetMissionIdList(copyId))
        {
            WriteVarint(ms, 0xB8);
            WriteVarint(ms, unchecked((ulong)mid));
        }

        // EnemyFleet (5) — repeated int32：本关全部敌舰队 id → BattleStartData.enemyFleetId。
        // 客户端战斗帧用它在 config_fleet 查 ship_exp / is_last_fleet，必须非空且有效。
        // 多舰队关卡（fleet_id 数组>1）必须逐个下发，InitNpc 才会生成全部敌舰队。
        foreach (int fid in fleetIdList)
        {
            WriteVarint(ms, 0x28);
            WriteVarint(ms, unchecked((ulong)fid));
        }
        // SkipVcr (17) — TCopySkipVcr[]，补发使 ctor 的 skipVcrs(+0x88) 段有数据
        {
            using MemoryStream sv = new();
            WriteVarint(sv, 0x08);
            WriteVarint(sv, 1021051); // ShipInfoId=1（玩家一号舰的 ship_info_id）
            // StartVcr(2)=false, EndVcr(3)=false 默认不编码（bool 默认 false）
            byte[] svb = sv.ToArray();
            WriteVarint(ms, 0x8A);
            WriteVarint(ms, (ulong)svb.Length);
            ms.Write(svb);
        }
        // EnemyFleets (24) — TBattleEnemyFleet[]，客户端 ctor 与战斗帧都需要。
        // 每个敌舰队（fleet_id 数组元素）各发一条，含该舰队 config_fleet.copy_enemys 的敌舰属性。
        foreach (int fid in fleetIdList)
        {
            List<int> enemyIds = CopyBattleLoader.GetEnemyIds(fid);
            if (enemyIds.Count == 0) continue;
            using MemoryStream ef = new();
            WriteVarint(ef, 0x08);
            WriteVarint(ef, unchecked((ulong)fid)); // FleetId
            WriteVarint(ef, 0x10);
            WriteVarint(ef, 0); // State=0
            foreach (int enemyId in enemyIds)
            {
                CopyBattleLoader.EnemyStat? stat = CopyBattleLoader.GetEnemyStat(enemyId);
                if (stat == null) continue;
                using MemoryStream es = new();
                WriteVarint(es, 0x08);
                WriteVarint(es, unchecked((ulong)enemyId)); // ShipId
                // Attr (2): ShipHp=1, Attack=8, Defense=9, Torpedo=10, TorpedoDefense=11,
                //          Hit=19, Dodge=20
                foreach ((int attrId, int val) in new[]
                         {
                             (1, stat.Hp), (8, stat.Attack), (9, stat.Defense),
                             (10, stat.TorpedoAttack), (11, stat.TorpedoDefense),
                             (19, stat.Hit), (20, stat.Dodge)
                         })
                {
                    using MemoryStream attr = new();
                    WriteVarint(attr, 0x08);
                    WriteVarint(attr, unchecked((ulong)attrId));
                    WriteVarint(attr, 0x10);
                    WriteVarint(attr, unchecked((ulong)val));
                    byte[] ab = attr.ToArray();
                    WriteVarint(es, 0x12);
                    WriteVarint(es, (ulong)ab.Length);
                    es.Write(ab);
                }

                // PSkill (3) — List<int>，至少一个元素使列表非空
                WriteVarint(es, 0x18);
                WriteVarint(es, 1);
                byte[] esb = es.ToArray();
                WriteVarint(ef, 0x1A);
                WriteVarint(ef, (ulong)esb.Length);
                ef.Write(esb);
            }

            byte[] efb = ef.ToArray();
            WriteVarint(ms, 0xC2);
            WriteVarint(ms, (ulong)efb.Length);
            ms.Write(efb);
        }

        // ConfigData (25) — repeated TPassEvaluate。protobuf-net 编码：每个 TPassEvaluate 是
        // 独立 field25(len-delimited)，内容直接是字段（无子消息 tag），Value=默认(0)不序列化。
        // PveCoreCreator._InitWithStartDataCore 用 ConfigDatas[52002(0xCB22)] 作为索敌限时（秒）
        // 覆盖 battlefieldTime：ConfigDatas[52002]=v → 索敌限时=v*1000 ms。之前发 (52002,1) 导致
        // 索敌限时 1 秒立即耗尽。删除 52002 → TryGetValue 失败回退 dictCopy.battle_time=180。
        if (isSeaCopy)
            foreach ((int t, int v) in new[] { (50000, 1), (0, 1) })
            {
                using MemoryStream ce = new();
                if (t != 0)
                {
                    WriteVarint(ce, 0x08);
                    WriteVarint(ce, unchecked((ulong)t));
                } // Type(1)

                if (v != 0)
                {
                    WriteVarint(ce, 0x10);
                    WriteVarint(ce, unchecked((ulong)v));
                } // Value(2)

                byte[] ceb = ce.ToArray();
                WriteVarint(ms, 0xCA);
                WriteVarint(ms, (ulong)ceb.Length);
                ms.Write(ceb);
            }

        return ms.ToArray();
    }

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
    private static (int CopyId, List<int>? DeployHeroIds, bool IsRunningFight, int BattleMode, int MatchType)
        DecodeStartBaseArg(byte[] args)
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

        return (copyId, deployHeroIds, isRunningFight, battleMode, matchType);
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

    internal async Task<byte[]> BuildPassBaseRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        byte[] args = request.Args ?? [];
        PassBaseArg passArg = DecodePassBaseArgAll(args);
        int copyId = passArg.BaseId;
        int grade = passArg.Grade;
        int battleTime = passArg.BattleTime;
        if (copyId == 0) return EncodePassBaseRet(0, 0, 0, 0);

        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        int passTime = battleTime > 0 ? battleTime : 60;
        int copyType = ChapterCopyLoader.GetCopyType(copyId);

        if (copyType == 2)
        {
            PlayerSeaCopyProgress seaProgress = account.SeaProgress ?? new PlayerSeaCopyProgress([]);
            List<CopyRecord> seaRecords = seaProgress.Records.ToList();
            int seaIdx = seaRecords.FindIndex(r => r.CopyId == copyId);
            bool isFirstPass = seaIdx < 0;
            int starLevel = grade > 0 ? 7 : 0;

            if (isFirstPass)
                seaRecords.Add(new CopyRecord(copyId, starLevel, grade, now, passTime, 1));
            else
            {
                CopyRecord existing = seaRecords[seaIdx];
                seaRecords[seaIdx] = existing with
                {
                    StarLevel = Math.Max(existing.StarLevel, starLevel),
                    Grade = Math.Max(existing.Grade, grade),
                    PassTime = passTime,
                    PassCount = existing.PassCount + 1
                };
            }

            account = account with { SeaProgress = new PlayerSeaCopyProgress(seaRecords) };
            await _repo.SaveAccountAsync(account, ct);
            return EncodePassBaseRet(copyId, grade, isFirstPass ? 1 : 0, passTime);
        }

        PlayerCopyProgress progress = account.CopyProgress ?? new PlayerCopyProgress([]);
        List<CopyRecord> records = progress.Records.ToList();
        int idx = records.FindIndex(r => r.CopyId == copyId);
        bool isPlotFirstPass = idx < 0;
        int plotStarLevel = grade > 0 ? 7 : 0;

        if (isPlotFirstPass)
        {
            records.Add(new CopyRecord(copyId, plotStarLevel, grade, now, passTime, 1));
        }
        else
        {
            CopyRecord existing = records[idx];
            records[idx] = existing with
            {
                StarLevel = Math.Max(existing.StarLevel, plotStarLevel),
                Grade = Math.Max(existing.Grade, grade),
                PassTime = passTime,
                PassCount = existing.PassCount + 1
            };
        }

        account = account with { CopyProgress = new PlayerCopyProgress(records) };

        PlayerCharacter c = account.Character;
        int bestChapter = FindChapterForCopy(copyId, c.PlotChapterId);
        if (bestChapter > c.PlotChapterId)
        {
            c = c with { PlotChapterId = bestChapter };
            account = account with { Character = c };
        }

        await _repo.SaveAccountAsync(account, ct);
        return EncodePassBaseRet(copyId, grade, isPlotFirstPass ? 1 : 0, passTime);
    }

    /// <summary>根据 copyId 查找所属章节，返回当前可推进到的最大章节 id。</summary>
    private static int FindChapterForCopy(int copyId, int currentChapterId)
    {
        List<int> chapterIds = ChapterCopyLoader.GetAllChapterIds();
        int bestInRange = currentChapterId;
        foreach (int chId in chapterIds)
        {
            List<int> copies = ChapterCopyLoader.GetCopyIds(chId);
            if (copies.Count == 0) continue;
            if (copies.Contains(copyId) && chId >= bestInRange)
                bestInRange = chId;
        }
        return bestInRange;
    }

    internal static byte[] EncodePassBaseRet(int copyId = 0, int grade = 3, int firstPass = 1, int passTime = 60)
    {
        using MemoryStream ms = new();
        if (copyId != 0)
        {
            WriteVarint(ms, 0x60);
            WriteVarint(ms, unchecked((ulong)copyId));
        }

        if (grade != 0)
        {
            WriteVarint(ms, 0x20);
            WriteVarint(ms, unchecked((ulong)grade));
        }

        int starLevel = grade > 0 ? 7 : 0;
        WriteVarint(ms, 0x30);
        WriteVarint(ms, unchecked((ulong)starLevel));

        if (firstPass != 0)
        {
            WriteVarint(ms, 0x50);
            WriteVarint(ms, unchecked((ulong)firstPass));
        }

        if (passTime != 0)
        {
            WriteVarint(ms, 0x40);
            WriteVarint(ms, unchecked((ulong)passTime));
        }

        WriteVarint(ms, 0x18);
        WriteVarint(ms, 0);

        return ms.ToArray();
    }

    public static int DecodePassBaseCopyId(byte[] args)
    {
        ProtoReader reader = new(args);
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 0) return checked((int)reader.ReadVarint());
            else reader.Skip(wire);
        return 0;
    }

    internal static byte[] BuildCopyInfoRet(byte[] args)
    {
        return EncodeCopyInfoRet();
    }

    internal static byte[] EncodeCopyInfoRet()
    {
        using MemoryStream ms = new();
        WriteVarint(ms, 0x20);
        WriteVarint(ms, 0);
        return ms.ToArray();
    }

    /// <summary>响应 copy.GetRandomFactors（TGetRandomFactorRet）。海域索敌/侦察关卡
    /// 详情页请求随机因子，服务端按 copyId → config_copy_display.random_factor_sets
    /// → config_random_factor_set.factor_groups → config_random_factor_group.factor 解析。</summary>
    private byte[] EncodeGetRandomFactors(byte[]? args)
    {
        ProtoReader reader = new(args ?? []);
        int copyId = 0;
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 0) copyId = checked((int)reader.ReadVarint()); // CopyId(1)
            else reader.Skip(wire);
        using MemoryStream ms = new();
        if (_copyRandomFactors.TryGetValue(copyId, out List<RandomFactorEntry>? entries))
            foreach (RandomFactorEntry e in entries)
                foreach (int f in e.Factors)
                {
                    // Factors(1) = repeated int32
                    WriteVarint(ms, 0x08);
                    WriteVarint(ms, unchecked((ulong)f));
                }

        // LastRefreshTime(2)=0 / IsShowTips(3)=false 默认省略
        return ms.ToArray();
    }

    /// <summary>
    /// 回环 copy.AttackBase 请求（TAttackBaseArg: AttackType(1)/CopyId(2)/HeroIds(3)/EnemyId(4)）
    /// 并附带一个伤害值（字段5，按最大生命值比例的扣血，HpCoefficient 比例尺=1e10 下 10%=1e9）。
    /// 客户端在没有回报时认定攻击失效，因此这里必须回包。
    /// </summary>
    internal static byte[] BuildAttackBaseRet(byte[]? args)
    {
        int attackType = 0, copyId = 0, enemyId = 0;
        List<int> heroIds = new();
        if (args is { Length: > 0 })
        {
            ProtoReader reader = new(args);
            while (reader.TryReadField(out int field, out int wire))
                switch (field)
                {
                    case 1 when wire == 0: attackType = checked((int)reader.ReadVarint()); break;
                    case 2 when wire == 0: copyId = checked((int)reader.ReadVarint()); break;
                    case 3 when wire == 0: heroIds.Add(checked((int)reader.ReadVarint())); break;
                    case 4 when wire == 0: enemyId = checked((int)reader.ReadVarint()); break;
                    default: reader.Skip(wire); break;
                }
        }

        using MemoryStream ms = new();
        if (attackType != 0)
        {
            WriteVarint(ms, 0x08);
            WriteVarint(ms, unchecked((ulong)attackType));
        }

        if (copyId != 0)
        {
            WriteVarint(ms, 0x10);
            WriteVarint(ms, unchecked((ulong)copyId));
        }

        foreach (int hid in heroIds)
        {
            WriteVarint(ms, 0x18);
            WriteVarint(ms, unchecked((ulong)hid));
        }

        if (enemyId != 0)
        {
            WriteVarint(ms, 0x20);
            WriteVarint(ms, unchecked((ulong)enemyId));
        }

        // 伤害：扣除 10% 最大生命值（比例尺下 1e9）
        WriteVarint(ms, 0x28);
        WriteVarint(ms, 1_000_000_000UL);
        return ms.ToArray();
    }

    /// <summary>回环 copy.QuitBase 请求（TQuitBaseArg），让客户端确认退出请求被受理。</summary>
    internal static byte[] BuildQuitBaseRet(byte[]? args)
    {
        using MemoryStream ms = new();
        if (args is { Length: > 0 })
            // 直接回环原始请求字节（客户端数据回环，避免服务端造数据）
            ms.Write(args);
        return ms.ToArray();
    }

    internal static void WriteString(Stream output, int field, string value)
    {
        WriteVarint(output, (ulong)field);
        byte[] bytes = Encoding.UTF8.GetBytes(value);
        WriteVarint(output, (ulong)bytes.Length);
        output.Write(bytes);
    }

    internal static ulong DecodeVarint(ReadOnlySpan<byte> data)
    {
        ulong value = 0;
        for (int shift = 0; shift < 64 && shift / 7 < data.Length; shift += 7)
            value |= (ulong)(data[shift / 7] & 0x7f) << shift;
        return value;
    }

    /// <summary>推送 battle.createBattleInfo 触发 BattleLauncher 场景切换。</summary>
    public byte[] BuildBattleCreateInfoPushEmpty(uint now)
    {
        // TBattlePushMessage — 完全空消息，表示本地 PvE
        using MemoryStream ms = new();
        return TMessageCodec.EncodeResponse(new TResponse(
            Method: "battle.createBattleInfo",
            Ret: ms.ToArray(),
            Time: now));
    }

    public byte[] BuildBattleCreateInfoPush(uint now, int copyId, List<Hero> heroes, PlayerCharacter character)
    {
        using MemoryStream ms = new();
        // UserList (5) — TBattleUserList with BattlePlayer
        using MemoryStream userList = new();
        WriteVarint(userList, 0x08);
        WriteVarint(userList, 0); // Index=0
        // Player (2) — TBattlePlayer (same as TStartBaseRet.BattlePlayer)
        byte[] playerBytes = EncodeBattlePlayer(heroes, character);
        WriteVarint(userList, 0x12);
        WriteVarint(userList, (ulong)playerBytes.Length);
        userList.Write(playerBytes);
        byte[] ulb = userList.ToArray();
        WriteVarint(ms, 0x2A);
        WriteVarint(ms, (ulong)ulb.Length);
        ms.Write(ulb);
        return TMessageCodec.EncodeResponse(new TResponse(
            Method: "battle.createBattleInfo",
            Ret: ms.ToArray(),
            Time: now));
    }

    internal static byte[] EncodeBattlePlayer(List<Hero> heroes, PlayerCharacter character)
    {
        using MemoryStream bp = new();
        WriteVarint(bp, 0x08);
        WriteVarint(bp, character.Uid); // Pid
        WriteVarint(bp, 0x10);
        WriteVarint(bp, character.Uid); // Uid
        WriteString(bp, 0x1A, character.Name); // Uname
        WriteVarint(bp, 0x20);
        WriteVarint(bp, unchecked((ulong)character.Level)); // Level
        WriteVarint(bp, 0x28);
        WriteVarint(bp, 1); // PlayerCamp=1
        WriteVarint(bp, 0x30);
        WriteVarint(bp, 1); // Index=1
        using MemoryStream fleet = new();
        WriteVarint(fleet, 0x08);
        WriteVarint(fleet, 1); // FleetId=1
        WriteVarint(fleet, 0x10);
        WriteVarint(fleet, 2); // FormationId=2
        WriteVarint(fleet, 0x18);
        WriteVarint(fleet, 1); // Index=1
        for (int i = 0; i < Math.Min(heroes.Count, 6); i++)
        {
            Hero h = heroes[i];
            using MemoryStream ship = new();
            WriteVarint(ship, 0x08);
            WriteVarint(ship, (ulong)h.HeroId);
            WriteVarint(ship, 0x10);
            WriteVarint(ship, unchecked((ulong)h.TemplateId));
            WriteVarint(ship, 0x18);
            WriteVarint(ship, unchecked((ulong)h.Level));
            WriteVarint(ship, 0x20);
            WriteVarint(ship, unchecked((ulong)i));
            foreach ((int attrId, int val) in new[] { (1, 1000), (2, 100), (3, 50) })
            {
                using MemoryStream attr = new();
                WriteVarint(attr, 0x08);
                WriteVarint(attr, unchecked((ulong)attrId));
                WriteVarint(attr, 0x10);
                WriteVarint(attr, unchecked((ulong)val));
                byte[] ab = attr.ToArray();
                WriteVarint(ship, 0x2A);
                WriteVarint(ship, (ulong)ab.Length);
                ship.Write(ab);
            }

            WriteVarint(ship, 0x30);
            WriteVarint(ship, PlayerAccountFactory.HpCoefficient);
            WriteVarint(ship, 0x58);
            WriteVarint(ship, 3);
            WriteVarint(ship, 0x60);
            WriteVarint(ship, unchecked((ulong)h.Fashioning));
            byte[] sb = ship.ToArray();
            WriteVarint(fleet, 0x22);
            WriteVarint(fleet, (ulong)sb.Length);
            fleet.Write(sb);
            WriteVarint(fleet, 0x40);
            WriteVarint(fleet, (ulong)h.HeroId); // HeroList(8) per ship
        }

        WriteVarint(fleet, 0x28);
        WriteVarint(fleet, 0);
        WriteVarint(fleet, 0x38);
        WriteVarint(fleet, 0);
        WriteVarint(fleet, 0x48);
        WriteVarint(fleet, 1);
        byte[] fb = fleet.ToArray();
        WriteVarint(bp, 0x3A);
        WriteVarint(bp, (ulong)fb.Length);
        bp.Write(fb);
        return bp.ToArray();
    }

    public async Task<IReadOnlyList<byte[]>> BuildPostEquipPushesAsync(string profileId, uint now, CancellationToken ct)
    {
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        List<HeroGrid> heroes = account.Dock.Heroes.Select(ToHeroGrid).ToList();
        return
        [
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "hero.UpdateHeroBagData",
                Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                Time: now)),
            BuildEquipPush(account, now)
        ];
    }

    /// <summary>编码玩家编队数据为 TSelfTactis protobuf。</summary>
    public static byte[] EncodeFleet(PlayerFleet fleet)
    {
        using MemoryStream ms = new();
        foreach (FleetEntry t in fleet.Tactics)
        {
            using MemoryStream entry = new();
            // tacticName (1)
            if (!string.IsNullOrEmpty(t.TacticName))
            {
                WriteVarint(entry, 0x0A);
                byte[] nameBytes = Encoding.UTF8.GetBytes(t.TacticName);
                WriteVarint(entry, (ulong)nameBytes.Length);
                entry.Write(nameBytes);
            }

            // heroInfo (2, repeated int32)
            if (t.HeroInfo is { Count: > 0 })
                foreach (int h in t.HeroInfo)
                {
                    WriteVarint(entry, 0x10);
                    WriteVarint(entry, unchecked((ulong)h));
                }

            // modeId (3)
            WriteVarint(entry, 0x18);
            WriteVarint(entry, unchecked((ulong)t.ModeId));
            // strategyId (4)
            WriteVarint(entry, 0x20);
            WriteVarint(entry, unchecked((ulong)t.StrategyId));
            // formationId (5)
            WriteVarint(entry, 0x28);
            WriteVarint(entry, unchecked((ulong)t.FormationId));
            // type (6)
            WriteVarint(entry, 0x30);
            WriteVarint(entry, unchecked((ulong)t.Type));
            // exHeroInfo (7, repeated int32)
            if (t.ExHeroInfo is { Count: > 0 })
                foreach (int h in t.ExHeroInfo)
                {
                    WriteVarint(entry, 0x38);
                    WriteVarint(entry, unchecked((ulong)h));
                }

            byte[] body = entry.ToArray();
            WriteVarint(ms, 0x0A); // tactics field 1
            WriteVarint(ms, (ulong)body.Length);
            ms.Write(body);
        }

        if (fleet.MaxPower != 0)
        {
            WriteVarint(ms, 0x10);
            WriteVarint(ms, unchecked((ulong)fleet.MaxPower));
        }

        if (fleet.MinPower != 0)
        {
            WriteVarint(ms, 0x18);
            WriteVarint(ms, unchecked((ulong)fleet.MinPower));
        }

        return ms.ToArray();
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

    internal static byte[] EncodeCacheDataRet()
    {
        // TCacheDataRet{Ret=string}
        using MemoryStream ms = new();
        WriteString(ms, 0x0A, "local");
        return ms.ToArray();
    }

    /// <summary>编码剧情章节初始数据为 TUserCopyInfo protobuf（CopyType=1 PlotCopy）。
    /// 从账户的 CopyProgress 读取实际通关数据，未通关的关卡 FirstPassTime=0/StarLevel=0。</summary>
    public static byte[] EncodePlotCopyInfo(int chapterId = 1, PlayerCopyProgress? progress = null)
    {
        Dictionary<int, CopyRecord> recordMap = progress?.Records
            .ToDictionary(r => r.CopyId, r => r) ?? new Dictionary<int, CopyRecord>();

        // 使用章节加载器获取所有章节的关卡
        List<int> chapterIds = ChapterCopyLoader.GetAllChapterIds();
        // 收集 chapterId 及之前所有章节的关卡
        List<int> allCopyIds = new();
        foreach (int chId in chapterIds)
        {
            if (chId > chapterId) break;
            allCopyIds.AddRange(ChapterCopyLoader.GetCopyIds(chId));
        }

        #region 兜底

        // 兜底：如果加载器没有数据，使用硬编码的关卡列表
        if (allCopyIds.Count == 0)
        {
            allCopyIds.AddRange(new[]
            {
                1, 2, 3, 4, 6, 7, 9, 10, 11, 12, 13,
                101, 102, 103, 104, 105, 106, 107, 108
            });
        }

        #endregion

        using MemoryStream ms = new();
        int maxCopyId = 0;
        foreach (int cid in allCopyIds)
        {
            using MemoryStream baseInfo = new();
            WriteVarint(baseInfo, 0x08);
            WriteVarint(baseInfo, unchecked((ulong)cid)); // BaseId(1)
            WriteVarint(baseInfo, 0x10);
            WriteVarint(baseInfo, 0); // Rid(2)=0
            int starLevel = 7;
            int firstPassTime = 1;
            if (recordMap.TryGetValue(cid, out CopyRecord? rec))
            {
                starLevel = rec.StarLevel;
                firstPassTime = rec.FirstPassTime > 0 ? 1 : 1;
            }
            WriteVarint(baseInfo, 0x18);
            WriteVarint(baseInfo, unchecked((ulong)starLevel)); // StarLevel(3)
            WriteVarint(baseInfo, 0x20);
            WriteVarint(baseInfo, 0); // IsRunningFight(4)=0
            WriteVarint(baseInfo, 0x28);
            WriteVarint(baseInfo, 0); // LBPoint(5)=0
            WriteVarint(baseInfo, 0x30);
            WriteVarint(baseInfo, unchecked((ulong)firstPassTime)); // FirstPassTime(6)
            byte[] body = baseInfo.ToArray();
            WriteVarint(ms, 0x0A);
            WriteVarint(ms, (ulong)body.Length);
            ms.Write(body);
            if (cid > maxCopyId) maxCopyId = cid;
        }

        WriteVarint(ms, 0x10);
        WriteVarint(ms, unchecked((ulong)maxCopyId)); // MaxCopyId(2)
        WriteVarint(ms, 0x18);
        WriteVarint(ms, 1); // CopyType(3)=PlotCopy
        return ms.ToArray();
    }

    /// <summary>编码海域（SeaCopy, CopyType=2）数据为 TUserCopyInfo protobuf。
    /// 海域页面（SeaCopyPage）依赖 Data.copyData:GetCopyInfo() 里有海域关卡，
    /// 否则 CheckChapterIsOpen/GetBattleModeChapter 返回 false，节点不显示。
    /// MaxCopyId = 最后一章第一关，使 _getFarestId(SeaCopy) 落在最后一章，
    /// 从而 nChapterNewIndex = 最后一章，所有章节可自由切换。</summary>
    public static byte[] EncodeSeaCopyInfo(PlayerSeaCopyProgress? progress = null)
    {
        Dictionary<int, CopyRecord> recordMap = progress?.Records
            .ToDictionary(r => r.CopyId, r => r) ?? new Dictionary<int, CopyRecord>();
        List<int> seaLevels = ChapterCopyLoader.GetSeaLevels();
        int maxCopyId = ChapterCopyLoader.GetSeaLastCopyId();
        using MemoryStream ms = new();
        foreach (int cid in seaLevels)
        {
            using MemoryStream baseInfo = new();
            WriteVarint(baseInfo, 0x08);
            WriteVarint(baseInfo, unchecked((ulong)cid)); // BaseId(1)
            WriteVarint(baseInfo, 0x10);
            WriteVarint(baseInfo, 0); // Rid(2)=0
            int starLevel = 7;
            int firstPassTime = 1;
            if (recordMap.TryGetValue(cid, out CopyRecord? rec))
            {
                starLevel = rec.StarLevel;
                firstPassTime = rec.FirstPassTime > 0 ? 1 : 1;
            }
            WriteVarint(baseInfo, 0x18);
            WriteVarint(baseInfo, unchecked((ulong)starLevel)); // StarLevel(3)
            WriteVarint(baseInfo, 0x20);
            WriteVarint(baseInfo, 0); // IsRunningFight(4)=0
            WriteVarint(baseInfo, 0x28);
            WriteVarint(baseInfo, 0); // LBPoint(5)=0
            WriteVarint(baseInfo, 0x30);
            WriteVarint(baseInfo, unchecked((ulong)firstPassTime)); // FirstPassTime(6)
            byte[] body = baseInfo.ToArray();
            WriteVarint(ms, 0x0A);
            WriteVarint(ms, (ulong)body.Length);
            ms.Write(body);
        }

        WriteVarint(ms, 0x10);
        WriteVarint(ms, unchecked((ulong)maxCopyId)); // MaxCopyId(2)
        WriteVarint(ms, 0x18);
        WriteVarint(ms, 2); // CopyType(3)=SeaCopy
        return ms.ToArray();
    }

    internal static Task<byte[]> BuildSimpleRet() => Task.FromResult(Array.Empty<byte>());

    internal async Task<byte[]> BuildLockHeroRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        (uint heroId, bool isLock) = DecodeLockHeroArg(request.Args);
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];
        heroList[heroIdx] = heroList[heroIdx] with { Lock = isLock };
        account = account with { Dock = dock with { Heroes = heroList } };
        await _repo.SaveAccountAsync(account, ct);
        return [];
    }

    private static (uint HeroId, bool Lock) DecodeLockHeroArg(ReadOnlySpan<byte> data)
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
        return (heroId, isLock);
    }

    internal async Task<byte[]> BuildRetireHeroRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        List<uint> heroIds = DecodeRetireHeroArg(request.Args);
        if (heroIds.Count == 0) return [];
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        heroList.RemoveAll(h => heroIds.Contains(h.HeroId));
        account = account with { Dock = dock with { Heroes = heroList } };
        await _repo.SaveAccountAsync(account, ct);
        return [];
    }

    private static List<uint> DecodeRetireHeroArg(ReadOnlySpan<byte> data)
    {
        ProtoReader reader = new(data);
        List<uint> heroIds = new();
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 0) heroIds.Add(checked((uint)reader.ReadVarint()));
            else reader.Skip(wire);
        return heroIds;
    }

    internal async Task<byte[]> BuildChangeNameRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        (uint heroId, string name) = DecodeChangeHeroNameArg(request.Args);
        if (heroId == 0 || string.IsNullOrEmpty(name)) return [];
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];
        heroList[heroIdx] = heroList[heroIdx] with { Name = name };
        account = account with { Dock = dock with { Heroes = heroList } };
        await _repo.SaveAccountAsync(account, ct);
        return [];
    }

    private static (uint HeroId, string Name) DecodeChangeHeroNameArg(ReadOnlySpan<byte> data)
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
        return (heroId, name);
    }

    internal async Task<byte[]> BuildAddAffectionRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        (uint heroId, _, int num) = DecodeHeroAddAffectionArg(request.Args);
        if (heroId == 0 || num <= 0) return [];
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        HeroDock dock = account.Dock;
        List<Hero> heroList = dock.Heroes.ToList();
        int heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];
        Hero hero = heroList[heroIdx];
        heroList[heroIdx] = hero with { Affection = hero.Affection + num * 10000 };
        account = account with { Dock = dock with { Heroes = heroList } };
        await _repo.SaveAccountAsync(account, ct);
        return [];
    }

    private static (uint HeroId, int TemplateId, int Num) DecodeHeroAddAffectionArg(ReadOnlySpan<byte> data)
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
        return (heroId, templateId, num);
    }

    internal async Task<byte[]> BuildGetHeroInfoRetAsync(string profileId, CancellationToken ct)
    {
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        List<HeroGrid> heroes = account.Dock.Heroes.Select(ToHeroGrid).ToList();
        return PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize));
    }

    internal async Task<byte[]> BuildGetHeroInfoByHeroIdArrayRetAsync(string profileId, CancellationToken ct)
    {
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        List<HeroGrid> heroes = account.Dock.Heroes.Select(ToHeroGrid).ToList();
        return PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize));
    }
}
