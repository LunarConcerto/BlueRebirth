local HomePageTweenEnd = class("game.guide.guideTrigger.HomePageTweenEnd", GR.requires.GuideTriggerBase)

function HomePageTweenEnd:initialize(nType)
  self.type = nType
end

function HomePageTweenEnd:onStart()
  eventManager:RegisterEvent(LuaEvent.HomePageReturn, self._onHomePageReturn, self)
end

function HomePageTweenEnd:_onHomePageReturn(bReturn)
  if bReturn then
    self:sendTrigger()
  end
end

function HomePageTweenEnd:onEnd()
  eventManager:UnregisterEvent(LuaEvent.HomePageReturn, self._onHomePageReturn)
end

return HomePageTweenEnd
