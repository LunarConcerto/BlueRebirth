local EventManager = class("util.EventManager")

function EventManager:initialize()
  self.private = {
    _eventMap = {}
  }
end

function EventManager:HaveListener(eventName)
  return self.private._eventMap[eventName] ~= nil
end

function EventManager:RegisterEvent(eventName, func, handler)
  local events = self.private._eventMap[eventName]
  local node = {
    func,
    handler,
    eventName,
    isValid = true
  }
  if events ~= nil then
    table.insert(events, node)
  else
    self.private._eventMap[eventName] = {node}
  end
end

function EventManager:RemoveAllListener(eventName)
  local events = self.private._eventMap[eventName]
  if events ~= nil then
    events = nil
  end
end

function EventManager:UnregisterEvent(eventName, func, handler)
  local events = self.private._eventMap[eventName]
  if events ~= nil then
    for k = #events, 1, -1 do
      local event = events[k]
      if event[1] == func then
        if handler ~= nil then
          if event[2] == handler then
            event.isValid = false
            table.remove(events, k)
          end
        else
          event.isValid = false
          table.remove(events, k)
        end
      end
    end
  end
end

function EventManager:SendEvent(eventName, param)
  local events_ref = self.private._eventMap[eventName]
  if events_ref ~= nil then
    local events = {}
    local event
    for i = 1, #events_ref do
      event = events_ref[i]
      events[i] = event
    end
    for i = 1, #events do
      event = events[i]
      event[1](event[2], param)
    end
  end
end

function EventManager:UnregisterEventByHandler(obj)
  for _, events in pairs(self.private._eventMap) do
    if events ~= nil then
      for k = #events, 1, -1 do
        local event = events[k]
        if event[2] == obj then
          table.remove(events, k)
        end
      end
    end
  end
end

function EventManager:FireEventToCSharp(eventId, param)
  UIManager:FireCSharpEvent(eventId, param)
end

return EventManager
