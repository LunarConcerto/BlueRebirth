local FireSunccess = class("game.guide.kits.torpedoguidestate.FireSunccess", require("game.guide.kits.torpedoguidestate.torpedoguidestatebase"))

function FireSunccess:initialize(objBehaviour, tblConfig, objManager)
  self.tblConfig = tblConfig
  self.tblStates = {}
  self.objManager = objManager
  self.objBehaviour = objBehaviour
  self:buildStates(self.tblConfig.States)
end

function FireSunccess:__onEnter()
  self:startState(1)
end

function FireSunccess:__onLeave()
end

function FireSunccess:onStateDone(nType)
  local nMaxIndex = self:getMaxType()
  if nType < nMaxIndex then
    local nNextKey = nType + 1
    self:startState(nNextKey)
  else
    self:onDone()
  end
end

function FireSunccess:onDone()
  self.objBehaviour:onDone()
end

return FireSunccess
