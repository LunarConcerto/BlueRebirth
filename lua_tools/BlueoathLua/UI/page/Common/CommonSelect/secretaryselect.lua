local SecretarySelect = class("ui.page.Common.CommonSelect.SecretarySelect")

function SecretarySelect:initialize()
  self.m_page = nil
  self.m_widgets = nil
  self.m_tabParams = nil
end

function SecretarySelect:Init(page, tabParams)
  self.m_page = page
  self.m_widgets = page.m_tabWidgets
  self.m_tabParams = tabParams
  self.m_page:OpenTopPage("CommonSelectPage", 1, "\232\136\185\229\157\158", self, true, self._ChangeSecretaryCancel)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_ok, self._ChangeSecretaryConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_cancal, self._ChangeSecretaryCancel, self)
  local dotinfo = {
    info = "ui_shipyard",
    type = "school_shipyard"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  self.m_page.m_tabSelectShip = tabParams.m_selectedIdList or {}
end

function SecretarySelect:_ChangeSecretaryConfirm()
  if #self.m_page.m_tabSelectShip == 0 then
    noticeManager:OpenTipPage(self, "\232\175\183\233\128\137\230\139\169\230\136\152\229\167\172")
    return
  end
  if Logic.forbiddenHeroLogic:CheckForbiddenInSystem(self.m_page.m_tabSelectShip[1], ForbiddenType.Secretary) then
    return
  end
  Logic.homeLogic:ChangeEnd(self.m_page.m_tabSelectShip[1])
  Service.userService:SendSecretary(self.m_page.m_tabSelectShip[1])
  UIHelper.Back()
end

function SecretarySelect:_ChangeSecretaryCancel()
  UIHelper.Back()
end

return SecretarySelect
