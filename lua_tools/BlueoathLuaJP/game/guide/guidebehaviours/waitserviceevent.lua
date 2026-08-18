local WaitServiceEvent = class("game.Guide.guidebehaviours.WaitServiceEvent", GR.requires.BehaviourBase)

function WaitServiceEvent:doBehaviour()
  if self:_check() then
    self:onDone()
    return
  end
  eventManager:RegisterEvent(LuaEvent.GuideInfoReceive, self.onServiceCall, self)
end

function WaitServiceEvent:onServiceCall()
  local bResult = self:_check()
  if bResult then
    eventManager:UnregisterEvent(LuaEvent.GuideInfoReceive, self.onServiceCall)
    self:onDone()
  end
end

function WaitServiceEvent:_check()
  local bResult = GR.guideHub:ismeetOneCondition(GUIDE_CONDITION.GuideEvent, self.objParam, false)
  return bResult
end

function WaitServiceEvent:interrupt()
  eventManager:UnregisterEvent(LuaEvent.GuideInfoReceive, self.onServiceCall)
end

return WaitServiceEvent
