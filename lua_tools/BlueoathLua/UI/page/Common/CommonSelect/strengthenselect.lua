local StrengthenSelect = class("ui.page.Common.CommonSelect.StrengthenSelect")

function StrengthenSelect:initialize()
  self.m_page = nil
  self.m_widgets = nil
  self.m_tabParams = nil
end

function StrengthenSelect:Init(page, tabParams)
  self.m_page = page
  self.m_widgets = page.m_tabWidgets
  self.m_tabParams = tabParams
  self.m_page:OpenTopPage("CommonSelectPage", 1, "\232\136\185\229\157\158", self, true, function()
    self:_StrengthenCancel()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_ok, self._StrengthenConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_cancal, self._StrengthenCancel, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_widgets.tog_showexp, self._ShowExp, self)
  self.m_page.m_tabShipInfo = self.m_tabParams.m_tabShipInfo
  self.m_page.m_tabSelectShip = clone(self.m_tabParams.m_selectedIdList)
  self.m_widgets.obj_strengthen:SetActive(true)
  self.m_page.m_tabChiName = Logic.strengthen_PageLogic:GetPropName(self.m_page.m_heroData, self.m_page.m_tabShipInfo.TemplateId)
  self.m_page:_LoadTotalExp(self.m_page.m_tabChiName)
end

function StrengthenSelect:_ShowExp()
  self.m_page.m_isShowProp = not self.m_page.m_isShowProp
  self.m_page:_LoadHeroItem(self.m_page.m_tabSortHero)
end

function StrengthenSelect:_StrengthenConfirm()
  local tabParam = {}
  table.insert(tabParam, self.m_page.m_tabSelectShip)
  table.insert(tabParam, self.m_page.m_tabTotalExp)
  self.m_page:_CheckSelectHero(LuaEvent.UpdataSelect, tabParam)
  Logic.dockLogic:RecordSelectShip(tabParam[1])
end

function StrengthenSelect:_StrengthenCancel()
  local tabParam = {}
  table.insert(tabParam, self.m_tabParams.m_selectedIdList)
  UIHelper.Back()
  eventManager:SendEvent(LuaEvent.UpdataSelect, tabParam)
end

return StrengthenSelect
