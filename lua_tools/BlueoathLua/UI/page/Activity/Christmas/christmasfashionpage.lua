local ActivityFashionPage = require("ui.page.Activity.SchoolActivity.ActivityFashionPage")
local ChristmasFashionPage = class("ui.page.Activity.Christmas.ChristmasFashionPage", ActivityFashionPage)

function ChristmasFashionPage:DoInit()
  self.mFashionParts = {
    self.tab_Widgets.luaPart1,
    self.tab_Widgets.luaPart2
  }
end

function ChristmasFashionPage:ShowPage()
  ActivityFashionPage.ShowPage(self)
  if self.mActivityType == ActivityType.SpecialChristmasFashion then
    local part = self.mFashionParts[1]:GetLuaTableParts()
    UGUIEventListener.ClearBabelButtonEventListener(part.btnGoto)
    UGUIEventListener.AddButtonOnClick(part.btnGoto, function()
      if not Data.activityData:IsActivityOpen(self.mActivityId) then
        noticeManager:ShowTipById(270022)
        return
      end
      UIHelper.OpenPage("ChristmasSalePage")
    end)
    self.tab_Widgets.objSale:SetActive(true)
    local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
    local _, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
    local stopTimer = function()
      if self.mTimer ~= nil then
        self.mTimer:Stop()
        self.mTimer = nil
      end
    end
    local doTimer = function()
      local svrTime = time.getSvrTime()
      local surplusTime = endTime - svrTime
      if surplusTime <= 0 then
        stopTimer()
        UIHelper.SetText(self.tab_Widgets.textLeftTime, "")
      else
        UIHelper.SetText(self.tab_Widgets.textLeftTime, UIHelper.GetCountDownStr(surplusTime))
      end
    end
    stopTimer()
    self.mTimer = self:CreateTimer(function()
      doTimer()
    end, 1, -1)
    self.mTimer:Start()
    doTimer()
  else
    self.tab_Widgets.objSale:SetActive(false)
  end
end

return ChristmasFashionPage
