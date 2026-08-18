local ItemUpdateTrigger = class("game.guide.guideTrigger.ItemUpdateTrigger", GR.requires.GuideTriggerBase)

function ItemUpdateTrigger:initialize(nType)
  self.type = nType
end

function ItemUpdateTrigger:onStart(param)
  eventManager:RegisterEvent(LuaEvent.UpdateBagItem, self._onItemUpdate, self)
end

function ItemUpdateTrigger:_onItemUpdate()
  self:sendTrigger()
end

function ItemUpdateTrigger:onEnd()
  eventManager:UnregisterEvent(LuaEvent.UpdateBagItem, self._onItemUpdate)
end

return ItemUpdateTrigger
