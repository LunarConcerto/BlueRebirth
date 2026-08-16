local HomeEnvManager = class("util.HomeEnvManager")
local m_Scenes = {
  [SceneType.HOME] = function()
    return homeEnvManager:GetHomeScenePath()
  end,
  [SceneType.BUILD] = function()
    return homeEnvManager:GetBuildScenePath()
  end,
  [SceneType.BATHROOM] = function()
    return "scenes/cj_weixiu_01"
  end,
  [SceneType.LOGIN] = function()
    return "scenes/login_enter"
  end,
  [SceneType.MARRY] = function()
    return homeEnvManager:GetMarryScenePath()
  end,
  [SceneType.RESTAURANTE] = function()
    return "scenes/cj_hz_jjw"
  end,
  [SceneType.TOWER] = function()
    return "scenes/sd_tower"
  end,
  [SceneType.Office] = function()
    return "scenes/cj_hz_tds_01"
  end,
  [SceneType.ElectricFactory] = function()
    return "scenes/cj_hz_fdz"
  end,
  [SceneType.OilFactory] = function()
    return "scenes/cj_lyc_01"
  end,
  [SceneType.ResourceFactory] = function()
    return "scenes/cj_hz_jjw"
  end,
  [SceneType.DormRoom] = function(params)
    return homeEnvManager:GetDormScenePath(params)
  end,
  [SceneType.FoodFactory] = function()
    return "scenes/cj_ct_01"
  end,
  [SceneType.ItemFactory] = function()
    return "scenes/cj_hz_scb"
  end,
  [SceneType.MiniGame] = function(params)
    return Logic2d:GetSceneStr(params)
  end,
  [SceneType.Remould] = function(params)
    return homeEnvManager:GetRemouldScenePath(params)
  end,
  [SceneType.Mubar] = function()
    return "scenes/cj_mb_01"
  end,
  [SceneType.MultiPveAct] = function()
    return "scenes/boss_001"
  end
}
local m_ScenesAddTime = {
  [SceneType.BATHROOM] = configManager.GetDataById("config_parameter", 73).value / 10000
}
local m_OpenCondition = {
  level = function(param)
    return homeEnvManager:_CheckLevel(param)
  end
}

function HomeEnvManager:initialize()
  self.m_addTime = 0
  self.m_homeBgm = nil
  self.configInfo = nil
  self.homeScenePath = nil
  self.m_sceneId = 1
end

function HomeEnvManager:ResetTime()
  self.m_addTime = 0
  self.m_homeBgm = nil
  self.configInfo = nil
  self.homeScenePath = nil
end

function HomeEnvManager:GetRemouldScenePath(params)
  local index = params.index
  local scenePath = "scenes/remould"
  return scenePath
end

function HomeEnvManager:GetBuildScenePath()
  local scenePath = "scenes/cj_zjm_001"
  if self.homeScenePath ~= nil then
    scenePath = self.homeScenePath
  end
  return scenePath
end

function HomeEnvManager:GetMarryScenePath()
  local scenePath = configManager.GetDataById("config_parameter", 191).arrValue[1]
  return scenePath
end

function HomeEnvManager:GetDormScenePath(params)
  local index = params.index
  local paths = {
    "cj_hz_ssh_01",
    "cj_hz_ssh_02",
    "cj_hz_ssh_03"
  }
  local scenePath = string.format("scenes/%s", paths[index])
  return scenePath
end

function HomeEnvManager:GetHomeScenePath()
  local defaultSceneType = configManager.GetDataById("config_parameter", 173).value
  local sceneType = PlayerPrefs.GetInt("HomeSceneType", Mathf.ToInt(defaultSceneType))
  if self.configInfo == nil then
    local config = configManager.GetData("config_home_scene_envir")
    self.configInfo = {}
    for i, v in ipairs(config) do
      if self.configInfo[v.type] == nil then
        self.configInfo[v.type] = {}
      end
      table.insert(self.configInfo[v.type], v)
    end
  end
  local time = os.date("*t", os.time() + self.m_addTime)
  local hour = time.hour
  hour = 24 + hour - 7 - math.floor((24 + hour - 7) / 24) * 24
  local totalSec = hour * 60 * 60 + time.min * 60 + time.sec
  local cycleSec = configManager.GetDataById("config_parameter", 71).value / 10000 * 60 * 60
  local curSec = totalSec - math.floor(totalSec / cycleSec) * cycleSec
  local oneHourSec = cycleSec / 24
  local curHour = curSec / oneHourSec
  local configTab = self.configInfo[sceneType]
  if configTab == nil then
    logError("\228\184\187\229\156\186\230\153\175\231\142\175\229\162\131\231\179\187\231\187\159\230\178\161\230\156\137\230\137\190\229\136\176\229\189\147\229\137\141\231\177\187\229\158\139\229\175\185\229\186\148\231\154\132\233\133\141\231\189\174,\232\175\183\231\173\150\229\136\146\231\161\174\232\174\164\233\133\141\231\189\174\232\161\168,\229\189\147\229\137\141\231\177\187\229\158\139" .. tostring(sceneType))
    return
  end
  local length = GetTableLength(configTab)
  local scenesTab = {}
  for i = 1, length do
    if curHour >= configTab[i].time_frame[1] and curHour <= configTab[i].time_frame[2] and self:_CheckSceneOpen(configTab[i]) then
      table.insert(scenesTab, configTab[i])
    end
  end
  local scenePath = "scenes/cj_zjm_001"
  if #scenesTab < 1 then
    logError("\228\184\187\229\156\186\230\153\175\231\142\175\229\162\131\231\179\187\231\187\159\230\178\161\230\156\137\230\137\190\229\136\176\229\144\136\233\128\130\231\154\132\228\184\187\229\156\186\230\153\175\239\188\140\232\175\183\231\173\150\229\136\146\231\161\174\232\174\164\233\133\141\231\189\174\232\161\168")
  else
    scenePath = self:_WeightRandom(scenesTab)
  end
  self.homeScenePath = scenePath
  return scenePath
end

function HomeEnvManager:_CheckSceneOpen(scenesTab)
  local length = #scenesTab.restrictive_condition_type
  if 0 < length then
    for i = 1, length do
      if not scenesTab.restrictive_condition_parameter[i] then
        logError("\232\175\183\231\173\150\229\136\146\231\161\174\232\174\164home_scene_envir\232\161\168\228\184\173\233\153\144\229\136\182\230\157\161\228\187\182\229\146\140\229\143\130\230\149\176\229\175\185\229\186\148\230\149\176\233\135\143\230\173\163\231\161\174")
        return true
      end
      if not m_OpenCondition[scenesTab.restrictive_condition_type[i]](scenesTab.restrictive_condition_parameter[i]) then
        return false
      end
    end
  end
  return true
end

function HomeEnvManager:_CheckLevel(param)
  return param <= Data.userData:GetUserLevel()
end

function HomeEnvManager:_WeightRandom(scenesTab)
  if 1 < #scenesTab then
    for i = 1, #scenesTab do
      if 1 < i then
        scenesTab[i].weight = scenesTab[i].weight + scenesTab[i - 1].weight
      end
    end
    local maxWeight = scenesTab[#scenesTab].weight
    local randomWeight = math.random(maxWeight)
    for i = 1, #scenesTab do
      if randomWeight <= scenesTab[i].weight then
        local periodBgm = self:_GetPeriodBgm()
        if periodBgm then
          self.m_homeBgm = scenesTab[i][periodBgm]
        else
          self.m_homeBgm = scenesTab[i].envir_bgm
        end
        self:_SetSceneId(scenesTab[i].id)
        return scenesTab[i].envir_resource
      end
    end
  else
    local periodBgm = self:_GetPeriodBgm()
    if periodBgm then
      local bgm = scenesTab[1][periodBgm]
      self.m_homeBgm = bgm
    else
      self.m_homeBgm = scenesTab[1].envir_bgm
    end
    self:_SetSceneId(scenesTab[1].id)
    return scenesTab[1].envir_resource
  end
end

function HomeEnvManager:_GetPeriodBgm()
  local periodConfig = configManager.GetData("config_activity_bgm_period")
  local tempConfig = {}
  for k, v in pairs(periodConfig) do
    if PeriodManager:IsInPeriod(v.period) then
      table.insert(tempConfig, v)
    end
  end
  if 0 < #tempConfig then
    table.sort(tempConfig, function(l, r)
      return l.weights > r.weights
    end)
    return tempConfig[1].envir_bgm
  end
  return nil
end

function HomeEnvManager:ChangeSceneByPath(path)
  return GR.sceneManager:ChangeScene(path)
end

function HomeEnvManager:ChangeScene(sceneType, refresh, params)
  local time = m_ScenesAddTime[sceneType]
  time = time or 0
  time = time * 60 * 60
  self.m_addTime = self.m_addTime + time
  local path = m_Scenes[sceneType](params)
  refresh = refresh and refresh or false
  return GR.sceneManager:ChangeScene(path, refresh)
end

function HomeEnvManager:EnterBattle()
  local time = configManager.GetDataById("config_parameter", 72).value / 10000
  time = time * 60 * 60
  self.m_addTime = self.m_addTime + time
end

function HomeEnvManager:PlayHomeBgm()
  if self.m_homeBgm ~= nil then
    SoundManager.Instance:PlayMusic(self.m_homeBgm)
  else
    SoundManager.Instance:PlayMusic("System|Homeport")
  end
end

function HomeEnvManager:_SetSceneId(sceneId)
  self.m_sceneId = sceneId
end

function HomeEnvManager:GetSceneId()
  return self.m_sceneId
end

function HomeEnvManager:GetCurrScene()
  return self.homeScenePath
end

function HomeEnvManager:_SetCurrBgm(scenesTab, index)
  local selectBgm = Logic.homeLogic:GetCurrentBgmConfig()
  if selectBgm.order > 1 then
    self.m_selectBgm = selectBgm.switch_name
  else
    local periodBgm = self:_GetPeriodBgm()
    if periodBgm then
      self.m_homeBgm = scenesTab[index][periodBgm]
    else
      self.m_homeBgm = scenesTab[index].envir_bgm
    end
  end
end

function HomeEnvManager:SetSelectBgm(bgmName)
  self.m_selectBgm = bgmName
  self:PlayHomeBgm()
end

return HomeEnvManager
