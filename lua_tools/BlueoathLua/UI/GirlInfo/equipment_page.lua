local Equipment_Page = class("UI.GirlInfo.Equipment_Page", LuaUIPage)

function Equipment_Page:DoInit()
  self.m_tabWidgets = nil
  self.m_fleetType = FleetType.Normal
  self.m_heroId = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function Equipment_Page:_SetFleetType(fleetType)
  self.m_fleetType = fleetType
end

function Equipment_Page:_GetFleetType()
  return self.m_fleetType
end

function Equipment_Page:DoOnOpen()
  local params = self:GetParam()
  self:_SetFleetType(params.FleetType)
  self:_UpdateHero(params.heroId)
  self.m_heroId = params.heroId
end

function Equipment_Page:UpdateGirlTog(heroId)
  self.m_tabWidgets.tween_dongHua:ResetToBeginning()
  self.m_tabWidgets.tween_dongHua:Play(true)
  noticeManager:CloseTip()
  if self.m_heroId ~= heroId then
    self:_UpdateHero(heroId)
    self.m_heroId = heroId
  end
end

function Equipment_Page:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._UpdateHero, self)
  self:RegisterEvent(LuaEvent.UpdateEquipMsg, self._UpdateHero, self)
  self:RegisterEvent(LuaEvent.UpdateGirlTog, self.UpdateGirlTog)
  self:RegisterEvent(LuaEvent.GirlInfoTween, self._GirlInfoTween)
  self:RegisterEvent(LuaEvent.GirlInfoUIReset, self._ResetUI)
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_add, self._AutoSetEquip, self, true)
  UGUIEventListener.AddButtonOnClick(widgets.btn_remove, self._AutoSetEquip, self, false)
  UGUIEventListener.AddButtonOnClick(widgets.btn_fashion, self._ClickEquipEffect, self)
end

function Equipment_Page:_AutoSetEquip(go, isAdd)
  local heroId = self.m_heroId
  local ok, msg = Logic.equipLogic:AutoSetEquips(heroId, isAdd, self:_GetFleetType())
  if not ok then
    noticeManager:ShowTip(msg)
  end
end

function Equipment_Page:_ResetUI()
  local widgets = self:GetWidgets()
  widgets.tween_dongHua:ResetToEnd()
end

function Equipment_Page:_GirlInfoTween(delta)
  local position = configManager.GetDataById("config_parameter", 95).arrValue
  if delta then
    self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D = Vector2.New(delta, position[3])
  else
    self.m_tabWidgets.tween_dongHua.from = self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D
    self.m_tabWidgets.tween_dongHua:ResetToBeginning()
    self.m_tabWidgets.tween_dongHua:Play(true)
  end
end

function Equipment_Page:_UpdateHero(heroId)
  heroId = heroId or self.m_heroId
  local isPlane = false
  local shipInfo = Data.heroData:GetHeroById(heroId)
  local equipTrench = Logic.shipLogic:GetShipEquipInfo(shipInfo.TemplateId, shipInfo)
  local fleetType, towerLock, isActivity, isLLEquip
  fleetType = self:_GetFleetType()
  local equips = Data.heroData:GetEquipsByType(heroId, fleetType)
  if equips == nil then
    logError("can not find equip data heroId:" .. heroId .. " fleetType:" .. fleetType)
    return
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_Trench, self.m_tabWidgets.trans_Trench, #equipTrench, function(nIndex, tabPart)
    local equipId = equips[nIndex].EquipsId
    tabPart.obj_Add:SetActive(equipId == 0)
    tabPart.img_Icon.gameObject:SetActive(equipId ~= 0)
    tabPart.trans_Star.gameObject:SetActive(equipId ~= 0)
    tabPart.obj_towerlock:SetActive(false)
    tabPart.obj_binding:SetActive(false)
    local tabTrenchId = equipTrench[nIndex].equipAttr
    local equipWearType = Logic.equipLogic:GetTrenchEquipType(tabTrenchId)
    tabPart.txt_Tag.text = equipWearType
    if heroId ~= self.m_heroId then
      self:RegisterRedDot(tabPart.redDot, heroId, nIndex, self:_GetFleetType())
    end
    UGUIEventListener.AddButtonOnClick(tabPart.img_Help, function()
      local equipType = ""
      for i = 1, #tabTrenchId do
        local wearType = configManager.GetDataById("config_equip_wear_type", tabTrenchId[i])
        local symbol = "\227\128\129"
        if i == #tabTrenchId then
          symbol = "\227\128\130"
        end
        equipType = equipType .. wearType.ewt_desc .. symbol
      end
      noticeManager:ShowMsgBox("\232\175\165\228\189\141\231\189\174\229\143\175\232\163\133\229\164\135\239\188\154" .. equipType)
    end)
    UGUIEventListener.ClearButtonEventListener(tabPart.btn_bg.gameObject)
    if not equipTrench[nIndex].open then
      tabPart.txt_IntensifyLevel.text = ""
      tabPart.txt_Name.text = ""
      tabPart.txt_Add.text = ""
      UIHelper.SetImage(tabPart.img_IconBg, "uipic_ui_attribute_bg_renwudikuang")
      tabPart.trans_Property.gameObject:SetActive(false)
      tabPart.txt_Limit.text = equipTrench[nIndex].advanceDesc
      tabPart.obj_Lock:SetActive(true)
      tabPart.obj_Add:SetActive(false)
      UIHelper.SetImage(tabPart.img_bg, "uipic_ui_common_bg_diban")
      UIHelper.SetImage(tabPart.img_Tag, "uipic_ui_common_bg_kongtubiaokuang")
      UIHelper.SetImage(tabPart.img_Help, "uipic_ui_store_bu_tishi-31")
      UIHelper.SetImage(tabPart.img_IconBg, "uipic_ui_common_bg_kongtubiaokuang")
      tabPart.btn_bg.interactable = false
      return
    end
    tabPart.txt_Limit.text = ""
    tabPart.obj_Lock:SetActive(false)
    if equipId == 0 then
      tabPart.txt_IntensifyLevel.text = ""
      tabPart.txt_Name.text = ""
      tabPart.txt_Add.text = "\231\130\185\229\135\187\230\183\187\229\138\160\232\163\133\229\164\135"
      UIHelper.SetImage(tabPart.img_IconBg, "uipic_ui_attribute_bg_renwudikuang")
      UGUIEventListener.AddButtonOnClick(tabPart.btn_bg, function()
        local canChangeEquip = Logic.equipLogic:CheckChangeEquip(heroId, tabTrenchId)
        if canChangeEquip then
          UIHelper.OpenPage("BagPage", {
            BagType.EQUIP_BAG,
            EquipToBagSign.CHANGE_EQUIP,
            nil,
            heroId,
            nIndex,
            tabTrenchId,
            FleetType = self:_GetFleetType()
          })
        else
          local equipType = tabTrenchId[1]
          local equipTypeConfig = configManager.GetDataById("config_equip_type", equipType)
          local equipTemplateId = equipTypeConfig.default_equip_id
          globalNoitceManager:ShowItemInfoPage(GoodsType.EQUIP, equipTemplateId)
        end
      end)
      tabPart.trans_Property.gameObject:SetActive(false)
      tabPart.obj_activity:SetActive(false)
      tabPart.obj_limit:SetActive(false)
    else
      towerLock = Logic.equipLogic:IsTowerLock(equipId, fleetType)
      tabPart.obj_towerlock:SetActive(towerLock)
      local ifShowLockEffect = Logic.equipLogic:IsBindLock(equipId, fleetType)
      tabPart.obj_binding:SetActive(ifShowLockEffect)
      local equipInfo = Logic.equipLogic:GetEquipById(equipId)
      local planeNume = Logic.equipLogic:_getPlaneNum(heroId, equipId, self:_GetFleetType())
      if equipInfo == nil then
        noticeManager:ShowMsgBox("\232\163\133\229\164\135\228\191\161\230\129\175\232\142\183\229\143\150\229\164\177\232\180\165")
        return
      end
      isActivity = Logic.equipLogic:IsAEquip(equipInfo.TemplateId)
      tabPart.obj_activity:SetActive(isActivity)
      isLLEquip = Logic.equipLogic:IsLLEquip(equipInfo.TemplateId)
      tabPart.obj_limit:SetActive(isLLEquip)
      local shipEquipInfo = configManager.GetDataById("config_equip", equipInfo.TemplateId)
      if shipEquipInfo.ewt_id[1] == 18 or shipEquipInfo.ewt_id[1] == 19 or shipEquipInfo.ewt_id[1] == 20 then
        isPlane = true
      else
        isPlane = false
      end
      local txt_IntensifyLevel = "+" .. Mathf.ToInt(equipInfo.EnhanceLv)
      if 0 >= equipInfo.EnhanceLv then
        txt_IntensifyLevel = " "
      end
      tabPart.txt_IntensifyLevel.text = txt_IntensifyLevel
      tabPart.txt_Name.text = shipEquipInfo.name
      tabPart.txt_Add.text = ""
      UIHelper.SetStar(tabPart.obj_imstar, tabPart.trans_Star, equipInfo.Star)
      tabPart.trans_Property.gameObject:SetActive(true)
      UIHelper.SetImage(tabPart.img_Icon, tostring(shipEquipInfo.icon))
      UIHelper.SetImage(tabPart.img_IconBg, QualityIcon[shipEquipInfo.quality])
      UGUIEventListener.AddButtonOnClick(tabPart.btn_bg, function()
        UIHelper.OpenPage("ShowEquipPage", {
          equipId = equipId,
          showEquipType = ShowEquipType.Info,
          FleetType = self:_GetFleetType()
        })
      end)
      local attr = Logic.equipLogic:GetCurEquipFinaAttr(equipInfo.EquipId)
      UIHelper.CreateSubPart(tabPart.obj_Property, tabPart.trans_Property, 4, function(mIndex, luaPart)
        local equipInfo = attr[mIndex]
        if equipInfo then
          luaPart.txt_Name.text = equipInfo.name
          if type(equipInfo.value) == "number" then
            luaPart.txt_Value.text = Mathf.ToInt(equipInfo.value)
          else
            luaPart.txt_Value.text = equipInfo.value
          end
          UIHelper.SetImage(luaPart.img_Tag, equipInfo.icon)
          luaPart.img_Tag.gameObject:SetActive(true)
          luaPart.txt_Value.gameObject:SetActive(true)
          luaPart.txt_Name.gameObject:SetActive(true)
        elseif isPlane then
          isPlane = false
          local planeInfo = configManager.GetDataById("config_attribute", 3102)
          luaPart.txt_Name.text = planeInfo.attr_name
          luaPart.txt_Value.text = Mathf.ToInt(planeNume)
          UIHelper.SetImage(luaPart.img_Tag, planeInfo.attr_icon)
          luaPart.img_Tag.gameObject:SetActive(true)
          luaPart.txt_Value.gameObject:SetActive(true)
          luaPart.txt_Name.gameObject:SetActive(true)
        else
          luaPart.txt_Name.gameObject:SetActive(false)
          luaPart.txt_Value.gameObject:SetActive(false)
          luaPart.img_Tag.gameObject:SetActive(false)
        end
      end)
      local isHave = Logic.equipLogic:EquipIsHaveEffect(equipInfo.TemplateId)
      tabPart.obj_effect:SetActive(isHave)
    end
  end)
end

function Equipment_Page:_ClickEquipEffect()
  local funcOpen = moduleManager:CheckFunc(FunctionID.EquipEffect, true)
  if not funcOpen then
    return
  end
  local shipInfo = Data.heroData:GetHeroById(self.m_heroId)
  if shipInfo == nil then
    logError("FATAL ERROR:can not find hero info about:" .. heroId)
    return
  end
  local fashionId = Logic.shipLogic:GetShipFashioning(self.m_heroId)
  local param = {
    heroId = self.m_heroId,
    fashionId = fashionId
  }
  UIHelper.OpenPage("EquipFashionPage", param)
end

function Equipment_Page:DoOnHide()
end

function Equipment_Page:DoOnClose()
end

return Equipment_Page
