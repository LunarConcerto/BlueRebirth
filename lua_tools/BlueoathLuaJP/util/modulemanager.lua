local ModuleManager = class("util.ModuleManager")
local OrAnd = {IsOr = 1, IsAnd = 2}

function ModuleManager:initialize()
  self.openPageOpenModule = nil
  self:_InitTabParam()
  eventManager:RegisterEvent(LuaEvent.LoginOk, self._RecordCanOpenModuleInfo, self)
  eventManager:RegisterEvent(LuaEvent.UserLevelUp, self._UpdateModuleInfo, self)
  eventManager:RegisterEvent(LuaEvent.PassNewCopy, self._UpdateModuleInfo, self)
  eventManager:RegisterEvent(LuaEvent.ShowOpenModule, self._ShowNewModuleOpen, self)
end

function ModuleManager:_InitTabParam()
  self.m_openPageFunc = {
    [FunctionID.Fleet] = self._Fleet,
    [FunctionID.BuildShip] = self._BuildShip,
    [FunctionID.ActPlotCopy] = self._ActCopyPlot,
    [FunctionID.ActSeaCopy] = self._ActCopySea,
    [FunctionID.BuildShipGirl] = self._BuildShipGirl,
    [FunctionID.Guild] = self._GuildEnterCheck,
    [FunctionID.DailyCopy] = self._OpenDailyCopy,
    [FunctionID.Task] = self._OpenTask,
    [FunctionID.Shop] = self._OpenShop,
    [FunctionID.SchoolActivity] = self._OpenSchoolActivity,
    [FunctionID.SeaCopy] = self._OpenSeaCopy,
    [FunctionID.Teaching] = self._OpenTeaching,
    [FunctionID.ActCopy] = self._ActCopy,
    [FunctionID.Activity] = self._OpenActivity,
    [FunctionID.TowerActivity] = self._TowerActivity,
    [FunctionID.MiniGame] = self._MiniGame,
    [FunctionID.PlotCopy] = self._OpenPlotCopy,
    [FunctionID.ActBoss] = self._ActBoss,
    [FunctionID.PlotCopyMainPage] = self._OpenPlotMainCopy,
    [FunctionID.Alchemy] = self._RyzaAlchemy,
    [FunctionID.ActGalgame] = self._OpenActGalgame,
    [FunctionID.DropShipUpActivity] = self._OpenCopyDropUp,
    [FunctionID.PVECopyPage] = self._OpenPveCopyPage,
    [FunctionID.ActSummaryCopy] = self._OpenSeaCopyPageWithActId,
    [FunctionID.ActFoodCompose] = self._FoodComposeByOther,
    [FunctionID.GuildOffer] = self._JumpToGuildOffer
  }
end

FunctionID = {
  Fleet = 1,
  BuildShip = 2,
  Repaire = 4,
  Dock = 5,
  Bag = 6,
  Copy = 7,
  Shop = 8,
  Study = 9,
  Task = 10,
  BathRoom = 11,
  Picture = 12,
  Email = 13,
  Friend = 14,
  Chat = 16,
  Activity = 17,
  Crusade = 18,
  Survey = 19,
  AutoFIght = 20,
  PlotCopy = 21,
  SeaCopy = 22,
  SupportFleet = 23,
  DailyCopy = 24,
  DoubleSpeed = 25,
  TripleSpeed = 26,
  Retire = 29,
  BuildShipGirl = 31,
  Train = 32,
  Strategy = 34,
  TrainLv = 35,
  ActPlotCopy = 36,
  ActSeaCopy = 37,
  Recharge = 38,
  TrainAdv = 39,
  ARKit = 40,
  PlotBarrage = 41,
  TrainBarrage = 42,
  GoodsCopy = 43,
  SkipPlayerSkipSkillAnim = 44,
  SkipEnemySkipSkillAnim = 45,
  SkipShipSkillFeedBack = 46,
  AutoAttak = 47,
  Tower = 51,
  Tactic = 52,
  Guild = 53,
  Fashion = 54,
  Building = 55,
  Illustrate = 57,
  Memory = 58,
  PresetFleet = 59,
  Teaching = 61,
  SchoolActivity = 62,
  VocationActivity = 64,
  ActCopy = 65,
  HERO_Intensity_AddRHero = 66,
  HERO_Intensity_NoTypeMatch = 67,
  Rank = 69,
  TowerActivity = 72,
  ActivityFahion = 74,
  DisplaySetting = 77,
  HERO_Intensity_MORESELECT = 78,
  EquipEffect = 79,
  EquipIllustrate = 90,
  Magazine = 91,
  BattlePass = 92,
  MiniGame = 93,
  RemouldPicture = 94,
  Remould = 96,
  BossCopy = 97,
  MubarCopy = 98,
  PlotCopyMainPage = 99,
  MubarOutpost = 111,
  ActBoss = 112,
  Alchemy = 114,
  LinkedPicture = 115,
  MultiPveEntrance = 116,
  ActGalgame = 117,
  ActGalgameCopy = 118,
  ActGalgameExtra = 119,
  DropShipUpActivity = 120,
  PVECopyPage = 121,
  ActSummaryCopy = 122,
  ActFoodCompose = 123,
  MubarPicture = 125,
  GuildOffer = 126,
  Talent = 127,
  BattlePassActivity = 128
}

function ModuleManager:_MiniGame(nFuncId, ...)
  local arg = {
    ...
  }
  UIHelper.OpenPage("MiniGamePage", {
    copyId = arg[1]
  })
end

function ModuleManager:_RecordCanOpenModuleInfo()
  local tabNoOpenModule = {}
  local config = configManager.GetData("config_function_info")
  for id, conf in pairs(config) do
    if conf.is_open == ModuleStatus.OpenF and not self:_CheckCondition(id, conf.level, conf.copy_id, conf.orAnd == OrAnd.IsAnd) then
      table.insert(tabNoOpenModule, conf)
    end
  end
  Logic.moduleLogic:SetNoOpenModule(tabNoOpenModule)
  Logic.moduleLogic:SetCheckFlg(true)
end

function ModuleManager:_UpdateModuleInfo()
  local tabNoOpenModule = Logic.moduleLogic:GetNoOpenModule()
  if not Logic.moduleLogic:GetCheckFlg() then
    return
  end
  if next(tabNoOpenModule) == nil then
    return
  end
  local newOpenList = {}
  for id, conf in ipairs(tabNoOpenModule) do
    if self:_CheckCondition(id, conf.level, conf.copy_id, conf.orAnd == OrAnd.IsAnd) then
      if conf.is_tanchuang == 1 then
        Logic.moduleLogic:SetNewOpenModule(conf)
      end
      table.remove(tabNoOpenModule, id)
      table.insert(newOpenList, conf)
    end
  end
  if 0 < #newOpenList then
    eventManager:SendEvent(LuaEvent.OpenNewModule, newOpenList)
  end
  self:_ShowNewModuleOpen()
end

function ModuleManager:_CheckCondition(funcId, condLevel, condCopyId, isAnd)
  local userLevel = Data.userData:GetUserLevel()
  if userLevel == nil or condLevel == nil then
    return false
  end
  local levelCondition = condLevel == -1 or condLevel <= userLevel
  local copyCondition = condCopyId == -1
  if condCopyId ~= -1 then
    local cid = Logic.copyLogic:GetChapterIdByCopyId(condCopyId)
    local copyType = Logic.copyLogic:GetChaperConfById(cid).class_type
    local copyInfo
    if copyType == ChapterType.PlotCopy then
      copyInfo = Data.copyData:GetPlotCopyDataCopyId(condCopyId)
    else
      copyInfo = Data.copyData:GetCopyDataByCopyId(condCopyId)
    end
    if copyInfo ~= nil and copyInfo.FirstPassTime > 0 then
      copyCondition = true
    end
  end
  if isAnd then
    return levelCondition and copyCondition
  else
    return levelCondition or copyCondition
  end
end

function ModuleManager:_ShowNewModuleOpen()
  local userIsInBattle = Logic.copyLogic:GetUserCurStatus()
  if userIsInBattle then
    return
  end
  local bInGuide = GR.guideHub:isInGuide()
  if bInGuide then
    return
  end
  local newOpenModule = Logic.moduleLogic:GetNewOpenModule()
  if newOpenModule ~= nil and newOpenModule.open_show_name ~= "" and newOpenModule.is_tanchuang == 1 then
    UIHelper.OpenPage("ModuleOpenPage", newOpenModule)
  end
  Logic.moduleLogic:SetNewOpenModule(nil)
end

function ModuleManager:OpenPageOpenModule()
  return Logic.moduleLogic:GetOpenPageOpenModule()
end

function ModuleManager:SetOpenPageUpdateModule(openModule)
  Logic.moduleLogic:SetOpenPageOpenModule(openModule)
end

function ModuleManager:CheckFuncCanShow(nFuncId)
  local conf = configManager.GetDataById("config_function_info", tostring(nFuncId))
  return Data.userData:GetUserLevel() >= conf.lookLevel
end

function ModuleManager:CheckFunc(nFuncId, isShowTip)
  local conf = configManager.GetDataById("config_function_info", tostring(nFuncId))
  if conf.is_open == ModuleStatus.No_OpenF then
    if isShowTip then
      noticeManager:ShowTip(UIHelper.GetString(920000307))
    end
    return false
  end
  if not self:_CheckCondition(conf.fi_id, conf.level, conf.copy_id, conf.orAnd == OrAnd.IsAnd) then
    if isShowTip then
      noticeManager:ShowTip(conf.comment)
    end
    return false
  end
  return true
end

function ModuleManager:JumpToFunc(nFuncId, ...)
  if self:CheckFunc(nFuncId, true) then
    self:_HandleParam(tonumber(nFuncId), ...)
    return true
  end
  return false
end

function ModuleManager:CloseToFunc(funId)
  funId = tonumber(funId)
  if funId == FunctionID.Fleet or funId == FunctionID.BuildShip or funId == FunctionID.BuildShipGirl then
    eventManager:SendEvent(LuaEvent.CloseLeftPage)
  else
    local config = configManager.GetDataById("config_function_info", tostring(funId))
    UIHelper.ClosePage(config.page_name)
  end
end

function ModuleManager:_HandleParam(nFuncId, ...)
  if self.m_openPageFunc[nFuncId] then
    self.m_openPageFunc[nFuncId](self, nFuncId, ...)
  else
    self:_DefaultHandle(nFuncId, ...)
  end
end

function ModuleManager:_GuildEnterCheck(nFuncId, ...)
  eventManager:SendEvent(LuaEvent.GUILD_ENTER_CHECK)
end

function ModuleManager:_OpenTask(nFuncId, ...)
  Logic.taskLogic:SetModuleIndex(0)
  Logic.taskLogic:SetTaskTagIndex(...)
  self:_DefaultHandle(nFuncId)
end

function ModuleManager:_OpenShop(nFuncId, ...)
  self:_DefaultHandle(nFuncId, {
    shopId = (...)
  })
end

function ModuleManager:_OpenSchoolActivity(nFuncId, ...)
  local pageParam = {
    showType = ActivityPageShowType.School,
    activityId = 26
  }
  UIHelper.OpenPage("ActivityPage", pageParam)
end

function ModuleManager:_OpenActivity(nFuncId, ...)
  local arg = {
    ...
  }
  local isOpen = Logic.activityLogic:CheckActivityOpenById(arg[1])
  if not isOpen then
    noticeManager:ShowTipById(2900003)
    return
  end
  UIHelper.OpenPage("ActivityPage", {
    activityId = arg[1],
    jumpParam = arg
  })
end

function ModuleManager:_TowerActivity(nFuncId, ...)
  local chapterId = Logic.towerActivityLogic:GetTowerActivity()
  if 0 < chapterId then
    local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
    local towerId = chapterConfig.relation_chapter_id
    local chapterTowerConfig = configManager.GetDataById("config_tower_activity", towerId)
    UIHelper.OpenPage(chapterTowerConfig.page_name, {chapterConfig = chapterConfig})
  else
    noticeManager:ShowTipById(2900003)
    return
  end
end

function ModuleManager:_ActBoss(nFuncId, ...)
  local param = {
    FunctionID = FunctionID.ActBoss
  }
  self:_DefaultHandle(nFuncId, param)
end

function ModuleManager:_BuildShip(nFuncId, ...)
  local arg = {
    ...
  }
  if arg and arg[1] and arg[1] > 0 then
    local buildId = arg[1]
    local buildConfig = configManager.GetDataById("config_extract_ship", buildId)
    if not Logic.buildShipLogic:CheckOtherLimit(buildConfig) then
      noticeManager:ShowTipById(1110047)
      return
    end
  end
  local config = configManager.GetDataById("config_function_info", tostring(nFuncId))
  if not UIHelper.IsPageOpen("HomePage") then
    local param = {
      funcId = config.goto_parm[1],
      childParam = (...)
    }
    self:_DefaultHandle(nFuncId, param)
  else
    UIHelper.OpenPage(config.page_name, ...)
  end
end

function ModuleManager:_BuildShipGirl(nFuncId, ...)
  local config = configManager.GetDataById("config_function_info", tostring(nFuncId))
  if not UIHelper.IsPageOpen("HomePage") then
    local param = {funcId = nFuncId}
    self:_DefaultHandle(nFuncId, param)
  else
    UIHelper.OpenPage(config.page_name, ...)
  end
end

function ModuleManager:_Fleet(nFuncId, ...)
  local config = configManager.GetDataById("config_function_info", tostring(nFuncId))
  if not UIHelper.IsPageOpen("HomePage") then
    UIHelper.OpenPage("HomePage")
    self:_DefaultHandle(nFuncId, ...)
  else
    self:_DefaultHandle(nFuncId, ...)
  end
end

function ModuleManager:_ActCopyPlot(nFuncId, ...)
  local arg = {
    ...
  }
  local chapterType = arg[1] or 0
  if 0 < chapterType and not Logic.copyChapterLogic:IsOpenByChapterType(chapterType) then
    return
  end
  local config = configManager.GetDataById("config_function_info", tostring(nFuncId))
  local param = {
    index = config.goto_parm[1]
  }
  self:_DefaultHandle(nFuncId, param)
end

function ModuleManager:_ActCopySea(nFuncId, ...)
  local arg = {
    ...
  }
  local copyId = arg[1] or 0
  if 0 < copyId then
    local isCopyOpen = Logic.copyLogic:IsCopyOpenById(copyId)
    if not isCopyOpen then
      noticeManager:ShowTipById(1001008)
      return
    end
  end
  local chapterType = arg[2] or 0
  if 0 < chapterType and not Logic.copyChapterLogic:IsOpenByChapterType(chapterType) then
    return
  end
  local config = configManager.GetDataById("config_function_info", tostring(nFuncId))
  local param = {
    index = config.goto_parm[1]
  }
  self:_DefaultHandle(nFuncId, param)
end

function ModuleManager:_ActCopy(nFuncId, ...)
  if not Logic.activityLogic:IsOpenBigActivity() then
    noticeManager:ShowTipById(270022)
    return
  end
  self:_DefaultHandle(nFuncId)
end

function ModuleManager:_OpenDailyCopy()
  UIHelper.OpenPage("CopyPage", {
    selectCopy = Logic.copyLogic.SelectCopyType.DailyCopy
  })
end

function ModuleManager:_OpenSeaCopy()
  if not Logic.fleetLogic:IsHasFleet() then
    noticeManager:ShowMsgBox(110007)
    return
  end
  UIHelper.OpenPage("CopyPage", {
    selectCopy = Logic.copyLogic.SelectCopyType.SeaCopy
  })
end

function ModuleManager:_OpenPlotMainCopy()
  if not Logic.fleetLogic:IsHasFleet() then
    noticeManager:ShowMsgBox(110007)
    return
  end
  UIHelper.OpenPage("CopyPage", {
    selectCopy = Logic.copyLogic.SelectCopyType.PlotMainCopy
  })
end

function ModuleManager:_OpenPlotCopy()
  if not Logic.fleetLogic:IsHasFleet() then
    noticeManager:ShowMsgBox(110007)
    return
  end
  UIHelper.OpenPage("CopyPage", {
    selectCopy = Logic.copyLogic.SelectCopyType.PlotCopy
  })
end

function ModuleManager:_OpenTeaching()
  if UIHelper.IsPageOpen("FriendPage") then
    self:_DefaultHandle(FunctionID.Teaching)
  else
    moduleManager:JumpToFunc(FunctionID.Friend, {
      selectTog = FriendList.Teaching
    })
  end
end

function ModuleManager:_RyzaAlchemy(nFuncId, ...)
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.RyzaAlchrmy)
  if activityId ~= nil and 0 < activityId then
    local InterItemBagId = configManager.GetDataById("config_activity", activityId).p1[2]
    if InterItemBagId ~= nil and 0 < InterItemBagId then
      local ownedItem = Data.interactionItemData:GetInteractionBagItemData()
      local isHave = ownedItem[InterItemBagId] ~= nil
      if not isHave then
        noticeManager:ShowMsgBox(4700031)
        return
      end
    end
    local param = {
      FunctionID = FunctionID.Alchemy,
      ItemId = (...)
    }
    self:_DefaultHandle(nFuncId, param)
  else
    noticeManager:ShowMsgBox(270016)
    return
  end
end

function ModuleManager:_OpenActGalgame(nFuncId, ...)
  local arg = {
    ...
  }
  local actid = arg[1] or 0
  local param = {
    FunctionID = FunctionID.ActGalgame,
    activityId = actid
  }
  self:_DefaultHandle(nFuncId, param)
end

function ModuleManager:_OpenCopyDropUp(nFuncId, ...)
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.ActDropShipUp)
  if activityId ~= nil and 0 < activityId then
    local dropUpConf = configManager.GetDataById("config_activity", activityId)
    local heroIdTab = dropUpConf.p1
    local dropRateTab = dropUpConf.p2
    local copyTab = dropUpConf.p3
    if #heroIdTab ~= #dropRateTab or #heroIdTab ~= #copyTab or #dropRateTab ~= #copyTab then
      logError("activity\232\161\168\229\137\175\230\156\172\230\142\137\232\144\189\233\153\144\230\151\182up\230\180\187\229\138\168\229\143\130\230\149\176\228\184\141\229\175\185\239\188\140activityId:%d", activityId)
      return
    end
    local param = {
      heroIdTab = heroIdTab,
      dropRateTab = dropRateTab,
      copyTab = copyTab,
      activityId = activityId
    }
    UIHelper.OpenPage("CopyDropUpPage", param)
  else
    noticeManager:ShowMsgBox(270016)
    return
  end
end

function ModuleManager:_OpenPveCopyPage(nFuncId, ...)
  local funcOpen = self:CheckFunc(nFuncId, true)
  if funcOpen then
    local uid = Data.userData:GetUserUid()
    PlayerPrefs.SetInt(uid .. "NewCopyButtomIndex", 4)
    UIHelper.OpenPage("CopyPage")
  end
end

function ModuleManager:_OpenSeaCopyPageWithActId(nFuncId, ...)
  local arg = {
    ...
  }
  local actid = arg[1] or 0
  UIHelper.OpenPage("SeaCopyPage", {nil, actid})
end

function ModuleManager:_FoodComposeByOther(nFuncId, ...)
  local arg = {
    ...
  }
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.FoodCompose)
  if activityId ~= nil and 0 < activityId then
    local config = configManager.GetDataById("config_function_info", tostring(nFuncId))
    local fpageName = config.page_name2
    local param = {
      activityId = activityId,
      subPage = config.page_name
    }
    if UIPageManager:IsExistPage(fpageName) then
      UIHelper.OpenPage(config.page_name, param)
    else
      UIHelper.OpenPage(fpageName, param)
    end
  else
    noticeManager:ShowMsgBox(270016)
    return
  end
end

function ModuleManager:_JumpToGuildOffer(nFuncId, ...)
  local arg = {
    ...
  }
  if Data.guildData:inGuild() then
    UIHelper.OpenPage("GuildPage", {Tog = 5})
  else
    noticeManager:ShowMsgBox(3700052)
    return
  end
end

function ModuleManager:_DefaultHandle(nFuncId, ...)
  local config = configManager.GetDataById("config_function_info", tostring(nFuncId))
  local handleParam = {
    ...
  }
  if 0 < #handleParam then
    UIHelper.OpenPage(config.page_name2, ...)
  else
    local gotoParam = config.goto_parm
    if gotoParam ~= nil and 0 < #gotoParam then
      UIHelper.OpenPage(config.page_name2, {GotoParam = gotoParam})
    else
      UIHelper.OpenPage(config.page_name2, ...)
    end
  end
end

function ModuleManager:GetFunctionTitle(nFuncId)
  local config = configManager.GetDataById("config_function_info", tostring(nFuncId))
  return config.name
end

return ModuleManager
