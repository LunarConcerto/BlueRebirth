local LevelDetailsPage = class("UI.Copy.LevelDetailsPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local levelFleetPage = require("ui.page.Copy.LevelFleetPage")
local levelFleetItem = require("ui.page.Copy.LevelFleetItem")
local levelRecordPart = require("ui.page.Copy.LevelRecordPartPage")
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
  self.openMission = true
  Data.copyData:SetMatchingState(false)
  self.attrHint = nil
  self.isTreatyBattle = false
  self.timerIndex = 0
  self.constTime = 60
  self.m_firstTime = true
  self.lockStateTab = {}
  self.tblHeros = nil
  self.tblFleets = nil
  self.tblBattleHeros = nil
  self.tblBattleFleets = nil
  self.isExHero = false
  self.tblExHeros = {}
  self.isSingleCopy = false
  self.singleCostType = 1
end

function LevelDetailsPage:DoOnOpen()
  self:_ShowPageRoot(true)
  self.userGoldData = Data.userData:GetCurrency(CurrencyType.GOLD)
  self.copyType = self.param.copyType
  self.nCopyId = self.param.copyId
  self.nChapterId = self.param.chapterId
  self.m_battleMode = self.param.battleMode or BattleMode.Normal
  Logic.copyLogic:SetCurCopyId(self.nCopyId)
  local copy_display_config = configManager.GetDataById("config_copy_display", self.nCopyId)
  if copy_display_config and copy_display_config.is_match == 1 then
    self.m_battleMode = BattleMode.Match
  end
  local isLimit = copy_display_config.attached_fleet == nil or copy_display_config.attached_fleet == 0
  self.m_tabWidgets.btn_attached.gameObject:SetActive(not isLimit)
  self.isSingleCopy = copy_display_config.is_match == 3
  self.m_displayConfig = Logic.copyLogic:GetCopyDesConfig(self.nCopyId)
  self.m_safeStageId = self.m_displayConfig.stageid
  self.m_isGoodsCopy = Logic.goodsCopyLogic:IsGoodsCopyLogic(self.nCopyId)
  self.m_chapterConfig = configManager.GetDataById("config_chapter", self.nChapterId)
  self.m_isWalkDog = self.m_chapterConfig.class_type == ChapterType.WalkDog
  self.m_isEquipTest = self.m_chapterConfig.class_type == ChapterType.EquipTestCopy
  SoundManager.Instance:PlayMusic(self.m_chapterConfig.leveldetailsbgm)
  self.m_fleetType = self.m_chapterConfig.tactic_type
  self.isTreatyBattle = Logic.dailyCopyLogic:CheckTreatyBattle(self.m_chapterConfig, self.nCopyId)
  local data = Data.fleetData:GetFleetData(self.m_fleetType)
  self.m_tabFleetData = clone(data)
  levelRecordPart:Init(self, self.m_tabWidgets, self.param)
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
  self:_Gateway()
  self:_CheckActTowerBindEquips()
  self:ShowMatchState()
  self.m_tabWidgets.btn_note.gameObject:SetActive(self.m_chapterConfig.class_type ~= ChapterType.MultiPveAct)
  self.m_tabWidgets.tx_biaoti_nvn.gameObject:SetActive(0 < self.m_displayConfig.max_fleet)
  self.m_tabWidgets.tx_biaoti.gameObject:SetActive(0 >= self.m_displayConfig.max_fleet)
  local nvnEnemyFleets = Logic.fleetOrderLogic:GetEnemyFleets(self.nCopyId)
  local str = self.m_displayConfig.max_fleet > #nvnEnemyFleets and #nvnEnemyFleets .. "-" .. self.m_displayConfig.max_fleet or tostring(#nvnEnemyFleets)
  self.m_tabWidgets.tx_biaoti_nvn.text = string.format(UIHelper.GetString(530009), str)
  self.m_tabWidgets.btn_nvn_fleet_order.gameObject:SetActive(0 < self.m_displayConfig.max_fleet and self.m_displayConfig.max_fleet < 5)
  self.m_tabWidgets.win_limit:SetActive(0 < self.m_displayConfig.max_fleet)
  self:ShowSingleCost()
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
  elseif self.m_fleetType == FleetType.GuildWar then
    tabTogs = MiddleTogList[4]
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
  if self.isSingleCopy then
    needCurrencyInfo = configManager.GetDataById("config_currency", CurrencyType.PVEPT)
  end
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
      if self.singleCostType == 0 then
        local canSupply = self:_UserPTNumIsEnough()
        if canSupply then
          self:AutoSupplyCallBack()
        else
          local tabParams = {
            msgType = NoticeType.TwoButton,
            callback = function(bool)
              if bool then
                self:_OpenBuyPT()
              end
            end
          }
          noticeManager:ShowMsgBox(4800116, tabParams)
        end
      else
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
      end
    end
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_pve, function()
      if not self:GetMatchingState() then
        local fleetIsSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(self.nBattleFleedId, FleetType.Normal)
        if fleetIsSweeping then
          logError("Cureent Fleet is sweeping")
          return
        end
        if self.singleCostType == 0 then
          local canSupply = self:_UserPTNumIsEnough()
          if canSupply then
            self:AutoSupplyCallBack()
          else
            local tabParams = {
              msgType = NoticeType.TwoButton,
              callback = function(bool)
                if bool then
                  self:_OpenBuyPT()
                end
              end
            }
            noticeManager:ShowMsgBox(4800116, tabParams)
          end
        else
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
        end
      else
        self:CancelMatchAndTip()
        return
      end
    end, self)
    self.m_tabWidgets.bu_chuzhenganniu:SetActive(false)
    self.m_tabWidgets.bg_xunlianmoshi:SetActive(false)
  else
    self.m_tabWidgets.bg_pve:SetActive(false)
    self.m_tabWidgets.bu_chuzhenganniu:SetActive(true)
    self:_ShowExercisesPart()
    self:ShowSweepBtn()
  end
end

function LevelDetailsPage:CancelMatchAndTip()
  Data.copyData:SetMatchingState(false)
  self:SetMatchBtnChangeByMS(false)
  self:StopTimer(self.matchTimer)
  self:LeaveMatch()
  self:ShowTipMsg(6100013)
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
  noticeManager:OpenTipPage(self, UIHelper.GetString(100036))
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
    self:OpenTopPage("LevelDetailsPage", 1, UIHelper.GetString(920000180), self, true)
    if self.isSingleCopy then
      eventManager:SendEvent(LuaEvent.TopShowPvePt)
    end
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
  self:RegisterEvent(LuaEvent.SetFleetMsg, self._SetRecommendAttr, self)
  self:RegisterEvent(LuaEvent.ClickFleetCard, self.ClickFleetCard, self)
  self:RegisterEvent(LuaEvent.UpdateSweepInfo, self._UpdateSweepInfo, self)
  self:RegisterEvent(LuaEvent.UpdateSweepFleetMaxNum, self._CheckMaxSweepFleetNum, self)
  self:RegisterEvent(LuaEvent.MatchSuccess, self.BackMatchSuccess, self)
  self:RegisterEvent(LuaEvent.RefreshMatchState, self.ShowMatchState, self)
  self:RegisterEvent(LuaEvent.ToLevelMatchState, self.ToLevelMatch, self)
  self:RegisterEvent(LuaEvent.MatchPreSuccess, self._JoinMatchRoomSuc, self)
  self:RegisterEvent(LuaEvent.MatchPreFail, self._JoinMatchRoomFai, self)
  self:RegisterEvent(LuaEvent.GetGuildWarBaseInfo, function(handler, data)
    if self.m_fleetType == FleetType.GuildWar then
      self:UpdateGuildWarPageInfo(data)
    end
  end)
  self:RegisterEvent(LuaEvent.UpdateGuildWarInfo, function(handler, data)
    if self.m_fleetType == FleetType.GuildWar then
      self:UpdateGuildWarTicketInfo()
    end
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_battle, function()
    self:_ClickBattle()
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.tog_repaire, self._ClickTogRepaire, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.obj_randFactor, self._ShowFactorDetail, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_safe, self._ClickSafe, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_exercises, self._ClickExercises, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_mission, self._ClickBattleMission, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_gateeway, self._ClickGateway, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.bg_autobattle_btn, self.GetNewSweepMaxNum, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_note, self._ClickSweepCopyRule, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_nvn_fleet_order, self._ClickNvNFleetOrder, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_attached, self.ClickBtnAttached, self)
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
  local uid = Data.userData:GetUserUid()
  local needShow = true
  for _, factor in pairs(ret.Factors) do
    local setRec = configManager.GetDataById("config_random_factor_set", factor.SetId)
    if setRec.factor_skip == 0 and PlayerPrefs.GetInt(uid .. "factor" .. factor.SetId, 0) == 0 and needShow then
      self:_ShowFactorDetail()
      needShow = false
    end
    PlayerPrefs.SetInt(uid .. "factor" .. factor.SetId, 1)
  end
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
  levelRecordPart:RegisterRecordToggle()
  self:_ShowBattleMission()
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
  local gotowar_num_mub = configManager.GetDataById("config_copy_display", self.nCopyId).gotowar_num_mub
  local mubarStr = UIHelper.GetString(990000004)
  if 0 < gotowar_num_mub then
    mubarStr = string.format(UIHelper.GetString(990000005), gotowar_num_mub)
  end
  UIHelper.SetText(self.m_tabWidgets.tx_mubar_limit, mubarStr)
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
    self.m_tabWidgets.trans_plan.gameObject:SetActive(0 >= self.m_displayConfig.max_fleet)
    self.m_tabWidgets.txt_plan.gameObject:SetActive(0 >= self.m_displayConfig.max_fleet)
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
  local exAttackFleet = fleetData[self.nToggleIndex].exHeroInfo
  for k, v in ipairs(exAttackFleet) do
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
  self:_SetBgLocks()
  self:_CreateFleetTip()
end

function LevelDetailsPage:_SetBgLocks()
  local totalCount = self.m_displayConfig.assist_fleet_num
  if self.isExHero then
    totalCount = 3
  end
  for i = 1, 6 do
    self.lockStateTab[i] = i > totalCount
    self.m_tabWidgets["trans_cardLock_" .. i]:SetActive(i > totalCount)
  end
end

function LevelDetailsPage:_CreateFleetTip()
  local tog_group = {}
  self.m_tabWidgets.togGp_leftFleetTip:ClearToggles()
  local buttoms = Logic.fleetLogic:GetFleetNum(self.m_fleetType)
  local max_fleet = self.m_displayConfig.max_fleet
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_one, self.m_tabWidgets.trans_leftGroup, buttoms, function(nIndex, tabPart)
    table.insert(tog_group, tabPart.tog_item)
    tabPart.txt_num.text = nIndex
    tabPart.txt_numNormal.text = nIndex
    tabPart.im_lockc.color = Color.New(tabPart.im_lockc.color.r, tabPart.im_lockc.color.g, tabPart.im_lockc.color.b, 0)
    tabPart.im_lockx.color = Color.New(tabPart.im_lockx.color.r, tabPart.im_lockx.color.g, tabPart.im_lockx.color.b, 0)
    table.insert(self.togTabPart, tabPart)
    if 0 < max_fleet and nIndex > max_fleet then
      tabPart.txt_num.text = ""
      tabPart.txt_numNormal.text = ""
      tabPart.im_lockc.color = Color.New(tabPart.im_lockc.color.r, tabPart.im_lockc.color.g, tabPart.im_lockc.color.b, 1)
      tabPart.im_lockx.color = Color.New(tabPart.im_lockc.color.r, tabPart.im_lockc.color.g, tabPart.im_lockc.color.b, 1)
    end
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
  self.tblHeros, self.tblFleets, self.tblExHeros = Logic.fleetOrderLogic:GetCopyFleetHeros(self.nCopyId, self.m_tabFleetData, self.nToggleIndex)
  self.nBattleFleedId = self.m_tabFleetData[toggeIndex].modeId
  self.tblBattleHeros, self.tblBattleFleets = Logic.fleetOrderLogic:GetCopyFleetHeros(self.nCopyId, self.m_tabFleetData, self.nBattleFleedId)
  local fleetData = clone(self.m_tabFleetData[toggeIndex])
  fleetData.heroInfo = Logic.fleetLogic:CheckFleetHeroNum(self.nCopyId, fleetData.heroInfo, false)
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
  local cardCount = 0
  local heroLists = {}
  local nameStr = ""
  local countStr = ""
  if self.isExHero then
    cardCount = 3
    heroLists = fleetData.exHeroInfo
    nameStr = UIHelper.GetString(830002)
    countStr = "(" .. #fleetData.heroInfo .. "/6)"
  else
    cardCount = 6
    heroLists = fleetData.heroInfo
    nameStr = UIHelper.GetString(830001)
    countStr = "(" .. #fleetData.exHeroInfo .. "/3)"
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_cardFleet, self.m_tabWidgets.trans_cardBg, cardCount, function(nIndex, tabPart)
    local heroId = 0
    if heroLists[nIndex] ~= nil then
      heroId = heroLists[nIndex]
    end
    local item = levelFleetItem:new()
    local sweepingInfo, _ = Logic.copyLogic:FleetIsSweepingCopy(self.nToggleIndex, self.m_fleetType)
    if sweepingInfo then
      item:InitItemClickDrag(self, heroId, nIndex, tabPart, self.m_chapterConfig, true, false, self.nCopyId, self.isExHero)
    else
      item:Init(self, heroId, nIndex, tabPart, self.m_chapterConfig, self.nCopyId, self.isExHero)
    end
    self.m_rectTranArr[nIndex] = tabPart.rectTranSelf
    self.m_fleetCardItem[nIndex] = item
    local luapart = tabPart.childpart:GetLuaTableParts()
    if not self.isShow then
      luapart.im_mood.gameObject:SetActive(false)
    end
  end)
  self.m_tabWidgets.txt_attachName.text = nameStr
  self.m_tabWidgets.txt_attachNum.text = countStr
  local totalAttack = self:GetTotalAttack(toggeIndex)
  self.m_tabWidgets.txt_fightNum.text = totalAttack
  Logic.copyLogic:SetBBattleAttack(totalAttack)
  local _, needGold = self:_GetRepaireNum()
  self.m_tabWidgets.txt_repaireNum.text = Mathf.ToInt(needGold)
  self:ShowSupply(fleetData)
  self:_SetRecommendAttr()
  Logic.fleetLogic:SetSelectTog(self.nBattleFleedId)
  self:ShowSweepBtn()
  self:ShowSweepingCopyInfo()
  local max_fleet = self.m_displayConfig.max_fleet
  self.m_tabWidgets.im_NvNmask:SetActive(0 < max_fleet and toggeIndex > max_fleet)
end

function LevelDetailsPage:GetTotalAttack(toggeIndex)
  local totalAttack = 0
  local fleetData = clone(self.m_tabFleetData[toggeIndex])
  for i = 1, #fleetData.heroInfo do
    local heroId = fleetData.heroInfo[i]
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
  for i = 1, #fleetData.exHeroInfo do
    local heroId = fleetData.exHeroInfo[i]
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
  return totalAttack
end

function LevelDetailsPage:ShowSupply(fleetData)
  local _, expend = self:_GetSupplyNum(self.tblBattleHeros)
  local maxChallengeCount = 0
  local curChallangeCount = 0
  if self.m_chapterConfig.class_type == ChapterType.GuildWarCopy then
    local guildWarData = Data.guildData:GetGuildWarData()
    if 0 < guildWarData.curChallangeCount then
      curChallangeCount = guildWarData.curChallangeCount
    end
    maxChallengeCount = guildWarData.maxChallengeCount
  end
  local num = Mathf.ToInt(math.abs(expend))
  self.m_tabWidgets.img_supply.gameObject:SetActive(num ~= 0 or self.m_chapterConfig.class_type ~= ChapterType.GuildWarCopy)
  self.m_tabWidgets.txt_supply.text = num
  self.m_tabWidgets.txt_supply.gameObject:SetActive(self.m_chapterConfig.class_type ~= ChapterType.GuildWarCopy)
  self.m_tabWidgets.obj_guildWarCost:SetActive(self.m_chapterConfig.class_type == ChapterType.GuildWarCopy)
  self.m_tabWidgets.txt_guildWarCount.text = curChallangeCount .. "/" .. maxChallengeCount
end

function LevelDetailsPage:_GetRepaireNum()
  local curToggleShip = {}
  local heroInfo = self.tblHeros
  for k, v in pairs(heroInfo) do
    if not npcAssistFleetMgr:IsNpcHeroId(v) then
      table.insert(curToggleShip, Data.heroData:GetHeroById(v))
    end
  end
  local exHeroInfo = self.tblExHeros
  for k, v in pairs(exHeroInfo) do
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
  local _, expend = self:_GetSupplyNum(self.tblBattleHeros)
  self.m_tabWidgets.txt_supply.text = Mathf.ToInt(math.abs(expend))
end

function LevelDetailsPage:_GetSupplyNum(heroIds)
  local heroIds = heroIds
  if #heroIds == 0 then
    return 0, 0
  end
  local expend = 0
  local count = #heroIds
  if 0 < self.m_displayConfig.max_fleet then
    count = 6
  end
  if self.m_battleMode == BattleMode.Memory then
    return count, expend
  end
  local config = Logic.copyLogic:GetCopyDesConfig(self.m_desConfInfo.id)
  if self.m_chapterConfig.new_ocean_tag == 1 and self.param.tabSerData.FirstPassTime ~= 0 then
    expend = 0 < #config.after_clear_supple_num and config.after_clear_supple_num[count] or 0
    return count, expend
  end
  expend = config.total_supple_num[count]
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
  self.tblHeros, self.tblFleets = Logic.fleetOrderLogic:GetCopyFleetHeros(self.nCopyId, self.m_tabFleetData, self.nToggleIndex)
  self.tblBattleHeros, self.tblBattleFleets = Logic.fleetOrderLogic:GetCopyFleetHeros(self.nCopyId, self.m_tabFleetData, self.nBattleFleedId)
  self:_ClickBattle(battleMode)
end

function LevelDetailsPage:_ClickBattle(battleMode)
  Logic.fleetLogic:SetNvNCurEnemyFleetId(0)
  if self.m_battleMode ~= BattleMode.Memory and battleMode ~= BattleMode.Sweep then
    self.m_battleMode = battleMode ~= nil and battleMode or BattleMode.Normal
  end
  levelFleetPage:SaveFleetData()
  local CopyIsSweeping = Logic.copyLogic:CurrentCopyIsSweeping(self.nCopyId)
  if CopyIsSweeping then
    local showText = string.format(UIHelper.GetString(960000024))
    noticeManager:OpenTipPage(self, showText)
    return
  end
  if battleMode == BattleMode.Sweep then
    local fleetIsSweeping, _ = Logic.copyLogic:FleetIsSweepingCopy(self.nBattleFleedId, self.m_fleetType)
    if fleetIsSweeping then
      local showText = string.format(UIHelper.GetString(960000024))
      noticeManager:OpenTipPage(self, showText)
      return
    end
    self:StartSweepCopy()
    return
  end
  if self.copyImp and not self.copyImp:CheckTime() then
    return
  end
  if 0 < self.m_displayConfig.max_fleet then
    local repeated, repeatedHeroList = Logic.fleetOrderLogic:CheckSameHeroInTab(self.tblBattleFleets)
    if repeated then
      local heroNameMsg = ""
      for i, sf_id in pairs(repeatedHeroList) do
        local sf_config = configManager.GetDataById("config_ship_fleet", sf_id)
        local sf_name = sf_config.ship_name
        heroNameMsg = heroNameMsg .. sf_name
        if #repeatedHeroList ~= i then
          heroNameMsg = heroNameMsg .. "\227\128\129"
        end
      end
      noticeManager:ShowTip(string.format(UIHelper.GetString(530001), heroNameMsg))
      return
    end
    local canBattle, errMsg, fleetList, choose = Logic.fleetOrderLogic:GetCanBattleNvN(self.nCopyId)
    if not canBattle then
      if choose then
        local param = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_CheckAfter()
            else
              return
            end
          end
        }
        noticeManager:ShowMsgBox(530002, param)
      else
        if errMsg ~= nil and errMsg ~= "" then
          noticeManager:ShowTip(errMsg)
        end
        return
      end
    else
      self:_CheckAfter()
    end
  else
    self:_CheckAfter()
  end
end

function LevelDetailsPage:_CheckAfter()
  for _, v in pairs(self.tblBattleFleets) do
    local IsSweeping, _ = Logic.copyLogic:FleetIsSweepingCopy(v.modeId, self.m_fleetType)
    if IsSweeping then
      noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(960000024)))
      return
    end
  end
  if Logic.forbiddenHeroLogic:CheckForbiddenHeroInTab(self.tblBattleHeros, ForbiddenType.Battle) then
    return
  end
  local MoreThan, gotowar_num_mub = Logic.forbiddenHeroLogic:CheckForbiddenHeroMubarNum(self.tblBattleHeros, self.nCopyId)
  if MoreThan then
    noticeManager:ShowTip(UIHelper.GetLocString(990000005, gotowar_num_mub))
    return
  end
  if self.m_chapterConfig.new_ocean_tag == 1 and self.m_battleMode == BattleMode.Normal and self.param.tabSerData.StarLevel == 7 then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_PreconditionCheck()
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(920000710), tabParams)
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
  elseif not self:GetMatchingState() and (self.param.pointInfo == nil or self.param.pointInfo.id == nil) then
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
  local isGuildShow = true
  if self.param.showSweepBtn ~= nil then
    isGuildShow = self.param.showSweepBtn
  end
  self.m_tabWidgets.bg_autobattle:SetActive(not isBossActivity and isGuildShow)
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
  if #self.m_desConfInfo.star_require == 0 or self.m_desConfInfo.autobattle_open == 0 then
    showText = UIHelper.GetString(530006)
    noticeManager:OpenTipPage(self, showText)
    return false
  end
  local copy_autobattle_star_limit = configManager.GetDataById("config_parameter", 513).value
  if Data.copyData:StarLevel2Num(self.param.tabSerData.StarLevel) ~= copy_autobattle_star_limit then
    showText = UIHelper.GetString(530007)
    noticeManager:OpenTipPage(self, showText)
    return false
  end
  if not self:CheckUserLevel() then
    showText = string.format(UIHelper.GetString(960000034))
    noticeManager:OpenTipPage(self, showText)
    return false
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
  local strid = 960000020
  if self.m_displayConfig.max_fleet > 0 then
    strid = 530008
  end
  UIHelper.OpenPage("HelpPage", {content = strid})
end

function LevelDetailsPage:_ClickNvNFleetOrder()
  UIHelper.OpenPage("FleetOrderPage", self.param)
end

function LevelDetailsPage:CheckSweepCopyInfo()
  if self:ClickSweepBtnCheck() then
    self:_ClickBattle(BattleMode.Sweep)
  end
end

function LevelDetailsPage:StartSweepCopy()
  local ships = Data.fleetData:GetShipByFleet(self.nBattleFleedId, BattleMode.Normal)
  local _, expend = self:_GetSupplyNum(ships)
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
    if self.singleCostType == 0 then
      local canSupply = self:_UserPTNumIsEnough()
      if canSupply then
        self:AutoSupplyCallBack()
      else
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_OpenBuyPT()
            end
          end
        }
        noticeManager:ShowMsgBox(4800116, tabParams)
      end
    else
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
    end
  else
    self:AutoSupplyCallBack()
  end
end

function LevelDetailsPage:_UserSupplyNumIsEnough()
  local _, expend = self:_GetSupplyNum(self.tblBattleHeros)
  local supply = Data.userData:GetCurrency(CurrencyType.SUPPLY)
  if expend <= supply then
    return true
  end
  return false
end

function LevelDetailsPage:_UserPTNumIsEnough()
  local num = configManager.GetDataById("config_parameter", 527).value
  local supply = Data.userData:GetCurrency(CurrencyType.PVEPT)
  if num <= supply then
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

function LevelDetailsPage:_OpenBuyPT()
  UIHelper.OpenPage("BuyResourcePage", BuyResource.PvePt)
end

function LevelDetailsPage:AutoRepaireCallBack()
  self.callBackType = nil
  local needRepaireShip, _ = self:_GetRepaireNum()
  local tabHeroTid = {}
  for k, v in pairs(needRepaireShip) do
    table.insert(tabHeroTid, v.TemplateId)
  end
  if next(needRepaireShip) ~= nil then
    local repair_name, repair_mainID = Logic.repaireLogic:ReapireRecordData(tabHeroTid)
    local countInfo = {
      time = 0,
      type = 2,
      repair_name = repair_name,
      repair_mainID = repair_mainID
    }
    RetentionHelper.Retention(PlatformDotType.service, countInfo)
  end
  self:_CreateFleetInfo(self.nToggleIndex)
  if self.copyImp:CheckBattleCondition() then
    self:_AttackConditionOne()
  end
end

function LevelDetailsPage:_AttackConditionOne()
  if not Logic.copyLogic:CheckAnyShips(self.tblBattleHeros) and not self.m_isEquipTest then
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
  for _, v in ipairs(self.tblBattleFleets) do
    local curFleet = v
    if Logic.copyLogic:CheckFlagShipDamage(curFleet.heroInfo, nil, self.m_fleetType) then
      noticeManager:ShowMsgBox(110011)
      return
    end
  end
  self:_AttackConditionThree()
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
  local heroIds = self.tblHeros
  if Logic.copyLogic:CheckShipSink(heroIds) then
    noticeManager:ShowMsgBox(UIHelper.GetString(920000183))
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
    local heroIds = self.tblHeros
    local args = {HeroId = heroIds}
    Service.heroService:_SendBathHero(args)
  else
    self:_AttackConditionSeven()
  end
end

function LevelDetailsPage:_UpdateMoodHero(err)
  local notice_limit_affection_num = configManager.GetDataById("config_parameter", 222).value
  if err == 0 then
    local heroIds = self.tblHeros
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
      
      local function goBathFun()
        moduleManager:JumpToFunc(FunctionID.BathRoom)
      end
      
      noticeManager:ShowSuperNotice(str, "", false, false, function()
        self:_AttackConditionSeven()
      end, nil, UIHelper.GetString(920000184), goBathFun)
    else
      self:_AttackConditionSeven()
    end
  end
end

function LevelDetailsPage:_AttackConditionSeven()
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(self.nCopyId)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local openTips = false
  local chapterType = chapterConfig.class_type
  local chapterTypeConfig = configManager.GetDataById("config_chapter_type", chapterType)
  if chapterTypeConfig.check_strategy == 1 then
    local isOpen = moduleManager:CheckFunc(FunctionID.Strategy, false)
    for _, v in ipairs(self.tblBattleFleets) do
      local sum = 0
      local fleetData = v
      local strategyId = fleetData.strategyId
      if isOpen and strategyId and 0 < strategyId then
        local fleetType = chapterConfig.tactic_type
        self.m_fleetType = fleetType
        local unLock = Logic.strategyLogic:CheckUnlockByFleet(v.modeId, fleetType)
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
      if self.m_tabWidgets.tog_repaire.isOn == false and (Logic.copyLogic:CheckAnyShipDamage(v.heroInfo, nil, self.m_fleetType, true) or Logic.copyLogic:CheckAnyShipDamage(v.exHeroInfo, nil, self.m_fleetType, false)) then
        sum = sum + TipsId.Repair
      end
      if 0 < sum then
        do
          local function callBackConfirm(isOn)
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
          openTips = true
        end
      end
    end
  end
  if not openTips then
    self:_AttackConditionEight()
  end
end

function LevelDetailsPage:_AttackConditionEight()
  local heros = self.tblHeros
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
    
    local function func(index)
      if index == 2 then
        self:_CheckFleetHeroNum()
      end
    end
    
    local param = {
      Tip = UIHelper.GetString(1300005),
      Items = items,
      Func = func
    }
    UIHelper.OpenPage("ItemTipPage", param)
  else
    self:_CheckFleetHeroNum()
  end
end

function LevelDetailsPage:_CheckFleetHeroNum()
  local noTipsIdTab = configManager.GetDataById("config_parameter", 342).arrValue
  local tabContain = table.containV(noTipsIdTab, self.nCopyId)
  if self.m_chapterConfig.new_ocean_tag == 1 and not tabContain then
    local more = false
    for _, v in pairs(self.tblBattleFleets) do
      if #v.heroInfo < OneFleetMaxCapacity then
        more = true
        break
      end
    end
    if more then
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            self:_CheckFleetAttr()
          end
        end
      }
      noticeManager:ShowMsgBox(131023, tabParams)
    else
      self:_CheckFleetAttr()
    end
  else
    self:_ClikOk()
  end
end

function LevelDetailsPage:_CheckFleetAttr()
  if self.attrHint ~= nil then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClikOk()
        end
      end
    }
    noticeManager:ShowMsgBox(self.attrHint, tabParams)
    eventManager:SendEvent(LuaEvent.GuideFleetAttr)
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
    local function callBackConfirm(isOn)
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
    local function callBackConfirm(isOn)
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
  if self.m_displayConfig.max_fleet > 0 then
    Logic.fleetLogic:SetBattleNvNFleets(self.tblBattleFleets, self.m_fleetType)
  end
  self.copyImp:StartAttack()
end

function LevelDetailsPage:StartMatchClick()
  Data.copyData:SetMatchingState(true)
  self:UnregisterEvent(LuaEvent.CacheDataRet, self.BackMatchCacheSuccess, self)
  self:RegisterEvent(LuaEvent.CacheDataRet, self.BackMatchCacheSuccess, self)
  local arg = {
    MatchType = Logic.copyLogic:MatchJoinByCopyId(self.nCopyId)
  }
  Service.matchService:SendMatchJoin(arg)
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
  local isPvePtMode = false
  if self.singleCostType == 0 then
    isPvePtMode = true
  end
  self.copyImp:CacheDataRet(cacheId, isPvePtMode)
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
  levelRecordPart:Close()
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
  levelRecordPart:GetCopyInfoCallback(ret)
end

function LevelDetailsPage:_SetRecommendAttr()
  levelRecordPart:SetRecommendAttr()
end

function LevelDetailsPage:OnDragCard(tabPart, shipInfo, clickIndex)
  local isSweeping, _ = Logic.copyLogic:FleetIsSweepingCopy(self.nToggleIndex, self.m_fleetType)
  if isSweeping then
    local showText = string.format(UIHelper.GetString(960000032))
    noticeManager:OpenTipPage(self, showText)
    return
  end
  levelFleetPage:OnDrag(tabPart, shipInfo, clickIndex, self.isExHero)
end

function LevelDetailsPage:ClickFleetCard()
  if Logic.towerLogic:IsTowerType(self.m_fleetType) and not Logic.towerLogic:IsCopyAttack(self.nCopyId) then
    noticeManager:ShowTipById(1700038)
    return false
  end
  levelFleetPage:ClickCard(self.isExHero)
end

function LevelDetailsPage:DragButtonUp()
  if Logic.towerLogic:IsTowerType(self.m_fleetType) and not Logic.towerLogic:IsCopyAttack(self.nCopyId) then
    noticeManager:ShowTipById(1700038)
    return false
  end
  levelFleetPage:DragButtonUp(self.isExHero)
end

function LevelDetailsPage:_SafeArea()
  if self.m_safeStageId == 0 or self.m_chapterConfig.new_ocean_tag == 1 or self.m_desConfInfo.safe_area_hidden == 1 then
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
  local selectLv = 1
  if copyData.SfLvChoose == nil or copyData.SfLvChoose == 0 then
    selectLv = self.param.tabSerData.SfLv or copyData.SfLvChoose
  else
    selectLv = copyData.SfLvChoose
  end
  self.m_tabWidgets.obj_difficult:SetActive(self.param.tabSerData.SfLv ~= selectLv)
  local safeConfig = configManager.GetDataById("config_safearea", selectLv)
  UIHelper.SetTextColor(self.m_tabWidgets.txt_currDif, safeConfig.desc, safeConfig.copy_text_color)
  if self.isTreatyBattle then
    self.m_tabWidgets.obj_difficult:SetActive(false)
    local selectBuff = Logic.dailyCopyLogic:GetSelectBuff().selectBuff
    if #selectBuff ~= 0 then
      local config = Logic.copyLogic:GetCurrSafeConfig(self.m_safeStageId, 1, 0, true)
      self.m_tabWidgets.slider_safe.value = config.sliderValue
      UIHelper.SetTextColor(self.m_tabWidgets.txt_safeName, config.name, config.nameColor)
      UIHelper.SetImage(self.m_tabWidgets.img_slider, config.sliderImage)
    end
  end
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
    noticeManager:ShowMsgBox(UIHelper.GetString(920000185))
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
  Logic.copyLogic:SetUserEnterBattle(true)
  Logic.copyLogic:SetEnterLevelInfo(false)
  homeEnvManager:EnterBattle()
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
  for _, v in ipairs(self.tblFleets) do
    local heroIds = v.heroInfo
    if Logic.copyLogic:CheckFlagShipDamage(heroIds, nil, self.m_fleetType) then
      noticeManager:ShowMsgBox(110011)
      return
    end
    if Logic.copyLogic:CheckShipSink(heroIds) then
      noticeManager:ShowMsgBox(UIHelper.GetString(920000183))
      return
    end
  end
  self:_AttackConditionSeven()
end

function LevelDetailsPage:ClickMemoryBattle()
  for _, v in ipairs(self.tblFleets) do
    local heroIds = v.heroInfo
    if Logic.copyLogic:CheckFlagShipDamage(heroIds, nil, self.m_fleetType) then
      noticeManager:ShowMsgBox(110011)
      return
    end
    if Logic.copyLogic:CheckShipSink(heroIds) then
      noticeManager:ShowMsgBox(UIHelper.GetString(920000183))
      return
    end
  end
  self:_AttackConditionSeven()
end

function LevelDetailsPage:_ShowBattleMission()
  self.m_tabWidgets.obj_battleMission:SetActive(self.m_desConfInfo.mission_display ~= 0)
  if self.m_desConfInfo.mission_display == 0 then
    return
  end
  local missionConf = configManager.GetDataById("config_mission_display", self.m_desConfInfo.mission_display)
  UIHelper.SetLocText(self.m_tabWidgets.txt_missionName, missionConf.name)
  UIHelper.SetLocText(self.m_tabWidgets.txt_missionDesc, missionConf.desc)
end

function LevelDetailsPage:_ClickBattleMission()
  self.m_tabWidgets.obj_mission:SetActive(self.openMission)
  self.openMission = not self.openMission
end

function LevelDetailsPage:_Gateway()
  local id = Logic.copyLogic:GetCopyDesConfig(self.m_desConfInfo.id).copy_demo_id
  self.m_tabWidgets.btn_gateeway.gameObject:SetActive(id ~= 0)
end

function LevelDetailsPage:_ClickGateway(...)
  local id = Logic.copyLogic:GetCopyDesConfig(self.m_desConfInfo.id).copy_demo_id
  UIHelper.OpenPage("GatewaySignPage", id)
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
    noticeManager:ShowMsgBox(6100012)
  end
end

function LevelDetailsPage:CreateGuildWarTimer()
  local timeNow = 0
  self.GuildWartimer = self:CreateTimer(function()
    if timeNow % 10 == 0 then
      Service.guildService:SendGetGuildWarBaseInfo(self.param.pointInfo.id)
    end
    timeNow = timeNow + 1
  end, 1, -1, false)
  self:StartTimer(self.GuildWartimer)
end

function LevelDetailsPage:StopGuildWarTimer()
  if self.GuildWartimer then
    self:StopTimer(self.GuildWartimer)
  end
end

function LevelDetailsPage:UpdateGuildWarPageInfo(data)
  if data.CopyId ~= self.nCopyId then
    self.nCopyId = data.CopyId
    self.m_desConfInfo = Logic.copyLogic:GetCopyDesConfig(self.nCopyId)
    levelRecordPart:Init(self, self.m_tabWidgets, self.param)
  end
  self.copyImp:SetGuildWarInfo(data)
end

function LevelDetailsPage:UpdateGuildWarTicketInfo()
  self.copyImp:SetGuildWarTicketInfo()
end

function LevelDetailsPage:ShowSingleCost()
  if self.isSingleCopy then
    self.m_tabWidgets.txt_supply.gameObject:SetActive(false)
    self.m_tabWidgets.img_supply.gameObject:SetActive(false)
    self.m_tabWidgets.trans_singleCost.gameObject:SetActive(true)
    self.m_tabWidgets.group_singleBase:ClearToggles()
    UIHelper.CreateSubPart(self.tab_Widgets.obj_singleItem, self.tab_Widgets.trans_singleCost, 2, function(index, uiPart)
      self.m_tabWidgets.group_singleBase:RegisterToggle(uiPart.tog_cost)
      if index == 1 then
        local img = Logic.currencyLogic:GetSmallIcon(CurrencyType.PVEPT)
        UIHelper.SetImage(uiPart.img_cost, img)
        local num = configManager.GetDataById("config_parameter", 527).value
        UIHelper.SetText(uiPart.txt_supply, num)
      else
        local img = Logic.currencyLogic:GetSmallIcon(CurrencyType.SUPPLY)
        UIHelper.SetImage(uiPart.img_cost, img)
        local _, expend = self:_GetSupplyNum(self.tblBattleHeros)
        UIHelper.SetText(uiPart.txt_supply, math.abs(expend))
      end
      if index == self.singleCostType + 1 then
        uiPart.tog_cost.isOn = true
      end
    end)
    UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.group_singleBase, self, "", self.SwitchSingleTogs)
    self:SwitchSingleTogs(self.singleCostType)
  else
    local _, expend = self:_GetSupplyNum(self.tblBattleHeros)
    local num = math.abs(expend)
    self.m_tabWidgets.img_supply.gameObject:SetActive(num ~= 0 or self.m_chapterConfig.class_type ~= ChapterType.GuildWarCopy)
    self.m_tabWidgets.txt_supply.gameObject:SetActive(true)
    self.m_tabWidgets.trans_singleCost.gameObject:SetActive(false)
    self.singleCostType = 1
  end
end

function LevelDetailsPage:ClickBtnAttached()
  self.isExHero = not self.isExHero
  self:_SetBgLocks()
  self:_CreateFleetInfo(self.nToggleIndex)
end

function LevelDetailsPage:SwitchSingleTogs(index)
  self.singleCostType = index
end

return LevelDetailsPage
