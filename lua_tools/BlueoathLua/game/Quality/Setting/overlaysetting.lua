local OverlaySetting = class("game.Quality.Setting.OverlaySetting")

function OverlaySetting:setQualityLv(lv)
  QualityHelper.SetOverlayQualityLv(lv)
end

return OverlaySetting
