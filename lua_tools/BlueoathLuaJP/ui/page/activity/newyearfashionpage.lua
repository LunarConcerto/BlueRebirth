local ActivityFashionPage = require("ui.page.Activity.SchoolActivity.ActivityFashionPage")
local NewYearFashionPage = class("ui.page.Activity.NewYearFashionPage", ActivityFashionPage)

function NewYearFashionPage:DoInit()
  self.mFashionParts = {
    self.tab_Widgets.luaPart1,
    self.tab_Widgets.luaPart2
  }
end

return NewYearFashionPage
