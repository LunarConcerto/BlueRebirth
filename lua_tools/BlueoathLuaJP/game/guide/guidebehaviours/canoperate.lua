local CanOperate = class("game.Guide.guidebehaviours.CanOperate", GR.requires.BehaviourBase)

function CanOperate:doBehaviour()
  GR.guideManager.guidePage:SetRayCastSize(Vector2.New(0, 1))
  self:onDone()
end

return CanOperate
