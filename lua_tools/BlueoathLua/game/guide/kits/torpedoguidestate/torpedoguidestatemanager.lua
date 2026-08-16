local TorpedoGuideStateManager = class("game.guide.kits.torpedoguidestate.TorpedoGuideStateManager")

function TorpedoGuideStateManager:initialize()
  self.tblStates = {}
  self.objCurState = nil
end

function TorpedoGuideStateManager:addState(nId, objState)
  self.tblStates[nId] = objState
end

function TorpedoGuideStateManager:enterState(nId)
  if self.objCurState ~= nil then
    self.objCurState:leave()
  end
  self.objCurState = self.tblStates[nId]
  self.objCurState:enter()
end

function TorpedoGuideStateManager:clearAll()
  for k, v in pairs(self.tblStates) do
    v:clear()
  end
  self.objCurState = nil
  self.tblStates = {}
end

return TorpedoGuideStateManager
