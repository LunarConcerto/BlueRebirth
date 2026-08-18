local PartOperate = class("game.Guide.guidebehaviours.PartOperate", GR.requires.BehaviourBase)

function PartOperate:doBehaviour()
  GR.guideManager.guidePage:SetRayCastSize(Vector2.New(0, 0.8))
  self:onDone()
end

return PartOperate
