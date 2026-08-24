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
        else if (request.Method == "hero.Marry")
        {
            ret = await BuildMarryRetAsync(request, profileId, now, ct);
        }
        else if (request.Method == "hero.HeroIntensify")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.HeroAdvance")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.HeroAdvanceMUB")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.LockHero")
        {
            ret = await BuildLockHeroRetAsync(request, profileId, ct);
        }
        else if (request.Method == "hero.RetireHero")
        {
            ret = await BuildRetireHeroRetAsync(request, profileId, ct);
        }
        else if (request.Method == "hero.ChangeName")
        {
            ret = await BuildChangeNameRetAsync(request, profileId, ct);
        }
        else if (request.Method == "hero.StudySkill")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.AutoEquip")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.AutoUnEquip")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.HeroAdvMaxLv")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.HeroEquipEffect")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.HeroRemould")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.EquipBinding")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.EquipUnBinding")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.EquipLockTransplant")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.HeroCombineUpLv")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.HeroCombineQuickLevelUp")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.HeroCombineBreak")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.HeroCombine")
        {
            ret = await BuildSimpleRet();
        }
        else if (request.Method == "hero.AddAffection")
        {
            ret = await BuildAddAffectionRetAsync(request, profileId, ct);
        }
        else if (request.Method == "hero.GetHeroInfo")
        {
            ret = await BuildGetHeroInfoRetAsync(profileId, ct);
        }
        else if (request.Method == "hero.GetHeroInfoByHeroIdArray")
        {
            ret = await BuildGetHeroInfoByHeroIdArrayRetAsync(profileId, ct);
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
            ret = await BuildPlotRewardAsync(request.Args ?? [], profileId, ct);
        }
        else if (request.Method == "copyinfo.GetCopyInfo")
        {
            ret = BuildCopyInfoRet(request.Args ?? []);
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
        else if (request.Method == "shop.GetShopsInfo")
        {
            ret = BuildShopsInfoRet(checked((uint)now));
        }
        else if (request.Method == "bag.GetBagInfo")
        {
            ret = await BuildGetBagInfoRetAsync(request, profileId, ct);
        }
        else if (request.Method == "fashion.Equip")
        {
            ret = await BuildFashionEquipRetAsync(request, profileId, ct);
        }
        else if (request.Method == "bathroom.BathStart")
        {
            ret = await BuildBathStartRetAsync(request, profileId, now, ct);
        }
        else if (request.Method == "bathroom.BathEnd" || request.Method == "bathroom.BathChangeHero")
        {
            ret = await BuildBathEndRetAsync(request, profileId, now, ct);
        }
        else if (request.Method == "bathroom.BathService")
        {
            ret = await BuildBathServiceRetAsync(request, profileId, now, ct);
        }
        else if (request.Method == "bathroom.BathAuto")
        {
            ret = await BuildBathAutoRetAsync(request, profileId, ct);
        }
        else if (request.Method == "bathroom.BathAllAuto")
        {
            ret = await BuildBathAllAutoRetAsync(request, profileId, ct);
        }
        else if (request.Method == "bathroom.GetBathroomInfo")
        {
            ret = await BuildGetBathroomInfoRetAsync(request, profileId, ct);
        }
        else if (request.Method == "bathroom.BathStartAll")
        {
            ret = await BuildBathStartAllRetAsync(request, profileId, now, ct);
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
                // Friend module (multiplayer social system, offline mode not applicable)
                "friend.GetFriendMainData" => [],
                "friend.GetRecommendList" => [],
                "friend.Apply" => [],
                "friend.Accept" => [],
                "friend.Refuse" => [],
                "friend.DeleteFriend" => [],
                "friend.SetBlack" => [],
                "friend.DeleteBlack" => [],
                "friend.SearchUser" => [],
                "friend.GetFriendList" => [],
                "friend.UpdateUserState" => [],
                // Chat module (multiplayer chat system, offline mode not applicable)
                "chat.ChangeWorldChannel" => [],
                "chat.SendMessage" => [],
                "chat.SendBarrage" => [],
                "chat.GetBarrageById" => [],
                // Discuss module (multiplayer discussion system, offline mode not applicable)
                "discuss.GetDiscuss" => [],
                "discuss.Discuss" => [],
                "discuss.HeroLike" => [],
                "discuss.Like" => [],
                "discuss.Dislike" => [],
                // Task module (return empty task list / success)
                "task.TaskInfo" => [],
                "task.TaskReward" => [],
                "task.TaskTrigger" => [],
                "task.TaskRewardByDaysActivity" => [],
                "task.TaskSevenDayActivity" => [],
                "task.TaskRewardByReturnActivity" => [],
                "task.TaskAllReward" => [],
                "task.GetPtReward" => [],
                "task.GetTeachingTask" => [],
                // ── Building: C# 3D building scene logic, offline mode not applicable ──
                "building.AddBuilding" => [],
                "building.UpgradeBuilding" => [],
                "building.DegradeBuilding" => [],
                "building.SetHero" => [],
                "building.SetBuildingListHero" => [],
                "building.FinishBuilding" => [],
                "building.ReceiveBuilding" => [],
                "building.ProduceItem" => [],
                "building.ComposeItem" => [],
                "building.ReceiveItem" => [],
                "building.ReceiveAll" => [],
                "building.ReceiveResource" => [],
                "building.UpdateHeroAddition" => [],
                "building.UseStrengthSpeedup" => [],
                "building.TriggerNormalHeroPlot" => [],
                "building.TriggerSpecialHeroPlot" => [],
                "building.SaveTactic" => [],
                "building.SetTacticName" => [],
                "building.RemoveTactic" => [],
                // ── Study: C# study timer and skill system, offline mode not applicable ──
                "study.GetStudyInfo" => [],
                "study.StartStudyPSkill" => [],
                "study.CancelStudyPSkill" => [],
                "study.EndStudyPSkill" => [],
                "study.SpeedUpStudy" => [],
                // ── Strategy: C# strategy tree UI logic, offline mode not applicable ──
                "strategy.Learn" => [],
                "strategy.Upgrade" => [],
                "strategy.Reset" => [],
                "strategy.Apply" => [],
                "strategy.GetStrategy" => [],
                // ── Build: C# build queue timer logic, offline mode not applicable ──
                "build.BuildingByFormula" => [],
                "build.BuildReceive" => [],
                "build.BuildQuicklyFinish" => [],
                // ── BuildNotes: C# social notes UI, offline mode not applicable ──
                "buildnotes.GetNotesList" => [],
                "buildnotes.GiveLike" => [],
                // ── Supply: C# supply switching UI, offline mode not applicable ──
                "supply.SupplySwitch" => [],
                // ── Repair: C# repair timer and dock UI, offline mode not applicable ──
                "repair.RepairHero" => [],
                // ── Shop: refresh ──
                "shop.RefreshShop" => [],
                // ── Equip: rise star, enhance, enhance bind, dismantle ──
                "equip.RiseStar" => [],
                "equip.Enhance" => [],
                "equip.EnhanceBind" => [],
                "equip.Dismantle" => [],
                // ── Bag: treasure, composite, sale ──
                "bag.GetNormalTreasureInfo" => [],
                "bag.GetSelectTreasureInfo" => [],
                "bag.CompositeItem" => [],
                "bag.SaleBagItem" => [],
                // ── Fashion: update data push, replace reward ──
                "fashion.updateData" => [],
                "fashion.fashionReplaceReward" => [],
                // ── Illustrate: client-side display features ──
                "illustrate.IllustrateNew" => [],
                "illustrate.AddBehaviour" => [],
                "illustrate.EquipNew" => [],
                "illustrate.VowHero" => [],
                "illustrate.VowDecTime" => [],
                "illustrate.ModiVowHeroList" => [],
                "illustrate.Memory" => [],
                // ── Guild module (multiplayer social system, offline mode not applicable) ──
                "guild.Create" => [],
                "guild.Search" => [],
                "guild.GetList" => [],
                "guild.Apply" => [],
                "guild.CancelApply" => [],
                "guild.Verify" => [],
                "guild.Dismiss" => [],
                "guild.Modify" => [],
                "guild.Appoint" => [],
                "guild.Remove" => [],
                "guild.Transfer" => [],
                "guild.Upgrade" => [],
                "guild.Quit" => [],
                "guild.GetApplyList" => [],
                "guild.GetMemberList" => [],
                "guild.RejectAll" => [],
                "guild.AcceptAll" => [],
                "guild.Publicity" => [],
                "guild.SetGuildLevelOfShow" => [],
                "guild.Impeach" => [],
                "guild.AcceptAllMsg" => [],
                "guild.UpdateOurGuildData" => [],
                "guild.UpdateMyGuildData" => [],
                // ── Guild War module (multiplayer guild war, offline mode not applicable) ──
                "guildwar.GetGuildwarInfo" => [],
                "guildwar.GetRankList" => [],
                "guildwar.GetBaseInfo" => [],
                "guildwar.GetHeroLockInfo" => [],
                "guildwar.GetBattleReport" => [],
                "guildwar.BattleReport" => [],
                "guildwar.GetGuildReward" => [],
                "guildwar.GetRankUserList" => [],
                "guildwar.GetHaveScores" => [],
                "guildwar.GetHaveGuildReward" => [],
                "guildwar.GetGuildGradeId" => [],
                "guildwar.UpdateBaseInfo" => [],
                // ── Guild Offer/Box/Task/BigActivity (multiplayer guild subsystems, offline mode not applicable) ──
                "guildOffer.GetOfferList" => [],
                "guildOffer.SubmitOffer" => [],
                "guildOffer.ReceiveOffer" => [],
                "guildOffer.RefreshOffer" => [],
                "guildbox.GetGuildBox" => [],
                "guildbox.OpenBox" => [],
                "guildbox.ReceiveBox" => [],
                "guildbigactivity.GetInfo" => [],
                "guildbigactivity.Join" => [],
                "guildbigactivity.ReceiveReward" => [],
                "guildofferrank.GetRankList" => [],
                "guildofferrank.GetSelfRank" => [],
                "guildbigactivityrank.GetRankList" => [],
                "guildbigactivityrank.GetSelfRank" => [],
                "guildtask.GetTaskList" => [],
                "guildtask.GetTaskReward" => [],
                "guildtask.TaskTrigger" => [],
                // ── Teaching module (multiplayer teaching/mentoring system, offline mode not applicable) ──
                "teachingsvr.TeachingInfo" => [],
                "teachingsvr.MyTeacher" => [],
                "teachingsvr.TeacherList" => [],
                "teachingsvr.Apply" => [],
                "teachingsvr.Agree" => [],
                "teachingsvr.Refuse" => [],
                "teachingsvr.Delete" => [],
                "user.TeacherRank" => [],
                "teachingsvr.Appraise" => [],
                "teachingsvr.MyStudent" => [],
                "teachingsvr.StudentList" => [],
                "teachingsvr.PersonalInfo" => [],
                "teachingsvr.Search" => [],
                "teachingsvr.ApplyList" => [],
                "teachingsvr.GetOtherInfo" => [],
                "teachingsvr.TaskReward" => [],
                // ── Match/Room/Multiplayer (multiplayer matchmaking and room system, offline mode not applicable) ──
                "matchsvr.CreateRoom" => [],
                "matchsvr.EnterRoom" => [],
                "matchsvr.ExitRoom" => [],
                "matchsvr.DismissRoom" => [],
                "matchsvr.Ready" => [],
                "matchsvr.Cancel" => [],
                "matchsvr.Kick" => [],
                "matchsvr.UploadTactic" => [],
                "matchsvr.GetRoomList" => [],
                "matchsvr.SwitchRoomPublicState" => [],
                "matchsvr.Start" => [],
                "match.UpdateRoomInfo" => [],
                "match.pveMatchRoomTimeout" => [],
                "room.GetRoomInfo" => [],
                "room.CreateRoom" => [],
                "room.EnterRoom" => [],
                "room.ExitRoom" => [],
                "room.DismissRoom" => [],
                "room.Ready" => [],
                "room.Cancel" => [],
                "room.Kick" => [],
                "room.Start" => [],
                "room.GetRoomList" => [],
                "room.SwitchRoomPublicState" => [],
                "room.UploadTactic" => [],
                "room.UpdateRoomInfo" => [],
                // ── Battle Multiplayer (multiplayer battle system, offline mode not applicable) ──
                "battle.CreateRoom" => [],
                "battle.JoinRoom" => [],
                "battle.MatchJoin" => [],
                "battle.MatchLeave" => [],
                "battle.createBattleInfo" => [],
                "battle.LeaveRoom" => [],
                // ── Copy module (remaining) ──
                "copy.StarReward" => [],
                "copy.FetchRewardBox" => [],
                "copy.DeleteRecord" => [],
                "copy.GetRecord" => [],
                "copy.TacticOn" => [],
                "copy.ChooseSfLv" => [],
                "copy.PassMiniGame" => [],
                "copy.PvpStartBase" => [],
                "copy.DotBase" => [],
                // ── CopyExtra ──
                "copyextra.AddCopyRewardCount" => [],
                "copyextra.UpdateCopyExtraInfo" => [],
                // ── ArchiveCopy ──
                "archiveCopy.ArchiveCopyData" => [],
                "archiveCopy.UpdataArchiveCopy" => [],
                "archiveCopy.IsLoad" => [],
                // ── MopUp ──
                "mopUp.GetMopUpData" => [],
                "mopUp.StartSweep" => [],
                "mopUp.CheckSweep" => [],
                "mopUp.StopSweep" => [],
                // ── Boss ──
                "boss.GetBossData" => [],
                "boss.UpdateBossData" => [],
                "boss.GetBossUserDamageRankList" => [],
                "boss.GetBossGuildDamageRankList" => [],
                // ── Tower ──
                "tower.GetTowerInfo" => [],
                "tower.Receive" => [],
                "tower.Replacement" => [],
                "tower.ReceiveBuff" => [],
                "tower.ResetChangeHeroIdList" => [],
                "tower.Reset" => [],
                "tower.SendUpgrade" => [],
                // ── ActivityTower ──
                "activityTower.GetActivityTower" => [],
                "activityTower.ReceiveBuff" => [],
                "activityTower.QuickPass" => [],
                "activityTower.ActivityTower" => [],
                "activityTower.Reset" => [],
                // ── ActivityBattlePass ──
                "activitybattlepass.GetActivityBattlePassInfo" => [],
                "activitybattlepass.GetActivityBattlePassReward" => [],
                "activitybattlepass.BuyActivityBattlePass" => [],
                "activitybattlepass.BuyActivityBattlePassGold" => [],
                "activitybattlepass.GetActivityBattlePassLevelReward" => [],
                "activitybattlepass.GetActivityBattlePassTaskReward" => [],
                // ── BattlePass ──
                "battlepass.GetBattlePassInfo" => [],
                "battlepass.GetBattlePassReward" => [],
                "battlepass.BuyBattlePass" => [],
                "battlepass.BuyBattlePassGold" => [],
                "battlepass.GetBattlePassLevelReward" => [],
                "battlepass.GetBattlePassTaskReward" => [],
                // ── ActivityVideo ──
                "activityVideo.SetActivityVideo" => [],
                // ── ShipTask ──
                "shiptask.GetShipTask" => [],
                "shiptask.ShipTaskReward" => [],
                "shiptask.ShipTaskTrigger" => [],
                "shiptask.ShipTaskAllReward" => [],
                // ── Exchange ──
                "exchange.GetExchangeInfo" => [],
                "exchange.Exchange" => [],
                "exchange.GetExchange" => [],
                // ── EquipActivity ──
                "equipactivity.GetReward" => [],
                "equipactivity.UpdateEquipActivityInfo" => [],
                // ── EquipTestCopy ──
                "equiptestcopy.GetEquipTestCopyInfo" => [],
                "equiptestcopy.StartEquipTestCopy" => [],
                "equiptestcopy.EndEquipTestCopy" => [],
                "equiptestcopy.PassEquipTestCopy" => [],
                // ── EquipNewTestCopy ──
                "equipnewtestcopy.GetEquipNewTestCopyInfo" => [],
                "equipnewtestcopy.StartEquipNewTestCopy" => [],
                "equipnewtestcopy.EndEquipNewTestCopy" => [],
                "equipnewtestcopy.PassEquipNewTestCopy" => [],
                // ── GoodsCopy ──
                "goodscopy.UpdateData" => [],
                // ── WalkDogCopy ──
                "walkdogcopy.UpdateData" => [],
                // ── FoodCompose ──
                "foodCompose.GetFoodComposeInfo" => [],
                "foodCompose.ComposeFood" => [],
                // ── MiniGame ──
                "miniGame.StartMiniGame" => [],
                // ── BigActivity ──
                "bigactivity.GetBigActivityInfo" => [],
                "bigactivity.GetBigActivityReward" => [],
                "bigactivity.BigActivity" => [],
                // ── InviteScore ──
                "invitescore.GetInviteScore" => [],
                "invitescore.GetInviteScoreReward" => [],
                "invitescore.InviteScore" => [],
                // ── TalentTree ──
                "talentTree.GetTalentTree" => [],
                "talentTree.TalentTreeLearn" => [],
                "talentTree.TalentTreeUpgrade" => [],
                "talentTree.TalentTreeReset" => [],
                "talentTree.TalentTreeApply" => [],
                "talentTree.TalentTreeTitle" => [],
                // ── Jopen ──
                "jopen.GetJopenInfo" => [],
                "jopen.JopenStart" => [],
                "jopen.JopenEnd" => [],
                // ── Magazine ──
                "magazine.GetMagazine" => [],
                "magazine.MagazineBuy" => [],
                "magazine.MagazineSell" => [],
                "magazine.MagazineCompose" => [],
                "magazine.MagazineEquip" => [],
                "magazine.MagazineUnEquip" => [],
                // ── InteractionItem ──
                "interactionitem.GetInteractionItem" => [],
                "interactionitem.InteractionItemBuy" => [],
                "interactionitem.InteractionItemSell" => [],
                "interactionitem.InteractionItemUse" => [],
                "interactionitem.InteractionItemCompose" => [],
                "interactionitem.InteractionItemEquip" => [],
                "interactionitem.InteractionItemUnEquip" => [],
                // ── Outpost ──
                "outpost.GetOutpost" => [],
                "outpost.OutpostStart" => [],
                "outpost.OutpostEnd" => [],
                "outpost.OutpostReceive" => [],
                "outpost.OutpostSpeedUp" => [],
                "outpost.OutpostSetHero" => [],
                "outpost.OutpostChangeHero" => [],
                "outpost.OutpostAll" => [],
                // ── PlayerHeadFrame ──
                "playerheadframe.RefreshPlayerHeadFrame" => [],
                // ── Prefs ──
                "prefs.SavePrefs" => [],
                "prefs.UpdatePrefsInfo" => [],
                // ── PresetFleet ──
                "presetfleet.SetPresetFleets" => [],
                "presetfleet.PresetFleetsInfo" => [],
                // ── SportsMeet & SportsMeetRank ──
                "sportsmeet.GetSportsMeet" => [],
                "sportsmeet.SportsMeetStart" => [],
                "sportsmeet.SportsMeetEnd" => [],
                "sportsmeet.SportsMeetReceive" => [],
                "sportsmeetrank.GetSportsMeetRank" => [],
                "sportsmeetrank.SportsMeetRankReward" => [],
                "sportsmeetrank.SportsMeetRankList" => [],
                "sportsmeetrank.SportsMeetRankInfo" => [],
                // ── SupportFleet ──
                "supportfleet.GetSupportFleet" => [],
                "supportfleet.SupportFleetSet" => [],
                "supportfleet.SupportFleetStart" => [],
                "supportfleet.SupportFleetEnd" => [],
                // ── Alchemy ──
                "alchemy.GetAlchemy" => [],
                "alchemy.AlchemyStart" => [],
                // ── Adventure ──
                "adventure.GetAdventure" => [],
                "adventure.AdventureStart" => [],
                "adventure.AdventureEnd" => [],
                // ── DailyCopy ──
                "dailycopy.GetDailyCopy" => [],
                "dailycopy.DailyCopyStart" => [],
                "dailycopy.DailyCopyEnd" => [],
                // ── SyncJson ──
                "syncJson.GetSyncJson" => [],
                // ── Update ──
                "update.UpdateGameAdvList" => [],
                "update.UpdateWebActivity" => [],
                "update.UpdateGMAnswer" => [],
                // ── User (remaining) ──
                "user.Logoff" => [],
                "user.BuyGold" => [],
                "user.BuySupply" => [],
                "user.BuyPvePt" => [],
                "user.GetSupply" => [],
                "user.Refresh" => [],
                "user.SetUserOrderRecord" => [],
                "user.KickInfo" => [],
                "user.InitQueueInfo" => [],
                "user.UpdateQueueInfo" => [],
                "user.MedalReplaceReward" => [],
                "user.NewHeadUnlock" => [],
                "usersvr.GetOtherInfo" => [],
                "user.GetMiniGameScoreRank" => [],
                "user.GetMiniGameScore" => [],
                "user.SetMiniGameScore" => [],
                // ── Battle (PvP / auto msg) ──
                "battle.pvpMatchReadyTimeout" => [],
                "battle.pvpMatchReady" => [],
                "battle.receiveAutoMsg" => [],
                "battle.SendAutoMsg" => [],
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

    private static BathHeroInfo ToBathHeroInfo(BathHero h) => new(h.HeroId, h.Pos, h.IsAuto, h.StartTime, h.BathTime, h.BuffId, h.BuffTime, h.Power);

    private static BathroomInfo ToBathroomInfo(PlayerBath? b) => b is null
        ? new BathroomInfo([], 0)
        : new BathroomInfo(b.HeroList.Select(ToBathHeroInfo).ToList(), b.IsAllAuto);

    // ── Bathroom handlers ──

    private async Task<byte[]> BuildBathStartRetAsync(TRequest request, string profileId, int now, CancellationToken ct)
    {
        var arg = PlayerDataCodec.DecodeBathStartArg(request.Args!);
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var dock = account.Dock;
        var hero = dock.Heroes.FirstOrDefault(h => h.HeroId == arg.HeroId);
        if (hero is null) throw new InvalidOperationException($"Hero {arg.HeroId} not found");
        var list = (account.Bath?.HeroList ?? []).ToList();
        list.RemoveAll(h => h.HeroId == arg.HeroId);
        list.Add(new BathHero(arg.HeroId, arg.Pos, StartTime: now, BathTime: 0));
        account = account with { Bath = new PlayerBath(list, account.Bath?.IsAllAuto ?? 0) };
        await _repo.SaveAccountAsync(account, ct);
        return PlayerDataCodec.Encode(ToBathroomInfo(account.Bath));
    }

    private async Task<byte[]> BuildBathEndRetAsync(TRequest request, string profileId, int now, CancellationToken ct)
    {
        uint heroId;
        if (request.Method == "bathroom.BathEnd")
            heroId = PlayerDataCodec.DecodeBathEndArg(request.Args!);
        else
        {
            var arg = PlayerDataCodec.DecodeBathChangeHeroArg(request.Args!);
            heroId = arg.HeroId;
        }
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var list = (account.Bath?.HeroList ?? []).ToList();
        var bathHero = list.FirstOrDefault(h => h.HeroId == heroId);
        if (bathHero is null) return PlayerDataCodec.EncodeBathEndRet(new BathHeroInfo(heroId, BathTime: 0));
        list.RemoveAll(h => h.HeroId == heroId);
        account = account with { Bath = new PlayerBath(list, account.Bath?.IsAllAuto ?? 0) };
        await _repo.SaveAccountAsync(account, ct);
        return PlayerDataCodec.EncodeBathEndRet(ToBathHeroInfo(bathHero));
    }

private async Task<byte[]> BuildBathServiceRetAsync(TRequest request, string profileId, int now, CancellationToken ct)
    {
        var arg = PlayerDataCodec.DecodeBathServiceArg(request.Args!);
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var bathHero = account.Bath?.HeroList.FirstOrDefault(h => h.HeroId == arg.HeroId);
        if (bathHero is null) return PlayerDataCodec.EncodeBathServiceRet(new BathHeroInfo(arg.HeroId), 0, false);
        // BuffId=0: skip buff lookup; GetBathAttrBuff checks heroBath.BuffId==0 → ret=nil
        return PlayerDataCodec.EncodeBathServiceRet(ToBathHeroInfo(bathHero), 0, false);
    }

    private async Task<byte[]> BuildBathAutoRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        var arg = PlayerDataCodec.DecodeBathAutoArg(request.Args!);
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var list = (account.Bath?.HeroList ?? []).ToList();
        var idx = list.FindIndex(h => h.HeroId == arg.HeroId);
        if (idx >= 0)
            list[idx] = list[idx] with { IsAuto = arg.Status };
        account = account with { Bath = new PlayerBath(list, account.Bath?.IsAllAuto ?? 0) };
        await _repo.SaveAccountAsync(account, ct);
        return [];
    }

    private async Task<byte[]> BuildBathAllAutoRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        var status = PlayerDataCodec.DecodeBathAllAutoArg(request.Args!);
        var account = await GetOrCreateAccountAsync(profileId, ct);
        account = account with { Bath = new PlayerBath(account.Bath?.HeroList ?? [], status) };
        await _repo.SaveAccountAsync(account, ct);
        return [];
    }

    private async Task<byte[]> BuildGetBathroomInfoRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        return PlayerDataCodec.Encode(ToBathroomInfo(account.Bath));
    }

    private async Task<byte[]> BuildBathStartAllRetAsync(TRequest request, string profileId, int now, CancellationToken ct)
    {
        var args = PlayerDataCodec.DecodeBathStartAllArg(request.Args!);
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var list = (account.Bath?.HeroList ?? []).ToList();
        var result = new List<BathHero>();
        foreach (var a in args)
        {
            list.RemoveAll(h => h.HeroId == a.HeroId);
            var bh = new BathHero(a.HeroId, a.Pos, StartTime: now, BathTime: 0);
            list.Add(bh);
            result.Add(bh);
        }
        account = account with { Bath = new PlayerBath(list, account.Bath?.IsAllAuto ?? 0) };
        await _repo.SaveAccountAsync(account, ct);
        return PlayerDataCodec.EncodeBathStartAllRet(result.Select(ToBathHeroInfo).ToList());
    }

    private static HeroGrid ToHeroGrid(Hero hero) =>
        new(hero.HeroId, hero.TemplateId, hero.Level, hero.Fashioning, hero.Exp, hero.CreateTime,
            hero.UpdateTime, hero.Affection, hero.MarryTime, hero.CurHp, hero.Mood, hero.MarryType,
            hero.EquipSlots, hero.Name, hero.Lock);

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


}
