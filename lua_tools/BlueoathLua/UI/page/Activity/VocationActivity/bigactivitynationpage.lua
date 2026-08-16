local super = require("ui.page.Activity.ActivityBase.BaseActivityTaskPage")
local BigActivityNationPage = class("ui.page.Activity.VocationActivity.BigActivityNationPage", super)

function BigActivityNationPage:ShowPage()
  super.ShowPage(self)
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textActivityTime, startTimeFormat .. "-" .. endTimeFormat)
end

return BigActivityNationPage
