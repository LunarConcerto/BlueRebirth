local FpsSetting = class("game.Quality.Setting.FpsSetting")

function FpsSetting:initialize()
  self.standardFps = 30
end

function FpsSetting:setQualityLv(lv)
  if lv == 0 then
    Application.targetFrameRate = self.standardFps
    vivoSDKInterface:sendTargetFrameCount(self.standardFps)
  else
    Application.targetFrameRate = self.standardFps * 2
    vivoSDKInterface:sendTargetFrameCount(self.standardFps * 2)
  end
end

function FpsSetting:setHighFps()
  self.standardFps = 60
end

return FpsSetting
