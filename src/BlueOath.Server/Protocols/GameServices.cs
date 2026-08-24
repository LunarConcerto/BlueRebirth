using System.Text;
using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;
using BlueOath.Storage;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 处理游戏登录应用层（11 字节头 + protobuf），该层分别承载于 TCP 的 NetSocket 帧内
/// 与 UDP 的 KCP 流内。由两种登录传输共用，避免重复实现。
/// 角色（<see cref="PlayerCharacter"/>）与船坞（<see cref="HeroDock"/>）数据不再硬编码，
/// 而是从存档数据库读取。
/// </summary>
internal sealed class GameServices
{

    private readonly SqliteGameRepository _repo;
    private readonly ILogger _logger;
    private readonly ILogger _fileLogger;
    private readonly GmGoodsConfig _gmGoods;
    private readonly Dictionary<int, (int Type, int ConfigId, int Num)> _gmGoodsMap;
    private readonly Dictionary<int, int> _fashionSfIdMap;
    private readonly IReadOnlyList<GmMailConfig> _gmMails;
    private readonly Dictionary<int, ConfigExtractShip> _extractShips;
    private readonly Dictionary<int, ConfigDropItem> _dropItems;
    private readonly Dictionary<int, ConfigSpecialdraw> _specialDraws;
    private readonly Dictionary<int, ConfigShipInfo> _shipInfos;
    private readonly Dictionary<int, int> _expPerItem;
    private readonly Dictionary<int, int> _expNeeded;
    private readonly Dictionary<int, List<RandomFactorEntry>> _copyRandomFactors;
    private readonly Random _rng = new();

    public GameServices(SqliteGameRepository repo, ServerOptions options, ILoggerFactory loggerFactory)
    {
        _repo = repo;
        _logger = loggerFactory.CreateLogger<GameServices>();
        _fileLogger = loggerFactory.CreateLogger(Infrastructure.GameLoginFileLoggerProvider.Category);
        _gmGoods = GmGoodsConfigLoader.Load(options.DataRoot);
        _gmGoodsMap = _gmGoods.Goods.ToDictionary(g => g.GoodId, g => (g.Type, g.ItemId, g.Num));
        _fashionSfIdMap = _gmGoods.FashionSfId.ToDictionary(kv => kv.Key, kv => kv.Value);
        _gmMails = GmMailsConfigLoader.Load(options.DataRoot).Mails;
        (_extractShips, _dropItems, _specialDraws, _shipInfos) = BuildShipExtractLoader.Load(options.DataRoot);
        (_expPerItem, _expNeeded) = ShipLevelupLoader.Load(options.DataRoot);
        _copyRandomFactors = RandomFactorLoader.Load(options.DataRoot);
        ChapterCopyLoader.Load(options.DataRoot);
        CopyBattleLoader.Load(options.DataRoot);
        MissionChainLoader.Load(options.DataRoot);
        ShipMainLoader.Load(options.DataRoot);
        AssistShipLoader.Load(options.DataRoot);
        EquipLoader.Load(options.DataRoot);
        ShipHandbookLoader.Load(options.DataRoot);
        PlotTriggerLoader.Load(options.DataRoot);
    }

    /// <summary>文件日志（game-login.log）供各模块记录帧级诊断。</summary>
    internal ILogger FileLogger => _fileLogger;

    /// <summary>GM 邮件配置（供 MailModule 等使用）。</summary>
    internal IReadOnlyList<GmMailConfig> GmMails => _gmMails;

    /// <summary>GM 商品映射：GoodId → (Type, ConfigId, Num)。</summary>
    internal IReadOnlyDictionary<int, (int Type, int ConfigId, int Num)> GmGoodsMap => _gmGoodsMap;

    /// <summary>时装 FashionTid → SfId 映射。</summary>
    internal IReadOnlyDictionary<int, int> FashionSfIdMap => _fashionSfIdMap;

    /// <summary>持久化账号（供各模块修改后落盘）。</summary>
    internal Task SaveAccountAsync(PlayerAccount account, CancellationToken ct = default) => _repo.SaveAccountAsync(account, ct);

    /// <summary>抽卡模板配置（供 BuildShipService）。</summary>
    internal IReadOnlyDictionary<int, ConfigExtractShip> ExtractShips => _extractShips;

    /// <summary>掉落物品配置（供 BuildShipService）。</summary>
    internal IReadOnlyDictionary<int, ConfigDropItem> DropItems => _dropItems;

    /// <summary>船信息配置（供 BuildShipService）。</summary>
    internal IReadOnlyDictionary<int, ConfigShipInfo> ShipInfos => _shipInfos;

    /// <summary>随机数（供 BuildShipService 抽取）。</summary>
    internal Random Rng => _rng;

    /// <summary>最近一次抽卡新增的英雄 ID（供 BuildShipService 增量推送）。</summary>
    internal List<uint> LastBuildHeroIds => _lastBuildHeroIds;

    /// <summary>海域随机因子（供 BattleService）。</summary>
    internal IReadOnlyDictionary<int, List<RandomFactorEntry>> CopyRandomFactors => _copyRandomFactors;

    /// <summary>道具经验表（供 HeroService）。</summary>
    internal IReadOnlyDictionary<int, int> ExpPerItem => _expPerItem;

    /// <summary>升级所需经验表（供 HeroService）。</summary>
    internal IReadOnlyDictionary<int, int> ExpNeeded => _expNeeded;

    /// <summary>
    /// 处理登录操作码：解码 <c>TArgLogin</c>，按 <c>Pid</c> 创建/加载本地档案，
    /// 返回 <c>TRetLogin</c> 编码结果与解析出的 profileId（供会话后续关联账号）。
    /// </summary>
    public async Task<(int Operation, byte[] Payload, string ProfileId)> BuildLoginPayloadAsync(byte[] payload, CancellationToken ct)
    {
        var request = GameLoginCodec.DecodeLogin(payload);
        var profileId = string.IsNullOrWhiteSpace(request.Pid) ? PlayerAccountFactory.DefaultProfileId : request.Pid;
        _logger.LogInformation("game-login login pid={ProfileId}", profileId);
        if (await _repo.LoadAsync(profileId, ct) is null)
            await _repo.CreateAsync(profileId, profileId, ct);
        var response = new TRetLogin("0", profileId);
        return (GameOperationCodes.Login, GameLoginCodec.Encode(response), profileId);
    }

    /// <summary>解析 <c>player.Login</c> 参数中的 Pid，返回关联的 profileId。</summary>
    public string ResolveLoginProfileId(TRequest request)
    {
        if (request.Args is null)
            return PlayerAccountFactory.DefaultProfileId;
        var login = GameLoginCodec.DecodeLogin(request.Args);
        return string.IsNullOrWhiteSpace(login.Pid) ? PlayerAccountFactory.DefaultProfileId : login.Pid;
    }

    /// <summary>尚未迁移到模块的协议方法（旧 if/else + stub switch），随迁移逐步清空。</summary>

    public async Task<byte[]> BuildUpdateUserInfoPushAsync(string profileId, uint now, CancellationToken ct)
    {
        // 这是一条服务器主动推送（非响应），携带完整用户信息，使客户端的
        // UserService._UpdateUserInfo 写入 Data.userData（HomeEnvManager._CheckLevel
        // 在选主界面场景时用到）。CallbackHandler/IsResponse 保持 0 = 推送。
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var push = new TResponse(Method: "user.UpdateUserInfo",
            Ret: EncodeGetUserInfo(account), Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>
    /// 引导数据推送（guide.GuideInfo）。必须在 user.UserLogin 应答前发送，否则
    /// LoginOk 事件触发 GuideManager:init 时 GUIDE_DONE_STAGES 仍为空，
    /// 引导系统会触发第一个 stage(id=10000) 打开 GuidePage。这里标记所有 stage 已完成。
    /// </summary>
    public byte[] BuildGuideInfoPush(uint now, PlayerAccount account)
    {
        var settings = new List<GuideSetting>
        {
            new("GUIDE_DONE_STAGES", BuildDoneGuideStages()),
            new("GUIDE_DOING_STAGE", ""),
            new("PlotPassKey", ""),
            new("PlotUtcTime", "0"),
            new("PlotToggleSkipTip", "0"),
        };
        var plotList = PlotTriggerLoader.AllPlotIds;
        _fileLogger.LogInformation("guide.GuideInfo push PlotList count={Count}", plotList.Count);
        var guideInfo = new GuideInfo(PlotList: plotList, Setting: settings);
        var ret = PlayerDataCodec.Encode(guideInfo);
        var push = new TResponse(Method: "guide.GuideInfo", Ret: ret, Time: now, IsResponse: 0);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>
    /// 客户端主界面在主动请求前就要读到的玩家域数据（建造/浴室队列原本只在打开主界面后才
    /// 请求，但 PushAllNotice 会在 MainStage.StageEnter 阶段遍历它们，遇到 nil 会报错）。
    /// 其中船坞（hero.UpdateHeroBagData）来自存档实体，其余仍为最小/空占位。
    /// </summary>
    public async Task<IReadOnlyList<byte[]>> BuildSyncPushesAsync(string profileId, uint now, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var heroes = account.Dock.Heroes.Select(ToHeroGrid).ToList();

        return
        [
            // 登录时间推送，填充 userdata.loginTime/loginTimePre，防止
            // IsFirstLoginToday 用 os.date("*t", 0) 报 "time result cannot be represented"。
            // loginTimePre 取一小时前（同一天），使 IsFirstLoginToday 返回 false（非首登）。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "user.UpdateLoginTime",
                Ret: TMessageCodec.EncodeRetUpdateLoginTime(checked((int)now), checked((int)now - 3600)),
                Time: now)),

            // 服务器时间推送，填充 time.m_svrStartTime，防止 PeriodManager calTime 里
            // os.date("*t", 0) 报 "time result cannot be represented"。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "user.UpdateSvrTime",
                Ret: TMessageCodec.EncodeRetGetSvrTime(checked((int)now), checked((int)now)),
                Time: now)),

            TMessageCodec.EncodeResponse(new TResponse(
                Method: "build.BuildsInfo",
                Ret: PlayerDataCodec.Encode(new BuildsInfoRet(
                    BuildingList: [new BuildFormula(EndTime: 0)])),
                Time: now)),

            TMessageCodec.EncodeResponse(new TResponse(
                Method: "bathroom.BathroomInfo",
                Ret: PlayerDataCodec.Encode(ToBathroomInfo(account.Bath)),
                Time: now)),

            // 船坞数据来自存档实体。秘书舰 HeroId 必须与 Character.SecretaryId 一致。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "hero.UpdateHeroBagData",
                Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                Time: now)),

            // 建筑数据推送，包含 Office 建筑（BuildingInfos）防止
            // GetOffice() 返回 nil 导致 GetMaxWorkerStrength/GetCurStrengthReal 崩溃。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "building.UpdateBuildingInfo",
                Ret: PlayerDataCodec.EncodeBuildingInfo(now),
                Time: now)),

            // 编队数据推送，填充玩家编队信息防止 fleetpage 打开时 exHeroInfo nil 崩溃。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "tactic.GetHerosTactic",
                Ret: EncodeFleet(account.Fleet ?? PlayerAccountFactory.DefaultFleet()),
                Time: now)),

            // 剧情章节数据推送，填充首章关卡信息防止章节锁定。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "copy.GetCopy",
                Ret: EncodePlotCopyInfo(int.MaxValue, account.CopyProgress),
                Time: now)),

            // 海域章节数据推送（CopyType=2 SeaCopy）。海域页面节点依赖 GetCopyInfo() 里
            // 存在海域关卡，缺则 CheckChapterIsOpen/GetBattleModeChapter 全 false → 海域页空。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "copy.GetCopy",
                Ret: EncodeSeaCopyInfo(account.SeaProgress),
                Time: now)),

            // 图鉴数据推送。IllustrateInfoRet.IllustrateList 是玩家已解锁的图鉴条目
            // （IllustrateId = config_ship_handbook 的 key = ship_info_id）；未列出的条目
            // 由 IllustrateData:UpdateHero 从 config_ship_handbook 生成 LOCK 状态。
            // IllustrateList/IllustrateEquipList 两个 repeated 字段必须非 nil（否则 ipairs(nil) 崩溃）。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "illustrate.IllustrateInfo",
                Ret: PlayerDataCodec.Encode(new IllustrateInfoRet(
                    IllustrateList: account.Dock.Heroes
                        .Select(h => new IllustrateInfo(ToIllustrateId(h.TemplateId), now, 0, false, null, 0))
                        .ToList(),
                    IllustrateEquipList: [new IllustrateEquipInfo()])),
                Time: now)),

            // 商店数据推送，让 Data.shopData.m_shopInfo 非空。
            BuildShopInfoPush(now),

            // 充值数据推送。RechargeLogic.GetServerDataById 读 GetRechargeData().Info，
            // 缺则 pairs(nil) 报 "attempt to call a nil value"。Info(field 3, repeated TRECHARGE)
            // 编码一个空元素即可。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "recharge.RechargeInfo",
                Ret: new byte[] { 0x1A, 0x00 },
                Time: now)),

            // 仓库数据推送（道具）。
            BuildBagPush(account, now),

            // 时装数据推送（已解锁时装）。
            BuildFashionPush(account, now),

            // 装备仓库推送（EquipBagSize=2000，初始空）。
            BuildEquipPush(account, now),

            // 头像解锁列表推送（默认秘书舰的 profile 1021051 已解锁）。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "user.NewHeadUnlockedList",
                Ret: BuildHeadUnlockedListPush(account),
                Time: now)),

            // 邮件系统触发：payback.newPayback 推送会让 EmailService._TagUpdataMail
            // 置 updataTog=true，玩家打开邮件页面时才 SendGetMailList 拉取邮件列表。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "payback.newPayback",
                Time: now)),
        ];
    }

    /// <summary>加载账号；不存在时按默认工厂创建并落盘（兼容旧存档）。</summary>
    internal async Task<PlayerAccount> GetOrCreateAccountAsync(string profileId, CancellationToken ct)
    {
        var account = await _repo.LoadAccountAsync(profileId, ct);
        if (account is not null)
        {
            EnsureEquipIdFromAccount(account);
            if (account.Character.Level < 80)
                account = account with { Character = account.Character with { Level = 80 } };
            return account;
        }
        var created = PlayerAccountFactory.CreateDefault(profileId, checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()));
        await _repo.SaveAccountAsync(created, ct);
        return created;
    }

    /// <summary>仅加载账号（不创建），供会话层在推送时读取最新数据。</summary>
    public async Task<PlayerAccount> GetAccountAsync(string profileId, CancellationToken ct)
    {
        var account = await _repo.LoadAccountAsync(profileId, ct);
        if (account is null)
            return PlayerAccountFactory.CreateDefault(profileId, checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()));
        if (account.Character.Level < 80)
            account = account with { Character = account.Character with { Level = 80 } };
        return account;
    }

    /// <summary>获取最近一次抽卡创建的新英雄 ID 列表（供会话层只推送增量 hero 数据）。</summary>
    public IReadOnlyList<uint> GetLastBuildHeroIds() => _lastBuildHeroIds;

    internal static byte[] EncodeCreateUser(PlayerAccount account)
    {
        var c = account.Character;
        return UserInfoCodec.Encode(new TUserInfo(c.Uid, c.Name, c.Level, c.Class));
    }

    internal static byte[] EncodeGetUserInfo(PlayerAccount account)
    {
        var c = account.Character;
        // 旧存档（无 CreateTime 字段）加载后 CreateTime=0，会导致 PeriodManager 里
        // os.date("*t", 0) 报 "time result cannot be represented"，这里兜底为当前时间。
        var createTime = c.CreateTime != 0 ? c.CreateTime : checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        return TMessageCodec.EncodeRetGetUserInfo(new UserInfoFields(
            Uid: c.Uid, Uname: c.Name, Level: c.Level, Class: c.Class, SecretaryId: c.SecretaryId,
            CreateTime: createTime, Gold: c.Gold, Diamond: c.Diamond, Supply: c.Supply, Bath: c.Bath,
            MainGun: c.MainGun, Torpedo: c.Torpedo, Plane: c.Plane, Other: c.Other,
            Retire: c.Retire, Strategy: c.Strategy, Medal: c.Medal, Tower: c.Tower,
            CopyTrainPoint: c.CopyTrainPoint, FashionPoint: c.FashionPoint, GuildContri: c.GuildContri,
            Lucky: c.Lucky, TeacherMedal: c.TeacherMedal, TeacherPrestige: c.TeacherPrestige,
            BattlePassExp: c.BattlePassExp, BattlePassGold: c.BattlePassGold, PvePt: c.PvePt,
            GuildCoinII: c.GuildCoinII, UrEquipCoin: c.UrEquipCoin, ActivityBattlePassExp: c.ActivityBattlePassExp,
            GetHeroCount: c.GetHeroCount, AttackCount: c.AttackCount, MarriedNum: c.MarriedNum,
            Head: c.Head, HeadFrame: c.HeadFrame, Message: c.Message));
    }

    internal static BathHeroInfo ToBathHeroInfo(BathHero h) => new(h.HeroId, h.Pos, h.IsAuto, h.StartTime, h.BathTime, h.BuffId, h.BuffTime, h.Power);

    internal static BathroomInfo ToBathroomInfo(PlayerBath? b) => b is null
        ? new BathroomInfo([], 0)
        : new BathroomInfo(b.HeroList.Select(ToBathHeroInfo).ToList(), b.IsAllAuto);


    internal static HeroGrid ToHeroGrid(Hero hero) =>
        new(hero.HeroId, hero.TemplateId, hero.Level, hero.Fashioning, hero.Exp, hero.CreateTime,
            hero.UpdateTime, hero.Affection, hero.MarryTime, hero.CurHp, hero.Mood, hero.MarryType,
            hero.EquipSlots, hero.Name, hero.Lock);

    /// <summary>
    /// 由舰娘 TemplateId（config_ship_main 的 key）推导图鉴 IllustrateId
    /// （config_ship_handbook 的 key = ship_info_id）。数据规范 ship_main_id = ship_info_id * 10 + 1。
    /// </summary>
    internal static int ToIllustrateId(int templateId) => (templateId - 1) / 10;

    /// <summary>引导系统所有 stage id（guideStageConfig.lua 顶层 stages 的 id）。</summary>
    private static readonly string[] DoneGuideStages =
    [
        "10000", "100000", "1000000", "99995", "99998", "99992", "1200000", "14000",
        "200000", "22001", "300000", "40001", "700000", "800000", "910000", "92000",
        "93000", "94000", "95000", "96000", "97000", "98000", "99000", "110000",
        "120000", "130000", "140000", "150000", "160000",
    ];

    /// <summary>序列化 GUIDE_DONE_STAGES（Serialize 生成的字符串，key 为字符串）。</summary>
    private static string BuildDoneGuideStages() =>
        "{" + string.Join(",", DoneGuideStages.Select(id => $"[\"{id}\"]=1")) + "}";




    /// <summary>
    /// 处理 hero.ChangeEquip：装备穿脱（EquipId&gt;0 = 装备，EquipId=0 = 卸下）。
    /// 更新 Hero.EquipSlots 和 EquipItem.HeroId，落盘后返回空响应（客户端通过推送刷新）。
    /// </summary>
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
    internal const int GoodsTypeShip = 3;
    internal const int GoodsTypeDrop = 4;

    // ExtractType 常量（constants.lua）
    private const int ExtractTypeEquip = 1;
    internal const int ExtractTypeShip = 2;
    private const int ExtractTypeFashion = 3;
    internal const int ExtractTypeLimitShip = 4;
    private const int ExtractTypeMixTure = 5;

    // HeroRarityType 常量
    internal const int RaritySR = 3;
    private const int RaritySSR = 4;

    /// <summary>从船坞移除指定舰娘。</summary>
    internal static PlayerAccount RemoveHero(PlayerAccount account, uint heroId)
    {
        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        heroes.RemoveAll(h => h.HeroId == heroId);
        return account with { Dock = dock with { Heroes = heroes } };
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

    internal static (uint HeroId, int MarryType) DecodeMarryArg(ReadOnlySpan<byte> payload)
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
    internal static (int Id, int Num, string CacheId) DecodeBuildShipArg(ReadOnlySpan<byte> payload)
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
    /// 处理用户档案更新（已迁移到 UserService）。
    /// </summary>

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

    internal static (uint HeroId, List<(int Id, int Num)> Items) DecodeHeroAddExp(ReadOnlySpan<byte> data)
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

    internal static byte[] EncodeHeroAddExpRet(uint heroId, List<(int Id, int Num)> items)
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
    internal static (int CopyId, List<int>? DeployHeroIds, bool IsRunningFight, int BattleMode, int MatchType)
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

    /// <summary>根据 copyId 查找所属章节，返回当前可推进到的最大章节 id。</summary>
    internal static int FindChapterForCopy(int copyId, int currentChapterId)
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

    internal static (uint HeroId, bool Lock) DecodeLockHeroArg(ReadOnlySpan<byte> data)
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

    internal static List<uint> DecodeRetireHeroArg(ReadOnlySpan<byte> data)
    {
        ProtoReader reader = new(data);
        List<uint> heroIds = new();
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 0) heroIds.Add(checked((uint)reader.ReadVarint()));
            else reader.Skip(wire);
        return heroIds;
    }

    internal static (uint HeroId, string Name) DecodeChangeHeroNameArg(ReadOnlySpan<byte> data)
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

    internal static (uint HeroId, int TemplateId, int Num) DecodeHeroAddAffectionArg(ReadOnlySpan<byte> data)
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

    /// <summary>config_shop 全部商店 id（104 个）。</summary>
    internal static readonly int[] ShopIds =
    [
        1, 3, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
        26, 27, 29, 30, 101, 102, 104, 105, 106, 107, 110, 111, 200, 201, 202, 205,
        206, 207, 208, 300, 302, 303, 305, 306, 401, 901, 902, 903, 911, 912, 913,
        914, 915, 916, 917, 918, 919, 920, 924, 930, 931, 934, 935, 936, 940, 950,
        951, 954, 955, 956, 957, 958, 1001, 1002, 1003, 1004, 1006, 1010, 1011, 1012,
        1013, 1014, 1015, 1020, 1021, 1022, 1023, 1024, 1025, 1026, 1030, 1040, 1041,
        1042, 1043, 1044, 1051, 1052, 1071, 1072, 1073, 1074, 1201, 1202,
    ];

    /// <summary>商店列表响应（shop.GetShopsInfo 使用）。</summary>
    internal byte[] BuildShopsInfoRet(uint now)
    {
        var goodsByShop = _gmGoods.Goods
            .GroupBy(g => g.ShopId)
            .ToDictionary(g => g.Key, g => g.Select(x => new ShopGoodsData(x.GoodId, 0, 0)).ToList());
        var shopInfo = ShopIds.Select(id =>
            goodsByShop.TryGetValue(id, out var goods)
                ? new RetShopInfo(id, goods)
                : new RetShopInfo(id)).ToList();
        return PlayerDataCodec.Encode(new RetShopsInfo(ShopInfo: shopInfo));
    }

    /// <summary>
    /// 商店数据推送（shop.UpdateShopInfo）。让 Data.shopData.m_shopInfo 非空，否则
    /// ShopData.GetShopInfoById 里 m_shopInfo[shopId] 为 nil，红点系统（BrokenFashionShop
    /// → CheckShopNewFashion）在主页/商店页就崩溃。
    /// GM 商品按配置的 ShopId 分组放入对应商店（分页）。
    /// </summary>
public byte[] BuildShopInfoPush(uint now)
    {
        var push = new TResponse(Method: "shop.UpdateShopInfo",
            Ret: BuildShopsInfoRet(now),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    // GoodsType 常量（constants.lua）。ITEM=1, EQUIP=2, CURRENCY=5, EQUIP_ENHANCE_ITEM=6, FASHION=18。
    internal const int GoodsTypeCurrency = 5;
    internal const int GoodsTypeEquip = 2;
    internal const int GoodsTypeFashion = 18;
    private uint _nextEquipId = 1;
    private uint _nextHeroId = 2; // 1 是默认秘书舰

    /// <summary>为 GM 命令生成下一个可用的舰娘实例 ID（调用前需确保已加载账号）。</summary>
    public uint NextHeroId() => _nextHeroId++;

    /// <summary>生成下一个装备实例 ID。</summary>
    internal uint NextEquipId() => _nextEquipId++;

    /// <summary>初始化 _nextEquipId 为账号中最大装备 ID + 1（避免服务重启后 ID 重复）。</summary>
    internal void EnsureEquipIdFromAccount(PlayerAccount account)
    {
        if (account.Equip is { Items.Count: > 0 } equip)
        {
            var maxId = equip.Items.Max(e => e.EquipId);
            if (maxId >= _nextEquipId)
                _nextEquipId = maxId + 1;
        }
        if (account.Dock is { Heroes.Count: > 0 } dock)
        {
            var maxId = dock.Heroes.Max(h => h.HeroId);
            if (maxId >= _nextHeroId)
                _nextHeroId = maxId + 1;
        }
    }


    /// <summary>发放单个 GM 商品（已迁移到 ShopModule）。</summary>


    /// <summary>
    /// 货币发放（CurrencyType → UserInfo 字段）。覆盖客户端 UserInfo 里全部 24 种持久货币
    /// （constants.lua CurrencyType 与 user_pb.lua TGetUserInfoRet 字段的并集，排除非 UserInfo
    /// 的战斗/建筑临时值如 BULLET/GAS/ELECTRIC 等）。
    /// </summary>
    internal static PlayerAccount AddCurrency(PlayerAccount account, int currencyType, int num)
    {
        var c = account.Character;
        c = currencyType switch
        {
            1 => c with { Gold = c.Gold + num },
            2 => c with { Diamond = c.Diamond + num },
            5 => c with { Supply = c.Supply + num },
            8 => c with { MainGun = c.MainGun + num },
            9 => c with { Torpedo = c.Torpedo + num },
            10 => c with { Plane = c.Plane + num },
            11 => c with { Other = c.Other + num },
            12 => c with { Retire = c.Retire + num },
            13 => c with { Bath = c.Bath + num },
            14 => c with { Strategy = c.Strategy + num },
            15 => c with { Medal = c.Medal + num },
            18 => c with { Tower = c.Tower + num },
            22 => c with { CopyTrainPoint = c.CopyTrainPoint + num },
            23 => c with { FashionPoint = c.FashionPoint + num },
            24 => c with { GuildContri = c.GuildContri + num },
            25 => c with { Lucky = c.Lucky + num },
            26 => c with { TeacherMedal = c.TeacherMedal + num },
            27 => c with { TeacherPrestige = c.TeacherPrestige + num },
            28 => c with { BattlePassExp = c.BattlePassExp + num },
            29 => c with { BattlePassGold = c.BattlePassGold + num },
            30 => c with { PvePt = c.PvePt + num },
            31 => c with { GuildCoinII = c.GuildCoinII + num },
            32 => c with { UrEquipCoin = c.UrEquipCoin + num },
            33 => c with { ActivityBattlePassExp = c.ActivityBattlePassExp + num },
            _ => c with { Gold = c.Gold + num },
        };
        return account with { Character = c };
    }

    internal static PlayerAccount AddBagItem(PlayerAccount account, int templateId, int num)
    {
        var bag = account.Bag ?? new PlayerBag([], 100);
        var items = bag.Items.ToList();
        var idx = items.FindIndex(i => i.TemplateId == templateId);
        if (idx >= 0)
            items[idx] = items[idx] with { Num = items[idx].Num + num };
        else
            items.Add(new BagItem(templateId, num));
        return account with { Bag = bag with { Items = items } };
    }

    /// <summary>仓库数据推送（bag.UpdateBagData）。</summary>
    public byte[] BuildBagPush(PlayerAccount account, uint now)
    {
        var bag = account.Bag ?? new PlayerBag([], 100);
        var info = bag.Items.Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList();
        var push = new TResponse(Method: "bag.UpdateBagData",
            Ret: PlayerDataCodec.Encode(new BagInfoRet(BagType: 1, BagSize: bag.BagSize, BagInfo: info)),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>时装数据推送（fashion.updateData）。</summary>
    public byte[] BuildFashionPush(PlayerAccount account, uint now)
    {
        var fashion = account.Fashion ?? new PlayerFashion([]);
        var info = fashion.Entries.Select(e => new FashionInfo(e.SfId, e.FashionTids)).ToList();
        var push = new TResponse(Method: "fashion.updateData",
            Ret: PlayerDataCodec.Encode(new FashionList(info)),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>装备仓库推送（equip.UpdateEquipBagData）。</summary>
    public byte[] BuildEquipPush(PlayerAccount account, uint now)
    {
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        var info = equip.Items.Select(e => new EquipInfo(e.EquipId, e.TemplateId, e.EnhanceLv,
            e.Star, e.HeroId, e.EnhanceExp)).ToList();
        var push = new TResponse(Method: "equip.UpdateEquipBagData",
            Ret: PlayerDataCodec.Encode(new EquipList(EquipBagSize: equip.EquipBagSize, EquipInfo: info)),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>购买后的数据推送（货币 + 仓库 + 时装 + 装备），供会话在 shop.BuyGoods 应答后发出。</summary>
    public async Task<IReadOnlyList<byte[]>> BuildPostBuyPushesAsync(string profileId, uint now, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        return
        [
            await BuildUpdateUserInfoPushAsync(profileId, now, ct),
            BuildBagPush(account, now),
            BuildFashionPush(account, now),
            BuildEquipPush(account, now),
        ];
    }

}
