local RankPage = class("UI.Activity.RankPage", LuaUIPage)
local MinigameRankPage = require("ui.page.Rank.MinigameRankPage")
local ActivityBossSingleRankPage = require("ui.page.Rank.ActivityBossSingleRankPage")
local ActBossTeamRankPage = require("ui.page.Rank.ActBossTeamRankPage")
local RankPageImp = {
  [RankType.MiniGame] = MinigameRankPage,
  [RankType.ActivityBossSinge] = ActivityBossSingleRankPage,
  [RankType.ActivityBossTeam] = ActBossTeamRankPage
}

function RankPage:DoInit()
end

function RankPage:DoOnOpen()
  self:OpenTopPageNoTitle("RankPage", 1)
  local rankType = self.param.RankType
  self.rankPageImp = RankPageImp[rankType]:new()
  self.rankPageImp:DoOnOpen(self, self.param, self.tab_Widgets)
end

function RankPage:RegisterAllEvent()
end

function RankPage:DoOnHide()
end

function RankPage:DoOnClose()
  self.rankPageImp:UnRegisterAllEvent()
end

return RankPage
