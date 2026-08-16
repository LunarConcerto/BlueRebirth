local HomeStudyState = class("Game.GameState.Home.HomeStudyState", require("Game.GameState.GameState"))
local super = HomeStudyState.super

function HomeStudyState:initialize()
  super.initialize(self)
end

function HomeStudyState:onStart(param)
  super.onStart(self)
end

function HomeStudyState:onEnd()
  super.onEnd(self)
end

return HomeStudyState
