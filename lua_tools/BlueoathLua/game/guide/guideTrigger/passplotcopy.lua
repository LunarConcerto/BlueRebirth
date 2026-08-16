local PassPlotCopy = class("game.guide.guideTrigger.PassPlotCopy", GR.requires.GuideTriggerBase)

function PassPlotCopy:initialize(nType)
  self.type = nType
end

function PassPlotCopy:onStart(param)
  self.copyId = param
  local tblCopyInfo = Data.copyData.CopyInfo
  local bPass = false
  for i, v in ipairs(tblCopyInfo) do
    if v.BaseId == self.copyId and v.FirstPassTime > 0 then
      bPass = true
      self:sendTrigger()
    end
  end
  if not bPass then
    eventManager:RegisterEvent(LuaEvent.PassNewCopy, self._onPassNewCopy, self)
  end
end

function PassPlotCopy:_onPassNewCopy()
  local tblCopyInfo = Data.copyData.CopyInfo
  for i, v in ipairs(tblCopyInfo) do
    if v.BaseId == self.copyId and v.FirstPassTime > 0 then
      self:sendTrigger()
    end
  end
end

function PassPlotCopy:onEnd()
  eventManager:UnregisterEvent(LuaEvent.PassNewCopy, self._onPassNewCopy)
end

return PassPlotCopy
