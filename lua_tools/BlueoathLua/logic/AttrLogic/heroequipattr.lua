local HeroEquipAttr = class("logic.AttrLogic.HeroEquipAttr", require("logic.AttrLogic.Attr"))

function HeroEquipAttr:initialize(equipArr, isNpc, copyId)
  self.equipArr = equipArr
  self.attrDic = {}
  self:_GetHeroEquipAttr(isNpc, copyId)
end

function HeroEquipAttr:_GetHeroEquipAttr(isNpc, copyId)
  for _, equipId in pairs(self.equipArr) do
    if equipId ~= 0 then
      local equip = Logic.equipLogic:GetEquipById(equipId)
      if equip then
        local property = Logic.equipLogic:GetCurEquipProperty(equipId, copyId)
        for key, value in pairs(property) do
          self:AddAttr(self.attrDic, value.attr, value.value)
        end
      elseif isNpc then
        local equipRec = configManager.GetDataById("config_equip", equipId, true)
        if equipRec then
          local property = Logic.equipLogic:GetCurEquipPropertyByTid(equipId, copyId)
          for key, value in pairs(property) do
            self:AddAttr(self.attrDic, value.attr, value.value)
          end
        end
      end
    end
  end
end

return HeroEquipAttr
