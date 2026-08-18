local ClickFleetFirstGirlTrick = class("game.Guide.guidebehaviours.ClickFleetFirstGirlTrick", GR.requires.BehaviourBase)

function ClickFleetFirstGirlTrick:doBehaviour()
  eventManager:RegisterEvent(LuaCSharpEvent.GuideCall, self._OnClick, self)
end

function ClickFleetFirstGirlTrick:_OnClick(nId)
  if nId == SpecialTrickId.OpenGirlInfoPage then
    eventManager:SendEvent(LuaEvent.ClickFleetPageFirstGirl)
    eventManager:UnregisterEvent(LuaCSharpEvent.GuideCall, self._OnClick, self)
    self:onDone()
  end
end

return ClickFleetFirstGirlTrick
