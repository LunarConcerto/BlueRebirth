local PassCopyTrigger = class("game.guide.guideTrigger.PassCopyTrigger", GR.requires.GuideTriggerBase)

function PassCopyTrigger:initialize(nType)
  self.type = nType
end

function PassCopyTrigger:onStart(param)
  self.copyId = param
  local bPass = self:_check()
  if not bPass then
    eventManager:RegisterEvent(LuaEvent.PassNewCopy, self._onPassNewCopy, self)
  else
    self:sendTrigger()
  end
end

function PassCopyTrigger:_onPassNewCopy()
  local bPass = self:_check()
  if bPass then
    self:sendTrigger()
  end
end

function PassCopyTrigger:_check()
  local tblSeaCopyInfo = Data.copyData:GetCopyServiceData()
  local bPass = false
  for i, v in pairs(tblSeaCopyInfo) do
    if v.BaseId == self.copyId and v.FirstPassTime > 0 then
      bPass = true
    end
  end
  local tblPlotCopyInfo = Data.copyData:GetPlotCopyServiceData()
  for i, v in pairs(tblPlotCopyInfo) do
    if v.BaseId == self.copyId and v.FirstPassTime > 0 then
      bPass = true
    end
  end
  return bPass
end

function PassCopyTrigger:onEnd()
  eventManager:UnregisterEvent(LuaEvent.PassNewCopy, self._onPassNewCopy)
end

return PassCopyTrigger
