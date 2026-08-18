local ClickLevelFleetItemTrick = class("game.Guide.guidebehaviours.ClickLevelFleetItemTrick", GR.requires.BehaviourBase)

function ClickLevelFleetItemTrick:doBehaviour()
  eventManager:RegisterEvent(LuaCSharpEvent.GuideCall, self._OnClick, self)
end

function ClickLevelFleetItemTrick:_OnClick(nId)
  if nId == SpecialTrickId.OpenFleetPage then
    eventManager:SendEvent(LuaEvent.ClickFleetCard)
    eventManager:UnregisterEvent(LuaCSharpEvent.GuideCall, self._OnClick, self)
    self:onDone()
  end
end

return ClickLevelFleetItemTrick
