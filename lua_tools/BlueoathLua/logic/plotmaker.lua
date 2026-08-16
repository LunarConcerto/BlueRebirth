local PlotMaker = class("logic.PlotMaker")

function PlotMaker:initialize()
end

function PlotMaker:OpenPlotPage()
  if self.current == nil then
    self.current = UIHelper.OpenPage("PlotPage")
  end
end

local plotPage, background_music, audio_id, audio_effect

function PlotMaker:PlaySection(plot_id)
  self:OpenPlotPage()
  local config = Logic.plotLogic:GetPlotInfo(plot_id)
  if config ~= nil then
    local firstStep
    if 0 < #config then
      firstStep = config[1]
    end
    self:SwitchAudio(firstStep)
    if self.plotPage ~= nil then
      self.plotPage:Play(config)
    end
  end
end

function PlotMaker:PlayStep(plot_step_id)
  self:OpenPlotPage()
  local step = self:GetPlotStep(plot_step_id)
  self:SwitchAudio(step)
  if step ~= nil then
    local config = {}
    config[1] = step
    if self.plotPage ~= nil then
      self.plotPage:Play(config)
    end
  end
end

function PlotMaker:GetPlotStep(plot_step_id)
  local step = configManager.GetDataById("config_plot_episode_main", plot_step_id)
  if step == nil then
    step = configManager.GetDataById("config_plot_episode_wedding", plot_step_id)
  end
  if step == nil then
    step = configManager.GetDataById("config_plot_episode_event", plot_step_id)
  end
  if step == nil then
    step = configManager.GetDataById("config_plot_episode_character", plot_step_id)
  end
  return step
end

function PlotMaker:GetPlotAudio(plot_step_id)
  local step = configManager.GetDataById("config_plot_episode_audio_main", plot_step_id)
  if step == nil then
    step = configManager.GetDataById("config_plot_episode_audio_wedding", plot_step_id)
  end
  if step == nil then
    step = configManager.GetDataById("config_plot_episode_audio_event", plot_step_id)
  end
  if step == nil then
    step = configManager.GetDataById("config_plot_episode_audio_character", plot_step_id)
  end
  return step
end

function PlotMaker:PlayMultiStep(steps)
  self:OpenPlotPage()
  local config = {}
  for k, v in pairs(steps) do
    local step = self:GetPlotStep(v)
    if step ~= nil then
      config[k] = step
    end
  end
  if #config and self.plotPage ~= nil then
    self.plotPage:Play(config)
  end
end

function PlotMaker:PlayTrigger(plotTriggerId)
  self:OpenPlotPage()
  local tabPlotTriggerConf = Logic.plotLogic:GetPlotTriggerConfById(plotTriggerId)
  local plotId = tabPlotTriggerConf.plot_episode_id
  local config = Logic.plotLogic:GetPlotInfo(plotId)
  if config ~= nil and self.plotPage ~= nil then
    self.plotPage:Play(config)
  end
end

function PlotMaker:SwitchAudio(step)
  local audio
  if step ~= nil then
    audio = self:GetPlotAudio(step.plot_episode_step_id)
  end
  if audio == nil then
    SoundManager.Instance:StopAllMusic()
  end
  if audio ~= nil and self.background_music ~= nil then
    if audio.background_music ~= self.background_music then
      SoundManager.Instance:StopAllMusic()
    else
      SoundManager.Instance:StopAudio(self.audio_id)
      if conditionCheckManager:Checkvalid(self.audio_effect) then
        local effects = string.split(self.audio_effect, ",")
        if 0 < #effects then
          for _, e in ipairs(effects) do
            SoundManager.Instance:StopAudio(e)
          end
        end
      end
    end
    self.background_music = audio.background_music
  else
    SoundManager.Instance:StopAllMusic()
  end
end

return PlotMaker
