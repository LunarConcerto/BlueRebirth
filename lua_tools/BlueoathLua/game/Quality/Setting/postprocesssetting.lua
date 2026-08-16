local PostProcessSetting = class("game.Quality.Setting.PostProcessSetting")
local PostProcessQuality = {Close = 0, Open = 1}

function PostProcessSetting:setQualityLv(lv)
  local isOpen = lv == PostProcessQuality.Open and not DeviceAdapter.isForceLow()
  PostProcessHud:SetActivePostProcess(isOpen)
  QualityHelper.SetAllowHDR(isOpen)
end

return PostProcessSetting
