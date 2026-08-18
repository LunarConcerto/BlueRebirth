local SkyOceanSetting = class("game.Quality.Setting.SkyOceanSetting")

function SkyOceanSetting:setQualityLv(lv)
  QualityHelper.SetSkyOceanQualityLv(lv)
end

return SkyOceanSetting
