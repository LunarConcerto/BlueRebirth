local GirlShowPage = class("UI.GirlInfo.GirlShowPage", LuaUIPage)
local heroDev = Logic.developLogic
local e_lvstate = heroDev.E_HeroLvState
local MAXBREAKLEVEL = 5
local PskillTypeColorMap = {
  [TalentType.ALL] = {
    236,
    161,
    43
  },
  [TalentType.ATTACK] = {
    236,
    161,
    43
  },
  [TalentType.DEFEND] = {
    65,
    122,
    227
  },
  [TalentType.ASSIST] = {
    43,
    205,
    58
  }
}

function GirlShowPage:DoInit()
  self.m_tabWidgets = nil
  self.m_tabShipInfo = {}
  self.m_propNum = {}
  self.m_pskillArr = {}
  self.m_fleetType = FleetType.Normal
  self.m_equipPartWidgets = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function GirlShowPage:_SetFleetType(fleetType)
  self.m_fleetType = fleetType
end

function GirlShowPage:_GetFleetType()
  return self.m_fleetType
end

function GirlShowPage:DoOnOpen()
  local params = self:GetParam()
  self.isNpc = params.isNpc
  self.m_heroId = params.heroId
  self:_SetFleetType(params.FleetType)
  self:_RegisterAllDot()
  self.m_tabShipInfo = Data.heroData:GetHeroById(self.m_heroId)
  self:_Refresh()
end

function GirlShowPage:_Refresh()
  local sm_id = Data.heroData:GetHeroById(self.m_heroId).TemplateId
  self.m_pskillArr = Logic.shipLogic:GetAllPSkillArrbyShipMainId(sm_id)
  self.m_pskillArr = Logic.shipLogic:DisposeSkillArr(self.m_pskillArr, self.m_heroId)
  self:_LoadEquipInfo(self.m_heroId)
  self:_LoadPropertInfo(self.m_tabShipInfo)
  self:_LoadSkillInfo(self.m_pskillArr, self.m_heroId)
  self:_LoadBreakInfo()
  self:_ShowHeroChar(sm_id)
  self:ShowMagazineTag()
end

function GirlShowPage:UpdateGirlInfo()
  self.m_tabShipInfo = Data.heroData:GetHeroById(self.m_heroId)
  self:_LoadEquipInfo(self.m_heroId)
  self:_LoadPropertInfo(self.m_tabShipInfo)
  self:_LoadBreakInfo()
  self:ShowMagazineTag()
end

function GirlShowPage:UpdateGirlTog(heroId)
  self.m_tabWidgets.tween_dongHua:ResetToBeginning()
  self.m_tabWidgets.tween_dongHua:Play(true)
  noticeManager:CloseTip()
  self.m_heroId = heroId
  self:_RegisterAllDot()
  self.m_tabShipInfo = Data.heroData:GetHeroById(self.m_heroId)
  self:_Refresh()
end

function GirlShowPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._UpdateHero, self)
  self:RegisterEvent(LuaEvent.UpdateEquipMsg, self._UpdateHero, self)
  self:RegisterEvent(LuaEvent.UpdateGirlTog, self.UpdateGirlTog)
  self:RegisterEvent(LuaEvent.UpdateBagEquip, self.UpdateGirlInfo)
  self:RegisterEvent(LuaEvent.GirlInfoTween, self._GirlInfoTween)
  self:RegisterEvent(LuaEvent.GirlInfoUIReset, self._ResetUI)
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_attribute, self._ClickAttribute, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_add, self._AutoSetEquip, self, true)
  UGUIEventListener.AddButtonOnClick(widgets.btn_remove, self._AutoSetEquip, self, false)
  UGUIEventListener.AddButtonOnClick(widgets.btnLevelUp, self.btnLevelUp, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_further, self._ShowHeroFurther, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_fashion, self._ClickFashion, self)
  self:RegisterEvent(LuaEvent.UpdateEquipEffect, self._UpdateHero)
end

function GirlShowPage:_RegisterAllDot()
  local widgets = self:GetWidgets()
  local heroId = self.m_heroId
  self:RegisterRedDot(widgets.redDot, heroId)
  self:RegisterRedDot(widgets.lf_reddot, heroId)
end

function GirlShowPage:btnLevelUp(go, isAdd)
  UIHelper.OpenPage("ShipLevelupPage", {
    heroId = self.m_heroId
  })
end

function GirlShowPage:_ShowHeroFurther()
  local state, cid = heroDev:GetLHeroState(self.m_heroId)
  if state == e_lvstate.FULL then
    noticeManager:ShowTip(UIHelper.GetString(911007))
  else
    local param = {
      heroId = self.m_heroId,
      cid = 1
    }
    UIHelper.OpenPage("ShipMaxLevelupPage", param)
  end
end

function GirlShowPage:_ResetUI()
  local widgets = self:GetWidgets()
  widgets.tween_dongHua:ResetToEnd()
end

function GirlShowPage:_AutoSetEquip(go, isAdd)
  local heroId = self.m_heroId
  local ok, msg = Logic.equipLogic:AutoSetEquips(heroId, isAdd, self:_GetFleetType())
  if not ok then
    noticeManager:ShowTip(msg)
  end
end

function GirlShowPage:_UpdateHero()
  self.m_tabShipInfo = Data.heroData:GetHeroById(self.m_heroId)
  self.m_tabProp = Logic.attrLogic:GetHeroFinalShowAttrById(self.m_heroId, self:_GetFleetType())
  self.m_propNum = Logic.attrLogic:DealTabPropNew(self.m_tabProp)
  self:_Refresh()
end

function GirlShowPage:_GirlInfoTween(delta)
  local position = configManager.GetDataById("config_parameter", 95).arrValue
  if delta then
    self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D = Vector2.New(delta, position[3])
  else
    self.m_tabWidgets.tween_dongHua.from = self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D
    self.m_tabWidgets.tween_dongHua:ResetToBeginning()
    self.m_tabWidgets.tween_dongHua:Play(true)
  end
end

function GirlShowPage:_LoadEquipInfo(heroId)
  local shipInfo = Data.heroData:GetHeroById(heroId)
  local tmp = Logic.shipLogic:GetShipEquipInfo(shipInfo.TemplateId, shipInfo)
  local fleetType, heroId, towerLock, equipId, isActivity, isLLEquip
  fleetType = self:_GetFleetType()
  heroId = self.m_heroId
  local equips = Data.heroData:GetEquipsByType(heroId, fleetType)
  if equips == nil then
    logError("can not find equip data heroId:" .. heroId .. " fleetType:" .. fleetType)
    return
  end
  local shipEquips = equips
  self.m_equipPartWidgets = {}
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_equip, self.m_tabWidgets.trans_equip, #tmp, function(index, tabPart)
    equipId = shipEquips[index].EquipsId
    tabPart.img_iconbg.gameObject:SetActive(equipId ~= 0)
    tabPart.lock:SetActive(not tmp[index].open)
    tabPart.plus:SetActive(tmp[index].open)
    tabPart.obj_towerlock:SetActive(false)
    tabPart.obj_activity:SetActive(false)
    tabPart.obj_binding:SetActive(false)
    self.m_equipPartWidgets[index] = tabPart
    if equipId == 0 then
      if self.isNpc then
        tabPart.lock:SetActive(true)
      elseif not tmp[index].open then
        UGUIEventListener.AddButtonOnClick(tabPart.btn_equip, function()
          local str = string.format(UIHelper.GetString(180012), tmp[index].advanceDesc)
          noticeManager:ShowTip(str)
        end)
      else
        UGUIEventListener.AddButtonOnClick(tabPart.btn_equip, self._ShowEquipPage, self, nil)
      end
    else
      towerLock = Logic.equipLogic:IsTowerLock(equipId, fleetType)
      tabPart.obj_towerlock:SetActive(towerLock)
      local ifShowLockEffect = Logic.equipLogic:IsBindLock(equipId, fleetType)
      tabPart.obj_binding:SetActive(ifShowLockEffect)
      local equipInfo = Logic.equipLogic:GetEquipById(equipId)
      isActivity = Logic.equipLogic:IsAEquip(equipInfo.TemplateId)
      tabPart.obj_activity:SetActive(isActivity)
      isLLEquip = Logic.equipLogic:IsLLEquip(equipInfo.TemplateId)
      tabPart.obj_limit:SetActive(isLLEquip)
      local txt_IntensifyLevel = "+" .. math.tointeger(equipInfo.EnhanceLv)
      if 0 >= equipInfo.EnhanceLv then
        txt_IntensifyLevel = " "
      end
      UIHelper.SetText(tabPart.txt_IntensifyLevel, txt_IntensifyLevel)
      UIHelper.SetStar(tabPart.obj_star, tabPart.trans_star, equipInfo.Star)
      local shipEquipInfo = configManager.GetDataById("config_equip", equipInfo.TemplateId)
      UIHelper.SetImage(tabPart.img_icon, tostring(shipEquipInfo.icon))
      UIHelper.SetImage(tabPart.img_iconbg, QualityIcon[shipEquipInfo.quality])
      UGUIEventListener.AddButtonOnClick(tabPart.btn_equip, self._ShowEquipInfo, self, {
        equipId = equipId,
        showEquipType = ShowEquipType.Info,
        FleetType = self:_GetFleetType()
      })
      local isHave = Logic.equipLogic:EquipIsHaveEffect(equipInfo.TemplateId)
      tabPart.img_skin:SetActive(isHave)
    end
  end)
  self.m_tabWidgets.btn_fashion.gameObject:SetActive(false)
  self.m_tabWidgets.btn_fashion.gameObject:SetActive(true)
end

function GirlShowPage:_ShowEquipInfo(go, args)
  args.isNpc = self.isNpc
  UIHelper.OpenPage("ShowEquipPage", args)
end

function GirlShowPage:_ShowEquipPage()
  eventManager:SendEvent("switchtag", 3)
end

local attrStr = {
  [AttrTypeNew.Common] = "Common",
  [AttrTypeNew.Gun] = "Gun",
  [AttrTypeNew.Torpedo] = "Torpedo",
  [AttrTypeNew.Plane] = "Plane"
}

function GirlShowPage:_LoadPropertInfo(tabShipInfo)
  local heroId = self.m_heroId
  local widgets = self:GetWidgets()
  self.m_tabProp = Logic.attrLogic:GetHeroFinalShowAttrById(self.m_heroId, self:_GetFleetType())
  self.m_propNum = Logic.attrLogic:DealTabPropNew(self.m_tabProp)
  self.m_tabWidgets.txt_fight.text = math.tointeger(Logic.attrLogic:GetBattlePower(tabShipInfo.HeroId, self:_GetFleetType()))
  local state = heroDev:GetLHeroState(heroId)
  widgets.btn_further.gameObject:SetActive(state ~= e_lvstate.LEVELUP)
  widgets.btnLevelUp.gameObject:SetActive(state == e_lvstate.LEVELUP)
  UIHelper.SetText(widgets.txt_Lv, math.tointeger(tabShipInfo.Lvl))
  local needExp = Logic.shipLogic:GetHeroLevelExp(tabShipInfo.Lvl)
  local lvRad
  if state == e_lvstate.FULL then
    lvRad = UIHelper.GetString(911012)
    widgets.sdr_jingyantiao.value = 1
  elseif state == e_lvstate.FURTHER then
    lvRad = needExp .. "/" .. needExp
    widgets.sdr_jingyantiao.value = 1
  else
    lvRad = math.tointeger(tabShipInfo.Exp) .. "/" .. needExp
    widgets.sdr_jingyantiao.value = math.tointeger(tabShipInfo.Exp) / needExp
  end
  UIHelper.SetText(widgets.txt_LvRadio, lvRad)
  local equipAttr = Logic.attrLogic:GetHeroEquipAttrById(tabShipInfo.HeroId, self:_GetFleetType())
  self:_LoadAttrInfo(tabShipInfo, equipAttr)
  local curHp = Logic.shipLogic:GetHeroHp(tabShipInfo.HeroId, self:_GetFleetType())
  widgets.sdr_shengmingtiao.value = Logic.repaireLogic:HeroHpShow(tabShipInfo, self:_GetFleetType())
  local maxHp = self.m_tabProp[AttrType.HP]
  widgets.txt_LifeRadio.text = math.ceil(curHp) .. "/" .. maxHp
end

function GirlShowPage:_LoadAttrInfo(tabShipInfo, equipAttr)
  local heroInfo = Data.heroData:GetHeroById(self.m_heroId)
  local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId)
  local tbl = shipInfo.attr_type_show
  for index = AttrTypeNew.Common, AttrTypeNew.Plane do
    local attrTable = self.m_propNum[index]
    local result = false
    for nIndex = 1, #tbl do
      if index == tbl[nIndex] then
        result = true
      end
    end
    local str = attrStr[index]
    self.m_tabWidgets["obj" .. str]:SetActive(result and 0 < #attrTable)
  end
  for nIndex = 1, #tbl do
    local attrIndex = tbl[nIndex]
    local attrTable = self.m_propNum[attrIndex]
    local str = attrStr[attrIndex]
    UIHelper.CreateSubPart(self.m_tabWidgets["obj_" .. str], self.m_tabWidgets["trans_" .. str], #attrTable, function(nIndexSub, tabPartSub)
      local aType = attrTable[nIndexSub].type
      local tabConfig = configManager.GetDataById("config_attribute", aType)
      local name = Logic.attrLogic:GetName(aType, tabShipInfo.TemplateId)
      UIHelper.SetText(tabPartSub.Tx_prop, name)
      UIHelper.SetImage(tabPartSub.Im_icon, tabConfig.attr_icon)
      local num = attrTable[nIndexSub].num
      num = num .. tabConfig.attr_unit
      if equipAttr[aType] and equipAttr[aType] ~= 0 then
        UIHelper.SetTextColor(tabPartSub.Tx_num, num, "2bcd3a")
      else
        UIHelper.SetText(tabPartSub.Tx_num, num)
      end
    end)
  end
  local widgets = self:GetWidgets()
  LayoutRebuilder.ForceRebuildLayoutImmediate(widgets.trans_content)
end

function GirlShowPage:_LoadSkillInfo(pskillArr, heroId)
  local widgets = self:GetWidgets()
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local displayArr = {}
  for i, pskillId in ipairs(pskillArr) do
    local displayData = {}
    displayData.pskillId = pskillId
    displayData.heroId = heroId
    local showSkillId = Logic.shipLogic:GetReplaceSkillId(pskillId, heroId)
    displayData.name = Logic.shipLogic:GetPSkillName(showSkillId)
    displayData.icon = Logic.shipLogic:GetPSkillIcon(showSkillId, heroInfo.TemplateId)
    displayData.lv = Logic.shipLogic:GetHeroPSkillLv(heroId, pskillId)
    displayData.desc = Logic.shipLogic:GetPSkillDesc(showSkillId, displayData.lv)
    displayData.type = Logic.shipLogic:GetPSkillType(showSkillId)
    local bUnlock, msg = Logic.shipLogic:CheckHeroPSkillActive(heroId, showSkillId)
    local bUnlock2 = Logic.shipLogic:CheckHeroPSkillActive(heroId, showSkillId)
    displayData.lock, displayData.lockInfo = not bUnlock, msg
    displayData.empty = false
    displayArr[i] = displayData
  end
  local colorCache
  UIHelper.CreateSubPart(widgets.obj_pskillItem, widgets.trans_pskillGrid, #displayArr, function(index, part)
    local data = displayArr[index]
    UIHelper.SetText(part.txt_name, data.name)
    colorCache = PskillTypeColorMap[data.type]
    part.txt_name.color = Color.New(colorCache[1] / 255, colorCache[2] / 255, colorCache[3] / 255, 1)
    if data.lv > 0 then
      UIHelper.SetText(part.txt_lv, "Lv." .. math.tointeger(data.lv))
    end
    UIHelper.SetImage(part.img_icon, data.icon)
    part.obj_lock:SetActive(data.lock)
    local skillId = data.pskillId
    local skillIdReal = skillId
    if type(skillId) == "table" then
      skillIdReal = skillId[1]
    end
    part.obj_lvbg:SetActive(type(skillId) ~= "table")
    self:RegisterRedDot(part.redDot, heroId, skillIdReal)
    UGUIEventListener.AddButtonOnClick(part.btn_click, function()
      local levelMax = Logic.shipLogic:GetPSkillLvMax(skillIdReal)
      if levelMax <= 1 then
        local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
        local params
        if type(skillId) == "table" then
          params = ItemInfoPage.GenPSkillsData(skillId, data.heroId, heroInfo.TemplateId)
        else
          params = ItemInfoPage.GenPSkillData(skillIdReal, data.heroId)
        end
        params.isNpc = self.isNpc
        UIHelper.OpenPage("ItemInfoPage", params)
      else
        UIHelper.OpenPage("SkillLevelupPage", {
          heroId = heroId,
          skillId = data.pskillId
        })
      end
    end)
  end)
end

function GirlShowPage:_LoadBreakInfo()
  local shipInfo = self.m_tabShipInfo
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.obj_tupoItem, widgets.trans_tupo, MAXBREAKLEVEL, function(index, tabPart)
    index = index + 1
    local tid, tog = self:_GetTid(shipInfo.Advance, index, shipInfo.TemplateId)
    local temp = configManager.GetDataById("config_ship_break", tid).desc
    if tog then
      tabPart.num.text = index
      tabPart.num.color = Color.New(0.2549019607843137, 0.48627450980392156, 0.8901960784313725, 1)
      UIHelper.SetImage(tabPart.img_star, "uipic_ui_attribute_im_xingxing_lan")
      tabPart.txt_icon.color = Color.New(0.2549019607843137, 0.48627450980392156, 0.8901960784313725, 1)
      tabPart.txt_dian.color = Color.New(0.2549019607843137, 0.48627450980392156, 0.8901960784313725, 1)
      UIHelper.SetText(tabPart.txt_miaoshu, temp)
      tabPart.txt_miaoshu.color = Color.New(0.2549019607843137, 0.48627450980392156, 0.8901960784313725, 1)
    else
      tabPart.num.color = Color.New(0.4549019607843137, 0.5254901960784314, 0.6078431372549019, 1)
      tabPart.txt_icon.color = Color.New(0.4549019607843137, 0.5254901960784314, 0.6078431372549019, 1)
      tabPart.txt_dian.color = Color.New(0.4549019607843137, 0.5254901960784314, 0.6078431372549019, 1)
      tabPart.txt_miaoshu.color = Color.New(0.4549019607843137, 0.5254901960784314, 0.6078431372549019, 1)
      UIHelper.SetImage(tabPart.img_star, "uipic_ui_attribute_im_xingxing_hui")
      UIHelper.SetText(tabPart.num, index)
      UIHelper.SetText(tabPart.txt_miaoshu, temp)
    end
  end)
end

function GirlShowPage:_ClickAttribute()
  local propNum = Logic.attrLogic:DealTabProp(self.m_tabProp)
  UIHelper.OpenPage("AttributePage", {
    propNum,
    self.m_tabShipInfo
  })
end

function GirlShowPage:_GetTid(advance, index, tid)
  if index <= advance then
    return tid - (advance - index), true
  else
    return tid + (index - advance), false
  end
end

local GIRL_CharWidth = 640
local GIRL_CharWidthSpace = 9.5

function GirlShowPage:_ShowHeroChar(sm_id)
  local widgets = self:GetWidgets()
  local charId, charLv
  local chars, charLvs = Logic.shipLogic:GetHeroCharcater(sm_id)
  local width, height
  local mimaLv = Logic.shipLogic:GetHeroCharcaterMaxLevel(sm_id)
  UIHelper.CreateSubPart(widgets.obj_char, widgets.trans_char, #chars, function(index, tabPart)
    charId, charLv = chars[index], charLvs[index]
    local name = Logic.shipLogic:GetCharacterName(charId)
    local desc = Logic.buildingLogic:GetCharacterAdditionStr(charId, charLv)
    UIHelper.SetText(tabPart.tx_title, name .. "  (Lv." .. charLv .. ")\239\188\154")
    width = GIRL_CharWidth - tabPart.tx_title.preferredWidth - GIRL_CharWidthSpace
    if next(desc) == nil then
      logError("can not find hero char desc,sm_id :" .. sm_id)
    else
      local item = desc[1]
      UIHelper.SetText(tabPart.tx_desc, string.format(UIHelper.GetString(item.strId), item.value))
    end
    tabPart.tx_desc.text = tabPart.tx_desc.text .. "("
    for i = mimaLv[index][1], mimaLv[index][2] do
      local desc1 = Logic.buildingLogic:GetCharacterAdditionStr(charId, i)
      local value = desc1[1].value
      if i <= charLv then
        if i == mimaLv[index][2] then
          tabPart.tx_desc.text = tabPart.tx_desc.text .. value .. "%)"
        else
          tabPart.tx_desc.text = tabPart.tx_desc.text .. value .. "%/"
        end
        tabPart.tx_desc.color = Color.New(0.2549019607843137, 0.48627450980392156, 0.8901960784313725, 1)
      elseif i == mimaLv[index][2] then
        tabPart.tx_desc.text = tabPart.tx_desc.text .. "<color=#74869B>" .. value .. "%)" .. "</color>"
      else
        tabPart.tx_desc.text = tabPart.tx_desc.text .. "<color=#74869B>" .. value .. "%/" .. "</color>"
      end
    end
    height = tabPart.rt_desc.sizeDelta.y
    tabPart.rt_desc.sizeDelta = Vector2.New(width, height)
  end)
end

function GirlShowPage:ShowMagazineTag()
  local heroInfo = Data.heroData:GetHeroById(self.m_heroId)
  local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId)
  local tagList = configManager.GetDataById("config_ship_handbook", shipInfo.sf_id).magazine_tag
  UIHelper.CreateSubPart(self.m_tabWidgets.tag, self.m_tabWidgets.content_tag, #tagList, function(index, tabPart)
    local config = configManager.GetDataById("config_magazine_tag", tagList[index])
    UIHelper.SetText(tabPart.tx_tag, config.name)
  end)
end

function GirlShowPage:_ClickFashion()
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

return GirlShowPage
