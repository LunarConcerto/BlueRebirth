local EquipEnhanceItemLogic = class("logic.EquipEnhanceItemLogic")

function EquipEnhanceItemLogic:GetIcon(id)
  local config = configManager.GetDataById("config_equip_enhance_item", id)
  return config.icon, "Item"
end

function EquipEnhanceItemLogic:GetName(id)
  local config = configManager.GetDataById("config_equip_enhance_item", id)
  return config.name
end

function EquipEnhanceItemLogic:GetDesc(id)
  local config = configManager.GetDataById("config_equip_enhance_item", id)
  return config.description
end

function EquipEnhanceItemLogic:GetQuality(id)
  local config = configManager.GetDataById("config_equip_enhance_item", id)
  return config.quality
end

function EquipEnhanceItemLogic:GetFrame(id)
  return "", ""
end

function EquipEnhanceItemLogic:GetTexIcon(id)
  local config = configManager.GetDataById("config_equip_enhance_item", id)
  return config.icon
end

return EquipEnhanceItemLogic
