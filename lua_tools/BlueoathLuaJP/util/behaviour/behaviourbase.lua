local BehaviourBase = class("util.behaviour.BehaviourBase")

function BehaviourBase:initialize(nType, objHolder, objParam)
  self.bIsDone = false
  self.nType = nType
  self.objHolder = objHolder
  self.objParam = objParam
  self.mEvents = {}
  self:onInit()
end

function BehaviourBase:getIsDone()
  return self.bIsDone
end

function BehaviourBase:onInit()
end

function BehaviourBase:doBehaviour(objParam)
end

function BehaviourBase:tick(nDeltaTime)
end

function BehaviourBase:interrupt()
end

function BehaviourBase:onDone(param)
  GR.guideHub:logError(tostring(self.nType) .. "  done")
  self:onBehaviourEnd()
  self:removeAllEvents()
  self.objHolder:onBehaviourDone(self, param)
  self.bIsDone = true
end

function BehaviourBase:onBehaviourEnd()
end

function BehaviourBase:registerEvent(nEventID, funcCB)
  table.insert(self.mEvents, {nEventID, funcCB})
  eventManager:RegisterEvent(nEventID, funcCB, self)
end

function BehaviourBase:removeEvent(nEventID, funcCB)
  eventManager:UnregisterEvent(nEventID, funcCB)
  local nCount = #self.mEvents
  for i = 1, nCount do
    local event = self.mEvents[i]
    if event[1] == nEventID and event[2] == funcCB then
      table.remove(self.mEvents, i)
      return
    end
  end
end

function BehaviourBase:removeAllEvents()
  local nCount = #self.mEvents
  for i = 1, nCount do
    local event = self.mEvents[i]
    eventManager:UnregisterEvent(event[1], event[2])
  end
  self.mEvents = {}
  eventManager:UnregisterEventByHandler(self)
end

return BehaviourBase
