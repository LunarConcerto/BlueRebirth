local WaitFire = class("game.guide.kits.torpedoguidestate.WaitFire", require("game.guide.kits.torpedoguidestate.torpedoguidestatebase"))

function WaitFire:initialize(objBehaviour, tblConfig, objManager)
  self.tblConfig = tblConfig
  self.tblStates = {}
  self.objManager = objManager
  self.objBehaviour = objBehaviour
  self:buildStates(self.tblConfig.States)
end

function WaitFire:__onEnter()
  self:startState(1)
  eventManager:RegisterEvent(LuaCSharpEvent.GuideFireTorpedo, self.__onFireTorpedo, self)
end

function WaitFire:__onFireTorpedo(nAngle)
  if nAngle > self.tblConfig.nLimitAngle then
    self.objManager:enterState(TorpedoState.FireFail)
  else
    self.objManager:enterState(TorpedoState.FireSunccess)
  end
end

function WaitFire:__onLeave()
  eventManager:UnregisterEventByHandler(self)
end

function WaitFire:onStateDone(nType)
  local nMaxIndex = self:getMaxType()
  if nType < nMaxIndex then
    local nNextKey = nType + 1
    self:startState(nNextKey)
  end
end

return WaitFire
