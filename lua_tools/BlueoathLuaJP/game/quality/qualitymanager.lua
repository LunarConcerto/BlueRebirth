local QualityManager = class("game.Quality.QualityManager")
require("game.Quality.DeviceAdapter")
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
  QualityHelper.SetIsReflectionProbeBug(DeviceAdapter.isReflectionProbeBug())
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
  self.handlerDic[QualityType.GyroQuality] = require("game.Quality.Setting.GyroSetting"):new()
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
    self:setQualityLvByType(v, k)
  end
  self.setting:setCurrentLv(lv)
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
  self.setting:setGyro(self.cacheDic.Gyro)
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
