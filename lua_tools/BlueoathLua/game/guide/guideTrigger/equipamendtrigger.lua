local EquipAmendTrigger = class("game.guide.guideTrigger.EquipAmendTrigger", GR.requires.GuideTriggerBase)

function EquipAmendTrigger:initialize(nType, pageName)
  self.type = nType
  self.param = pageName
end

function EquipAmendTrigger:tick()
  if UIPageManager:IsExistPage(self.param[1]) or self.UIPageManager:IsExistPage(self.param[2]) then
    local equipData = Data.equipData:GetEquipData()
    for k, equip in pairs(equipData) do
      local equipMaxStar = Logic.equipLogic:GetEquipMaxStar(equip.TemplateId)
      if equipMaxStar ~= equip.Star then
        local renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
        if equip.EnhanceLv >= renovate.need_enhance_level then
          self:sendTrigger()
        end
      end
    end
  end
end

return EquipAmendTrigger
