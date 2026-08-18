local ShowEquipPage = class("UI.Common.ShowEquipPage", LuaUIPage)
local DropPath = require("ui.page.Common.DropPath")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local CommonRewardItem = require("ui.page.CommonItem")

function ShowEquipPage:DoInit()
  self.m_tabWidgets = nil
  self.m_openParam = nil
  self.m_equipId = 0
  self.showIndex = 0
  self.totalBuyNum = 1
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_fleetType = FleetType.Normal
  self.priceIndex = -1
  self.selectCurrTab = {}
  self.priceItem = {}
end

function ShowEquipPage:_SetFleetType(fleetType)
  self.m_fleetType = fleetType
end

function ShowEquipPage:_GetFleetType()
  return self.m_fleetType
end

function ShowEquipPage:showEquip()
  self:_ResetShow()
  if self.showEquipType == ShowEquipType.Shop or self.showEquipType == ShowEquipType.Simple then
    self:showEquipByTid()
  elseif self.showEquipType == ShowEquipType.InfoBag or self.showEquipType == ShowEquipType.Info then
    self:showEquipById()
  end
  self:_ShowTipRoot(self.m_tid)
  self:_ShowLevelLimitInfo(self.m_tid)
end

function ShowEquipPage:showEquipById()
  local equip = Logic.equipLogic:GetEquipById(self.m_equipId)
  self.tabAttrInfo = Logic.equipLogic:GetCurEquipFinaAttr(equip.EquipId)
  self.m_equipStar = equip.Star
  local txt_IntensifyLevel = "+" .. math.tointeger(equip.EnhanceLv)
  if equip.EnhanceLv <= 0 then
    txt_IntensifyLevel = " "
  end
  self.m_tabWidgets.txt_IntensifyLevel.text = txt_IntensifyLevel
  UIHelper.SetStar(self.m_tabWidgets.obj_Star, self.m_tabWidgets.trans_Star, equip.Star)
  self:InitButton(equip)
  self:_SetBtns()
  self:_ShowActivityInfo(self.m_equipId)
end

function ShowEquipPage:showEquipByTid()
  self.tabAttrInfo = Logic.equipLogic:GetCurEquipFinaAttrByLv(self.m_tid)
  self.m_tabWidgets.txt_IntensifyLevel.text = " "
  UIHelper.SetStar(self.m_tabWidgets.obj_Star, self.m_tabWidgets.trans_Star, 0)
end

function ShowEquipPage:DoOnOpen()
  self.m_openParam = self:GetParam()
  self.isNpc = self.m_openParam.isNpc
  self.showEquipType = self.m_openParam.showEquipType
  self.showDrop = self.m_openParam.showDrop
  self.m_equipId = self.m_openParam.equipId
  self.m_tid = self.m_openParam.templateId
  self:_SetFleetType(self.m_openParam.FleetType)
  if self.m_equipId and self.m_equipId > 0 then
    local equip = Logic.equipLogic:GetEquipById(self.m_equipId)
    self.m_tid = equip.TemplateId
  end
  local equipInfo = configManager.GetDataById("config_equip", self.m_tid)
  self.m_equipMaxLv = equipInfo.enhance_level_max
  self.shipEquipInfo = configManager.GetDataById("config_equip", self.m_tid)
  self.customParam = self.m_openParam.customParam
  self.m_tabWidgets.drop:SetActive(self.showDrop == true)
  self.m_tabWidgets.obj_shop:SetActive(self.showEquipType == ShowEquipType.Shop)
  self.m_tabWidgets.obj_price:SetActive(self.showEquipType == ShowEquipType.Shop)
  self:showEquip()
  if self.showEquipType == ShowEquipType.Shop then
    local data = self.customParam
    self:_ShowCurrencyInfo()
    self:_SetAllPrice()
    self.totalBuyNum = 1
    if data.isBatch then
      self.m_tabWidgets.txt_buyNum.gameObject:SetActive(true)
      self.m_tabWidgets.txt_buyNum.text = self.totalBuyNum
      UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_leftButton, function()
        self:_ClickSubBuyNum()
      end)
      UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_rightButton, function()
        self:_ClickAddBuyNum(data.goodData)
      end)
    else
      self.m_tabWidgets.txt_buyNum.gameObject:SetActive(false)
    end
  end
  if self.showDrop == true then
    local dropData = {
      ryzaFormulaId = self.shipEquipInfo.ryza_formula_id
    }
    DropPath:_DisplayDrop(self.m_tabWidgets, self.shipEquipInfo.drop_path, self, dropData)
  end
  self:ApplyShipType()
  self.m_tabWidgets.txt_Name.text = self.shipEquipInfo.name
  UIHelper.SetImage(self.m_tabWidgets.img_Icon, self.shipEquipInfo.icon)
  UIHelper.SetImage(self.m_tabWidgets.img_quality, QualityIcon[self.shipEquipInfo.quality])
  local isHave = Logic.equipLogic:EquipIsHaveEffect(self.m_tid)
  self.m_tabWidgets.obj_effect:SetActive(isHave)
  self.m_tabWidgets.txt_equiptag.text = Logic.equipLogic:GetEquipTag(self.shipEquipInfo.ewt_id)
  self.m_tabWidgets.obj_morefather:SetActive(#self.tabAttrInfo > 6)
  if #self.tabAttrInfo > 6 then
    self.m_tabWidgets.txt_moreinfo.text = UIHelper.GetString(170007)
  end
  self.showCount = #self.tabAttrInfo / 6
  self:_ShowEquipInfo()
  self:_ShowCanEquipNum()
  self:_ShowEquipEffect()
end

function ShowEquipPage:ApplyShipType()
  local shipType, shipTypeInfo
  if #self.shipEquipInfo.equip_ship <= 0 then
    shipTypeInfo = UIHelper.GetString(920000174)
  else
    for v, k in pairs(self.shipEquipInfo.equip_ship) do
      shipType = configManager.GetDataById("config_ship_type", k)
      if v ~= #self.shipEquipInfo.equip_ship then
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
  self.m_tabWidgets.txt_equiptInfo.text = UIHelper.GetString(920000175) .. shipTypeInfo
end

function ShowEquipPage:InitButton(equip)
  local maxStar = Logic.equipLogic:GetEquipMaxStar(equip.TemplateId)
  local equipMaxLv = Logic.equipLogic:GetEquipMaxLv(equip.TemplateId)
  local canIntensify = Logic.equipLogic:IsBindLock(self.m_equipId, self:_GetFleetType()) and equipMaxLv <= equip.EnhanceLv or equipMaxLv > equip.EnhanceLv
  self.m_tabWidgets.gray_Intensify.Gray = not canIntensify
  if maxStar == math.tointeger(equip.Star) then
    if self.showEquipType == ShowEquipType.InfoBag then
      self.m_tabWidgets.btn_bagIntensify.gameObject:SetActive(true)
      self.m_tabWidgets.btn_bagRetrofit.gameObject:SetActive(false)
    elseif self.showEquipType == ShowEquipType.Info then
      self.m_tabWidgets.btn_Intensify.gameObject:SetActive(true)
      self.m_tabWidgets.btn_Retrofit.gameObject:SetActive(false)
    end
  else
    local renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
    if self.showEquipType == ShowEquipType.InfoBag then
      self.m_tabWidgets.btn_bagIntensify.gameObject:SetActive(equip.EnhanceLv < renovate.need_enhance_level)
      self.m_tabWidgets.btn_bagRetrofit.gameObject:SetActive(equip.EnhanceLv >= renovate.need_enhance_level)
    elseif self.showEquipType == ShowEquipType.Info then
      self.m_tabWidgets.btn_Intensify.gameObject:SetActive(equip.EnhanceLv < renovate.need_enhance_level)
      self.m_tabWidgets.btn_Retrofit.gameObject:SetActive(equip.EnhanceLv >= renovate.need_enhance_level)
    end
  end
  local common = Logic.equipLogic:IsCommonRiseEquip(equip.TemplateId)
  UIHelper.DisableButton(self.m_tabWidgets.btn_bagIntensify, common)
  local canDevelop = Logic.equipLogic:CanDevelop(equip.TemplateId)
  self.m_tabWidgets.obj_button:SetActive(self.showEquipType == ShowEquipType.Info and canDevelop)
  self.m_tabWidgets.obj_abutton:SetActive(self.showEquipType == ShowEquipType.Info and not canDevelop)
  self.m_tabWidgets.obj_bagEquipButton:SetActive(self.showEquipType == ShowEquipType.InfoBag and canDevelop)
end

function ShowEquipPage:_SetBtns()
  if self.isNpc then
    self.m_tabWidgets.btn_Demount.gameObject:SetActive(false)
    self.m_tabWidgets.btn_Change.gameObject:SetActive(false)
    self.m_tabWidgets.btn_Intensify.gameObject:SetActive(false)
    self.m_tabWidgets.btn_Retrofit.gameObject:SetActive(false)
    self.m_tabWidgets.btn_Binding.gameObject:SetActive(false)
    self.m_tabWidgets.btn_UnBinding.gameObject:SetActive(false)
  else
    self.m_tabWidgets.btn_Binding.gameObject:SetActive(self:_CanBind())
    self.m_tabWidgets.btn_UnBinding.gameObject:SetActive(self:_CanUnBind())
    self.m_tabWidgets.gray_Demount.Gray = self:_CanUnBind()
  end
end

function ShowEquipPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Close.gameObject, self.CloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.img_Tag.gameObject, self.CloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Demount.gameObject, self._Demount, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Change.gameObject, self._Change, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Intensify.gameObject, self._Intensify, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Retrofit.gameObject, self._Retrofit, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Binding.gameObject, self._Binding, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_UnBinding.gameObject, self._UnBinding, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_bagIntensify.gameObject, self._Intensify, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_bagRetrofit.gameObject, self._Retrofit, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_moreinfo, self._ShowEquipInfo, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_shop, self._ShopEquip, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, self.CloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.obj_adetail, self._OnGetAReward, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ademout.gameObject, self._Demount, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_achange.gameObject, self._Change, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_icon, self._OnIconClicked, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_effect, self._OpenEquipEffect, self)
  self:RegisterEvent("changeHeroEquip", self._ChangeHeroEquip, self)
  self:RegisterEvent(LuaEvent.AEQUIP_RefreshData, self.showEquip, self)
  self:RegisterEvent(LuaEvent.UpdateEquipEffect, self._ShowEquipEffect)
  self:RegisterEvent(LuaEvent.CloseWebView, self._UnmuteMusic, self)
  self:RegisterEvent(LuaEvent.UpdateEquipBind, self.showEquip, self)
  self:RegisterEvent(LuaEvent.GetUnBindReward, self.ShowEquipRetireReward, self)
end

function ShowEquipPage:_ShopEquip()
  local data = self.customParam
  if Logic.equipLogic:IsEquipBagFullAfterAdd(self.totalBuyNum * data.buyNum) then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClickDismantlePageOk()
        end
      end,
      nameOk = UIHelper.GetString(920000068)
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(170016), tabParams)
    return
  end
  local num = self.totalBuyNum
  local tabCondition = Logic.shopLogic:GetTableBuyCurrency(self.selectCurrTab)
  local isCan = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
  if isCan and Logic.shopLogic:IsOpenByShopId(data.shopId, true) then
    self.priceIndex = self.priceIndex ~= -1 and self.priceIndex or nil
    Service.shopService:SendBuyGoods(data.shopId, data.goodData.id, num, self.priceIndex)
    local dotinfo = {
      info = data.dotInfo,
      itemID = tostring(data.goodData.id)
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    local tab = {
      info = "shop_get",
      equip_id = tostring(data.goodData.goods[2])
    }
    RetentionHelper.Retention(PlatformDotType.equipGetLog, tab)
    UIHelper.ClosePage("ShowEquipPage")
  end
end

function ShowEquipPage:_ClickDismantlePageOk()
  UIHelper.OpenPage("DismantlePage")
end

function ShowEquipPage:_ShowEquipInfo()
  local isPlane = false
  local planeNume = 0
  if self.shipEquipInfo.ewt_id[1] == 18 or self.shipEquipInfo.ewt_id[1] == 19 or self.shipEquipInfo.ewt_id[1] == 20 then
    isPlane = true
  else
    isPlane = false
  end
  if self.showEquipType == ShowEquipType.Info then
    local heroId = Data.equipData:GetEquipHero(self.m_equipId, self:_GetFleetType())
    if 0 < heroId then
      planeNume = Logic.equipLogic:_getPlaneNum(heroId, self.m_equipId, self:_GetFleetType())
    end
  else
    isPlane = false
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_Property, self.m_tabWidgets.trans_Property, 6, function(nIndex, tabPart)
    local equipInfo = self.tabAttrInfo[nIndex + 6 * self.showIndex]
    tabPart.obj_prop:SetActive(equipInfo or isPlane)
    if equipInfo then
      if utf8.len(equipInfo.name) >= 3 then
        tabPart.txt_Name.text = string.format("<size=17>%s</size>", equipInfo.name)
      else
        tabPart.txt_Name.text = string.format("<size=17>%s</size>", equipInfo.name)
      end
      local attrValueShow = Logic.attrLogic:GetAttrShow(equipInfo.id, equipInfo.value)
      tabPart.txt_Value.text = attrValueShow
      UIHelper.SetImage(tabPart.img_Tag, equipInfo.icon)
      tabPart.img_Tag.gameObject:SetActive(true)
      tabPart.txt_Name.gameObject:SetActive(true)
      tabPart.txt_Value.gameObject:SetActive(true)
    elseif isPlane then
      isPlane = false
      local planeInfo = configManager.GetDataById("config_attribute", 3102)
      tabPart.txt_Name.text = planeInfo.attr_name
      tabPart.txt_Value.text = Mathf.ToInt(planeNume)
      UIHelper.SetImage(tabPart.img_Tag, planeInfo.attr_icon)
      tabPart.img_Tag.gameObject:SetActive(true)
      tabPart.txt_Value.gameObject:SetActive(true)
      tabPart.txt_Name.gameObject:SetActive(true)
    else
      tabPart.txt_Name.gameObject:SetActive(false)
      tabPart.txt_Value.gameObject:SetActive(false)
      tabPart.img_Tag.gameObject:SetActive(false)
    end
  end)
  self.showIndex = self.showIndex + 1
  if self.showIndex > self.showCount then
    self.showIndex = 0
  end
  self:_ShowEquipPSkill(self.m_equipId, self.m_tid)
end

function ShowEquipPage:_ChangeHeroEquip()
  self:CloseClick()
end

function ShowEquipPage:_Demount()
  local heroId = Data.equipData:GetEquipHero(self.m_equipId, self:_GetFleetType())
  if heroId == 0 then
    logError("logic error,can not find equip hero")
    return
  end
  local index = Logic.equipLogic:GetIndexByEquipId(self.m_equipId, self:_GetFleetType())
  local lock = Logic.equipLogic:IsBindLock(self.m_equipId, self:_GetFleetType())
  if lock then
    noticeManager:ShowTipById(6100010)
    return
  end
  Service.heroService:SendChangeEquip(heroId, index, 0, self:_GetFleetType())
  local content = string.format(UIHelper.GetString(170003), self.shipEquipInfo.name)
  noticeManager:ShowTip(content)
end

function ShowEquipPage:_Change()
  local lock = Logic.equipLogic:IsBindLock(self.m_equipId, self:_GetFleetType())
  if lock then
    noticeManager:ShowTipById(6100010)
    return
  end
  local heroId = Data.equipData:GetEquipHero(self.m_equipId, self:_GetFleetType())
  if heroId == 0 then
    logError("logic error,can not find equip hero")
    return
  end
  local index = Logic.equipLogic:GetIndexByEquipId(self.m_equipId, self:_GetFleetType())
  local tabTrenchId = Logic.equipLogic:GetTrenchByEquipId(self.m_equipId, self:_GetFleetType())
  self:CloseClick()
  UIHelper.OpenPage("BagPage", {
    BagType.EQUIP_BAG,
    EquipToBagSign.CHANGE_EQUIP,
    self.m_equipId,
    heroId,
    index,
    tabTrenchId,
    FleetType = self:_GetFleetType()
  })
end

function ShowEquipPage:_Intensify(go)
  local equipInfo = Logic.equipLogic:GetEquipById(self.m_equipId)
  local maxLv = Logic.equipLogic:GetEquipMaxLv(equipInfo.TemplateId)
  if maxLv <= equipInfo.EnhanceLv then
    local lock = Data.equipData:GetEquipState(self.m_equipId, self:_GetFleetType()) == MEquipState.LOCK
    if lock then
      local equipCfg = configManager.GetDataById("config_equip", equipInfo.TemplateId)
      local equipBreakLvConf = {}
      if equipCfg.quality ~= ItemQuality.UR then
        equipBreakLvConf = configManager.GetDataById("config_equip_levelbreak_item", LvBreakType.Normal)
      else
        equipBreakLvConf = configManager.GetDataById("config_equip_levelbreak_item", LvBreakType.UR)
      end
      local levelRank = equipBreakLvConf.level_rank
      if equipInfo.EnhanceLv >= levelRank[2] or equipInfo.EnhanceLv < levelRank[1] then
        noticeManager:ShowTipById(110034)
        return
      end
    else
      noticeManager:ShowTipById(110034)
      return
    end
  end
  self:CloseClick()
  UIHelper.OpenPage("EquipIntensifyPage", {
    EquipId = self.m_equipId,
    FleetType = self:_GetFleetType()
  })
end

function ShowEquipPage:_Retrofit()
  local equipInfo = Logic.equipLogic:GetEquipById(self.m_equipId)
  local maxStar = Logic.equipLogic:GetEquipMaxStar(equipInfo.TemplateId)
  if maxStar == math.tointeger(self.m_equipStar) then
    noticeManager:OpenTipPage(self, UIHelper.GetString(170009))
    return
  end
  self:CloseClick()
  UIHelper.OpenPage("EquipRiseStarPage", {
    EquipId = self.m_equipId,
    FleetType = self:_GetFleetType()
  })
end

function ShowEquipPage:CloseClick()
  UIHelper.ClosePage("ShowEquipPage")
end

function ShowEquipPage:_ClickSubBuyNum()
  local mixNum = 1
  local temp = self.totalBuyNum - mixNum
  if mixNum > temp then
    noticeManager:OpenTipPage(self, 270018)
    return
  else
    self.totalBuyNum = temp
  end
  self:_SetAllPrice()
end

function ShowEquipPage:_ClickAddBuyNum(data)
  local mixNum = 1
  local maxNum = data.is_buy_batch * 10
  local temp = self.totalBuyNum + mixNum
  if maxNum < temp then
    noticeManager:OpenTipPage(self, 270019)
    return
  else
    self.totalBuyNum = temp
  end
  self:_SetAllPrice()
end

function ShowEquipPage:_ShowEquipPSkill(equipId, templateId)
  local equipData
  if equipId ~= nil then
    equipData = Data.equipData:GetEquipDataById(equipId)
    templateId = equipData.TemplateId
  end
  local common = Logic.equipLogic:IsCommonRiseEquip(templateId)
  local equipPskills = Logic.equipLogic:GetEquipRisePSkillById(templateId)
  local widgets = self:GetWidgets()
  widgets.obj_pskilllist:SetActive(0 < #equipPskills)
  if 0 < #equipPskills then
    UIHelper.CreateSubPart(widgets.obj_pskill, widgets.trans_pskill, #equipPskills, function(index, tabParts)
      local pskillId = equipPskills[index]
      local name = Logic.shipLogic:GetPSkillName(pskillId)
      local ok, info = Logic.equipLogic:CheckPSkillOpen(equipId, pskillId)
      local lvdes = ok and "Level: " .. info.PSkillLv or UIHelper.GetString(920000112)
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
    LayoutRebuilder.ForceRebuildLayoutImmediate(widgets.trans_pskill)
  end
end

function ShowEquipPage:_ShowCanEquipNum()
  local widgets = self:GetWidgets()
  local tid = self:_getTid()
  if tid == 0 then
    return
  end
  local show, str = Logic.equipLogic:GetHeroMaxWearStr(tid)
  widgets.tx_equipnum.gameObject:SetActive(show)
  UIHelper.SetText(widgets.tx_equipnum, str)
end

function ShowEquipPage:_ShowActivityInfo(equipId)
  if equipId and 0 < equipId then
    local widgets = self:GetWidgets()
    local data = Data.equipData:GetEquipDataById(equipId)
    if data == nil then
      return
    end
    local tid = data.TemplateId
    local isAEquip = Logic.equipLogic:IsAEquip(tid)
    widgets.obj_activitytip:SetActive(isAEquip)
    widgets.obj_activity:SetActive(isAEquip)
    local aname = Logic.equipLogic:GetAPointName(tid)
    UIHelper.SetText(widgets.tx_aname, aname)
    local atip = Logic.equipLogic:GetAAddTip(equipId)
    UIHelper.SetText(widgets.tx_aaddtip, atip)
    local cur = Logic.equipLogic:GetAEquipPointCur(equipId)
    local max = Logic.equipLogic:GetAEquipPointMax(tid)
    UIHelper.SetText(widgets.tx_aprogress, cur .. " / " .. max)
    widgets.sld_aprogress.value = cur / max
    widgets.obj_aequiptip:SetActive(isAEquip)
    local agot = Logic.equipLogic:IsAEquipPointGot(equipId)
    local max = Logic.equipLogic:GetAEquipPointMax(tid)
    local cur = Logic.equipLogic:GetAEquipPointCur(equipId)
    local can = max <= cur and not agot
    widgets.obj_adetail:SetActive(isAEquip and can)
    widgets.obj_anoget:SetActive(isAEquip and max > cur)
    widgets.obj_agot:SetActive(isAEquip and agot)
    if isAEquip then
      self:_ShowAEquipReward(tid, widgets)
    end
  else
    self:_ResetAEquipWidgets()
  end
end

function ShowEquipPage:_ResetShow()
  self:_ResetAEquipWidgets()
end

function ShowEquipPage:_ResetAEquipWidgets()
  local widgets = self:GetWidgets()
  widgets.obj_activitytip:SetActive(false)
  widgets.obj_activity:SetActive(false)
  widgets.obj_adetail:SetActive(false)
  widgets.obj_aequiptip:SetActive(false)
  widgets.obj_abutton:SetActive(false)
end

function ShowEquipPage:_ShowAEquipReward(tid, widgets)
  local rewards = Logic.equipLogic:GetAEquipReward(tid)
  if rewards and rewards[1] then
    UIHelper.CreateSubPart(widgets.obj_areward, widgets.trans_arewards, 1, function(index, parts)
      local item = CommonRewardItem:new()
      item:Init(index, rewards[1], parts)
      UGUIEventListener.AddButtonOnClick(parts.im_frame, function(go, reward)
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId))
      end, nil, rewards[1])
    end)
  else
    logError("show activity equip reward find error, equip templateId: " .. tid)
  end
end

function ShowEquipPage:_ShowLevelLimitInfo(templateId)
  local widgets = self:GetWidgets()
  local isLLEquip, copyIds = Logic.equipLogic:IsLLEquip(templateId)
  widgets.obj_limit:SetActive(isLLEquip)
  widgets.obj_limitroot:SetActive(isLLEquip)
  UIHelper.CreateSubPart(widgets.obj_limitcopy, widgets.trans_limitcopy, #copyIds, function(index, tabPart)
    local str = Logic.copyLogic:GetShortTitle(copyIds[index])
    UIHelper.SetText(tabPart.tx_limit, str)
  end)
end

function ShowEquipPage:_ShowTipRoot(templateId)
  local isLLEquip = Logic.equipLogic:IsLLEquip(templateId)
  local pskills = Logic.equipLogic:GetEquipRisePSkillById(templateId)
  local widgets = self:GetWidgets()
  widgets.obj_tiproot:SetActive(isLLEquip or 0 < #pskills)
end

function ShowEquipPage:_getTid()
  local tid
  if self.m_equipId then
    local data = Data.equipData:GetEquipDataById(self.m_equipId)
    if data ~= nil then
      tid = data.TemplateId
    end
  elseif self.m_tid then
    tid = self.m_tid
  else
    tid = 0
  end
  return tid
end

function ShowEquipPage:_OnGetAReward()
  local tid = Logic.equipLogic:GetEquipTidByEquipId(self.m_equipId)
  if 0 < tid then
    Logic.equipactivityLogic:CheckAndSendGetReward(self.m_equipId)
  end
end

function ShowEquipPage:_ShowEquipEffect()
  self.tab_Widgets.btn_effect.gameObject:SetActive(self.showEquipType == ShowEquipType.Info)
  local heroId = Data.equipData:GetEquipHero(self.m_equipId, self:_GetFleetType())
  local serMapEffects = {}
  local equipFashionId = configManager.GetDataById("config_equip", self.m_tid).skill_fashion_id
  self.tab_Widgets.EquipEffectPart:SetActive(#equipFashionId ~= 0)
  if heroId ~= 0 then
    serMapEffects = Logic.equipLogic:GetSerMapEffects(heroId)
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_itemEffect, self.tab_Widgets.trans_itemEffect, #equipFashionId, function(index, tabPart)
    local skillFashion = configManager.GetDataById("config_skill_fashion", equipFashionId[index])
    UIHelper.SetText(tabPart.txt_name, skillFashion.skill_fashion_name)
    UIHelper.SetImage(tabPart.im_effect, skillFashion.show_picture)
    if next(serMapEffects) ~= nil and serMapEffects[skillFashion.equip_fashion_show_type][tonumber(equipFashionId[index])] then
      tabPart.obj_select:SetActive(true)
    else
      tabPart.obj_select:SetActive(false)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_play, self._PlayAdvio, self, tonumber(equipFashionId[index]))
  end)
end

function ShowEquipPage:_OpenEquipEffect()
  local funcOpen = moduleManager:CheckFunc(FunctionID.EquipEffect, true)
  if not funcOpen then
    return
  end
  local equipFashionTabId = configManager.GetDataById("config_equip", self.m_tid).skill_fashion_id
  local equipFashionId
  for k, v in pairs(equipFashionTabId) do
    equipFashionId = v
    break
  end
  if equipFashionId == nil then
    logError("equip_fashion_id \228\184\186\231\169\186")
    return
  end
  local skillFashion = configManager.GetDataById("config_skill_fashion", equipFashionId)
  local heroId = Data.equipData:GetEquipHero(self.m_equipId, self:_GetFleetType())
  local fashionId = Logic.shipLogic:GetShipFashioning(heroId)
  local param = {
    heroId = heroId,
    fashionId = fashionId,
    equipType = skillFashion.equip_fashion_show_type
  }
  UIHelper.OpenPage("EquipFashionPage", param)
end

function ShowEquipPage:_PlayAdvio(go, effectId)
  local funcOpen = moduleManager:CheckFunc(FunctionID.EquipEffect, true)
  if not funcOpen then
    return
  end
  SoundManager.Instance:PlayMusic("Role_unlock")
  Logic.equipLogic:_PlayAdvio(effectId)
end

function ShowEquipPage:_UnmuteMusic()
  SoundManager.Instance:PlayMusic("Role_unlock_finish")
end

function ShowEquipPage:_ShowCurrencyInfo()
  self.tab_Widgets.obj_price:SetActive(true)
  self.selectCurrTab = self.customParam.goodData.currency
  self:_CreateCurrency()
end

function ShowEquipPage:_Binding()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        self:sureBinging()
      end
    end
  }
  noticeManager:ShowMsgBox(6100006, tabParams)
end

function ShowEquipPage:sureBinging()
  if not self:_CanBind() then
    return
  end
  local heroId = Data.equipData:GetEquipHero(self.m_equipId, self:_GetFleetType())
  logWarning(" heroid:", heroId, "type", self:_GetFleetType(), "state:", Data.equipData:GetEquipState(self.m_equipId, self:_GetFleetType()))
  local args = {
    HeroId = heroId,
    EquipId = self.m_equipId,
    EquipType = self:_GetFleetType()
  }
  Service.heroService:_SendEquipBinding(args)
  self:CloseClick()
end

function ShowEquipPage:_CreateCurrency()
  self.priceItem = {}
  UIHelper.CreateSubPart(self.tab_Widgets.obj_priceItem, self.tab_Widgets.trans_price, #self.selectCurrTab, function(nIndex, tabPart)
    local currencyInfo = self.selectCurrTab[nIndex]
    local currType = currencyInfo[1]
    local currencyId = currencyInfo[2]
    local selectPrice = self.priceIndex == -1 and nIndex or self.priceIndex + 1
    local pIndex = #self.customParam.goodData.price[selectPrice] < self.customParam.goodsSerData.Num + 1 and #self.customParam.goodData.price[selectPrice] or self.customParam.goodsSerData.Num + 1
    local price = self.customParam.goodData.price[selectPrice][pIndex]
    local icon = Logic.goodsLogic:GetSmallIcon(currencyId, currType)
    UIHelper.SetImage(tabPart.im_currIcon, tostring(icon), true)
    tabPart.txt_price.text = price
    if self.customParam.goodData.cur_relation == 2 then
      tabPart.tog_payway.gameObject:SetActive(true)
      self.tab_Widgets.tog_group:RegisterToggle(tabPart.tog_payway)
    end
    table.insert(self.priceItem, tabPart)
  end)
  if self.customParam.goodData.cur_relation == 2 then
    UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
    self.tab_Widgets.tog_group:SetActiveToggleIndex(0)
  end
end

function ShowEquipPage:sureUnBinding()
  if not self:_CanUnBind() then
    return
  end
  local equipInfo = Logic.equipLogic:GetEquipById(self.m_equipId)
  local equipCfg = configManager.GetDataById("config_equip", equipInfo.TemplateId)
  local equipLevelBreakConf = {}
  if equipCfg.quality ~= ItemQuality.UR then
    equipLevelBreakConf = configManager.GetDataById("config_equip_levelbreak_item", LvBreakType.Normal)
  else
    equipLevelBreakConf = configManager.GetDataById("config_equip_levelbreak_item", LvBreakType.UR)
  end
  local toolID = equipLevelBreakConf.unlock_item[1]
  local toolNum = equipLevelBreakConf.unlock_item[2]
  local isTool = toolNum <= Data.bagData:GetItemNum(toolID)
  if not isTool then
    noticeManager:ShowTipById(6100008)
    return
  end
  local heroId = Data.equipData:GetEquipHero(self.m_equipId, self:_GetFleetType())
  local args = {
    HeroId = heroId,
    EquipId = self.m_equipId,
    EquipType = self:_GetFleetType()
  }
  Service.heroService:_SendEquipUnBinding(args)
end

function ShowEquipPage:_UnBinding()
  local equip = Logic.equipLogic:GetEquipById(self.m_equipId)
  local param = {equipInfo = equip, showEquipPage = self}
  self:OpenSubPage("EquipBindReturnPage", param)
end

function ShowEquipPage:_CanBind()
  local heroId = Data.equipData:GetEquipHero(self.m_equipId, self:_GetFleetType())
  local lock = Data.equipData:GetEquipState(self.m_equipId, self:_GetFleetType()) == MEquipState.LOCK
  if heroId == 0 then
    logWarning("\230\173\164\232\163\133\229\164\135\230\178\161\230\156\137\229\156\168\232\139\177\233\155\132\228\184\138")
    return false
  elseif lock then
    logWarning("\230\173\164\232\163\157\229\130\153\229\183\178\231\187\145\229\174\154")
    return false
  end
  if self.shipEquipInfo.enhance_level_max ~= self.m_equipMaxLv then
    logWarning("\230\173\164\232\163\157\229\130\153\228\184\141\230\152\175\230\148\175\230\140\129\231\187\145\229\174\154\231\154\132\231\177\187\229\158\139")
    return false
  end
  local equip = Logic.equipLogic:GetEquipById(self.m_equipId)
  if equip.EnhanceLv ~= self.m_equipMaxLv then
    return false
  end
  if self:_GetFleetType() ~= FleetType.Normal then
    return false
  end
  return true
end

function ShowEquipPage:_CanUnBind()
  local heroId = Data.equipData:GetEquipHero(self.m_equipId, self:_GetFleetType())
  local lock = Data.equipData:GetEquipState(self.m_equipId, self:_GetFleetType()) == MEquipState.LOCK
  if heroId == 0 or not lock then
    return false
  end
  if self.shipEquipInfo.enhance_level_max ~= self.m_equipMaxLv then
    return false
  end
  if self:_GetFleetType() ~= FleetType.Normal then
    return false
  end
  return true
end

function ShowEquipPage:ShowEquipRetireReward()
  local rewards = Data.heroData:GetEquipRetireReward()
  if 0 < #rewards then
    Logic.rewardLogic:ShowCommonReward(rewards, "ShowEquipPage")
  end
end

function ShowEquipPage:_SwitchTogs(index)
  if self.priceIndex ~= -1 then
    self.totalBuyNum = 1
    self.tab_Widgets.txt_buyNum.text = self.totalBuyNum
    local price = Logic.shopLogic:GetPriceByNum(self.customParam.goodData.price[self.priceIndex + 1], self.customParam.goodsSerData.Num, self.totalBuyNum)
    self.priceItem[self.priceIndex + 1].txt_price.text = price
  end
  self.priceIndex = index
  self.selectCurrTab = {
    self.customParam.goodData.currency[index + 1]
  }
end

function ShowEquipPage:_SetAllPrice()
  for i, v in ipairs(self.selectCurrTab) do
    if self.priceItem[i] ~= nil then
      local priceTab = self.priceIndex ~= -1 and self.customParam.goodData.price[self.priceIndex + 1] or self.customParam.goodData.price[i]
      local price = Logic.shopLogic:GetPriceByNum(priceTab, self.customParam.goodsSerData.Num, self.totalBuyNum)
      v[3] = price
      local selectPrice = self.priceIndex == -1 and i or self.priceIndex + 1
      self.priceItem[selectPrice].txt_price.text = price
    end
  end
end

function ShowEquipPage:_OnIconClicked()
  local checkId = configManager.GetDataById("config_parameter", 349).arrValue[2]
  local curEquipId = self.m_tid
  if curEquipId == checkId then
    Logic.activityLogic:CumuRechargeClickCount(checkId)
  end
end

function ShowEquipPage:DoOnHide()
end

function ShowEquipPage:DoOnClose()
end

return ShowEquipPage
