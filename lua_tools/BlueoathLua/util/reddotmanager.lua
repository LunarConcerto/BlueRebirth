local RedDotManager = class("util.RedDotManager")
local redDotLogic = class("logic.RedDotLogic")
local redDotLogic = Logic.redDotLogic
RedDotManager.m_tabIdCheckRedDot = {
  [FunctionID.Friend] = {
    redDotLogic.FriendDotState,
    MSG_ID = LuaEvent.GetFriendsInfo
  },
  [FunctionID.Email] = {
    redDotLogic.EmailDotState,
    MSG_ID = LuaEvent.UpdataMailList
  },
  [FunctionID.Study] = {
    redDotLogic.StudyDotState,
    MSG_ID = LuaEvent.NewPayback
  },
  [FunctionID.Crusade] = {
    redDotLogic.WishDotState,
    MSG_ID = LuaEvent.UpdateWish
  }
}
RedDotConfig = {
  [1] = {
    func = redDotLogic.TaskOrAchieve,
    MSG_ID = {
      LuaEvent.GetTaskReward,
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [2] = {
    func = redDotLogic.Supply,
    MSG_ID = {
      LuaEvent.UpdataUserInfo,
      LuaEvent.UpdateActivity
    },
    alwaysDirty = false,
    type = 0
  },
  [3] = {
    func = redDotLogic.Task,
    MSG_ID = {
      LuaEvent.GetTaskReward,
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [4] = {
    func = redDotLogic.Achieve,
    MSG_ID = {
      LuaEvent.GetTaskReward,
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [5] = {
    func = redDotLogic.AchieveByType,
    MSG_ID = {
      LuaEvent.GetTaskReward,
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 1
  },
  [6] = {
    func = redDotLogic.TaskByType,
    MSG_ID = {
      LuaEvent.GetTaskReward,
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 1
  },
  [7] = {
    func = redDotLogic.Illustrate,
    MSG_ID = {
      LuaEvent.UpdataIllustrateList
    },
    alwaysDirty = false,
    type = 0
  },
  [8] = {
    func = redDotLogic.FriendApply,
    MSG_ID = {
      LuaEvent.GetFriendsInfo,
      LuaEvent.ApplyFriend
    },
    alwaysDirty = false,
    type = 0
  },
  [9] = {
    func = redDotLogic.FriendDotState,
    MSG_ID = {
      LuaEvent.GetFriendsInfo,
      LuaEvent.TeachingUpdateInfo
    },
    alwaysDirty = false,
    type = 0
  },
  [10] = {
    func = redDotLogic.EmailDotState,
    MSG_ID = {
      LuaEvent.UpdataMailList,
      LuaEvent.NewPayback
    },
    alwaysDirty = false,
    type = 0
  },
  [11] = {
    func = redDotLogic.StudyDotState,
    MSG_ID = {
      LuaEvent.StartStudy,
      LuaEvent.FinishStudy
    },
    alwaysDirty = false,
    type = 0
  },
  [12] = {
    func = redDotLogic.WishDotState,
    MSG_ID = {
      LuaEvent.UpdateWish
    },
    alwaysDirty = false,
    type = 0
  },
  [13] = {
    func = redDotLogic.PrivateChat,
    MSG_ID = {
      LuaEvent.UpdataHomeChat,
      LuaEvent.UpdataChatInfo,
      LuaEvent.ChatResetUnreadById
    },
    alwaysDirty = false,
    type = 0
  },
  [14] = {
    func = redDotLogic.AssistFleetFinish,
    MSG_ID = {
      LuaEvent.UpdateAssistList,
      LuaEvent.SupportTimerFinish
    },
    alwaysDirty = false,
    type = 0
  },
  [15] = {
    func = redDotLogic.ShipBreakByShipId,
    MSG_ID = {
      LuaEvent.UpdateHeroData,
      LuaEvent.UpdateGirlTog
    },
    alwaysDirty = false,
    type = 1
  },
  [16] = {
    func = redDotLogic.MoreQualityEquipByShipId,
    MSG_ID = {
      LuaEvent.UpdateBagEquip,
      LuaEvent.UpdateEquipMsg,
      LuaEvent.UpdateHeroData
    },
    alwaysDirty = false,
    type = 1
  },
  [17] = {
    func = redDotLogic.MoreQualityEquipByIndex,
    MSG_ID = {
      LuaEvent.UpdateBagEquip,
      LuaEvent.UpdateEquipMsg,
      LuaEvent.UpdateHeroData
    },
    alwaysDirty = false,
    type = 1
  },
  [18] = {
    func = redDotLogic.CanEquipByShipId,
    MSG_ID = {
      LuaEvent.UpdateBagEquip,
      LuaEvent.UpdateEquipMsg,
      LuaEvent.UpdateHeroData
    },
    alwaysDirty = false,
    type = 1
  },
  [19] = {
    func = redDotLogic.CanEquipByShipIdByIndex,
    MSG_ID = {
      LuaEvent.UpdateBagEquip,
      LuaEvent.UpdateEquipMsg,
      LuaEvent.UpdateHeroData
    },
    alwaysDirty = false,
    type = 1
  },
  [20] = {
    func = redDotLogic.EquipEnhanceByShipId,
    MSG_ID = {
      LuaEvent.UpdateBagEquip
    },
    alwaysDirty = false,
    type = 1
  },
  [21] = {
    func = redDotLogic.EquipEnhanceByIndex,
    MSG_ID = {
      LuaEvent.UpdateBagEquip
    },
    alwaysDirty = false,
    type = 1
  },
  [22] = {
    func = redDotLogic.EquipRiseStarByShipId,
    MSG_ID = {
      LuaEvent.UpdateEquipMsg,
      LuaEvent.UpdateGirlTog,
      LuaEvent.UpdataUserInfo,
      LuaEvent.UpdateBagItem
    },
    alwaysDirty = false,
    type = 1
  },
  [23] = {
    func = redDotLogic.EquipRiseStarByIndex,
    MSG_ID = {
      LuaEvent.UpdateEquipMsg,
      LuaEvent.UpdataUserInfo,
      LuaEvent.UpdateBagItem
    },
    alwaysDirty = false,
    type = 1
  },
  [24] = {
    func = redDotLogic.Plot,
    MSG_ID = {},
    alwaysDirty = false,
    type = 0
  },
  [25] = {
    func = redDotLogic.PlotById,
    MSG_ID = {},
    alwaysDirty = false,
    type = 1
  },
  [26] = {
    func = redDotLogic.FriendChat,
    MSG_ID = {
      LuaEvent.UpdataChatInfo,
      LuaEvent.ChatResetUnreadById
    },
    alwaysDirty = false,
    type = 0
  },
  [27] = {
    func = redDotLogic.AssistFleetFree,
    MSG_ID = {
      LuaEvent.UpdateAssistList
    },
    alwaysDirty = false,
    type = 0
  },
  [28] = {
    func = redDotLogic.FleetStrategy,
    MSG_ID = {
      LuaEvent.GetFleetMsg,
      LuaEvent.UpdateHeroItem
    },
    alwaysDirty = false,
    type = 1
  },
  [29] = {
    func = redDotLogic.TrainChestReward,
    MSG_ID = {
      LuaEvent.GetCopyData
    },
    alwaysDirty = false,
    type = 1
  },
  [30] = {
    func = redDotLogic.BigActivity,
    MSG_ID = {
      LuaEvent.GetTaskReward
    },
    alwaysDirty = false,
    type = 0
  },
  [31] = {
    func = redDotLogic.NewPlayer,
    MSG_ID = {
      LuaEvent.GetNewPlayerReward,
      LuaEvent.SelfReddotCallBack
    },
    alwaysDirty = false,
    type = 0
  },
  [32] = {
    func = redDotLogic.BuildShipGirl,
    MSG_ID = {
      LuaEvent.UpadateBuildGirlData
    },
    alwaysDirty = false,
    type = 0
  },
  [33] = {
    func = redDotLogic.NewPlayerDays,
    MSG_ID = {
      LuaEvent.GetNewPlayerReward,
      LuaEvent.UpdateLoginTime
    },
    alwaysDirty = false,
    type = 1
  },
  [34] = {
    func = redDotLogic.FirstRecharge,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [35] = {
    func = redDotLogic.CumuCost,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [36] = {
    func = redDotLogic.MaintenanceAnnouncement,
    MSG_ID = {
      LuaEvent.AnnouncementState,
      LuaEvent.OpenAnnouncement
    },
    alwaysDirty = false,
    type = 0
  },
  [37] = {
    func = redDotLogic.ShipLevelUpByShipId,
    MSG_ID = {
      LuaEvent.HeroAddExp
    },
    alwaysDirty = false,
    type = 1
  },
  [38] = {
    func = redDotLogic.Strategy,
    MSG_ID = {
      LuaEvent.StrategyRedDot
    },
    alwaysDirty = false,
    type = 1
  },
  [39] = {
    func = redDotLogic.SafeArea,
    MSG_ID = {
      LuaEvent.GetCopyData
    },
    alwaysDirty = false,
    type = 1
  },
  [40] = {
    func = redDotLogic.ShipSkill,
    MSG_ID = {
      LuaEvent.HeroStudySkill
    },
    alwaysDirty = false,
    type = 1
  },
  [41] = {
    func = redDotLogic.DailyLogin,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [42] = {
    func = redDotLogic.ShopLevelGift1,
    MSG_ID = {
      LuaEvent.ShopLevelGift
    },
    alwaysDirty = false,
    type = 1
  },
  [43] = {
    func = redDotLogic.UserChatUnRend,
    MSG_ID = {
      LuaEvent.UpdataChatInfo,
      LuaEvent.ChatResetUnreadById
    },
    alwaysDirty = false,
    type = 1
  },
  [44] = {
    func = redDotLogic.ShopLevelGift2,
    MSG_ID = {
      LuaEvent.ShopLevelGift
    },
    alwaysDirty = false,
    type = 1
  },
  [45] = {
    func = redDotLogic.ShopLevelGift3,
    MSG_ID = {
      LuaEvent.ShopLevelGift
    },
    alwaysDirty = false,
    type = 1
  },
  [46] = {
    func = redDotLogic.ShopLevelGift4,
    MSG_ID = {
      LuaEvent.ShopLevelGift,
      LuaEvent.UpdateDailyShop
    },
    alwaysDirty = false,
    type = 1
  },
  [47] = {
    func = redDotLogic.SeaCopyBoxById,
    MSG_ID = {
      LuaEvent.FetchRewardBox
    },
    alwaysDirty = false,
    type = 1
  },
  [48] = {
    func = redDotLogic.SeaCopyBox,
    MSG_ID = {
      LuaEvent.FetchRewardBox
    },
    alwaysDirty = false,
    type = 0
  },
  [49] = {
    func = redDotLogic.GoodsCopyFirstBattle,
    MSG_ID = {
      LuaEvent.GoodsCopyBattle
    },
    alwaysDirty = false,
    type = 0
  },
  [50] = {
    func = redDotLogic.ShipSkillByHeroId,
    MSG_ID = {
      LuaEvent.HeroStudySkill
    },
    alwaysDirty = false,
    type = 1
  },
  [51] = {
    func = redDotLogic.CumuRecharge,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [52] = {
    func = redDotLogic.SingleRecharge,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [53] = {
    func = redDotLogic.BigActivityById,
    MSG_ID = {
      LuaEvent.GetTaskReward
    },
    alwaysDirty = false,
    type = 1
  },
  [55] = {
    func = redDotLogic.GuildHaveApply,
    MSG_ID = {
      LuaEvent.Flag_Update_HaveApply
    },
    alwaysDirty = false,
    type = 0
  },
  [56] = {
    func = redDotLogic.DailyShop,
    MSG_ID = {
      LuaEvent.UpdateDailyShop
    },
    alwaysDirty = false,
    type = 1
  },
  [57] = {
    func = redDotLogic.DailySubShop,
    MSG_ID = {
      LuaEvent.UpdateDailyShop
    },
    alwaysDirty = false,
    type = 1
  },
  [58] = {
    func = redDotLogic.BuildingCanGetOil,
    MSG_ID = {
      LuaEvent.BuildingRefreshData
    },
    alwaysDirty = false,
    type = 0
  },
  [59] = {
    func = redDotLogic.BuildingCanGetGold,
    MSG_ID = {
      LuaEvent.BuildingRefreshData
    },
    alwaysDirty = false,
    type = 0
  },
  [60] = {
    func = redDotLogic.BuildingCanGetItem,
    MSG_ID = {
      LuaEvent.BuildingRefreshData
    },
    alwaysDirty = false,
    type = 0
  },
  [61] = {
    func = redDotLogic.BuildShipStatus,
    MSG_ID = {
      LuaEvent.BuildFinish
    },
    alwaysDirty = false,
    type = 0
  },
  [62] = {
    func = redDotLogic.InSingleBuildingHero,
    MSG_ID = {
      LuaEvent.BuildingRefreshData
    },
    alwaysDirty = false,
    type = 1
  },
  [63] = {
    func = redDotLogic.InAllBuildingHero,
    MSG_ID = {
      LuaEvent.BuildingRefreshData
    },
    alwaysDirty = false,
    type = 0
  },
  [64] = {
    func = redDotLogic.DailyLoginById,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 1
  },
  [65] = {
    func = redDotLogic.BuildShipFree,
    MSG_ID = {
      LuaEvent.BuildFinish,
      LuaEvent.BulidShipBtnFree
    },
    alwaysDirty = false,
    type = 1
  },
  [68] = {
    func = redDotLogic.BuildShipTimesReward,
    MSG_ID = {
      LuaEvent.BuildFinish
    },
    alwaysDirty = false,
    type = 1
  },
  [69] = {
    func = redDotLogic.BuildShipTimesReward,
    MSG_ID = {
      LuaEvent.BuildFinish
    },
    alwaysDirty = false,
    type = 1
  },
  [71] = {
    func = redDotLogic.TeachingCanEvaTeacher,
    MSG_ID = {
      LuaEvent.TeachingAppraise,
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [72] = {
    func = redDotLogic.TeachingCanTaskReward,
    MSG_ID = {
      LuaEvent.UpdataTaskList,
      LuaEvent.GetTaskReward
    },
    alwaysDirty = false,
    type = 0
  },
  [73] = {
    func = redDotLogic.TeachingGetCareerReward,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [74] = {
    func = redDotLogic.TeachingApply,
    MSG_ID = {
      LuaEvent.TeachingUpdateInfo,
      LuaEvent.TeachingRefuseApply
    },
    alwaysDirty = false,
    type = 0
  },
  [75] = {
    func = redDotLogic.TeachingApply,
    MSG_ID = {
      LuaEvent.TeachingUpdateInfo,
      LuaEvent.TeachingRefuseApply
    },
    alwaysDirty = false,
    type = 0
  },
  [76] = {
    func = redDotLogic.ActivityTaskCanGetReward,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 1
  },
  [77] = {
    func = redDotLogic.ActivitySchoolSumm,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [70] = {
    func = redDotLogic.PresetFleetStatus,
    MSG_ID = {
      LuaEvent.UpdataUserInfo,
      LuaEvent.PresetFleetInfo
    },
    alwaysDirty = false,
    type = 0
  },
  [78] = {
    func = redDotLogic.CanGetGuildTaskConstantReward,
    MSG_ID = {
      LuaEvent.UPDATE_GUILDTASK_INFO
    },
    alwaysDirty = false,
    type = 0
  },
  [79] = {
    func = redDotLogic.CanGetGuildTaskRandomReward,
    MSG_ID = {
      LuaEvent.UPDATE_GUILDTASK_INFO,
      LuaEvent.UPDATE_GUILDTASK_USER_INFO
    },
    alwaysDirty = false,
    type = 0
  },
  [80] = {
    func = redDotLogic.NotYetApplyGuildTask,
    MSG_ID = {
      LuaEvent.UPDATE_GUILDTASK_INFO,
      LuaEvent.UPDATE_GUILDTASK_USER_INFO
    },
    alwaysDirty = false,
    type = 0
  },
  [81] = {
    func = redDotLogic.OpenedTeaching,
    MSG_ID = {
      LuaEvent.TeachingOpened
    },
    alwaysDirty = false,
    type = 0
  },
  [82] = {
    func = redDotLogic.ActSSRIsHaveTimes,
    MSG_ID = {
      LuaEvent.UpadateActData
    },
    alwaysDirty = false,
    type = 0
  },
  [83] = {
    func = redDotLogic.ActivityNationSumm,
    MSG_ID = {
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [84] = {
    func = redDotLogic.DailyCopy,
    MSG_ID = {},
    alwaysDirty = false,
    type = 0
  },
  [85] = {
    func = redDotLogic.WishCanUseItem,
    MSG_ID = {
      LuaEvent.UpdateBagItem,
      LuaEvent.UpdataIllustrateList
    },
    alwaysDirty = false,
    type = 0
  },
  [86] = {
    func = redDotLogic.BuildingHeroPlotAll,
    MSG_ID = {
      LuaEvent.BuildingRefreshData
    },
    alwaysDirty = false,
    type = 0
  },
  [87] = {
    func = redDotLogic.BuildingHeroPlotSingle,
    MSG_ID = {
      LuaEvent.BuildingRefreshData
    },
    alwaysDirty = false,
    type = 1
  },
  [89] = {
    func = redDotLogic.HalloweenActivityNewStory,
    MSG_ID = {
      LuaEvent.AEQUIP_RefreshData,
      LuaEvent.GetCopyData
    },
    alwaysDirty = false,
    type = 0
  },
  [90] = {
    func = redDotLogic.ActivityEquipCanGetReward,
    MSG_ID = {
      LuaEvent.AEQUIP_RefreshData
    },
    alwaysDirty = false,
    type = 0
  },
  [88] = {
    func = redDotLogic.AEquipCanUp,
    MSG_ID = {
      LuaEvent.UpdateBagEquip,
      LuaEvent.UpdateEquipMsg,
      LuaEvent.UpdateHeroData,
      LuaEvent.UpdateActivity
    },
    alwaysDirty = false,
    type = 1
  },
  [91] = {
    func = redDotLogic.TestShip,
    MSG_ID = {
      LuaEvent.GoodsCopyBattle
    },
    alwaysDirty = false,
    type = 1
  },
  [92] = {
    func = redDotLogic.EquipTest,
    MSG_ID = {
      LuaEvent.EquipTestReceiveRewards,
      LuaEvent.EquipTestDamage
    },
    alwaysDirty = false,
    type = 1
  },
  [94] = {
    func = redDotLogic.ThanksgivingDayReawrd,
    MSG_ID = {
      LuaEvent.GetTaskReward
    },
    alwaysDirty = false,
    type = 1
  },
  [95] = {
    func = redDotLogic.ActivitySecretCopyCanGetReward,
    MSG_ID = {
      LuaEvent.ActivitySecretCopy_RefreshData,
      LuaEvent.ActivitySecretCopy_LookRefresh
    },
    alwaysDirty = false,
    type = 0
  },
  [97] = {
    func = redDotLogic.HeroCanFurther,
    MSG_ID = {
      LuaEvent.HERO_LvFurtherOk,
      LuaEvent.UpdateHeroData,
      LuaEvent.UpdateBagItem
    },
    alwaysDirty = false,
    type = 1
  },
  [98] = {
    func = redDotLogic.GMAnswerUpdate,
    MSG_ID = {
      LuaEvent.RedDotGMAnswerUpdate
    },
    alwaysDirty = false,
    type = 0
  },
  [99] = {
    func = redDotLogic.CheckSevenDaysSign,
    MSG_ID = {
      LuaEvent.GetTaskReward
    },
    alwaysDirty = false,
    type = 1
  },
  [100] = {
    func = redDotLogic.ActivityShipTestReward,
    MSG_ID = {
      LuaEvent.ShipTask_RefreshData
    },
    alwaysDirty = false,
    type = 1
  },
  [101] = {
    func = redDotLogic.ActivityShipTestRewardByTaskType,
    MSG_ID = {
      LuaEvent.ShipTask_RefreshData
    },
    alwaysDirty = false,
    type = 1
  },
  [102] = {
    func = redDotLogic.ActivityPageLook,
    MSG_ID = {
      LuaEvent.ActivityPage_LookRefresh
    },
    alwaysDirty = false,
    type = 1
  },
  [103] = {
    func = redDotLogic.FashionShop,
    MSG_ID = {
      LuaEvent.OpenShopFashion
    },
    alwaysDirty = false,
    type = 1
  },
  [104] = {
    func = redDotLogic.GeneralShop,
    MSG_ID = {
      LuaEvent.OpenShopFashion
    },
    alwaysDirty = false,
    type = 1
  },
  [106] = {
    func = redDotLogic.ActivityLoveLetterReward,
    MSG_ID = {
      LuaEvent.ActivityValentineLoveLetter_RefreshData
    },
    alwaysDirty = true,
    type = 1
  },
  [105] = {
    func = redDotLogic.CheckAllPeriodItem,
    MSG_ID = {
      LuaEvent.UpdateBagItem,
      LuaEvent.ItemPastDue
    },
    alwaysDirty = false,
    type = 0
  },
  [107] = {
    func = redDotLogic.ActivityValentineSale,
    MSG_ID = {
      LuaEvent.OpenValentineSale,
      LuaEvent.UpdateActivity
    },
    alwaysDirty = false,
    type = 0
  },
  [108] = {
    func = redDotLogic.ActivityValentinePackage,
    MSG_ID = {
      LuaEvent.UpdateActivity,
      LuaEvent.OpenValentinePackage
    },
    alwaysDirty = false,
    type = 0
  },
  [109] = {
    func = redDotLogic.Milestone,
    MSG_ID = {
      LuaEvent.UpdateActivity,
      LuaEvent.GetMilestoneMsg
    },
    alwaysDirty = false,
    type = 1
  },
  [600] = {
    func = redDotLogic.BattlePassCanRecieveTaskRewardByIndex,
    MSG_ID = {
      LuaEvent.BattlePass_Update
    },
    alwaysDirty = false,
    type = 1
  },
  [601] = {
    func = redDotLogic.BattlePassCanRecieveTaskReward,
    MSG_ID = {
      LuaEvent.BattlePass_Update
    },
    alwaysDirty = false,
    type = 0
  },
  [602] = {
    func = redDotLogic.BattlePassCanRecieveLevelReward,
    MSG_ID = {
      LuaEvent.BattlePass_Update
    },
    alwaysDirty = false,
    type = 0
  },
  [81003] = {
    func = redDotLogic.ActivitySceneLogin,
    MSG_ID = {
      LuaEvent.OpenActivitySceneLoginPage
    },
    alwaysDirty = false,
    type = 1
  },
  [81008] = {
    func = redDotLogic.NewMagazine,
    MSG_ID = {
      LuaEvent.GetMagazineMsg,
      LuaEvent.GetMagazineFetchReward
    },
    alwaysDirty = false,
    type = 0
  },
  [81009] = {
    func = redDotLogic.MagazineReward,
    MSG_ID = {
      LuaEvent.GetMagazineMsg,
      LuaEvent.GetMagazineFetchReward
    },
    alwaysDirty = false,
    type = 1
  },
  [81010] = {
    func = redDotLogic.MagazineRewardAll,
    MSG_ID = {
      LuaEvent.GetMagazineMsg,
      LuaEvent.GetMagazineFetchReward
    },
    alwaysDirty = false,
    type = 0
  },
  [82001] = {
    func = redDotLogic.AnniversaryMemoryReward,
    MSG_ID = {
      LuaEvent.GetTaskReward
    },
    alwaysDirty = false,
    type = 1
  },
  [81011] = {
    func = redDotLogic.ReturnPlayer,
    MSG_ID = {
      LuaEvent.GetReturnPlayerReward,
      LuaEvent.ReturnPlayerReddotCallBack
    },
    alwaysDirty = false,
    type = 0
  },
  [81012] = {
    func = redDotLogic.ReturnPlayerDays,
    MSG_ID = {
      LuaEvent.GetReturnPlayerReward,
      LuaEvent.UpdateLoginTime
    },
    alwaysDirty = false,
    type = 1
  },
  [82002] = {
    func = redDotLogic.BirthdayCakePage,
    MSG_ID = {
      LuaEvent.BirthdayCakePageOpen
    },
    alwaysDirty = false,
    type = 0
  },
  [83001] = {
    func = redDotLogic.ActivitySearchGoods,
    MSG_ID = {
      LuaEvent.GetTaskReward,
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [81013] = {
    func = redDotLogic.DecorateFurnitureBagItem,
    MSG_ID = {
      LuaEvent.GetNewDecorateItem,
      LuaEvent.CloseDecorationBag
    },
    alwaysDirty = false,
    type = 0
  },
  [50000] = {
    func = redDotLogic.EquipIllustrate,
    MSG_ID = {
      LuaEvent.UpdataIllustrateEquipList,
      LuaEvent.UpdataIllustrateList
    },
    alwaysDirty = false,
    type = 0
  },
  [82003] = {
    func = redDotLogic.EquipNewTest,
    MSG_ID = {
      LuaEvent.FetchRewardBox,
      LuaEvent.EquipNewTestReceiveRewards,
      LuaEvent.EquipNewTestOpenDot
    },
    alwaysDirty = false,
    type = 1
  },
  [81025] = {
    func = redDotLogic.ActivityMiniGame,
    MSG_ID = {
      LuaEvent.GetTaskReward,
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 0
  },
  [81002] = {
    func = redDotLogic.Exchange,
    MSG_ID = {
      LuaEvent.UpdateBagItem,
      LuaEvent.GetExchangeMsg
    },
    alwaysDirty = false,
    type = 1
  },
  [82005] = {
    func = redDotLogic.MianPlot,
    MSG_ID = {},
    alwaysDirty = false,
    type = 1
  },
  [83002] = {
    func = redDotLogic.MultiPveTask,
    MSG_ID = {
      LuaEvent.GetTaskReward,
      LuaEvent.UpdataTaskList
    },
    alwaysDirty = false,
    type = 1
  },
  [82008] = {
    func = redDotLogic.MultiPveEntrance,
    MSG_ID = {
      LuaEvent.UpdateCopyRewardCount
    },
    alwaysDirty = false,
    type = 0
  }
}

function RedDotManager:initialize()
  for k, v in pairs(self.m_tabIdCheckRedDot) do
    if v.MSG_ID then
      eventManager:RegisterEvent(v.MSG_ID, self._UpdateRedDot, self)
    end
  end
end

function RedDotManager:_UpdateRedDot()
  eventManager:SendEvent(LuaEvent.UpdateHomeRedDot)
end

function RedDotManager:CheckHomeRedDot(nFuncId)
  if not moduleManager:CheckFunc(nFuncId, false) then
    return false
  end
  local tblFuncs = self.m_tabIdCheckRedDot[nFuncId] or {}
  local temp = false
  local ret = false
  for i = 1, #tblFuncs do
    temp = tblFuncs[i](tblFuncs.handler)
    if i == 1 then
      ret = temp
    else
      ret = ret or temp
    end
  end
  return ret
end

function RedDotManager:getStateByRedDot(redDot, param)
  if IsNil(redDot) then
    return
  end
  local redDotType = redDot:GetRedDotType()
  local config = configManager.GetDataById("config_flag_res", redDotType)
  if config == nil then
    logError("config_flag_res not config, redDotType:" .. redDotType)
    return
  end
  local typ = config.number
  if typ == RedDotType.Normal then
    self:getStateByRedDotNormal(redDot, param)
  elseif typ == RedDotType.Number then
    self:getStateByRedDotNumber(redDot, param)
  end
end

function RedDotManager:getStateByRedDotNormal(redDot, param)
  local keys = redDot:GetKeys()
  local tg = redDot:GetToggle()
  if tg and tg.toggle.isOn then
    redDot.gameObject:SetActive(false)
    return
  end
  local comment = ""
  for i, redDotId in pairs(keys) do
    if redDotId and 0 < redDotId then
      param = self:GetParamById(redDotId, param)
      local config = RedDotConfig[redDotId]
      if config.type ~= REDDOT_PARAM_TYPE.Programmer or #param ~= 0 then
        local result = self:GetStateById(redDotId, RedDotType.Normal, param)
        local resultStr = result and "true" or "false"
        comment = comment .. "Id:" .. redDotId
        if param then
          for i, v in pairs(param) do
            comment = comment .. "    " .. "param:" .. tostring(v)
          end
        end
        comment = comment .. "    " .. "result:" .. resultStr .. "#"
        if result then
          redDot.gameObject:SetActive(true)
          redDot:SetComment(comment)
          return
        end
      end
    end
  end
  redDot:SetComment(comment)
  redDot.gameObject:SetActive(false)
end

function RedDotManager:getStateByRedDotNumber(redDot, param)
  local keys = redDot:GetKeys()
  local comment = ""
  local result = 0
  for i, redDotId in pairs(keys) do
    if redDotId and 0 < redDotId then
      param = self:GetParamById(redDotId, param)
      local config = RedDotConfig[redDotId]
      if config.type ~= REDDOT_PARAM_TYPE.Programmer or #param ~= 0 then
        local num = self:GetStateById(redDotId, RedDotType.Number, param)
        result = result + num
        comment = comment .. "Id:" .. redDotId
        if param then
          for i, v in pairs(param) do
            comment = comment .. "    " .. "param:" .. v
          end
        end
        comment = comment .. "    " .. "num:" .. num .. "#"
      end
    end
  end
  redDot:SetTextByNumber(result)
  redDot:SetComment(comment)
end

function RedDotManager:GetParamById(redDotId, param)
  local rec = RedDotConfig[redDotId]
  if not rec then
    logError("RedDotConfig not config, redDotId:" .. redDotId)
    return
  end
  local typ = rec.type
  local result = {}
  if typ == REDDOT_PARAM_TYPE.None then
    return result
  elseif typ == REDDOT_PARAM_TYPE.Programmer then
    return param
  elseif typ == REDDOT_PARAM_TYPE.Planer then
    local funConfig = configManager.GetDataById("config_flagsystem", redDotId)
    if funConfig == nil then
      logError("config_flagsystem not config, redDotId:" .. redDotId)
      return
    end
    return funConfig.param
  end
end

function RedDotManager:GetStateById(redDotId, redDotType, param)
  local funConfig = configManager.GetDataById("config_flagsystem", redDotId)
  if funConfig == nil then
    logError("config_flagsystem not config, redDotId:" .. redDotId)
    return
  end
  local funcOpenId = funConfig.function_open
  if funcOpenId then
    for i, v in pairs(funcOpenId) do
      if not moduleManager:CheckFunc(tostring(v), false) then
        if redDotType == RedDotType.Normal then
          return false
        else
          return 0
        end
      end
    end
  end
  local config = RedDotConfig[redDotId]
  if not config then
    logError("RedDotConfig not config, redDotId:" .. redDotId)
    return
  end
  return config.func(table.unpack(param))
end

function RedDotManager:RegisterRedDot(page, redDot, ...)
  local param = {
    ...
  }
  local keys = redDot:GetKeys()
  local img = redDot:GetImage().image
  local redDotType = redDot:GetRedDotType()
  local config = configManager.GetDataById("config_flag_res", redDotType)
  if config == nil then
    logError("config_flag_res not config, redDotType:" .. redDotType)
    return
  end
  if img then
    UIHelper.SetImage(img, config.res_path)
  end
  local luaEventTbl = {}
  for i, redDotId in pairs(keys) do
    if redDotId and 0 < redDotId then
      local config = RedDotConfig[redDotId]
      if not config then
        logError("RedDotConfig not config, redDotId:" .. redDotId)
      elseif config.type == REDDOT_PARAM_TYPE.Programmer and #param == 0 then
        logError("\233\156\128\232\166\129\231\168\139\229\186\143\228\188\160\229\143\130\239\188\140\231\168\139\229\186\143\230\178\161\230\156\137\228\188\160\229\143\130, redDotId:" .. redDotId .. " page:" .. page:GetName())
        logError("\233\156\128\232\166\129\231\168\139\229\186\143\228\188\160\229\143\130\239\188\140\231\168\139\229\186\143\230\178\161\230\156\137\228\188\160\229\143\130, redDot:" .. printTable(redDot))
      elseif config.alwaysDirty == true then
        local redDotTime = page:CreateTimer(function()
          self:getStateByRedDot(redDot, param)
        end, 1, -1, false)
        redDotTime:Start()
      else
        for _, eventId in pairs(config.MSG_ID) do
          luaEventTbl[eventId] = true
        end
      end
    end
  end
  local id = redDot:GetId()
  page:UnRegisterRedDotById(id)
  local tg = redDot:GetToggle()
  if tg then
    tg.toggle.onValueChanged:AddListener(function()
      self:getStateByRedDot(redDot, param)
    end)
  end
  for eventId, v in pairs(luaEventTbl) do
    local funcCallback = function()
      self:getStateByRedDot(redDot, param)
    end
    page:RegisterRedDotEvent(id, eventId, funcCallback)
  end
  self:getStateByRedDot(redDot, param)
end

function RedDotManager:RegisterRedDotByParamList(page, redDot, redDotParamList)
  local keys = redDot:GetKeys()
  local img = redDot:GetImage().image
  local redDotType = redDot:GetRedDotType()
  local redDotParamList = redDotParamList or {}
  local config = configManager.GetDataById("config_flag_res", redDotType)
  if config == nil then
    logError("config_flag_res not config, redDotType:" .. redDotType)
    return
  end
  if img then
    UIHelper.SetImage(img, config.res_path)
  end
  local luaEventTbl = {}
  for i, redDotId in pairs(keys) do
    if redDotId and 0 < redDotId then
      local config = RedDotConfig[redDotId]
      local param = redDotParamList[i] or {}
      if not config then
        logError("RedDotConfig not config, redDotId:" .. redDotId)
      elseif config.type == REDDOT_PARAM_TYPE.Programmer and #param == 0 then
        logError("\233\156\128\232\166\129\231\168\139\229\186\143\228\188\160\229\143\130\239\188\140\231\168\139\229\186\143\230\178\161\230\156\137\228\188\160\229\143\130, redDotId:" .. redDotId .. " page:" .. page:GetName())
        logError("\233\156\128\232\166\129\231\168\139\229\186\143\228\188\160\229\143\130\239\188\140\231\168\139\229\186\143\230\178\161\230\156\137\228\188\160\229\143\130, redDot:" .. printTable(redDot))
      elseif config.alwaysDirty == true then
        local redDotTime = page:CreateTimer(function()
          self:getStateByRedDot(redDot, param)
        end, 1, -1, false)
        redDotTime:Start()
      else
        for _, eventId in pairs(config.MSG_ID) do
          luaEventTbl[eventId] = true
        end
      end
    end
  end
  local id = redDot:GetId()
  page:UnRegisterRedDotById(id)
  local tg = redDot:GetToggle()
  if tg then
    tg.toggle.onValueChanged:AddListener(function()
      self:getStateByRedDotParamList(redDot, redDotParamList)
    end)
  end
  for eventId, v in pairs(luaEventTbl) do
    local funcCallback = function()
      self:getStateByRedDotParamList(redDot, redDotParamList)
    end
    page:RegisterRedDotEvent(id, eventId, funcCallback)
  end
  self:getStateByRedDotParamList(redDot, redDotParamList)
end

function RedDotManager:getStateByRedDotParamList(redDot, redDotParamList)
  if IsNil(redDot) then
    return
  end
  local redDotType = redDot:GetRedDotType()
  local config = configManager.GetDataById("config_flag_res", redDotType)
  if config == nil then
    logError("config_flag_res not config, redDotType:" .. redDotType)
    return
  end
  local typ = config.number
  if typ == RedDotType.Normal then
    self:getStateByRedDotNormalParamList(redDot, redDotParamList)
  elseif typ == RedDotType.Number then
    self:getStateByRedDotNumberParamList(redDot, redDotParamList)
  end
end

function RedDotManager:getStateByRedDotNormalParamList(redDot, redDotParamList)
  local keys = redDot:GetKeys()
  local tg = redDot:GetToggle()
  if tg and tg.toggle.isOn then
    redDot.gameObject:SetActive(false)
    return
  end
  local comment = ""
  for i, redDotId in pairs(keys) do
    if redDotId and 0 < redDotId then
      local param = redDotParamList[i] or {}
      param = self:GetParamById(redDotId, param)
      local config = RedDotConfig[redDotId]
      if config.type ~= REDDOT_PARAM_TYPE.Programmer or #param ~= 0 then
        local result = self:GetStateById(redDotId, RedDotType.Normal, param)
        local resultStr = result and "true" or "false"
        comment = comment .. "Id:" .. redDotId
        if param then
          for i, v in pairs(param) do
            comment = comment .. "    " .. "param:" .. tostring(v)
          end
        end
        comment = comment .. "    " .. "result:" .. resultStr .. "#"
        if result then
          redDot.gameObject:SetActive(true)
          redDot:SetComment(comment)
          return
        end
      end
    end
  end
  redDot:SetComment(comment)
  redDot.gameObject:SetActive(false)
end

function RedDotManager:getStateByRedDotNumberParamList(redDot, redDotParamList)
  local keys = redDot:GetKeys()
  local comment = ""
  local result = 0
  for i, redDotId in pairs(keys) do
    if redDotId and 0 < redDotId then
      local param = redDotParamList[i] or {}
      param = self:GetParamById(redDotId, param)
      local config = RedDotConfig[redDotId]
      if config.type ~= REDDOT_PARAM_TYPE.Programmer or #param ~= 0 then
        local num = self:GetStateById(redDotId, RedDotType.Number, param)
        result = result + num
        comment = comment .. "Id:" .. redDotId
        if param then
          for i, v in pairs(param) do
            comment = comment .. "    " .. "param:" .. v
          end
        end
        comment = comment .. "    " .. "num:" .. num .. "#"
      end
    end
  end
  redDot:SetTextByNumber(result)
  redDot:SetComment(comment)
end

return RedDotManager
