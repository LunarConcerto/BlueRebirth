local SubscribeInfoPage = class("UI.Recharge.SubscribeInfoPage", LuaUIPage)

function SubscribeInfoPage:DoInit()
  self.m_tabWidgets = nil
end

function SubscribeInfoPage:DoOnOpen()
  self:_LoadContent(self.param)
end

function SubscribeInfoPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_subscribe, self._ClickSubscribe, self)
end

function SubscribeInfoPage:_ClickSubscribe()
  if not self.param.subscribeIng then
    self.param.func(self.param.info)
  end
  UIHelper.ClosePage("subscribeInfoPage")
end

function SubscribeInfoPage:_LoadContent(tabParam)
  local subscribeIng = tabParam.subscribeIng
  self.tab_Widgets.btn_subscribe.gameObject:SetActive(not subscribeIng)
  self.tab_Widgets.obj_subscribing:SetActive(subscribeIng)
  UIHelper.SetText(self.tab_Widgets.text_price, tabParam.info.cost)
end

function SubscribeInfoPage:_ClickClose()
  UIHelper.ClosePage("subscribeInfoPage")
end

return SubscribeInfoPage
