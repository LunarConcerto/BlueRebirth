local CopyDetailPage_1_1 = class("game.guide.guideTrigger.CopyDetailPage_1_1", GR.requires.GuideTriggerBase)

function CopyDetailPage_1_1:initialize(nType)
  self.type = nType
end

function CopyDetailPage_1_1:onStart()
  eventManager:RegisterEvent(LuaEvent.OpenLevelDetailsPage, self.__onOpenPage, self)
end

function CopyDetailPage_1_1:__onOpenPage(param)
  if param == nil then
    return
  end
  if param.copyType ~= CopyType.COMMONCOPY then
    return
  end
  if param.copyId ~= 5011 then
    return
  end
  if param.IsRunningFight == true then
    return
  end
  eventManager:UnregisterEvent(LuaEvent.OpenLevelDetailsPage, self.__onOpenPage, self)
  self:sendTrigger()
end

return CopyDetailPage_1_1
