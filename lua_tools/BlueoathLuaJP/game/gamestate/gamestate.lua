local GameState = class("Game.GameState.GameState")

function GameState:initialize()
  self.mEvents = {}
end

function GameState:onStart(param)
  self:registerAllEvents()
end

function GameState:onEnd()
  self:removeAllEvents()
end

function GameState:registerAllEvents()
end

function GameState:registerEvent(nEventID, funcCB)
  table.insert(self.mEvents, {nEventID, funcCB})
  eventManager:RegisterEvent(nEventID, funcCB, self)
end

function GameState:removeEvent(nEventID, funcCB)
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

function GameState:removeAllEvents()
  local nCount = #self.mEvents
  for i = 1, nCount do
    local event = self.mEvents[i]
    eventManager:UnregisterEvent(event[1], event[2])
  end
  self.mEvents = {}
  eventManager:UnregisterEventByHandler(self)
end

return GameState
