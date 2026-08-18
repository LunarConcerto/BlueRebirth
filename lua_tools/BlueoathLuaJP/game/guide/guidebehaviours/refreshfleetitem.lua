local RefreshFleetItem = class("game.Guide.guidebehaviours.RefreshFleetItem", GR.requires.BehaviourBase)

function RefreshFleetItem:doBehaviour()
  eventManager:SendEvent(LuaEvent.RefreshLevelHeroItem)
  self:onDone()
end

return RefreshFleetItem
