local GirlInfoDetail = class("game.guide.guideTrigger.GirlInfoDetail", GR.requires.GuideTriggerBase)

function GirlInfoDetail:initialize(nType)
  self.type = nType
end

function GirlInfoDetail:onStart()
  eventManager:RegisterEvent(LuaEvent.GirlInfoOpenIndex, self.__onGirlInfoChange, self)
end

function GirlInfoDetail:__onGirlInfoChange(nIndex)
  if nIndex == 1 then
    self:sendTrigger()
  end
end

function GirlInfoDetail:onEnd()
  eventManager:UnregisterEvent(LuaEvent.GirlInfoOpenIndex, self.__onGirlInfoChange)
end

return GirlInfoDetail
