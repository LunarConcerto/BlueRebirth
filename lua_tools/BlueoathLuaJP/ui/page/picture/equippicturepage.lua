local EquipPicturePage = class("UI.Picture.EquipPicturePage", LuaUIPage)

function EquipPicturePage:DoInit()
  self.equipData = {}
end

function EquipPicturePage:DoOnOpen()
  self.equipData = self:GetParam()
  self:OpenTopPage("EquipPicturePage", 1, UIHelper.GetString(500004), self, true)
  self:DoOnOpenInit()
end

function EquipPicturePage:DoOnOpenInit()
  local widgets = self:GetWidgets()
  local equip = configManager.GetDataById("config_equip", self.equipData.EquipId)
  UIHelper.SetText(widgets.tx_equipName, self.equipData.name)
  UIHelper.SetText(widgets.tx_quality, AllType[self.equipData.quality])
  self:_InitRenovateSkill()
  local ewtId = Logic.equipLogic:GetEquipTag(equip.ewt_id)
  UIHelper.SetText(widgets.tx_equipType, ewtId)
  UIHelper.SetText(widgets.tx_shipType, self.equipData.name)
  local isCanWear = Logic.equipLogic:GetHeroMaxWearNumById(self.equipData.EquipId)
  widgets.obj_zhuangbeitexing:SetActive(isCanWear)
  UIHelper.SetText(widgets.tx_texing, UIHelper.GetString(500003))
  UIHelper.SetImage(widgets.im_bg, GirlEquipQualityBgTexture[self.equipData.quality])
  UIHelper.SetImage(widgets.img_goods, self.equipData.icon)
  UIHelper.SetImage(widgets.img_quality, EquipQualityIcon[self.equipData.quality])
  self:ApplyShipType()
  self:_ShowEquipEffect()
  self:_ShowShuXing()
end

function EquipPicturePage:_InitRenovateSkill()
  local equipPskills = Logic.equipLogic:GetEquipRisePSkillById(self.equipData.EquipId)
  local widgets = self:GetWidgets()
  widgets.obj_pskilllist:SetActive(0 < #equipPskills)
  if 0 < #equipPskills then
    UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_skill, #equipPskills, function(index, tabParts)
      local pskillId = equipPskills[index]
      local name = Logic.shipLogic:GetPSkillName(pskillId)
      local equip = configManager.GetDataById("config_equip", self.equipData.EquipId)
      local des = Logic.shipLogic:GetPSkillDesc(pskillId, equip.star_max)
      UIHelper.SetText(tabParts.tx_name, name)
      UIHelper.SetText(tabParts.tx_des, des)
      UIHelper.SetTextColor(tabParts.tx_des, des, "5e718a")
    end)
  end
end

function EquipPicturePage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_get, self._ShowGetApproach, self)
  self:RegisterEvent(LuaEvent.CloseWebView, self._UnmuteMusic, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
end

function EquipPicturePage:ApplyShipType()
  local widgets = self:GetWidgets()
  local shipType, shipTypeInfo
  local equipData = configManager.GetDataById("config_equip", self.equipData.EquipId)
  if #equipData.equip_ship <= 0 then
    shipTypeInfo = UIHelper.GetString(920000174)
  else
    for v, k in pairs(equipData.equip_ship) do
      shipType = configManager.GetDataById("config_ship_type", k)
      if v ~= #equipData.equip_ship then
        if shipTypeInfo then
          shipTypeInfo = shipTypeInfo .. shipType.name .. "\227\128\129"
        else
          shipTypeInfo = shipType.name .. "\227\128\129"
        end
      elseif shipTypeInfo then
        shipTypeInfo = shipTypeInfo .. shipType.name
      else
        shipTypeInfo = shipType.name
      end
    end
  end
  widgets.tx_shipType.text = shipTypeInfo
end

function EquipPicturePage:_ShowGetApproach()
  UIHelper.OpenPage("ShowEquipPage", {
    templateId = self.equipData.EquipId,
    showEquipType = ShowEquipType.Simple,
    showDrop = true
  })
end

function EquipPicturePage:_ShowEquipEffect()
  local equipFashionId = configManager.GetDataById("config_equip", self.equipData.EquipId).skill_fashion_id
  self.tab_Widgets.obj_effect:SetActive(0 < #equipFashionId)
  self.tab_Widgets.equipfashion:SetActive(0 < #equipFashionId)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_itemEffect, self.tab_Widgets.trans_itemEffect, #equipFashionId, function(index, tabPart)
    local skillFashion = configManager.GetDataById("config_skill_fashion", equipFashionId[index])
    UIHelper.SetText(tabPart.txt_name, skillFashion.skill_fashion_name)
    UIHelper.SetImage(tabPart.im_effect, skillFashion.show_picture)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_play, self._PlayAdvio, self, tonumber(equipFashionId[index]))
  end)
end

function EquipPicturePage:_PlayAdvio(go, effectId)
  local funcOpen = moduleManager:CheckFunc(FunctionID.EquipEffect, true)
  if not funcOpen then
    return
  end
  SoundManager.Instance:PlayMusic("Role_unlock")
  Logic.equipLogic:_PlayAdvio(effectId)
end

function EquipPicturePage:_ShowShuXing()
  local equip = configManager.GetDataById("config_equip", self.equipData.EquipId)
  local tabAttrInfo = Logic.equipLogic:GetCurEquipFinaAttrByLv(self.equipData.EquipId, equip.enhance_level_max)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_shuxing, self.tab_Widgets.trans_liebiao, #tabAttrInfo, function(index, tabPart)
    local attrData = tabAttrInfo[index]
    UIHelper.SetText(tabPart.Tx_prop, attrData.name)
    UIHelper.SetText(tabPart.Tx_num, attrData.value)
    UIHelper.SetImage(tabPart.Im_icon, attrData.icon)
  end)
end

function EquipPicturePage:_UnmuteMusic()
  SoundManager.Instance:PlayMusic("Role_unlock_finish")
end

function EquipPicturePage:_ShareOver()
  self:ShareComponentShow(true)
end

return EquipPicturePage
