local ExitBattleManual = class("game.guide.guideTrigger.ExitBattleManual", GR.requires.GuideTriggerBase)

function ExitBattleManual:initialize(nType)
  self.type = nType
end

function ExitBattleManual:onStart()
  eventManager:RegisterEvent(LuaEvent.ExistBattleManual, self.__onExitBattleManual, self)
end

function ExitBattleManual:__onExitBattleManual()
  eventManager:UnregisterEvent(LuaEvent.ExistBattleManual, self.__onExitBattleManual, self)
  self:sendTrigger()
end

return ExitBattleManual
