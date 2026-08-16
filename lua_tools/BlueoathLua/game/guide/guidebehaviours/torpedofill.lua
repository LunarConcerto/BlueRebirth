local TorpedoFill = class("game.Guide.guidebehaviours.TorpedoFill", GR.requires.BehaviourBase)

function TorpedoFill:doBehaviour()
  GR.guideManager.guidePage:FullTorpedoNumActive(self.objParam)
  self:onDone()
end

return TorpedoFill
