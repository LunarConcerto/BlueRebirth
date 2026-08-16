local ActivityWishPage = class("ui.page.Activity.VocationActivity.ActivityWishPage", LuaUIPage)

function ActivityWishPage:DoInit()
end

function ActivityWishPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function ActivityWishPage:RegisterAllEvent()
end

function ActivityWishPage:DoOnHide()
end

function ActivityWishPage:DoOnClose()
end

function ActivityWishPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  UIHelper.SetLocText(self.tab_Widgets.textDesc, activityCfg.p7[1])
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textActivityTime, startTimeFormat .. "-" .. endTimeFormat)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnGoto, function()
    moduleManager:JumpToFunc(FunctionID.Crusade)
  end)
end

return ActivityWishPage
