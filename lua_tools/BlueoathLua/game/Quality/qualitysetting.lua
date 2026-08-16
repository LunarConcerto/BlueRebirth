local QualitySetting = class("game.Quality.QualitySetting")
local json = require("cjson")
local QualityLevel = {
  [GlobalQuality.Low] = {
    Shader = 0,
    Action = 1,
    Shadow = 0,
    AntiAliasing = 0,
    Resolution = 0,
    PostProcess = 0,
    Outline = 0,
    Fps = 0
  },
  [GlobalQuality.Medium] = {
    Shader = 1,
    Action = 2,
    Shadow = 1,
    AntiAliasing = 1,
    Resolution = 1,
    PostProcess = 0,
    Outline = 1,
    Fps = 0
  },
  [GlobalQuality.High] = {
    Shader = 2,
    Action = 4,
    Shadow = 2,
    AntiAliasing = 2,
    Resolution = 1,
    PostProcess = 1,
    Outline = 1,
    Fps = 0
  },
  [GlobalQuality.SuperHigh] = {
    Shader = 2,
    Action = 4,
    Shadow = 2,
    AntiAliasing = 2,
    Resolution = 1,
    PostProcess = 1,
    Outline = 1,
    Fps = 1
  }
}

function QualitySetting:initialize()
end

function QualitySetting:getQualityConfig(lv)
  local conf
  if lv == GlobalQuality.Custom then
    conf = self:__getCustomQuality()
  else
    conf = QualityLevel[lv]
    if DeviceAdapter.isVivoNew() then
      conf.Fps = self:getSpecialFPS()
    end
  end
  return conf
end

function QualitySetting:__getCustomQuality()
  local conf = QualityLevel[GlobalQuality.Custom]
  if conf == nil then
    conf = clone(QualityLevel[GlobalQuality.High])
    local strRecord = PlayerPrefs.GetString("customQuality")
    if strRecord ~= "" then
      local tabRecord = json.decode(strRecord)
      for k, v in pairs(conf) do
        conf[k] = tabRecord[k] or v
      end
    end
    QualityLevel[GlobalQuality.Custom] = conf
  end
  return conf
end

function QualitySetting:getCurrentLv(defaultLv)
  if self.quality == nil then
    local tmp = PlayerPrefs.GetInt("GlobalQuality", GlobalQuality.None)
    self.quality = tmp ~= GlobalQuality.None and tmp or defaultLv
  end
  return self.quality
end

function QualitySetting:setCurrentLv(lv)
  self.quality = lv
end

function QualitySetting:saveCustomQualityConfig(conf)
  local customConf = self:__getCustomQuality()
  for k, v in pairs(conf) do
    customConf[k] = v
  end
  local strRecord = json.encode(conf)
  PlayerPrefs.SetString("customQuality", strRecord)
  self:saveQuality()
end

function QualitySetting:saveQuality()
  PlayerPrefs.SetInt("GlobalQuality", self.quality)
end

function QualitySetting:saveSpecialFPS(nFPS)
  PlayerPrefs.SetInt("independentFPS", nFPS)
end

function QualitySetting:getSpecialFPS()
  return PlayerPrefs.GetInt("independentFPS", 0)
end

return QualitySetting
