local CannotOperate = class("game.Guide.guidebehaviours.CannotOperate", GR.requires.BehaviourBase)

function CannotOperate:doBehaviour()
  GR.guideManager.guidePage:SetRayCastSize(Vector2.New(0, 0))
  self:onDone()
end

return CannotOperate
