local super = require("ui.page.Activity.ThanksgivingDayPage")
local BabelCelebratePage = class("ui.page.Activity.Common.BabelCelebratePage", super)

function BabelCelebratePage:Retention()
  local dotinfo = {
    info = "ui_babelcelebrate_get"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function BabelCelebratePage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "BabelCelebratePage")
  self:refreshInfo()
end

return BabelCelebratePage
