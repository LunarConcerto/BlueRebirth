local AssistSelect = class("ui.page.Common.CommonSelect.AssistSelect")

function AssistSelect:initialize()
  self.m_page = nil
  self.m_widgets = nil
  self.m_tabParams = nil
  self.m_showFleet = true
end

function AssistSelect:Init(page, tabParams)
  self.m_page = page
  self.m_widgets = page.m_tabWidgets
  self.m_tabParams = tabParams
  self.m_page:OpenTopPage("CommonSelectPage", 1, "\232\136\185\229\157\158", self, true, function()
    self:_CrusadeCancel()
  end)
  UGUIEventListener.AddButtonToggleChanged(self.m_widgets.tog_showFleet, self._ShowFleet, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_ok, self._CrusadeConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_cancal, self._CrusadeCancel, self)
  local dotinfo = {
    info = "ui_shipyard",
    type = "crusade_shipyard"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  self.m_widgets.obj_crusade:SetActive(true)
  self.m_page.m_tabSelectShip = self.m_tabParams.m_selectedIdList
  if next(self.m_tabParams.m_selectedIdList) ~= nil then
    table.insertto(self.m_page.m_SelectedBack, self.m_page.m_tabSelectShip)
  end
end

function AssistSelect:_ShowFleet(go, isOn)
  local tabTemp
  self.m_showFleet = isOn
  if not isOn then
    tabTemp = Logic.shipLogic:RemoveFleetShip(self.m_page.m_tabSortHero)
  else
    tabTemp = self.m_page.m_heroData
  end
  local custom = {
    Ships = self.m_tabParams.m_tids,
    Types = self.m_tabParams.m_type
  }
  tabTemp = HeroSortHelper.AssistFilterAndSort(tabTemp, self.m_page.m_tabOutParams[1], self.m_page.m_tabOutParams[2], self.m_page.m_sortway, custom)
  self.m_page.m_tabSortHero = tabTemp
  self.m_page:_LoadHeroItem(tabTemp)
end

function AssistSelect:_CrusadeConfirm()
  local index = Logic.assistNewLogic:GetAssistContext().CurIndex
  Logic.assistNewLogic:SetAssistHeros(index, self.m_page.m_tabSelectShip)
  UIHelper.Back()
end

function AssistSelect:_CrusadeCancel()
  local index = Logic.assistNewLogic:GetAssistContext().CurIndex
  Logic.assistNewLogic:SetAssistHeros(index, self.m_page.m_SelectedBack)
  UIHelper.Back()
end

function AssistSelect:GetShowFleet()
  return self.m_showFleet
end

return AssistSelect
