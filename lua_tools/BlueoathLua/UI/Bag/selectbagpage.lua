local SelectBagPage = class("UI.Bag.SelectBagPage", LuaUIPage)
local equipItem = require("ui.page.Bag.BagEquipItem")
local equipAttrItem = require("ui.page.Bag.BagEquipAttItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local BagItem = {BAG_MATREIAL_ITEM = 0, BAG_EQUIP_ITEM = 1}
local ITEM_ID_BEGIN = 10000

function SelectBagPage:DoInit()
  self.m_tabWidgets = nil
  self.m_curSelectTog = 0
  self.m_localRecord = nil
  self.m_equipsInfo = nil
  self.m_heroEquipInfo = nil
  self.m_openParam = nil
  self.m_itemInfo = nil
  self.m_fenGeEquip = {}
  self.m_fenGeNomal = {}
  self.m_fenGeAtt = {}
  self.m_selectEquip = nil
  self.m_equipType = nil
  self.m_equipHeroId = nil
  self.m_fleetType = FleetType.Normal
  self:_InitParam()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.tabTags = {
    self.m_tabWidgets.tween_material,
    self.m_tabWidgets.tween_equip
  }
end

function SelectBagPage:_InitParam()
  self.m_equipToBagSign = nil
  self.m_maxSelectNum = 0
  self.m_selectNum = 0
  self.m_selectItem = {}
  self.m_selectEquipInfo = {}
  self.m_bagType = nil
end

function SelectBagPage:RegisterAllEvent()
  self.m_tabWidgets.tog_group:ClearToggles()
  self:RegisterEvent(LuaEvent.UpdateBagEquip, self._UpdateBagEquip, self)
  self:RegisterEvent(LuaEvent.UpdateEquipMsg, self._UpdatePage, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self._UpdateBagItem, self)
  self:RegisterEvent("changeHeroEquip", self._UpdateBagEquip, self)
  self:RegisterEvent(LuaEvent.EquipRiseStarSuccess, self._UpdateBagEquip, self)
  self.tabTogs = {
    self.m_tabWidgets.tog_material,
    self.m_tabWidgets.tog_equip
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

function SelectBagPage:_ShowUnintall()
  UIHelper.OpenPage("DismantlePage")
end

function SelectBagPage._stopToggle()
end

function SelectBagPage:DoOnOpen()
  self:OpenTopPage("SelectBagPage", 1, "\228\187\147\229\186\147", self, true)
  self.m_localRecord = Logic.bagLogic:GetSortRecord()
  if next(self.m_localRecord) == nil then
    self:_SetSortRecord()
  end
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
  elseif self.m_openParam ~= nil and self.m_equipToBagSign == EquipToBagSign.RISE_STAR then
    self.m_maxSelectNum = self.m_openParam[3]
    self.m_equipHeroId = self.m_openParam[4]
    self:_SetEquipToggle()
    return
  end
  self:_GetBagEquipInfo()
  self.m_itemInfo = Logic.bagLogic:DisposeItem()
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

function SelectBagPage:_SetEquipToggle()
  self:_SwitchTogs(BagItem.BAG_EQUIP_ITEM)
  self.m_tabWidgets.tog_group:SetActiveToggleIndex(BagItem.BAG_EQUIP_ITEM)
  self.m_tabWidgets.tog_group:ResigterToggleUnActive(0, self._stopToggle)
end

function SelectBagPage:_RiseInBag()
  self.m_tabWidgets.obj_rise:SetActive(true)
  self.m_tabWidgets.obj_equipButtom:SetActive(false)
  self.m_tabWidgets.obj_equipMiddle:SetActive(true)
  self.m_tabWidgets.obj_attMiddle:SetActive(false)
  self.m_tabWidgets.txt_selectNum.text = string.format("%d/<color=#47ACAC>%d</color>", 0, self.m_maxSelectNum)
  local riseExpendEquip = Logic.equipLogic:GetSpecificEquipInfo(self.m_equipHeroId)
  local equipconfig = Logic.equipLogic:GetEquipConfig(riseExpendEquip, nil, nil, self:_GetFleetType())
  self:_LoadEquipItem(equipconfig)
end

function SelectBagPage:_GetBagEquipInfo()
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

function SelectBagPage:_UpdatePage()
  local curToggle = Logic.bagLogic:GetCurToggle()
  self.m_itemInfo = Logic.bagLogic:DisposeItem()
  if curToggle == 0 then
    self:_LoadNomalItem()
  else
    self:_GetBagEquipInfo()
  end
end

function SelectBagPage:_UpdateBagItem()
  self:_DestroyNoamlPop()
  self.m_itemInfo = Logic.bagLogic:DisposeItem()
  local curToggle = Logic.bagLogic:GetCurToggle()
  if curToggle == 0 then
    self:_LoadNomalItem()
  else
    self:_GetBagEquipInfo()
  end
end

function SelectBagPage:_UpdateBagEquip()
  self:_DestroyEquipPop()
  self:_DestroyAttPop()
  if self.m_openParam ~= nil and self.m_equipToBagSign == EquipToBagSign.CHANGE_EQUIP then
    self.m_openParam[3] = self.m_selectEquip
  end
  self.m_localRecord = Logic.bagLogic:GetSortRecord()
  local totalEquip = self:_ShowHeroEquip()
  local equipOrder = Logic.bagLogic:EquipScreenAndSort(totalEquip, self.m_localRecord.Screen, self.m_localRecord.Sort + 1, self.m_localRecord.Order == 0)
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

function SelectBagPage:_SwitchTogs(index)
  for k, v in pairs(self.tabTags) do
    if k == index + 1 then
      self.tabTags[k]:Play(true)
    else
      self.tabTags[k]:Play(false)
    end
  end
  self.m_curSelectTog = index
  if index == 0 then
    self:_ShowEquipPage(false)
    self:_LoadNomalItem()
  elseif self.m_equipToBagSign == EquipToBagSign.RISE_STAR then
    self:_RiseInBag()
  else
    self:_ShowEquipPage(true)
    self:_GetBagEquipInfo()
    self:_UpdateBagEquip()
  end
  Logic.bagLogic:SetCurToggle(self.m_curSelectTog)
end

function SelectBagPage:_ShowEquipPage(enabled)
  self.m_tabWidgets.obj_rise:SetActive(false)
  self.m_tabWidgets.obj_equipButtom:SetActive(enabled)
  self.m_tabWidgets.obj_equipMiddle:SetActive(enabled)
  self.m_tabWidgets.obj_attMiddle:SetActive(enable)
  self.m_tabWidgets.obj_materialBut:SetActive(not enabled)
  self.m_tabWidgets.obj_middle:SetActive(not enabled)
end

function SelectBagPage:_ShowHeroEquip()
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

function SelectBagPage:_LoadNomalItem()
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_normalItem, self.m_tabWidgets.obj_normalItem, #self.m_itemInfo, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local info = self.m_itemInfo[nIndex]
      tabPart.txt_goodsName.text = info.name
      tabPart.txt_value.text = math.tointeger(info.num)
      if info.icon ~= nil then
        UIHelper.SetImage(tabPart.img_goods, tostring(info.icon))
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

function SelectBagPage:_LoadEquipItem(screenEquipTab)
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_equipItem, self.m_tabWidgets.obj_equipItem, #screenEquipTab, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local item = equipItem:new()
      local equipInfo = screenEquipTab[nIndex]
      if self.m_equipToBagSign == EquipToBagSign.RISE_STAR then
        item:Init(self, tabPart, equipInfo, self.m_equipToBagSign, nIndex)
        self.m_selectItem[nIndex] = item
      else
        item:Init(self, tabPart, equipInfo, nil, nIndex)
      end
    end
  end)
  local num = math.ceil(#screenEquipTab / 8)
  if 1 < num then
    self:_LoadFenGeEquip(num)
  end
end

function SelectBagPage:_LoadAttItem(screenEquipTab)
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

function SelectBagPage:_LoadFenGeEquip(num)
  self:_DestroyEquipPop()
  for i = 1, num - 1 do
    local createEquipLine = UIHelper.CreateGameObject(self.tab_Widgets.obj_fenGeEquip, self.tab_Widgets.trans_fenGeEquipItem)
    table.insert(self.m_fenGeEquip, createEquipLine)
    createEquipLine:SetActive(true)
    img_fenGe = createEquipLine.gameObject:GetComponent(UIImage.GetClassType())
    UIHelper.SetImage(img_fenGe, "uipic_ui_store_im_01")
  end
end

function SelectBagPage:_LoadFenGeNomal(num)
  self:_DestroyNoamlPop()
  for i = 1, num - 1 do
    local createNomalLine = UIHelper.CreateGameObject(self.tab_Widgets.obj_fenGe, self.tab_Widgets.trans_fenGeNomalItem)
    table.insert(self.m_fenGeNomal, createNomalLine)
    createNomalLine:SetActive(true)
    img_fenGe = createNomalLine.gameObject:GetComponent(UIImage.GetClassType())
    UIHelper.SetImage(img_fenGe, "uipic_ui_store_im_01")
  end
end

function SelectBagPage:_LoadFenGeAtt(num)
  self:_DestroyAttPop()
  for i = 1, num - 1 do
    local createAttLine = UIHelper.CreateGameObject(self.tab_Widgets.obj_fenGeAttEquip, self.tab_Widgets.trans_fenGeAttItem)
    table.insert(self.m_fenGeAtt, createAttLine)
    createAttLine:SetActive(true)
    img_fenGe = createAttLine.gameObject:GetComponent(UIImage.GetClassType())
    UIHelper.SetImage(img_fenGe, "uipic_ui_store_im_01")
  end
end

function SelectBagPage:_DestroyNoamlPop()
  if self.m_fenGeNomal ~= {} then
    for v, k in pairs(self.m_fenGeNomal) do
      GameObject.Destroy(k)
    end
    self.tab_Widgets.obj_fenGe:SetActive(false)
    self.m_fenGeNomal = {}
  end
end

function SelectBagPage:_DestroyEquipPop()
  if self.m_fenGeEquip ~= {} then
    for v, k in pairs(self.m_fenGeEquip) do
      GameObject.Destroy(k)
    end
    self.tab_Widgets.obj_fenGeEquip:SetActive(false)
    self.m_fenGeEquip = {}
  end
end

function SelectBagPage:_DestroyAttPop()
  if self.m_fenGeAtt ~= {} then
    for v, k in pairs(self.m_fenGeAtt) do
      GameObject.Destroy(k)
    end
    self.tab_Widgets.obj_fenGeEquip:SetActive(false)
    self.m_fenGeAtt = {}
  end
end

function SelectBagPage:_ItemDetail(iteminfo)
  local itemIndex = math.floor(iteminfo.id / ITEM_ID_BEGIN)
  if itemIndex == GoodsType.Fragment then
    UIHelper.OpenPage("PaperPage", iteminfo)
  elseif itemIndex == GoodsType.ITEM and iteminfo.type == 2 then
    UIHelper.OpenPage("SelectTreasurePage", iteminfo)
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(itemIndex, iteminfo.id))
  end
end

function SelectBagPage:ClickEquipDetail(equipId)
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
end

function SelectBagPage:_OpenHelp()
  UIHelper.OpenPage("HelpPage", {content = 320001})
end

function SelectBagPage:_OpenSort()
  UIHelper.OpenPage("BagEquipSortPage")
end

function SelectBagPage:ClickSelectEquip(isSelect, index, equipInfo)
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

function SelectBagPage:_RiseCancel()
  self:_InitParam()
  UIHelper.Back()
end

function SelectBagPage:_RiseSure()
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

function SelectBagPage:_ClickSure()
  Data.equipData:SetConsumeEquip(self.m_selectEquipInfo)
  self:_InitParam()
  UIHelper.Back()
end

function SelectBagPage:_SetSortRecord()
  local record = Data.userData:GetOrderRecord(OrderRecord.EQUIP_BAG)
  if record == nil then
    self.m_localRecord.Type = 2
    self.m_localRecord.Sort = 0
    self.m_localRecord.Screen = 0
    self.m_localRecord.Order = 0
    self.m_localRecord.UseEquip = 0
    self.m_localRecord.AttrEquip = 0
    Logic.bagLogic:SetSortRecord(self.m_localRecord)
    return
  end
  for i, v in pairs(record) do
    if type(v) ~= "table" then
      self.m_localRecord[i] = v
    end
  end
  self.m_localRecord.UseEquip = record.OtherInfo[1]
  self.m_localRecord.AttrEquip = record.OtherInfo[2]
  Logic.bagLogic:SetSortRecord(self.m_localRecord)
end

function SelectBagPage:_SortOrder()
  local param = {}
  if self.m_tabWidgets.tog_order.isOn then
    self.m_tabWidgets.txt_order.text = UIHelper.GetString(190002)
    param.Order = 0
  else
    self.m_tabWidgets.txt_order.text = UIHelper.GetString(190001)
    param.Order = 1
  end
  Logic.bagLogic:SetSortRecord(param)
  self:_UpdateBagEquip()
end

function SelectBagPage:_ShowSortWay()
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

function SelectBagPage:_RecordSort()
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

function SelectBagPage:_SetFleetType(fleetType)
  self.m_fleetType = fleetType
end

function SelectBagPage:_GetFleetType()
  return self.m_fleetType
end

function SelectBagPage:DoOnClose()
  self:_RecordSort()
  Data.equipData:ClearRecord()
end

function SelectBagPage:DoOnHide()
  self.m_tabWidgets.tog_group:ClearToggles()
  Data.equipData:ClearRecord()
end

return SelectBagPage
