local SuperNoticePage = class("UI.Common.SuperNoticePage", LuaUIPage)

function SuperNoticePage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function SuperNoticePage:DoOnOpen()
  if self.param == nil then
    logError("self.param is nil")
    return
  end
  self.tab_Widgets.tog_hint.gameObject:SetActive(self.param.tgIsShow)
  self.tab_Widgets.tog_hint.isOn = self.param.tgIsOn
  self.tab_Widgets.content.text = self.param.content
  self.tab_Widgets.content_tg.text = self.param.contentTg
  self.tab_Widgets.btn_custom.gameObject:SetActive(self.param.nameCustom)
  if self.param.nameCustom then
    self.tab_Widgets.txt_nameCustom.text = self.param.nameCustom
  end
  if self.param.titleTxt then
    self.tab_Widgets.txt_title.text = self.param.titleTxt
  end
  self.tab_Widgets.txt_custom.gameObject:SetActive(self.param.customTxt)
  if self.param.customTxt then
    self.tab_Widgets.txt_custom.text = self.param.customTxt
  end
  self.tab_Widgets.btn_cancel.gameObject:SetActive(not self.param.isHideCancel)
end

function SuperNoticePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancel, self._ClickCancel, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickCancel, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_bg, self._ClickCancel, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_custom, self._ClickCustom, self)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.tog_hint, self._ClickTg, self)
end

function SuperNoticePage:_ClickConfirm()
  local isOn = self.tab_Widgets.tog_hint.isOn
  self:_CloseNotice()
  if self.param and self.param.callBackConfirm then
    self.param.callBackConfirm(isOn)
  end
end

function SuperNoticePage:_ClickCancel()
  self:_CloseNotice()
  if self.param and self.param.callBackCancel then
    self.param.callBackCancel()
  end
end

function SuperNoticePage:_CloseNotice()
  UIHelper.ClosePage("SuperNoticePage")
end

function SuperNoticePage:_ClickTg()
end

function SuperNoticePage:_ClickCustom()
  self:_CloseNotice()
  if self.param and self.param.callBackCustom then
    self.param.callBackCustom()
  end
end

return SuperNoticePage
