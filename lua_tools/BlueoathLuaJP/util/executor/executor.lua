local Executor = class("util.Executor.Executor")

function Executor:initialize(param)
  self.groupExecutor = nil
  self.state = ExecutorState.Wait
  self.tblExecutors = {}
  self.strName = nil
  self.mEvents = {}
  self:init(param)
end

function Executor:init(param)
end

function Executor:play()
  self.state = ExecutorState.Running
  self:playImp()
end

function Executor:playImp()
end

function Executor:stop()
  self:onStop()
  self.state = ExecutorState.End
  self:removeAllEvents()
end

function Executor:onStop()
end

function Executor:getState()
  return self.state
end

function Executor:isEnd()
  local result = self.state == ExecutorState.End
  return result
end

function Executor:tick()
end

function Executor:reset()
  self.state = ExecutorState.Wait
  self:resetImp()
end

function Executor:resetImp()
end

function Executor:setParent(objGroupExecutor)
  self.groupExecutor = objGroupExecutor
end

function Executor:getParent()
  return self.groupExecutor
end

function Executor:tostring()
  return self.strName
end

function Executor:registerEvent(nEventID, funcCB)
  table.insert(self.mEvents, {nEventID, funcCB})
  eventManager:RegisterEvent(nEventID, funcCB, self)
end

function Executor:removeEvent(nEventID, funcCB)
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

function Executor:removeAllEvents()
  local nCount = #self.mEvents
  for i = 1, nCount do
    local event = self.mEvents[i]
    eventManager:UnregisterEvent(event[1], event[2])
  end
  self.mEvents = {}
  eventManager:UnregisterEventByHandler(self)
end

return Executor
