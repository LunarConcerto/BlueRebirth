local BaseStage = class("stage.BaseStage")

function BaseStage:initialize()
end

function BaseStage:OpenGroupPage(param)
  for _, v in pairs(param) do
    local openParam = v[2] or nil
    local layer = v[3] or 1
    if v[4] == nil then
      v[4] = true
    end
    local tostack = v[4]
    UIHelper.OpenPage(v[1], openParam, layer, tostack)
  end
end

function BaseStage:CloseGroupPage(param)
  for _, v in pairs(param) do
    local openParam = v[2] or nil
    UIHelper.ClosePage(v[1], v[2])
  end
end

function BaseStage:RegisterEvent(nEventID, funcCB)
  if not self.mEvents then
    self.mEvents = {}
  end
  table.insert(self.mEvents, {nEventID, funcCB})
  eventManager:RegisterEvent(nEventID, funcCB, self)
end

function BaseStage:UnregisterAllEvent()
  local nCount = #self.mEvents
  for i = 1, nCount do
    local event = self.mEvents[i]
    eventManager:UnregisterEvent(event[1], event[2])
  end
  self.mEvents = {}
  eventManager:UnregisterEventByHandler(self)
end

return BaseStage
