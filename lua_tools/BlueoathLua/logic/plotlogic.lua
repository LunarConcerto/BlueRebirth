local PlotLogic = class("logic.PlotLogic")

function PlotLogic:initialize()
end

function PlotLogic:RefreshPlotEpisodeConfig()
  self.plotEpisodeCofig = nil
  self:GetPlotEpisodeConfig()
end

function PlotLogic:RefreshPlotTriggerConfig()
  self.plotTriggerConfig = nil
  self:GetPlotTriggerConfig()
end

function PlotLogic:GetPlotEpisodeConfig()
  if self.plotEpisodeCofig == nil then
    self.plotEpisodeCofig = {}
    local plotData = configManager.GetData("config_plot_episode_main")
    self:FillPlotEpisodeConfig(plotData)
    plotData = configManager.GetData("config_plot_episode_event")
    self:FillPlotEpisodeConfig(plotData)
    plotData = configManager.GetData("config_plot_episode_wedding")
    self:FillPlotEpisodeConfig(plotData)
    plotData = configManager.GetData("config_plot_episode_character")
    self:FillPlotEpisodeConfig(plotData)
  end
  return self.plotEpisodeCofig
end

local plot_episodeNames = {
  plot_episode_main = "config_plot_episode_main",
  plot_episode_event = "config_plot_episode_event",
  plot_episode_wedding = "config_plot_episode_wedding",
  plot_episode_character = "config_plot_episode_character"
}
local plot_episode_AudioNames = {
  plot_episode_main = "config_plot_episode_audio_main",
  plot_episode_event = "config_plot_episode_audio_event",
  plot_episode_wedding = "config_plot_episode_audio_wedding",
  plot_episode_character = "config_plot_episode_audio_character"
}

function PlotLogic:GetPlotEpisodeConfigByTrigger(trigger)
  if self.plotEpisodeCofig == nil then
    self.plotEpisodeCofig = {}
  end
  if self.plotEpisodeCofig[trigger.plot_episode_id] ~= nil then
    return self.plotEpisodeCofig[trigger.plot_episode_id]
  end
  local rows = {}
  local steps = string.split(trigger.plot_steps, ",")
  for k, v in pairs(steps) do
    if v ~= "0" then
      local r = configManager.GetDataById(plot_episodeNames[trigger.plot_tableName], v)
      if v ~= nil then
        table.insert(rows, r)
      end
    end
  end
  self:FillPlotEpisodeConfig(rows)
  return self.plotEpisodeCofig[trigger.plot_episode_id]
end

function PlotLogic:FillPlotEpisodeConfig(plotData)
  for k, v in pairs(plotData) do
    if self.plotEpisodeCofig[v.plot_episode_id] == nil then
      self.plotEpisodeCofig[v.plot_episode_id] = {}
    end
    table.insert(self.plotEpisodeCofig[v.plot_episode_id], v)
  end
  for k, v in pairs(self.plotEpisodeCofig) do
    table.sort(v, function(a, b)
      return a.step < b.step
    end)
  end
end

function PlotLogic:GetPlotTriggerConfig()
  if self.plotTriggerConfig == nil then
    self.plotTriggerConfig = {}
    local plotData = configManager.GetData("config_plot_episode_trigger")
    for k, v in pairs(plotData) do
      if self.plotTriggerConfig[v.plot_trigger_type_id] == nil then
        self.plotTriggerConfig[v.plot_trigger_type_id] = {}
      end
      table.insert(self.plotTriggerConfig[v.plot_trigger_type_id], v)
    end
  end
  return self.plotTriggerConfig
end

function PlotLogic:GetPlotInfo(plotId)
  local plotData = self:GetPlotEpisodeConfig()
  return plotData[plotId]
end

function PlotLogic:GetPlotInfoByTrigger(trigger)
  local plotData = self:GetPlotEpisodeConfigByTrigger(trigger)
  self._audioTableName = plot_episode_AudioNames[trigger.plot_tableName]
  return plotData
end

function PlotLogic:GetPlotTriggerConfigByType(plotType)
  local plotData = self:GetPlotTriggerConfig()
  return plotData[plotType]
end

function PlotLogic:GetPlotTriggerConfById(id)
  return configManager.GetDataById("config_plot_episode_trigger", id)
end

function PlotLogic:GetPlotShipConfById(id)
  return configManager.GetDataById("config_plot_episode_ship", id)
end

function PlotLogic:GetPlotTweenInfoConfigById(id)
  return configManager.GetDataById("config_plot_episode_tween", id)
end

function PlotLogic:GetPlotEffectConfById(id)
  return configManager.GetDataById("config_plot_episode_effect", id)
end

function PlotLogic:GetPlotAudioInfoConfigById(id, plot)
  return configManager.GetDataById(self._audioTableName, id)
end

function PlotLogic:GetPlotExpressionInfoConfigById(id)
  return configManager.GetDataById("config_plot_episode_expression", id)
end

function PlotLogic:GetPlotTweensConfig(tweens, pos)
  local tweentable = {}
  local tweeninfo
  if 0 < #tweens then
    for k, v in pairs(tweens) do
      if v ~= nil and 1 < #v and v[1] == pos then
        local __tweeninfo = self:GetPlotTweenInfoConfigById(v[2])
        if __tweeninfo ~= nil then
          table.insert(tweentable, __tweeninfo)
        end
      end
    end
  end
  return tweentable
end

function PlotLogic:GetPlotTweenEffectConfig(tweens)
  local tweentable = {}
  local tweeninfo
  if 0 < #tweens then
    for k, tweenId in pairs(tweens) do
      if tweenId ~= nil then
        tweeninfo = self:GetPlotTweenInfoConfigById(tweenId)
        if tweeninfo ~= nil then
          table.insert(tweentable, tweeninfo)
        end
      end
    end
  end
  return tweentable
end

function PlotLogic:AddRoleInfo(addToTab, pos, tabkerId)
  for k, v in pairs(addToTab) do
    if v.TalkerId == tabkerId then
      if v.Pos ~= pos then
        v.Pos = pos
      end
      return
    end
  end
  table.insert(addToTab, {Pos = pos, TalkerId = tabkerId})
end

function PlotLogic:DeleteRoleInfo(removeToTab, talkerId, isDelete)
  for k, v in ipairs(removeToTab) do
    if isDelete then
      if v.TalkerId == talkerId then
        table.remove(removeToTab, k)
      end
    elseif v.TalkerId ~= talkerId then
      table.remove(removeToTab, k)
    end
  end
end

function PlotLogic:ModifyRoleAttr(tab, talkerId, pos)
  for k, v in ipairs(tab) do
    if v.TalkerId == talkerId then
      v.Pos = pos
      return
    end
  end
end

function PlotLogic:SetPlotBranch(plotInfo)
  local tabTemp = {}
  local temp
  if next(plotInfo.branch1_parameter) ~= nil then
    temp = {
      Param = plotInfo.branch1_parameter,
      Name = plotInfo.plot_episode_branch1_name
    }
    table.insert(tabTemp, temp)
  end
  if next(plotInfo.branch2_parameter) ~= nil then
    temp = {
      Param = plotInfo.branch2_parameter,
      Name = plotInfo.plot_episode_branch2_name
    }
    table.insert(tabTemp, temp)
  end
  if next(plotInfo.branch3_parameter) ~= nil then
    temp = {
      Param = plotInfo.branch3_parameter,
      Name = plotInfo.plot_episode_branch3_name
    }
    table.insert(tabTemp, temp)
  end
  if next(plotInfo.branch4_parameter) ~= nil then
    temp = {
      Param = plotInfo.branch4_parameter,
      Name = plotInfo.plot_episode_branch4_name
    }
    table.insert(tabTemp, temp)
  end
  return tabTemp
end

function PlotLogic:GetPlotBranchOptionOfEnd(plotInfo)
  if next(plotInfo.branch1_parameter) ~= nil then
    temp = {
      Param = plotInfo.branch1_parameter,
      Name = plotInfo.plot_episode_branch1_name
    }
    return temp
  end
  return nil
end

function PlotLogic:GetPlotMultiBranchOptionOfEnd(branchTree)
  local node = branchTree
  while node ~= nil do
    node = node.child[1]
  end
  return node
end

function PlotLogic:CheckPlotTriggerd(triggerId)
  local userData = Data.userData:GetUserData()
  logError(userData)
end

function PlotLogic:SetPlotTriggerd()
end

function PlotLogic:CreateSelectiveTree(text)
  if string.sub(text, 1, 1) == "(" then
    text = string.sub(text, 2, string.len(text) - 1)
  end
  local root = {}
  root.info = nil
  root.parent = nil
  root.childstring = text
  local stack = {}
  table.insert(stack, 1, root)
  while 0 < #stack do
    local node = stack[#stack]
    stack[#stack] = nil
    if node.childstring ~= nil and node.childstring ~= "" then
      local slice, params = self:ParseBranchText(node.childstring)
      if 0 < #slice then
        local child = {}
        for i = 1, #slice do
          local c = {}
          c.info = slice[i]
          c.parent = node
          c.childstring = params[i]
          table.insert(child, c)
          table.insert(stack, 1, c)
        end
        node.child = child
      end
    end
  end
  return root
end

function PlotLogic:ParseBranchText(text)
  if text == nil or text == "" then
    return nil
  end
  local slice = {}
  local params = {}
  local startF = 1
  local startParamsF = 0
  local leftCount = 0
  local rightCount = 0
  local call_params = false
  local index = 1
  local len = string.len(text)
  while index <= len do
    local byte = string.byte(text, index)
    if call_params == false then
      if byte == 44 and startF <= index - 1 then
        table.insert(slice, string.sub(text, startF, index - 1))
        startF = index + 1
      end
      if byte == 40 then
        table.insert(slice, string.sub(text, startF, index - 1))
        startParamsF = index + 1
        call_params = true
      end
    end
    if call_params == true then
      if byte == 40 then
        leftCount = leftCount + 1
      end
      if byte == 41 then
        rightCount = rightCount + 1
      end
      if leftCount == rightCount then
        params[#slice] = string.sub(text, startParamsF, index - 1)
        startParamsF = 0
        startF = index + 2
        index = startF
        call_params = false
      end
    end
    index = index + 1
  end
  while 1 <= len do
    local byte = string.byte(text, len)
    if byte == 44 then
      table.insert(slice, string.sub(text, len + 1, string.len(text)))
      break
    end
    if byte == 41 then
      break
    end
    len = len - 1
    if len == 0 then
      table.insert(slice, string.sub(text, 1, string.len(text)))
    end
  end
  return slice, params
end

function PlotLogic:GetBranchConfigByID(id)
  return configManager.GetDataById("config_plot_episode_branch", id)
end

return PlotLogic
