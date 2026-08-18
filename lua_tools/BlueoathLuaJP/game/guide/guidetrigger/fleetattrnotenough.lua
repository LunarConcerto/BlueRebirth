local FleetAttrNotEnough = class("game.guide.guideTrigger.FleetAttrNotEnough", GR.requires.GuideTriggerBase)

function FleetAttrNotEnough:initialize(nType)
  self.type = nType
end

function FleetAttrNotEnough:onStart()
  eventManager:RegisterEvent(LuaEvent.GuideFleetAttr, self.__onBosShow, self)
end

function FleetAttrNotEnough:__onBosShow()
  eventManager:UnregisterEvent(LuaEvent.GuideFleetAttr, self.__onBosShow, self)
  self:sendTrigger()
end

return FleetAttrNotEnough
