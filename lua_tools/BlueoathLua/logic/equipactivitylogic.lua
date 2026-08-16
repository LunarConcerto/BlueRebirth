local EquipActivityLogic = class("logic.EquipActivityLogic")

function EquipActivityLogic:initialize()
end

function EquipActivityLogic:IsCanGetReward(equipId, equipTid)
  if equipId <= 0 then
    return false
  end
  local equipCfg = configManager.GetDataById("config_equip", equipTid)
  local power = Data.equipactivityData:GetPowerPointByEquipId(equipId)
  local isReward = Data.equipactivityData:GetIsRewardByEquipId(equipId)
  if isReward <= 0 and power >= equipCfg.max_energy then
    return true
  end
  return false
end

return EquipActivityLogic
