local AntiAliasingSetting = class("game.Quality.Setting.AntiAliasingSetting")
local ResolutionSetting = require("game.Quality.Setting.ResolutionSetting")

function AntiAliasingSetting:setQualityLv(lv)
  if self:needMSAA() then
    self:setPostAA(0)
    self:setMSAA(lv)
  else
    self:setPostAA(lv)
    self:setMSAA(0)
  end
  self.AALevel = lv
end

function AntiAliasingSetting:setBattleMSAA()
  if self:needMSAA() then
    self:setPostAA(0)
    self:setMSAA(self.AALevel)
  else
    self:setPostAA(self.AALevel)
    self:setMSAA(0)
  end
end

function AntiAliasingSetting:setNonBattleMSAA()
  if self:needMSAA() then
    self:setPostAA(0)
    self:setMSAA(self.AALevel)
  else
    self:setPostAA(self.AALevel)
    self:setMSAA(0)
  end
end

function AntiAliasingSetting:needMSAA()
  return not isEditor and not isWindows and isIOS and ResolutionSetting.IsLowResolution()
end

function AntiAliasingSetting:setMSAA(lv)
  if lv == 0 then
    QualitySettings.antiAliasing = 0
  end
  if lv == 1 then
    QualitySettings.antiAliasing = 2
  end
  if lv == 2 then
    QualitySettings.antiAliasing = 4
  end
end

function AntiAliasingSetting:setPostAA(lv)
  if lv == 0 then
    PostProcessHud:SetAntiAliasingActive(0)
  end
  if lv == 1 then
    PostProcessHud:SetAntiAliasingActive(1)
  end
  if lv == 2 then
    PostProcessHud:SetAntiAliasingActive(2)
  end
end

return AntiAliasingSetting
