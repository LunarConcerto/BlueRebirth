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
internal sealed partial class GameLoginMessageHandler
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

    public GameLoginMessageHandler(SqliteGameRepository repo, ServerOptions options, ILoggerFactory loggerFactory)
    {
        _repo = repo;
        _logger = loggerFactory.CreateLogger<GameLoginMessageHandler>();
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


}
