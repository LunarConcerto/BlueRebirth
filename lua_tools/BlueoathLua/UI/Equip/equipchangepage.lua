local EquipChangePage = class("UI.Equip.EquipChangePage", LuaUIPage)

function EquipChangePage:DoInit()
  self.m_tabWidgets = nil
  self.NewEquipId = nil
  self.HeroId = nil
  self.Index = nil
  self.m_equipToBagSign = nil
  self.oldIndex = 0
  self.newIndex = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_fleetType = FleetType.Normal
end

function EquipChangePage:_SetFleetType(fleetType)
  self.m_fleetType = fleetType
end

function EquipChangePage:_GetFleetType()
  return self.m_fleetType
end

function EquipChangePage:DoOnOpen()
  local param = self:GetParam()
  local oldId = param[1]
  self.NewEquipId = param[2]
  self.HeroId = param[3]
  self.Index = param[4]
  self.m_equipToBagSign = param[5]
  self:_SetFleetType(param.FleetType)
  if oldId then
    self.OldEquipId = oldId
    self:_ShowOldEquip()
  end
  self:ShowNewEquip()
  self.m_tabWidgets.obj_EquipInfo:SetActive(oldId ~= nil)
  self.m_tabWidgets.obj_Warning:SetActive(oldId == nil)
  self.m_tabWidgets.txt_oldequiptag.gameObject:SetActive(oldId ~= nil)
end

function EquipChangePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Cancel, self._CloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Change, self._Change, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Close, self._CloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Bg, self._CloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_oldinfo, self._ShowOldEquip, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_newinfo, self.ShowNewEquip, self)
  self:RegisterEvent("changeHeroEquip", self._ChangeHeroEquip, self)
end

function EquipChangePage:_ShowOldEquip()
  local oldEquip = Logic.equipLogic:GetEquipById(self.OldEquipId)
  local equipInfo = configManager.GetDataById("config_equip", oldEquip.TemplateId)
  local isHave = Logic.equipLogic:EquipIsHaveEffect(oldEquip.TemplateId)
  self.m_tabWidgets.txt_OldName.text = equipInfo.name
  self.m_tabWidgets.txt_OldIntensifyLevel.gameObject:SetActive(oldEquip.EnhanceLv ~= 0)
  self.m_tabWidgets.txt_OldIntensifyLevel.text = "+" .. math.tointeger(oldEquip.EnhanceLv)
  UIHelper.SetStar(self.m_tabWidgets.obj_oldStar, self.m_tabWidgets.trans_oldStar, oldEquip.Star)
  self.m_tabWidgets.obj_oldSkin:SetActive(isHave)
  self.m_tabWidgets.txt_oldequiptag.text = Logic.equipLogic:GetEquipTag(equipInfo.ewt_id)
  UIHelper.SetImage(self.m_tabWidgets.img_OldIcon, tostring(equipInfo.icon))
  UIHelper.SetImage(self.m_tabWidgets.img_OldQuality, QualityIcon[equipInfo.quality])
  self.tabOldAttr = Logic.equipLogic:GetCurEquipFinaAttr(oldEquip.EquipId)
  self.oldCount = #self.tabOldAttr / 6
  if #self.tabOldAttr > 6 then
    self.m_tabWidgets.btn_oldinfo.gameObject:SetActive(true)
    self.m_tabWidgets.txt_moreold.text = UIHelper.GetString(170007)
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_OldProperty, self.m_tabWidgets.trans_OldProperty, 6, function(nIndex, tabPart)
    local equipInfo = self.tabOldAttr[nIndex + 6 * self.oldIndex]
    if equipInfo then
      tabPart.txt_Name.text = equipInfo.name
      local attrValueShow = Logic.attrLogic:GetAttrShow(equipInfo.id, equipInfo.value)
      tabPart.txt_Value.text = attrValueShow
      UIHelper.SetImage(tabPart.img_Tag, equipInfo.icon)
      tabPart.img_Tag.gameObject:SetActive(true)
      tabPart.txt_Name.gameObject:SetActive(true)
      tabPart.txt_Value.gameObject:SetActive(true)
    else
      tabPart.txt_Name.gameObject:SetActive(false)
      tabPart.txt_Value.gameObject:SetActive(false)
      tabPart.img_Tag.gameObject:SetActive(false)
    end
    tabPart.obj_prop:SetActive(equipInfo)
  end)
  self.oldIndex = self.oldIndex + 1
  if self.oldIndex > self.oldCount then
    self.oldIndex = 0
  end
  self:_ShowOldEquipTipRoot(oldEquip.TemplateId)
  self:_ShowOldEquipPSkill(self.OldEquipId, oldEquip.TemplateId)
  self:_ShowOldEquipActivity(self.OldEquipId)
  self:_ShowOldEquipLimit(oldEquip.TemplateId)
  self:_ShowNumTip(oldEquip.TemplateId, self.m_tabWidgets.tx_oonly)
end

function EquipChangePage:ShowNewEquip()
  local equip = Logic.equipLogic:GetEquipById(self.NewEquipId)
  local equipInfo = configManager.GetDataById("config_equip", equip.TemplateId)
  local isAlreadyEquipt = false
  local isHave = Logic.equipLogic:EquipIsHaveEffect(equip.TemplateId)
  self.m_tabWidgets.txt_NewName.text = equipInfo.name
  self.m_tabWidgets.txt_NewIntensifyLevel.gameObject:SetActive(equip.EnhanceLv ~= 0)
  self.m_tabWidgets.txt_NewIntensifyLevel.text = "+" .. math.tointeger(equip.EnhanceLv)
  self.m_tabWidgets.obj_NewTag:SetActive(isAlreadyEquipt)
  self.m_tabWidgets.obj_newSkin:SetActive(isHave)
  UIHelper.SetStar(self.m_tabWidgets.obj_newStar, self.m_tabWidgets.trans_newStar, equip.Star)
  UIHelper.SetImage(self.m_tabWidgets.img_NewIcon, tostring(equipInfo.icon))
  UIHelper.SetImage(self.m_tabWidgets.img_NewQuality, QualityIcon[equipInfo.quality])
  self.m_tabWidgets.txt_newequiptag.text = Logic.equipLogic:GetEquipTag(equipInfo.ewt_id)
  self.tabNewAttr = Logic.equipLogic:GetCurEquipFinaAttr(self.NewEquipId)
  self.newCount = #self.tabNewAttr / 6
  if #self.tabNewAttr > 6 then
    self.m_tabWidgets.btn_newinfo.gameObject:SetActive(true)
    self.m_tabWidgets.txt_morenew.text = UIHelper.GetString(170007)
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_NewProperty, self.m_tabWidgets.trans_NewProperty, 6, function(nIndex, tabPart)
    local equipInfo = self.tabNewAttr[nIndex + 6 * self.newIndex]
    if equipInfo then
      tabPart.txt_Name.text = equipInfo.name
      local attrValueShow = Logic.attrLogic:GetAttrShow(equipInfo.id, equipInfo.value)
      tabPart.txt_Value.text = attrValueShow
      UIHelper.SetImage(tabPart.img_Tag, equipInfo.icon)
      tabPart.img_Tag.gameObject:SetActive(true)
      tabPart.txt_Name.gameObject:SetActive(true)
      tabPart.txt_Value.gameObject:SetActive(true)
    else
      tabPart.txt_Name.gameObject:SetActive(false)
      tabPart.txt_Value.gameObject:SetActive(false)
      tabPart.img_Tag.gameObject:SetActive(false)
    end
    tabPart.obj_prop:SetActive(equipInfo)
  end)
  self.newIndex = self.newIndex + 1
  if self.newIndex > self.newCount then
    self.newIndex = 0
  end
  self:_ShowNewEquipTipRoot(equip.TemplateId)
  self:_ShowNewEquipPSkill(self.NewEquipId, equip.TemplateId)
  self:_ShowNewEquipActivity(self.NewEquipId)
  self:_ShowNewEquipLimit(equip.TemplateId)
  self:_ShowNumTip(equip.TemplateId, self.m_tabWidgets.tx_nonly)
end

function EquipChangePage:_ChangeHeroEquip()
  noticeManager:ShowTip(self._changeTips)
  self:_CloseClick()
end

function EquipChangePage:_Change()
  local equip = Logic.equipLogic:GetEquipById(self.NewEquipId)
  local equipInfo = configManager.GetDataById("config_equip", equip.TemplateId)
  if self.OldEquipId then
    local oldTid = Logic.equipLogic:GetEquipById(self.OldEquipId).TemplateId
    if oldTid ~= equip.TemplateId then
      local ok, msg = Logic.equipLogic:CheckHeroMaxWearNum(self.HeroId, equip.TemplateId, self:_GetFleetType())
      if not ok then
        noticeManager:ShowTip(msg)
        return
      end
    end
    local lock = Logic.equipLogic:IsBindLock(self.OldEquipId, self:_GetFleetType())
    if lock then
      noticeManager:ShowTipById(6100010)
      return
    end
  else
    local ok, msg = Logic.equipLogic:CheckHeroMaxWearNum(self.HeroId, equip.TemplateId, self:_GetFleetType())
    if not ok then
      noticeManager:ShowTip(msg)
      return
    end
  end
  local lock = Logic.equipLogic:IsBindLock(self.NewEquipId, self:_GetFleetType())
  if lock then
    noticeManager:ShowTipById(6100010)
    return
  end
  self._changeTips = string.format(UIHelper.GetString(170002), equipInfo.name)
  local oldHero = Data.equipData:GetEquipHero(self.NewEquipId, self:_GetFleetType())
  if oldHero ~= 0 and oldHero ~= self.HeroId then
    local oldShip = Logic.shipLogic:GetShipInfoByHeroId(oldHero)
    local newShip = Logic.shipLogic:GetShipInfoByHeroId(self.HeroId)
    local content = string.format(UIHelper.GetString(170008), oldShip.ship_name, equipInfo.name, newShip.ship_name)
    local param = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ConfirmChange()
        end
      end
    }
    noticeManager:ShowMsgBox(content, param)
    return
  end
  self:_ConfirmChange()
end

function EquipChangePage:_ConfirmChange()
  if self.m_equipToBagSign == EquipToBagSign.CHANGE_EQUIP then
    UIHelper.Back()
  end
  Service.heroService:SendChangeEquip(self.HeroId, self.Index, self.NewEquipId, self:_GetFleetType())
end

function EquipChangePage:_ShowOldEquipTipRoot(tid)
  local widgets = self:GetWidgets()
  self:_ShowTipRoot(tid, widgets.obj_otiproot)
end

function EquipChangePage:_ShowNewEquipTipRoot(tid)
  local widgets = self:GetWidgets()
  self:_ShowTipRoot(tid, widgets.obj_ntiproot)
end

function EquipChangePage:_ShowOldEquipPSkill(equipId, templateId)
  local widgets = self:GetWidgets()
  self:_ShowEquipPSkill(equipId, templateId, widgets.obj_opskilllist, widgets.obj_opskill, widgets.trans_opskill)
end

function EquipChangePage:_ShowNewEquipPSkill(equipId, templateId)
  local widgets = self:GetWidgets()
  self:_ShowEquipPSkill(equipId, templateId, widgets.obj_npskilllist, widgets.obj_npskill, widgets.trans_npskill)
end

function EquipChangePage:_ShowOldEquipActivity(equipId)
  local widgets = self:GetWidgets()
  self:_ShowActivityInfo(equipId, widgets.obj_oactivity)
end

function EquipChangePage:_ShowNewEquipActivity(equipId)
  local widgets = self:GetWidgets()
  self:_ShowActivityInfo(equipId, widgets.obj_nactivity)
end

function EquipChangePage:_ShowOldEquipLimit(templateId)
  local widgets = self:GetWidgets()
  self:_ShowLevelLimitInfo(templateId, widgets.obj_olimit, widgets.obj_olimitroot, widgets.obj_olimititem, widgets.trans_olimititem)
end

function EquipChangePage:_ShowNewEquipLimit(templateId)
  local widgets = self:GetWidgets()
  self:_ShowLevelLimitInfo(templateId, widgets.obj_nlimit, widgets.obj_nlimitroot, widgets.obj_nlimititem, widgets.trans_nlimititem)
end

function EquipChangePage:_ShowNumTip(tid, wtext)
  local show, str = Logic.equipLogic:GetHeroMaxWearStr(tid)
  wtext.gameObject:SetActive(show)
  UIHelper.SetText(wtext, str)
end

function EquipChangePage:_ShowEquipPSkill(equipId, templateId, wlist, wobj, wtrans)
  local equipData
  if equipId ~= nil then
    equipData = Data.equipData:GetEquipDataById(equipId)
    templateId = equipData.TemplateId
  end
  local common = Logic.equipLogic:IsCommonRiseEquip(templateId)
  local equipPskills = Logic.equipLogic:GetEquipRisePSkillById(templateId)
  wlist:SetActive(0 < #equipPskills)
  if 0 < #equipPskills then
    UIHelper.CreateSubPart(wobj, wtrans, #equipPskills, function(index, tabParts)
      local pskillId = equipPskills[index]
      local name = Logic.shipLogic:GetPSkillName(pskillId)
      local ok, info = Logic.equipLogic:CheckPSkillOpen(equipId, pskillId)
      local lvdes = ok and "Level: " .. info.PSkillLv or "(\230\148\185\228\191\174\229\144\142\232\167\163\233\148\129)"
      local lv = ok and info.PSkillLv or 1
      if common then
        ok = true
        lv = 1
        lvdes = "Level: 1"
      end
      local des = Logic.shipLogic:GetPSkillDesc(pskillId, lv)
      UIHelper.SetText(tabParts.tx_name, name)
      UIHelper.SetText(tabParts.tx_des, des)
      if ok then
        UIHelper.SetTextColor(tabParts.tx_lv, lvdes, "5e718a")
        UIHelper.SetTextColor(tabParts.tx_des, des, "5e718a")
      else
        UIHelper.SetText(tabParts.tx_lv, lvdes)
      end
    end)
  end
end

function EquipChangePage:_ShowActivityInfo(equipId, uobj)
  if equipId and 0 < equipId then
    local data = Data.equipData:GetEquipDataById(equipId)
    if data == nil then
      return
    end
    local tid = data.TemplateId
    local isAEquip = Logic.equipLogic:IsAEquip(tid)
    uobj:SetActive(isAEquip)
  end
end

function EquipChangePage:_ShowLevelLimitInfo(templateId, uobj, o_root, o_item, t_item)
  local isLLEquip, copyIds = Logic.equipLogic:IsLLEquip(templateId)
  o_root:SetActive(isLLEquip)
  uobj:SetActive(isLLEquip)
  UIHelper.CreateSubPart(o_item, t_item, #copyIds, function(index, tabPart)
    local str = Logic.copyLogic:GetShortTitle(copyIds[index])
    UIHelper.SetText(tabPart.tx_limit, str)
  end)
end

function EquipChangePage:_ShowTipRoot(templateId, uobj)
  local isLLEquip = Logic.equipLogic:IsLLEquip(templateId)
  local pskills = Logic.equipLogic:GetEquipRisePSkillById(templateId)
  uobj:SetActive(isLLEquip or 0 < #pskills)
end

function EquipChangePage:_CloseClick()
  UIHelper.ClosePage("EquipChangePage")
end

function EquipChangePage:DoOnHide()
end

function EquipChangePage:DoOnClose()
end

return EquipChangePage
