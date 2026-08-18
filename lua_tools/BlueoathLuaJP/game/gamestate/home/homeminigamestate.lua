local HomeMiniGameState = class("Game.GameState.Home.HomeMiniGameState", require("Game.GameState.GameState"))
local super = HomeMiniGameState.super

function HomeMiniGameState:initialize()
  super.initialize(self)
end

function HomeMiniGameState:registerAllEvents()
end

function HomeMiniGameState:onStart()
  super.onStart(self)
  GameManager2d:InitData()
end

function HomeMiniGameState:onEnd()
  super.onEnd(self)
end

return HomeMiniGameState
