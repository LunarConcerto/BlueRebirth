using System.Text;
using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
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
        _fileLogger.LogInformation("game-login C2S method={Method} callback={Callback} argsLen={ArgsLen}",
            request.Method, request.CallbackHandler, request.Args?.Length ?? 0);
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
                _ => []
            };
        }
        var response = new TResponse(Method: request.Method, Ret: ret,
            CallbackHandler: request.CallbackHandler, Time: checked((uint)now),
            Token: request.Token, Seq: 0, IsResponse: 1);
        return (GameOperationCodes.S2C, TMessageCodec.EncodeResponse(response));
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
