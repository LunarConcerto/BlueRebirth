local SelectRandTreasurePage = class("UI.Bag.SelectRandTreasurePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local qualityImage = {
  "",
  "",
  "uipic_ui_treasure_fo_sr",
  "uipic_ui_treasure_fo_ssr"
}
local qualityColour = {
  "#cae0e4",
  "#33d6f3",
  "#dd7dff",
  "#fffd3c"
}
local DefultShowPos = 1

function SelectRandTreasurePage:DoInit()
  self.m_tabWidgets = nil
  self.shipName = nil
  self.pos = 1
  self.lastPart = nil
  self.equipName = nil
  self.equipId = nil
  self.itemName = nil
  self.fashionShipName = nil
  self.fashionName = nil
  self.openNum = nil
  self.itemInfo = nil
  self.selectFashionId = 0
  self.tab_Widgets.obj_bg:SetActive(false)
  self.tab_Widgets.obj_equipBg:SetActive(false)
  self.tab_Widgets.obj_itemBg:SetActive(false)
end

function SelectRandTreasurePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_receive, function()
    self:_ClickSureFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_recEquip, function()
    self:_ClickEquipSure()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_recItem, function()
    self:_ClickItemSure()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_fashionReceive, function()
    self:_ClickFashionSure()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickCloseFun, self)
  self:RegisterEvent(LuaEvent.GetTreasureInfo, self._GetTreasureInfo, self)
  self:RegisterEvent(LuaEvent.UpdateSelectRand, self._UpdatePage, self)
end

function SelectRandTreasurePage:DoOnOpen()
  local params = self:GetParam()
  self.itemInfo = params[1]
  self.openNum = params[2]
  self:_UpdatePage()
end

function SelectRandTreasurePage:_UpdatePage()
  local useInfo
  if Logic.bagLogic:IsRandSelectItem(self.itemInfo.id) then
    useInfo = Logic.bagLogic:GetRandSelectItemUseInfo(self.itemInfo.id)
    if useInfo == nil or next(useInfo) == nil then
      if UIPageManager:GetPageFromHistory("ItemInfoPage") == nil then
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.ITEM_SELECTED, self.itemInfo.id))
      end
      self.tab_Widgets.obj_close:SetActive(false)
      return
    end
  else
    useInfo = Logic.bagLogic:GetSelectBoxItem(self.itemInfo.id)
  end
  if self.itemInfo.type == SelectRandItem.RandShip then
    self:DisplayShipInfo(useInfo)
  elseif self.itemInfo.type == SelectRandItem.RandEquip then
    self:DisplayEquipInfo(useInfo)
  elseif self.itemInfo.type == SelectRandItem.RandItem then
    self:DisplayItemInfo(useInfo)
  elseif self.itemInfo.type == SelectRandItem.RandFashion then
    self:DisplayFashionInfo(useInfo)
  end
  self.tab_Widgets.obj_close:SetActive(true)
end

function SelectRandTreasurePage:DisplayEquipInfo(useInfo)
  self.tab_Widgets.obj_equipBg:SetActive(true)
  UIHelper.SetImage(self.tab_Widgets.img_equipBg, self.itemInfo.bg)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_equipItem, self.tab_Widgets.trans_equip, #useInfo, function(nIndex, tabPart)
    local equipTid = useInfo[nIndex].ConfigId
    local equipInfo = Logic.equipLogic:GetEquipConfigById(equipTid)
    tabPart.obj_select:SetActive(false)
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[equipInfo.quality])
    UIHelper.SetImage(tabPart.img_icon, equipInfo.icon)
    UIHelper.SetImage(tabPart.im_choose, SelectImg[equipInfo.quality])
    UIHelper.SetImage(tabPart.im_qualityDi, QualityBgDi[equipInfo.quality])
    tabPart.txt_name.text = equipInfo.name
    UGUIEventListener.AddButtonOnClick(tabPart.btn_select, function()
      self:_SelectEquip(equipTid, equipInfo, nIndex, tabPart)
    end)
    if nIndex == self.pos then
      self:_SelectEquip(equipTid, equipInfo, nIndex, tabPart)
    end
  end)
end

function SelectRandTreasurePage:DisplayItemInfo(useInfo)
  self.tab_Widgets.obj_itemBg:SetActive(true)
  UIHelper.SetImage(self.tab_Widgets.img_itemBg, self.itemInfo.bg)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_item, #useInfo, function(nIndex, tabPart)
    local itemId = useInfo[nIndex].ConfigId
    local itemNum = useInfo[nIndex].Num
    local itemType = useInfo[nIndex].Type
    local itemInfo = Logic.bagLogic:GetItemByTempateId(itemType, itemId)
    tabPart.obj_select:SetActive(false)
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetImage(tabPart.img_icon, itemInfo.icon)
    UIHelper.SetImage(tabPart.im_choose, SelectImg[itemInfo.quality])
    UIHelper.SetImage(tabPart.im_qualityDi, QualityBgDi[itemInfo.quality])
    tabPart.txt_name.text = itemInfo.name
    tabPart.txt_num.text = "x" .. itemNum
    UGUIEventListener.AddButtonOnClick(tabPart.btn_select, function()
      self:_SelectItem(itemId, itemInfo, nIndex, tabPart)
    end)
    if nIndex == self.pos then
      self:_SelectItem(itemId, itemInfo, nIndex, tabPart)
    end
  end)
end

function SelectRandTreasurePage:_SelectEquip(equipTid, equipInfo, nIndex, tabPart)
  if self.lastPart ~= nil then
    self.lastPart.obj_select:SetActive(false)
    tabPart.obj_select:SetActive(true)
  else
    tabPart.obj_select:SetActive(true)
  end
  self.lastPart = tabPart
  UIHelper.SetImage(self.tab_Widgets.img_quality, QualityIcon[equipInfo.quality])
  UIHelper.SetImage(self.tab_Widgets.img_equip, equipInfo.icon)
  UIHelper.SetImage(self.tab_Widgets.im_equipGetBg, QualityGetBgDi[equipInfo.quality])
  local equipTypeId = Logic.equipLogic:GetEquipType(equipTid)
  local wearType = configManager.GetDataById("config_equip_wear_type", equipTypeId)
  self.tab_Widgets.txt_equipType.text = wearType.equip_show_name
  local nameStr = Logic.shipLogic:GetShipTypeName(equipInfo.equip_ship)
  self.tab_Widgets.txt_shipType.text = nameStr
  self.tab_Widgets.txt_equipName.text = equipInfo.name
  self.equipName = equipInfo.name
  self.equipId = equipTid
  self.pos = nIndex
  local equipAttr = Logic.equipLogic:GetCurEquipFinaAttrByLv(equipTid)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_attrItem, self.tab_Widgets.trans_attr, #equipAttr, function(index, tabPart)
    local temp = equipAttr[index]
    UIHelper.SetText(tabPart.txt_name, temp.name)
    UIHelper.SetText(tabPart.txt_value, temp.value)
    UIHelper.SetImage(tabPart.img_tag, temp.icon)
  end)
  self:_ShowEquipPSkill(equipTid)
end

function SelectRandTreasurePage:_SelectItem(itemid, itemInfo, nIndex, tabPart)
  if self.lastPart ~= nil then
    self.lastPart.obj_select:SetActive(false)
    tabPart.obj_select:SetActive(true)
  else
    tabPart.obj_select:SetActive(true)
  end
  self.lastPart = tabPart
  self.itemName = itemInfo.name
  UIHelper.SetImage(self.tab_Widgets.img_itemQuality, QualityIcon[itemInfo.quality])
  UIHelper.SetImage(self.tab_Widgets.img_itemIcon, itemInfo.icon)
  UIHelper.SetImage(self.tab_Widgets.im_itemGetBg, QualityGetBgDi[itemInfo.quality])
  self.tab_Widgets.txt_itemDes.text = itemInfo.desc
  self.tab_Widgets.txt_itemName.text = itemInfo.name
  self.pos = nIndex
end

function SelectRandTreasurePage:_ShowEquipPSkill(equipId)
  local common = Logic.equipLogic:IsCommonRiseEquip(equipId)
  local equipPskills = Logic.equipLogic:GetEquipRisePSkillById(equipId)
  local widgets = self:GetWidgets()
  widgets.obj_pskilllist:SetActive(0 < #equipPskills)
  if 0 < #equipPskills then
    UIHelper.CreateSubPart(widgets.obj_pskill, widgets.trans_pskill, #equipPskills, function(index, tabParts)
      local pskillId = equipPskills[index]
      local name = Logic.shipLogic:GetPSkillName(pskillId)
      local ok, info = Logic.equipLogic:CheckPSkillOpen(nil, pskillId)
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
  end
end

function SelectRandTreasurePage:DisplayShipInfo(useInfo)
  self.tab_Widgets.obj_bg:SetActive(true)
  self.tab_Widgets.trans_girl.gameObject:SetActive(true)
  UIHelper.SetImage(self.tab_Widgets.img_bg, self.itemInfo.bg)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_girl, self.tab_Widgets.trans_girl, #useInfo, function(nIndex, tabPart)
    local shipTid = useInfo[nIndex].ConfigId
    local girlInfo = Logic.shipLogic:GetShipShowById(shipTid)
    tabPart.obj_select:SetActive(false)
    tabPart.rect_card.anchoredPosition = Vector2.New(0, 0)
    UIHelper.SetImage(tabPart.img_girl, girlInfo.ship_icon_bathroom)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_select, function()
      self:_SelectGirl(shipTid, girlInfo, nIndex, tabPart)
    end)
    if nIndex == self.pos then
      self:_SelectGirl(shipTid, girlInfo, nIndex, tabPart)
    end
  end)
end

function SelectRandTreasurePage:_SelectGirl(shipTid, girlInfo, nIndex, tabPart)
  if self.lastPart ~= nil then
    self.lastPart.obj_select:SetActive(false)
    self.lastPart.rect_card.anchoredPosition = Vector2.New(0, 0)
    tabPart.obj_select:SetActive(true)
    tabPart.rect_card.anchoredPosition = Vector2.New(30, 0)
  else
    tabPart.obj_select:SetActive(true)
    tabPart.rect_card.anchoredPosition = Vector2.New(30, 0)
  end
  self.lastPart = tabPart
  local shipInfo = Logic.shipLogic:GetShipInfoById(shipTid)
  self.tab_Widgets.txt_name.text = shipInfo.ship_name
  local typeIcon = Logic.shipLogic:GetShipTypeIcon(shipInfo.ship_type)
  UIHelper.SetImage(self.tab_Widgets.img_type, typeIcon)
  UIHelper.SetImage(self.tab_Widgets.img_shipQuality, qualityImage[shipInfo.quality], true)
  local skillTab = Logic.shipLogic:GetAllPSkillArrbyShipMainId(shipTid)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_skillItem, self.tab_Widgets.trans_skill, #skillTab, function(skillIndex, skillPart)
    local skillName = Logic.shipLogic:GetPSkillName(skillTab[skillIndex])
    local skillIcon = Logic.shipLogic:GetPSkillIcon(skillTab[skillIndex], shipTid)
    skillPart.txt_name.text = skillName
    UIHelper.SetImage(skillPart.img_icon, skillIcon)
    UGUIEventListener.AddButtonOnClick(skillPart.btn_click, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenMaxPSkillData(skillTab[skillIndex], shipTid))
    end)
  end)
  local position = configManager.GetDataById("config_ship_position", girlInfo.ss_id)
  local grilTrans = self.tab_Widgets.img_girl.transform
  grilTrans.localPosition = Vector3.New(position.item_selected_position[1], position.item_selected_position[2], 0)
  local scaleSize = position.item_selected_scale / 10000
  local mirror = position.item_selected_inversion
  local scale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  grilTrans.localScale = scale
  UIHelper.SetImage(self.tab_Widgets.img_girl, girlInfo.ship_draw)
  self.shipName = shipInfo.ship_name
  self.pos = nIndex
end

function SelectRandTreasurePage:DisplayFashionInfo(useInfo)
  self.tab_Widgets.obj_fashionBg:SetActive(true)
  self.tab_Widgets.trans_fashion.gameObject:SetActive(true)
  UIHelper.SetImage(self.tab_Widgets.img_fashionBg, self.itemInfo.bg)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_fashionItem, self.tab_Widgets.trans_fashion, #useInfo, function(nIndex, tabPart)
    local shipSid = useInfo[nIndex].ConfigId
    local girlInfo = configManager.GetDataById("config_ship_show", shipSid)
    tabPart.obj_select:SetActive(false)
    tabPart.rect_card.anchoredPosition = Vector2.New(0, 0)
    UIHelper.SetImage(tabPart.img_girl, girlInfo.ship_icon_bathroom)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_select, function()
      self:_SelectFashion(shipSid, girlInfo, nIndex, tabPart)
    end)
    if nIndex == self.pos then
      self:_SelectFashion(shipSid, girlInfo, nIndex, tabPart)
    end
  end)
end

function SelectRandTreasurePage:_SelectFashion(shipSid, girlInfo, nIndex, tabPart)
  if self.lastPart ~= nil then
    self.lastPart.obj_select:SetActive(false)
    self.lastPart.rect_card.anchoredPosition = Vector2.New(0, 0)
    tabPart.obj_select:SetActive(true)
    tabPart.rect_card.anchoredPosition = Vector2.New(30, 0)
  else
    tabPart.obj_select:SetActive(true)
    tabPart.rect_card.anchoredPosition = Vector2.New(30, 0)
  end
  self.lastPart = tabPart
  local girlFashionInfo = configManager.GetDataById("config_fashion", shipSid)
  local colour = qualityColour[girlInfo.quality]
  local colourName = "<color=" .. colour .. ">" .. girlFashionInfo.name .. ":</color>"
  UIHelper.SetText(self.tab_Widgets.txt_fashionName, colourName)
  UIHelper.SetText(self.tab_Widgets.txt_fashionDesc, girlFashionInfo.description)
  self.tab_Widgets.txt_fashionShipName.text = girlInfo.ship_name
  local typeIcon = Logic.shipLogic:GetShipTypeIcon(girlInfo.ship_type)
  UIHelper.SetImage(self.tab_Widgets.img_fashionType, typeIcon)
  UIHelper.SetImage(self.tab_Widgets.img_fashionQuality, qualityImage[girlInfo.quality], true)
  local position = configManager.GetDataById("config_ship_position", girlInfo.ss_id)
  local grilTrans = self.tab_Widgets.img_fashiongirl.transform
  grilTrans.localPosition = Vector3.New(position.item_selected_position[1], position.item_selected_position[2], 0)
  local scaleSize = position.item_selected_scale / 10000
  local mirror = position.item_selected_inversion
  local scale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  grilTrans.localScale = scale
  UIHelper.SetImage(self.tab_Widgets.img_fashiongirl, girlInfo.ship_draw)
  self.fashionShipName = girlInfo.ship_name
  self.fashionName = girlFashionInfo.name
  self.pos = nIndex
  self.selectFashionId = shipSid
end

function SelectRandTreasurePage:_GetTreasureInfo(serverRet)
  local useInfo = Logic.bagLogic:GetRandSelectItemUseInfo(serverRet.treasureId)
  if useInfo == nil then
    Logic.rewardLogic:ShowCommonReward(serverRet.treasuresInfo, "SelectRandTreasurePage", function()
      Logic.bagLogic:_UpdateSelectRand()
    end)
    local bagInfo = Logic.bagLogic:ItemInfoById(self.itemInfo.id)
    local value = bagInfo == nil and 0 or bagInfo.num
    if value == 0 then
      if UIPageManager:IsExistPage("SelectRandTreasurePage") then
        UIHelper.ClosePage("SelectRandTreasurePage")
      end
      return
    end
    self:_ResetPage()
  else
    if self.itemInfo.type == SelectRandItem.RandShip then
      self:DisplayShipInfo(useInfo)
    elseif self.itemInfo.type == SelectRandItem.RandEquip then
      self:DisplayEquipInfo(useInfo)
    elseif self.itemInfo.type == SelectRandItem.RandItem then
      self:DisplayItemInfo(useInfo)
    elseif self.itemInfo.type == SelectRandItem.RandFashion then
      self:DisplayFashionInfo(useInfo)
    end
    self.tab_Widgets.obj_close:SetActive(true)
  end
end

function SelectRandTreasurePage:_ClickSure()
  Service.bagService:SendGetSelectTreasureItem(self.itemInfo.id, self.pos, self.openNum)
  if not Logic.bagLogic:IsRandSelectItem(self.itemInfo.id) then
    UIHelper.ClosePage("SelectRandTreasurePage")
  end
  if self.itemInfo.type == SelectRandItem.RandEquip then
    local dotinfo = {
      info = "treasure_get",
      equip_id = tostring(self.equipId)
    }
    RetentionHelper.Retention(PlatformDotType.equipGetLog, dotinfo)
  end
end

function SelectRandTreasurePage:_ResetPage()
  self.shipName = nil
  self.pos = 1
  self.lastPart = nil
  self.equipName = nil
  self.equipId = nil
  self.fashionShipName = nil
  self.fashionName = nil
  self.tab_Widgets.obj_bg:SetActive(false)
  self.tab_Widgets.obj_equipBg:SetActive(false)
  self.tab_Widgets.obj_itemBg:SetActive(false)
  self.tab_Widgets.obj_close:SetActive(false)
end

function SelectRandTreasurePage:_ClickCloseFun()
  UIHelper.ClosePage("SelectRandTreasurePage")
end

function SelectRandTreasurePage:_ClickSureFun()
  local canOpen = Logic.rewardLogic:CanGotShip(1)
  if not canOpen then
    return
  end
  self:ShowTips(450001, self.shipName)
end

function SelectRandTreasurePage:_ClickEquipSure()
  local canOpen = Logic.rewardLogic:CanGotEquip(1)
  if not canOpen then
    return
  end
  self:ShowTips(450002, self.equipName)
end

function SelectRandTreasurePage:_ClickItemSure()
  self:ShowTips(450003, self.itemName)
end

function SelectRandTreasurePage:ShowTips(languageId, content)
  local str = string.format(UIHelper.GetString(languageId), content)
  local param = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        self:_ClickSure()
      end
    end
  }
  noticeManager:ShowMsgBox(str, param)
end

function SelectRandTreasurePage:_ClickFashionSure()
  local str = string.format(UIHelper.GetString(450004), self.fashionShipName, self.fashionName)
  local param = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        self:_CheckFashionOwned()
      end
    end
  }
  noticeManager:ShowMsgBox(str, param)
end

function SelectRandTreasurePage:_CheckFashionOwned()
  local useInfo = Logic.bagLogic:GetRandSelectItemUseInfo(self.itemInfo.id)
  local shipSid = 0
  if userInfo ~= nil then
    shipSid = useInfo[self.pos].ConfigId
  else
    shipSid = self.selectFashionId
  end
  local isHave = Logic.fashionLogic:CheckFashionOwn(shipSid)
  if isHave then
    local str = UIHelper.GetString(450005)
    local param = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClickSure()
        end
      end
    }
    noticeManager:ShowMsgBox(str, param)
  else
    self:_ClickSure()
  end
end

function SelectRandTreasurePage:DoOnHide()
end

function SelectRandTreasurePage:DoOnClose()
end

return SelectRandTreasurePage
