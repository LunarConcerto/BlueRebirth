local ShowComponent = class("game.Guide.guidebehaviours.ShowComponent", GR.requires.BehaviourBase)

function ShowComponent:doBehaviour()
  local nCompId = self.objParam
  GR.guideHub:enableElement(nCompId, false)
  self:onDone()
end

return ShowComponent
