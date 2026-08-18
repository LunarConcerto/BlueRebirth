local FireFail = class("game.guide.kits.torpedoguidestate.FireFail", require("game.guide.kits.torpedoguidestate.torpedoguidestatebase"))

function FireFail:initialize(objBehaviour, tblConfig, objManager)
  self.tblConfig = tblConfig
  self.tblStates = {}
  self.objManager = objManager
  self.objBehaviour = objBehaviour
  self:buildStates(self.tblConfig.States)
end

function FireFail:__onEnter()
  self:startState(1)
end

function FireFail:__onLeave()
end

function FireFail:onStateDone(nType)
  local nMaxIndex = self:getMaxType()
  if nType < nMaxIndex then
    local nNextKey = nType + 1
    self:startState(nNextKey)
  else
    self:onDone()
  end
end

function FireFail:onDone()
  self.objManager:enterState(TorpedoState.WaitInRange)
end

return FireFail
