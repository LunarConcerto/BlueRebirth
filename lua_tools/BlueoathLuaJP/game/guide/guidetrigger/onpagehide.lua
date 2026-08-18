local OnPageHide = class("game.guide.guideTrigger.OnPageHide", GR.requires.GuideTriggerBase)

function OnPageHide:initialize(nType)
  self.type = nType
end

function OnPageHide:onStart(param)
  self.strPageName = param
  eventManager:RegisterEvent(LuaEvent.OnPageHide, self._onPageHide, self)
end

function OnPageHide:_onPageHide(strPageName)
  if strPageName == self.strPageName then
    self:sendTrigger()
  end
end

function OnPageHide:onEnd()
  eventManager:UnregisterEvent(LuaEvent.OnPageHide, self._onPlotEnd)
end

return OnPageHide
