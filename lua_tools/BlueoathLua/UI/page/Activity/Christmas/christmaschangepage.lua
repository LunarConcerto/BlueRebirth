local ChristmasChangePage = class("ui.page.Activity.Christmas.ChristmasChangePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ChristmasChangePage:DoInit()
end

function ChristmasChangePage:DoOnOpen()
  self.mBuyWay = ACS_BUY_WAY.CUR
  self:ShowPage()
end

function ChristmasChangePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.CloseMySelf, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCancel, self.CloseMySelf, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self.ShowPage, self)
end

function ChristmasChangePage:DoOnHide()
end

function ChristmasChangePage:DoOnClose()
end

function ChristmasChangePage:ShowPage()
  local displayM1 = ItemInfoPage.GenDisplayData(GoodsType.CURRENCY, CurrencyType.GOLD)
  UIHelper.SetImage(self.tab_Widgets.imgIcon_M1, displayM1.icon)
  UIHelper.SetImage(self.tab_Widgets.imgQuality_M1, QualityIcon[displayM1.quality])
  local displayM2 = ItemInfoPage.GenDisplayData(GoodsType.ITEM, BLINDBOX_TOY_ID)
  UIHelper.SetImage(self.tab_Widgets.imgToy_M2, displayM2.icon)
  local costExchangeCur = configManager.GetDataById("config_parameter", 311).value
  UIHelper.SetLocText(self.tab_Widgets.textNum_M1, 710082, costExchangeCur)
  local costExchangeToy = configManager.GetDataById("config_parameter", 312).value
  UIHelper.SetLocText(self.tab_Widgets.textNum_M2, 710082, costExchangeToy)
  local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, BLINDBOX_CUR_ID)
  UIHelper.SetImage(self.tab_Widgets.imgBBMoney, display.icon)
  local display_Toy = ItemInfoPage.GenDisplayData(GoodsType.ITEM, BLINDBOX_TOY_ID)
  UIHelper.SetImage(self.tab_Widgets.imgBBToy, display_Toy.icon)
  local ownToyCount = Data.bagData:GetItemNum(BLINDBOX_TOY_ID)
  UIHelper.SetLocText(self.tab_Widgets.textBBToy, 710082, ownToyCount)
  local sendBuyFunc = function(times)
    local buyway = self.mBuyWay or ACS_BUY_WAY.CUR
    if buyway == ACS_BUY_WAY.CUR then
      local owncount = Data.userData:GetCurrency(CurrencyType.GOLD)
      if owncount < costExchangeCur * times then
        UIHelper.OpenPage("BuyResourcePage", BuyResource.Gold)
        return
      end
    else
      logError("err buy way", buyway)
      return
    end
    Service.activitychristmasshopService:SendBuyBlindItem({BuyWay = buyway, BuyTimes = times})
  end
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnOk_1, function()
    sendBuyFunc(1)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnOk_10, function()
    sendBuyFunc(10)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnMethod1, function()
    self.mBuyWay = ACS_BUY_WAY.CUR
    self:ShowBuyWay()
  end)
  self:ShowBuyWay()
end

function ChristmasChangePage:ShowBuyWay()
  local buyway = self.mBuyWay or ACS_BUY_WAY.CUR
end

function ChristmasChangePage:CloseMySelf()
  UIHelper.ClosePage(self:GetName())
end

return ChristmasChangePage
