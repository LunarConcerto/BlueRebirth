local ShaderSetting = class("game.Quality.Setting.ShaderSetting")
local ShaderLODLow = 900
local ShaderLODMedium = 950
local ShaderLODHigh = 1000

function ShaderSetting:setQualityLv(lv)
  if DeviceAdapter.isForceLow() then
    lv = GlobalQuality.Low
  end
  if lv == GlobalQuality.Low then
    Shader.globalMaximumLOD = ShaderLODLow
    QualitySettings.anisotropicFiltering = AnisotropicFiltering.Disable
    vivoSDKInterface:sendQuality(2)
  elseif lv == GlobalQuality.Medium then
    Shader.globalMaximumLOD = ShaderLODMedium
    QualitySettings.anisotropicFiltering = AnisotropicFiltering.Disable
    vivoSDKInterface:sendQuality(1)
  else
    Shader.globalMaximumLOD = ShaderLODHigh
    QualitySettings.anisotropicFiltering = AnisotropicFiltering.Enable
    vivoSDKInterface:sendQuality(0)
  end
  QualityHelper.isQuarterScreen = isIOS
  QualityHelper.SetSkyOceanQualityLv(lv)
end

function ShaderSetting:getShaderLod(lv)
  if lv == GlobalQuality.Low then
    return ShaderLODLow
  elseif lv == GlobalQuality.Medium then
    return ShaderLODMedium
  else
    return ShaderLODHigh
  end
end

return ShaderSetting
