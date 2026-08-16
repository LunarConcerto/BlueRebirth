SettlementNoticePage = class("UI.SettlementNoticePage", LuaUIPage)

function SettlementNoticePage:DoInit()
  self.m_tabWidgets = nil
end

function SettlementNoticePage:DoOnOpen()
  noticeManager:SetIsClose(false)
  self.m_tabParam = self:GetParam()
  self:_LoadNotice(self.m_tabParam)
end

function SettlementNoticePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdataNotice, self._LoadNotice, self)
end

function SettlementNoticePage:_LoadNotice(tabParam)
  if tabParam == nil then
    UIHelper.ClosePage("SettlementNoticePage")
  else
    self:_DealParams(tabParam)
    local m_type = tabParam.msgType
    if m_type == nil then
      self:_ShowMsgBoxOneButton(self.content, self.nameok)
    elseif m_type == NoticeType.TwoButton then
      self:_ShowMsgBoxTwoButton(self.content, self.nameok, self.namecancel)
    end
  end
end

function SettlementNoticePage:_ShowMsgBoxTwoButton(content, nameok, namecancel)
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

function SettlementNoticePage:_DealParams(tabParam)
  self.content = tabParam.content or ""
  self.target = tabParam.target
  self.callbackOk = tabParam.callbackOk
  self.callbackCancel = tabParam.callbackCancel
  self.nameok = tabParam.nameOk or "\231\161\174\229\174\154"
  self.namecancel = tabParam.nameCancel or "\229\143\150\230\182\136"
  self.guidedefineId = tabParam.guidedefineId
end

function SettlementNoticePage:_ClosePage()
  eventManager:SendEvent(LuaEvent.CloseNotice)
end

function SettlementNoticePage:_Cancel()
  self:_ClosePage()
  if self.callbackCancel ~= nil then
    self.callbackCancel(self.target)
  end
end

function SettlementNoticePage:_Confirm()
  self:_ClosePage()
  if self.callbackOk ~= nil then
    self.callbackOk(self.target)
  end
end

function SettlementNoticePage:DoOnHide()
  noticeManager:SetIsClose(true)
end

function SettlementNoticePage:DoOnClose()
  noticeManager:SetIsClose(true)
end

return SettlementNoticePage
