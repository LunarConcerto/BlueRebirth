local LevelDetailsPage = class("UI.Copy.LevelDetailsPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local levelFleetPage = require("ui.page.copy.levelFleetPage")
local levelFleetItem = require("ui.page.copy.LevelFleetItem")
local Finish_Color = Color.New(0.2549019607843137, 0.47843137254901963, 0.8901960784313725, 255)
local Defult_Color = Color.New(0.4588235294117647, 0.49411764705882355, 0.5607843137254902, 255)
local StarStatus = {
  1,
  2,
  4
}
local commonCopy = require("ui.page.Copy.CommonCopyLevelDetailPage")
local dailyCopy = require("ui.page.Copy.DailyCopyLevelDetailPage")
local bossCopy = require("ui.page.BossCopy.BossCopyLevelDetailPage")
local CopyTypeTable = {
  [CopyType.COMMONCOPY] = commonCopy,
  [CopyType.DAILYCOPY] = dailyCopy,
  [CopyType.BOSS] = bossCopy
}
local matchStateImg = {
  [1] = "uipic_ui_pvematchbtn_1",
  [2] = "uipic_ui_pvematchbtn_2"
}
local LeftTogUnActiveImgMap = {
  [true] = "uipic_ui_copy_bu_anniu_weixuanzhong",
  [false] = "uipic_ui_copy_bu_zhiyuananniu"
}
local MiddleTogType = {
  Recommend = "Recommend",
  Fast = "Fast",
  First = "First",
  Evaluate = "Evaluate",
  AtkGrad = "AtkGrad",
  Explain = "Explain",
  BossBattle = "BossBattle"
}
local MiddleTogList = {
  [1] = {
    {
      131004,
      MiddleTogType.Recommend
    },
    {
      131007,
      MiddleTogType.Fast
    },
    {
      131006,
      MiddleTogType.First
    },
    {
      131008,
      MiddleTogType.Evaluate
    }
  },
  [2] = {
    {
      131003,
      MiddleTogType.Explain
    },
    {
      131004,
      MiddleTogType.Recommend
    },
    {
      131007,
      MiddleTogType.Fast
    },
    {
      131006,
      MiddleTogType.First
    },
    {
      131008,
      MiddleTogType.Evaluate
    }
  },
  [3] = {
    {
      131006,
      MiddleTogType.First
    },
    {
      131009,
      MiddleTogType.AtkGrad
    }
  },
  [4] = {
    {
      131004,
      MiddleTogType.Recommend
    }
  },
  [5] = {},
  [6] = {
    {
      131003,
      MiddleTogType.Explain
    }
  },
  [10] = {
    {
      4300015,
      MiddleTogType.BossBattle
    }
  }
}
local ButtonTogMap = {
  [ButtomTogType.OUTPUT] = 1300003,
  [ButtomTogType.LLEQUIP] = 1300004,
  [ButtomTogType.KILLBOSS] = 4300004
}

function LevelDetailsPage:DoInit()
  self.m_desConfInfo = nil
  self.tabSerData = nil
  self.m_tabFleetData = nil
  self.callBackType = nil
  self.userGoldData = 0
  self.nBattleFleedId = 1
  self.nToggleIndex = 0
  self.nCopyId = 0
  self.nChapterId = 0
  self.bIsRunning = false
  self.togTabPart = {}
  self.mRecordInfo = {}
  self.assistShipIds = {}
  self.m_safeStageId = 0
  self.m_displayConfig = nil
  self.m_fleetType = FleetType.Normal
  self.HeroInfoCallBack = {
    autoRepaireCallBack = self.AutoRepaireCallBack,
    autoSupplyCallBack = self.AutoSupplyCallBack
  }
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_popObj = nil
  self.m_popShip = nil
  self.m_clickPos = nil
  self.m_rectTranArr = {}
  self.m_fleetCardItem = {}
  self.lastPos = nil
  self.isClickCard = true
  self.m_bNeedSave = false
  self.m_chapterType = 0
  self.m_chapterConfig = nil
  self.m_fleetType = 1
  self.m_battleMode = BattleMode.Normal
  self.m_isGoodsCopy = false
  Data.copyData:SetMatchingState(false)
  self.timerIndex = 0
end

function LevelDetailsPage:DoOnOpen()
  self:_ShowPageRoot(true)
  self.userGoldData = Data.userData:GetCurrency(CurrencyType.GOLD)
  self.copyType = self.param.copyType
  self.nCopyId = self.param.copyId
  self.nChapterId = self.param.chapterId
  self.m_battleMode = self.param.battleMode or BattleMode.Normal
  local copy_display_config = configManager.GetDataById("config_copy_display", self.nCopyId)
  if copy_display_config and copy_display_config.is_match == 1 then
    self.m_battleMode = BattleMode.Match
  end
  self.m_displayConfig = Logic.copyLogic:GetCopyDesConfig(self.nCopyId)
  self.m_safeStageId = self.m_displayConfig.stageid
  self.isBossPlot = self.param and self.param.isBossPlot or false
  self.m_isGoodsCopy = Logic.goodsCopyLogic:IsGoodsCopyLogic(self.nCopyId)
  self.m_chapterConfig = configManager.GetDataById("config_chapter", self.nChapterId)
  self.m_isWalkDog = self.m_chapterConfig.class_type == ChapterType.WalkDog
  self.m_isEquipTest = self.m_chapterConfig.class_type == ChapterType.EquipTestCopy
  SoundManager.Instance:PlayMusic(self.m_chapterConfig.leveldetailsbgm)
  self.m_fleetType = self.m_chapterConfig.tactic_type
  local data = Data.fleetData:GetFleetData(self.m_fleetType)
  self.m_tabFleetData = clone(data)
  self.copyImp = CopyTypeTable[self.copyType]:new()
  self.copyImp:Init(self, self.param, self.m_tabWidgets)
  self.copyImp:UpdateInfo()
  self:_InitNpcAssist()
  self:_IsShowMood()
  self.copyImp:CreateFleet()
  levelFleetPage:Init(self, self.m_fleetType)
  self.m_tabWidgets.tog_repaire.isOn = Logic.copyLogic:GetAutoRepaireInfo()
  self:_ClickTogRepaire()
  local isEnter = Logic.copyLogic:GetEnterLevelInfo()
  if isEnter then
    local dotinfo = {
      info = "ui_copy_details"
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  end
  if self.copyType == CopyType.COMMONCOPY then
    Logic.copyLogic:CachCurFirstTime(self.param.tabSerData.FirstPassTime)
  end
  self:RequireRandomFactors()
  self:_SafeArea()
  self:SetGameLimitDesc()
  self:_ShowExercisesPart()
  self:_CheckActTowerBindEquips()
  self:ShowMatchState()
end

function LevelDetailsPage:_RegisterRecordToggle()
  self.m_tabWidgets.tog_group:ClearToggles()
  local tabTogs = {}
  if self.m_fleetType == FleetType.Normal then
    if self.m_isGoodsCopy then
      tabTogs = MiddleTogList[4]
    elseif self.m_chapterConfig.class_type == ChapterType.Teach and self.m_desConfInfo.checkpoint_instructions ~= 0 then
      tabTogs = MiddleTogList[6]
    elseif self.m_desConfInfo.checkpoint_instructions ~= 0 then
      tabTogs = MiddleTogList[2]
    elseif self.m_chapterConfig.class_type == ChapterType.BossCopy then
      local bossData = Data.copyData:GetBossInfo()
      if Logic.bossCopyLogic:GetBossCopyStage(self.isBossPlot) == BossStage.ActBattleBoss then
        tabTogs = MiddleTogList[10]
      else
        tabTogs = MiddleTogList[4]
      end
    else
      tabTogs = MiddleTogList[1]
    end
  elseif self.m_fleetType == FleetType.LimitTower then
    tabTogs = MiddleTogList[5]
  else
    tabTogs = MiddleTogList[3]
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_togItem, self.m_tabWidgets.trans_display, #tabTogs, function(nIndex, tabPart)
    tabPart.txt_name.text = UIHelper.GetString(tabTogs[nIndex][1])
    self.tab_Widgets.tog_group:RegisterToggle(tabPart.tog_all)
    local blue = nIndex == 1 and "uipic_ui_clearrecord_bu_01" or "uipic_ui_clearrecord_bu_02"
    local yellow = nIndex == 1 and "uipic_ui_clearrecord_bu_01_xuanzhong" or "uipic_ui_clearrecord_bu_02_xuanzhong"
    UIHelper.SetImage(tabPart.img_blue, blue)
    UIHelper.SetImage(tabPart.img_yellow, yellow)
    if tabTogs[nIndex][2] == MiddleTogType.Evaluate and self.m_desConfInfo.evaluation_instructions == "" then
      tabPart.tog_all.gameObject:SetActive(false)
    else
      tabPart.tog_all.gameObject:SetActive(true)
    end
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_group, self, tabTogs, self._RecordTogs)
end

function LevelDetailsPage:_RegisterButtomTog()
  local widgets = self:GetWidgets()
  widgets.togg_buttom:ClearToggles()
  local togs = self.copyImp:SetBottomTog()
  local ok = Logic.equipLogic:HaveLLEquip(self.nCopyId)
  if ok then
    table.insert(togs, ButtomTogType.LLEQUIP)
  end
  local togwidgets = {}
  UIHelper.CreateSubPart(widgets.obj_buttomtog, widgets.trans_buttomtog, #togs, function(index, tabPart)
    UIHelper.SetText(tabPart.txt_name, UIHelper.GetString(ButtonTogMap[togs[index]]))
    widgets.togg_buttom:RegisterToggle(tabPart.tog_all)
    togwidgets[index] = tabPart.tog_all
    local blue = index == 1 and "uipic_ui_clearrecord_bu_01" or "uipic_ui_clearrecord_bu_02"
    local yellow = index == 1 and "uipic_ui_clearrecord_bu_01_xuanzhong" or "uipic_ui_clearrecord_bu_02_xuanzhong"
    UIHelper.SetImage(tabPart.img_blue, blue)
    UIHelper.SetImage(tabPart.img_yellow, yellow)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.togg_buttom, self, togs, self._SwitchButtom)
  togwidgets[1].isOn = true
end

function LevelDetailsPage:_SwitchButtom(index, param)
  local tag = param[index + 1]
  local widgets = self:GetWidgets()
  widgets.obj_output:SetActive(tag == ButtomTogType.OUTPUT or tag == ButtomTogType.KILLBOSS)
  widgets.obj_llequip:SetActive(tag == ButtomTogType.LLEQUIP)
  if tag == ButtomTogType.LLEQUIP then
    self:_ShowLLEquips()
  elseif tag == ButtomTogType.KILLBOSS then
    self.copyImp:CreateKillBossReward()
  elseif tag == ButtomTogType.OUTPUT then
    self.copyImp:_CreateDropItem()
  end
end

function LevelDetailsPage:_ShowLLEquips()
  local widgets = self:GetWidgets()
  local _, equips = Logic.equipLogic:HaveLLEquip(self.nCopyId)
  UIHelper.CreateSubPart(widgets.obj_llequipitem, widgets.trans_llequipitem, #equips, function(index, tabPart)
    local temp = {
      Type = GoodsType.EQUIP,
      ConfigId = equips[index],
      Num = 0
    }
    local item = CommonRewardItem:new()
    item:Init(index, temp, tabPart)
    UGUIEventListener.AddButtonOnClick(tabPart.img_frame, self._ShowItemInfo, self, temp)
  end)
end

function LevelDetailsPage:_ShowExercisesPart()
  local needCurrencyInfo = configManager.GetDataById("config_currency", CurrencyType.EXERCISES)
  local tabParam = {isShow = true, CurrencyInfo = needCurrencyInfo}
  eventManager:SendEvent(LuaEvent.TopAddItem, tabParam)
  self.m_tabWidgets.obj_exercises:SetActive(self.m_displayConfig.exercises_point ~= -1)
end

function LevelDetailsPage:ShowMatchState()
  self.m_isMatching = self:GetMatchingState()
  if self.m_battleMode == BattleMode.Match then
    self.m_tabWidgets.bg_autobattle:SetActive(false)
    self.m_tabWidgets.bg_pve:SetActive(true)
    UIHelper.SetText(self.m_tabWidgets.tx_pve_time, UIHelper.GetCountDownStr(0))
    self:SetMatchBtnChangeByMS(self.m_isMatching)
    if self.m_isMatching then
      self:StopTimer(self.matchTimer)
      self.matchTimer = nil
      Data.copyData:SetMatchingState(false)
      self:SetMatchBtnChangeByMS(self:GetMatchingState())
      self:_AttackConditionOne()
    end
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_pve, function()
      if not self:GetMatchingState() then
        local fleetIsSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(self.nBattleFleedId, FleetType.Normal)
        if fleetIsSweeping then
          logError("Cureent Fleet is sweeping")
          return
        end
        self:_AttackConditionOne()
      else
        self:CancelMatchAndTip()
        return
      end
    end, self)
    self.m_tabWidgets.bu_chuzhenganniu:SetActive(false)
    self.m_tabWidgets.bg_xunlianmoshi:SetActive(false)
  else
    self.m_tabWidgets.bg_autobattle:SetActive(true)
    self.m_tabWidgets.bg_pve:SetActive(false)
    self.m_tabWidgets.bu_chuzhenganniu:SetActive(true)
    self.m_tabWidgets.bg_xunlianmoshi:SetActive(true)
  end
end

function LevelDetailsPage:CancelMatchAndTip()
  Data.copyData:SetMatchingState(false)
  self:SetMatchBtnChangeByMS(false)
  self:StopTimer(self.matchTimer)
  self:LeaveMatch()
  self:ShowTipMsg(6100012)
end

function LevelDetailsPage:ShowTipMsg(msgId)
  local showText = UIHelper.GetString(msgId)
  noticeManager:OpenTipPage(self, showText)
end

function LevelDetailsPage:_JoinMatchRoomSuc()
  self:StopTimer(self.matchTimer)
  self.matchTimer = nil
  self.timerIndex = 0
  self.matchTimer = self:CreateTimer(function()
    self.timerIndex = self.timerIndex + 1
    UIHelper.SetText(self.m_tabWidgets.tx_pve_time, UIHelper.GetCountDownStr(self.timerIndex))
  end, 1, -1, false)
  Data.copyData:SetMatchingState(true)
  self:StartTimer(self.matchTimer)
  self:SetMatchBtnChangeByMS(true)
end

function LevelDetailsPage:_JoinMatchRoomFai()
  noticeManager:OpenTipPage(self, "\229\138\160\229\133\165\230\136\191\233\151\180\229\164\177\232\180\165\239\188\140\232\175\183\233\135\141\230\150\176\229\140\185\233\133\141!")
  Data.copyData:SetMatchingState(false)
  self:SetMatchBtnChangeByMS(false)
  self:StopTimer(self.matchTimer)
  self:LeaveMatch()
end

function LevelDetailsPage:GetMatchingState()
  return Data.copyData:GetMatchingState()
end

function LevelDetailsPage:SetMatchBtnChangeByMS(isMatching)
  self.m_tabWidgets.obj_pve_time:SetActive(isMatching)
  self.m_tabWidgets.img_pvetime:SetActive(isMatching)
  if isMatching then
    UIHelper.SetText(self.m_tabWidgets.tx_pve_time, UIHelper.GetCountDownStr(0))
    UIHelper.SetImage(self.m_tabWidgets.img_pve, "uipic_ui_pvematchbtn_2")
  else
    UIHelper.SetImage(self.m_tabWidgets.img_pve, "uipic_ui_pvematchbtn_1")
  end
end

function LevelDetailsPage:SetMatchTimerByMS(isMatching)
  if isMatching then
    Data.copyData:SetMatchingState(true)
    self.matchTimer = self:CreateTimer(function()
      self.m_tabWidgets.obj_pve_time:SetActive(true)
      self.timerIndex = self.timerIndex + 1
      UIHelper.SetText(self.m_tabWidgets.tx_pve_time, UIHelper.GetCountDownStr(self.timerIndex))
    end, 1, -1, false)
    self:StartTimer(self.matchTimer)
  else
    self:CancelMatchAndTip()
  end
end

function LevelDetailsPage:ToLevelMatch()
  self:CancelMatchAndTip()
end

function LevelDetailsPage:LeaveMatch()
  local arg = {
    uid = Data.userData:GetUserData().Uid
  }
  Service.matchService:SendMatchLeave(arg)
end

function LevelDetailsPage:_ShowPageRoot(isOn)
  local widgets = self:GetWidgets()
  widgets.obj_left:SetActive(isOn)
  widgets.obj_right:SetActive(isOn)
  if isOn then
    self:OpenTopPage("LevelDetailsPage", 1, "\229\133\179\229\141\161\232\175\166\230\131\133", self, true)
  else
    self:CloseTopPage()
  end
end

function LevelDetailsPage:CloseFuc()
  self.m_isMatching = self:GetMatchingState()
  if self.m_isMatching then
    self:CancelMatchAndTip()
  end
  self:CloseTopPage()
  UIHelper.ClosePage("LevelDetailsPage")
end

function LevelDetailsPage:RequireRandomFactors()
  if not table.empty(self.m_displayConfig.random_factor_sets) then
    local copyId = self.nCopyId
    if self.bIsRunning then
      copyId = Logic.copyLogic:GetCopyChaseInfo(self.nChapterId, self.nCopyId)
    end
    Service.copyService:SendGetRandomFactors(copyId)
  end
end

function LevelDetailsPage:_InitNpcAssist()
  npcAssistFleetMgr:Clear()
  self.assistShipIds = npcAssistFleetMgr:CreateNpcShips4UI(self.nCopyId)
  self.hasNpcAssist = npcAssistFleetMgr:CheckNpcAssist(self.nCopyId)
  npcAssistFleetMgr:SetNpcAssist(self.hasNpcAssist)
  if self.hasNpcAssist then
    self.m_tabFleetData = clone(self.m_tabFleetData)
    for index = 1, #self.m_tabFleetData do
      local assistShipIds = clone(self.assistShipIds)
      self.m_tabFleetData[index].heroInfo = npcAssistFleetMgr:ReplaceFirstFleet(self.m_tabFleetData[index].heroInfo, assistShipIds, self.nCopyId)
    end
  end
end

function LevelDetailsPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._InitHeroData)
  self:RegisterEvent(LuaEvent.CopyStartBase, function(handler, ret)
    self:CopyEnter(ret)
  end)
  self:RegisterEvent(LuaEvent.DailyCopyEnter, function(handler, ret)
    self:CopyEnter(ret)
  end)
  self:RegisterEvent(LuaEvent.CopySupply, self._UpdateSupplyNum)
  self:RegisterEvent(LuaEvent.GetRandFactor, self._GetRandFactorCallback)
  self:RegisterEvent(LuaEvent.GetCopyInfo, self._GetCopyInfoCallback)
  self:RegisterEvent(LuaEvent.HomePageOtherPageClose, function()
    levelFleetPage:OnFleetClose()
  end)
  self:RegisterEvent(LuaEvent.SetFleetMsg, function()
    levelFleetPage:OnFleetChange()
  end)
  self:RegisterEvent(LuaEvent.SaveFleet, function()
    levelFleetPage:SetSaveSign()
  end)
  self:RegisterEvent(LuaEvent.FleetOpen, self._ShowPageRoot, self, false)
  self:RegisterEvent(LuaEvent.UpdateTowerInfo, function()
    self.copyImp:CreateFleet()
  end, self)
  self:RegisterEvent(LuaEvent.FleetToBattle, function(handler, ret)
    self:_ClickFleetBattle(ret)
  end, self)
  self:RegisterEvent(LuaEvent.ClickFleetCard, self.ClickFleetCard, self)
  self:RegisterEvent(LuaEvent.UpdateSweepInfo, self._UpdateSweepInfo, self)
  self:RegisterEvent(LuaEvent.UpdateSweepFleetMaxNum, self._CheckMaxSweepFleetNum, self)
  self:RegisterEvent(LuaEvent.MatchSuccess, self.BackMatchSuccess, self)
  self:RegisterEvent(LuaEvent.RefreshMatchState, self.ShowMatchState, self)
  self:RegisterEvent(LuaEvent.ToLevelMatchState, self.ToLevelMatch, self)
  self:RegisterEvent(LuaEvent.MatchPreSuccess, self._JoinMatchRoomSuc, self)
  self:RegisterEvent(LuaEvent.MatchPreFail, self._JoinMatchRoomFai, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_battle, function()
    self:_ClickBattle()
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.tog_repaire, self._ClickTogRepaire, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.obj_randFactor, self._ShowFactorDetail, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_safe, self._ClickSafe, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_exercises, self._ClickExercises, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.bg_autobattle_btn, self.GetNewSweepMaxNum, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_note, self._ClickSweepCopyRule, self)
  self:RegisterEvent(LuaEvent.UpdateMoodHero, self._UpdateMoodHero)
  self:RegisterEvent(LuaEvent.ChooseSafeLvOk, self._SelectSafeLv)
end

function LevelDetailsPage:_GetRandFactorCallback(ret)
  self.m_tabWidgets.obj_randFactor.gameObject:SetActive(#ret.Factors > 0)
  self.m_tabWidgets.obj_rand.gameObject:SetActive(#ret.Factors > 0)
  local copyId = self.nCopyId
  if self.bIsRunning then
    copyId = Logic.copyLogic:GetCopyChaseInfo(self.nChapterId, self.nCopyId)
  end
  Logic.copyLogic:SetRandFactors(copyId, ret)
  self.m_tabWidgets.obj_randFactorSign:SetActive(ret.IsShowTips)
end

function LevelDetailsPage:_ShowFactorDetail()
  self.m_tabWidgets.obj_randFactorSign:SetActive(false)
  local copyId = self.nCopyId
  if self.bIsRunning then
    copyId = Logic.copyLogic:GetCopyChaseInfo(self.nChapterId, self.nCopyId)
  end
  UIHelper.OpenPage("RanFactorDetailsPage", {copyDisplayId = copyId})
end

function LevelDetailsPage:GetBattleFleetId()
  return self.nBattleFleedId
end

function LevelDetailsPage:ModifyDisplayConfig(config, isRunningFight)
  self.m_desConfInfo = config
  self:_RegisterRecordToggle()
  local dispId = Logic.copyLogic:GetSafeEffectDispId(self.nCopyId)
  if not isRunningFight and dispId ~= self.nCopyId then
    self.m_desConfInfo = Logic.copyLogic:GetCopyDesConfig(dispId)
  end
  local chapterConfig = configManager.GetDataById("config_chapter", self.nChapterId)
  if chapterConfig.class_type == ChapterType.SeaCopy and not isRunningFight then
    self.m_tabWidgets.txt_plan.text = UIHelper.GetString(922001)
  else
    self.m_tabWidgets.txt_plan.text = UIHelper.GetString(922000)
  end
  self:DisplayStarRequire(isRunningFight)
  self:_RegisterButtomTog()
end

function LevelDetailsPage:GetDisplayConfig()
  return self.m_desConfInfo
end

function LevelDetailsPage:DisplayStarRequire(isRunningFight)
  if #self.m_desConfInfo.star_require > 0 then
    local notShowStar = isRunningFight or Logic.towerLogic:IsTowerType(self.m_fleetType) or self.m_isGoodsCopy or self.m_desConfInfo.star_require_unlock == 1
    local starNum = notShowStar and 0 or self.param.tabSerData.StarLevel
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_planItem, self.m_tabWidgets.trans_plan, #self.m_desConfInfo.star_require, function(nIndex, tabPart)
      local descId = self.m_desConfInfo.star_require[nIndex]
      tabPart.txt_planDesc.text = configManager.GetDataById("config_evaluate", descId).description
      tabPart.txt_planDesc.color = starNum & StarStatus[nIndex] == StarStatus[nIndex] and Finish_Color or Defult_Color
      local dotImage = starNum & StarStatus[nIndex] == StarStatus[nIndex] and "uipic_ui_copy_im_zuozhanjihua_dian_lanse" or "uipic_ui_copy_im_zuozhanjihua_dian"
      UIHelper.SetImage(tabPart.im_planDot, dotImage, true)
      tabPart.obj_finish:SetActive(starNum & StarStatus[nIndex] == StarStatus[nIndex] and self.copyType ~= CopyType.DAILYCOPY and not self.m_isWalkDog)
    end)
  end
end

function LevelDetailsPage:_ClickTogRepaire()
  if self.m_tabWidgets.tog_repaire.isOn then
    self.m_tabWidgets.im_repaire:SetActive(self.m_tabWidgets.tog_repaire.isOn)
    self.m_tabWidgets.im_norepaire:SetActive(not self.m_tabWidgets.tog_repaire.isOn)
  else
    self.m_tabWidgets.im_norepaire:SetActive(not self.m_tabWidgets.tog_repaire.isOn)
    self.m_tabWidgets.im_repaire:SetActive(self.m_tabWidgets.tog_repaire.isOn)
  end
  Logic.copyLogic:SetAutoRepaireInfo(self.m_tabWidgets.tog_repaire.isOn)
end

function LevelDetailsPage:CreateShowStar(param)
  self.m_tabWidgets.im_oneStar:SetActive(param & 1 == 1)
  self.m_tabWidgets.im_twoStar:SetActive(param & 2 == 2)
  self.m_tabWidgets.im_threeStar:SetActive(param & 4 == 4)
end

function LevelDetailsPage:GetOpenEquipGridNum()
  local tabTemp = {}
  local fleetData = Data.fleetData:GetFleetData()
  local curAttackFleet = fleetData[self.nToggleIndex].heroInfo
  for k, v in ipairs(curAttackFleet) do
    local shipInfo = Data.heroData:GetHeroById(v)
    local openNum = Logic.shipLogic:GetShipOpenEquipNum(shipInfo)
    table.insert(tabTemp, {HeroId = v, EquipGridNum = openNum})
  end
  return tabTemp
end

function LevelDetailsPage:ShowAreaInfo()
  self.m_tabWidgets.txt_areaDescription.text = self.m_desConfInfo.description
  self.m_tabWidgets.txt_dituName.text = self.m_desConfInfo.name
  UIHelper.SetImage(self.m_tabWidgets.im_ditu, self.m_desConfInfo.thumbnail)
  self.m_tabWidgets.txt_fightTime.text = self.m_desConfInfo.battle_time
  self.m_tabWidgets.txt_fightTime.text = Logic.copyLogic:OnNumberInvert(tonumber(self.m_tabWidgets.txt_fightTime.text))
end

function LevelDetailsPage:_InitFleet()
  for index = 1, #self.m_tabFleetData do
    self.m_tabFleetData[index].heroInfo = Logic.fleetLogic:CheckFleetHeroNum(self.nCopyId, self.m_tabFleetData[index].heroInfo)
  end
  self:_SetBgLocks()
  self:_CreateFleetTip()
end

function LevelDetailsPage:_SetBgLocks()
  local totalCount = self.m_displayConfig.assist_fleet_num
  for i = 1, 6 do
    self.m_tabWidgets["trans_cardLock_" .. i]:SetActive(i > totalCount)
  end
end

function LevelDetailsPage:_CreateFleetTip()
  local tog_group = {}
  self.m_tabWidgets.togGp_leftFleetTip:ClearToggles()
  local buttoms = Logic.fleetLogic:GetFleetNum(self.m_fleetType)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_one, self.m_tabWidgets.trans_leftGroup, buttoms, function(nIndex, tabPart)
    table.insert(tog_group, tabPart.tog_item)
    tabPart.txt_num.text = nIndex
    tabPart.txt_numNormal.text = nIndex
    table.insert(self.togTabPart, tabPart)
  end)
  for i, tog in ipairs(tog_group) do
    self.m_tabWidgets.togGp_leftFleetTip:RegisterToggle(tog)
  end
  self:_UnActiveTog()
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.togGp_leftFleetTip, self, " ", self._SwitchFleetTipTogs)
  if self:_SetSelectFleetTip() ~= nil then
    local nShip = 1
    nShip = self:_SetSelectFleetTip()
    self.m_tabWidgets.togGp_leftFleetTip:SetActiveToggleIndex(nShip - 1)
  else
    logError("\232\136\176\233\152\159\228\184\173\230\178\161\230\156\137\232\136\185")
  end
end

function LevelDetailsPage:_UnActiveTog()
  for index = 1, #self.m_tabFleetData do
    if #self.m_tabFleetData[index].heroInfo == 0 then
      self.m_tabWidgets.togGp_leftFleetTip:ResigterToggleUnActive(index - 1, self._StopTog)
    else
      self.m_tabWidgets.togGp_leftFleetTip:RemoveToggleUnActive(index - 1, self._StopTog)
    end
  end
end

function LevelDetailsPage:_StopTog()
  local showText = string.format(UIHelper.GetString(130002))
  noticeManager:OpenTipPage(self, showText)
end

function LevelDetailsPage:_SetSelectFleetTip()
  local nShip = Logic.fleetLogic:GetSelectTog()
  local heroInfo = self.m_tabFleetData[nShip]
  for index = nShip, #self.m_tabFleetData do
    if #self.m_tabFleetData[index].heroInfo > 0 then
      return index
    end
  end
  for index = 1, nShip do
    if #self.m_tabFleetData[index].heroInfo > 0 then
      return index
    end
  end
  return nil
end

function LevelDetailsPage:_SwitchFleetTipTogs(nIndex)
  local fleetIndex = nIndex + 1
  self:_CreateFleetInfo(fleetIndex)
end

function LevelDetailsPage:_CreateFleetInfo(toggeIndex)
  self.nToggleIndex = toggeIndex
  local fleetData = self.m_tabFleetData[toggeIndex]
  npcAssistFleetMgr:SetUIShipIds(fleetData.heroInfo)
  if self.hasNpcAssist then
    npcAssistFleetMgr:SetNpcFleetData(self.m_tabFleetData)
  end
  local widgets = self:GetWidgets()
  local strategyId = fleetData.strategyId
  if strategyId and 0 < strategyId then
    local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
    UIHelper.SetText(widgets.tx_strategy, strategyConfig.strategy_name)
  else
    UIHelper.SetText(widgets.tx_strategy, UIHelper.GetString(980011))
  end
  self.m_rectTranArr = {}
  local tabRepaireShip = {}
  local nLength = #fleetData.heroInfo
  local totalAttack = 0
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_cardFleet, self.m_tabWidgets.trans_cardBg, 6, function(nIndex, tabPart)
    local heroId = 0
    if fleetData.heroInfo[nIndex] ~= nil then
      heroId = fleetData.heroInfo[nIndex]
      local heroData = Data.heroData:GetHeroById(heroId)
      if heroId ~= nil then
        if npcAssistFleetMgr:IsNpcHeroId(heroId) then
          totalAttack = totalAttack + heroData.BattlePower
        else
          local heroAttr = Logic.attrLogic:GetBattlePower(heroId, self.m_fleetType, self.nCopyId)
          totalAttack = totalAttack + heroAttr
        end
      end
    end
    local item = levelFleetItem:new()
    local sweepingInfo, _ = Logic.copyLogic:FleetIsSweepingCopy(self.nToggleIndex, self.m_fleetType)
    if sweepingInfo then
      item:InitItemClickDrag(self, heroId, nIndex, tabPart, self.m_chapterConfig, true, false)
    else
      item:Init(self, heroId, nIndex, tabPart, self.m_chapterConfig)
    end
    self.m_rectTranArr[nIndex] = tabPart.rectTranSelf
    self.m_fleetCardItem[nIndex] = item
    luapart = tabPart.childpart:GetLuaTableParts()
    if not self.isShow then
      luapart.im_mood.gameObject:SetActive(false)
    end
  end)
  self.m_tabWidgets.txt_fightNum.text = totalAttack
  local _, needGold = self:_GetRepaireNum()
  self.m_tabWidgets.txt_repaireNum.text = Mathf.ToInt(needGold)
  local _, expend = self:_GetSupplyNum(fleetData)
  self.m_tabWidgets.txt_supply.text = Mathf.ToInt(math.abs(expend))
  self.nBattleFleedId = self.m_tabFleetData[toggeIndex].modeId
  Logic.fleetLogic:SetSelectTog(self.nBattleFleedId)
  self:ShowSweepBtn()
  self:ShowSweepingCopyInfo()
end

function LevelDetailsPage:_GetRepaireNum()
  local curToggleShip = {}
  local heroInfo = self.m_tabFleetData[self.nToggleIndex].heroInfo
  for k, v in pairs(heroInfo) do
    if not npcAssistFleetMgr:IsNpcHeroId(v) then
      table.insert(curToggleShip, Data.heroData:GetHeroById(v))
    end
  end
  local needRepairShip = Logic.repaireLogic:GetRepairShip(curToggleShip)
  local needGold = Logic.repaireLogic:CalculateNeedAllGold(needRepairShip)
  return needRepairShip, needGold
end

function LevelDetailsPage:_UpdateSupplyNum(m_desConfInfo)
  self.m_desConfInfo = m_desConfInfo
  local _, expend = self:_GetSupplyNum(self.m_tabFleetData[self.nToggleIndex])
  self.m_tabWidgets.txt_supply.text = Mathf.ToInt(math.abs(expend))
end

function LevelDetailsPage:_GetSupplyNum(tabInfo)
  local heroIds = tabInfo.heroInfo
  if #heroIds == 0 then
    return 0, 0
  end
  local arg = {}
  local expend = 0
  local count = #heroIds
  if self.m_battleMode == BattleMode.Memory then
    return count, expend
  end
  local config = Logic.copyLogic:GetCopyDesConfig(self.m_desConfInfo.id).total_supple_num
  expend = config[count]
  return count, expend
end

function LevelDetailsPage:GetCopyIdSupply(arg)
  local config = Logic.copyLogic:GetCopyDesConfig(arg)
  return config.total_supple_num[6]
end

function LevelDetailsPage:_InitHeroData()
  if self.callBackType then
    self.HeroInfoCallBack[self.callBackType](self)
  end
end

function LevelDetailsPage:_RecordAttackBeforeCopyData()
  Logic.copyLogic:RecordAttackBeforeCopyData()
end

function LevelDetailsPage:SetGameLimitDesc()
  if self.m_displayConfig.shiplimit_desc > 0 then
    self.tab_Widgets.obj_condition:SetActive(true)
    UIHelper.SetLocText(self.tab_Widgets.txt_condition, self.m_displayConfig.shiplimit_desc)
  else
    self.tab_Widgets.obj_condition:SetActive(false)
  end
end

function LevelDetailsPage:CheckGameLimit()
  local heroIds = self.m_tabFleetData[self.nToggleIndex].heroInfo
  local limitIds = self.m_displayConfig.ship_limit
  local pass = true
  for k, limitId in pairs(limitIds) do
    if not Logic.gameLimitLogic.CheckConditionById(limitId, self.nToggleIndex) then
      pass = false
      break
    end
  end
  return pass, self.m_displayConfig.shiplimit_desc
end

function LevelDetailsPage:_ClickFleetBattle(battleMode)
  self:_InitNpcAssist()
  self.nToggleIndex = Logic.fleetLogic:GetSelectTog()
  self.nBattleFleedId = self.m_tabFleetData[self.nToggleIndex].modeId
  self:_ClickBattle(battleMode)
end

function LevelDetailsPage:_ClickBattle(battleMode)
  if self.m_battleMode ~= BattleMode.Memory and battleMode ~= BattleMode.Sweep then
    self.m_battleMode = battleMode ~= nil and battleMode or BattleMode.Normal
  end
  levelFleetPage:SaveFleetData()
  local fleetIsSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(self.nBattleFleedId, self.m_fleetType)
  local CopyIsSweeping = Logic.copyLogic:CurrentCopyIsSweeping(self.nCopyId)
  if fleetIsSweeping or CopyIsSweeping then
    local showText = string.format(UIHelper.GetString(960000024))
    noticeManager:OpenTipPage(self, showText)
    return
  end
  if battleMode == BattleMode.Sweep then
    self:StartSweepCopy()
    return
  end
  if self.copyImp and not self.copyImp:CheckTime() then
    return
  end
  levelFleetPage:SaveFleetData()
  if Logic.forbiddenHeroLogic:CheckForbiddenHeroInTab(self.m_tabFleetData[self.nToggleIndex].heroInfo, ForbiddenType.Battle) then
    return
  end
  self:_RecordAttackBeforeCopyData()
  local needRepaireShip, neeGold = self:_GetRepaireNum()
  local tabHeroTid = {}
  for k, v in pairs(needRepaireShip) do
    table.insert(tabHeroTid, v.TemplateId)
  end
  if self.m_chapterConfig.new_ocean_tag == 1 and self.m_battleMode == BattleMode.Normal then
    self:_FullStarsTips()
  else
    self:_PreconditionCheck()
  end
end

function LevelDetailsPage:GetNewSweepMaxNum()
  Service.copyService:GetSweepMaxFleetNum()
end

function LevelDetailsPage:_CheckMaxSweepFleetNum()
  self:CheckSweepCopyInfo()
end

function LevelDetailsPage:_UpdateSweepInfo()
  self:ShowSweepingCopyInfo()
end

function LevelDetailsPage:ShowSweepingCopyInfo()
  local fleetIsSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(self.nBattleFleedId, self.m_fleetType)
  self.m_tabWidgets.obj_autobattle:SetActive(false)
  self.localTimer = {}
  if fleetIsSweeping then
    local timeNow = time.getSvrTime()
    local dispId = Logic.copyLogic:GetSafeEffectDispId(fleetSweepData.copyId)
    self.displayCopyConfig = configManager.GetDataById("config_copy_display", dispId)
    self:SetSweepCopyCountName(self.m_tabWidgets.sweep_times, fleetSweepData)
    self:SweepCopyRemianTime(self.m_tabWidgets.sweep_time, fleetSweepData)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_jumpsweep, function()
      local configInfo, copyType = Logic.copyLogic:GetCopyTypeByChapterId(fleetSweepData.chaperId)
      if copyType ~= 0 then
        if copyType == Logic.copyLogic.SelectCopyType.DailyCopy then
          local groupId = configManager.GetDataById("config_chapter", fleetSweepData.chaperId)
          UIHelper.OpenPage("DailyCopyDetailPage", {
            dailyGroupId = groupId.dailygroup_id
          })
        else
          UIHelper.OpenPage("CopyPage", {
            selectCopy = Logic.copyLogic.SelectCopyType.SeaCopy,
            chapterId = fleetSweepData.chaperId,
            SelectedChapIndex = fleetSweepData.chaperId
          })
        end
      else
        local activityConfig = configManager.GetMultiDataByKeyValue("config_activity", "audobattle_chapter", fleetSweepData.chaperId)
        local openActivityId
        for i = 1, #activityConfig do
          if activityConfig[i].type == 29 and PeriodManager:IsInPeriod(activityConfig[i].period) then
            openActivityId = activityConfig[i].id
          end
        end
        if openActivityId == nil then
          logError("\230\180\187\229\138\168\230\156\137\233\151\174\233\162\152\230\136\150\232\128\133\231\130\185\229\135\187\230\151\182\233\151\180\230\156\137\233\151\174\233\162\152\239\188\140", activityConfig, ",activityid", openActivityId)
          local showText = string.format(UIHelper.GetString(960000024))
          noticeManager:OpenTipPage(self, showText)
        else
          UIHelper.OpenPage("ActivityCopyPage", {activityId = openActivityId})
        end
      end
    end, self)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.sweep_btn_cancel, self._ClickStopSweepOption, self)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.sweep_btn_finish, self._ClickFinishSweepCopy, self)
    self:StopAllTimer()
    local timer = self:CreateTimer(function()
      self:SweepCopyRemianTime(self.m_tabWidgets.sweep_time, fleetSweepData)
    end, 1, -1, false)
    self:StartTimer(timer)
  elseif not self:GetMatchingState() then
    self:StopAllTimer()
  end
  self.m_tabWidgets.obj_autobattle:SetActive(fleetIsSweeping)
end

function LevelDetailsPage:_ClickStopSweepOption()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        self:_ClickFinishSweepCopy()
      end
    end
  }
  noticeManager:ShowMsgBox(UIHelper.GetString(960000029), tabParams)
end

function LevelDetailsPage:SetSweepCopyCountName(txt, data)
  local timeNow = time.getSvrTime()
  if timeNow > data.endTime then
    timeNow = data.endTime
    self.m_tabWidgets.sweep_copyname.text = string.format(UIHelper.GetString(960000028))
    self.m_tabWidgets.sweep_obj_finish:SetActive(true)
    self.m_tabWidgets.sweep_obj_cancel:SetActive(false)
  else
    self.m_tabWidgets.sweep_copyname.text = self.displayCopyConfig.name
    self.m_tabWidgets.sweep_obj_finish:SetActive(false)
    self.m_tabWidgets.sweep_obj_cancel:SetActive(true)
  end
  local passTime = timeNow - data.startTime
  local count, _ = math.modf(passTime / self.displayCopyConfig.autobattle_time)
  txt.text = count .. "/" .. data.sweepCounts
end

function LevelDetailsPage:SweepCopyRemianTime(txt, data)
  local timeNow = time.getSvrTime()
  local duringTime = data.endTime - timeNow
  self:SetSweepCopyCountName(self.m_tabWidgets.sweep_times, data)
  if duringTime < 0 then
    UIHelper.SetText(txt, UIHelper.GetCountDownStr(0))
    self:StopAllTimer()
  else
    local showTime = duringTime % self.displayCopyConfig.autobattle_time
    UIHelper.SetText(txt, UIHelper.GetCountDownStr(showTime))
  end
end

function LevelDetailsPage:_ClickCancelSweepCopy()
  local config = {
    fleetId = self.nBattleFleedId,
    copyId = self.nCopyId,
    sweepCounts = 1
  }
  Service.copyService:StopSweepCopy(config)
end

function LevelDetailsPage:_ClickFinishSweepCopy()
  self:_ClickCancelSweepCopy()
end

function LevelDetailsPage:ShowSweepBtn()
  if self.m_battleMode == BattleMode.Match then
    return
  end
  local isBossActivity = false
  if self.param.isBossPlot ~= nil and self.param.isBossPlot == false then
    isBossActivity = true
  end
  self.m_tabWidgets.bg_autobattle:SetActive(not isBossActivity)
  if not self:CheckUserLevel() then
    UIHelper.SetImage(self.m_tabWidgets.img_autobattle, "uipic_ui_saodanganniu3")
  else
    UIHelper.SetImage(self.m_tabWidgets.img_autobattle, "uipic_ui_saodanganniu1")
  end
end

function LevelDetailsPage:CheckUserLevel()
  local ConfigLevel = configManager.GetDataById("config_function_info", 110).level
  local userLevel = Data.userData:GetUserData().Level
  if ConfigLevel <= userLevel then
    return true
  end
  return false
end

function LevelDetailsPage:ClickSweepBtnCheck()
  local battleMode = self.m_battleMode
  if self.m_battleMode == BattleMode.Exercises then
    battleMode = BattleMode.Normal
  end
  if not self:CheckGameLimitCondition() then
    return
  end
  local showText
  local ships = Data.fleetData:GetShipByFleet(self.nBattleFleedId, battleMode)
  if #ships < 6 then
    showText = string.format(UIHelper.GetString(960000030))
    noticeManager:OpenTipPage(self, showText)
    return false
  end
  local isSafeArea = configManager.GetDataById("config_copy_display", self.nCopyId).stageid
  if isSafeArea == 0 or isSafeArea == nil then
    showText = string.format(UIHelper.GetString(960000033))
    noticeManager:OpenTipPage(self, showText)
    return false
  end
  if not self:CheckUserLevel() then
    showText = string.format(UIHelper.GetString(960000034))
    noticeManager:OpenTipPage(self, showText)
    return false
  end
  if #ships == 6 and isSafeArea ~= 0 then
    local isSafe = Logic.copyLogic:IsSafeArea(self.m_safeStageId, self.param.tabSerData.SfLv, self.param.tabSerData.SfPoint, true)
    if isSafe == false then
      showText = string.format(UIHelper.GetString(960000033))
      noticeManager:OpenTipPage(self, showText)
      return false
    end
  end
  if Logic.copyLogic:CheckDockFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClikAllDock()
        end
      end,
      nameOk = UIHelper.GetString(180029)
    }
    noticeManager:ShowMsgBox(110012, tabParams)
    return false
  end
  if Logic.copyLogic:CheckEquipBagFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClikToEquipPage()
        end
      end
    }
    noticeManager:ShowMsgBox(1000014, tabParams)
    return false
  end
  return true
end

function LevelDetailsPage:_ClickSweepCopyRule()
  UIHelper.OpenPage("HelpPage", {content = 960000020})
end

function LevelDetailsPage:CheckSweepCopyInfo()
  if self:ClickSweepBtnCheck() then
    self:_ClickBattle(BattleMode.Sweep)
  end
end

function LevelDetailsPage:StartSweepCopy()
  local _, expend = self:_GetSupplyNum(self.m_tabFleetData[self.nToggleIndex])
  local cheseId
  if self.bIsRunning then
    cheseId = Logic.copyLogic:GetCopyIdByRunningCopyId(self.nCopyId)
  else
    cheseId = Logic.copyLogic:GetCopyChaseInfo(self.nChapterId, self.nCopyId)
  end
  if cheseId then
    expend = expend + self:GetCopyIdSupply(cheseId)
  end
  local config = {
    SweepCopyCostTime = configManager.GetDataById("config_copy_display", self.nCopyId).autobattle_time,
    SweepCopyTimes = 1,
    SweepCopyCostSupply = expend,
    SweepCopyMaxTimes = 10,
    FleetId = self.nBattleFleedId,
    CopyId = self.nCopyId,
    IsActivityCopy = self.param.IsOpenActivity,
    ChapterId = self.nChapterId
  }
  UIHelper.OpenPage("AutoBattleSelectPage", config)
end

function LevelDetailsPage:CheckGameLimitCondition()
  local checkGameLimit, descId = self:CheckGameLimit()
  if not checkGameLimit then
    logError("checkGameLimit")
    noticeManager:ShowMsgBox(UIHelper.GetLocString(610002, UIHelper.GetLocString(descId)))
    return false
  end
  return true
end

function LevelDetailsPage:_PreconditionCheck()
  self:_RecordAttackBeforeCopyData()
  if not self:CheckGameLimitCondition() then
    return
  end
  local isHasFleet = Logic.fleetLogic:IsHasFleet(self.m_fleetType)
  if not isHasFleet and not self.m_isEquipTest then
    noticeManager:ShowMsgBox(110007)
    return
  end
  if self.m_battleMode == BattleMode.Normal then
    local canSupply = self:_UserSupplyNumIsEnough()
    if canSupply then
      self:AutoSupplyCallBack()
    else
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            self:_OpenBuySupply()
          end
        end
      }
      noticeManager:ShowMsgBox(110036, tabParams)
    end
  else
    self:AutoSupplyCallBack()
  end
end

function LevelDetailsPage:_UserSupplyNumIsEnough()
  local _, expend = self:_GetSupplyNum(self.m_tabFleetData[self.nToggleIndex])
  local supply = Data.userData:GetCurrency(CurrencyType.SUPPLY)
  if expend <= supply then
    return true
  end
  return false
end

function LevelDetailsPage:AutoSupplyCallBack()
  self:_CreateFleetInfo(self.nToggleIndex)
  local isHaveRepaireShip = self:_AutoRepaire()
  if isHaveRepaireShip then
    self.callBackType = "autoRepaireCallBack"
  elseif self.copyImp:CheckBattleCondition() then
    self:_AttackConditionOne()
  end
end

function LevelDetailsPage:_AutoRepaire()
  local isHaveRepaireShip = false
  if not self.m_tabWidgets.tog_repaire.isOn then
    return isHaveRepaireShip
  end
  local tabHero = {}
  local needRepairShip, needGold = self:_GetRepaireNum()
  if 0 < #needRepairShip then
    isHaveRepaireShip = true
    self.userGoldData = Data.userData:GetCurrency(CurrencyType.GOLD)
    if needGold <= self.userGoldData then
      for k, v in pairs(needRepairShip) do
        table.insert(tabHero, v.HeroId)
      end
      Service.repaireService:SendGetRepair(tabHero)
    else
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            self:_OpenBuyGold()
          end
        end
      }
      noticeManager:ShowMsgBox(110035, tabParams)
    end
  end
  return isHaveRepaireShip
end

function LevelDetailsPage:_OpenBuyGold()
  UIHelper.OpenPage("BuyResourcePage", BuyResource.Gold)
end

function LevelDetailsPage:_OpenBuySupply()
  UIHelper.OpenPage("BuyResourcePage", BuyResource.Supply)
end

function LevelDetailsPage:AutoRepaireCallBack()
  self.callBackType = nil
  self:_CreateFleetInfo(self.nToggleIndex)
  if self.copyImp:CheckBattleCondition() then
    self:_AttackConditionOne()
  end
end

function LevelDetailsPage:_AttackConditionOne()
  if not Logic.copyLogic:CheckAnyShips(self.m_tabFleetData[self.nBattleFleedId].heroInfo) and not self.m_isEquipTest then
    noticeManager:OpenTipPage(self, 110007)
    return
  end
  if not self:_CheckTowerCondition() then
    return
  end
  if self.m_battleMode == BattleMode.Normal or self.m_battleMode == BattleMode.Match then
    self:_AttackConditionTwo()
  elseif self.m_battleMode == BattleMode.Exercises then
    self:ClickExercisesBattle()
  elseif self.m_battleMode == BattleMode.Memory then
    self:ClickMemoryBattle()
  end
end

function LevelDetailsPage:_AttackConditionTwo()
  local curFleet = self.m_tabFleetData[self.nBattleFleedId]
  if Logic.copyLogic:CheckFlagShipDamage(curFleet.heroInfo, nil, self.m_fleetType) then
    noticeManager:ShowMsgBox(110011)
  else
    self:_AttackConditionThree()
  end
end

function LevelDetailsPage:_AttackConditionThree()
  if Logic.copyLogic:CheckDockFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClikAllDock()
        end
      end,
      nameOk = UIHelper.GetString(180029)
    }
    noticeManager:ShowMsgBox(110012, tabParams)
  else
    self:_AttackConditionFour()
  end
end

function LevelDetailsPage:_ClikAllDock()
  UIHelper.OpenPage("HeroRetirePage")
end

function LevelDetailsPage:_AttackConditionFour()
  if Logic.copyLogic:CheckEquipBagFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClikToEquipPage()
        end
      end
    }
    noticeManager:ShowMsgBox(1000014, tabParams)
    return
  end
  self:_AttackConditionFive()
end

function LevelDetailsPage:_ClikToEquipPage()
  UIHelper.ClosePage("NoticePage")
  UIHelper.OpenPage("DismantlePage")
end

function LevelDetailsPage:_AttackConditionFive()
  local heroIds = self.m_tabFleetData[self.nToggleIndex].heroInfo
  if Logic.copyLogic:CheckShipSink(heroIds) then
    noticeManager:ShowMsgBox("\232\136\176\233\152\159\228\184\173\230\156\137\230\178\137\230\178\161\230\136\152\229\167\172\239\188\140\230\151\160\230\179\149\229\135\186\229\135\187")
    return
  end
  self:_AttackConditionSix()
end

local TipsId = {
  StrategyApply = 1,
  StrategyUnlock = 2,
  Repair = 4
}
local TipsTable = {
  [1] = {
    tips = 980016,
    playerPrefsKey = PlayerPrefsKey.StrategyApply
  },
  [2] = {
    tips = 980017,
    playerPrefsKey = PlayerPrefsKey.StrategyUnlock
  },
  [4] = {tips = 110013, playerPrefsKey = nil},
  [5] = {tips = 980018, playerPrefsKey = nil},
  [6] = {tips = 980019, playerPrefsKey = nil}
}

function LevelDetailsPage:_IsShowMood(...)
  local chapterConfig = configManager.GetDataById("config_chapter", self.nChapterId)
  local loveInfo = configManager.GetData("config_chapter_type")
  self.isShow = false
  for v, k in pairs(loveInfo) do
    if k.affection_change_sort == chapterConfig.class_type then
      if k.affection_add == 0 then
        self.isShow = false
      else
        self.isShow = true
      end
    end
  end
end

function LevelDetailsPage:_AttackConditionSix()
  if self.isShow then
    local heroIds = self.m_tabFleetData[self.nToggleIndex].heroInfo
    local args = {HeroId = heroIds}
    Service.heroService:_SendBathHero(args)
  else
    self:_AttackConditionSeven()
  end
end

function LevelDetailsPage:_UpdateMoodHero(err)
  local notice_limit_affection_num = configManager.GetDataById("config_parameter", 222).value
  if err == 0 then
    local heroIds = self.m_tabFleetData[self.nToggleIndex].heroInfo
    local args = {HeroId = heroIds}
    local badMood = {}
    local zeroMood = {}
    local tipId = 1500025
    for v, k in pairs(heroIds) do
      if not npcAssistFleetMgr:IsNpcHeroId(k) then
        local moodInfo, moodNum = Logic.marryLogic:GetLoveInfo(k, MarryType.Mood)
        if notice_limit_affection_num > moodNum and 0 < moodNum then
          table.insert(badMood, k)
        elseif moodNum == 0 then
          table.insert(zeroMood, k)
        end
      end
    end
    local str = ""
    if 0 < #zeroMood then
      for v, k in pairs(zeroMood) do
        local shipInfo = Logic.shipLogic:GetShipInfoByHeroId(k)
        local girlInfo = Data.heroData:GetHeroById(k)
        if not npcAssistFleetMgr:IsNpcHeroId(k) then
          if girlInfo.Name ~= "" then
            if v == #zeroMood then
              str = str .. girlInfo.Name
            else
              str = str .. girlInfo.Name .. "\239\188\140"
            end
          elseif v == #zeroMood then
            str = str .. shipInfo.ship_name
          else
            str = str .. shipInfo.ship_name .. "\239\188\140"
          end
        end
      end
      str = string.format(UIHelper.GetString(tipId), str)
      local goBathFun = function()
        moduleManager:JumpToFunc(FunctionID.BathRoom)
      end
      noticeManager:ShowSuperNotice(str, "", false, false, function()
        self:_AttackConditionSeven()
      end, nil, "\229\142\187\230\181\180\229\174\164", goBathFun)
    else
      self:_AttackConditionSeven()
    end
  end
end

function LevelDetailsPage:_AttackConditionSeven()
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(self.nCopyId)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local sum = 0
  local chapterType = chapterConfig.class_type
  local chapterTypeConfig = configManager.GetDataById("config_chapter_type", chapterType)
  if chapterTypeConfig.check_strategy == 1 then
    local isOpen = moduleManager:CheckFunc(FunctionID.Strategy, false)
    local fleetData = self.m_tabFleetData[self.nToggleIndex]
    local strategyId = fleetData.strategyId
    if isOpen and strategyId and 0 < strategyId then
      local fleetType = chapterConfig.tactic_type
      self.m_fleetType = fleetType
      local unLock = Logic.strategyLogic:CheckUnlockByFleet(self.nToggleIndex, fleetType)
      local timePre = PlayerPrefs.GetInt(PlayerPrefsKey.StrategyUnlock .. "Time", 0)
      local isSame = time.isSameDay(timePre, os.time())
      local flag = isSame and PlayerPrefs.GetBool(PlayerPrefsKey.StrategyUnlock, false)
      if not unLock and not flag then
        sum = sum + TipsId.StrategyUnlock
      end
    end
    local timePre = PlayerPrefs.GetInt(PlayerPrefsKey.StrategyApply .. "Time", 0)
    local isSame = time.isSameDay(timePre, os.time())
    local flag = isSame and PlayerPrefs.GetBool(PlayerPrefsKey.StrategyApply, false)
    if isOpen and (not strategyId or strategyId <= 0) and not flag then
      sum = sum + TipsId.StrategyApply
    end
  end
  local heroIds = self.m_tabFleetData[self.nToggleIndex].heroInfo
  if self.m_tabWidgets.tog_repaire.isOn == false and Logic.copyLogic:CheckAnyShipDamage(heroIds, nil, self.m_fleetType) then
    sum = sum + TipsId.Repair
  end
  if 0 < sum then
    local callBackConfirm = function(isOn)
      local playerPrefsKey = TipsTable[sum].playerPrefsKey
      if playerPrefsKey then
        PlayerPrefs.SetBool(playerPrefsKey, isOn)
        PlayerPrefs.SetInt(playerPrefsKey .. "Time", os.time())
      end
      self:_AttackConditionEight()
    end
    local content = UIHelper.GetString(TipsTable[sum].tips)
    local contentTg = UIHelper.GetString(931002)
    local playerPrefsKey = TipsTable[sum].playerPrefsKey
    local tgIsShow = playerPrefsKey ~= nil
    local tgIsON = false
    if playerPrefsKey then
      tgIsON = PlayerPrefs.GetBool(TipsTable[sum].playerPrefsKey, false)
    end
    noticeManager:ShowSuperNotice(content, contentTg, tgIsShow, tgIsON, callBackConfirm)
  else
    self:_AttackConditionEight()
  end
end

function LevelDetailsPage:_AttackConditionEight()
  local heros = self.m_tabFleetData[self.nToggleIndex].heroInfo
  local equips, heroEquips, temp = {}, {}, {}
  for _, heroId in ipairs(heros) do
    temp = Data.heroData:GetEquipsByType(heroId, self.m_fleetType)
    if temp then
      for _, equip in ipairs(temp) do
        if equip.EquipsId > 0 then
          table.insert(equips, equip.EquipsId)
        end
      end
    end
  end
  local check, res = Logic.equipLogic:CheckLLEquipById(self.nCopyId, equips)
  if check then
    local items = {}
    for _, equipId in ipairs(res) do
      local tid = Data.equipData:GetEquipDataById(equipId)
      if tid then
        tid = tid.TemplateId
        table.insert(items, {
          Type = GoodsType.EQUIP,
          ConfigId = tid,
          Num = 0,
          Id = equipId
        })
      end
    end
    local func = function(index)
      if index == 2 then
        self:_ClikOk()
      end
    end
    local param = {
      Tip = UIHelper.GetString(1300005),
      Items = items,
      Func = func
    }
    UIHelper.OpenPage("ItemTipPage", param)
  else
    self:_ClikOk()
  end
end

function LevelDetailsPage:_ClikOk()
  if Logic.towerLogic:IsTowerType(self.m_fleetType) then
    self:_CheckTowerEquip(self.m_fleetType)
  elseif self.m_battleMode == BattleMode.Match then
    self:StartMatchClick()
  else
    self:_StartAttck()
  end
end

function LevelDetailsPage:_CheckTowerEquip()
  if not Logic.towerLogic:GetTowerEquipFlag(self.m_chapterConfig.tactic_type) then
    local callBackConfirm = function(isOn)
      Logic.towerLogic:SetTowerEquipFlag(isOn, self.m_chapterConfig.tactic_type)
      self:_CheckTowerHurt()
    end
    if Logic.towerLogic:CheckTowerEquip(self.m_chapterConfig.tactic_type) then
      local content = UIHelper.GetString(1700055)
      local contentTg = UIHelper.GetString(1700054)
      local tgIsShow = true
      local tgIsON = Logic.towerLogic:GetTowerEquipFlag(self.m_chapterConfig.tactic_type)
      noticeManager:ShowSuperNotice(content, contentTg, tgIsShow, tgIsON, callBackConfirm)
    else
      self:_CheckTowerHurt()
    end
  else
    self:_CheckTowerHurt()
  end
end

function LevelDetailsPage:_CheckTowerHurt()
  if not Logic.towerLogic:GetTowerHurtFlag(self.m_chapterConfig.tactic_type) then
    local callBackConfirm = function(isOn)
      Logic.towerLogic:SetTowerHurtFlag(isOn, self.m_chapterConfig.tactic_type)
      self:_ClikOkTowerCallback()
    end
    if Logic.towerLogic:CheckTowerHurt(self.m_chapterConfig.tactic_type) then
      local content = UIHelper.GetString(1700053)
      local contentTg = UIHelper.GetString(1700054)
      local tgIsShow = true
      local tgIsON = Logic.towerLogic:GetTowerHurtFlag(self.m_chapterConfig.tactic_type)
      noticeManager:ShowSuperNotice(content, contentTg, tgIsShow, tgIsON, callBackConfirm)
    else
      self:_ClikOkTowerCallback()
    end
  else
    self:_ClikOkTowerCallback()
  end
end

function LevelDetailsPage:_ClikOkTowerCallback()
  if self.m_battleMode == BattleMode.Normal then
    UIHelper.OpenPage("TowerLockWarnPage", {
      fleetType = self.m_chapterConfig.tactic_type,
      callback = function()
        self:_StartAttck()
      end
    })
  else
    self:_StartAttck()
  end
end

function LevelDetailsPage:_StartAttck()
  if self.m_battleMode == BattleMode.Match then
    self:StartMatchClick()
    return
  end
  self:RegisterEvent(LuaEvent.CacheDataRet, self._CacheDataRet, self)
  Logic.fleetLogic:SetBattleFleetId(self.nBattleFleedId, self.m_fleetType)
  self.copyImp:StartAttack()
end

function LevelDetailsPage:StartMatchClick()
  Data.copyData:SetMatchingState(true)
  self:UnregisterEvent(LuaEvent.CacheDataRet, self.BackMatchCacheSuccess, self)
  self:RegisterEvent(LuaEvent.CacheDataRet, self.BackMatchCacheSuccess, self)
  Logic.copyLogic:MatchJoinByCopyId(self.nCopyId)
  Logic.fleetLogic:SetBattleFleetId(self.nBattleFleedId, self.m_fleetType)
  self.copyImp:SetMatchTempData()
end

function LevelDetailsPage:BackMatchSuccess(roomId)
  self.m_roomId = roomId
  self.copyImp:StartAttack()
end

function LevelDetailsPage:BackMatchCacheSuccess(cacheId)
  self:UnregisterEvent(LuaEvent.CacheDataRet, self.BackMatchCacheSuccess, self)
  self.m_cacheId = cacheId
  self.copyImp:SendMatchStartBase()
end

function LevelDetailsPage:_CacheDataRet(cacheId)
  self.copyImp:CacheDataRet(cacheId)
end

function LevelDetailsPage:DoOnHide()
  self.m_tabWidgets.togGp_leftFleetTip:ClearToggles()
  self.m_tabWidgets.tog_group:ClearToggles()
end

function LevelDetailsPage:DoOnClose()
  Logic.fleetLogic:SetSelectTog(self.nBattleFleedId)
  self.m_tabWidgets.togGp_leftFleetTip:ClearToggles()
  self.m_tabWidgets.tog_group:ClearToggles()
  levelFleetPage:SaveFleetData()
  if Data.copyData:GetMatchingState() then
    Data.copyData:SetMatchingState(false)
    local arg = {
      uid = Data.userData:GetUserData().Uid
    }
    Service.matchService:SendMatchLeave(arg)
  end
end

function LevelDetailsPage:_ShowItemInfo(go, award)
  Logic.itemLogic:ShowItemInfo(award.Type, award.ConfigId)
end

function LevelDetailsPage:_GetCopyInfoCallback(ret)
  self.mRecordInfo = ret
  self.mRecordInfo.Recommend = Logic.copyLogic:GetCopyRecommend(self.nCopyId)
  self.m_tabWidgets.tog_group:SetActiveToggleIndex(0)
end

function LevelDetailsPage:_RecordTogs(index, param)
  local record = {}
  self:_ResetDisplay()
  local togType = param[index + 1][2]
  if togType == MiddleTogType.Evaluate or togType == MiddleTogType.Explain then
    local evaluateStr = togType == MiddleTogType.Evaluate and self.m_desConfInfo.evaluation_instructions or ""
    local bossStr = togType == MiddleTogType.Explain and UIHelper.GetString(self.m_desConfInfo.checkpoint_instructions) or ""
    UIHelper.SetText(self.m_tabWidgets.txt_score, evaluateStr)
    UIHelper.SetText(self.m_tabWidgets.txt_bossInfo, bossStr)
    self.m_tabWidgets.obj_score:SetActive(true)
    self.m_tabWidgets.obj_bossInfo:SetActive(togType ~= MiddleTogType.Evaluate)
    self.m_tabWidgets.txt_score.gameObject:SetActive(togType == MiddleTogType.Evaluate)
    return
  elseif togType == MiddleTogType.BossBattle then
    self:_SetBossBattle()
    self.m_tabWidgets.obj_bossCopy:SetActive(true)
    return
  else
    record.info = self.mRecordInfo[togType]
  end
  self.m_tabWidgets.obj_noRecord:SetActive(record.info == nil or next(record.info.Tactic) == nil)
  self.m_tabWidgets.obj_record:SetActive(record.info ~= nil and next(record.info.Tactic) ~= nil)
  if record.info ~= nil and next(record.info.Tactic) then
    self:_DisplayRecord(record)
  end
end

function LevelDetailsPage:_ResetDisplay()
  self.m_tabWidgets.obj_noRecord:SetActive(false)
  self.m_tabWidgets.obj_record:SetActive(false)
  self.m_tabWidgets.obj_score:SetActive(false)
  self.m_tabWidgets.obj_bossCopy:SetActive(false)
end

function LevelDetailsPage:_DisplayRecord(record)
  self.m_tabWidgets.obj_base:SetActive(record.info.Uid)
  self.m_tabWidgets.txt_name.text = record.info.Uname == "" and math.tointeger(record.info.Uid) or record.info.Uname
  self.m_tabWidgets.txt_lv.text = record.info.Level and "lv." .. math.tointeger(record.info.Level) or 0
  local mTime = record.info.PassTime and time.getTimeStringFontMinute(record.info.PassTime) or 0
  self.m_tabWidgets.txt_time.text = mTime
  self.m_tabWidgets.txt_strategy.text = record.info.StrategyId ~= 0 and Logic.strategyLogic:GetNameById(record.info.StrategyId) or UIHelper.GetString(980022)
  local fleetInfo = record.info.Tactic
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_fleetItem, self.m_tabWidgets.trans_fleet, #fleetInfo, function(index, tabParts)
    local heroInfo = fleetInfo[index]
    local shipShow = Logic.shipLogic:GetShipShowById(heroInfo.Tid)
    local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.Tid)
    if index == 1 then
      UIHelper.SetImage(tabParts.img_typeBg, "uipic_ui_newfleetpage_bg_qijiandiban")
    end
    UIHelper.SetImage(tabParts.img_type, NewCardShipTypeImg[shipInfo.ship_type])
    UIHelper.SetImage(tabParts.im_icon, tostring(shipShow.ship_icon5))
    UIHelper.SetStar(tabParts.Star, tabParts.StarPrt, heroInfo.AdvLevel)
    UIHelper.SetText(tabParts.tx_lv, "Lv." .. math.tointeger(heroInfo.Level))
    UIHelper.SetImage(tabParts.im_quality, QualityIcon[shipInfo.quality])
    UGUIEventListener.AddButtonOnClick(tabParts.btn_detail, function()
      self:_OnClickRecordFleet(record)
    end)
  end)
end

function LevelDetailsPage:_SetBossBattle()
  local bossCopyInfo, bossConf = Logic.bossCopyLogic:GetActBossInfoByCopyId(self.nCopyId)
  local bossData = Data.copyData:GetBossInfo()
  local battleMaxNum = configManager.GetDataById("config_parameter", 408).value
  local currBattleNum = bossData.AtkCount ~= nil and bossData.AtkCount or 0
  local leftNum = battleMaxNum - currBattleNum
  UIHelper.SetLocText(self.m_tabWidgets.txt_bossLeft, bossConf.leveldetails_id)
  self.m_tabWidgets.txt_bossSum.gameObject:SetActive(false)
end

function LevelDetailsPage:_OnClickRecordFleet(record)
  UIHelper.OpenPage("CopyRecordPage", record)
end

function LevelDetailsPage:OnDragCard(tabPart, shipInfo, clickIndex)
  local isSweeping, _ = Logic.copyLogic:FleetIsSweepingCopy(self.nToggleIndex, self.m_fleetType)
  if isSweeping then
    local showText = string.format(UIHelper.GetString(960000032))
    noticeManager:OpenTipPage(self, showText)
    return
  end
  levelFleetPage:OnDrag(tabPart, shipInfo, clickIndex)
end

function LevelDetailsPage:ClickFleetCard()
  if Logic.towerLogic:IsTowerType(self.m_fleetType) and not Logic.towerLogic:IsCopyAttack(self.nCopyId) then
    noticeManager:ShowTipById(1700038)
    return false
  end
  levelFleetPage:ClickCard()
end

function LevelDetailsPage:DragButtonUp()
  if Logic.towerLogic:IsTowerType(self.m_fleetType) and not Logic.towerLogic:IsCopyAttack(self.nCopyId) then
    noticeManager:ShowTipById(1700038)
    return false
  end
  levelFleetPage:DragButtonUp()
end

function LevelDetailsPage:_SafeArea()
  if self.m_safeStageId == 0 then
    self.m_tabWidgets.obj_slider:SetActive(false)
    return
  end
  self.m_tabWidgets.obj_slider:SetActive(true)
  local config = Logic.copyLogic:GetCurrSafeConfig(self.m_safeStageId, self.param.tabSerData.SfLv, self.param.tabSerData.SfPoint, true)
  self.m_tabWidgets.slider_safe.value = config.sliderValue
  UIHelper.SetTextColor(self.m_tabWidgets.txt_safeName, config.name, config.nameColor)
  UIHelper.SetImage(self.m_tabWidgets.img_slider, config.sliderImage)
  self:RegisterRedDot(self.m_tabWidgets.obj_safeDot, self.param.tabSerData.BaseId)
  self:_SelectSafeLv()
end

function LevelDetailsPage:_SelectSafeLv()
  local copyData = Data.copyData:GetCopyInfoById(self.param.tabSerData.BaseId)
  local selectLv = copyData.SfLvChoose == 0 and self.param.tabSerData.SfLv or copyData.SfLvChoose
  self.m_tabWidgets.obj_difficult:SetActive(self.param.tabSerData.SfLv ~= selectLv)
  local safeConfig = configManager.GetDataById("config_safearea", selectLv)
  UIHelper.SetTextColor(self.m_tabWidgets.txt_currDif, safeConfig.desc, safeConfig.copy_text_color)
end

function LevelDetailsPage:_ClickSafe()
  if not self.param.tabSerData then
    return
  end
  UIHelper.OpenPage("SafeInfoPage", {
    self.m_safeStageId,
    self.param.tabSerData.BaseId,
    true
  })
end

function LevelDetailsPage:CopyEnter(ret)
  local userData = Data.userData:GetUserData()
  if ret.Rid == nil then
    noticeManager:ShowMsgBox("\230\156\141\229\138\161\229\153\168\232\191\148\229\155\158\230\149\176\230\141\174\233\148\153\232\175\175")
    return
  end
  local safeLv = self.m_safeStageId == 0 and 0 or self.param.tabSerData.SfLv
  local safePoint = self.m_safeStageId == 0 and 0 or self.param.tabSerData.SfPoint
  Logic.copyLogic:SetAttackCopyInfo(self.nCopyId, self.bIsRunning, safeLv, safePoint)
  local isStrat = {}
  local SetConditions = {
    1,
    2,
    3,
    4
  }
  local SetQucikConditions = {}
  SetQucikConditions, isStrat = Logic.setLogic:GenSetCondition(self.nCopyId, safeLv)
  Logic.setLogic:SetQuickChallenge(isStrat)
  homeEnvManager:EnterBattle()
  Logic.copyLogic:SetUserEnterBattle(true)
  Logic.copyLogic:SetEnterLevelInfo(false)
end

function LevelDetailsPage:_ClickExercises()
  self:_ClickBattle(BattleMode.Exercises)
end

function LevelDetailsPage:_CheckTowerCondition()
  if not Logic.towerLogic:IsTowerType(self.m_fleetType) then
    return true
  end
  if not Logic.towerLogic:IsCopyAttack(self.nCopyId) then
    noticeManager:ShowTipById(1700038)
    return false
  end
  local minNum = configManager.GetDataById("config_parameter", 211).value
  if minNum > #self.m_tabFleetData[self.nBattleFleedId].heroInfo then
    noticeManager:OpenTipPage(self, 1700033)
    return false
  end
  if self.m_battleMode == BattleMode.Normal then
    local canBattle = Logic.towerLogic:CheckFleetBattleCount(self.m_tabFleetData[self.nBattleFleedId].heroInfo, self.m_chapterConfig)
    return canBattle
  end
  return true
end

function LevelDetailsPage:ClickExercisesBattle()
  local exercisesPoint = Data.userData:GetCurrency(CurrencyType.EXERCISES)
  if exercisesPoint < self.m_displayConfig.exercises_point then
    noticeManager:OpenTipPage(self, 1701001)
    return
  end
  local heroIds = self.m_tabFleetData[self.nToggleIndex].heroInfo
  if Logic.copyLogic:CheckFlagShipDamage(heroIds, nil, self.m_fleetType) then
    noticeManager:ShowMsgBox(110011)
    return
  end
  if Logic.copyLogic:CheckShipSink(heroIds) then
    noticeManager:ShowMsgBox("\232\136\176\233\152\159\228\184\173\230\156\137\230\178\137\230\178\161\230\136\152\229\167\172\239\188\140\230\151\160\230\179\149\229\135\186\229\135\187")
    return
  end
  self:_AttackConditionSeven()
end

function LevelDetailsPage:ClickMemoryBattle()
  local heroIds = self.m_tabFleetData[self.nToggleIndex].heroInfo
  if Logic.copyLogic:CheckFlagShipDamage(heroIds, nil, self.m_fleetType) then
    noticeManager:ShowMsgBox(110011)
    return
  end
  if Logic.copyLogic:CheckShipSink(heroIds) then
    noticeManager:ShowMsgBox("\232\136\176\233\152\159\228\184\173\230\156\137\230\178\137\230\178\161\230\136\152\229\167\172\239\188\140\230\151\160\230\179\149\229\135\186\229\135\187")
    return
  end
  self:_AttackConditionSeven()
end

function LevelDetailsPage:CheckForbiddenHeroInFleet()
  local heroTab = self.m_tabFleetData[self.nToggleIndex].heroInfo
  for _, heroId in pairs(heroTab) do
    local forbidden = Logic.forbiddenHeroLogic:CheckForbiddenInSystem(heroId, ForbiddenType.Battle)
    if forbidden then
      return true
    end
  end
  return false
end

function LevelDetailsPage:_CheckActTowerBindEquips()
  if self.m_fleetType == FleetType.LimitTower and Logic.towerLogic:IfNeedEquipTransplant(FleetType.LimitTower) then
    noticeManager:ShowMsgBox("\231\148\177\228\186\142\229\173\152\229\156\168\231\187\145\229\174\154\232\163\133\229\164\135\239\188\140\229\142\159\231\187\145\229\174\154\232\163\133\229\164\135\233\135\141\231\189\174")
  end
end

return LevelDetailsPage
