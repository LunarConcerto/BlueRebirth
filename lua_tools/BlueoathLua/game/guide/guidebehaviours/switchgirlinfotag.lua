local SwitchGirlinfoTag = class("game.Guide.guidebehaviours.SwitchGirlinfoTag", GR.requires.BehaviourBase)

function SwitchGirlinfoTag:doBehaviour()
  eventManager:SendEvent("switchtag", 0)
  self:onDone()
end

return SwitchGirlinfoTag
