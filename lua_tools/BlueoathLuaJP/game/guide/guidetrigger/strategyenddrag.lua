local StrategyEndDrag = class("game.guide.guideTrigger.StrategyEndDrag", GR.requires.GuideTriggerBase)

function StrategyEndDrag:initialize(nType)
  self.type = nType
end

function StrategyEndDrag:onStart()
  eventManager:RegisterEvent(LuaEvent.StrategyEndDrag, self.__onEndDrag, self)
end

function StrategyEndDrag:__onEndDrag(nFLeetId)
  self:sendTrigger()
  eventManager:UnregisterEvent(LuaEvent.StrategyEndDrag, self.__onEndDrag)
end

return StrategyEndDrag
