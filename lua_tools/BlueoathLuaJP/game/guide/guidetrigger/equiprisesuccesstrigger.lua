local EquipRiseSuccessTrigger = class("game.guide.guideTrigger.EquipRiseSuccessTrigger", GR.requires.GuideTriggerBase)

function EquipRiseSuccessTrigger:initialize(nType)
  self.type = nType
end

function EquipRiseSuccessTrigger:onStart()
  local bHaveRiseSuccessEquip = self:__bagHaveRiseSuccessEquip()
  if bHaveRiseSuccessEquip then
    self:sendTrigger()
  else
    eventManager:RegisterEvent(LuaEvent.EquipRiseStarSuccess, self.__onEquipSuccessEnhance, self)
  end
end

function EquipRiseSuccessTrigger:__onEquipSuccessEnhance()
  self:sendTrigger()
end

function EquipRiseSuccessTrigger:__bagHaveRiseSuccessEquip()
  local tblEquips = Data.equipData:GetEquipData()
  for k, v in pairs(tblEquips) do
    if v.Star > 0 then
      return true
    end
  end
  return false
end

return EquipRiseSuccessTrigger
