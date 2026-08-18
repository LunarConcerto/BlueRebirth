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
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_explain1, self._ClickExplain1, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_explain2, self._ClickExplain2, self)
end

function SubscribeInfoPage:_ClickSubscribe()
  if not self.param.subscribeIng then
    self.param.func(self.param.info)
  end
  UIHelper.ClosePage("subscribeInfoPage")
end

function SubscribeInfoPage:_LoadContent(tabParam)
  local os = platformManager:GetOS()
  self.tab_Widgets.obj_ios_explain:SetActive(os == "ios")
  self.tab_Widgets.obj_google_explain:SetActive(os ~= "ios")
  local subscribeIng = tabParam.subscribeIng
  self.tab_Widgets.btn_subscribe.gameObject:SetActive(not subscribeIng)
  self.tab_Widgets.obj_subscribing:SetActive(subscribeIng)
  UIHelper.SetText(self.tab_Widgets.text_price, tabParam.info.true_cost)
end

function SubscribeInfoPage:_ClickExplain1()
  if "" ~= self.tab_Widgets.txt_explain1.text then
    CS.Platform.openUrl(self.tab_Widgets.txt_explain1.text)
  end
end

function SubscribeInfoPage:_ClickExplain2()
  if "" ~= self.tab_Widgets.txt_explain2.text then
    CS.Platform.openUrl(self.tab_Widgets.txt_explain2.text)
  end
end

function SubscribeInfoPage:_ClickClose()
  UIHelper.ClosePage("subscribeInfoPage")
end

return SubscribeInfoPage
