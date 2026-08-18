local OpenFleetLater = class("game.Guide.Guidebehaviours.OpenFleetLater", GR.requires.BehaviourBase)

function OpenFleetLater:doBehaviour()
  Logic.fleetLogic:SetGuideFlag(self.objParam)
  self:onDone()
end

return OpenFleetLater
