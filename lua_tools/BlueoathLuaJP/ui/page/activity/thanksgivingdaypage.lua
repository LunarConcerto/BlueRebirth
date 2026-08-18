local ThanksgivingDayPage = class("UI.Activity.ThanksgivingDayPage", LuaUIPage)

function ThanksgivingDayPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.bu_get, self.btnGetReward, self)
end

function ThanksgivingDayPage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self:refreshInfo()
end

function ThanksgivingDayPage:refreshInfo()
  local arrTask = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  self.taskInfo = nil
  if arrTask ~= nil and 0 < #arrTask then
    self.taskInfo = arrTask[1]
  end
  if self.taskInfo == nil then
    self.tab_Widgets.bu_complete:SetActive(false)
    self.tab_Widgets.obj_bu_get:SetActive(false)
  elseif 0 < self.taskInfo.Data.RewardTime then
    self.tab_Widgets.bu_complete:SetActive(true)
    self.tab_Widgets.obj_bu_get:SetActive(false)
  elseif 0 < self.taskInfo.Data.FinishTime then
    self.tab_Widgets.bu_complete:SetActive(false)
    self.tab_Widgets.obj_bu_get:SetActive(true)
    UIHelper.DisableButton(self.tab_Widgets.bu_get, false)
  else
    self.tab_Widgets.bu_complete:SetActive(false)
    self.tab_Widgets.obj_bu_get:SetActive(true)
    UIHelper.DisableButton(self.tab_Widgets.bu_get, true)
  end
end

function ThanksgivingDayPage:DoOnClose()
end

function ThanksgivingDayPage:btnGetReward(go, index)
  local activityConfig = configManager.GetDataById("config_activity", self.activityId)
  if activityConfig.period > 0 and not PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  Service.taskService:SendTaskReward(self.taskInfo.TaskId, TaskType.Activity)
  self:Retention()
end

function ThanksgivingDayPage:Retention()
  local dotinfo = {
    info = "ui_thanksgivingday_get"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function ThanksgivingDayPage:btnInfo(go)
end

function ThanksgivingDayPage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "ThanksgivingDayPage")
  self:refreshInfo()
end

return ThanksgivingDayPage
