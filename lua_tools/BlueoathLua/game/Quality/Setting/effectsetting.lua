local EffectSetting = class("game.Quality.Setting.EffectSetting")

function EffectSetting:setQualityLv(lv)
  QualityHelper.effectQualityLv = lv
end

return EffectSetting
