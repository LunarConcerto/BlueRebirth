local GuideTPoint = class("game.Guide.guidebehaviours.GuideTPoint", GR.requires.BehaviourBase)

function GuideTPoint:doBehaviour()
  GR.guideManager.guidePage:SetTAdvantageActive(self.objParam)
  self:onDone()
end

return GuideTPoint
