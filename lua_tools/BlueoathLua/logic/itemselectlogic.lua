local ItemSelectLogic = class("logic.ItemSelectLogic")

function ItemSelectLogic:GetIcon(id)
  local config = configManager.GetDataById("config_item_selected", id)
  return config.icon
end

function ItemSelectLogic:GetSmallIcon(id)
  local config = configManager.GetDataById("config_item_selected", id)
  return config.icon
end

function ItemSelectLogic:GetName(id)
  local config = configManager.GetDataById("config_item_selected", id)
  return config.name
end

function ItemSelectLogic:GetDesc(id)
  local config = configManager.GetDataById("config_item_selected", id)
  return config.description
end

function ItemSelectLogic:GetQuality(id)
  local config = configManager.GetDataById("config_item_selected", id)
  return config.quality
end

function ItemSelectLogic:GetFrame(id)
  return "", ""
end

function ItemSelectLogic:GetTexIcon(id)
  local config = configManager.GetDataById("config_item_selected", id)
  return config.icon
end

function ItemSelectLogic:GetInfo(id)
  local config = configManager.GetDataById("config_item_selected", id)
  return config
end

return ItemSelectLogic
