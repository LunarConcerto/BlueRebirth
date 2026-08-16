local PlotTrigger = class("game.guide.guideTrigger.PlotTrigger", GR.requires.GuideTriggerBase)

function PlotTrigger:initialize(nType)
  self.type = nType
  self.plotTriggerId = nil
  self.plotTriggerParam = nil
end

function PlotTrigger:onStart(param)
  self.plotTriggerId = param[1]
  self.plotTriggerParam = param[2]
  eventManager:RegisterEvent(LuaEvent.PlotTrigger, self._onPlotTrigger, self)
end

function PlotTrigger:_onPlotTrigger(param)
  local nTriggerType = param[1]
  local triggerParam = param[2]
  if nTriggerType ~= self.plotTriggerId then
    return
  end
  if self.plotTriggerParam == triggerParam then
    self:sendTrigger()
  end
end

function PlotTrigger:onEnd()
  eventManager:UnregisterEvent(LuaEvent.PlotTrigger, self._onPlotTrigger)
end

return PlotTrigger
