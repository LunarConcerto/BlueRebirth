local BattleFail = class("game.guide.guideTrigger.BattleFail", GR.requires.GuideTriggerBase)

function BattleFail:initialize(nType)
  self.type = nType
end

function BattleFail:onStart(param)
  self.tblContainCopy = param
  eventManager:RegisterEvent(LuaEvent.BattleFail, self.__onBattleFail, self)
end

function BattleFail:__onBattleFail(nFailCopy)
  if table.containV(self.tblContainCopy, nFailCopy) then
    self:sendTrigger()
    eventManager:UnregisterEvent(LuaEvent.BattleFail, self.__onBattleFail)
  end
end

return BattleFail
