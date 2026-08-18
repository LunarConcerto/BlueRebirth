local DismantlePage = class("UI.Bag.DismantlePage", LuaUIPage)
local equipItem = require("ui.page.Bag.BagEquipItem")
local equipAttrItem = require("ui.page.Bag.BagEquipAttItem")
local DismantleType = {DismantleItem = 1, DismantleEquip = 2}

function DismantlePage:DoInit()
  self.m_tabWidgets = nil
  self.m_tabScreenEquip = {}
  self.m_fenGeEquip = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.selectItemTab = {}
end

function DismantlePage:RegisterAllEvent()
  local widgets = self.m_tabWidgets
  UGUIEventListener.AddButtonOnClick(widgets.btn_sort, self._OpenSort, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_screen, self._OpenSort, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_sure, self._UnInstall, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_selectWhite, self._TogSelectN, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_selectBlue, self._TogSelectR, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_selectPurple, self._TogSelectSR, self)
  self:RegisterEvent(LuaEvent.UpdateBagEquip, self._UpdataDismantle, self)
  self:RegisterEvent(LuaEvent.UpdateEquipMsg, self._UpdataDismantle, self)
  self:RegisterEvent(LuaEvent.DismantleSuccess, self._ShowSuccessTips, self)
  self:RegisterEvent(LuaEvent.SaleBagItemSuccess, self._ShowItemSuccess, self)
end

function DismantlePage:DoOnOpen()
  local widgets = self.m_tabWidgets
  local params = self:GetParam()
  self.dismantleType = params ~= nil and params or DismantleType.DismantleEquip
  if params ~= nil then
    UGUIEventListener.AddButtonOnClick(widgets.btn_equip, self._CloseEquipTip, self)
    widgets.btn_item.transform.localPosition = Vector3.New(-291.52, -44.64, 0)
    widgets.btn_equip.transform.localPosition = Vector3.New(-242.02, -105, 0)
    widgets.obj_equipBtn:SetActive(false)
    self:OpenTopPage("DismantlePage", 1, UIHelper.GetString(4700018), self, true)
    self:_UpdateBagItem()
    return
  end
  UGUIEventListener.AddButtonOnClick(widgets.btn_item, self._CloseTip, self)
  widgets.btn_item.transform.localPosition = Vector3.New(-242.02, -44.64, 0)
  widgets.btn_equip.transform.localPosition = Vector3.New(-291.52, -105, 0)
  self:OpenTopPage("DismantlePage", 1, UIHelper.GetString(920000068), self, true)
  self:_UpdataDismantle()
  self.needCurrencyInfo = configManager.GetDataById("config_currency", CurrencyType.MAINGUN)
  local tabParam = {
    isShow = true,
    CurrencyInfo = self.needCurrencyInfo
  }
  eventManager:SendEvent(LuaEvent.TopAddItem, tabParam)
end

function DismantlePage:_UpdateBagItem()
  if self.dismantleType == DismantleType.DismantleEquip then
    return
  end
  local dismantleItem = {}
  local m_itemInfo = Logic.bagLogic:DisposeItem()
  for _, v in ipairs(m_itemInfo) do
    if v.saleable == 1 then
      table.insert(dismantleItem, v)
    end
  end
  self:_LoadDismantleItem(dismantleItem)
end

function DismantlePage:_UpdataDismantle()
  self:_DestroyEquipPop()
  self:_ShowUnuseEquip()
  self:_ShowButtomNum(self.m_tabWidgets.txt_capacity)
  self:_ShowSortStr()
end

function DismantlePage:_ShowUnuseEquip()
  local localRecord = Logic.dismantleLogic:GetDismantleSortSet()
  local tabUnuseEquip = self:_GetBagEquipInfo()
  local screenType = Logic.equipLogic:GetEquipTypeConfig()
  local screen = screenType[localRecord.Screen + 1].ewt_id
  local equipOrder = Logic.bagLogic:EquipScreenAndSort(tabUnuseEquip, screen, localRecord.Sort + 1, localRecord.Order == 0)
  self:_LoadEquipItem(equipOrder)
end

function DismantlePage:_ShowSuccessTips(rewards)
  self.m_tabWidgets.tog_select.isOn = false
  if 0 < #rewards then
    Logic.rewardLogic:ShowCommonReward(rewards, "DismantlePage", function()
      Logic.equipLogic:ResetDisRewardCache()
    end)
  end
  self:_ResetData()
  self:_ResetUI()
end

function DismantlePage:_ResetUI()
  local widgets = self:GetWidgets()
  widgets.tog_selectWhite.isOn = false
  widgets.tog_selectBlue.isOn = false
  widgets.tog_selectPurple.isOn = false
  self:_ShowButtomNum(widgets.txt_capacity)
end

function DismantlePage:_ResetData()
  Logic.dismantleLogic:ResetDismantleEquip()
end

function DismantlePage:_GetBagEquipInfo()
  local equipBagInfo = Data.equipData:GetEquipData()
  local equipTab = Logic.equipLogic:GetEquipConfig(equipBagInfo, nil)
  local _, tabRes = Logic.equipLogic:EquipBagOverlay(equipTab)
  return tabRes
end

function DismantlePage:_UnInstall()
  if self.dismantleType == DismantleType.DismantleItem then
    if next(self.selectItemTab) ~= nil then
      UIHelper.OpenPage("DismantleConfirmPage", {
        selectTab = self.selectItemTab,
        dismantleType = self.dismantleType
      })
    else
      noticeManager:ShowTip(UIHelper.GetString(4700019))
    end
    return
  end
  local equips = Logic.dismantleLogic:GetDismantleEquip()
  if next(equips) == nil then
    noticeManager:ShowTip(UIHelper.GetString(920000103))
    return
  end
  equips = Logic.dismantleLogic:ToArray(equips)
  local str = ""
  local high = Logic.equipLogic:HaveHighQualityEquip(equips)
  local intensify = Logic.equipLogic:HaveIntensifyEquip(equips)
  if high then
    str = str .. UIHelper.GetString(920000104)
  end
  if intensify then
    if high then
      str = str .. "\227\128\129"
    end
    str = str .. UIHelper.GetString(920000105)
  end
  if utf8.len(str) ~= 0 then
    str = UIHelper.SetColor(str, "FF0000")
    str = string.format(UIHelper.GetString(170015), str)
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ConfirmUninsall(equips)
        end
      end
    }
    noticeManager:ShowMsgBox(str, tabParams)
    return
  end
  UIHelper.OpenPage("DismantleConfirmPage", {
    selectTab = equips,
    dismantleType = self.dismantleType
  })
end

function DismantlePage:_ConfirmUninsall(equips)
  UIHelper.OpenPage("DismantleConfirmPage", {
    selectTab = equips,
    dismantleType = self.dismantleType
  })
end

function DismantlePage:_TogSelectN(go, isOn)
  self:_TogSelectByQuality(isOn, HeroRarityType.N)
end

function DismantlePage:_TogSelectR(go, isOn)
  self:_TogSelectByQuality(isOn, HeroRarityType.R)
end

function DismantlePage:_TogSelectSR(go, isOn)
  self:_TogSelectByQuality(isOn, HeroRarityType.SR)
end

function DismantlePage:_TogSelectByQuality(isOn, quality)
  local q, c, tid
  
  local function condition(equipId, quality)
    q = Logic.equipLogic:GetQualityByEquipId(equipId)
    if q < HeroRarityType.SR then
      return q == quality
    end
    tid = Data.equipData:GetEquipDataById(equipId).TemplateId
    c = Logic.equipLogic:IsCommonRiseEquip(tid)
    return q == quality and not c
  end
  
  for _, id in ipairs(self.m_tabScreenEquip) do
    if condition(id, quality) then
      if isOn then
        Logic.dismantleLogic:AddDismantleEquip(id)
      else
        Logic.dismantleLogic:RemoveDismantleEquip(id)
      end
    end
  end
  self:_UpdataDismantle()
end

function DismantlePage:_LoadEquipItem(screenEquipTab)
  local widgets = self.m_tabWidgets
  self.m_tabScreenEquip = {}
  self:_AddEquipId2Table(self.m_tabScreenEquip, screenEquipTab)
  UIHelper.SetInfiniteItemParam(widgets.iil_equipItem, widgets.obj_equipItem, #screenEquipTab, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local item = equipItem:new()
      local equipInfo = screenEquipTab[nIndex]
      item:Init(self, tabPart, equipInfo, EquipToBagSign.DISMANTLE_EQUIP, nIndex)
      self:_ShowDismantleStatus(tabPart, equipInfo)
    end
  end)
  local num = math.ceil(#screenEquipTab / 8)
  if 1 < num then
    self:_LoadFenGeEquip(num)
  end
  self:_RemoveNoScreenEquip()
end

function DismantlePage:_LoadFenGeEquip(num)
  self:_DestroyEquipPop()
  for i = 1, num - 1 do
    local createEquipLine = UIHelper.CreateGameObject(self.tab_Widgets.obj_fenGeEquip, self.tab_Widgets.trans_fenGeEquipItem)
    table.insert(self.m_fenGeEquip, createEquipLine)
    createEquipLine:SetActive(true)
    img_fenGe = createEquipLine.gameObject:GetComponent(UIImage.GetClassType())
    UIHelper.SetImage(img_fenGe, "uipic_ui_store_im_01")
  end
end

function DismantlePage:_DestroyEquipPop()
  if self.m_fenGeEquip ~= {} then
    for v, k in pairs(self.m_fenGeEquip) do
      GameObject.Destroy(k)
    end
    self.tab_Widgets.obj_fenGeEquip:SetActive(false)
    self.m_fenGeEquip = {}
  end
end

function DismantlePage:_RemoveNoScreenEquip()
  local equips = Logic.dismantleLogic:GetDismantleEquip()
  local res = {}
  for _, id in ipairs(self.m_tabScreenEquip) do
    if equips[id] then
      table.insert(res, id)
    end
  end
  Logic.dismantleLogic:SetDismantleEquip(res)
end

function DismantlePage:_ShowDismantleStatus(tabPart, equipInfo)
  local disNum = Logic.equipLogic:InDismantleNum(equipInfo.tabEquipId)
  tabPart.obj_selectTag:SetActive(disNum ~= 0)
  if disNum == 0 then
    UIHelper.SetText(tabPart.txt_num, equipInfo.Num)
  else
    UIHelper.SetText(tabPart.txt_num, disNum .. "/" .. equipInfo.Num)
  end
end

function DismantlePage:_ClickSubEquip(equipInfo, tabPart)
  local tabEquipId = equipInfo.tabEquipId
  local disNum = Logic.equipLogic:InDismantleNum(tabEquipId)
  for k, v in pairs(tabEquipId) do
    if Logic.equipLogic:IsInDismantle(v) then
      Logic.dismantleLogic:RemoveDismantleEquip(v)
      break
    end
  end
  if disNum == 1 then
    tabPart.obj_selectTag:SetActive(false)
    UIHelper.SetText(tabPart.txt_num, #tabEquipId)
  else
    UIHelper.SetText(tabPart.txt_num, disNum - 1 .. "/" .. #tabEquipId)
  end
  self:_ShowButtomNum(self.m_tabWidgets.txt_capacity)
  local widgets = self.m_tabWidgets
  self.m_tabWidgets.tog_select.isOn = false
end

function DismantlePage:_ClickEquipDismantle(equipInfo, tabPart)
  local tabEquipId = equipInfo.tabEquipId
  local can, msg = Logic.equipLogic:CanDelect(equipInfo.TemplateId)
  if not can then
    noticeManager:ShowTip(msg)
    return
  end
  local equipNum = equipInfo.Num
  local disNum = Logic.equipLogic:InDismantleNum(tabEquipId)
  if disNum == 0 then
    local addNum
    for k, v in ipairs(tabEquipId) do
      Logic.dismantleLogic:AddDismantleEquip(v)
    end
    addNum = equipNum
    tabPart.obj_selectTag:SetActive(true)
    UIHelper.SetText(tabPart.txt_num, addNum .. "/" .. #tabEquipId)
  else
    for k, v in pairs(tabEquipId) do
      if Logic.equipLogic:IsInDismantle(v) then
        Logic.dismantleLogic:RemoveDismantleEquip(v)
      end
    end
    tabPart.obj_selectTag:SetActive(false)
    UIHelper.SetText(tabPart.txt_num, #tabEquipId)
    self.m_tabWidgets.tog_select.isOn = false
  end
  self:_ShowButtomNum(self.m_tabWidgets.txt_capacity)
  local isOn = Logic.dismantleLogic:GetDismantleNum() ~= 0
end

function DismantlePage:_OpenSort()
  UIHelper.OpenPage("BagEquipSortPage", BagSortSign.ForDismantle)
end

function DismantlePage:_CloseTip()
  noticeManager:ShowTip(UIHelper.GetString(920000106))
end

function DismantlePage:_CloseEquipTip()
  noticeManager:ShowTip(UIHelper.GetString(4700020))
end

function DismantlePage:_ShowButtomNum(tx_num)
  local selectNum = Logic.dismantleLogic:GetDismantleNum()
  UIHelper.SetText(tx_num, "<color=#ffffff>" .. selectNum .. "</color>")
end

function DismantlePage:_ShowSortStr()
  local screenType = Logic.equipLogic:GetEquipTypeConfig()
  local localRecord = Logic.dismantleLogic:GetDismantleSortSet()
  self.m_tabWidgets.txt_screen.text = screenType[localRecord.Screen + 1].ewt_desc
  self.m_tabWidgets.txt_sort.text = UIHelper.GetString(tonumber(14010 .. localRecord.Sort + 1))
end

function DismantlePage:_AddEquipId2Table(tabEquipId, tabEquipInfo)
  for k, v in ipairs(tabEquipInfo) do
    for key, value in pairs(v.tabEquipId) do
      table.insert(tabEquipId, value)
    end
  end
end

function DismantlePage:_GetFleetType()
  return FleetType.Normal
end

function DismantlePage:DoOnClose()
  Logic.dismantleLogic:ResetDismantleEquip()
end

function DismantlePage:DoOnHide()
end

function DismantlePage:_LoadDismantleItem(itemTab)
  local widgets = self.m_tabWidgets
  UIHelper.SetInfiniteItemParam(widgets.iil_equipItem, widgets.obj_equipItem, #itemTab, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local item = equipItem:new()
      local itemInfo = itemTab[nIndex]
      tabPart.img_select.enabled = false
      tabPart.txt_equipName.text = itemInfo.name
      UIHelper.SetImage(tabPart.img_goods, tostring(itemInfo.icon))
      UIHelper.SetImage(tabPart.img_quality, QualityIcon[itemInfo.quality])
      tabPart.txt_num.text = itemInfo.num
      tabPart.txt_lv.gameObject:SetActive(false)
      tabPart.obj_girl:SetActive(false)
      tabPart.obj_newSign:SetActive(false)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_equip, function()
        self:_ClickItemDismantle(itemInfo, tabPart)
      end)
      UGUIEventListener.AddButtonOnClick(tabPart.obj_selectTag, function()
        self:_ClickSubItem(itemInfo, tabPart)
      end)
      tabPart.obj_selectTag:SetActive(false)
      self:_ShowItemDismantleStatus(tabPart, itemInfo)
    end
  end)
  self:_ShowItemButtomNum()
  local num = math.ceil(#itemTab / 8)
  if 1 < num then
    self:_LoadFenGeEquip(num)
  end
end

function DismantlePage:_ClickSubItem(itemInfo, tabPart)
  local disNum = self.selectItemTab[itemInfo.id]
  self.selectItemTab[itemInfo.id] = disNum - 1
  if disNum == 1 then
    tabPart.obj_selectTag:SetActive(false)
    UIHelper.SetText(tabPart.txt_num, itemInfo.num)
    self.selectItemTab[itemInfo.id] = nil
  else
    UIHelper.SetText(tabPart.txt_num, disNum - 1 .. "/" .. itemInfo.num)
  end
  self:_ShowItemButtomNum()
  self.m_tabWidgets.tog_select.isOn = false
end

function DismantlePage:_ClickItemDismantle(itemInfo, tabPart)
  local disNum = self.selectItemTab[itemInfo.id]
  if disNum == nil then
    self.selectItemTab[itemInfo.id] = itemInfo.num
    tabPart.obj_selectTag:SetActive(true)
    UIHelper.SetText(tabPart.txt_num, itemInfo.num .. "/" .. itemInfo.num)
  else
    self.selectItemTab[itemInfo.id] = nil
    tabPart.obj_selectTag:SetActive(false)
    UIHelper.SetText(tabPart.txt_num, itemInfo.num)
    self.m_tabWidgets.tog_select.isOn = false
  end
  self:_ShowItemButtomNum()
end

function DismantlePage:_ShowItemButtomNum()
  local totalNum = 0
  for _, v in pairs(self.selectItemTab) do
    totalNum = totalNum + v
  end
  UIHelper.SetText(self.m_tabWidgets.txt_capacity, "<color=#ffffff>" .. totalNum .. "</color>")
end

function DismantlePage:_ShowItemSuccess(ret)
  if #ret.saleItemReward > 0 then
    Logic.rewardLogic:ShowCommonReward(ret.saleItemReward, "DismantlePage")
  end
  self.selectItemTab = {}
  self:_UpdateBagItem()
end

function DismantlePage:_ShowItemDismantleStatus(tabPart, itemInfo)
  local disNum = self.selectItemTab[itemInfo.id]
  tabPart.obj_selectTag:SetActive(disNum ~= nil)
  if disNum == nil then
    UIHelper.SetText(tabPart.txt_num, itemInfo.num)
  else
    UIHelper.SetText(tabPart.txt_num, disNum .. "/" .. itemInfo.num)
  end
end

return DismantlePage
