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
internal sealed class GameLoginMessageHandler
{
    private readonly SqliteGameRepository _repo;
    private readonly ILogger _logger;
    private readonly ILogger _fileLogger;
    private readonly GmGoodsConfig _gmGoods;
    private readonly Dictionary<int, (int Type, int ConfigId, int Num)> _gmGoodsMap;
    private readonly Dictionary<int, int> _fashionSfIdMap;
    private readonly IReadOnlyList<GmMailConfig> _gmMails;
    private readonly Dictionary<int, BuildShipPool> _buildPools;
    private readonly Dictionary<int, int> _expPerItem;
    private readonly Dictionary<int, int> _expNeeded;
    private readonly Dictionary<int, List<int>> _copyRandomFactors;
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
        _buildPools = GmBuildPoolLoader.Load(options.DataRoot);
        (_expPerItem, _expNeeded) = ShipLevelupLoader.Load(options.DataRoot);
        _copyRandomFactors = RandomFactorLoader.Load(options.DataRoot);
        ChapterCopyLoader.Load(options.DataRoot);
        CopyBattleLoader.Load(options.DataRoot);
        ShipMainLoader.Load(options.DataRoot);
        AssistShipLoader.Load(options.DataRoot);
        EquipLoader.Load(options.DataRoot);
    }

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

    /// <summary>
    /// 处理 C2S 消息：按方法名分发到对应响应。角色相关方法（player.CreateUser /
    /// user.GetUserInfo）从存档账号读取，其余仍为最小响应或返回空。
    /// </summary>
    public async Task<(int Operation, byte[] Payload)> BuildC2SResponseAsync(
        TRequest request, string profileId, CancellationToken ct)
    {
        _fileLogger.LogInformation("game-login C2S method={Method} callback={Callback} argsLen={ArgsLen} hex={Hex}",
            request.Method, request.CallbackHandler, request.Args?.Length ?? 0,
            request.Args is { Length: > 0 } ? Convert.ToHexString(request.Args) : "");
        var now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        byte[] ret;
        if (request.Method == "shop.BuyGoods")
        {
            ret = await BuildBuyGoodsRetAsync(request, profileId, ct);
        }
        else if (request.Method == "shop.QualityBuyGoods")
        {
            ret = await BuildQualityBuyGoodsRetAsync(request, profileId, ct);
        }
        else if (request.Method == "mail.FetchItem" || request.Method == "mail.FetchAllItems")
        {
            ret = await BuildFetchMailRetAsync(request, profileId, now, ct);
        }
        else if (request.Method == "hero.ChangeEquip")
        {
            ret = await BuildChangeEquipRetAsync(request, profileId, ct);
        }
        else if (request.Method == "hero.AddExp")
        {
            ret = await BuildAddExpRetAsync(request, profileId, ct);
        }
        else if (request.Method == "tactic.GetHerosTactic")
        {
            ret = await BuildGetHerosTacticAsync(profileId, ct);
        }
        else if (request.Method == "tactic.SetHerosTactic")
        {
            ret = await BuildSetHerosTacticAsync(request, profileId, ct);
        }
        else if (request.Method == "guide.PlotReward")
        {
            ret = BuildPlotReward(request.Args ?? []);
        }
        else if (request.Method == "user.SetUserSecretary")
        {
            ret = await BuildUserProfileUpdateAsync(request, profileId, ct, "Secretary");
        }
        else if (request.Method == "user.ChangeName")
        {
            ret = await BuildUserProfileUpdateAsync(request, profileId, ct, "Name");
        }
        else if (request.Method == "user.SetMessage")
        {
            ret = await BuildUserProfileUpdateAsync(request, profileId, ct, "Message");
        }
        else if (request.Method == "user.SetPlayerHeadFrame")
        {
            ret = await BuildUserProfileUpdateAsync(request, profileId, ct, "HeadFrame");
        }
        else if (request.Method == "user.SetHead")
        {
            ret = await BuildUserProfileUpdateAsync(request, profileId, ct, "Head");
        }
        else if (request.Method == "buildship.BuildShip")
        {
            ret = await BuildBuildShipRetAsync(request, profileId, ct);
        }
        else if (request.Method == "copy.StartBase")
        {
            ret = await BuildStartBaseRetAsync(request, profileId, ct);
        }
        else if (request.Method == "copy.AttackBase")
        {
            ret = BuildAttackBaseRet(request.Args);
        }
        else if (request.Method == "copy.PassBase")
        {
            ret = await BuildPassBaseRetAsync(request, profileId, ct);
        }
        else if (request.Method == "copy.QuitBase")
        {
            ret = BuildQuitBaseRet(request.Args);
        }
        else if (request.Method == "copy.GetRandomFactors")
        {
            ret = EncodeGetRandomFactors(request.Args);
        }
        else
        {
            ret = request.Method switch
            {
                "player.Login" => GameLoginCodec.Encode(new TRetLogin("ok", "1")),
                "player.GetUserList" => [],
                "player.CreateUser" => EncodeCreateUser(await GetOrCreateAccountAsync(profileId, ct)),
                "user.UserLogin" => TMessageCodec.EncodeRetUserLogin("ok", "", 0),
                "user.GetUserInfo" => EncodeGetUserInfo(await GetOrCreateAccountAsync(profileId, ct)),
                "GetSvrTime" => TMessageCodec.EncodeRetGetSvrTime(now, now),
                "mail.GetMailList" => BuildMailListRet(now),
                "mail.OpenMail" => BuildMailListRet(now),
                "mail.DeleteMail" => BuildMailListRet(now),
                "mail.DeleteAllMail" => BuildMailListRet(now),
                "mail.ReceiveNewMail" => BuildMailListRet(now),
                "buildship.BuildShipInfo" => new byte[] { 0x08, 0x00 }, // DrawInfo: empty
                "buildship.BuildShipBox" => [],
                "buildship.BuildShipReward" => [],
                "user.GetHeadBuyCount" => new byte[] { 0x08, 0x00, 0x10, 0x00 }, // ShipFleetId=0, Count=0
                "user.BuyHead" => [],
                "user.NewHeadUnlockedList" => [],
                "copy.GetCopy" => EncodePlotCopyInfo(),
                "copy.UnLockCopy" => EncodePlotCopyInfo(),
                "guide.Setting" => [],
                "cachedata.CacheData" => EncodeCacheDataRet(),
                "battle.CreateMutiBattle" => [],
                _ => []
            };
        }
        var response = new TResponse(Method: request.Method, Ret: ret,
            CallbackHandler: request.CallbackHandler, Time: checked((uint)now),
            Token: request.Token, Seq: 0, IsResponse: 1);
        var encoded = TMessageCodec.EncodeResponse(response);
        _fileLogger.LogInformation("game-login S2C method={Method} retLen={Len} hex={Hex}",
            request.Method, ret.Length, Convert.ToHexString(encoded));
        return (GameOperationCodes.S2C, encoded);
    }

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
    public byte[] BuildGuideInfoPush(uint now)
    {
        var push = new TResponse(Method: "guide.GuideInfo",
            Ret: PlayerDataCodec.Encode(new GuideInfo(Setting:
            [
                new GuideSetting("GUIDE_DONE_STAGES", BuildDoneGuideStages()),
                new GuideSetting("GUIDE_DOING_STAGE", ""),
            ])),
            Time: now);
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
                Ret: PlayerDataCodec.Encode(new BathroomInfo(
                    HeroList: [new BathHeroInfo(HeroId: 0, StartTime: 0)])),
                Time: now)),

            // 船坞数据来自存档实体。秘书舰 HeroId 必须与 Character.SecretaryId 一致。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "hero.UpdateHeroBagData",
                Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                Time: now)),

            // 建筑数据推送，填充空的 SpecialPlotDatas/NormalPlotDatas 防止
            // BuildingData:GetSpecialPlots 里 pairs(nil) 崩溃（readonlymeta.lua
            // 重写的 pairs 对 nil 返回 nil 导致 generic for 调用 nil 迭代器）。
            // TUserBuildingInfo: field 11=NormalPlotDatas, field 12=SpecialPlotDatas
            // 各含一个全零 THeroPlotData（HeroId=0,PlotId=0,BuildingId=0），
            // 使 SetData 把 self.datas.SpecialPlotDatas 初始化为非空表。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "building.UpdateBuildingInfo",
                Ret: new byte[] {
                    0x62, 0x06, 0x08, 0x01, 0x10, 0x00, 0x18, 0x00,  // SpecialPlotDatas[0]: HeroId=1
                    0x5A, 0x06, 0x08, 0x01, 0x10, 0x00, 0x18, 0x00,  // NormalPlotDatas[0]: HeroId=1
                },
                Time: now)),

            // 编队数据推送，填充玩家编队信息防止 fleetpage 打开时 exHeroInfo nil 崩溃。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "tactic.GetHerosTactic",
                Ret: EncodeFleet(account.Fleet ?? PlayerAccountFactory.DefaultFleet()),
                Time: now)),

            // 剧情章节数据推送，填充首章关卡信息防止章节锁定。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "copy.GetCopy",
                Ret: EncodePlotCopyInfo(account.Character.PlotChapterId),
                Time: now)),

            // 海域章节数据推送（CopyType=2 SeaCopy）。海域页面节点依赖 GetCopyInfo() 里
            // 存在海域关卡，缺则 CheckChapterIsOpen/GetBattleModeChapter 全 false → 海域页空。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "copy.GetCopy",
                Ret: EncodeSeaCopyInfo(),
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
        return account ?? PlayerAccountFactory.CreateDefault(profileId, checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()));
    }

    /// <summary>获取最近一次抽卡创建的新英雄 ID 列表（供会话层只推送增量 hero 数据）。</summary>
    public IReadOnlyList<uint> GetLastBuildHeroIds() => _lastBuildHeroIds;

    private static byte[] EncodeCreateUser(PlayerAccount account)
    {
        var c = account.Character;
        return UserInfoCodec.Encode(new TUserInfo(c.Uid, c.Name, c.Level, c.Class));
    }

    private static byte[] EncodeGetUserInfo(PlayerAccount account)
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

    private static HeroGrid ToHeroGrid(Hero hero) =>
        new(hero.HeroId, hero.TemplateId, hero.Level, hero.Fashioning, hero.Exp, hero.CreateTime,
            hero.UpdateTime, hero.Affection, hero.MarryTime, hero.CurHp, hero.Mood, hero.MarryType,
            hero.EquipSlots);

    /// <summary>
    /// 由舰娘 TemplateId（config_ship_main 的 key）推导图鉴 IllustrateId
    /// （config_ship_handbook 的 key = ship_info_id）。数据规范 ship_main_id = ship_info_id * 10 + 1。
    /// </summary>
    private static int ToIllustrateId(int templateId) => (templateId - 1) / 10;

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

    /// <summary>config_shop 全部商店 id（104 个）。</summary>
    private static readonly int[] ShopIds =
    [
        1, 3, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
        26, 27, 29, 30, 101, 102, 104, 105, 106, 107, 110, 111, 200, 201, 202, 205,
        206, 207, 208, 300, 302, 303, 305, 306, 401, 901, 902, 903, 911, 912, 913,
        914, 915, 916, 917, 918, 919, 920, 924, 930, 931, 934, 935, 936, 940, 950,
        951, 954, 955, 956, 957, 958, 1001, 1002, 1003, 1004, 1006, 1010, 1011, 1012,
        1013, 1014, 1015, 1020, 1021, 1022, 1023, 1024, 1025, 1026, 1030, 1040, 1041,
        1042, 1043, 1044, 1051, 1052, 1071, 1072, 1073, 1074, 1201, 1202,
    ];

    /// <summary>
    /// 商店数据推送（shop.UpdateShopInfo）。让 Data.shopData.m_shopInfo 非空，否则
    /// ShopData.GetShopInfoById 里 m_shopInfo[shopId] 为 nil，红点系统（BrokenFashionShop
    /// → CheckShopNewFashion）在主页/商店页就崩溃。
    /// GM 商品按配置的 ShopId 分组放入对应商店（分页）。
    /// </summary>
    public byte[] BuildShopInfoPush(uint now)
    {
        var goodsByShop = _gmGoods.Goods
            .GroupBy(g => g.ShopId)
            .ToDictionary(g => g.Key, g => g.Select(x => new ShopGoodsData(x.GoodId, 0, 0)).ToList());
        var shopInfo = ShopIds.Select(id =>
            goodsByShop.TryGetValue(id, out var goods)
                ? new RetShopInfo(id, goods)
                : new RetShopInfo(id)).ToList();
        var push = new TResponse(Method: "shop.UpdateShopInfo",
            Ret: PlayerDataCodec.Encode(new RetShopsInfo(ShopInfo: shopInfo)),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    // GoodsType 常量（constants.lua）。ITEM=1, EQUIP=2, CURRENCY=5, EQUIP_ENHANCE_ITEM=6, FASHION=18。
    private const int GoodsTypeCurrency = 5;
    private const int GoodsTypeEquip = 2;
    private const int GoodsTypeFashion = 18;
    private uint _nextEquipId = 1;
    private uint _nextHeroId = 2; // 1 是默认秘书舰

    /// <summary>为 GM 命令生成下一个可用的舰娘实例 ID（调用前需确保已加载账号）。</summary>
    public uint NextHeroId() => _nextHeroId++;

    /// <summary>初始化 _nextEquipId 为账号中最大装备 ID + 1（避免服务重启后 ID 重复）。</summary>
    private void EnsureEquipIdFromAccount(PlayerAccount account)
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

    /// <summary>
    /// 处理 shop.BuyGoods：免费发放商品内容到对应存储（GM 功能，不扣货币）。
    /// - ITEM/EQUIP_ENHANCE_ITEM → 仓库（bag）
    /// - CURRENCY → 货币（UserInfo.Bath 温泉币）
    /// - FASHION → 时装解锁
    /// 返回 TBuyGoodsRet{Reward, GoodId, BuyNum}，并把更新后的账号落盘。
    /// </summary>
    private async Task<byte[]> BuildBuyGoodsRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return [];
        var (_, goodId, buyNum, _) = TMessageCodec.DecodeBuyGoodsArg(request.Args);
        if (buyNum <= 0)
            buyNum = 1;

        var account = await GetOrCreateAccountAsync(profileId, ct);
        var (newAccount, reward) = ApplyGoods(account, goodId, buyNum);
        if (reward.Type == 0)
            return [];
        await _repo.SaveAccountAsync(newAccount, ct);

        return TMessageCodec.EncodeBuyGoodsRet(reward, goodId, buyNum);
    }

    /// <summary>
    /// 处理 shop.QualityBuyGoods（多选/批量购买）：对每个 GoodId 免费发放。
    /// 返回 TQualityBuyGoodsRet{Reward, GoodIdList}。
    /// </summary>
    private async Task<byte[]> BuildQualityBuyGoodsRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null)
            return [];
        var (_, goodIds) = TMessageCodec.DecodeQualityBuyGoodsArg(request.Args);
        if (goodIds.Count == 0)
            return [];

        var account = await GetOrCreateAccountAsync(profileId, ct);
        var rewards = new List<CommonReward>();
        foreach (var goodId in goodIds)
        {
            var (newAccount, reward) = ApplyGoods(account, goodId, 1);
            if (reward.Type == 0)
                continue;
            account = newAccount;
            rewards.Add(reward);
        }
        await _repo.SaveAccountAsync(account, ct);

        return TMessageCodec.EncodeQualityBuyGoodsRet(rewards, goodIds);
    }

    /// <summary>发放单个 GM 商品，返回更新后的账号和奖励。无效商品返回 Type=0 的空奖励。</summary>
    private (PlayerAccount Account, CommonReward Reward) ApplyGoods(PlayerAccount account, int goodId, int buyNum)
    {
        if (!_gmGoodsMap.TryGetValue(goodId, out var goods))
            return (account, new CommonReward());
        if (buyNum <= 0)
            buyNum = 1;
        var totalNum = goods.Num * buyNum;

        if (goods.Type == GoodsTypeCurrency)
        {
            // 货币（CurrencyType → UserInfo 对应字段）
            account = AddCurrency(account, goods.ConfigId, totalNum);
        }
        else if (goods.Type == GoodsTypeFashion)
        {
            account = AddFashion(account, goods.ConfigId);
        }
        else if (goods.Type == GoodsTypeEquip)
        {
            // 装备：每个商品条目发放一件装备实例（EquipId 自增），存入装备仓库
            for (var i = 0; i < totalNum; i++)
                account = AddEquipItem(account, goods.ConfigId);
        }
        else
        {
            account = AddBagItem(account, goods.ConfigId, totalNum);
        }
        return (account, new CommonReward(goods.Type, goods.ConfigId, totalNum));
    }

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

    /// <summary>装备入库：创建一件装备实例（EquipId 自增），存入装备仓库。</summary>
    private PlayerAccount AddEquipItem(PlayerAccount account, int templateId)
    {
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        var items = equip.Items.ToList();
        var id = _nextEquipId++;
        items.Add(new EquipItem(EquipId: id, TemplateId: templateId));
        return account with { Equip = equip with { Items = items } };
    }

    private PlayerAccount AddFashion(PlayerAccount account, int fashionTid)
    {
        var fashion = account.Fashion ?? new PlayerFashion([]);
        var entries = fashion.Entries.ToList();
        var sfId = _fashionSfIdMap.GetValueOrDefault(fashionTid, fashionTid);
        var idx = entries.FindIndex(e => e.SfId == sfId);
        if (idx >= 0)
        {
            var tids = entries[idx].FashionTids.ToList();
            if (!tids.Contains(fashionTid))
                tids.Add(fashionTid);
            entries[idx] = entries[idx] with { FashionTids = tids };
        }
        else
        {
            entries.Add(new FashionEntry(sfId, [fashionTid]));
        }
        return account with { Fashion = fashion with { Entries = entries } };
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

/// <summary>从数据目录下的 gm-goods.json 加载 GM 商品配置（数据驱动，避免硬编码）。</summary>
internal static class GmGoodsConfigLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static GmGoodsConfig Load(string dataRoot)
    {
        var path = Path.Combine(dataRoot, "gm-goods.json");
        if (!File.Exists(path))
            return new GmGoodsConfig([], new Dictionary<int, int>());
        try
        {
            return JsonSerializer.Deserialize<GmGoodsConfig>(File.ReadAllText(path), JsonOptions)
                ?? new GmGoodsConfig([], new Dictionary<int, int>());
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[gm-goods] failed to parse {path}: {ex.Message}");
            return new GmGoodsConfig([], new Dictionary<int, int>());
        }
    }
}

/// <summary>从数据目录下的 gm-mails.json 加载 GM 邮件配置（数据驱动，避免硬编码）。</summary>
internal static class GmMailsConfigLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static GmMailsConfig Load(string dataRoot)
    {
        var path = Path.Combine(dataRoot, "gm-mails.json");
        if (!File.Exists(path))
            return new GmMailsConfig([]);
        try
        {
            return JsonSerializer.Deserialize<GmMailsConfig>(File.ReadAllText(path), JsonOptions)
                ?? new GmMailsConfig([]);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[gm-mails] failed to parse {path}: {ex.Message}");
            return new GmMailsConfig([]);
        }
    }
}

/// <summary>从数据目录下的 build-pools.json 加载抽卡池配置（数据驱动，不依赖客户端 config DB）。</summary>
internal static class GmBuildPoolLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static Dictionary<int, BuildShipPool> Load(string dataRoot)
    {
        var path = Path.Combine(dataRoot, "build-pools.json");
        if (!File.Exists(path))
            return [];
        try
        {
            var config = JsonSerializer.Deserialize<GmBuildPoolsConfig>(File.ReadAllText(path), JsonOptions);
            if (config?.Pools is null) return [];
            return config.Pools.ToDictionary(p => p.PoolId, p => new BuildShipPool(p.PoolId,
                p.Ships.Select(s => new BuildShipEntry(s.TemplateId, s.Weight)).ToList()));
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[build-pools] failed to parse {path}: {ex.Message}");
            return [];
        }
    }
}

/// <summary>build-pools.json 的顶层结构。</summary>
internal sealed record GmBuildPoolsConfig(IReadOnlyList<GmBuildPoolConfig> Pools);

/// <summary>单个卡池配置。</summary>
internal sealed record GmBuildPoolConfig(int PoolId, IReadOnlyList<GmBuildShipConfig> Ships);

/// <summary>单个卡池中的船娘条目。</summary>
internal sealed record GmBuildShipConfig(int TemplateId, int Weight);

/// <summary>从 config_ship_exp_item.db 和 config_ship_levelup.db 加载升级所需数据。</summary>
internal static class ShipLevelupLoader
{
    private const byte XorKey = 0x55;

    public static (Dictionary<int, int> ExpPerItem, Dictionary<int, int> ExpNeeded) Load(string dataRoot)
    {
        var configDir = Path.GetFullPath(Path.Combine(dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
        var expPerItem = new Dictionary<int, int>();
        var expNeeded = new Dictionary<int, int>();
        LoadExpItems(configDir, expPerItem);
        LoadLevelupExp(configDir, expNeeded);
        return (expPerItem, expNeeded);
    }

    private static void LoadExpItems(string configDir, Dictionary<int, int> result)
    {
        try
        {
            var path = Path.Combine(configDir, "config_ship_exp_item.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("exp", out var exp))
                    result[id] = exp.GetInt32();
            }
        }
        catch { }
    }

    private static void LoadLevelupExp(string configDir, Dictionary<int, int> result)
    {
        try
        {
            var path = Path.Combine(configDir, "config_ship_levelup.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("exp", out var exp))
                    result[id] = exp.GetInt32();
            }
        }
        catch { }
    }

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>加载海域索敌随机因子：config_copy_display.random_factor_sets
/// → config_random_factor_set.factor_groups → config_random_factor_group.factor。
/// 供 copy.GetRandomFactors 协议与 StartBase 的 RandomFactors 字段使用。</summary>
internal static class RandomFactorLoader
{
    private const byte XorKey = 0x55;

    public static Dictionary<int, List<int>> Load(string dataRoot)
    {
        var result = new Dictionary<int, List<int>>();
        try
        {
            var configDir = ChapterCopyLoader.FindConfigDir(dataRoot);
            var copyDisplay = new Dictionary<int, List<int>>();
            LoadTable(configDir, "config_copy_display.db", "random_factor_sets", copyDisplay);
            var factorSets = new Dictionary<int, List<int>>();
            LoadTable(configDir, "config_random_factor_set.db", "factor_groups", factorSets);
            var factorGroups = new Dictionary<int, List<int>>();
            LoadTable(configDir, "config_random_factor_group.db", "factor", factorGroups);
            foreach (var (copyId, setIds) in copyDisplay)
            {
                var factors = new List<int>();
                foreach (var setId in setIds)
                {
                    if (!factorSets.TryGetValue(setId, out var groupIds)) continue;
                    foreach (var groupId in groupIds)
                        if (factorGroups.TryGetValue(groupId, out var fs))
                            factors.AddRange(fs);
                }
                if (factors.Count > 0) result[copyId] = factors;
            }
        }
        catch { }
        return result;
    }

    private static void LoadTable(string configDir, string dbFile, string jsonProp, Dictionary<int, List<int>> result)
    {
        var path = Path.Combine(configDir, dbFile);
        if (!File.Exists(path)) return;
        using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
        c.Open();
        using var cmd = c.CreateCommand();
        cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
        using var r = cmd.ExecuteReader();
        while (r.Read())
        {
            var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
            if (id == 0) continue;
            var bytes = ReadColumnBytes(r, 1);
            var json = XorDecode(bytes);
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty(jsonProp, out var arr) || arr.ValueKind != JsonValueKind.Array) continue;
            var list = new List<int>();
            foreach (var item in arr.EnumerateArray())
                if (item.TryGetInt32(out var v)) list.Add(v);
            result[id] = list;
        }
    }

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_copy / config_fleet / config_ship_enemy 加载战斗配置。</summary>
internal static class CopyBattleLoader{
    private static readonly Dictionary<int, int> _copyFleetMap = new();       // copy_id → fleet_id
    private static readonly Dictionary<int, int> _copyConfigIdMap = new();    // copy_id → config_copy DBObject id
    private static readonly Dictionary<int, List<int>> _fleetEnemies = new(); // fleet_id → enemy ship ids
    private static readonly Dictionary<int, bool> _fleetHasAttached = new();  // fleet_id → 是否带 copy_attacheds
    private static readonly Dictionary<int, EnemyStat> _enemyStats = new();   // enemy id → stats
    private static bool _loaded;

    public sealed record EnemyStat(int Hp, int Attack, int Defense, int Level, int ShipInfoId,
        int Hit = 100, int Dodge = 0, int TorpedoAttack = 0, int TorpedoDefense = 0);

    public static void Load(string dataRoot)
    {
        if (_loaded) return;
        try
        {
            var configDir = Path.GetFullPath(Path.Combine(dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
            LoadCopyFleet(configDir);
            LoadFleetEnemies(configDir);
            LoadEnemyStats(configDir);
        }
        catch { }
        _loaded = true;
    }

    private static void LoadCopyFleet(string configDir)
    {
        try
        {
            var path = Path.Combine(configDir, "config_copy.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            var candidates = new Dictionary<int, (int fleetId, bool isDefault)>();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("copy_id", out var copyIdProp)) continue;
                if (!doc.RootElement.TryGetProperty("fleet_id", out var fleetIdProp)) continue;
                var copyId = copyIdProp.GetInt32();
                foreach (var item in fleetIdProp.EnumerateArray())
                {
                    var fleetId = item.GetInt32();
                    // 默认分支: blood_range_lower == -1 且 random_weight == 1000
                    var isDefault = doc.RootElement.TryGetProperty("blood_range_lower", out var brl) && brl.GetInt32() == -1
                        && doc.RootElement.TryGetProperty("random_weight", out var rw) && rw.GetInt32() == 1000;
                    if (!candidates.TryGetValue(copyId, out var cur) || (isDefault && !cur.isDefault))
                        candidates[copyId] = (fleetId, isDefault);
                    // 记录默认分支对应的 config_copy DBObject id（客户端用该 id 查 config_copy）
                    if (isDefault) _copyConfigIdMap[copyId] = id;
                }
            }
            foreach (var (copyId, val) in candidates)
                _copyFleetMap[copyId] = val.fleetId;
        }
        catch { }
    }

    private static void LoadFleetEnemies(string configDir)
    {
        try
        {
            var path = Path.Combine(configDir, "config_fleet.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("copy_enemys", out var enemies)) continue;
                var list = new List<int>();
                foreach (var item in enemies.EnumerateArray())
                    list.Add(item.GetInt32());
                _fleetEnemies[id] = list;
                // copy_attacheds 结构为 [[attachedFleetId, formation], ...]
                if (doc.RootElement.TryGetProperty("copy_attacheds", out var attached)
                    && attached.ValueKind == JsonValueKind.Array)
                {
                    var cnt = 0;
                    foreach (var item in attached.EnumerateArray())
                    {
                        if (item.ValueKind == JsonValueKind.Array && item.GetArrayLength() > 0
                            && item[0].ValueKind == JsonValueKind.Number && item[0].GetInt32() != 0)
                            cnt++;
                    }
                    _fleetHasAttached[id] = cnt > 0;
                }
            }
        }
        catch { }
    }

    private static void LoadEnemyStats(string configDir)
    {
        try
        {
            var path = Path.Combine(configDir, "config_ship_enemy.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                var bytes = ReadColumnBytes(r, 1);
                var json = XorDecode(bytes);
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("hp", out var hpProp)) continue;
                _enemyStats[id] = new EnemyStat(
                    hpProp.GetInt32(),
                    doc.RootElement.TryGetProperty("attack", out var atk) ? atk.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("defense", out var def) ? def.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("level", out var lv) ? lv.GetInt32() : 1,
                    doc.RootElement.TryGetProperty("ship_info_id", out var sid) ? sid.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("hit", out var hit) ? hit.GetInt32() : 100,
                    doc.RootElement.TryGetProperty("dodge", out var dodge) ? dodge.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("torpedo_attack", out var ta) ? ta.GetInt32() : 0,
                    doc.RootElement.TryGetProperty("torpedo_defense", out var td) ? td.GetInt32() : 0);
            }
        }
        catch { }
    }

    public static int GetFleetId(int copyId)
        => _copyFleetMap.TryGetValue(copyId, out var id) ? id : copyId;

    public static bool HasCopyAttacheds(int fleetId)
        => _fleetHasAttached.TryGetValue(fleetId, out var has) && has;

    /// <summary>敌人舰队锚点：直接返回 config_copy 查到的真实舰队 id。
    /// 不再因 copy_attacheds 为空回退到临时测试舰队 907（此前误判，导致所有关卡
    /// 都弹 907 的 9999999HP 伤害测试敌舰 71）。若客户端 PVEStartData 因此 NRE，再单独处理。</summary>
    public static int GetFleetIdWithAttached(int copyId)
        => GetFleetId(copyId);

    public static int GetConfigId(int copyId)
        => _copyConfigIdMap.TryGetValue(copyId, out var id) ? id : copyId;

    public static List<int> GetEnemyIds(int fleetId)
        => _fleetEnemies.TryGetValue(fleetId, out var list) ? list : [];

    public static EnemyStat? GetEnemyStat(int enemyId)
        => _enemyStats.TryGetValue(enemyId, out var stat) ? stat : null;

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        const byte XorKey = 0x55;
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_ship_main 加载玩家船基础属性（key = sm_id = 船的 TemplateId）。</summary>
internal static class ShipMainLoader
{
    private static readonly Dictionary<int, ConfigShipMain> _ships = new();
    private static bool _loaded;

    public static void Load(string dataRoot)
    {
        if (_loaded) return;
        try
        {
            var configDir = Path.GetFullPath(Path.Combine(
                dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
            var path = Path.Combine(configDir, "config_ship_main.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                try
                {
                    var cfg = JsonSerializer.Deserialize<ConfigShipMain>(XorDecode(ReadColumnBytes(r, 1)));
                    if (cfg is null) continue;
                    _ships[id] = cfg;
                    if (cfg.SmId != 0)
                        _ships[checked((int)cfg.SmId)] = cfg;
                }
                catch
                {
                    // 个别坏行（如 id=nill 的无效 JSON）跳过，不影响整表加载。
                }
            }
        }
        catch { }
        _loaded = true;
    }

    public static ConfigShipMain? Get(int templateId)
        => _ships.TryGetValue(templateId, out var cfg) ? cfg : null;

    /// <summary>属性等级成长：base + levelup × (level - 1)。</summary>
    public static long Leveled(long baseValue, long levelup, int level)
        => baseValue + levelup * Math.Max(0, level - 1);

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        const byte XorKey = 0x55;
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_assist_ship_info 加载临时/支援舰船（key = assist_ship_info id = HeroId）。</summary>
internal static class AssistShipLoader
{
    private static readonly Dictionary<int, ConfigAssistShipInfo> _ships = new();
    private static bool _loaded;

    public static void Load(string dataRoot)
    {
        if (_loaded) return;
        try
        {
            var configDir = Path.GetFullPath(Path.Combine(
                dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
            var path = Path.Combine(configDir, "config_assist_ship_info.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                try
                {
                    var cfg = JsonSerializer.Deserialize<ConfigAssistShipInfo>(XorDecode(ReadColumnBytes(r, 1)));
                    if (cfg is null) continue;
                    _ships[id] = cfg;
                }
                catch { }
            }
        }
        catch { }
        _loaded = true;
    }

    public static ConfigAssistShipInfo? Get(int id)
        => _ships.TryGetValue(id, out var cfg) ? cfg : null;

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        const byte XorKey = 0x55;
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_equip 加载装备模板（key = e_id），用于构造出战船只的装备数据。</summary>
internal static class EquipLoader
{
    private static readonly Dictionary<int, ConfigEquip> _equips = new();
    private static bool _loaded;

    public static void Load(string dataRoot)
    {
        if (_loaded) return;
        try
        {
            var configDir = Path.GetFullPath(Path.Combine(
                dataRoot, "..", "..", "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config"));
            var path = Path.Combine(configDir, "config_equip.db");
            if (!File.Exists(path)) return;
            using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
            c.Open();
            using var cmd = c.CreateCommand();
            cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                if (id == 0) continue;
                try
                {
                    var cfg = JsonSerializer.Deserialize<ConfigEquip>(XorDecode(ReadColumnBytes(r, 1)));
                    if (cfg is null) continue;
                    _equips[id] = cfg;
                }
                catch { }
            }
        }
        catch { }
        _loaded = true;
    }

    public static ConfigEquip? Get(int id)
        => _equips.TryGetValue(id, out var cfg) ? cfg : null;

    private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return [];
        var value = reader.GetValue(ordinal);
        return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
    }

    private static string XorDecode(byte[] source)
    {
        const byte XorKey = 0x55;
        var result = new byte[source.Length];
        for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
        return Encoding.UTF8.GetString(result);
    }
}

/// <summary>从 config_chapter 加载章节 → 关卡列表映射。</summary>
 internal static class ChapterCopyLoader
 {
     private static readonly Dictionary<int, List<int>> _chapterCopies = new();
     private static readonly Dictionary<int, int> _firstCopyMap = new();
     private static readonly Dictionary<int, List<int>> _seaChapterCopies = new();
     private static int _seaFirstChapterId = 0;
     private static int _seaFirstCopyId = 0;
     private static bool _loaded;

     public static void Load(string dataRoot)
     {
         if (_loaded) return;
         try
         {
             var configDir = FindConfigDir(dataRoot);
             var path = Path.Combine(configDir, "config_chapter.db");
             if (!File.Exists(path)) return;
             using var c = new SqliteConnection($"Data Source={path};Mode=ReadOnly");
             c.Open();
             using var cmd = c.CreateCommand();
             cmd.CommandText = "SELECT id, jsonbytes FROM DBObject";
             using var r = cmd.ExecuteReader();
             while (r.Read())
             {
                 var id = int.TryParse(r.GetString(0), out var parsed) ? parsed : 0;
                 if (id == 0) continue;
                 var bytes = ReadColumnBytes(r, 1);
                 var json = XorDecode(bytes);
                 using var doc = JsonDocument.Parse(json);
                 if (!doc.RootElement.TryGetProperty("level_list", out var levelList)) continue;
                 if (!doc.RootElement.TryGetProperty("class_type", out var classType)) continue;
                 var copies = new List<int>();
                 foreach (var item in levelList.EnumerateArray())
                     copies.Add(item.GetInt32());
                 if (copies.Count == 0) continue;
                 var ct = classType.GetInt32();
                 if (ct == 1) // PlotCopy
                 {
                     _chapterCopies[id] = copies;
                     _firstCopyMap[id] = copies[0];
                 }
                 else if (ct == 2) // SeaCopy
                 {
                     _seaChapterCopies[id] = copies;
                     if (_seaFirstChapterId == 0 || id < _seaFirstChapterId)
                     {
                         _seaFirstChapterId = id;
                         _seaFirstCopyId = copies[0];
                     }
                 }
             }
         }
         catch { }
         _loaded = true;
     }

     public static List<int> GetCopyIds(int chapterId)
         => _chapterCopies.TryGetValue(chapterId, out var list) ? list : [];

     public static int GetFirstCopyId(int chapterId)
         => _firstCopyMap.TryGetValue(chapterId, out var id) ? id : 0;

     public static List<int> GetAllChapterIds()
         => [.. _chapterCopies.Keys.OrderBy(x => x)];

     /// <summary>海域（SeaCopy, class_type=2）全部章节的关卡，按章节 id 升序。</summary>
     public static List<int> GetSeaLevels()
     {
         var result = new List<int>();
         foreach (var chapterId in _seaChapterCopies.Keys.OrderBy(x => x))
             result.AddRange(_seaChapterCopies[chapterId]);
         return result;
     }

     /// <summary>海域第 1 章第一关（用作 MaxCopyId，使 _getFarestId 落在第 1 章）。</summary>
     public static int GetSeaFirstCopyId() => _seaFirstCopyId;

     /// <summary>从 dataRoot 向上逐级查找游戏配置目录
     /// （blueoath/blueoath/blueoath_Data/StreamingAssets/config）。适配不同 --data 深度
     /// （如 runtime/jp 下 dataRoot/../.. 即项目根，bin/Debug/net8.0/data 需向上 6 级）。</summary>
     internal static string FindConfigDir(string dataRoot)
     {
         var dir = new DirectoryInfo(dataRoot);
         for (var i = 0; i < 8 && dir != null; i++, dir = dir.Parent)
         {
             var cand = Path.Combine(dir.FullName, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "config");
             if (Directory.Exists(cand)) return cand;
         }
         return dataRoot;
     }

     private static byte[] ReadColumnBytes(SqliteDataReader reader, int ordinal)
     {
         if (reader.IsDBNull(ordinal)) return [];
         var value = reader.GetValue(ordinal);
         return value switch { byte[] b => b, string s => Encoding.UTF8.GetBytes(s), _ => [] };
     }

     private static string XorDecode(byte[] source)
     {
         const byte XorKey = 0x55;
         var result = new byte[source.Length];
         for (var i = 0; i < source.Length; i++) result[i] = (byte)(source[i] ^ XorKey);
         return Encoding.UTF8.GetString(result);
     }
 }
