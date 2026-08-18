local WaitInRange = class("game.guide.kits.torpedoguidestate.WaitInRange", require("game.guide.kits.torpedoguidestate.torpedoguidestatebase"))

function WaitInRange:initialize(objBehaviour, tblConfig, objManager)
  self.tblConfig = tblConfig
  self.tblStates = {}
  self.objManager = objManager
  self.objBehaviour = objBehaviour
  self:buildStates(self.tblConfig.States)
end

function WaitInRange:__onEnter()
  self:startState(1)
end

function WaitInRange:__onLeave()
end

function WaitInRange:onStateDone(nType)
  local nMaxIndex = self:getMaxType()
  if nType < nMaxIndex then
    local nNextKey = nType + 1
    self:startState(nNextKey)
  else
    self:__onInRange()
  end
end

function WaitInRange:__onInRange()
  self.objManager:enterState(TorpedoState.WaitFire)
end

return WaitInRange
