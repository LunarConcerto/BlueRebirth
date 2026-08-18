local PageOpen = class("game.guide.guideTrigger.PageOpen", GR.requires.GuideTriggerBase)

function PageOpen:initialize(nType, strPageName)
  self.type = nType
  self.strPageName = strPageName
end

function PageOpen:onStart()
  if UIHelper.IsPageOpen(self.strPageName) then
    self:sendTrigger()
  else
    eventManager:RegisterEvent(LuaEvent.OpenPage, self._onPageOpen, self)
  end
end

function PageOpen:_onPageOpen(strName)
  if strName == self.strPageName then
    self:sendTrigger()
  end
end

function PageOpen:onEnd()
  eventManager:UnregisterEvent(LuaEvent.OpenPage, self._onPageOpen)
end

return PageOpen
