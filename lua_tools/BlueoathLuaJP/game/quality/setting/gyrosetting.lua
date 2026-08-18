local GyroSetting = class("game.Quality.Setting.GyroSetting")
local Input = CS.UnityEngine.Input

function GyroSetting:initialize()
end

function GyroSetting:setQualityLv(lv)
  if lv == 0 then
    Input.gyro.enabled = false
  else
    Input.gyro.enabled = true
  end
end

return GyroSetting
