local GameStateManager = class("game.GameState.GameStateManager")

function GameStateManager:initialize()
  self.curState = nil
  self.mStateMap = {}
  self.mStatePath = nil
end

function GameStateManager:init(statePath)
  self.mStatePath = statePath
end

function GameStateManager:switchState(state, param)
  if state == self.curState then
    return
  end
  local oldState = self.curState and self.mStateMap[self.curState] or nil
  if oldState then
    oldState:onEnd()
  end
  self.curState = state
  local newState = self:__getState(state)
  newState:onStart(param)
end

function GameStateManager:__getState(state)
  local newState = self.mStateMap[state]
  if newState == nil then
    newState = require(self.mStatePath[state]):new()
    self.mStateMap[state] = newState
  end
  return newState
end

return GameStateManager
