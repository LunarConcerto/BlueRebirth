local ResolutionSetting = class("game.Quality.Setting.ResolutionSetting")
local HIGH_HEIGHT = 1080
local LOW_HEIGHT = 576
local LOW_SCALE = 1.875
ResolutionSetting.width = nil
ResolutionSetting.height = nil

function ResolutionSetting:initialize()
  self.deviceWidth = Screen.width
  self.deviceHeight = Screen.height
  ResolutionSetting.width = self.deviceWidth
  ResolutionSetting.height = self.deviceHeight
  self.realRadio = self.deviceWidth / self.deviceHeight
end

function ResolutionSetting:setQualityLv(lv)
  QualityHelper.resolutionQualityLv = lv
  self:__vivosend(lv)
  if isWindows then
    return
  end
  local width, height
  if lv == ResolutionQuality.High or lv == ResolutionQuality.Middle then
    width, height = self:getHighRes()
  elseif lv == ResolutionQuality.Low then
    width, height = self:getLowRes()
  end
  width = math.floor(width + 0.5)
  height = math.floor(height + 0.5)
  Screen.SetResolution(width, height, Screen.fullScreen)
end

function ResolutionSetting:__vivosend(lv)
  if lv == ResolutionQuality.High then
    vivoSDKInterface:sendTargetDisplay(0)
  elseif lv == ResolutionQuality.Middle then
    vivoSDKInterface:sendTargetDisplay(1)
  elseif lv == ResolutionQuality.Low then
    vivoSDKInterface:sendTargetDisplay(2)
  end
end

function ResolutionSetting:checkOSVertion()
  if isAndroid then
    local large, middle, patch = string.match(UnityEngine.SystemInfo.operatingSystem, "(%d+).(%d+)")
    local ver = math.tointeger(large)
    return ver < 8
  end
  return true
end

function ResolutionSetting:getHighRes()
  return self.deviceWidth, self.deviceHeight
end

function ResolutionSetting:getLowRes()
  local height = self.deviceHeight / LOW_SCALE
  if height < LOW_HEIGHT then
    height = LOW_HEIGHT
  end
  return height * self.realRadio, height
end

function ResolutionSetting.IsLowResolution()
  return ResolutionSetting.height and ResolutionSetting.height < 1080 or false
end

return ResolutionSetting
