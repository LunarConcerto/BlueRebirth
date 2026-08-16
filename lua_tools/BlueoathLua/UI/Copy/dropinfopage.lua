local DropInfoPage = class("UI.Copy.DropInfoPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local DropType = {
  Ship = 0,
  Complex = 1,
  single = 2
}

function DropInfoPage:DoInit()
  self.m_tabOpenDropInfoConf = nil
  self.m_tabCopyDropIds = nil
  self.m_tabTagDropInfo = {}
  self.nOpenItemId = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function DropInfoPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeGroup, function()
    self:_ClickBeforeBack()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.im_mask, function()
    self:_ClickBeforeBack()
  end)
end

function DropInfoPage:DoOnOpen()
  self.m_tabOpenDropInfoConf = self.param.ItemInfo
  self.m_tabCopyDropIds = self.param.TabCopyDropInfo
  self:_CreateShowTag()
end

function DropInfoPage:_CreateShowTag()
  for k, v in pairs(self.m_tabCopyDropIds) do
    local tagInfo = configManager.GetDataById("config_drop_info", v)
    if tagInfo.type ~= 2 then
      local inPeriod = true
      if tagInfo.period ~= nil and tagInfo.period > 0 then
        inPeriod = PeriodManager:IsInPeriod(tagInfo.period)
      end
      if inPeriod then
        table.insert(self.m_tabTagDropInfo, tagInfo)
      end
    end
  end
  local togGroup = {}
  local selectIndex = 0
  self.m_tabWidgets.tog_tagGroup:ClearToggles()
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_cloneYeQian, self.m_tabWidgets.trans_itemYeQianContent, #self.m_tabTagDropInfo, function(nIndex, tabPart)
    local TagDesInfo = self.m_tabTagDropInfo[nIndex]
    tabPart.tx_tag.text = TagDesInfo.name
    tabPart.tx_xuanzhong.text = TagDesInfo.name
    if self.m_tabOpenDropInfoConf.id == TagDesInfo.id then
      selectIndex = nIndex
    end
    table.insert(togGroup, tabPart.tog_item)
  end)
  for i, tog in ipairs(togGroup) do
    self.m_tabWidgets.tog_tagGroup:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_tagGroup, self, " ", self._SwitchTogsTag)
  self.m_tabWidgets.tog_tagGroup:SetActiveToggleIndex(selectIndex - 1)
end

function DropInfoPage:_SwitchTogsTag(nIndex)
  local tagDropInfo = self.m_tabTagDropInfo[nIndex + 1]
  self:_ShowTagContentInfo(tagDropInfo)
end

function DropInfoPage:_ShowTagContentInfo(tagDropInfo)
  local dropItem = tagDropInfo.item_info
  local tabItem = {}
  UIHelper.SetText(self.m_tabWidgets.txt_desc, tagDropInfo.description)
  for i = 1, #dropItem do
    local dropGoods = dropItem[i]
    local tab_tableIndexInfo = configManager.GetDataById("config_table_index", dropGoods[1])
    local tabInfo = Logic.bagLogic:GetItemByTempateId(tab_tableIndexInfo.id, dropGoods[2])
    tabInfo.Num = dropGoods[3] and dropGoods[3] or 0
    table.insert(tabItem, tabInfo)
  end
  local tabSortItem = tabItem
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_cloneDropItem, self.m_tabWidgets.trans_itemDropContent, #tabSortItem, function(nIndex, tabPart)
    local itemInfo = tabSortItem[nIndex]
    UIHelper.SetImage(tabPart.im_bgFleet, QualityIcon[itemInfo.quality])
    local bIsCanClick = false
    if tagDropInfo.type == 0 then
      tabPart.im_other.gameObject:SetActive(true)
      tabPart.obj_ship.gameObject:SetActive(false)
      UIHelper.SetImage(tabPart.im_fleet, tostring(itemInfo.icon))
      bIsCanClick = true
    else
      if tagDropInfo.type == 3 then
        tabPart.txt_firstRewardNum.text = "x" .. itemInfo.Num
      end
      tabPart.obj_ship.gameObject:SetActive(false)
      tabPart.im_other.gameObject:SetActive(true)
      UIHelper.SetImage(tabPart.im_fleet, tostring(itemInfo.icon))
      bIsCanClick = true
    end
    tabPart.txt_firstRewardNum.gameObject:SetActive(tagDropInfo.type == 3)
    tabPart.obj_numBg:SetActive(tagDropInfo.type == 3)
    if itemInfo.tabIndex == 2 and tabPart.obj_skin ~= nil then
      local isHave = Logic.equipLogic:EquipIsHaveEffect(itemInfo.id)
      tabPart.obj_skin:SetActive(isHave)
    elseif tabPart.obj_skin ~= nil then
      tabPart.obj_skin:SetActive(false)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_outItem, function()
      if bIsCanClick then
        Logic.itemLogic:ShowItemInfo(itemInfo.tabIndex, itemInfo.id)
      end
    end)
  end)
end

function DropInfoPage:_ClickBeforeBack()
  UIHelper.ClosePage("DropInfoPage")
end

return DropInfoPage
