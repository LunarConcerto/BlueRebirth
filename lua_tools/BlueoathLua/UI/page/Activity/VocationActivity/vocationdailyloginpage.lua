local super = require("ui.page.Activity.ActivityBase.BaseActivityDailyLoginPage")
local VocationDailyLoginPage = class("ui.page.Activity.VocationActivity.VocationDailyLoginPage", super)

function VocationDailyLoginPage:ShowPage()
  super.ShowPage(self)
  self.tab_Widgets.objNationDay:SetActive(true)
  local activityCfg = configManager.GetDataById("config_activity", self.activityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textNationDayTime, startTimeFormat .. "-" .. endTimeFormat)
  local tabTaskInfo = Logic.taskLogic:GetTaskListByType(TaskType.Activity, self.activityId)
  if tabTaskInfo == nil then
    logError("SignCopyPage tabTaskInfo is nil")
    return
  end
  local theLastInfo = tabTaskInfo[#tabTaskInfo]
  local info = theLastInfo.Data
  local signDays = info.Count
  UIHelper.SetText(self.tab_Widgets.textNationDayLoginDay, signDays)
end

return VocationDailyLoginPage
