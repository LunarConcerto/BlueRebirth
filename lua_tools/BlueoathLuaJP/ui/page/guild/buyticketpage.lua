local BuyTicketPage = class("UI.Guild.BuyTicketPage", LuaUIPage)

function BuyTicketPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function BuyTicketPage:DoOnOpen()
  self.param = self:GetParam()
  self:LoadCfgInfo()
  self:LoadContentInfo()
end

function BuyTicketPage:LoadCfgInfo()
  self.configInfo = configManager.GetData("config_guildoffer_info")[1]
end

function BuyTicketPage:LoadContentInfo()
  local userOfferInfo = Data.guildOfferData:GetUserOfferInfo()
  self.currentBuyCount = userOfferInfo.DailyBuyCount
  UIHelper.SetText(self.m_tabWidgets.txt_hint, UIHelper.GetString(3700021) .. self.currentBuyCount .. "/" .. self.configInfo.maxbuytime)
  local costNum = self:GetOfferCost(self.currentBuyCount)
  UIHelper.SetText(self.m_tabWidgets.txt_currencyNum, costNum)
end

function BuyTicketPage:GetOfferCost(hasBuyCount)
  return math.ceil(self.configInfo.ticketprice[2] + hasBuyCount * self.configInfo.priceincrease)
end

function BuyTicketPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, function()
    UIHelper.ClosePage("BuyTicketPage")
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, function()
    UIHelper.ClosePage("BuyTicketPage")
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_true, function()
    eventManager:RegisterEvent(LuaEvent.UpdateGuildOfferUserInfo, self.UpdateGuildOfferUserInfo, self)
    Service.guildService:SendGuildOfferUserInfo()
  end)
  self:RegisterEvent(LuaEvent.UpdateUserGOTaskCount, self.UpdatePage, self)
end

function BuyTicketPage:UpdateGuildOfferUserInfo()
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildOfferUserInfo, self.UpdateGuildOfferUserInfo, self)
  local userInfo = Data.guildOfferData:GetUserOfferInfo()
  if userInfo.DailyBuyCount == self.currentBuyCount then
    if userInfo.DailyBuyCount >= self.configInfo.maxbuytime then
      noticeManager:ShowTip(UIHelper.GetString(3700023))
      UIHelper.ClosePage("BuyTicketPage")
      return
    end
    self:BuyCount()
  else
    self:LoadContentInfo()
  end
end

function BuyTicketPage:BuyCount()
  local currencyNum = Data.userData:GetCurrency(self.configInfo.ticketprice[1])
  local costNum = self:GetOfferCost(self.currentBuyCount)
  if currencyNum >= costNum then
    Service.guildService:SendBuyOffer(1)
  else
    noticeManager:ShowTip(UIHelper.GetString(230008))
  end
end

function BuyTicketPage:UpdatePage()
  UIHelper.ClosePage("BuyTicketPage")
end

function BuyTicketPage:DoOnHide()
end

function BuyTicketPage:DoOnClose()
end

return BuyTicketPage
