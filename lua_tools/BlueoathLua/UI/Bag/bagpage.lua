local BagPage = class("UI.Bag.BagPage", LuaUIPage)
local equipItem = require("ui.page.Bag.BagEquipItem")
local equipAttrItem = require("ui.page.Bag.BagEquipAttItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local BagItem = {BAG_MATREIAL_ITEM = 0, BAG_EQUIP_ITEM = 1}
local ITEM_ID_BEGIN = 10000
local ONE_DAY_SEC = 86400

function BagPage:DoInit()
  self.m_tabWidgets = nil
  self.m_curSelectTog = 0
  self.m_localRecord = nil
  self.m_equipsInfo = nil
  self.m_heroEquipInfo = nil
  self.m_openParam = nil
  self.m_itemInfo = nil
  self.m_decorateItemInfo = {}
  self.m_fenGeEquip = {}
  self.m_fenGeNomal = {}
  self.m_fenGeAtt = {}
  self.m_fenGeDecorate = {}
  self.m_selectEquip = nil
  self.m_fleetType = FleetType.Normal
  self.m_equipType = nil
  self.m_equipHeroId = nil
  self.m_timer = nil
  self.specialItemInfo = {}
  self.tabTemp = {}
  self.startIndex = 0
  self.endIndex = 0
  self:_InitParam()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.tabTags = {
    {
      self.m_tabWidgets.tween_material,
      self.m_tabWidgets.obj_materialLine
    },
    {
      self.m_tabWidgets.tween_equip,
      self.m_tabWidgets.obj_equipLine
    },
    {
      self.m_tabWidgets.tween_decorate,
      self.m_tabWidgets.obj_decorateLine
    }
  }
end

function BagPage:_InitParam()
  self.m_equipToBagSign = nil
  self.m_maxSelectNum = 0
  self.m_selectNum = 0
  self.m_selectItem = {}
  self.m_selectEquipInfo = {}
  self.m_bagType = nil
end

function BagPage:RegisterAllEvent()
  self.m_tabWidgets.tog_group:ClearToggles()
  self:RegisterEvent(LuaEvent.UpdateBagEquip, self._UpdateBagEquip, self)
  self:RegisterEvent(LuaEvent.UpdateEquipMsg, self._UpdatePage, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self._UpdateBagItem, self)
  self:RegisterEvent("changeHeroEquip", self._UpdateBagEquip, self)
  self:RegisterEvent(LuaEvent.EquipRiseStarSuccess, self._UpdateBagEquip, self)
  self:RegisterEvent(LuaEvent.RefreshAllInteractionItem, self._UpdatePage, self)
  self:RegisterEvent(LuaEvent.ACShop_GetToy, function(handler, param)
    self:__OpenEffect(param)
  end)
  self:RegisterEvent(LuaEvent.CloseDecorationBag, self._UpdatePage, self)
  self.tabTogs = {
    self.m_tabWidgets.tog_material,
    self.m_tabWidgets.tog_equip,
    self.m_tabWidgets.tog_decorate
  }
  for i, tog in ipairs(self.tabTogs) do
    self.m_tabWidgets.tog_group:RegisterToggle(tog)
  end
  self.m_tabWidgets.tog_group:RemoveToggleUnActive(0)
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_group, self, "", self._SwitchTogs)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_sort, self._OpenSort, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_screen, self._OpenSort, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_help, self._OpenHelp, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, self._RiseCancel, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_sure, self._RiseSure, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_order, self._SortOrder, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_uninstall, self._ShowUnintall, self)
end

function BagPage:_ShowUnintall()
  UIHelper.OpenPage("DismantlePage")
end

function BagPage._stopToggle()
end

function BagPage:DoOnOpen()
  self:OpenTopPage("BagPage", 1, "\228\187\147\229\186\147", self, true)
  self.m_localRecord = Logic.bagLogic:GetSortRecord()
  self.m_openParam = self:GetParam()
  if type(self.m_openParam) == "table" then
    self.m_bagType = self.m_openParam[1]
    self.m_equipToBagSign = self.m_openParam[2]
    self:_SetFleetType(self.m_openParam.FleetType)
  end
  if self.m_openParam ~= nil and self.m_equipToBagSign == EquipToBagSign.CHANGE_EQUIP then
    self.m_equipHeroId = self.m_openParam[4]
    self.m_equipType = self.m_openParam[6]
    self.m_selectEquip = self.m_openParam[3]
    self.m_localRecord = Logic.bagLogic:GetSelectEquipRecord()
  end
  self:_GetBagEquipInfo()
  self.m_itemInfo = Logic.bagLogic:DisposeItem()
  self.m_decorateItemInfo = Logic.interactionItemLogic:GetDecorateBagOther()
  self:_ShowSortWay()
  if self.m_bagType == BagType.EQUIP_BAG then
    self:_SetEquipToggle()
  else
    local curToggle = Logic.bagLogic:GetCurToggle()
    self.m_tabWidgets.tog_group:SetActiveToggleIndex(curToggle)
  end
  local dotInfo = {info = "ui_depot"}
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

function BagPage:_SetEquipToggle()
  self.m_tabWidgets.tog_group:SetActiveToggleIndex(BagItem.BAG_EQUIP_ITEM)
  self.m_tabWidgets.tog_group:ResigterToggleUnActive(0, self._stopToggle)
  self.m_tabWidgets.tog_group:ResigterToggleUnActive(2, self._stopToggle)
end

function BagPage:_GetBagEquipInfo()
  local equipBagInfo = Data.equipData:GetEquipData()
  local equipTab = Logic.equipLogic:GetEquipConfig(equipBagInfo, self.m_equipType, self.m_equipHeroId, self:_GetFleetType())
  self.m_heroEquipInfo, self.m_equipsInfo = Logic.equipLogic:EquipBagOverlay(equipTab, self:_GetFleetType())
  local size = Logic.equipLogic:GetEquipOccupySize()
  local equipSize = Data.equipData:GetEquipBagSize()
  if size >= equipSize then
    self.m_tabWidgets.txt_capacity.text = string.format("<color=#D54852>%d</color>/<color=#47ACAC>%d</color>", size, equipSize)
  else
    self.m_tabWidgets.txt_capacity.text = string.format("<color=#ffffff>%d</color>/<color=#677c99>%d</color>", size, equipSize)
  end
end

function BagPage:_UpdatePage()
  local curToggle = Logic.bagLogic:GetCurToggle()
  self.m_itemInfo = Logic.bagLogic:DisposeItem()
  if curToggle == 0 then
    self:_LoadNomalItem()
  elseif curToggle == 2 then
    self:_LoadDecorateItem()
  else
    self:_GetBagEquipInfo()
  end
end

function BagPage:_UpdateBagItem()
  self:_DestroyNoamlPop()
  self:_UpdatePage()
end

function BagPage:_UpdateBagEquip()
  self:_DestroyEquipPop()
  self:_DestroyAttPop()
  self.m_localRecord = Logic.bagLogic:GetSortRecord()
  if self.m_openParam ~= nil and self.m_equipToBagSign == EquipToBagSign.CHANGE_EQUIP then
    self.m_localRecord = Logic.bagLogic:GetSelectEquipRecord()
  end
  local totalEquip = self:_ShowHeroEquip()
  local screenType = Logic.equipLogic:GetEquipTypeConfig()
  local screen = screenType[self.m_localRecord.Screen + 1].ewt_id
  local equipOrder = Logic.bagLogic:EquipScreenAndSort(totalEquip, screen, self.m_localRecord.Sort + 1, self.m_localRecord.Order == 0)
  if self.m_localRecord.AttrEquip == 1 then
    self:_LoadAttItem(equipOrder)
    self.m_tabWidgets.obj_equipMiddle:SetActive(false)
    self.m_tabWidgets.obj_attMiddle:SetActive(true)
  else
    self:_LoadEquipItem(equipOrder)
    self.m_tabWidgets.obj_equipMiddle:SetActive(true)
    self.m_tabWidgets.obj_attMiddle:SetActive(false)
  end
  self:_ShowSortWay()
end

function BagPage:_SwitchTogs(index)
  for k, v in pairs(self.tabTags) do
    local objTab = self.tabTags[k]
    if k == index + 1 then
      objTab[1]:Play(true)
      objTab[2]:SetActive(true)
    else
      objTab[1]:Play(false)
      objTab[2]:SetActive(false)
    end
  end
  self.m_curSelectTog = index
  if index == 0 then
    self:_ShowOtherPage(BagType.ITEM_BAG)
    self:_LoadNomalItem()
  elseif index == 2 then
    self:_ShowOtherPage(BagType.DECORATE_BAG)
    self:_LoadDecorateItem()
  else
    self:_ShowOtherPage(BagType.EQUIP_BAG)
    self:_GetBagEquipInfo()
    self:_UpdateBagEquip()
  end
  Logic.bagLogic:SetCurToggle(self.m_curSelectTog)
end

function BagPage:_ShowEquipPage(enabled)
  self.m_tabWidgets.obj_rise:SetActive(false)
  self.m_tabWidgets.obj_equipButtom:SetActive(enabled)
  self.m_tabWidgets.obj_equipMiddle:SetActive(enabled)
  self.m_tabWidgets.obj_attMiddle:SetActive(enable)
  self.m_tabWidgets.obj_materialBut:SetActive(not enabled)
  self.m_tabWidgets.obj_middle:SetActive(not enabled)
  self.m_tabWidgets.decorateAllMiddle:SetActive(not enabled)
end

function BagPage:_ShowOtherPage(Type)
  self.m_tabWidgets.obj_rise:SetActive(false)
  self.m_tabWidgets.obj_equipButtom:SetActive(Type == BagType.EQUIP_BAG)
  self.m_tabWidgets.obj_equipMiddle:SetActive(Type == BagType.EQUIP_BAG)
  self.m_tabWidgets.obj_attMiddle:SetActive(enable)
  self.m_tabWidgets.obj_materialBut:SetActive(Type == BagType.ITEM_BAG or Type == BagType.DECORATE_BAG)
  self.m_tabWidgets.obj_middle:SetActive(Type == BagType.ITEM_BAG)
  self.m_tabWidgets.decorateAllMiddle:SetActive(Type == BagType.DECORATE_BAG)
end

function BagPage:_ShowHeroEquip()
  local total = {}
  if self.m_localRecord.UseEquip == 1 then
    for i, v in pairs(self.m_heroEquipInfo) do
      table.insert(total, v)
    end
    for i, v in ipairs(self.m_equipsInfo) do
      table.insert(total, v)
    end
  else
    total = self.m_equipsInfo
  end
  return total
end

function BagPage:_LoadNomalItem()
  self.specialItemInfo = {}
  self.tabTemp = {}
  self:CreateCountDown()
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_normalItem, self.m_tabWidgets.obj_normalItem, #self.m_itemInfo, function(tabParts, startIndex, endIndex)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
      self.tabTemp[tonumber(k)] = v
    end
    self.startIndex = startIndex
    self.endIndex = endIndex
    for nIndex, tabPart in pairs(tabTemp) do
      local info = self.m_itemInfo[nIndex]
      local itemIndex = math.floor(info.id / ITEM_ID_BEGIN)
      tabPart.txt_goodsName.text = info.name
      tabPart.txt_value.text = "x" .. math.tointeger(info.num)
      tabPart.obj_ringEff:SetActive(info.id == 10180)
      tabPart.obj_piece:SetActive(itemIndex == GoodsType.Fragment)
      tabPart.obj_im_valentineGift:SetActive(itemIndex == GoodsType.VALENTINE_GIFT)
      if info.icon ~= nil then
        UIHelper.SetImage(tabPart.img_goods, tostring(info.icon))
      end
      tabPart.obj_redDot:SetActive(false)
      tabPart.obj_time:SetActive(info.createTime)
      if info.createTime then
        local duration = Logic.bagLogic:GetPeriodItemTime(info.time_duration, info.createTime)
        tabPart.obj_redDot:SetActive(duration < ONE_DAY_SEC)
        tabPart.tx_time.text = Logic.bagLogic:GetPeriodCountDown(duration)
        self.specialItemInfo[nIndex] = info
      end
      UIHelper.SetImage(tabPart.img_quality, QualityIcon[info.quality])
      UGUIEventListener.AddButtonOnClick(tabPart.btn_goods, function()
        self:_ItemDetail(info)
      end)
    end
  end)
  local num = math.ceil(#self.m_itemInfo / 8)
  if 1 < num then
    self:_LoadFenGeNomal(num)
  end
end

function BagPage:_LoadDecorateItem()
  local furnitureTheme = Logic.interactionItemLogic:GetDecorateBagFurTheme()
  self.m_tabWidgets.im_lineTheme.gameObject:SetActive(#furnitureTheme ~= 0)
  local curTheme = Data.interactionItemData:GetMutexFurnitureTheme()
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_decorateSetItem, self.m_tabWidgets.tran_decorateSetMiddle, #furnitureTheme, function(index, tabPart)
    local info = furnitureTheme[index]
    UIHelper.SetImage(tabPart.img_icon, info.icon)
    UIHelper.SetText(tabPart.tx_name, info.name)
    tabPart.im_isOn.Gray = info.id ~= curTheme
    UGUIEventListener.AddButtonOnClick(tabPart.btn_Info, function()
      UIHelper.OpenPage("DecorationSetPage", {
        themeId = info.id
      })
    end)
    tabPart.redDot.gameObject:SetActive(false)
    local haveNew = Logic.interactionItemLogic:GetDecorateThemeNew(info.id)
    tabPart.redDot.gameObject:SetActive(haveNew)
  end)
  self.m_tabWidgets.im_lineOther.gameObject:SetActive(#self.m_decorateItemInfo ~= 0)
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_decorateItem, self.m_tabWidgets.obj_decorateItem, #self.m_decorateItemInfo, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local info = self.m_decorateItemInfo[nIndex]
      tabPart.txt_goodsName.text = info.name
      tabPart.obj_ringEff:SetActive(info.id == 10180)
      tabPart.txt_value.gameObject:SetActive(false)
      if info.icon ~= nil then
        UIHelper.SetImage(tabPart.img_goods, tostring(info.icon))
      end
      UIHelper.SetImage(tabPart.img_quality, QualityIcon[info.quality])
      UGUIEventListener.AddButtonOnClick(tabPart.btn_goods, function()
        self:_ItemDetail(info)
      end)
    end
  end)
  local num = math.ceil(#self.m_decorateItemInfo / 8)
  if 1 < num then
    self:_LoadFenGeDecorate(num)
  end
end

function BagPage:_LoadEquipItem(screenEquipTab)
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_equipItem, self.m_tabWidgets.obj_equipItem, #screenEquipTab, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local item = equipItem:new()
      local equipInfo = screenEquipTab[nIndex]
      item:Init(self, tabPart, equipInfo, nil, nIndex)
    end
  end)
  local num = math.ceil(#screenEquipTab / 8)
  if 1 < num then
    self:_LoadFenGeEquip(num)
  end
end

function BagPage:_LoadAttItem(screenEquipTab)
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_attItem, self.m_tabWidgets.obj_attItem, #screenEquipTab, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local item = equipAttrItem:new()
      local equipInfo = screenEquipTab[nIndex]
      item:Init(self, tabPart, equipInfo, nIndex)
    end
  end)
  local num = math.ceil(#screenEquipTab / 3)
  if 1 < num then
    self:_LoadFenGeAtt(num)
  end
end

function BagPage:_LoadFenGeEquip(num)
  self:_DestroyEquipPop()
  for i = 1, num - 1 do
    local createEquipLine = UIHelper.CreateGameObject(self.tab_Widgets.obj_fenGeEquip, self.tab_Widgets.trans_fenGeEquipItem)
    table.insert(self.m_fenGeEquip, createEquipLine)
    createEquipLine:SetActive(true)
    img_fenGe = createEquipLine.gameObject:GetComponent(UIImage.GetClassType())
    UIHelper.SetImage(img_fenGe, "uipic_ui_store_im_01")
  end
end

function BagPage:_LoadFenGeNomal(num)
  self:_DestroyNoamlPop()
  for i = 1, num - 1 do
    local createNomalLine = UIHelper.CreateGameObject(self.tab_Widgets.obj_fenGe, self.tab_Widgets.trans_fenGeNomalItem)
    table.insert(self.m_fenGeNomal, createNomalLine)
    createNomalLine:SetActive(true)
    img_fenGe = createNomalLine.gameObject:GetComponent(UIImage.GetClassType())
    UIHelper.SetImage(img_fenGe, "uipic_ui_store_im_01")
  end
end

function BagPage:_LoadFenGeDecorate(num)
  self:_DestroyDecoratePop()
  for i = 1, num - 1 do
    local createDecorateLine = UIHelper.CreateGameObject(self.tab_Widgets.obj_fenGeDecorate, self.tab_Widgets.trans_fenGeDecorateItem)
    table.insert(self.m_fenGeDecorate, createDecorateLine)
    createDecorateLine:SetActive(true)
    img_fenGe = createDecorateLine.gameObject:GetComponent(UIImage.GetClassType())
    UIHelper.SetImage(img_fenGe, "uipic_ui_store_im_01")
  end
end

function BagPage:_LoadFenGeAtt(num)
  self:_DestroyAttPop()
  for i = 1, num - 1 do
    local createAttLine = UIHelper.CreateGameObject(self.tab_Widgets.obj_fenGeAttEquip, self.tab_Widgets.trans_fenGeAttItem)
    table.insert(self.m_fenGeAtt, createAttLine)
    createAttLine:SetActive(true)
    img_fenGe = createAttLine.gameObject:GetComponent(UIImage.GetClassType())
    UIHelper.SetImage(img_fenGe, "uipic_ui_store_im_01")
  end
end

function BagPage:_DestroyNoamlPop()
  if self.m_fenGeNomal ~= {} then
    for v, k in pairs(self.m_fenGeNomal) do
      GameObject.Destroy(k)
    end
    self.tab_Widgets.obj_fenGe:SetActive(false)
    self.m_fenGeNomal = {}
  end
end

function BagPage:_DestroyDecoratePop()
  if self.m_fenGeDecorate ~= {} then
    for v, k in pairs(self.m_fenGeDecorate) do
      GameObject.Destroy(k)
    end
    self.tab_Widgets.obj_fenGeDecorate:SetActive(false)
    self.m_fenGeDecorate = {}
  end
end

function BagPage:_DestroyEquipPop()
  if self.m_fenGeEquip ~= {} then
    for v, k in pairs(self.m_fenGeEquip) do
      GameObject.Destroy(k)
    end
    self.tab_Widgets.obj_fenGeEquip:SetActive(false)
    self.m_fenGeEquip = {}
  end
end

function BagPage:_DestroyAttPop()
  if self.m_fenGeAtt ~= {} then
    for v, k in pairs(self.m_fenGeAtt) do
      GameObject.Destroy(k)
    end
    self.tab_Widgets.obj_fenGeEquip:SetActive(false)
    self.m_fenGeAtt = {}
  end
end

function BagPage:_ItemDetail(iteminfo)
  local itemIndex = math.floor(iteminfo.id / ITEM_ID_BEGIN)
  if itemIndex == GoodsType.Fragment then
    UIHelper.OpenPage("PaperPage", iteminfo)
  elseif itemIndex == GoodsType.ITEM and iteminfo.type == 2 then
    UIHelper.OpenPage("SelectTreasurePage", iteminfo)
  elseif itemIndex == GoodsType.ITEM_SELECTED then
    if Logic.bagLogic:IsRandSelectItem(iteminfo.id) then
      UIHelper.OpenPage("SelectRandTreasurePage", {iteminfo})
    else
      UIHelper.OpenPage("SelectTreasurePage", iteminfo)
    end
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(itemIndex, iteminfo.id))
  end
end

function BagPage:ClickEquipDetail(equipId)
  if self.m_bagType == BagType.EQUIP_BAG then
    local can, msg = Logic.equipLogic:CanChange(self.m_equipHeroId, self.m_openParam[6], self.m_selectEquip, self:_GetFleetType())
    if not can then
      noticeManager:ShowMsgBox(msg)
      return
    end
    UIHelper.OpenPage("EquipChangePage", {
      self.m_openParam[3],
      equipId,
      self.m_openParam[4],
      self.m_openParam[5],
      self.m_openParam[2],
      FleetType = self:_GetFleetType()
    })
    self.m_selectEquip = equipId
    return
  end
  UIHelper.OpenPage("ShowEquipPage", {
    equipId = equipId,
    showEquipType = ShowEquipType.InfoBag,
    FleetType = self:_GetFleetType()
  })
  local equipInfoArr = Data.equipData:GetRecordNewEquip()
  if next(equipInfoArr) ~= nil then
    local updateBag = Logic.equipLogic:ShowEquipDetails(equipId)
    if updateBag then
      self:_UpdateBagEquip()
    end
  end
end

function BagPage:_OpenHelp()
  UIHelper.OpenPage("HelpPage", {content = 320001})
end

function BagPage:_OpenSort()
  if self.m_openParam ~= nil and self.m_equipToBagSign == EquipToBagSign.CHANGE_EQUIP then
    UIHelper.OpenPage("BagEquipSortPage", BagSortSign.ForChangeEquip)
  else
    UIHelper.OpenPage("BagEquipSortPage")
  end
end

function BagPage:ClickSelectEquip(isSelect, index, equipInfo)
  local can, msg = Logic.equipLogic:CanDelect(equipInfo.TemplateId)
  if not can then
    noticeManager:ShowTip(msg)
    return
  end
  if isSelect and self.m_selectNum >= self.m_maxSelectNum then
    noticeManager:OpenTipPage(self, string.format("\230\156\128\229\164\154\233\128\137\230\139\169%d\228\184\170\232\163\133\229\164\135", self.m_maxSelectNum))
    return
  end
  local item = self.m_selectItem[index]
  item.tabPart.img_select.enabled = isSelect
  if isSelect then
    self.m_selectNum = self.m_selectNum + 1
    table.insert(self.m_selectEquipInfo, equipInfo)
  else
    self.m_selectNum = self.m_selectNum - 1
    for i = 1, #self.m_selectEquipInfo do
      table.remove(self.m_selectEquipInfo, i)
      break
    end
  end
  self.m_tabWidgets.txt_selectNum.text = string.format("%d/<color=#47ACAC>%d</color>", self.m_selectNum, self.m_maxSelectNum)
end

function BagPage:_RiseCancel()
  self:_InitParam()
  UIHelper.ClosePage("BagPage")
end

function BagPage:_RiseSure()
  for i = 1, #self.m_selectEquipInfo do
    if Logic.equipLogic:IsEquipIntensify(self.m_selectEquipInfo[i].EquipId) then
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            self:_ClickSure()
          end
        end
      }
      noticeManager:ShowMsgBox("\229\183\178\233\128\137\231\154\132\232\163\133\229\164\135\228\184\173\229\144\171\230\156\137\229\183\178\229\159\185\229\133\187\231\154\132\232\163\133\229\164\135\239\188\140\230\152\175\229\144\166\233\128\137\230\139\169", tabParams)
      return
    end
  end
  self:_ClickSure()
end

function BagPage:_ClickSure()
  Data.equipData:SetConsumeEquip(self.m_selectEquipInfo)
  self:_InitParam()
end

function BagPage:_SortOrder()
  local param = {}
  if self.m_tabWidgets.tog_order.isOn then
    self.m_tabWidgets.txt_order.text = UIHelper.GetString(190002)
    param.Order = 0
  else
    self.m_tabWidgets.txt_order.text = UIHelper.GetString(190001)
    param.Order = 1
  end
  if self.m_openParam ~= nil and self.m_equipToBagSign == EquipToBagSign.CHANGE_EQUIP then
    Logic.bagLogic:SetSelectEquipRecord(param)
  end
  Logic.bagLogic:SetSortRecord(param)
  self:_UpdateBagEquip()
end

function BagPage:_ShowSortWay()
  if self.m_localRecord.Order == 0 then
    self.m_tabWidgets.txt_order.text = UIHelper.GetString(190002)
    self.m_tabWidgets.tog_order.isOn = true
  else
    self.m_tabWidgets.txt_order.text = UIHelper.GetString(190001)
    self.m_tabWidgets.tog_order.isOn = false
  end
  local screenType = Logic.equipLogic:GetEquipTypeConfig()
  self.m_tabWidgets.txt_screen.text = screenType[self.m_localRecord.Screen + 1].ewt_desc
  self.m_tabWidgets.txt_sort.text = UIHelper.GetString(tonumber(14010 .. self.m_localRecord.Sort + 1))
end

function BagPage:_RecordSort()
  local recordTab = Logic.bagLogic:GetSortRecord()
  local sendTab = {}
  sendTab.Type = OrderRecord.EQUIP_BAG
  sendTab.Sort = recordTab.Sort
  sendTab.Screen = recordTab.Screen
  sendTab.Order = recordTab.Order
  sendTab.OtherInfo = {}
  table.insert(sendTab.OtherInfo, recordTab.UseEquip)
  table.insert(sendTab.OtherInfo, recordTab.AttrEquip)
  Service.userService:SendOrderRecord(sendTab)
end

function BagPage:__OpenEffect(param)
  local toyId = param.ToyId
  local repeated = param.repeated
  local shipGirlConfig = configManager.GetDataById("config_interaction_figurte", toyId)
  local shipGrilModelPath = shipGirlConfig.figure_name
  local ModelPathELISA = "modelsq/" .. shipGrilModelPath .. "/" .. shipGrilModelPath
  if self.m_sprayObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_sprayObj)
    self.m_sprayObj = nil
  end
  self.m_sprayObj = GR.objectPoolManager:LuaGetGameObject(ModelPathELISA, self.tab_Widgets.trans)
  local itemPosition = configManager.GetDataById("config_parameter", 328).arrValue
  self.m_sprayObj.transform.localPosition = Vector3.New(itemPosition[1][1], itemPosition[1][2], itemPosition[1][3])
  self.m_sprayObj.transform.localEulerAngles = Vector3.New(itemPosition[2][1], itemPosition[2][2], itemPosition[2][3])
  self.m_sprayObj.transform.localScale = Vector3.New(itemPosition[3][1], itemPosition[3][2], itemPosition[3][3])
  UIHelper.SetLayer(self.m_sprayObj, LayerMask.NameToLayer("UI"))
  self.tab_Widgets.objEffect:SetActive(true)
  self.tab_Widgets.tx_Repeated.gameObject:SetActive(repeated)
end

function BagPage:_SetFleetType(fleetType)
  self.m_fleetType = fleetType
end

function BagPage:_GetFleetType()
  return self.m_fleetType
end

function BagPage:DoOnClose()
  if self.m_openParam == nil then
    self:_RecordSort()
  end
  Data.equipData:ClearRecord()
  Logic.bagLogic:ResetSelectEquipRecord()
  if self.m_sprayObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_sprayObj)
    self.m_sprayObj = nil
  end
end

function BagPage:DoOnHide()
  self:StopTimer()
  self.m_tabWidgets.tog_group:ClearToggles()
  Data.equipData:ClearRecord()
end

function BagPage:CreateCountDown()
  self.m_timer = self.m_timer or Timer.New()
  local timer = self.m_timer
  if timer.running then
    timer:Stop()
  end
  timer:Reset(function()
    self:_SetLeftTime()
  end, 1, -1)
  timer:Start()
  self:_SetLeftTime()
end

function BagPage:StopTimer()
  if self.m_timer and self.m_timer.running then
    self.m_timer:Stop()
    self.m_timer = nil
  end
end

function BagPage:_SetLeftTime()
  if next(self.specialItemInfo) == nil then
    return
  end
  for k, v in pairs(self.specialItemInfo) do
    local info = v
    local tabPart = self.tabTemp[k]
    if info.createTime ~= 0 then
      local duration = Logic.bagLogic:GetPeriodItemTime(info.time_duration, info.createTime)
      if duration <= 0 then
        self:_UpdateBagItem()
        eventManager:SendEvent(LuaEvent.ItemPastDue)
      elseif self.m_timer and k >= self.startIndex and k <= self.endIndex and tabPart then
        tabPart.obj_redDot:SetActive(duration < ONE_DAY_SEC)
        UIHelper.SetText(tabPart.tx_time, Logic.bagLogic:GetPeriodCountDown(duration))
      end
    end
  end
end

return BagPage
