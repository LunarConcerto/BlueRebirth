local super = require("ui.page.Activity.ThanksgivingDayPage")
local LanternFestivalPage = class("ui.page.Activity.Common.LanternFestivalPage", super)

function LanternFestivalPage:refreshInfo()
  local arrTask = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  self.taskInfo = nil
  if arrTask ~= nil and 0 < #arrTask then
    self.taskInfo = arrTask[1]
  end
  if self.taskInfo == nil then
    self.tab_Widgets.bu_complete:SetActive(false)
    self.tab_Widgets.obj_bu_get:SetActive(true)
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

function LanternFestivalPage:btnGetReward(go, index)
  if self.taskInfo then
    local activityConfig = configManager.GetDataById("config_activity", self.activityId)
    if activityConfig.period > 0 and not PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area) then
      noticeManager:ShowTipById(270022)
      return
    end
    Service.taskService:SendTaskReward(self.taskInfo.TaskId, TaskType.Activity)
    self:Retention()
  else
    noticeManager:ShowTipById(7500001)
  end
end

function LanternFestivalPage:Retention()
  local dotinfo = {
    info = "ui_lanternfestival_get"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function LanternFestivalPage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "LanternFestivalPage")
  self:refreshInfo()
end

return LanternFestivalPage
