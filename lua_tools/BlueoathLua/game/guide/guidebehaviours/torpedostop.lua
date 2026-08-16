local TorpedoStop = class("game.Guide.guidebehaviours.TorpedoStop", GR.requires.BehaviourBase)

function TorpedoStop:doBehaviour()
  GR.guideManager.guidePage:TickDisplay(self.objParam)
  self:onDone()
end

return TorpedoStop
