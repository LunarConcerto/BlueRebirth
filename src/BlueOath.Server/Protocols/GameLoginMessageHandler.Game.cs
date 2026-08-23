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
    /// <summary>把 GM 邮件配置转换为 MailList 实体列表（IsGotReawrd=0，可反复领取）。</summary>
    private IReadOnlyList<MailList> BuildMailEntities(int now) =>
        _gmMails.Select(m => new MailList(
            Mid: m.Mid,
            Subject: m.Subject,
            Content: m.Content,
            ReceiveTime: now,
            ReadTime: 0,
            IsGotReawrd: 0,
            Items: [new MailItem(GoodsTypeCurrency, m.CurrencyType, m.Num)],
            DeleteTime: 0)).ToList();

    /// <summary>邮件列表响应（mail.GetMailList/OpenMail/DeleteMail/DeleteAllMail/ReceiveNewMail 共用）。</summary>
    private byte[] BuildMailListRet(int now)
    {
        var list = BuildMailEntities(now);
        return PlayerDataCodec.Encode(new MailListRet(MailNum: list.Count, List: list));
    }

    /// <summary>
    /// 邮件领取（mail.FetchItem / mail.FetchAllItems）：发放对应邮件的货币并落盘，邮件不删除
    /// （IsGotReawrd 保持 0，客户端仍显示"领取"按钮，实现无限领取）。返回 TMailListRet{list, Reward}。
    /// </summary>
    private async Task<byte[]> BuildFetchMailRetAsync(TRequest request, string profileId, int now, CancellationToken ct)
    {
        var mid = request.Args is null ? 0UL : TMessageCodec.DecodeMailMid(request.Args);
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var rewards = new List<CommonReward>();
        foreach (var mail in _gmMails)
        {
            if (request.Method == "mail.FetchItem" && mail.Mid != mid)
                continue;
            account = AddCurrency(account, mail.CurrencyType, mail.Num);
            rewards.Add(new CommonReward(GoodsTypeCurrency, mail.CurrencyType, mail.Num));
        }
        if (rewards.Count > 0)
            await _repo.SaveAccountAsync(account, ct);
        var list = BuildMailEntities(now);
        return PlayerDataCodec.Encode(new MailListRet(MailNum: list.Count, List: list, Reward: rewards));
    }

    /// <summary>
    /// 处理 hero.ChangeEquip：装备穿脱（EquipId&gt;0 = 装备，EquipId=0 = 卸下）。
    /// 更新 Hero.EquipSlots 和 EquipItem.HeroId，落盘后返回空响应（客户端通过推送刷新）。
    /// </summary>
    private async Task<byte[]> BuildChangeEquipRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return [];
        var (heroId, luaIndex, equipId, _) = TMessageCodec.DecodeHeroChangeEquipArgs(request.Args);
        // Lua 客户端发送 1-based 索引，C# 数组是 0-based，需要转换。
        var index = luaIndex - 1;
        if (index < 0 || index >= 6)
            return [];
        var account = await GetOrCreateAccountAsync(profileId, ct);

        var dock = account.Dock;
        var heroList = dock.Heroes.ToList();
        var heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0)
            return [];
        var hero = heroList[heroIdx];

        // 获取当前装备槽数组
        var slots = (hero.EquipSlots ?? new uint[] { 0, 0, 0, 0, 0, 0 }).ToArray();

        // 如果旧槽有装备，先卸下
        var oldEquipId = slots[index];
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
    private static PlayerAccount SetEquipHeroId(PlayerAccount account, uint equipId, uint heroId)
    {
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        var items = equip.Items.ToList();
        var idx = items.FindIndex(e => e.EquipId == equipId);
        if (idx >= 0)
            items[idx] = items[idx] with { HeroId = heroId };
        return account with { Equip = equip with { Items = items } };
    }

    /// <summary>
    /// 处理 buildship.BuildShip：按卡池权重随机抽取舰娘，10 连保底至少一个 SR（quality>=3）。
    /// 抽取到的舰娘加入船坞，返回 TBuildShipRet{BuildShipResult=[TCommonReward]}。
    /// </summary>
    private async Task<byte[]> BuildBuildShipRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return [];
        var (poolId, num, _) = DecodeBuildShipArg(request.Args);
        if (num <= 0) num = 1;
        if (num > 10) num = 10;

        var account = await GetOrCreateAccountAsync(profileId, ct);
        var now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        var rewards = new List<CommonReward>();
        _lastBuildHeroIds = new List<uint>();

        for (var i = 0; i < num; i++)
        {
            var tid = RollShip(poolId);
            if (tid == 0) continue;
            var heroId = _nextHeroId++;
            account = AddShip(account, heroId, tid, now);
            _lastBuildHeroIds.Add(heroId);
            rewards.Add(new CommonReward(3, tid, 1, (int)heroId));
        }
        if (rewards.Count > 0)
            await _repo.SaveAccountAsync(account, ct);

        return EncodeBuildShipRet(rewards);
    }

    private List<uint> _lastBuildHeroIds = [];

    /// <summary>
    /// 按卡池权重随机抽取一个舰娘 TemplateId。返回 0 表示池中没有可抽的船。
    /// </summary>
    private int RollShip(int poolId)
    {
        if (!_buildPools.TryGetValue(poolId, out var pool) || pool.Ships.Count == 0)
            return 0;
        return WeightedPick(pool.Ships);
    }

    private int WeightedPick(IReadOnlyList<BuildShipEntry> entries)
    {
        var totalWeight = entries.Sum(e => e.Weight);
        if (totalWeight <= 0) return entries[0].TemplateId;
        var roll = _rng.Next(totalWeight);
        var cumulative = 0;
        foreach (var e in entries)
        {
            cumulative += e.Weight;
            if (roll < cumulative)
                return e.TemplateId;
        }
        return entries[^1].TemplateId;
    }

    /// <summary>舰娘加入船坞：创建 Hero 实例。Affection=1000 避免 GetLoveInfo 返回 nil。</summary>
    internal static PlayerAccount AddShip(PlayerAccount account, uint heroId, int templateId, int now)
    {
        var dock = account.Dock;
        var heroes = dock.Heroes.ToList();
        var fashioning = (templateId - 1) / 10;
        heroes.Add(new Hero(HeroId: heroId, TemplateId: templateId, Level: 1,
            Fashioning: fashioning, CreateTime: now, UpdateTime: now, Affection: 1000, CurHp: PlayerAccountFactory.HpCoefficient, Mood: 0, MarryType: 0));
        return account with { Dock = dock with { Heroes = heroes } };
    }

    /// <summary>解码 TBuildShipArg: Id(1, int32), Num(2, int32), CacheId(3, string)。</summary>
    private static (int Id, int Num, string CacheId) DecodeBuildShipArg(ReadOnlySpan<byte> payload)
    {
        var reader = new ProtoReader(payload);
        int id = 0, num = 1;
        var cacheId = "";
        while (reader.TryReadField(out var field, out var wire))
        {
            switch (field)
            {
                case 1 when wire == 0: id = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 0: num = checked((int)reader.ReadVarint()); break;
                case 3 when wire == 2: cacheId = reader.ReadString(); break;
                default: reader.Skip(wire); break;
            }
        }
        return (id, num, cacheId);
    }

    /// <summary>编码 TBuildShipRet: BuildShipResult(1, repeated TCommonReward)。</summary>
    private static byte[] EncodeBuildShipRet(IReadOnlyList<CommonReward> rewards)
    {
        using var output = new MemoryStream();
        foreach (var r in rewards)
        {
            using var item = new MemoryStream();
            if (r.Type != 0) { item.WriteByte(0x08); WriteVarint(item, unchecked((ulong)r.Type)); }
            if (r.ConfigId != 0) { item.WriteByte(0x10); WriteVarint(item, unchecked((ulong)r.ConfigId)); }
            if (r.Num != 0) { item.WriteByte(0x18); WriteVarint(item, unchecked((ulong)r.Num)); }
            item.WriteByte(0x20); WriteVarint(item, unchecked((ulong)r.Id));
            var body = item.ToArray();
            output.WriteByte(0x0A);
            WriteVarint(output, (ulong)body.Length);
            output.Write(body);
        }
        // SpReward(2) 和 TransReward(3) 各编码一个空元素，避免 _LoadTenCard 里
        // self.transReward[nIndex].Reward 访问 nil 崩溃。
        for (var i = 0; i < rewards.Count; i++)
        {
            output.WriteByte(0x12); output.WriteByte(0x00); // SpReward
            output.WriteByte(0x1A); output.WriteByte(0x00); // TransReward
        }
        return output.ToArray();
    }

    /// <summary>构建头像解锁列表推送（TNewHeadUnlockedList），包含船坞中所有舰娘的 sf_id。</summary>
    private static byte[] BuildHeadUnlockedListPush(PlayerAccount account)
    {
        // 收集船坞中所有舰娘的 sf_id（ship_info_id = (TemplateId - 1) / 10）
        var sfIds = account.Dock.Heroes
            .Select(h => (h.TemplateId - 1) / 10)
            .Distinct()
            .ToList();
        using var output = new MemoryStream();
        foreach (var sfId in sfIds)
        {
            // TNewHeadNode: ShipFleetId(1, int32), ProfileID(2, repeated int32)
            using var node = new MemoryStream();
            WriteVarint(node, 0x08); WriteVarint(node, unchecked((ulong)sfId)); // ShipFleetId
            WriteVarint(node, 0x10); WriteVarint(node, unchecked((ulong)sfId)); // ProfileID = sfId
            var body = node.ToArray();
            output.WriteByte(0x0A); // UnlockedList field 1, wire 2
            WriteVarint(output, (ulong)body.Length);
            output.Write(body);
        }
        return output.ToArray();
    }

    private static void WriteVarint(Stream output, ulong value)
    {
        while (value >= 0x80) { output.WriteByte((byte)(value | 0x80)); value >>= 7; }
        output.WriteByte((byte)value);
    }

    private ref struct ProtoReader
    {
        private readonly ReadOnlySpan<byte> _data;
        private int _offset;
        public ProtoReader(ReadOnlySpan<byte> data) { _data = data; _offset = 0; }
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
                if (_offset >= _data.Length) throw new EndOfStreamException();
                var cur = _data[_offset++];
                value |= (ulong)(cur & 0x7f) << shift;
                if ((cur & 0x80) == 0) return value;
            }
            throw new InvalidDataException();
        }
        public string ReadString() => Encoding.UTF8.GetString(ReadBytes());
        public ReadOnlySpan<byte> ReadBytes()
        {
            var len = checked((int)ReadVarint());
            var val = _data.Slice(_offset, len);
            _offset += len;
            return val;
        }
        public void Skip(int wire)
        {
            switch (wire)
            {
                case 0: ReadVarint(); break;
                case 2: ReadBytes(); break;
                default: throw new InvalidDataException();
            }
        }
    }

    /// <summary>
    /// 处理用户档案更新（秘书舰/改名/签名/头像/头像框）。
    /// 解码对应协议的 arg，更新 PlayerCharacter，落盘，返回空响应。
    /// </summary>
    private async Task<byte[]> BuildUserProfileUpdateAsync(TRequest request, string profileId, CancellationToken ct, string field)
    {
        if (request.Args is null) return [];
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var c = account.Character;

        if (field == "Secretary")
        {
            // TSetUserSecretaryArg: SecretaryId(1, uint32)
            var secId = DecodeVarintField(request.Args, 1);
            if (secId == 0) return [];
            c = c with { SecretaryId = (uint)secId };
        }
        else if (field == "Name")
        {
            // TUserChangeNameArg: Name(1, string)
            var name = DecodeStringField(request.Args, 1);
            if (string.IsNullOrWhiteSpace(name)) return [];
            c = c with { Name = name };
        }
        else if (field == "Message")
        {
            // TSetUserMsgArg: Message(1, string)
            var msg = DecodeStringField(request.Args, 1);
            c = c with { Message = msg ?? "" };
        }
        else if (field == "HeadFrame")
        {
            // TUserSetPlayerHeadFrameArg: headFrameId(1, int32)
            var frameId = DecodeVarintField(request.Args, 1);
            c = c with { HeadFrame = (int)frameId };
        }
        else if (field == "Head")
        {
            // TNewHeadBuyHeadArg: ShipFleetId(1, int32), ProfileID(2, int32) — 取 ProfileID
            var profileId_i = DecodeVarintField(request.Args, 2);
            if (profileId_i == 0) return [];
            c = c with { Head = (int)profileId_i };
        }
        else return [];

        account = account with { Character = c };
        await _repo.SaveAccountAsync(account, ct);
        return [];
    }

    private static ulong DecodeVarintField(ReadOnlySpan<byte> data, int field)
    {
        var reader = new ProtoReader(data);
        while (reader.TryReadField(out var f, out var wire))
        {
            if (f == field && wire == 0) return reader.ReadVarint();
            reader.Skip(wire);
        }
        return 0;
    }

    private static string? DecodeStringField(ReadOnlySpan<byte> data, int field)
    {
        var reader = new ProtoReader(data);
        while (reader.TryReadField(out var f, out var wire))
        {
            if (f == field && wire == 2) return reader.ReadString();
            reader.Skip(wire);
        }
        return null;
    }

    private async Task<byte[]> BuildAddExpRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        var (heroId, items) = DecodeHeroAddExp(request.Args);
        if (heroId == 0 || items.Count == 0) return [];

        var account = await GetOrCreateAccountAsync(profileId, ct);
        var dock = account.Dock;
        var heroList = dock.Heroes.ToList();
        var heroIdx = heroList.FindIndex(h => h.HeroId == heroId);
        if (heroIdx < 0) return [];
        var hero = heroList[heroIdx];

        var totalExp = 0;
        var bag = account.Bag ?? new PlayerBag([], 100);
        var bagItems = bag.Items.ToList();
        foreach (var (itemId, num) in items)
        {
            if (!_expPerItem.TryGetValue(itemId, out var perExp)) continue;
            totalExp += perExp * num;
            var bagIdx = bagItems.FindIndex(i => i.TemplateId == itemId);
            if (bagIdx >= 0)
            {
                var newNum = bagItems[bagIdx].Num - num;
                if (newNum <= 0) bagItems.RemoveAt(bagIdx);
                else bagItems[bagIdx] = bagItems[bagIdx] with { Num = newNum };
            }
        }
        if (totalExp == 0) return [];

        var level = hero.Level;
        var exp = hero.Exp + totalExp;
        var maxLevel = 200;
        while (level < maxLevel)
        {
            var needExp = _expNeeded.GetValueOrDefault(level, 500);
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
        var reader = new ProtoReader(data);
        uint heroId = 0;
        var items = new List<(int, int)>();
        while (reader.TryReadField(out var field, out var wire))
        {
            if (field == 1 && wire == 0) heroId = checked((uint)reader.ReadVarint());
            else if (field == 2 && wire == 2)
            {
                var itemBytes = reader.ReadBytes();
                var itemReader = new ProtoReader(itemBytes);
                int curId = 0, curNum = 0;
                while (itemReader.TryReadField(out var f, out var w))
                {
                    if (f == 2 && w == 0) curId = checked((int)itemReader.ReadVarint());
                    else if (f == 3 && w == 0) curNum = checked((int)itemReader.ReadVarint());
                    else itemReader.Skip(w);
                }
                if (curId > 0 && curNum > 0) items.Add((curId, curNum));
            }
            else reader.Skip(wire);
        }
        return (heroId, items);
    }

    private static byte[] EncodeHeroAddExpRet(uint heroId, List<(int Id, int Num)> items)
    {
        using var output = new MemoryStream();
        if (heroId != 0) { output.WriteByte(0x08); WriteVarint(output, heroId); }
        foreach (var (id, num) in items)
        {
            using var item = new MemoryStream();
            if (id != 0) { item.WriteByte(0x10); WriteVarint(item, unchecked((ulong)id)); }
            if (num != 0) { item.WriteByte(0x18); WriteVarint(item, unchecked((ulong)num)); }
            var body = item.ToArray();
            output.WriteByte(0x12);
            WriteVarint(output, (ulong)body.Length);
            output.Write(body);
        }
        return output.ToArray();
    }

    private async Task<byte[]> BuildGetHerosTacticAsync(string profileId, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var fleet = account.Fleet ?? PlayerAccountFactory.DefaultFleet();
        return EncodeFleet(fleet);
    }

    private async Task<byte[]> BuildSetHerosTacticAsync(TRequest request, string profileId, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var entries = DecodeSetHerosTactic(request.Args ?? []);
        var newFleet = new PlayerFleet(entries);
        var updated = account with { Fleet = newFleet };
        await _repo.SaveAccountAsync(updated, ct);
        return EncodeFleet(newFleet);
    }

    private static byte[] BuildPlotReward(byte[] args)
    {
        return EncodePlotRewardRet(args.Length > 0 ? (int)DecodeVarint(args.AsSpan()) : 0);
    }

    /// <summary>推送当前章节的 copy.GetCopy 数据。markPassed=true 表示上一章已通关。</summary>
    public async Task<byte[]> BuildCopyPushAsync(string profileId, uint now, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var chapterId = account.Character.PlotChapterId;
        return TMessageCodec.EncodeResponse(new TResponse(
            Method: "copy.GetCopy",
            Ret: EncodePlotCopyInfo(chapterId, markPassed: chapterId > 1),
            Time: now));
    }

    private async Task<byte[]> BuildStartBaseRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        try
        {
            var account = await GetOrCreateAccountAsync(profileId, ct);
            var args = request.Args ?? [];
            var (copyId, deployHeroIds, isRunningFight, battleMode, matchType) = DecodeStartBaseArg(args);
            _fileLogger.LogInformation("copy.StartBase argsLen={Len} hex={Hex} copyId={CopyId} deployHeroIds={Deploy} isRunningFight={IsRunning}",
                args.Length, Convert.ToHexString(args), copyId,
                deployHeroIds is null ? "<null>" : string.Join(",", deployHeroIds), isRunningFight);
            var heroList = account.Dock.Heroes.ToList();
            // 关卡出战舰队必须回环客户端请求里的 HeroList（剧情关限制），
            // 而不是从玩家编队猜。请求未带时回退到全部船。
            return EncodeStartBaseRet(copyId, heroList, deployHeroIds, isRunningFight, battleMode, matchType);
        }
        catch (Exception ex)
        {
            _fileLogger.LogError(ex, "BuildStartBaseRetAsync failed");
            return [];
        }
    }

    public byte[] EncodeMutiBattleRet(int copyId, List<Hero> heroes)
    {
        // TBattleCreateMutiRet{ BattleId(1), Ip(2), Port(3), Arg(4=TBattleCreateMutiArg) }
        // TBattleCreateMutiArg 字段与 TStartBaseRet 相同
        using var ms = new MemoryStream();
        WriteVarint(ms, 0x08); WriteVarint(ms, 1); // BattleId=1
        // Arg (4) = TBattleCreateMutiArg，与 TStartBaseRet 编码相同
        var arg = EncodeStartBaseRet(copyId, heroes, null);
        WriteVarint(ms, 0x22); WriteVarint(ms, (ulong)arg.Length); ms.Write(arg);
        return ms.ToArray();
    }

    public byte[] EncodeStartBaseRetDirect(int copyId, List<Hero> heroes)
    {
        return EncodeStartBaseRet(copyId, heroes, null);
    }

    private static byte[] EncodeStartBaseRet(int copyId, List<Hero> heroes, IReadOnlyList<int>? deployHeroIds = null,
        bool isRunningFight = false, int battleMode = 1, int matchType = 0)
    {
        // 本关真实敌舰队 id（config_copy → fleet_id），供 TStartBaseRet.EnemyFleet(字段5)
        // → BattleStartData.enemyFleetId 使用。
        var realFleetId = CopyBattleLoader.GetFleetId(copyId);
        // 敌人舰队锚点：GetFleetIdWithAttached 现直接查表（copy 6 → 200602 → 敌舰 100003）。
        var fleetId = CopyBattleLoader.GetFleetIdWithAttached(copyId);
        var enemyIds = CopyBattleLoader.GetEnemyIds(fleetId);

        // 出战船只按客户端请求顺序（剧情关可能带临时/支援舰船，其 HeroId 不在玩家船坞，
        // 需从 config_assist_ship_info 加载回环，否则临时舰船丢失）。编队为空时回退到全部船。
        List<Hero> deploy;
        if (deployHeroIds is { Count: > 0 })
        {
            var byId = heroes.ToDictionary(h => (int)h.HeroId);
            deploy = new List<Hero>();
            foreach (var id in deployHeroIds)
            {
                if (byId.TryGetValue(id, out var hero))
                {
                    deploy.Add(hero);
                }
                else if (AssistShipLoader.Get(id) is { } assist)
                {
                    var templateId = checked((int)assist.ShipMainId);
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

        using var ms = new MemoryStream();
        // BattlePlayer (1) — TBattlePlayerList with full fleet data
        using var bpList = new MemoryStream();
        using var bp = new MemoryStream();
        WriteVarint(bp, 0x08); WriteVarint(bp, 1); // Pid=1
        WriteVarint(bp, 0x10); WriteVarint(bp, 1); // Uid=1
        WriteString(bp, 0x1A, "player"); // Uname
        WriteVarint(bp, 0x20); WriteVarint(bp, 1); // Level=1
        WriteVarint(bp, 0x28); WriteVarint(bp, 1); // PlayerCamp=1
        WriteVarint(bp, 0x30); WriteVarint(bp, 1); // Index=1
        // FleetInfo (7) — TBattleFleet with full ship data
        using var fleet = new MemoryStream();
        WriteVarint(fleet, 0x08); WriteVarint(fleet, 1); // FleetId=1
        WriteVarint(fleet, 0x10); WriteVarint(fleet, 2); // FormationId=2
        WriteVarint(fleet, 0x18); WriteVarint(fleet, 1); // Index=1
        // Ships (4)
        for (int i = 0; i < deploy.Count; i++)
        {
            var h = deploy[i];
            using var ship = new MemoryStream();
            WriteVarint(ship, 0x08); WriteVarint(ship, (ulong)h.HeroId);
            WriteVarint(ship, 0x10); WriteVarint(ship, unchecked((ulong)h.TemplateId));
            WriteVarint(ship, 0x18); WriteVarint(ship, unchecked((ulong)h.Level));
            WriteVarint(ship, 0x20); WriteVarint(ship, unchecked((ulong)i));
            // Attr (5) — 按船 TemplateId 查 config_ship_main 发真实属性（考虑等级成长），
            // 临时/支援舰船（HeroId 在 config_assist_ship_info）直接用其属性表。
            // 命中判定 __IsHit(hit, dodge) 依赖 Hit/Dodge。
            var assist = AssistShipLoader.Get(checked((int)h.HeroId));
            var cfg = ShipMainLoader.Get(h.TemplateId);
            long shipHp, attack, defense, hit, dodge, crit, antiCrit, torpedoAttack, torpedoDefense;
            long planeBomb = 0, planeTorpedo = 0, scoutNum = 1;
            if (assist is not null)
            {
                shipHp = assist.Hp; attack = assist.Attack; defense = assist.Defense;
                hit = assist.Hit; dodge = assist.Dodge; crit = assist.Crit; antiCrit = assist.AntiCrit;
                torpedoAttack = assist.TorpedoAttack; torpedoDefense = assist.TorpedoDefense;
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
                shipHp = 1000; attack = 100; defense = 50; hit = 100; dodge = 35;
                crit = 0; antiCrit = 0; torpedoAttack = 0; torpedoDefense = 0;
            }
            else
            {
                shipHp = ShipMainLoader.Leveled(cfg.Hp, cfg.HpLevelup, h.Level);
                attack = ShipMainLoader.Leveled(cfg.Attack, cfg.AttackLevelup, h.Level);
                defense = ShipMainLoader.Leveled(cfg.Defense, cfg.DefenseLevelup, h.Level);
                hit = cfg.Hit; dodge = cfg.Dodge; crit = cfg.Crit; antiCrit = cfg.AntiCrit;
                torpedoAttack = ShipMainLoader.Leveled(cfg.TorpedoAttack, cfg.TorpedoAttackLevelup, h.Level);
                torpedoDefense = ShipMainLoader.Leveled(cfg.TorpedoDefense, cfg.TorpedoDefenseLevelup, h.Level);
                planeBomb = cfg.ShipBombAttack;
                planeTorpedo = cfg.ShipTorpedoAttack;
                if (cfg.CarryPlaneCount > 0) scoutNum = cfg.CarryPlaneCount;
            }
            foreach (var (attrId, val) in new[] { (1, shipHp), (5, scoutNum), (8, attack), (9, defense),
                (10, torpedoAttack), (11, torpedoDefense),
                (14, planeBomb), (15, planeTorpedo),
                (17, crit), (18, antiCrit), (19, hit), (20, dodge) })
            {
                using var attr = new MemoryStream();
                WriteVarint(attr, 0x08); WriteVarint(attr, unchecked((ulong)attrId));
                WriteVarint(attr, 0x10); WriteVarint(attr, unchecked((ulong)val));
                var ab = attr.ToArray();
                WriteVarint(ship, 0x2A); WriteVarint(ship, (ulong)ab.Length); ship.Write(ab);
            }
            WriteVarint(ship, 0x30); WriteVarint(ship, PlayerAccountFactory.HpCoefficient); // CurHp(6)
            WriteVarint(ship, 0x58); WriteVarint(ship, 3); // EquipGridNum(11)
            WriteVarint(ship, 0x60); WriteVarint(ship, unchecked((ulong)h.Fashioning)); // Fashioning(12)
            // PSkill (8) — TFiledPSkillLv[], 每艘船给一个最小技能(PSkillId=1,PSkillLv=1)
            using var pskill = new MemoryStream();
            WriteVarint(pskill, 0x08); WriteVarint(pskill, 1); // PSkillId=1
            WriteVarint(pskill, 0x10); WriteVarint(pskill, 1); // PSkillLv=1
            var pskillBytes = pskill.ToArray();
            WriteVarint(ship, 0x42); WriteVarint(ship, (ulong)pskillBytes.Length); ship.Write(pskillBytes);
            // Equips (7) — TBattleEquip[]。临时/支援舰船用 config_assist_ship_info.equip。
            // 航母的空袭依赖飞机装备（PlaneNum），否则空袭技能不出现。
            if (assist?.Equip is { Count: > 0 })
            {
                for (int ei = 0; ei < assist.Equip.Count; ei++)
                {
                    var eid = checked((int)assist.Equip[ei]);
                    if (eid == 0) continue;
                    var ecfg = EquipLoader.Get(eid);
                    using var eq = new MemoryStream();
                    WriteVarint(eq, 0x08); WriteVarint(eq, unchecked((ulong)eid)); // EquipTid(1)
                    WriteVarint(eq, 0x10); WriteVarint(eq, unchecked((ulong)ei));  // EquipIndex(2)
                    WriteVarint(eq, 0x18); WriteVarint(eq, 100);                   // PlaneNum(3)
                    if (ecfg?.EquipProp is { Count: > 0 })
                    {
                        foreach (var ap in ecfg.EquipProp)
                        {
                            if (ap is { Count: >= 2 })
                            {
                                using var av = new MemoryStream();
                                WriteVarint(av, 0x08); WriteVarint(av, unchecked((ulong)ap[0])); // propId
                                WriteVarint(av, 0x10); WriteVarint(av, unchecked((ulong)ap[1])); // value
                                var avb = av.ToArray();
                                WriteVarint(eq, 0x22); WriteVarint(eq, (ulong)avb.Length); eq.Write(avb);
                            }
                        }
                    }
                    var eqb = eq.ToArray();
                    WriteVarint(ship, 0x3A); WriteVarint(ship, (ulong)eqb.Length); ship.Write(eqb);
                }
            }
            var sb = ship.ToArray();
            WriteVarint(fleet, 0x22); WriteVarint(fleet, (ulong)sb.Length); fleet.Write(sb);
            // HeroList (8) — one per ship
            WriteVarint(fleet, 0x40); WriteVarint(fleet, (ulong)h.HeroId);
        }
        WriteVarint(fleet, 0x28); WriteVarint(fleet, 0); // StrategyId=0
        WriteVarint(fleet, 0x38); WriteVarint(fleet, 0); // KillTimes=0
        WriteVarint(fleet, 0x48); WriteVarint(fleet, 1); // TacticType=1
        var fb = fleet.ToArray();
        WriteVarint(bp, 0x3A); WriteVarint(bp, (ulong)fb.Length); bp.Write(fb);
        var bpb = bp.ToArray();
        WriteVarint(bpList, 0x0A); WriteVarint(bpList, (ulong)bpb.Length); bpList.Write(bpb);
        var bplb = bpList.ToArray();
        WriteVarint(ms, 0x0A); WriteVarint(ms, (ulong)bplb.Length); ms.Write(bplb);
        // RandomSeed (2)
        WriteVarint(ms, 0x10); WriteVarint(ms, 12345);
        // Rid (3) = config_copy 的 r_id（客户端用它作 copyDictId 查 config_copy -> scene_id）
        var copyRid = CopyBattleLoader.GetConfigId(copyId);
        WriteVarint(ms, 0x18); WriteVarint(ms, unchecked((ulong)copyRid));
        // CopyId (6) — 客户端用它在 config_copy_display 里查配置（键=显示 id，来自请求）
        WriteVarint(ms, 0x30); WriteVarint(ms, unchecked((ulong)copyId));
        // CopyType (7)：剧情=1(PlotCopy)，海域=2(SeaCopy)。海域关卡战斗初始化按 CopyType 分支。
        // 海域侦察任务按 SeaCopy(2) 走索敌 3D 玩法，是正常逻辑，不能绕开（绕开会失去索敌玩法意义）。
        var isSeaCopy = ChapterCopyLoader.GetSeaLevels().Contains(copyId);
        WriteVarint(ms, 0x38); WriteVarint(ms, isSeaCopy ? (ulong)2 : (ulong)1);
        // RandomFactors (12) — 海域索敌/侦察场景初始化依赖。海域关卡 random_factor_sets=[61]，
        // 服务端需下发 SetId=61 的随机因子，否则 BattlePage 索敌 UI 初始化卡加载。
        if (isSeaCopy)
        {
            using var rf = new MemoryStream();
            WriteVarint(rf, 0x08); WriteVarint(rf, 1);   // Factors[0]=1
            WriteVarint(rf, 0x10); WriteVarint(rf, 61);  // GroupId(2)=61
            WriteVarint(rf, 0x18); WriteVarint(rf, 61);  // SetId(3)=61
            var rfb = rf.ToArray();
            WriteVarint(ms, 0x62); WriteVarint(ms, (ulong)rfb.Length); ms.Write(rfb);
        }
        // CopyPass (8) = false
        // BossProgress (9) = 0
        // IsRunningFight (10) — 回环客户端请求的 IsRunningFight（请求/响应同名字段）
        if (isRunningFight) { WriteVarint(ms, 0x50); WriteVarint(ms, 1); }
        // SafeLv (13) = 0
        WriteVarint(ms, 0x68); WriteVarint(ms, 0);
        // BattleMode (18) = Normal=1(普通)/Exercises=2(练习)/Memory=3(记忆)/Sweep=4(扫荡)
        // 回环客户端请求的 BattleMode（请求 field 9）
        WriteVarint(ms, 0x90); WriteVarint(ms, unchecked((ulong)(battleMode == 0 ? 1 : battleMode)));
        // MatchType (26) = 0 — 回环客户端请求的 MatchType（请求 field 15）
        if (matchType != 0) { WriteVarint(ms, 0xD0); WriteVarint(ms, unchecked((ulong)matchType)); }
        // 海域索敌：补齐未编码字段（IsFinal/AnimMode/WeatherGroupId），索敌核心初始化可能检查。
        if (isSeaCopy)
        {
            // IsFinal (19) = false
            WriteVarint(ms, 0x98); WriteVarint(ms, 0);
            // AnimMode (20) = 0
            WriteVarint(ms, 0xA0); WriteVarint(ms, 0);
            // WeatherGroupId (21) = 0
            WriteVarint(ms, 0xA8); WriteVarint(ms, 0);
        }
        // Token (16) = ""
        WriteString(ms, 0x82, "1111111111111111111111111111111111111");
        // arrRes (4) — TCopyRes[]。海域索敌 InitResPoint 遍历 copyRess（=arrRes）用元素查
        // battlefield_resource，海域 battlefield_resource[copyId] 缺失导致 GetDict null 卡死。
        // 海域 arrRes 发空（copyRess 空 → InitResPoint 跳过资源点生成）。
        if (!isSeaCopy)
        {
            using var cr = new MemoryStream();
            WriteVarint(cr, 0x08); WriteVarint(cr, unchecked((ulong)copyId)); // id
            var crb = cr.ToArray();
            WriteVarint(ms, 0x22); WriteVarint(ms, (ulong)crb.Length); ms.Write(crb);
        }
        // CopyMission (23) — repeated int32。注意：字段23 是 varint 元素（wire type 0），
        // 之前的 `0xB8 0x00` 编码出来的不是空数组而是 [0]——客户端按 0 去查 config_mission
        // 找不到 DictMission，MissionNode 拿 null 直接空引用崩溃。必须发客户端 config_mission
        // 里真实存在的任务 ID（101/102/103 是一串完整的杀敌链，ECA action 均已配置）。
        foreach (var mid in new[] { 101, 102, 103 })
        {
            WriteVarint(ms, 0xB8);
            WriteVarint(ms, unchecked((ulong)mid));
        }
        // EnemyFleet (5) — repeated int32：本关敌舰队 id → BattleStartData.enemyFleetId。
        // 客户端战斗帧用它在 config_fleet 查 ship_exp / is_last_fleet，必须非空且有效。
        WriteVarint(ms, 0x28); WriteVarint(ms, unchecked((ulong)realFleetId));
        // SkipVcr (17) — TCopySkipVcr[]，补发使 ctor 的 skipVcrs(+0x88) 段有数据
        {
            using var sv = new MemoryStream();
            WriteVarint(sv, 0x08); WriteVarint(sv, 1021051); // ShipInfoId=1（玩家一号舰的 ship_info_id）
            // StartVcr(2)=false, EndVcr(3)=false 默认不编码（bool 默认 false）
            var svb = sv.ToArray();
            WriteVarint(ms, 0x8A); WriteVarint(ms, (ulong)svb.Length); ms.Write(svb);
        }
        // EnemyFleets (24) — TBattleEnemyFleet[]，客户端 ctor 与战斗帧都需要
        if (enemyIds.Count > 0)
        {
            using var ef = new MemoryStream();
            WriteVarint(ef, 0x08); WriteVarint(ef, unchecked((ulong)fleetId)); // FleetId
            WriteVarint(ef, 0x10); WriteVarint(ef, 0); // State=0
            foreach (var enemyId in enemyIds)
            {
                var stat = CopyBattleLoader.GetEnemyStat(enemyId);
                if (stat == null) continue;
                using var es = new MemoryStream();
                WriteVarint(es, 0x08); WriteVarint(es, unchecked((ulong)enemyId)); // ShipId
                // Attr (2): ShipHp=1, Attack=8, Defense=9, Torpedo=10, TorpedoDefense=11,
                //          Hit=19, Dodge=20
                foreach (var (attrId, val) in new[] {
                    (1, stat.Hp), (8, stat.Attack), (9, stat.Defense),
                    (10, stat.TorpedoAttack), (11, stat.TorpedoDefense),
                    (19, stat.Hit), (20, stat.Dodge) })
                {
                    using var attr = new MemoryStream();
                    WriteVarint(attr, 0x08); WriteVarint(attr, unchecked((ulong)attrId));
                    WriteVarint(attr, 0x10); WriteVarint(attr, unchecked((ulong)val));
                    var ab = attr.ToArray();
                    WriteVarint(es, 0x12); WriteVarint(es, (ulong)ab.Length); es.Write(ab);
                }
                // PSkill (3) — List<int>，至少一个元素使列表非空
                WriteVarint(es, 0x18); WriteVarint(es, 1);
                var esb = es.ToArray();
                WriteVarint(ef, 0x1A); WriteVarint(ef, (ulong)esb.Length); ef.Write(esb);
            }
            var efb = ef.ToArray();
            WriteVarint(ms, 0xC2); WriteVarint(ms, (ulong)efb.Length); ms.Write(efb);
        }
        // ConfigData (25) — repeated TPassEvaluate。protobuf-net 编码：每个 TPassEvaluate 是
        // 独立 field25(len-delimited)，内容直接是字段（无子消息 tag），Value=默认(0)不序列化。
        // PveCoreCreator._InitWithStartDataCore 用 ConfigDatas[52002(0xCB22)] 作为索敌限时（秒）
        // 覆盖 battlefieldTime：ConfigDatas[52002]=v → 索敌限时=v*1000 ms。之前发 (52002,1) 导致
        // 索敌限时 1 秒立即耗尽。删除 52002 → TryGetValue 失败回退 dictCopy.battle_time=180。
        if (isSeaCopy)
        {
            foreach (var (t, v) in new[] { (50000, 1), (0, 1) })
            {
                using var ce = new MemoryStream();
                if (t != 0) { WriteVarint(ce, 0x08); WriteVarint(ce, unchecked((ulong)t)); } // Type(1)
                if (v != 0) { WriteVarint(ce, 0x10); WriteVarint(ce, unchecked((ulong)v)); } // Value(2)
                var ceb = ce.ToArray();
                WriteVarint(ms, 0xCA); WriteVarint(ms, (ulong)ceb.Length); ms.Write(ceb);
            }
        }
        return ms.ToArray();
    }

    public int DecodeStartBaseCopyIdPublic(byte[] args) => DecodeStartBaseCopyId(args);

    private static int DecodeStartBaseCopyId(byte[] args)
    {
        var reader = new ProtoReader(args);
        var copyId = 0;
        while (reader.TryReadField(out var field, out var wire))
        {
            if (field == 2 && wire == 0) copyId = checked((int)reader.ReadVarint());
            else reader.Skip(wire);
        }
        return copyId;
    }

    /// <summary>
    /// 解码 copy.StartBase 请求的 TStartBaseArg，提取：
    ///  - CopyId(2)
    ///  - 关卡出战舰队 HeroList(13) 中第一个 TStartBaseHeroList 的 HeroIdList(1, repeated uint32)
    /// 客户端在请求里已指定本关可出战的舰船（剧情关限制），服务端必须回环它而非自行猜测。
    /// </summary>
    private static (int CopyId, List<int>? DeployHeroIds, bool IsRunningFight, int BattleMode, int MatchType) DecodeStartBaseArg(byte[] args)
    {
        var reader = new ProtoReader(args);
        int copyId = 0;
        List<int>? deployHeroIds = null;
        bool isRunningFight = false;
        int battleMode = 0;
        int matchType = 0;
        while (reader.TryReadField(out var field, out var wire))
        {
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
                    var sub = new ProtoReader(reader.ReadBytes());
                    var ids = new List<int>();
                    while (sub.TryReadField(out var f2, out var w2))
                    {
                        if (f2 == 1 && w2 == 0) ids.Add(checked((int)sub.ReadVarint()));
                        else sub.Skip(w2);
                    }
                    if (ids.Count > 0) deployHeroIds = ids;
                    break;
                default:
                    reader.Skip(wire);
                    break;
            }
        }
        return (copyId, deployHeroIds, isRunningFight, battleMode, matchType);
    }

    private async Task<byte[]> BuildPassBaseRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        var account = await GetAccountAsync(profileId, ct);
        return EncodePassBaseRet();
    }

    private static byte[] EncodePassBaseRet()
    {
        using var ms = new MemoryStream();
        // Grade (4) = 3 (SSS)
        WriteVarint(ms, 0x20); WriteVarint(ms, 3);
        // StarLv (6) = 7 (all 3 stars: 1|2|4)
        WriteVarint(ms, 0x30); WriteVarint(ms, 7);
        // FirstPass (10) = 1
        WriteVarint(ms, 0x50); WriteVarint(ms, 1);
        // PassTime (8) = 60
        WriteVarint(ms, 0x40); WriteVarint(ms, 60);
        return ms.ToArray();
    }

    /// <summary>响应 copy.GetRandomFactors（TGetRandomFactorRet）。海域索敌/侦察关卡
    /// 详情页请求随机因子，服务端按 copyId → config_copy_display.random_factor_sets
    /// → config_random_factor_set.factor_groups → config_random_factor_group.factor 解析。</summary>
    private byte[] EncodeGetRandomFactors(byte[]? args)
    {
        var reader = new ProtoReader(args ?? []);
        int copyId = 0;
        while (reader.TryReadField(out var field, out var wire))
        {
            if (field == 1 && wire == 0) copyId = checked((int)reader.ReadVarint()); // CopyId(1)
            else reader.Skip(wire);
        }
        using var ms = new MemoryStream();
        if (_copyRandomFactors.TryGetValue(copyId, out var factors))
        {
            foreach (var f in factors)
            {
                // Factors(1) = repeated int32
                WriteVarint(ms, 0x08); WriteVarint(ms, unchecked((ulong)f));
            }
        }
        // LastRefreshTime(2)=0 / IsShowTips(3)=false 默认省略
        return ms.ToArray();
    }

    /// <summary>
    /// 回环 copy.AttackBase 请求（TAttackBaseArg: AttackType(1)/CopyId(2)/HeroIds(3)/EnemyId(4)）
    /// 并附带一个伤害值（字段5，按最大生命值比例的扣血，HpCoefficient 比例尺=1e10 下 10%=1e9）。
    /// 客户端在没有回报时认定攻击失效，因此这里必须回包。
    /// </summary>
    private static byte[] BuildAttackBaseRet(byte[]? args)
    {
        int attackType = 0, copyId = 0, enemyId = 0;
        var heroIds = new List<int>();
        if (args is { Length: > 0 })
        {
            var reader = new ProtoReader(args);
            while (reader.TryReadField(out var field, out var wire))
            {
                switch (field)
                {
                    case 1 when wire == 0: attackType = checked((int)reader.ReadVarint()); break;
                    case 2 when wire == 0: copyId = checked((int)reader.ReadVarint()); break;
                    case 3 when wire == 0: heroIds.Add(checked((int)reader.ReadVarint())); break;
                    case 4 when wire == 0: enemyId = checked((int)reader.ReadVarint()); break;
                    default: reader.Skip(wire); break;
                }
            }
        }
        using var ms = new MemoryStream();
        if (attackType != 0) { WriteVarint(ms, 0x08); WriteVarint(ms, unchecked((ulong)attackType)); }
        if (copyId != 0) { WriteVarint(ms, 0x10); WriteVarint(ms, unchecked((ulong)copyId)); }
        foreach (var hid in heroIds) { WriteVarint(ms, 0x18); WriteVarint(ms, unchecked((ulong)hid)); }
        if (enemyId != 0) { WriteVarint(ms, 0x20); WriteVarint(ms, unchecked((ulong)enemyId)); }
        // 伤害：扣除 10% 最大生命值（比例尺下 1e9）
        WriteVarint(ms, 0x28); WriteVarint(ms, 1_000_000_000UL);
        return ms.ToArray();
    }

    /// <summary>回环 copy.QuitBase 请求（TQuitBaseArg），让客户端确认退出请求被受理。</summary>
    private static byte[] BuildQuitBaseRet(byte[]? args)
    {
        using var ms = new MemoryStream();
        if (args is { Length: > 0 })
        {
            // 直接回环原始请求字节（客户端数据回环，避免服务端造数据）
            ms.Write(args);
        }
        return ms.ToArray();
    }

    private static void WriteString(Stream output, int field, string value)
    {
        WriteVarint(output, (ulong)field);
        var bytes = Encoding.UTF8.GetBytes(value);
        WriteVarint(output, (ulong)bytes.Length);
        output.Write(bytes);
    }

    private static byte[] EncodePlotRewardRet(int plotId)
    {
        using var ms = new MemoryStream();
        if (plotId != 0) { WriteVarint(ms, 0x08); WriteVarint(ms, unchecked((ulong)plotId)); }
        return ms.ToArray();
    }

    private static ulong DecodeVarint(ReadOnlySpan<byte> data)
    {
        ulong value = 0;
        for (var shift = 0; shift < 64 && shift / 7 < data.Length; shift += 7)
            value |= (ulong)(data[shift / 7] & 0x7f) << shift;
        return value;
    }

    /// <summary>推送 battle.createBattleInfo 触发 BattleLauncher 场景切换。</summary>
    public byte[] BuildBattleCreateInfoPushEmpty(uint now)
    {
        // TBattlePushMessage — 完全空消息，表示本地 PvE
        using var ms = new MemoryStream();
        return TMessageCodec.EncodeResponse(new TResponse(
            Method: "battle.createBattleInfo",
            Ret: ms.ToArray(),
            Time: now));
    }

    public byte[] BuildBattleCreateInfoPush(uint now, int copyId, List<Hero> heroes)
    {
        using var ms = new MemoryStream();
        // UserList (5) — TBattleUserList with BattlePlayer
        using var userList = new MemoryStream();
        WriteVarint(userList, 0x08); WriteVarint(userList, 0); // Index=0
        // Player (2) — TBattlePlayer (same as TStartBaseRet.BattlePlayer)
        var playerBytes = EncodeBattlePlayer(heroes);
        WriteVarint(userList, 0x12); WriteVarint(userList, (ulong)playerBytes.Length); userList.Write(playerBytes);
        var ulb = userList.ToArray();
        WriteVarint(ms, 0x2A); WriteVarint(ms, (ulong)ulb.Length); ms.Write(ulb);
        return TMessageCodec.EncodeResponse(new TResponse(
            Method: "battle.createBattleInfo",
            Ret: ms.ToArray(),
            Time: now));
    }

    private static byte[] EncodeBattlePlayer(List<Hero> heroes)
    {
        using var bp = new MemoryStream();
        WriteVarint(bp, 0x08); WriteVarint(bp, 1); // Pid=1
        WriteVarint(bp, 0x10); WriteVarint(bp, 1); // Uid=1
        WriteString(bp, 0x1A, "player"); // Uname
        WriteVarint(bp, 0x20); WriteVarint(bp, 1); // Level=1
        WriteVarint(bp, 0x28); WriteVarint(bp, 1); // PlayerCamp=1
        WriteVarint(bp, 0x30); WriteVarint(bp, 1); // Index=1
        using var fleet = new MemoryStream();
        WriteVarint(fleet, 0x08); WriteVarint(fleet, 1); // FleetId=1
        WriteVarint(fleet, 0x10); WriteVarint(fleet, 2); // FormationId=2
        WriteVarint(fleet, 0x18); WriteVarint(fleet, 1); // Index=1
        for (int i = 0; i < Math.Min(heroes.Count, 6); i++)
        {
            var h = heroes[i];
            using var ship = new MemoryStream();
            WriteVarint(ship, 0x08); WriteVarint(ship, (ulong)h.HeroId);
            WriteVarint(ship, 0x10); WriteVarint(ship, unchecked((ulong)h.TemplateId));
            WriteVarint(ship, 0x18); WriteVarint(ship, unchecked((ulong)h.Level));
            WriteVarint(ship, 0x20); WriteVarint(ship, unchecked((ulong)i));
            foreach (var (attrId, val) in new[] { (1, 1000), (2, 100), (3, 50) })
            {
                using var attr = new MemoryStream();
                WriteVarint(attr, 0x08); WriteVarint(attr, unchecked((ulong)attrId));
                WriteVarint(attr, 0x10); WriteVarint(attr, unchecked((ulong)val));
                var ab = attr.ToArray();
                WriteVarint(ship, 0x2A); WriteVarint(ship, (ulong)ab.Length); ship.Write(ab);
            }
            WriteVarint(ship, 0x30); WriteVarint(ship, PlayerAccountFactory.HpCoefficient);
            WriteVarint(ship, 0x58); WriteVarint(ship, 3);
            WriteVarint(ship, 0x60); WriteVarint(ship, unchecked((ulong)h.Fashioning));
            var sb = ship.ToArray();
            WriteVarint(fleet, 0x22); WriteVarint(fleet, (ulong)sb.Length); fleet.Write(sb);
            WriteVarint(fleet, 0x40); WriteVarint(fleet, (ulong)h.HeroId); // HeroList(8) per ship
        }
        WriteVarint(fleet, 0x28); WriteVarint(fleet, 0);
        WriteVarint(fleet, 0x38); WriteVarint(fleet, 0);
        WriteVarint(fleet, 0x48); WriteVarint(fleet, 1);
        var fb = fleet.ToArray();
        WriteVarint(bp, 0x3A); WriteVarint(bp, (ulong)fb.Length); bp.Write(fb);
        return bp.ToArray();
    }

    public async Task<IReadOnlyList<byte[]>> BuildPostEquipPushesAsync(string profileId, uint now, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var heroes = account.Dock.Heroes.Select(ToHeroGrid).ToList();
        return
        [
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "hero.UpdateHeroBagData",
                Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                Time: now)),
            BuildEquipPush(account, now),
        ];
    }

    /// <summary>编码玩家编队数据为 TSelfTactis protobuf。</summary>
    public static byte[] EncodeFleet(PlayerFleet fleet)
    {
        using var ms = new MemoryStream();
        foreach (var t in fleet.Tactics)
        {
            using var entry = new MemoryStream();
            // tacticName (1)
            if (!string.IsNullOrEmpty(t.TacticName))
            {
                WriteVarint(entry, 0x0A);
                var nameBytes = Encoding.UTF8.GetBytes(t.TacticName);
                WriteVarint(entry, (ulong)nameBytes.Length);
                entry.Write(nameBytes);
            }
            // heroInfo (2, repeated int32)
            if (t.HeroInfo is { Count: > 0 })
            {
                foreach (var h in t.HeroInfo)
                {
                    WriteVarint(entry, 0x10);
                    WriteVarint(entry, unchecked((ulong)h));
                }
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
            {
                foreach (var h in t.ExHeroInfo)
                {
                    WriteVarint(entry, 0x38);
                    WriteVarint(entry, unchecked((ulong)h));
                }
            }
            var body = entry.ToArray();
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
        var entries = new List<FleetEntry>();
        var reader = new ProtoReader(args);
        while (reader.TryReadField(out var field, out var wire))
        {
            if (field == 1 && wire == 2) // tactics
            {
                var inner = new ProtoReader(reader.ReadBytes());
                var modeId = 0;
                var type = 1;
                var tacticName = "";
                var heroInfo = new List<int>();
                var exHeroInfo = new List<int>();
                var strategyId = 0;
                var formationId = 2;
                while (inner.TryReadField(out var f, out var w))
                {
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
                }
                entries.Add(new FleetEntry(modeId, type, tacticName, heroInfo, exHeroInfo, strategyId, formationId));
            }
            else reader.Skip(wire);
        }
        return entries;
    }

    private static byte[] EncodeCacheDataRet()
    {
        // TCacheDataRet{Ret=string}
        using var ms = new MemoryStream();
        WriteString(ms, 0x0A, "local");
        return ms.ToArray();
    }

    /// <summary>编码剧情章节初始数据为 TUserCopyInfo protobuf（CopyType=1 PlotCopy）。</summary>
public static byte[] EncodePlotCopyInfo(int chapterId = 1, bool markPassed = false)
    {
        // 硬编码前 5 章的所有关卡，全部标记为已通关
        // 章节1: [1,2,3,4,6,7,9,10,11,12,13]
        // 章节2: [101,102,103,104,105,106,107,108]
        var hardCodedCopyIds = new[] {
            // 章节1
            1,2,3,4,6,7,9,10,11,12,13,
            // 章节2
            101,102,103,104,105,106,107,108,
        };
        using var ms = new MemoryStream();
        foreach (var cid in hardCodedCopyIds)
        {
            using var baseInfo = new MemoryStream();
            WriteVarint(baseInfo, 0x08); WriteVarint(baseInfo, unchecked((ulong)cid)); // BaseId(1)
            WriteVarint(baseInfo, 0x10); WriteVarint(baseInfo, 0); // Rid(2)=0
            WriteVarint(baseInfo, 0x18); WriteVarint(baseInfo, 0); // StarLevel(3)=0
            WriteVarint(baseInfo, 0x20); WriteVarint(baseInfo, 0); // IsRunningFight(4)=0
            WriteVarint(baseInfo, 0x28); WriteVarint(baseInfo, 0); // LBPoint(5)=0
            WriteVarint(baseInfo, 0x30); WriteVarint(baseInfo, 1); // FirstPassTime(6)=1
            var body = baseInfo.ToArray();
            WriteVarint(ms, 0x0A); WriteVarint(ms, (ulong)body.Length); ms.Write(body);
        }
        // MaxCopyId = 108（章节2最后一个关卡），使 _getFarestId 返回章节2
        WriteVarint(ms, 0x10); WriteVarint(ms, 108);
        WriteVarint(ms, 0x18); WriteVarint(ms, 1);
        return ms.ToArray();
    }

    /// <summary>编码海域（SeaCopy, CopyType=2）数据为 TUserCopyInfo protobuf。
    /// 海域页面（SeaCopyPage）依赖 Data.copyData:GetCopyInfo() 里有海域关卡，
    /// 否则 CheckChapterIsOpen/GetBattleModeChapter 返回 false，节点不显示。
    /// MaxCopyId = 第 1 章第一关，使 _getFarestId(SeaCopy) 落在第 1 章。</summary>
    public static byte[] EncodeSeaCopyInfo()
    {
        var seaLevels = ChapterCopyLoader.GetSeaLevels();
        var maxCopyId = ChapterCopyLoader.GetSeaFirstCopyId();
        using var ms = new MemoryStream();
        foreach (var cid in seaLevels)
        {
            using var baseInfo = new MemoryStream();
            WriteVarint(baseInfo, 0x08); WriteVarint(baseInfo, unchecked((ulong)cid)); // BaseId(1)
            WriteVarint(baseInfo, 0x10); WriteVarint(baseInfo, 0); // Rid(2)=0
            WriteVarint(baseInfo, 0x18); WriteVarint(baseInfo, 0); // StarLevel(3)=0
            WriteVarint(baseInfo, 0x20); WriteVarint(baseInfo, 0); // IsRunningFight(4)=0
            WriteVarint(baseInfo, 0x28); WriteVarint(baseInfo, 0); // LBPoint(5)=0
            WriteVarint(baseInfo, 0x30); WriteVarint(baseInfo, 0); // FirstPassTime(6)=0
            var body = baseInfo.ToArray();
            WriteVarint(ms, 0x0A); WriteVarint(ms, (ulong)body.Length); ms.Write(body);
        }
        WriteVarint(ms, 0x10); WriteVarint(ms, unchecked((ulong)maxCopyId)); // MaxCopyId(2)
        WriteVarint(ms, 0x18); WriteVarint(ms, 2); // CopyType(3)=SeaCopy
        return ms.ToArray();
    }
}
