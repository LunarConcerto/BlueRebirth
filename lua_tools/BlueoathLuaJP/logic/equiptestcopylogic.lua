local EquipTestCopyLogic = class("logic.EquipTestCopyLogic")

function EquipTestCopyLogic:initialize()
end

function EquipTestCopyLogic:GetLevelByDamage(activityCfg, damage)
  local level = 1
  local damageDatas = activityCfg.p4
  for i, data in ipairs(damageDatas) do
    if damage < data[1] then
      break
    end
    level = level + 1
  end
  return level
end

function EquipTestCopyLogic:GetReceiveRewardLevel(activityCfg)
  local damageDatas = activityCfg.p4
  local unreceviable = #damageDatas + 1
  local curMaxDamage = Data.equipTestCopyData:GetMaxDamage()
  local level = self:GetLevelByDamage(activityCfg, curMaxDamage)
  local receiveData = Data.equipTestCopyData:GetReceivedRewards()
  local receiveCount = #receiveData
  if receiveCount < #damageDatas and receiveCount < level - 1 then
    return receiveCount + 1, level
  end
  return unreceviable, level
end

return EquipTestCopyLogic
