local PlotManager = class("util.PlotManager")
local EditorMode = false
local MuteEffect = false
local MuteCV = false
local MuteBackgroundMusic = false
local MuteExchangedMusic = false
local passTable = {}
local today
local toggleSkipTips = false
local history = {}
local plotOver = false
local MapSettingBefore = {}
local MapSettingAfter = {}
local openFullPage = {
  [PlotTriggerType.copy_start_after_cg] = 1,
  [PlotTriggerType.fleetbattle_after_cg] = 2,
  [PlotTriggerType.fleetbattle_before_count] = 3,
  [PlotTriggerType.copy_start_before_cg] = 4
}

function PlotManager:initialize()
  self.triggerTypeImp = {
    [PlotTriggerType.copy_start_before_cg] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.copy_start_after_cg] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.discovery_fleet] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.fleetbattle_before_cg] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.fleetbattle_after_cg] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.fleetenemy_blood] = function(param, plotInfos)
      return self:_FleetEnemyBlood(param, plotInfos)
    end,
    [PlotTriggerType.fleetbattle_before_count] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.fleetbattle_after_count] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.copy_end_count] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.plot_episode_reward] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.receive_task] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.complete_task] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.newplayer_guide] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.plot_episode_branch] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.plot_copy_display_trigger] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.marriage_before] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.marriage_after] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.character_story] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.mini_game_2d_start] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.mini_game_2d_fail] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end,
    [PlotTriggerType.mini_game_2d_success] = function(param, plotInfos)
      return self:_DefaultTrigger(param, plotInfos)
    end
  }
  self.objNetCache = require("Game.Guide.Kits.GuideNetCache"):new()
  self.daytimespan = 86400
  self.__read_plot_history = nil
end

function PlotManager:_CheckCanTrigger(plotTriggerId)
  return true
end

function PlotManager:OpenPlotPage(plotTriggerId, battleMode, callback)
  if plotTriggerId and self:_CheckCanTrigger(plotTriggerId) then
    local function callFunc()
      UIHelper.OpenPage("PlotPage", {
        PlotTriggerId = plotTriggerId,
        
        battleMode = battleMode,
        callback = callback
      })
    end
    
    plotTriggerTypeId = Logic.plotLogic:GetPlotTriggerConfById(plotTriggerId).plot_trigger_type_id
    if openFullPage[plotTriggerTypeId] ~= nil then
      callFunc()
    else
      do
        local pageName = "StartAnimationPage"
        UIHelper.OpenPage(pageName)
        local openEffTimer = Timer.New(function()
          UIHelper.ClosePage(pageName)
          UIHelper.SetUILock(false)
          callFunc()
        end, 0.8, 1)
        openEffTimer:Start()
      end
    end
  end
end

function PlotManager:OpenPlotPageByMarry(plotTriggerId)
  if plotTriggerId and self:_CheckCanTrigger(plotTriggerId) then
    local pageName = UIHelper.OpenPage("PlotPage", {PlotTriggerId = plotTriggerId})
    self.MarryPlotPage = pageName
  end
end

function PlotManager:OpenPlotByType(ptype, param, battleMode, callback)
  self:OpenPlotPageByType(ptype, param, battleMode, callback)
  self:DisPlatSetting(ptype, param)
end

function PlotManager:GetTriggerId(ptype, param)
  local plotInfos = Logic.plotLogic:GetPlotTriggerConfigByType(ptype)
  if plotInfos then
    return self.triggerTypeImp[ptype](param, plotInfos)
  end
end

function PlotManager:OpenPlotPageByType(ptype, param, battleMode, callback)
  local plotInfos = Logic.plotLogic:GetPlotTriggerConfigByType(ptype)
  if plotInfos then
    local triggerId = self.triggerTypeImp[ptype](param, plotInfos)
    if not triggerId and ptype == 15 then
      logError("\228\184\141\229\173\152\229\156\168\231\177\187\229\158\139\228\184\186" .. tostring(ptype) .. "\229\143\130\230\149\176\228\184\186" .. tostring(param) .. "\231\154\132\229\137\167\230\131\133\239\188\140\232\175\183\231\173\150\229\136\146\230\163\128\230\159\165\233\133\141\231\189\174\232\161\168~~")
    end
    if ptype == PlotTriggerType.marriage_before or ptype == PlotTriggerType.marriage_after then
      self:OpenPlotPageByMarry(triggerId)
    else
      self:OpenPlotPage(triggerId, battleMode, callback)
    end
  end
  eventManager:SendEvent(LuaEvent.PlotTrigger, {ptype, param})
end

function PlotManager:DisPlatSetting(ptype, param)
  local copyInfo = Logic.copyLogic:GetAttackCopyInfo()
  if ptype == PlotTriggerType.fleetbattle_before_cg then
    MapSettingBefore[SettingDict.SkipMySkillAnim] = CacheUtil.GetIsSkipSkillAnimIndex(true)
    MapSettingBefore[SettingDict.SkipEnemySkillAnim] = CacheUtil.GetIsSkipSkillAnimIndex(false)
    MapSettingBefore[SettingDict.SkipOtherAnim] = CacheUtil.GetSkipSkillAnimResult()
    MapSettingBefore[SettingDict.SkipEnemyTorpedoAnim] = CacheUtil.GetSkipEnemyTorpedoPlayAnim()
    Logic.setLogic:NilSetting(ptype, param)
  elseif ptype == PlotTriggerType.fleetbattle_before_count then
    MapSettingAfter = nil
  end
  local enemyFleet = configManager.GetData("config_sp_settings_fleet_dict")
  if ptype == PlotTriggerType.fleetbattle_before_cg or ptype == PlotTriggerType.fleetbattle_before_count then
    for k, v in pairs(enemyFleet) do
      if v.sp_setting_copy_id == copyInfo.CopyId and v.sp_setting_fleet_id == param then
        for index, value in pairs(v.sp_setting) do
          self:SaveSettingData(ptype, value)
          if ptype == PlotTriggerType.fleetbattle_before_cg then
            if MapSettingAfter == nil then
              MapSettingAfter = {}
            end
            MapSettingAfter[value[1]] = value[2] == 1
          end
        end
      end
    end
    Logic.setLogic:SetSettingAfter(MapSettingAfter)
  end
end

function PlotManager:SaveSettingData(ptype, value)
  local isTrue
  if ptype == PlotTriggerType.fleetbattle_before_cg then
    isTrue = value[2] == 1
  else
    isTrue = MapSettingBefore[value[1]]
  end
  if value[1] == SettingDict.SkipMySkillAnim then
    PlotManager.ForceSettings[value[1]](true, isTrue)
  elseif value[1] == SettingDict.SkipEnemySkillAnim then
    PlotManager.ForceSettings[value[1]](false, isTrue)
  else
    PlotManager.ForceSettings[value[1]](isTrue)
  end
end

function PlotManager:GetMarryPlotPage()
  return self.MarryPlotPage
end

function PlotManager:CheckPlot(ptype, param)
  local plotInfos = Logic.plotLogic:GetPlotTriggerConfigByType(ptype)
  if plotInfos then
    local triggerId = self.triggerTypeImp[ptype](param, plotInfos)
    return triggerId
  end
  return false
end

function PlotManager:PlotEnd(triggerId)
  self:MarryEndBefore()
  eventManager:SendEvent(LuaEvent.PlotEnd, triggerId)
  local info = Logic.plotLogic:GetPlotTriggerConfById(triggerId)
  if info and info.plot_trigger_end > 0 then
    eventManager:SendEvent(LuaEvent.PlotTriggerEnd, info.plot_trigger_end)
    self:ClearHistory()
    eventManager:FireEventToCSharp(LuaCSharpEvent.PlotEnd)
  end
  self:SavePlayerPres()
end

function PlotManager:SetMarryEff(effectObj, obj_self)
  self.effectObj = effectObj
  self.obj_self = obj_self
  self.isMarry = true
end

function PlotManager:GetMarryEff()
  return self.effectObj
end

function PlotManager:MarryEndBefore()
  if self.isMarry then
    self.isMarry = false
    self.effectObj.transform:SetParent(self.obj_self.gameObject.transform)
  end
end

function PlotManager:_DefaultTrigger(param, plotInfos)
  if param then
    for k, v in pairs(plotInfos) do
      local info = v.plot_trigger_parameter
      if info ~= nil and 0 < #info then
        for x, y in pairs(info) do
          if y == param then
            return v.plot_trigger_id
          end
        end
      end
    end
  end
  return nil
end

function PlotManager:_FleetEnemyBlood(param, plotInfos)
  if param then
    local id = param[1]
    local blood = param[2]
    for k, v in pairs(plotInfos) do
      local info = v.plot_trigger_parameter
      if info ~= nil and 0 < #info then
        for x, y in pairs(info) do
          if y[1] == id and blood <= y[2] then
            return v.plot_trigger_id
          end
        end
      end
    end
  end
end

function PlotManager:OpenEditorMode()
  self.EditorMode = true
end

function PlotManager:GetReadPassFlag(plotID)
  return self.passTable[plotID]
end

function PlotManager:SetReadPassFlag(plotID)
  if self.passTable == nil then
    self.passTable = {}
  end
  self.passTable[plotID] = true
  local strVal = Serialize(self.passTable)
  self.objNetCache:sentNet(UserSettingsKey.PlotPassKey, strVal)
end

function PlotManager:SetToggleSkipTip(yes)
  local time = -1
  local val = 0
  if yes == true then
    time = os.time()
    self.today = -1
    self:FormatToday()
    val = 1
  end
  self.objNetCache:sentNet(UserSettingsKey.PlotUtcTimeKey, tostring(time))
  self.toggleSkipTips = yes
  self.objNetCache:sentNet(UserSettingsKey.PlotToggleSkipTipKey, tostring(val))
end

function PlotManager:InitPlotPassFlags(param)
  if next(param.Setting) ~= nil then
    for _, v in ipairs(param.Setting) do
      if v.Key == UserSettingsKey.PlotPassKey then
        self.passTable = Unserialize(v.Value)
      end
      if v.Key == UserSettingsKey.PlotUtcTimeKey then
        self.today = tonumber(v.Value)
        self:FormatToday()
      end
      if v.Key == UserSettingsKey.PlotToggleSkipTipKey then
        local val = tonumber(v.Value)
        if val == 1 then
          self.toggleSkipTips = true
        else
          self.toggleSkipTips = false
        end
      end
    end
  end
  if self.passTable == nil then
    self.passTable = {}
  end
  if self.today == nil then
    self:FormatToday()
  end
  if self.toggleSkipTips == nil then
    self.toggleSkipTips = false
  end
end

function PlotManager:CheckToday()
  return self.LocalTime() - self.today < self.daytimespan
end

function PlotManager:CheckTomorrow()
  return self.LocalTime() - self.today >= self.daytimespan
end

function PlotManager:FormatToday()
  if self.today == nil or self.today == -1 then
    self.today = self.LocalTime()
  end
  self.today, _ = math.modf(self.today / self.daytimespan)
  self.today = self.today * self.daytimespan
end

function PlotManager:LocalTime()
  return os.time() - time.getTimeZoneOffset()
end

function PlotManager:Record(step)
  if self.history == nil then
    self.history = {}
  end
  local have
  for k, v in pairs(self.history) do
    if v.plot_episode_step_id == step.plot_episode_step_id then
      have = k
    end
  end
  if have ~= nil then
    self.history[have] = step
  else
    table.insert(self.history, step)
  end
  self:RecordStepToLocalHistory(step)
end

function PlotManager:GetRecords()
  if self.history == nil then
    self.history = {}
  end
  return self.history
end

function PlotManager:RecordBranch(plot_stepID, item)
  if self.brancHistory == nil then
    self.brancHistory = {}
  end
  if self.brancHistory[plot_stepID] == nil then
    self.brancHistory[plot_stepID] = {}
  end
  table.insert(self.brancHistory[plot_stepID], item)
  return self.history
end

function PlotManager:GetBranchRecords()
  if self.brancHistory == nil then
    self.brancHistory = {}
  end
  return self.brancHistory
end

function PlotManager:ClearHistory()
  self.history = {}
  self.brancHistory = {}
end

PlotManager.ForceSettings = {
  [SettingDict.SkipMySkillAnim] = CacheUtil.SetSkipIsSkillAnimIndex,
  [SettingDict.SkipEnemySkillAnim] = CacheUtil.SetSkipIsSkillAnimIndex,
  [SettingDict.SkipOtherAnim] = CacheUtil.SetSkipSkillAnimResul,
  [SettingDict.SkipEnemyTorpedoAnim] = CacheUtil.SetSkipEnemyTorpedoPlayAnim
}

function PlotManager:LoadPlayerPres()
  if self.__read_plot_history ~= nil then
    return
  end
  self.__read_plot_history = {}
  local uid = Data.userData:GetUserUid()
  local strRecord = PlayerPrefs.GetString(uid .. "___plot_history__")
  if strRecord == nil then
    return
  end
  local his = string.split(strRecord, ";")
  for k, v in pairs(his) do
    if v ~= nil and v ~= "" then
      self.__read_plot_history[tonumber(v)] = tonumber(v)
    end
  end
end

function PlotManager:RecordStepToLocalHistory(plotInfo)
  self:LoadPlayerPres()
  self.__read_plot_history[plotInfo.plot_episode_step_id] = plotInfo.plot_episode_step_id
end

function PlotManager:SavePlayerPres()
  local strRecord = ""
  self:LoadPlayerPres()
  for k, v in pairs(self.__read_plot_history) do
    strRecord = strRecord .. ";" .. v
  end
  local uid = Data.userData:GetUserUid()
  PlayerPrefs.SetString(uid .. "___plot_history__", strRecord)
end

function PlotManager:CheckShowTip(plotinfo)
  self:LoadPlayerPres()
  return self.__read_plot_history[plotinfo.plot_episode_step_id] ~= nil
end

return PlotManager
