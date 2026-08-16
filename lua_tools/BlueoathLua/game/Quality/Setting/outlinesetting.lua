local OutlineSetting = class("game.Quality.Setting.OutlineSetting")

function OutlineSetting:setQualityLv(lv)
  QualityHelper.isQuarterScreen = isIOS
  QualityHelper.SetOutlineQualityLv(lv)
end

return OutlineSetting
