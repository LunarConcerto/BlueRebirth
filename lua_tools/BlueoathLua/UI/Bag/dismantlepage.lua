local DismantlePage = class("UI.Bag.DismantlePage", LuaUIPage)
local equipItem = require("ui.page.Bag.BagEquipItem")
local equipAttrItem = require("ui.page.Bag.BagEquipAttItem")

function DismantlePage:DoInit()
  self.m_tabWidgets = nil
  self.m_tabScreenEquip = {}
  self.m_fenGeEquip = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function DismantlePage:RegisterAllEvent()
  local widgets = self.m_tabWidgets
  UGUIEventListener.AddButtonOnClick(widgets.btn_item, self._CloseTip, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_sort, self._OpenSort, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_screen, self._OpenSort, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_sure, self._UnInstall, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_selectWhite, self._TogSelectN, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_selectBlue, self._TogSelectR, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_selectPurple, self._TogSelectSR, self)
  self:RegisterEvent(LuaEvent.UpdateBagEquip, self._UpdataDismantle, self)
  self:RegisterEvent(LuaEvent.UpdateEquipMsg, self._UpdataDismantle, self)
  self:RegisterEvent(LuaEvent.DismantleSuccess, self._ShowSuccessTips, self)
end

function DismantlePage:DoOnOpen()
  self:OpenTopPage("DismantlePage", 1, "\230\139\134\232\167\163", self, true)
  self:_UpdataDismantle()
  self.needCurrencyInfo = configManager.GetDataById("config_currency", CurrencyType.MAINGUN)
  local tabParam = {
    isShow = true,
    CurrencyInfo = self.needCurrencyInfo
  }
  eventManager:SendEvent(LuaEvent.TopAddItem, tabParam)
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
  local equips = Logic.dismantleLogic:GetDismantleEquip()
  if next(equips) == nil then
    noticeManager:ShowTip("\232\175\183\233\128\137\230\139\169\232\166\129\230\139\134\232\167\163\231\154\132\232\163\133\229\164\135")
    return
  end
  equips = Logic.dismantleLogic:ToArray(equips)
  local str = ""
  local high = Logic.equipLogic:HaveHighQualityEquip(equips)
  local intensify = Logic.equipLogic:HaveIntensifyEquip(equips)
  if high then
    str = str .. "\231\178\190\233\148\144\229\143\138\228\187\165\228\184\138\229\147\129\232\180\168"
  end
  if intensify then
    if high then
      str = str .. "\227\128\129"
    end
    str = str .. "\231\187\143\232\191\135\229\188\186\229\140\150"
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
  UIHelper.OpenPage("DismantleConfirmPage", equips)
end

function DismantlePage:_ConfirmUninsall(equips)
  UIHelper.OpenPage("DismantleConfirmPage", equips)
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
  local condition = function(equipId, quality)
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
  noticeManager:ShowTip("\230\157\144\230\150\153\228\184\141\229\143\175\228\187\165\230\139\134\232\167\163")
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

return DismantlePage
