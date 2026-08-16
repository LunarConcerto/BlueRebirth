local EquipRiseStarPage = class("UI.Equip.EquipRiseStarPage", LuaUIPage)

function EquipRiseStarPage:DoInit()
  self.m_equipId = 0
  self.m_tabSelectId = {}
  self.m_isEnough = true
  self:_CollectEffectObj()
  self.m_fleetType = FleetType.Normal
end

function EquipRiseStarPage:_CollectEffectObj()
  local widgets = self:GetWidgets()
  self.m_effObjs = {}
  for i = 2, 3 do
    table.insert(self.m_effObjs, widgets["eff_rise" .. i])
  end
end

function EquipRiseStarPage:_SetFleetType(fleetType)
  self.m_fleetType = fleetType
end

function EquipRiseStarPage:_GetFleetType()
  return self.m_fleetType
end

function EquipRiseStarPage:DoOnOpen()
  self.m_equipId = self:GetParam().EquipId
  self:_SetFleetType(self:GetParam().FleetType)
  self:_UpdateEquipInfo()
  self:_ShowCusumeItem()
  local dotinfo = {
    info = "ui_equip_reform"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function EquipRiseStarPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_Bg, self._Cancel, self)
  UGUIEventListener.AddButtonOnClick(widgets.img_Tag, self._Cancel, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_Cancel, self._Cancel, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_Amend, self._Amend, self)
  UGUIEventListener.AddButtonOnClick(widgets.obj_NoAmend, self._ToIntensify, self)
  self:RegisterEvent(LuaEvent.UpdateEquipMsg, self._UpdateEquipInfo)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self._ShowCusumeItem)
  self:RegisterEvent(LuaEvent.EquipRiseStarSuccess, self._RiseStarSuccess)
  self:RegisterEvent(LuaEvent.UpdataUserInfo, self._ShowCusumeItem, self)
end

function EquipRiseStarPage:_UpdateEquipInfo()
  local equipId = self:GetParam().EquipId
  local widgets = self:GetWidgets()
  local renovateInfo
  local equip = Logic.equipLogic:GetEquipById(equipId)
  local equipInfo = configManager.GetDataById("config_equip", equip.TemplateId)
  local isMaxStar = Logic.equipLogic:IsMaxStar(equipId)
  local canRise = Logic.equipLogic:CanRiseStar(equipId)
  local isNeedSelf = Logic.equipLogic:IsRiseNeedSelf(equipId)
  UIHelper.SetText(widgets.txt_Name, equipInfo.name)
  UIHelper.SetText(widgets.txt_OldIntensifyLevel, "+" .. math.tointeger(equip.EnhanceLv))
  UIHelper.SetStar(widgets.obj_oldStar, widgets.trans_oldStar, equip.Star)
  UIHelper.SetImage(widgets.img_OldIcon, equipInfo.icon)
  UIHelper.SetImage(widgets.img_OldQuality, QualityIcon[equipInfo.quality])
  widgets.obj_NewEquip:SetActive(not isMaxStar)
  widgets.txt_MaxWarning.gameObject:SetActive(isMaxStar)
  widgets.obj_NoAmend:SetActive(isMaxStar or not canRise)
  widgets.btn_Amend.gameObject:SetActive(canRise)
  if isMaxStar then
    renovateInfo = configManager.GetDataById("config_equip_enhance_renovate", equip.Star)
    UIHelper.SetText(widgets.tx_Cancel, "\231\161\174\229\174\154")
    UIHelper.SetText(widgets.txt_MaxWarning, UIHelper.GetString(110024))
  else
    renovateInfo = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
    local lvstr = "+" .. math.tointeger(equip.EnhanceLv)
    UIHelper.SetText(widgets.txt_NewIntensifyLevel, lvstr)
    UIHelper.SetStar(widgets.obj_newStar, widgets.trans_newStar, equip.Star + 1)
    UIHelper.SetImage(widgets.img_NewIcon, equipInfo.icon)
    UIHelper.SetImage(widgets.img_NewQuality, QualityIcon[equipInfo.quality])
    local cancelStr = canRise and "\229\143\150\230\182\136" or "\231\161\174\229\174\154"
    UIHelper.SetText(widgets.tx_Cancel, cancelStr)
  end
  UIHelper.SetText(widgets.txt_Hit, UIHelper.GetString(110021))
  widgets.trans_equip.gameObject:SetActive(isNeedSelf)
  local tabSelectEquip = Data.equipData:GetConsumeEquip()
  self.m_tabSelectId = self:_GetEquipIds(tabSelectEquip)
  if isNeedSelf then
    UIHelper.CreateSubPart(widgets.obj_equip, widgets.trans_equip, renovateInfo.equip_self_count, function(nIndex, tabPart)
      local itemnum, enough = Logic.equipLogic:_GetConsumesNum(BagItemType.EQUIP, equip.TemplateId, renovateInfo.equip_self_count, self.m_equipId)
      itemnum = math.tointeger(itemnum)
      local str
      if enough then
        UIHelper.SetText(tabPart.Tex_num, itemnum .. "/" .. renovateInfo.equip_self_count)
      else
        UIHelper.SetText(tabPart.Tex_num, itemnum .. "/" .. renovateInfo.equip_self_count, "d54852")
      end
      local selected = tabSelectEquip and tabSelectEquip[nIndex]
      tabPart.obj_add:SetActive(not selected)
      tabPart.Img_icon.gameObject:SetActive(selected)
      if selected then
        UIHelper.SetImage(tabPart.img_quality, QualityIcon[tabSelectEquip[nIndex].quality])
        UIHelper.SetImage(tabPart.Img_icon, tabSelectEquip[nIndex].icon)
        table.insert(self.m_effObjs, 1, tabPart.eff_rise)
      else
        UIHelper.SetImage(tabPart.img_quality, "uipic_ui_common_bg_kongdikuang")
      end
      UGUIEventListener.AddButtonOnClick(tabPart.Img_bg, function()
        if enough then
          self:_ShowEquipBag(enough, equipId, renovateInfo.equip_self_count)
        else
          globalNoitceManager:ShowItemInfoPage(GoodsType.EQUIP, equip.TemplateId)
        end
      end)
    end)
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(widgets.trans_consumeroot)
  self:_ShowEquipPSkill(equipId)
end

function EquipRiseStarPage:_ShowCusumeItem()
  local equipId = self:GetParam().EquipId
  local widgets = self:GetWidgets()
  local consumes = Logic.equipLogic:GetRiseStartMaterial(equipId)
  UIHelper.CreateSubPart(widgets.obj_Consume, widgets.trans_Consume, #consumes, function(nIndex, tabPart)
    local value = consumes[nIndex]
    local icon = Logic.goodsLogic:GetIcon(value[2], value[1])
    UIHelper.SetImage(tabPart.img_Icon, icon)
    local itemnum, enough = Logic.equipLogic:_GetConsumesNum(value[1], value[2], value[3])
    itemnum = math.tointeger(itemnum)
    local txt_Count
    if enough then
      UIHelper.SetText(tabPart.txt_Count, itemnum .. "/" .. math.tointeger(value[3]))
    else
      UIHelper.SetTextColor(tabPart.txt_Count, itemnum .. "/" .. math.tointeger(value[3]), "d54852")
      self.m_isEnough = enough
    end
  end)
end

function EquipRiseStarPage:_ShowEquipBag(enough, equipId, maxnum)
  local canRise = Logic.equipLogic:CanRiseStar(equipId)
  if not canRise then
    noticeManager:ShowTip(UIHelper.GetString(170011))
    return
  end
  if enough then
    UIHelper.OpenPage("SelectBagPage", {
      BagType.EQUIP_BAG,
      "RiseStar",
      maxnum,
      equipId,
      FleetType = self:_GetFleetType()
    })
  else
    noticeManager:ShowTip(UIHelper.GetString(170012))
  end
end

function EquipRiseStarPage:_ToIntensify()
  UIHelper.OpenPage("EquipIntensifyPage", {
    EquipId = self.m_equipId,
    FleetType = self:_GetFleetType()
  })
  UIHelper.ClosePage("EquipRiseStarPage")
end

function EquipRiseStarPage:_Amend()
  local equipId = self:GetParam().EquipId
  local consumes = Logic.equipLogic:GetRiseStartMaterial(equipId)
  for i, value in pairs(consumes) do
    local itemnum, enough = Logic.equipLogic:_GetConsumesNum(value[1], value[2], value[3])
    if not enough then
      globalNoitceManager:ShowItemInfoPage(value[1], value[2])
      noticeManager:OpenTipPage(self, 170006)
      return
    end
  end
  local isNeedSelf = Logic.equipLogic:IsRiseNeedSelf(equipId)
  local equip = Logic.equipLogic:GetEquipById(equipId)
  if isNeedSelf and #self.m_tabSelectId == 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(170013))
    return
  end
  Service.equipService:SendRiseStar(self.m_equipId, self.m_tabSelectId)
  Data.equipData:ResetConsumeEquip()
end

function EquipRiseStarPage:_Cancel()
  UIHelper.ClosePage("EquipRiseStarPage")
end

function EquipRiseStarPage:_GetEquipIds(tabSelectEquip)
  local res = {}
  for k, v in pairs(tabSelectEquip) do
    res[#res + 1] = math.tointeger(v.EquipId)
  end
  return res
end

function EquipRiseStarPage:_RiseStarSuccess()
  noticeManager:ShowTip(UIHelper.GetString(170005))
  self:_PlayEffect()
end

function EquipRiseStarPage:_PlayEffect()
  local widgets = self:GetWidgets()
  self.m_effObjs[1]:SetActive(true)
  local total = #self.m_effObjs - 1
  for i = 1, total do
    local timer = self:CreateTimer(function()
      self.m_effObjs[i + 1]:SetActive(true)
    end, i, 1, false)
    self:StartTimer(timer)
  end
  local closeTimer = self:CreateTimer(function()
    self:_DisableEffect()
  end, #self.m_effObjs, 1, false)
  self:StartTimer(closeTimer)
end

function EquipRiseStarPage:_DisableEffect()
  for _, v in ipairs(self.m_effObjs) do
    v:SetActive(false)
  end
end

function EquipRiseStarPage:_ShowEquipPSkill(equipId)
  local equipData = Data.equipData:GetEquipDataById(equipId)
  local equipPskills = Logic.equipLogic:GetEquipRisePSkillById(equipData.TemplateId)
  local widgets = self:GetWidgets()
  local getLv = function(open, info, max)
    if open then
      local lv = info.PSkillLv
      if max then
        return lv
      end
      return lv + 1
    else
      return 1
    end
  end
  widgets.obj_pskilllist:SetActive(0 < #equipPskills)
  if 0 < #equipPskills then
    UIHelper.CreateSubPart(widgets.obj_pskill, widgets.trans_pskill, #equipPskills, function(index, tabParts)
      local pskillId = equipPskills[index]
      local name = Logic.shipLogic:GetPSkillName(pskillId)
      local ok, info = Logic.equipLogic:CheckPSkillOpen(equipId, pskillId)
      local max = Logic.equipLogic:CheckPSkillMax(equipId, pskillId)
      local lv = getLv(ok, info, max)
      local lvdes = ""
      if not ok then
        lvdes = name
      elseif not max then
        lvdes = "\230\138\128\232\131\189\230\143\144\229\141\135\232\135\179" .. lv + 1
      else
        lvdes = "\230\138\128\232\131\189\230\187\161\231\186\167"
      end
      local namedes = ok and name or "\232\142\183\229\190\151\230\138\128\232\131\189"
      local des = Logic.shipLogic:GetPSkillDesc(pskillId, lv)
      UIHelper.SetText(tabParts.tx_name, namedes)
      UIHelper.SetText(tabParts.tx_lv, lvdes)
      UIHelper.SetText(tabParts.tx_des, des)
    end)
  end
end

function EquipRiseStarPage:DoOnHide()
  Data.equipData:ResetConsumeEquip()
end

function EquipRiseStarPage:DoOnClose()
  Data.equipData:ResetConsumeEquip()
end

return EquipRiseStarPage
