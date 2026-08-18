local PlotEndTrigger = class("game.guide.guideTrigger.PlotEndTrigger", GR.requires.GuideTriggerBase)

function PlotEndTrigger:initialize(nType)
  self.type = nType
  self.tblAllPlotId = nil
end

function PlotEndTrigger:onStart(param)
  self.tblAllPlotId = param
  eventManager:RegisterEvent(LuaEvent.PlotEnd, self._onPlotEnd, self)
end

function PlotEndTrigger:_onPlotEnd(nPlotId)
  local nCount = #self.tblAllPlotId
  for i = 1, nCount do
    local nTarget = self.tblAllPlotId[i]
    if nTarget == nPlotId then
      self:sendTrigger()
    end
  end
end

function PlotEndTrigger:onEnd()
  eventManager:UnregisterEvent(LuaEvent.PlotEnd, self._onPlotEnd)
end

return PlotEndTrigger
