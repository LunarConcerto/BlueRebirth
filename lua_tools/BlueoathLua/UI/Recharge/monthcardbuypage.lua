local MonthCardBuyPage = class("UI.Recharge.MonthCardBuyPage", LuaUIPage)

function MonthCardBuyPage:DoInit()
end

function MonthCardBuyPage:DoOnOpen()
  self:_LoadContent(self.param)
end

function MonthCardBuyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
end

function MonthCardBuyPage:_ClickClose()
  UIHelper.ClosePage("MonthCardBuyPage")
end

function MonthCardBuyPage:_BuyItem(go, param)
  self:_ClickClose()
  param.func(param.info)
end

function MonthCardBuyPage:_LoadContent(param)
  local info = param.info
  local days = param.days
  UIHelper.SetText(self.tab_Widgets.txtName, info.name)
  local strTab = string.split(info.desc, "<<n")
  UIHelper.CreateSubPart(self.tab_Widgets.obj_sub, self.tab_Widgets.trans_sub_list, #strTab, function(nIndex, tabPart)
    UIHelper.SetText(tabPart.text_sub, strTab[nIndex])
  end)
  local isBigMonth = info.paytype == RechargeItemType.BigMonthCard
  self.tab_Widgets.obj_month:SetActive(not isBigMonth)
  self.tab_Widgets.obj_bigmonth:SetActive(isBigMonth)
  local str = configManager.GetDataById("config_language", 270044).content
  if days then
    str = string.format(configManager.GetDataById("config_language", 430009).content, days)
  end
  UIHelper.SetText(self.tab_Widgets.textTime, str)
  self.tab_Widgets.btnBuy.gameObject:SetActive(false)
  self.tab_Widgets.btnSubscribe.gameObject:SetActive(false)
  self.tab_Widgets.btnSellout.gameObject:SetActive(false)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnBuy, self._BuyItem, self, param)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnSubscribe, self._BuyItem, self, param)
  if isBigMonth then
    self:_LoadBigMonthContent(info)
  else
    self:_LoadMonthCardConten(info)
  end
end

function MonthCardBuyPage:_LoadBigMonthContent(info)
  self.tab_Widgets.btnBuy.gameObject:SetActive(true)
  UIHelper.SetText(self.tab_Widgets.txt_bigmonth_cost, info.cost)
end

function MonthCardBuyPage:_LoadMonthCardConten(info)
  UIHelper.SetText(self.tab_Widgets.costInfo, info.cost)
  if platformManager:GetOS() == "android" then
    self.tab_Widgets.btnBuy.gameObject:SetActive(true)
  elseif platformManager:GetOS() == "ios" then
    if info.paytype == RechargeItemType.MonthCard then
      if days and days > 0 then
        self.tab_Widgets.btnSellout.gameObject:SetActive(true)
      else
        self.tab_Widgets.btnBuy.gameObject:SetActive(true)
      end
    elseif info.paytype == RechargeItemType.Subscribe then
      self.tab_Widgets.btnSubscribe.gameObject:SetActive(true)
    end
  end
end

return MonthCardBuyPage
