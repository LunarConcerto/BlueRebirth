local BreakSelect = class("ui.page.Common.CommonSelect.BreakSelect")

function BreakSelect:initialize()
  self.m_page = nil
  self.m_widgets = nil
  self.m_tabParams = nil
end

function BreakSelect:Init(page, tabParams)
  self.m_page = page
  self.m_widgets = page.m_tabWidgets
  self.m_tabParams = tabParams
  self.m_page:OpenTopPage("CommonSelectPage", 1, "\232\136\185\229\157\158", self, true, function()
    self:_BreakCancel()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_ok, self._BreakConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_cancal, self._BreakCancel, self)
  local dotinfo = {
    info = "ui_shipyard",
    type = "break_shipyard"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  self.m_widgets.obj_sort:SetActive(false)
  self.m_page.m_tabSelectShip = self.m_tabParams.m_selectedIdList
  if next(self.m_tabParams.m_selectedIdList) ~= nil then
    table.insertto(self.m_page.m_SelectedBack, self.m_page.m_tabSelectShip)
  end
end

function BreakSelect:_BreakConfirm()
  self.m_page:_CheckSelectHero(LuaEvent.HeroBreakSelect, self.m_page.m_tabSelectShip)
end

function BreakSelect:_BreakCancel()
  eventManager:SendEvent(LuaEvent.HeroBreakSelect, self.m_page.m_SelectedBack)
  UIHelper.Back()
end

return BreakSelect
