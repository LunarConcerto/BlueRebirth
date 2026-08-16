local BagEquipSortPage = class("UI.Bag.BagEquipSortPage", LuaUIPage)

function BagEquipSortPage:DoInit()
  self.m_tabWidgets = nil
  self.paramTab = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.togTabPart = {}
  self.togTabRairtyPart = {}
end

function BagEquipSortPage:DoOnOpen()
  self.param = self:GetParam()
  self.m_tabWidgets.tween_scale:Play(true)
  self:_LoadSortItem()
  self:_LoadScreenItem()
  self:_SetSelectTog()
  if self.param == BagSortSign.ForDismantle then
    self.m_tabWidgets.tog_useEquip.gameObject:SetActive(false)
    self.m_tabWidgets.tog_equipAtt.gameObject:SetActive(false)
  end
end

function BagEquipSortPage:_SetSelectTog()
  local param = Logic.bagLogic:GetSortRecord()
  if self.param == BagSortSign.ForChangeEquip then
    param = Logic.bagLogic:GetSelectEquipRecord()
  end
  self.m_tabWidgets.tog_sortGroup:SetActiveToggleIndex(param.Sort)
  self.m_tabWidgets.tog_screenGroup:SetActiveToggleIndex(param.Screen)
  self.m_tabWidgets.tog_useEquip.isOn = param.UseEquip == 1
  self.m_tabWidgets.tog_equipAtt.isOn = param.AttrEquip == 1
end

function BagEquipSortPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_true, self._ClickTrue, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancal, self._ClickCancel, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_useEquip, self._ShowUseEquip, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_equipAtt, self._ShowEquipAtt, self)
end

function BagEquipSortPage:_LoadSortItem()
  local tabTogGroup = {}
  local count = 0
  for k, v in pairs(EquipSortType) do
    count = count + 1
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_sortItem, self.m_tabWidgets.tan_sortItem, count, function(nIndex, tabPart)
    tabPart.txt_name.text = UIHelper.GetString(tonumber(14010 .. nIndex))
    tabPart.tx_rarityFg.text = UIHelper.GetString(tonumber(14010 .. nIndex))
    table.insert(tabTogGroup, tabPart.Tog_rarity)
  end)
  for i, tog in ipairs(tabTogGroup) do
    self.m_tabWidgets.tog_sortGroup:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_sortGroup, self, "", self._SaveSortIndex)
end

function BagEquipSortPage:_SaveSortIndex(index)
  for v, k in pairs(self.togTabPart) do
    if v == index + 1 then
      k.img_select.gameObject:SetActive(true)
      k.obj_noAll:SetActive(false)
    else
      k.img_select.gameObject:SetActive(false)
      k.obj_noAll:SetActive(true)
    end
  end
  self.paramTab.Sort = index
end

function BagEquipSortPage:_LoadScreenItem()
  local screenType = Logic.equipLogic:GetEquipTypeConfig()
  local tabTog = {}
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_screenItem, self.m_tabWidgets.trans_screenItem, #screenType, function(nIndex, tabPart)
    tabPart.txt_name.text = screenType[nIndex].ewt_desc
    tabPart.tx_noAll.text = screenType[nIndex].ewt_desc
    tabTog[nIndex] = tabPart.Tog_rarity
    table.insert(self.togTabRairtyPart, tabPart)
  end)
  for i, tog in ipairs(tabTog) do
    self.m_tabWidgets.tog_screenGroup:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_screenGroup, self, "", self._SaveScreenIndex)
end

function BagEquipSortPage:_SaveScreenIndex(index)
  for v, k in pairs(self.togTabRairtyPart) do
    if v == index + 1 then
      k.img_select.gameObject:SetActive(true)
      k.Obj_noAll.gameObject:SetActive(false)
    else
      k.img_select.gameObject:SetActive(false)
      k.Obj_noAll:SetActive(true)
    end
  end
  self.paramTab.Screen = index
end

function BagEquipSortPage:_ShowUseEquip()
  if self.m_tabWidgets.tog_useEquip.isOn then
    self.paramTab.UseEquip = 1
  else
    self.paramTab.UseEquip = 0
  end
end

function BagEquipSortPage:_ShowEquipAtt()
  if self.m_tabWidgets.tog_equipAtt.isOn then
    self.paramTab.AttrEquip = 1
  else
    self.paramTab.AttrEquip = 0
  end
end

function BagEquipSortPage:_ClickTrue()
  if self.param == BagSortSign.ForChangeEquip then
    Logic.bagLogic:SetSelectEquipRecord(self.paramTab)
  else
    Logic.bagLogic:SetSortRecord(self.paramTab)
  end
  eventManager:SendEvent(LuaEvent.UpdateBagEquip)
  self:_ClosePage()
end

function BagEquipSortPage:_ClickCancel()
  self:_ClosePage()
end

function BagEquipSortPage:_ClosePage()
  UIHelper.ClosePage("BagEquipSortPage")
end

function BagEquipSortPage:DoOnHide()
  self.m_tabWidgets.tog_sortGroup:ClearToggles()
  self.m_tabWidgets.tog_screenGroup:ClearToggles()
end

function BagEquipSortPage:DoOnClose()
  self.m_tabWidgets.tog_sortGroup:ClearToggles()
  self.m_tabWidgets.tog_screenGroup:ClearToggles()
end

return BagEquipSortPage
