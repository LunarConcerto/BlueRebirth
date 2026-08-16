local PlotSyncLogic = class("logic.PlotSyncLogic")

function PlotSyncLogic:initialize()
end

local configType = {
  plot_episode_main = "config_plot_episode_main",
  plot_episode_wedding = "config_plot_episode_wedding",
  plot_episode_event = "config_plot_episode_event",
  plot_episode_character = "config_plot_episode_character",
  plot_episode_audio_main = "config_plot_episode_audio_main",
  plot_episode_audio_wedding = "config_plot_episode_audio_wedding",
  plot_episode_audio_event = "config_plot_episode_audio_event",
  plot_episode_audio_character = "config_plot_episode_audio_character",
  plot_episode_expression = "config_plot_episode_expression",
  plot_episode_ship = "config_plot_episode_ship",
  plot_episode_trigger = "config_plot_episode_trigger",
  plot_episode_tween = "config_plot_episode_tween"
}
local logicdataType = {
  plotepisodedata = function()
    return Logic.plotLogic:GetPlotEpisodeConfig()
  end
}

function PlotSyncLogic:Write(plotdata)
  for k, v in pairs(plotdata) do
    if v ~= nil then
      local obj = Unserialize(v)
      if obj ~= nil then
        self:WriteToConfig(k, obj)
        self:WriteToLogic(k, obj)
      end
    end
  end
end

function PlotSyncLogic:Cover(plotdata)
  for k, v in pairs(plotdata) do
    if v ~= nil then
      local obj = Unserialize(v)
      if obj ~= nil then
        self:CoverConfig(k, obj)
      else
        logError(k .. "\229\143\141\229\186\143\229\136\151\229\140\150\229\164\177\232\180\165")
        file = io.open(string.format("E:\\%s.lua", k), "a")
        file:write("--test")
        file:write(v)
        file:close()
      end
    end
  end
  Logic.plotLogic:RefreshPlotEpisodeConfig()
  Logic.plotLogic:RefreshPlotTriggerConfig()
end

function PlotSyncLogic:CoverConfig(type, data)
  local target = configType[type]
  local count = 0
  local config = {}
  if target ~= nil and data ~= nil then
    for k, v in pairs(data) do
      count = count + 1
      config[k] = v
    end
    configManager.SetData(target, config)
  end
  logError(target .. ":" .. count .. "  " .. #config)
end

function PlotSyncLogic:Delete(type, data)
  log("PlotSyncLogic:Cover")
  for k, v in pairs(plotdata) do
    if v ~= nil then
      local obj = Unserialize(v)
      if obj ~= nil then
        self:DeleteConfigData(k, obj)
      end
    end
  end
  Logic.plotLogic:RefreshPlotEpisodeConfig()
  Logic.plotLogic:RefreshPlotTriggerConfig()
end

function PlotSyncLogic:DeleteConfigData(type, data)
  local target = configType[type]
  if target ~= nil then
    local config = configManager.GetData(target)
    if data then
      for k, v in pairs(data) do
        config[k] = nil
      end
    end
  end
end

function PlotSyncLogic:WriteToConfig(type, data)
  local target = configType[type]
  if target ~= nil then
    local config = configManager.GetData(target)
    if data then
      for k, v in pairs(data) do
        config[k] = v
      end
    end
  end
end

function PlotSyncLogic:WriteToLogic(type, data)
  if type == "plotepisodedata" and logicdataType[type] ~= nil then
    local config = logicdataType[type]()
    for k, v in pairs(data) do
      config[v.plot_episode_id][v.step] = v
    end
  end
end

return PlotSyncLogic
