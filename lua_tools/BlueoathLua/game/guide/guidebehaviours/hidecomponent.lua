local HideComponent = class("game.Guide.guidebehaviours.HideComponent", GR.requires.BehaviourBase)

function HideComponent:doBehaviour()
  GR.guideHub:disableElement()
  self:onDone()
end

return HideComponent
