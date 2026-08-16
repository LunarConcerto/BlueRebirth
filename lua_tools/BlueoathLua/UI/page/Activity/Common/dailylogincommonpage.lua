local super = require("ui.page.Activity.ActivityBase.BaseActivityDailyLoginPage")
local DailyLoginCommonPage = class("ui.page.Activity.Common.DailyLoginCommonPage", super)

function DailyLoginCommonPage:ShowPage()
  super.ShowPage(self)
  self:ShowTime()
end

return DailyLoginCommonPage
