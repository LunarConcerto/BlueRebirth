local ActionSetting = class("game.Quality.Setting.ActionSetting")

function ActionSetting:setQualityLv(lv)
  QualityHelper.SetDynamicBoneQualityLv(lv)
end

return ActionSetting
