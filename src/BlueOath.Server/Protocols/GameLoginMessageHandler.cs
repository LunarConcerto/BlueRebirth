using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Storage;
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

    public GameLoginMessageHandler(SqliteGameRepository repo, ServerOptions options, ILoggerFactory loggerFactory)
    {
        _repo = repo;
        _logger = loggerFactory.CreateLogger<GameLoginMessageHandler>();
        _fileLogger = loggerFactory.CreateLogger(Infrastructure.GameLoginFileLoggerProvider.Category);
        _gmGoods = GmGoodsConfigLoader.Load(options.DataRoot);
        _gmGoodsMap = _gmGoods.Goods.ToDictionary(g => g.GoodId, g => (g.Type, g.ItemId, g.Num));
        _fashionSfIdMap = _gmGoods.FashionSfId.ToDictionary(kv => kv.Key, kv => kv.Value);
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
        ];
    }

    /// <summary>加载账号；不存在时按默认工厂创建并落盘（兼容旧存档）。</summary>
    private async Task<PlayerAccount> GetOrCreateAccountAsync(string profileId, CancellationToken ct)
    {
        var account = await _repo.LoadAccountAsync(profileId, ct);
        if (account is not null)
            return account;
        var created = PlayerAccountFactory.CreateDefault(profileId, checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()));
        await _repo.SaveAccountAsync(created, ct);
        return created;
    }

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
        return TMessageCodec.EncodeRetGetUserInfo(c.Uid, c.Name, c.Level, c.Class, c.SecretaryId,
            createTime, c.Bath, c.Gold, c.Diamond, c.Supply);
    }

    private static HeroGrid ToHeroGrid(Hero hero) =>
        new(hero.HeroId, hero.TemplateId, hero.Level, hero.Fashioning, hero.Exp, hero.CreateTime,
            hero.UpdateTime, hero.Affection, hero.MarryTime, hero.CurHp, hero.Mood, hero.MarryType);

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

    // GoodsType 常量（constants.lua）。ITEM=1, CURRENCY=5, EQUIP_ENHANCE_ITEM=6, FASHION=18。
    private const int GoodsTypeCurrency = 5;
    private const int GoodsTypeFashion = 18;

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
        else
        {
            account = AddBagItem(account, goods.ConfigId, totalNum);
        }
        return (account, new CommonReward(goods.Type, goods.ConfigId, totalNum));
    }

    /// <summary>货币发放（CurrencyType → UserInfo 字段）。1=金币,2=钻石,5=体力,13=温泉币。</summary>
    private static PlayerAccount AddCurrency(PlayerAccount account, int currencyType, int num)
    {
        var c = account.Character;
        c = currencyType switch
        {
            1 => c with { Gold = c.Gold + num },
            2 => c with { Diamond = c.Diamond + num },
            5 => c with { Supply = c.Supply + num },
            13 => c with { Bath = c.Bath + num },
            _ => c with { Gold = c.Gold + num },
        };
        return account with { Character = c };
    }

    private static PlayerAccount AddBagItem(PlayerAccount account, int templateId, int num)
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

    /// <summary>购买后的数据推送（货币 + 仓库 + 时装），供会话在 shop.BuyGoods 应答后发出。</summary>
    public async Task<IReadOnlyList<byte[]>> BuildPostBuyPushesAsync(string profileId, uint now, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        return
        [
            await BuildUpdateUserInfoPushAsync(profileId, now, ct),
            BuildBagPush(account, now),
            BuildFashionPush(account, now),
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
