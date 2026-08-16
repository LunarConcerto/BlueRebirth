local ActivityBattlePage = class("ui.page.Activity.VocationActivity.ActivityBattlePage", LuaUIPage)

function ActivityBattlePage:DoInit()
end

function ActivityBattlePage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function ActivityBattlePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCloseTip, function()
    self.tab_Widgets.objHelp:SetActive(false)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnHelp, function()
    self.tab_Widgets.objHelp:SetActive(true)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnBattle, function()
    if not Data.activityData:IsActivityOpen(self.mActivityId) then
      noticeManager:ShowTipById(270022)
      return
    end
    local isHasFleet = Logic.fleetLogic:IsHasFleet()
    if not isHasFleet then
      noticeManager:OpenTipPage(self, 110007)
      return
    end
    local serverData = Data.copyData:GetWalkDogData()
    local areaConfig = {
      copyType = CopyType.COMMONCOPY,
      tabSerData = serverData,
      chapterId = WalkDogChapterId,
      IsRunningFight = false,
      copyId = serverData.BaseId
    }
    Logic.copyLogic:SetEnterLevelInfo(true)
    UIHelper.OpenPage("LevelDetailsPage", areaConfig)
  end)
end

function ActivityBattlePage:DoOnHide()
end

function ActivityBattlePage:DoOnClose()
end

function ActivityBattlePage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  UIHelper.SetLocText(self.tab_Widgets.textBattleDesc, activityCfg.p7[1])
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textActivityTime, startTimeFormat .. "-" .. endTimeFormat)
  local highSecond = Data.walkDogCopyData:GetMaxLiveTime() or 0
  UIHelper.SetText(self.tab_Widgets.textHighSecond, highSecond)
  local maxKill = Data.walkDogCopyData:GetMaxSingleKill() or 0
  UIHelper.SetText(self.tab_Widgets.textMaxSingleKill, maxKill)
  local maxScore = Data.walkDogCopyData:GetMaxSingleScore() or 0
  UIHelper.SetText(self.tab_Widgets.textMaxSingleScore, maxScore)
end

return ActivityBattlePage
