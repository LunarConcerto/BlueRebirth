local ActivityFashionPage = require("ui.page.Activity.SchoolActivity.ActivityFashionPage")
local NewYearFestivalFashionPage = class("ui.page.Activity.NewYearFestivalFashionPage", ActivityFashionPage)

function NewYearFestivalFashionPage:DoInit()
  self.mFashionParts = {
    self.tab_Widgets.luaPart1,
    self.tab_Widgets.luaPart2,
    self.tab_Widgets.luaPart3
  }
end

return NewYearFestivalFashionPage
