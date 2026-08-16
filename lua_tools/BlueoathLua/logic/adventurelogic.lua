local AdventureLogic = class("logic.AdventureLogic")

function AdventureLogic:initialize()
end

function AdventureLogic:IsAllLevelMax()
  local result = true
  local roles = configManager.GetDataById("config_parameter", 284).arrValue
  for i, roleId in ipairs(roles) do
    local config = configManager.GetDataById("config_adventure_role", roleId)
    local level = Data.adventureData:GetLevelById(roleId)
    if level < config.level_max then
      result = false
      break
    end
  end
  return result
end

function AdventureLogic:IsAllKill()
  local enemyTbl = configManager.GetDataById("config_parameter", 285).arrValue
  local index = Data.adventureData:GetIndex()
  return index >= #enemyTbl
end

function AdventureLogic:HaveHp()
  local roles = configManager.GetDataById("config_parameter", 284).arrValue
  for i, roleId in ipairs(roles) do
    local hp = Data.adventureData:GetHpById(roleId)
    if 0 < hp then
      return true
    end
  end
  return false
end

return AdventureLogic
