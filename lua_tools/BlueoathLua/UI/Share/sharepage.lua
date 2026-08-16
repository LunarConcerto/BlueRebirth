local SharePage = class("UI.Share.SharePage", LuaUIPage)

function SharePage:DoInit()
  self.tab_Widgets.btn_weibo.gameObject:SetActive(platformManager:ShowSharePlatform(ShareType.WeiBo))
  self.tab_Widgets.btn_weixin.gameObject:SetActive(platformManager:ShowSharePlatform(ShareType.WeiXin))
  self.tab_Widgets.btn_qqfriend.gameObject:SetActive(platformManager:ShowSharePlatform(ShareType.QQFriend))
  self.tab_Widgets.btn_qqzone.gameObject:SetActive(platformManager:ShowSharePlatform(ShareType.QQZone))
  self.tab_Widgets.btn_ssrWeibo.gameObject:SetActive(platformManager:ShowSharePlatform(ShareType.WeiBo))
  self.tab_Widgets.btn_ssrWeixin.gameObject:SetActive(platformManager:ShowSharePlatform(ShareType.WeiXin))
  self.tab_Widgets.btn_ssrQQFriend.gameObject:SetActive(platformManager:ShowSharePlatform(ShareType.QQFriend))
  self.tab_Widgets.btn_ssrQQZone.gameObject:SetActive(platformManager:ShowSharePlatform(ShareType.QQZone))
end

function SharePage:DoOnOpen()
  local pathType = self:GetParam()
  self:_InitSharePage(pathType)
end

function SharePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_weixin, self._ShareWeixin)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_weibo, self._ShareWeibo)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_qqfriend, self._ShareQQFriend)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_qqzone, self._ShareQQZone)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ssrWeixin, self._ShareWeixin)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ssrWeibo, self._ShareWeibo)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ssrQQFriend, self._ShareQQFriend)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ssrQQZone, self._ShareQQZone)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ssrClose, self._ClickClose)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
end

function SharePage:_InitSharePage(pathType)
  local widgets = self:GetWidgets()
  widgets.obj_common:SetActive(pathType == OpenSharePage.Other)
  widgets.obj_imgBGSSR:SetActive(pathType == OpenSharePage.ActSSR)
end

function SharePage:_ClickClose()
  shareManager:CloseShare()
end

function SharePage:_ShareOver()
  UIHelper.ClosePage("SharePage")
end

function SharePage:_ShareWeixin()
  shareManager:ShareToApp(ShareType.WeiXin)
end

function SharePage:_ShareWeibo()
  shareManager:ShareToApp(ShareType.WeiBo)
end

function SharePage:_ShareQQFriend()
  shareManager:ShareToApp(ShareType.QQFriend)
end

function SharePage:_ShareQQZone()
  shareManager:ShareToApp(ShareType.QQZone)
end

function SharePage:DoOnHide()
end

function SharePage:DoOnClose()
end

return SharePage
