local super = require("ui.page.Activity.ActivityBase.BaseActivityDailyLoginPage")
local DailyLoginAdventurePage = class("ui.page.Activity.DailyLogin.DailyLoginAdventurePage", super)

function DailyLoginAdventurePage:ShowPage()
  super.ShowPage(self)
  self:ShowTime()
end

return DailyLoginAdventurePage
