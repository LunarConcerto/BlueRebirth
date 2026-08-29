using System.Collections.Concurrent;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;
using BlueOath.Storage;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 处理游戏登录应用层（11 字节头 + protobuf），该层分别承载于 TCP 的 NetSocket 帧内
/// 与 UDP 的 KCP 流内。由两种登录传输共用，避免重复实现。
/// 角色（<see cref="PlayerCharacter"/>）与船坞（<see cref="HeroDock"/>）数据不再硬编码，
/// 而是从存档数据库读取。
/// 编解码职责已拆出到 <see cref="ProtocolEncoder"/> / <see cref="ProtocolDecoder"/>；
/// 本类聚焦共享服务能力：账号加载/落盘、配置、跨域推送构建与领域实体操作。
/// </summary>
internal sealed class GameServices
{
    private const int DefaultAffectionGiftCount = 999;
    private const int OathShopCurrencyId = 17553;
    private const int DefaultOathShopCurrencyCount = 99_999_999;
    private const int DefaultConstructionItemCount = 99_999;
    private const int DefaultBuildingMaterialCount = 99_999;
    private readonly SqliteGameRepository _repo;
    private readonly ILogger _logger;
    private readonly ILogger _fileLogger;
    private readonly string _defaultProfileId;
    private readonly string _defaultProfileName;
    private readonly GmGoodsConfig _gmGoods;
    private readonly Dictionary<int, GmGoodConfig> _gmGoodsMap;
    private readonly Dictionary<int, int> _fashionSfIdMap;
    private readonly IReadOnlyList<GmMailConfig> _gmMails;
    private readonly Dictionary<int, ConfigExtractShip> _extractShips;
    private readonly Dictionary<int, ConfigDropItem> _dropItems;
    private readonly Dictionary<int, ConfigItemInfo> _itemInfos;
    private readonly Dictionary<int, ConfigSpecialdraw> _specialDraws;
    private readonly Dictionary<int, ConfigShipInfo> _shipInfos;
    private readonly Dictionary<int, int> _expPerItem;
    private readonly Dictionary<int, int> _expNeeded;
    private readonly Dictionary<int, List<RandomFactorEntry>> _copyRandomFactors;
    private readonly Random _rng = new();
    private readonly BuildPoolsConfig _buildPoolsConfig = BuildPoolsConfigLoader.Load();

    public GameServices(SqliteGameRepository repo, ServerOptions options, ILoggerFactory loggerFactory)
    {
        _repo = repo;
        _logger = loggerFactory.CreateLogger<GameServices>();
        _fileLogger = loggerFactory.CreateLogger(Infrastructure.GameLoginFileLoggerProvider.Category);
        _defaultProfileId = options.ProfileId;
        _defaultProfileName = options.ProfileName;
        // 游戏客户端配置目录直接来自启动参数 --client-path（不再从 dataRoot 向上逐级查找）。
        string configDir = ConfigDbLoader.BuildConfigDir(options.ClientPath);
        string clientId = options.Profile.Region == ClientRegion.Japan
            ? $"jp-{options.Profile.ClientVersion}"
            : $"cn-{options.Profile.ClientVersion}";
        EquipmentModCatalog equipmentMods = EquipmentModLoader.Load(
            EquipmentModLoader.ResolveModsRoot(options.ClientPath), clientId);
        FashionConfigLoader.Load(configDir);
        var gmGoods = GmGoodsConfigLoader.Load(options.DataRoot);
        FashionShopCatalog fashionShopCatalog = FashionShopGoodsLoader.Load(configDir);
        _gmGoods = GmGoodsConfigLoader.Load(options.DataRoot);
        _gmGoodsMap = _gmGoods.Goods.ToDictionary(g => g.GoodId);
        _fashionSfIdMap = BuildFashionSfIdMap();
        _gmMails = GmMailsConfigLoader.Load(options.DataRoot).Mails;
        (_extractShips, _dropItems, _specialDraws, _shipInfos) = BuildShipExtractLoader.Load(configDir);
        ConstructionConfigLoader.Load(configDir);
        BuildingConfigLoader.Load(configDir);
        _itemInfos = ItemInfoLoader.Load(configDir);
        (_expPerItem, _expNeeded) = ShipLevelupLoader.Load(configDir);
        _copyRandomFactors = RandomFactorLoader.Load(configDir);
        ChapterCopyLoader.Load(configDir);
        CopyBattleLoader.Load(configDir);
        MissionChainLoader.Load(configDir);
        ShipMainLoader.Load(configDir);
        AssistShipLoader.Load(configDir);
        EquipLoader.Load(configDir, equipmentMods.Equipment);
        AffectionItemLoader.Load(configDir);
        ShipHandbookLoader.Load(configDir);
        PlotTriggerLoader.Load(configDir);
        CharacterStoryLoader.Load(configDir);
        RemouldConfigLoader.Load(configDir);
    }

    /// <summary>文件日志（game-login.log）供各模块记录帧级诊断。</summary>
    internal ILogger FileLogger => _fileLogger;

    /// <summary>GM 邮件配置（供 MailModule 等使用）。</summary>
    internal IReadOnlyList<GmMailConfig> GmMails => _gmMails;

    /// <summary>GM 商品映射：GoodId → GmGoodConfig。</summary>
    internal IReadOnlyDictionary<int, GmGoodConfig> GmGoodsMap => _gmGoodsMap;

    /// <summary>时装 FashionTid → SfId 映射。</summary>
    internal IReadOnlyDictionary<int, int> FashionSfIdMap => _fashionSfIdMap;

    /// <summary>持久化账号（供各模块修改后落盘）。同时更新内存缓存。</summary>
    internal async Task SaveAccountAsync(PlayerAccount account, CancellationToken ct = default)
    {
        _accountCache[account.ProfileId] = account;
        await _repo.SaveAccountAsync(account, ct);
    }

    /// <summary>抽卡模板配置（供 BuildShipService）。</summary>
    internal IReadOnlyDictionary<int, ConfigExtractShip> ExtractShips => _extractShips;

    /// <summary>掉落物品配置（供 BuildShipService）。</summary>
    internal IReadOnlyDictionary<int, ConfigDropItem> DropItems => _dropItems;

    /// <summary>道具配置（宝箱道具通过 DropId 指向 config_drop_item）。</summary>
    internal IReadOnlyDictionary<int, ConfigItemInfo> ItemInfos => _itemInfos;

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
    internal ConfigEquipEnhanceItem? GetEquipEnhanceItem(int id) => EquipLoader.GetEnhanceItem(id);
    internal ConfigEquipEnhanceLevel? GetEquipEnhanceLevel(int level) => EquipLoader.GetEnhanceLevel(level);
    internal ConfigEquipEnhanceLevelUr? GetEquipEnhanceLevelUr(int level) => EquipLoader.GetEnhanceLevelUr(level);
    internal ConfigEquipLevelbreakItem? GetEquipLevelbreakItem(int type) => EquipLoader.GetLevelbreakItem(type);
    internal ConfigEquipEnhanceRenovate? GetEquipRenovateLevel(int level) => EquipLoader.GetRenovateLevel(level);
    internal ConfigEquip? GetEquipConfig(int id) => EquipLoader.Get(id);
    internal ConfigAffectionItem? GetAffectionItem(int id) => AffectionItemLoader.Get(id);

    /// <summary>
    /// 处理登录操作码：解码 <c>TArgLogin</c>，按服务器启动时选定的账号创建/加载本地档案，
    /// 返回 <c>TRetLogin</c> 编码结果与 profileId（供会话后续关联账号）。
    /// </summary>
    public async Task<LoginPayload> BuildLoginPayloadAsync(byte[] payload, CancellationToken ct)
    {
        _ = GameLoginCodec.DecodeLogin(payload);
        var profileId = _defaultProfileId;
        _logger.LogInformation("game-login login pid={ProfileId}", profileId);
        if (await _repo.LoadAsync(profileId, ct) is null)
            await _repo.CreateAsync(profileId, _defaultProfileName, ct);
        var response = new TRetLogin("0", profileId);
        return new LoginPayload(GameOperationCodes.Login, GameLoginCodec.Encode(response), profileId);
    }

    /// <summary>返回服务器启动时选定的账号，避免客户端缓存的旧 Pid 串档。</summary>
    public string ResolveLoginProfileId(TRequest request)
    {
        _ = request;
        return _defaultProfileId;
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
    /// 其中船坞和传统建造队列来自存档实体，其余仍为最小/空占位。
    /// </summary>
    public async Task<IReadOnlyList<byte[]>> BuildSyncPushesAsync(string profileId, uint now, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        PlayerAccount refreshed = ConstructionService.RefreshQueue(account, now);
        if (!ReferenceEquals(refreshed, account))
        {
            account = refreshed;
            await SaveAccountAsync(account, ct);
        }
        var heroes = account.Dock.Heroes.Select(ToHeroGrid).ToList();
        var illustrateBehaviour = (account.Illustrate?.Entries ?? [])
            .ToDictionary(e => e.IllustrateId, e => e.BehaviourList);

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

            // 用户信息推送：在 LoginOk 之前设置 Level，使 _RecordCanOpenModuleInfo
            // 能正确判断模块打开条件，避免 tabNoOpenModule 收集全部模块后弹出 ModuleOpenPage。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "user.GetUserInfo",
                Ret: EncodeGetUserInfo(account),
                Time: now)),

            TMessageCodec.EncodeResponse(new TResponse(
                Method: "build.BuildsInfo",
                Ret: ConstructionService.EncodeInfo(account.Construction),
                Time: now)),

            TMessageCodec.EncodeResponse(new TResponse(
                Method: "bathroom.BathroomInfo",
                Ret: PlayerDataCodec.Encode(ToBathroomInfo(account.Bath)),
                Time: now)),

            // 退役/强化候选筛选会直接遍历 StudyData.ArrProgress，且不会处理尚未
            // 初始化的 nil。字段 1 是可用训练位数量；空的 repeated ArrProgress
            // 会由客户端 protobuf 默认成空表。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "study.GetStudyInfo",
                Ret: new byte[] { 0x08, 0x02 },
                Time: now)),

            // 船坞数据来自存档实体。秘书舰 HeroId 必须与 Character.SecretaryId 一致。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "hero.UpdateHeroBagData",
                Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                Time: now)),

            // 建筑数据推送，包含 Office 建筑（BuildingInfos）防止
            // GetOffice() 返回 nil 导致 GetMaxWorkerStrength/GetCurStrengthReal 崩溃。
            BuildingService.BuildInfoPush(account.Building, now),

            // 编队数据推送，填充玩家编队信息防止 fleetpage 打开时 exHeroInfo nil 崩溃。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "tactic.GetHerosTactic",
                Ret: ProtocolEncoder.EncodeFleet(account.Fleet ?? PlayerAccountFactory.DefaultFleet()),
                Time: now)),

            // 剧情章节数据推送，填充首章关卡信息防止章节锁定。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "copy.GetCopy",
                Ret: ProtocolEncoder.EncodePlotCopyInfo(int.MaxValue, account.CopyProgress),
                Time: now)),

            // 海域章节数据推送（CopyType=2 SeaCopy）。海域页面节点依赖 GetCopyInfo() 里
            // 存在海域关卡，缺则 CheckChapterIsOpen/GetBattleModeChapter 全 false → 海域页空。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "copy.GetCopy",
                Ret: ProtocolEncoder.EncodeSeaCopyInfo(account.SeaProgress),
                Time: now)),

            // アンブラ進軍（MubarCopy, CopyType=33）。入口是客户端长期活动配置，
            // 不依赖服务器活动列表；不推送会导致 MubarCopyPage 以空章节列表启动。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "copy.GetCopy",
                Ret: ProtocolEncoder.EncodeMubarCopyInfo(),
                Time: now)),

            // 图鉴数据推送。IllustrateInfoRet.IllustrateList 是玩家已解锁的图鉴条目
            // （IllustrateId = config_ship_handbook 的 key = ship_info_id）；未列出的条目
            // 由 IllustrateData:UpdateHero 从 config_ship_handbook 生成 LOCK 状态。
            // IllustrateList/IllustrateEquipList 两个 repeated 字段必须非 nil（否则 ipairs(nil) 崩溃）。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "illustrate.IllustrateInfo",
                Ret: PlayerDataCodec.Encode(new IllustrateInfoRet(
                    IllustrateList: account.Dock.Heroes
                        .Select(h =>
                        {
                            int siId = ToIllustrateId(h.TemplateId);
                            illustrateBehaviour.TryGetValue(siId, out var behaviour);
                            return new IllustrateInfo(siId, now, 0, false, behaviour, 0);
                        })
                        .ToList(),
                    IllustrateEquipList: [new IllustrateEquipInfo()],
                    HeroMemoryList: CharacterStoryLoader.AllMemories)),
                Time: now)),

            // 活动剧情回顾进度。Index 设为章节节点总数，使所有往期活动剧情均可重播。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "illustrate.Memory",
                Ret: PlayerDataCodec.Encode(new StoryMemoryList(ChapterCopyLoader.AllChapterMemories)),
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

            // 卡池信息推送（buildship.BuildShipInfo）：为配置中启用的卡池设置未来的 CloseTime，
            // 客户端 CheckActIsOpen 据此判定这些限时卡池为开启状态。同时下发抽数/已领奖励状态。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "buildship.BuildShipInfo",
                Ret: ProtocolEncoder.EncodeBuildShipInfo(_buildPoolsConfig.EnabledPoolIds, now, account.BuildState),
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
                Ret: ProtocolEncoder.BuildHeadUnlockedListPush(account),
                Time: now)),

            // 邮件系统触发：payback.newPayback 推送会让 EmailService._TagUpdataMail
            // 置 updataTog=true，玩家打开邮件页面时才 SendGetMailList 拉取邮件列表。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "payback.newPayback",
                Time: now)),
        ];
    }

    /// <summary>加载账号；不存在时按默认工厂创建并落盘。优先从内存缓存读取。</summary>
    internal async Task<PlayerAccount> GetOrCreateAccountAsync(string profileId, CancellationToken ct)
    {
        if (_accountCache.TryGetValue(profileId, out var cached))
            return cached;

        var account = await _repo.LoadAccountAsync(profileId, ct);
        if (account is not null)
        {
            EnsureEquipIdFromAccount(account);
            account = EnsureHeroPSkills(account);
            account = EnsureAllFashion(account);
            PlayerAccount normalized = NormalizeAffection(account);
            bool affectionMigrated = !ReferenceEquals(normalized, account);
            account = normalized;
            account = EnsureAffectionGifts(account);
            account = EnsureOathShopCurrency(account);
            PlayerAccount constructionReady = EnsureConstructionItems(account);
            bool constructionMigrated = !ReferenceEquals(constructionReady, account);
            account = constructionReady;
            PlayerAccount buildingReady = EnsureBuilding(account);
            bool buildingMigrated = !ReferenceEquals(buildingReady, account);
            account = buildingReady;
            PlayerAccount buildingMaterialsReady = EnsureBuildingMaterials(account);
            bool buildingMaterialsMigrated = !ReferenceEquals(buildingMaterialsReady, account);
            account = buildingMaterialsReady;
            PlayerAccount profileNameReady = SynchronizeProfileDisplayName(account, GetProfileDisplayName(profileId));
            bool profileNameMigrated = !ReferenceEquals(profileNameReady, account);
            account = profileNameReady;
            if (account.Character.Level < 80)
                account = account with { Character = account.Character with { Level = 80 } };
            _accountCache[profileId] = account;
            if (affectionMigrated || constructionMigrated || buildingMigrated || buildingMaterialsMigrated ||
                profileNameMigrated)
                await _repo.SaveAccountAsync(account, ct);
            return account;
        }
        var created = PlayerAccountFactory.CreateDefault(profileId,
            checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()), GetProfileDisplayName(profileId));
        created = EnsureHeroPSkills(created);
        created = EnsureAllFashion(created);
        created = NormalizeAffection(created);
        created = EnsureAffectionGifts(created);
        created = EnsureOathShopCurrency(created);
        created = EnsureConstructionItems(created);
        created = EnsureBuildingMaterials(created);
        _accountCache[profileId] = created;
        await _repo.SaveAccountAsync(created, ct);
        return created;
    }

    /// <summary>仅加载账号（不创建），供会话层在推送时读取最新数据。优先从内存缓存读取。</summary>
    public async Task<PlayerAccount> GetAccountAsync(string profileId, CancellationToken ct)
    {
        if (_accountCache.TryGetValue(profileId, out var cached))
            return cached;

        var account = await _repo.LoadAccountAsync(profileId, ct);
        if (account is null)
        {
            account = PlayerAccountFactory.CreateDefault(profileId,
                checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()), GetProfileDisplayName(profileId));
            account = EnsureHeroPSkills(account);
            account = EnsureAllFashion(account);
            account = NormalizeAffection(account);
            account = EnsureAffectionGifts(account);
            account = EnsureOathShopCurrency(account);
            account = EnsureConstructionItems(account);
            return EnsureBuildingMaterials(account);
        }
        account = EnsureHeroPSkills(account);
        account = EnsureAllFashion(account);
        PlayerAccount normalized = NormalizeAffection(account);
        bool affectionMigrated = !ReferenceEquals(normalized, account);
        account = normalized;
        account = EnsureAffectionGifts(account);
        account = EnsureOathShopCurrency(account);
        account = EnsureConstructionItems(account);
        PlayerAccount buildingReady = EnsureBuilding(account);
        bool buildingMigrated = !ReferenceEquals(buildingReady, account);
        account = buildingReady;
        PlayerAccount buildingMaterialsReady = EnsureBuildingMaterials(account);
        bool buildingMaterialsMigrated = !ReferenceEquals(buildingMaterialsReady, account);
        account = buildingMaterialsReady;
        PlayerAccount profileNameReady = SynchronizeProfileDisplayName(account, GetProfileDisplayName(profileId));
        bool profileNameMigrated = !ReferenceEquals(profileNameReady, account);
        account = profileNameReady;
        PlayerAccount bagReady = CleanupPollutedBagShips(account);
        bool bagMigrated = !ReferenceEquals(bagReady, account);
        account = bagReady;
        if (account.Character.Level < 80)
            account = account with { Character = account.Character with { Level = 80 } };
        _accountCache[profileId] = account;
        if (affectionMigrated || buildingMigrated || buildingMaterialsMigrated || profileNameMigrated || bagMigrated)
            await _repo.SaveAccountAsync(account, ct);
        return account;
    }

    /// <summary>迁移修复：清除误入仓库的舰娘模板。早期商店购买舰娘错误地走 AddBagItem
    /// 写入背包，客户端 baglogic 按 config_table_index 解析模板时崩溃。舰娘模板
    /// （config_ship_main）不属于背包，应移除以恢复存档。</summary>
    private static PlayerAccount CleanupPollutedBagShips(PlayerAccount account)
    {
        var bag = account.Bag;
        if (bag is null || bag.Items.Count == 0) return account;
        List<BagItem> cleaned = bag.Items
            .Where(item => ShipMainLoader.Get(item.TemplateId) is null)
            .ToList();
        if (cleaned.Count == bag.Items.Count) return account;
        return account with { Bag = bag with { Items = cleaned } };
    }

    private string GetProfileDisplayName(string profileId) =>
        profileId.Equals(_defaultProfileId, StringComparison.Ordinal) ? _defaultProfileName : profileId;

    /// <summary>
    /// 同步启动器账号名。只有角色名仍等于上次由启动器管理的名称时才跟随更新，
    /// 因此玩家在游戏内主动设置的昵称不会被覆盖。
    /// </summary>
    internal static PlayerAccount SynchronizeProfileDisplayName(PlayerAccount account, string displayName)
    {
        string normalized = string.IsNullOrWhiteSpace(displayName) ? account.ProfileId : displayName.Trim();
        if (account.ProfileDisplayName == normalized)
            return account;

        bool isManagedName = account.ProfileDisplayName is null
            ? account.Character.Name == account.ProfileId
            : account.Character.Name == account.ProfileDisplayName;
        PlayerCharacter character = isManagedName
            ? account.Character with { Name = normalized }
            : account.Character;
        return account with { Character = character, ProfileDisplayName = normalized };
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
            hero.EquipSlots, hero.Name, hero.ChangeNameTime, hero.Lock, hero.Advance, hero.AdvLv, hero.PSkills,
            hero.RemouldEffects, hero.RemouldLevel);

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

    // GoodsType 常量（constants.lua）。ITEM=1, EQUIP=2, SHIP=3, DROP=4, CURRENCY=5,
    // EQUIP_ENHANCE_ITEM=6, REWARD_SHIPLEVELUP_ITEM=15（舰船经验书，config_ship_exp_item）, FASHION=18。
    internal const int GoodsTypeItem = 1;
    internal const int GoodsTypeShip = 3;
    internal const int GoodsTypeDrop = 4;
    internal const int GoodsTypeRewardShipLevelUp = 15;

    // ExtractType 常量（constants.lua）
    internal const int ExtractTypeShip = 2;
    internal const int ExtractTypeLimitShip = 4;

    // HeroRarityType 常量
    internal const int RaritySR = 3;

    /// <summary>从船坞移除指定舰娘，并同时回收其已装备的装备实例（HeroId == heroId 的 EquipItem）。</summary>
    internal static PlayerAccount RemoveHero(PlayerAccount account, uint heroId)
    {
        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        heroes.RemoveAll(h => h.HeroId == heroId);
        PlayerEquip equip = account.Equip ?? new PlayerEquip([], 2000);
        List<EquipItem> items = equip.Items.ToList();
        items.RemoveAll(e => e.HeroId == heroId);
        return account with { Dock = dock with { Heroes = heroes }, Equip = equip with { Items = items } };
    }

    private List<uint> _lastBuildHeroIds = [];

    private readonly ConcurrentDictionary<string, SemaphoreSlim> _accountLocks = new();

    private readonly ConcurrentDictionary<string, PlayerAccount> _accountCache = new();

    /// <summary>获取指定账号的互斥锁，用于序列化并发写操作（如 hero.AddExp 快速连续升级）。</summary>
    internal async Task<IDisposable> LockAccountAsync(string profileId, CancellationToken ct)
    {
        var sem = _accountLocks.GetOrAdd(profileId, _ => new SemaphoreSlim(1, 1));
        await sem.WaitAsync(ct);
        return new AccountLockReleaser(sem);
    }

    private sealed class AccountLockReleaser(SemaphoreSlim sem) : IDisposable
    {
        public void Dispose() => sem.Release();
    }

    /// <summary>舰娘加入船坞：创建 Hero 实例，并按 config_ship_info（键 = ship_info_id = (templateId-1)/10）
    /// 的 equip1..equip6 发放默认装备（分配实例 ID 入装备仓库 + 填入 EquipSlots）。
    /// Affection 使用客户端配置的初始好感度 50。</summary>
    internal PlayerAccount AddShip(PlayerAccount account, uint heroId, int templateId, int now)
    {
        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        int fashioning = (templateId - 1) / 10;

        // 默认装备：config_ship_info.equip1..equip6。每个有效槽位分配一个装备实例，
        // EquipItem 存入装备仓库（HeroId 标记已装备），EquipSlots 记录槽位引用。
        List<uint> slots = [0, 0, 0, 0, 0, 0];
        PlayerEquip equip = account.Equip ?? new PlayerEquip([], 2000);
        List<EquipItem> equipItems = equip.Items.ToList();
        if (_shipInfos.TryGetValue((templateId - 1) / 10, out ConfigShipInfo? info))
        {
            long[] defaultEquips = [info.Equip1, info.Equip2, info.Equip3, info.Equip4, info.Equip5, info.Equip6];
            for (int i = 0; i < defaultEquips.Length; i++)
            {
                int equipTemplate = checked((int)defaultEquips[i]);
                if (equipTemplate <= 0 || EquipLoader.Get(equipTemplate) is null) continue;
                uint equipId = NextEquipId();
                equipItems.Add(new EquipItem(equipId, equipTemplate, HeroId: heroId));
                slots[i] = equipId;
            }
        }

        // 默认技能：从 config_ship_main.pskill_show_id 读取，每个技能初始 Level=1。
        List<PSkillEntry> pskills = CreateDefaultPSkills(templateId);

        heroes.Add(new Hero(heroId, templateId, 1,
            fashioning, CreateTime: now, UpdateTime: now,
            Affection: PlayerAccountFactory.DefaultAffection, CurHp: PlayerAccountFactory.HpCoefficient,
            Mood: 10000, MarryType: 0, EquipSlots: slots, PSkills: pskills));
        return account with { Dock = dock with { Heroes = heroes }, Equip = equip with { Items = equipItems } };
    }

    /// <summary>从 config_ship_main 读取默认技能列表（匹配客户端 GetAllPSkillArrbyShipMainId：pskill_show_id + direct_activate_talent_id + condition_activate_talent_id）。Level=1。</summary>
    internal static List<PSkillEntry> CreateDefaultPSkills(int templateId)
    {
        var skills = new List<PSkillEntry>();
        var cfg = ShipMainLoader.Get(templateId);
        if (cfg is null) return skills;

        var allIds = new List<long>();

        // pskill_show_id
        if (cfg.PskillShowId is { Count: > 0 } psIds)
            allIds.AddRange(psIds);

        // direct_activate_talent_id
        if (cfg.DirectActivateTalentId is { Count: > 0 } daIds)
            allIds.AddRange(daIds);

        // condition_activate_talent_id
        if (cfg.ConditionActivateTalentId is { Count: > 0 } caIds)
            foreach (var obj in caIds)
            {
                if (obj is System.Text.Json.JsonElement je && je.ValueKind == System.Text.Json.JsonValueKind.Number)
                    allIds.Add(je.GetInt64());
                else if (obj is long l)
                    allIds.Add(l);
            }

        foreach (long psId in allIds)
            if (psId > 0)
                skills.Add(new PSkillEntry((uint)psId, level: 1));

        return skills;
    }

    /// <summary>确保所有英雄都有默认 PSkills（兼容旧存档）。</summary>
    private static PlayerAccount EnsureHeroPSkills(PlayerAccount account)
    {
        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        bool changed = false;
        for (int i = 0; i < heroes.Count; i++)
        {
            if (heroes[i].PSkills is not { Count: > 0 })
            {
                heroes[i] = heroes[i] with { PSkills = CreateDefaultPSkills(heroes[i].TemplateId) };
                changed = true;
            }
        }
        return changed ? account with { Dock = dock with { Heroes = heroes } } : account;
    }

    /// <summary>
    /// 创建/加载档案时全量解锁全部时装（唯一解锁途径是商店，直接绕过）。
    /// 时装按 config_fashion.belong_to_ship（= config_ship_info.sf_id）分组为
    /// FashionEntry，供 fashion.updateData 推送。对已存在旧档同样生效。
    /// </summary>
    private static PlayerAccount EnsureAllFashion(PlayerAccount account)
    {
        var all = FashionConfigLoader.AllFashion;
        if (all.Count == 0) return account;
        var existing = new HashSet<(int, int)>();
        foreach (var entry in account.Fashion?.Entries ?? [])
            foreach (var tid in entry.FashionTids)
                existing.Add((entry.SfId, tid));
        var merged = all.Select(e =>
        {
            var tids = existing.Count > 0
                ? e.FashionTids.Concat(
                      account.Fashion?.Entries.SelectMany(x => x.FashionTids)
                          .Where(tid => FashionConfigLoader.FashionSfIdMap.GetValueOrDefault(tid) == e.SfId)
                          .Where(tid => !e.FashionTids.Contains(tid)) ?? [])
                  : e.FashionTids;
            return new FashionEntry(e.SfId, tids.Distinct().OrderBy(x => x).ToList());
        }).ToList();
        return account with { Fashion = new PlayerFashion(merged) };
    }

    /// <summary>
    /// 修复旧版本创建的错误初始好感度（1000/10000），并把历史赠礼产生的越界值
    /// 截断到客户端配置的未誓约 100、誓约后 200 上限。
    /// </summary>
    private static PlayerAccount NormalizeAffection(PlayerAccount account)
    {
        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        bool changed = false;
        for (int i = 0; i < heroes.Count; i++)
        {
            Hero hero = heroes[i];
            int affection = hero.Affection is 1000 or 10000
                ? PlayerAccountFactory.DefaultAffection
                : hero.Affection;
            int maxAffection = hero.MarryTime == 0
                ? PlayerAccountFactory.UnmarriedMaxAffection
                : PlayerAccountFactory.MarriedMaxAffection;
            affection = Math.Clamp(affection, 0, maxAffection);
            if (affection == hero.Affection) continue;
            heroes[i] = hero with { Affection = affection };
            changed = true;
        }
        return changed ? account with { Dock = dock with { Heroes = heroes } } : account;
    }

    /// <summary>
    /// 为新档案和旧档案补齐配置表中的好感度礼物。只添加从未存在过的种类；
    /// 已经消耗到 0 的条目会保留原值，避免每次登录自动恢复库存。
    /// </summary>
    private static PlayerAccount EnsureAffectionGifts(PlayerAccount account)
    {
        if (AffectionItemLoader.All.Count == 0) return account;
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> items = bag.Items.ToList();
        HashSet<int> existingIds = items.Select(i => i.TemplateId).ToHashSet();
        bool changed = false;
        foreach (var (id, gift) in AffectionItemLoader.All.OrderBy(x => x.Key))
        {
            if (gift.AffectionExp <= 0 || existingIds.Contains(id)) continue;
            items.Add(new BagItem(id, DefaultAffectionGiftCount));
            changed = true;
        }
        return changed ? account with { Bag = bag with { Items = items } } : account;
    }

    /// <summary>
    /// 戒指商品 102021 使用已结束活动的兑换道具 17553 作为客户端侧价格。
    /// 本地 GM 商店虽然不会在服务端扣款，但 Lua 会在发送 shop.BuyGoods 前检查库存；
    /// 因此为新旧档案补齐兑换额度；数量不足单价时也会恢复，符合免费 GM 商店语义。
    /// </summary>
    private static PlayerAccount EnsureOathShopCurrency(PlayerAccount account)
    {
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> items = bag.Items.ToList();
        int idx = items.FindIndex(i => i.TemplateId == OathShopCurrencyId);
        if (idx >= 0)
        {
            if (items[idx].Num >= 15_000) return account;
            items[idx] = items[idx] with { Num = DefaultOathShopCurrencyCount };
        }
        else
        {
            items.Add(new BagItem(OathShopCurrencyId, DefaultOathShopCurrencyCount));
        }
        return account with { Bag = bag with { Items = items } };
    }

    /// <summary>
    /// 构建 FashionTid → SfId 完整映射：优先 config_fashion.belong_to_ship（全量），
    /// 再补 gm-goods.json 手写白名单中配置表缺失的项。
    /// </summary>
    private Dictionary<int, int> BuildFashionSfIdMap()
    {
        var map = new Dictionary<int, int>();
        foreach (var kv in FashionConfigLoader.FashionSfIdMap)
            map[kv.Key] = kv.Value;
        foreach (var kv in _gmGoods.FashionSfId)
            map.TryAdd(kv.Key, kv.Value);
        return map;
    }

    internal static PlayerAccount SetAffection(PlayerAccount account, uint heroId, int amount)
    {
        HeroDock dock = account.Dock;
        List<Hero> heroes = dock.Heroes.ToList();
        int idx = heroes.FindIndex(h => h.HeroId == heroId);
        if (idx < 0) return account;
        Hero hero = heroes[idx];
        int maxAffection = hero.MarryTime == 0
            ? PlayerAccountFactory.UnmarriedMaxAffection
            : PlayerAccountFactory.MarriedMaxAffection;
        int affection = (int)Math.Clamp(
            checked((long)amount * PlayerAccountFactory.AffectionScale),
            0L,
            maxAffection);
        heroes[idx] = heroes[idx] with { Affection = affection };
        return account with { Dock = dock with { Heroes = heroes } };
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

    internal static Task<byte[]> BuildSimpleRet() => Task.FromResult(Array.Empty<byte>());

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

    /// <summary>
    /// 货币发放（CurrencyType → UserInfo 字段）。覆盖客户端 UserInfo 里全部 24 种持久货币
    /// （constants.lua CurrencyType 与 user_pb.lua TGetUserInfoRet 字段的并集，排除非 UserInfo
    /// 的战斗/建筑临时值如 BULLET/GAS/ELECTRIC 等）。
    /// </summary>
    internal static bool TryGetCurrency(PlayerAccount account, int currencyType, out int value)
    {
        PlayerCharacter c = account.Character;
        value = currencyType switch
        {
            1 => c.Gold,
            2 => c.Diamond,
            5 => c.Supply,
            8 => c.MainGun,
            9 => c.Torpedo,
            10 => c.Plane,
            11 => c.Other,
            12 => c.Retire,
            13 => c.Bath,
            14 => c.Strategy,
            15 => c.Medal,
            18 => c.Tower,
            22 => c.CopyTrainPoint,
            23 => c.FashionPoint,
            24 => c.GuildContri,
            25 => c.Lucky,
            26 => c.TeacherMedal,
            27 => c.TeacherPrestige,
            28 => c.BattlePassExp,
            29 => c.BattlePassGold,
            30 => c.PvePt,
            31 => c.GuildCoinII,
            32 => c.UrEquipCoin,
            33 => c.ActivityBattlePassExp,
            _ => int.MinValue,
        };
        return value != int.MinValue;
    }

    /// <summary>首次启用传统建造时，为本地 GM 档案补齐物资并写入迁移标记。</summary>
    private static PlayerAccount EnsureConstructionItems(PlayerAccount account)
    {
        // Construction 非空也作为迁移标记；即使某项物资日后恰好消耗至零，重启也不能再次赠送。
        if (account.Construction is not null) return account;
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> items = bag.Items.ToList();
        foreach (int templateId in new[]
                 {
                     ConstructionService.MaterialSteel,
                     ConstructionService.MaterialAluminium,
                     ConstructionService.QuickFinishItem,
                 })
        {
            int index = items.FindIndex(item => item.TemplateId == templateId);
            if (index < 0)
            {
                items.Add(new BagItem(templateId, DefaultConstructionItemCount));
            }
        }
        return account with
        {
            Bag = bag with { Items = items },
            Construction = new PlayerConstruction([]),
        };
    }

    /// <summary>为旧存档补上默认办公室与宿舍；新增字段为 null 时只迁移一次。</summary>
    private static PlayerAccount EnsureBuilding(PlayerAccount account)
    {
        if (account.Building is not null) return account;
        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        return account with { Building = PlayerAccountFactory.DefaultBuilding(now) };
    }

    /// <summary>
    /// 客户端会在发送基地新建/升级请求前检查配置中的建材库存。本地基地不消耗物资，
    /// 因此为新旧档案直接补足全部建材，避免客户端在请求到达服务端之前将操作拦截。
    /// </summary>
    private static PlayerAccount EnsureBuildingMaterials(PlayerAccount account)
    {
        if (BuildingConfigLoader.MaterialTemplateIds.Count == 0) return account;
        PlayerBag bag = account.Bag ?? new PlayerBag([], 100);
        List<BagItem> items = bag.Items.ToList();
        bool changed = false;
        foreach (int templateId in BuildingConfigLoader.MaterialTemplateIds)
        {
            int index = items.FindIndex(item => item.TemplateId == templateId);
            if (index >= 0 && items[index].Num >= DefaultBuildingMaterialCount) continue;
            if (index >= 0)
                items[index] = items[index] with { Num = DefaultBuildingMaterialCount };
            else
                items.Add(new BagItem(templateId, DefaultBuildingMaterialCount));
            changed = true;
        }
        return changed ? account with { Bag = bag with { Items = items } } : account;
    }

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

    /// <summary>仓库数据推送（bag.UpdateBagData）。<paramref name="removedTemplateIds"/> 为本次
    /// 完全消耗的道具模板 ID，以 Num=0 的删除标记追加，使客户端 bagdata.SetData 清除旧条目。</summary>
    public byte[] BuildBagPush(PlayerAccount account, uint now, IReadOnlyList<int>? removedTemplateIds = null)
    {
        var bag = account.Bag ?? new PlayerBag([], 100);
        var info = bag.Items.Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList();
        if (removedTemplateIds is { Count: > 0 })
            foreach (int templateId in removedTemplateIds)
                info.Add(new BagGridInfo(templateId, 0));
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

    /// <summary>装备仓库推送（equip.UpdateEquipBagData）。<paramref name="removedEquipIds"/> 为本次
    /// 移除的装备实例 ID，以 TemplateId=0 的删除标记追加，使客户端 equipdata.UpdateEquip 清除它们。</summary>
    public byte[] BuildEquipPush(PlayerAccount account, uint now, IReadOnlyList<uint>? removedEquipIds = null)
    {
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        var info = equip.Items.Select(e => new EquipInfo(e.EquipId, e.TemplateId, e.EnhanceLv,
            e.Star, e.HeroId, e.EnhanceExp)).ToList();
        if (removedEquipIds is { Count: > 0 })
            foreach (uint id in removedEquipIds)
                info.Add(new EquipInfo(EquipId: id, TemplateId: 0));
        var push = new TResponse(Method: "equip.UpdateEquipBagData",
            Ret: PlayerDataCodec.Encode(new EquipList(EquipBagSize: equip.EquipBagSize, EquipInfo: info)),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>购买数据推送（货币 + 仓库 + 时装 + 装备），必须在 shop.BuyGoods 应答前发出。</summary>
    public async Task<IReadOnlyList<byte[]>> BuildBuyPushesAsync(string profileId, uint now, CancellationToken ct,
        IReadOnlyList<int>? removedBagTemplateIds = null)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        List<HeroGrid> heroes = account.Dock.Heroes.Select(ToHeroGrid).ToList();
        return
        [
            await BuildUpdateUserInfoPushAsync(profileId, now, ct),
            // 购买舰娘后刷新船坞（hero.UpdateHeroBagData），使新船立即出现在船坞。
            TMessageCodec.EncodeResponse(new TResponse(
                Method: "hero.UpdateHeroBagData",
                Ret: PlayerDataCodec.Encode(new HeroBag(heroes, account.Dock.BagSize)),
                Time: now)),
            BuildBagPush(account, now, removedBagTemplateIds),
            BuildFashionPush(account, now),
            BuildEquipPush(account, now),
        ];
    }

    /// <summary>换装/买时装后的数据推送（船坞 + 装备仓库），供会话在 hero.ChangeEquip 应答后发出。</summary>
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

    public async Task<IReadOnlyList<byte[]>> BuildEnhancePushesAsync(string profileId, uint now, CancellationToken ct)
    {
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        return [BuildBagPush(account, now), BuildEquipPush(account, now)];
    }

    public async Task<IReadOnlyList<byte[]>> BuildBindEnhancePushesAsync(string profileId, uint now, CancellationToken ct)
    {
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        return
        [
            await BuildUpdateUserInfoPushAsync(profileId, now, ct),
            BuildBagPush(account, now),
            BuildEquipPush(account, now),
        ];
    }

    public async Task<IReadOnlyList<byte[]>> BuildRiseStarPushesAsync(string profileId, uint now, CancellationToken ct)
    {
        PlayerAccount account = await GetOrCreateAccountAsync(profileId, ct);
        return
        [
            await BuildUpdateUserInfoPushAsync(profileId, now, ct),
            BuildBagPush(account, now),
            BuildEquipPush(account, now),
        ];
    }
}
