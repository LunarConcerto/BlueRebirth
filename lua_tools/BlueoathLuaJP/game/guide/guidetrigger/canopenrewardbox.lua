local CanOpenRewardBox = class("game.guide.guideTrigger.CanOpenRewardBox", GR.requires.GuideTriggerBase)

function CanOpenRewardBox:initialize(nType)
  self.type = nType
end

function CanOpenRewardBox:onStart()
  eventManager:RegisterEvent(LuaEvent.CopyPageRefreshChapter, self.__onChapterRefresh, self)
end

function CanOpenRewardBox:__onChapterRefresh(nCurChapIndex)
  if UIHelper.IsPageOpen("ModuleOpenPage") then
    return
  end
  if Logic.redDotLogic.SeaCopyBoxById(nCurChapIndex) then
    self:sendTrigger()
    eventManager:UnregisterEvent(LuaEvent.CopyPageRefreshChapter, self.__onChapterRefresh)
  end
end

return CanOpenRewardBox
