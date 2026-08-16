local EquipEnhaceLv = class("game.guide.guideTrigger.EquipEnhaceLv", GR.requires.GuideTriggerBase)

function EquipEnhaceLv:initialize(nType)
  self.type = nType
end

function EquipEnhaceLv:onStart(nLevel)
  self.nTargetLv = nLevel
  local bHaveEnhanceLvEquip = self:__bagHaveEnhanceLvEquip()
  if bHaveEnhanceLvEquip then
    self:sendTrigger()
  else
    eventManager:RegisterEvent(LuaEvent.EquipIntenstitySuccess, self.__onEquipEnhance, self)
  end
end

function EquipEnhaceLv:__onEquipEnhance(nEquipId)
  local equipData = Logic.equipLogic:GetEquipById(nEquipId)
  if equipData.EnhanceLv >= self.nTargetLv then
    eventManager:UnregisterEvent(LuaEvent.EquipIntenstitySuccess, self.__onEquipEnhance, self)
    self:sendTrigger()
  end
end

function EquipEnhaceLv:__bagHaveEnhanceLvEquip()
  local tblEquips = Data.equipData:GetEquipData()
  for k, v in pairs(tblEquips) do
    if v.EnhanceLv >= self.nTargetLv then
      return true
    end
  end
  return false
end

return EquipEnhaceLv
