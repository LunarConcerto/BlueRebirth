local FragmentLogic = class("logic.FragmentLogic")

function FragmentLogic:GetIcon(id)
  local config = configManager.GetDataById("config_fragment", id)
  return config.icon
end

function FragmentLogic:GetName(id)
  local config = configManager.GetDataById("config_fragment", id)
  return config.name
end

function FragmentLogic:GetDesc(id)
  local config = configManager.GetDataById("config_fragment", id)
  return config.description
end

function FragmentLogic:GetQuality(id)
  local config = configManager.GetDataById("config_fragment", id)
  return config.quality
end

function FragmentLogic:GetFrame(id)
  return "", ""
end

function FragmentLogic:GetTexIcon(id)
  local config = configManager.GetDataById("config_fragment", id)
  return config.icon
end

return FragmentLogic
