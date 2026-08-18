local TalentUpgradeItemLogic = class("logic.TalentUpgradeItemLogic")

function TalentUpgradeItemLogic:GetIcon(id)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", id)
  return config.icon, "Item"
end

function TalentUpgradeItemLogic:GetName(id)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", id)
  return config.name
end

function TalentUpgradeItemLogic:GetDesc(id)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", id)
  return config.description
end

function TalentUpgradeItemLogic:GetQuality(id)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", id)
  return config.quality
end

function TalentUpgradeItemLogic:GetFrame(id)
  return "", ""
end

function TalentUpgradeItemLogic:GetTexIcon(id)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", id)
  return config.icon
end

function TalentUpgradeItemLogic:GetSmallIcon(id)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", id)
  return config.icon_small
end

return TalentUpgradeItemLogic
