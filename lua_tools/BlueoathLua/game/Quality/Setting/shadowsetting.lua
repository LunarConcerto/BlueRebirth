local ShadowSetting = class("game.Quality.Setting.ShadowSetting")

function ShadowSetting:setQualityLv(lv)
  if DeviceAdapter.isCloseShadow() then
    lv = 0
  end
  sLv = 0
  rLv = 0
  if 0 < lv then
    sLv = 1
  end
  if 1 < lv then
    rLv = 1
  end
  QualitySettings.shadows = sLv
  QualitySettings.shadowResolution = rLv
  QualityHelper.SetShadowStatus(lv)
end

return ShadowSetting
