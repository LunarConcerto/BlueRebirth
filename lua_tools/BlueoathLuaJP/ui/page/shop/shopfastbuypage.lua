local ShopFastBuyPage = class("UI.Shop.ShopFastBuyPage", LuaUIPage)

function ShopFastBuyPage:DoInit()
  self.selectedTab = nil
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
end

function ShopFastBuyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_BtnOK, self._OnClickOk, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_BtnCancel, self._OnClickCancle, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._OnClickCancle, self)
  self:RegisterEvent(LuaEvent.ShopBuyFastSuccess, self._OnBuySuccess)
end

function ShopFastBuyPage:DoOnOpen()
  self.selectedTab = self:GetParam().selectedTab
  self:_LoadView()
end

function ShopFastBuyPage:_LoadView()
  local goodsTab = self:_DisposeSelectGoodsTab(self.selectedTab)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_itemContent, #goodsTab, function(index, uiPart)
    local goodInfo = goodsTab[index]
    UIHelper.SetText(uiPart.text_num, goodInfo.num)
    local icon = Logic.goodsLogic:GetIcon(goodInfo.id, goodInfo.type)
    UIHelper.SetImage(uiPart.img_icon, icon)
    local quality = Logic.goodsLogic:GetQuality(goodInfo.id, goodInfo.type)
    UIHelper.SetImage(uiPart.img_quality, QualityIcon[quality])
    local name = Logic.goodsLogic:GetName(goodInfo.id, goodInfo.type)
    UIHelper.SetText(uiPart.text_name, name)
  end)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_priceItem, self.tab_Widgets.trans_priceContent, #self.selectedTab.currencys, function(pindex, puiPart)
    local currency = self.selectedTab.currencys[pindex]
    local icon = Logic.currencyLogic:GetSmallIcon(currency.id)
    UIHelper.SetImage(puiPart.im_icon, icon)
    UIHelper.SetText(puiPart.tx_price, currency.num)
  end)
end

function ShopFastBuyPage:_DisposeSelectGoodsTab(selectGoodsTab)
  local selectedTab = clone(selectGoodsTab)
  local delTab = {}
  for i = 1, #selectedTab.goods do
    local goodInfo = selectedTab.goods[i]
    for j = i + 1, #selectedTab.goods do
      local temp = selectedTab.goods[j]
      if goodInfo and temp and goodInfo.id == temp.id and goodInfo.commodityId ~= temp.commodityId then
        goodInfo.num = goodInfo.num + temp.num
        table.remove(selectedTab.goods, j)
      end
    end
  end
  return selectedTab.goods
end

function ShopFastBuyPage:_OnClickOk()
  local commodityIdTab = {}
  for _, goodInfo in ipairs(self.selectedTab.goods) do
    table.insert(commodityIdTab, goodInfo.commodityId)
  end
  Service.shopService:SendQualityBuyGoods(self.selectedTab.shopId, commodityIdTab)
end

function ShopFastBuyPage:_OnClickCancle()
  UIHelper.ClosePage("ShopFastBuyPage")
end

function ShopFastBuyPage:_OnBuySuccess(param)
  noticeManager:ShowTipById(230006)
  UIHelper.ClosePage("ShopFastBuyPage")
end

function ShopFastBuyPage:DoOnHide()
end

function ShopFastBuyPage:DoOnClose()
end

return ShopFastBuyPage
