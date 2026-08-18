local BathShipTrigger = class("game.guide.guideTrigger.BathShipTrigger", GR.requires.GuideTriggerBase)

function BathShipTrigger:initialize(nType)
  self.type = nType
end

function BathShipTrigger:tick()
  local oneShipInBath = Logic.repaireLogic:CheckShipNum()
  if oneShipInBath then
    self:sendTrigger()
  end
end

return BathShipTrigger
