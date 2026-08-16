local BuildTenShipReturn = class("game.guide.guideTrigger.BuildTenShipReturn", GR.requires.GuideTriggerBase)

function BuildTenShipReturn:initialize(nType)
  self.type = nType
end

function BuildTenShipReturn:onStart()
  eventManager:RegisterEvent(LuaEvent.BuildTenShipReturn, self.__onReturn, self)
end

function BuildTenShipReturn:__onReturn()
  self:sendTrigger()
  eventManager:UnregisterEvent(LuaEvent.BuildTenShipReturn, self.__onReturn)
end

return BuildTenShipReturn
