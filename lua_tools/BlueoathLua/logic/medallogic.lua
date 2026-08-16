local MedalLogic = class("logic.MedalLogic")

function MedalLogic:GetIcon(id)
  local config = configManager.GetDataById("config_medal", id)
  return config.icon, "NewOutBattle"
end

function MedalLogic:GetName(id)
  local config = configManager.GetDataById("config_medal", id)
  return config.name
end

function MedalLogic:GetDesc(id)
  local config = configManager.GetDataById("config_medal", id)
  return config.description
end

function MedalLogic:GetQuality(id)
  local config = configManager.GetDataById("config_medal", id)
  return config.quality
end

function MedalLogic:GetFrame(id)
  return "", ""
end

function MedalLogic:GetTexIcon(id)
  local config = configManager.GetDataById("config_medal", id)
  return config.icon
end

function MedalLogic:GetMedal(id)
  local config = configManager.GetDataById("config_medal", id)
  return config
end

function MedalLogic:GetWay(id)
  local config = configManager.GetDataById("config_medal", id)
  return config.get
end

return MedalLogic
