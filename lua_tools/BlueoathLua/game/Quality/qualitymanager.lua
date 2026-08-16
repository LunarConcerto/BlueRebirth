local QualityManager = class("game.Quality.QualityManager")
require("game.Quality.DeviceAdapter")
vivoSDKInterface = require("game.vivoSDKInterface.vivoSDKInterface"):new()
local QualityName = {
  "Low",
  "Medium",
  "High"
}

function QualityManager:initialize()
  self.setting = require("game.Quality.QualitySetting"):new()
  local defaultLv = DeviceAdapter.getDefaultQuality()
  PlatformWrapper:setInitRetention(QualityName[defaultLv])
  QualityHelper.SetInstancingBug(DeviceAdapter.isInstancingBug())
  QualityHelper.SetRGBAHalfClose(DeviceAdapter.isRGBAHalfClose())
  QualityHelper.SetForceARGBHalf(DeviceAdapter.isForceARGBHalf())
  local width = BabelTimeSDK.GetScreenWidth()
  local unsafeSize = BabelTimeSDK.GetDangerWidth() + DeviceAdapter.getUnsafeOffset()
  ResolutionHelper.Init(unsafeSize / width)
  UIManager:SetAdaptive()
  local curLv = self:getGlobalQuality(defaultLv)
  self.originDic = self.setting:getQualityConfig(curLv)
  self.cacheDic = {}
  self:__registerAllEvents()
  self:__registerQualityHandler()
  self:__highFpsCheck()
  self:setGlobalQuality(curLv)
  self.bvivoNew = DeviceAdapter.isVivoNew()
end

function QualityManager:__registerAllEvents()
  eventManager:RegisterEvent(LuaCSharpEvent.QualityAutoReduce, function(self)
    self:__onAutoReduce()
  end, self)
end

function QualityManager:__onAutoReduce()
  local curQuality = self:getGlobalQuality()
  if curQuality ~= GlobalQuality.Low and curQuality ~= GlobalQuality.Custom then
    curQuality = curQuality - 1
    self:setGlobalQuality(curQuality)
    self:saveAll()
  end
end

function QualityManager:__registerQualityHandler()
  self.handlerDic = {}
  self.handlerDic[QualityType.ShaderQuality] = require("game.Quality.Setting.ShaderSetting"):new()
  self.handlerDic[QualityType.ActionQuality] = require("game.Quality.Setting.ActionSetting"):new()
  self.handlerDic[QualityType.ShadowQuality] = require("game.Quality.Setting.ShadowSetting"):new()
  self.handlerDic[QualityType.AntiAliasingQuality] = require("game.Quality.Setting.AntiAliasingSetting"):new()
  self.handlerDic[QualityType.ResolutionQuality] = require("game.Quality.Setting.ResolutionSetting"):new()
  self.handlerDic[QualityType.PostProcessQuality] = require("game.Quality.Setting.PostProcessSetting"):new()
  self.handlerDic[QualityType.OutlineQuality] = require("game.Quality.Setting.OutlineSetting"):new()
  self.handlerDic[QualityType.FpsQuality] = require("game.Quality.Setting.FpsSetting"):new()
end

function QualityManager:getSettingByType(qualityType)
  return self.handlerDic[qualityType]
end

function QualityManager:getGlobalQuality(defaultLv)
  return self.setting:getCurrentLv(defaultLv)
end

function QualityManager:setGlobalQuality(lv)
  self.originDic = self.setting:getQualityConfig(lv)
  for k, v in pairs(self.originDic) do
    if k == QualityType.FpsQuality then
      self:__checkVivoNewFPS(v, k)
    else
      self:setQualityLvByType(v, k)
    end
  end
  self.setting:setCurrentLv(lv)
end

function QualityManager:__checkVivoNewFPS(v, k)
  local isVivoNew = DeviceAdapter.isVivoNew()
  if not isVivoNew then
    self:setQualityLvByType(v, k)
  else
    local nLv = self.cacheDic[QualityType.FpsQuality]
    if nLv == nil then
      nLv = self:getQualityLvByType(QualityType.FpsQuality)
    end
    self:setQualityLvByType(nLv, QualityType.FpsQuality)
  end
end

function QualityManager:setQualityLvByType(lv, qualityType)
  local handler = self.handlerDic[qualityType]
  handler:setQualityLv(lv)
  self.cacheDic[qualityType] = lv
end

function QualityManager:getQualityLvByType(qualityType)
  return self.originDic[qualityType]
end

function QualityManager:saveAll()
  if DeviceAdapter.isVivoNew() then
    self:__vivoSpecialSaveAll()
  else
    self:__nomalSaveAll()
  end
end

function QualityManager:__nomalSaveAll()
  local bChanged = false
  for k, v in pairs(self.cacheDic) do
    if v ~= self.originDic[k] then
      bChanged = true
      break
    end
  end
  if bChanged then
    self.setting:setCurrentLv(GlobalQuality.Custom)
    self.setting:saveCustomQualityConfig(self.cacheDic)
    self.originDic = self.setting:getQualityConfig(self:getGlobalQuality())
  else
    self.setting:saveQuality()
  end
end

function QualityManager:__vivoSpecialSaveAll()
  local bChanged = false
  for k, v in pairs(self.cacheDic) do
    if v ~= self.originDic[k] and k ~= QualityType.FpsQuality then
      bChanged = true
      break
    end
  end
  if bChanged then
    self.setting:setCurrentLv(GlobalQuality.Custom)
    self.setting:saveCustomQualityConfig(self.cacheDic)
    self.originDic = self.setting:getQualityConfig(self:getGlobalQuality())
  else
    self.setting:saveQuality()
  end
  if DeviceAdapter.isVivoNew() then
    self.originDic[QualityType.FpsQuality] = self.cacheDic[QualityType.FpsQuality]
    self.setting:saveSpecialFPS(self.cacheDic[QualityType.FpsQuality])
  end
end

function QualityManager:getShaderLod()
  local handler = self.handlerDic[QualityType.ShaderQuality]
  return handler:getShaderLod(self.originDic[QualityType.ShaderQuality])
end

function QualityManager:__highFpsCheck()
  local highFps = DeviceAdapter.getHighFps()
  if 0 < highFps then
    local handler = self.handlerDic[QualityType.FpsQuality]
    return handler:setHighFps(true)
  end
end

function QualityManager:getHighFps()
  return DeviceAdapter.getHighFps()
end

return QualityManager
