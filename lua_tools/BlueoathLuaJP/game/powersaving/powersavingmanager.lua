local PowerSavingManager = class("game.PowerSaving.PowerSavingManager")
local nSleepTime = 60

function PowerSavingManager:initialize()
  nSleepTime = configManager.GetDataById("config_parameter", 337).value
  self.tickTimer = FrameTimer.New(function()
    self:__tick()
  end, 1, -1)
  self.tickTimer:Start()
  self.nRecordTime = 0
  self.bIsSleep = false
  self.bPause = false
  self.strRecordBrightness = nil
  self.bIsOn = true
  self.nLightnessLevel = 1
end

function PowerSavingManager:onLoginEnter()
  self:setIsOn(true)
  self:setLightness(1)
end

function PowerSavingManager:onLogin()
  self:setIsOn(SettingHelper.GetPowerSavingOn())
  self:setLightness(SettingHelper.GetPowerSavingLightness())
end

function PowerSavingManager:setIsOn(bIsOn)
  self.bIsOn = bIsOn
end

function PowerSavingManager:setLightness(nLightness)
  self.nLightnessLevel = nLightness
end

function PowerSavingManager:__getLightnessByLevel(nLevel)
  if nLevel == 1 then
    return 0
  elseif nLevel == 2 then
    return 0.1
  elseif nLevel == 3 then
    return 0.2
  elseif nLevel == 4 then
    return 0.3
  elseif nLevel == 5 then
    return 0.5
  end
end

function PowerSavingManager:getIsPause()
  return self.bPause
end

function PowerSavingManager:setIsPause(bPause)
  self.bPause = bPause
end

function PowerSavingManager:__tick()
  if not self.bIsOn then
    return
  end
  if self.bPause then
    return
  end
  if CS.UnityEngine.Input.touchCount ~= 0 or CS.UnityEngine.Input.anyKey then
    self.nRecordTime = 0
    if self.bIsSleep then
      self:Resume()
    end
    return
  end
  if not self.bIsSleep then
    self.nRecordTime = self.nRecordTime + Time.deltaTime
    if self.nRecordTime >= nSleepTime then
      self:PowerDown()
      self.nRecordTime = 0
    end
  end
end

function PowerSavingManager:PowerDown()
  if self.bIsSleep then
    return
  end
  self.bIsSleep = true
  if isEditor then
    return
  end
  if not useSDK then
    return
  end
  if isIOS or isAndroid then
    self.strRecordBrightness = CS.Platform.getMainScreenBrightness()
    local nCurBrightness = tonumber(self.strRecordBrightness)
    local nLightnessFactor = self:__getLightnessByLevel(self.nLightnessLevel)
    local nTargetBrightness = nCurBrightness * nLightnessFactor
    CS.Platform.setMainScreenBrightness(tostring(nTargetBrightness))
  end
end

function PowerSavingManager:Resume()
  if not self.bIsSleep then
    return
  end
  if not useSDK then
    return
  end
  if isEditor then
    return
  end
  self.bIsSleep = false
  if isAndroid then
    CS.Platform.setMainScreenBrightness("-1")
  elseif isIOS and self.strRecordBrightness ~= nil then
    CS.Platform.setMainScreenBrightness(self.strRecordBrightness)
  end
end

return PowerSavingManager
