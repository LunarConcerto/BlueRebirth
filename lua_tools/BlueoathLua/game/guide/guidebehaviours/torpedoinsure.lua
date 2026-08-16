local TorpedoInsure = class("game.Guide.guidebehaviours.TorpedoInsure", GR.requires.BehaviourBase)

function TorpedoInsure:onInit()
  self.objStateManager = require("game.guide.kits.torpedoguidestate.TorpedoGuideStateManager"):new()
  self:__initStates()
end

function TorpedoInsure:__initStates()
  local objWait = require("game.guide.kits.torpedoguidestate.WaitFire"):new(self, self.objParam.WaitParam, self.objStateManager)
  local objFail = require("game.guide.kits.torpedoguidestate.FireFail"):new(self, self.objParam.FailParam, self.objStateManager)
  local objSunccess = require("game.guide.kits.torpedoguidestate.FireSunccess"):new(self, self.objParam.SuccessParam, self.objStateManager)
  local objWaitInRange = require("game.guide.kits.torpedoguidestate.WaitInRange"):new(self, self.objParam.WaitInRangeParam, self.objStateManager)
  self.objStateManager:addState(TorpedoState.WaitFire, objWait)
  self.objStateManager:addState(TorpedoState.FireFail, objFail)
  self.objStateManager:addState(TorpedoState.FireSunccess, objSunccess)
  self.objStateManager:addState(TorpedoState.WaitInRange, objWaitInRange)
end

function TorpedoInsure:doBehaviour()
  self.objStateManager:enterState(TorpedoState.WaitInRange)
end

function TorpedoInsure:onBehaviourEnd()
  self.objStateManager:clearAll()
end

return TorpedoInsure
