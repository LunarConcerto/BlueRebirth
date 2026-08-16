NoticePage = class("UI.NoticePage", LuaUIPage)

function NoticePage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function NoticePage:DoOnOpen()
  noticeManager:SetIsClose(false)
  self.m_tabParam = self:GetParam()
  self:_LoadNotice(self.m_tabParam)
end

function NoticePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdataNotice, self._LoadNotice, self)
end

function NoticePage:_LoadNotice(tabParam)
  if tabParam == nil then
    UIHelper.ClosePage("NoticePage")
  else
    self:_DealParams(tabParam)
  end
end

function NoticePage:_ShowMsgBoxOneButton(content, nameok)
  self.m_tabWidgets.btn_ok.gameObject:SetActive(true)
  self.m_tabWidgets.obj_btnfather:SetActive(false)
  if type(content) == "number" then
    self.m_tabWidgets.txt_content.text = UIHelper.GetString(content)
  else
    self.m_tabWidgets.txt_content.text = content
  end
  if nameok ~= nil then
    self.m_tabWidgets.txt_ok.text = nameok
  end
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ok, self._Confirm, self)
end

function NoticePage:_ShowMsgBoxTwoButton(content, nameok, namecancel)
  self.m_tabWidgets.obj_btnfather:SetActive(true)
  self.m_tabWidgets.btn_ok.gameObject:SetActive(false)
  if type(content) == "number" then
    self.m_tabWidgets.txt_content.text = UIHelper.GetString(content)
  else
    self.m_tabWidgets.txt_content.text = content
  end
  if nameok ~= nil then
    self.m_tabWidgets.txt_ok1.text = nameok
  end
  if namecancel ~= nil then
    self.m_tabWidgets.txt_cancel.text = namecancel
  end
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ok1, self._Confirm, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, self._Cancel, self)
end

function NoticePage:_DealParams(tabParam)
  self.content = tabParam.content or ""
  self.target = tabParam.target
  self.callbackOk = tabParam.callbackOk
  self.callbackCancel = tabParam.callbackCancel
  self.nameok = tabParam.nameOk or "\231\161\174\229\174\154"
  self.namecancel = tabParam.nameCancel or "\229\143\150\230\182\136"
  self.guidedefineId = tabParam.guidedefineId
end

function NoticePage:_ClosePage()
  eventManager:SendEvent(LuaEvent.CloseNotice)
end

function NoticePage:_Cancel()
  self:_ClosePage()
  if self.callbackCancel ~= nil then
    self.callbackCancel(self.target)
  end
end

function NoticePage:_Confirm()
  self:_ClosePage()
  if self.callbackOk ~= nil then
    self.callbackOk(self.target)
  end
end

function NoticePage:DoOnHide()
  noticeManager:SetIsClose(true)
end

function NoticePage:DoOnClose()
  noticeManager:SetIsClose(true)
end

return NoticePage
