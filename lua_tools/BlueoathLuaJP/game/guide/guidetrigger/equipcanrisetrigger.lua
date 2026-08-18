local EquipCanRiseTrigger = class("game.guide.guideTrigger.EquipCanRiseTrigger", GR.requires.GuideTriggerBase)

function EquipCanRiseTrigger:initialize(nType)
  self.type = nType
end

function EquipCanRiseTrigger:onStart()
  local bHaveRiseEquip = self:__bagHaveCanRiseEquip()
  if bHaveRiseEquip then
    self:sendTrigger()
  else
    eventManager:RegisterEvent(LuaEvent.EquipIntenstitySuccess, self.__onEquipEnhance, self)
  end
end

function EquipCanRiseTrigger:__onEquipEnhance(nEquipId)
  local bCanRise = Logic.equipLogic:CanRiseStar(nEquipId)
  if bCanRise then
    eventManager:UnregisterEvent(LuaEvent.EquipIntenstitySuccess, self.__onEquipEnhance, self)
    self:sendTrigger()
  end
end

function EquipCanRiseTrigger:__bagHaveCanRiseEquip()
  local tblEquips = Data.equipData:GetEquipData()
  for k, v in pairs(tblEquips) do
    local bCanRise = Logic.equipLogic:CanRiseStar(k)
    if bCanRise then
      return true
    end
  end
  return false
end

return EquipCanRiseTrigger
