local ShopItemInfoPage = class("UI.Shop.ShopItemInfoPage")
local ONCE_MAX_NUM = 10
local ONCE_MIN_NUM = 1

function ShopItemInfoPage:Init(page, widgets)
  self.page = page
  self.tab_Widgets = widgets
  self.useDiscount = false
  self.useDisInfoTab = {}
  self.ownSameDisc = {}
end

function ShopItemInfoPage:ShowItemInfo(data)
  if data.goodData.goods[1] == GoodsType.CURRENCY then
    self.tab_Widgets.txt_repertory.gameObject:SetActive(true)
  else
    local tableInfo = Logic.shopLogic:GetTableIndexConfById(data.goodData.goods[1])
    self.tab_Widgets.txt_repertory.gameObject:SetActive(tableInfo.bag_index ~= 0)
  end
  self.tab_Widgets.obj_price:SetActive(true)
  local price = data.goodData.price2[1]
  local icon = Logic.goodsLogic:GetSmallIcon(price[2], price[1])
  UIHelper.SetImage(self.tab_Widgets.im_expendIcon, tostring(icon), true)
  self.tab_Widgets.im_expendIcon.gameObject:SetActive(price[2] ~= CurrencyType.RMB)
  self.tab_Widgets.tx_money:SetActive(price[2] == CurrencyType.RMB)
  self.tab_Widgets.txt_price.text = price[3]
  self.tab_Widgets.im_expendIcon2.gameObject:SetActive(#data.goodData.price2 == 2)
  self.tab_Widgets.tx_money2.gameObject:SetActive(#data.goodData.price2 == 2)
  self.tab_Widgets.txt_price2.gameObject:SetActive(#data.goodData.price2 == 2)
  if #data.goodData.price2 == 2 then
    local price2 = data.goodData.price2[2]
    local icon2 = Logic.goodsLogic:GetSmallIcon(price2[2], price2[1])
    UIHelper.SetImage(self.tab_Widgets.im_expendIcon2, tostring(icon2), true)
    self.tab_Widgets.im_expendIcon2.gameObject:SetActive(price2[2] ~= CurrencyType.RMB)
    self.tab_Widgets.tx_money2.gameObject:SetActive(price2[2] == CurrencyType.RMB)
    self.tab_Widgets.txt_price2.text = price2[3]
  end
  self:ShowBatchBuy(data)
  self:ShowDiscount(data, price)
end

function ShopItemInfoPage:ShowBatchBuy(data)
  if data.isBatch then
    self.tab_Widgets.obj_batch.gameObject:SetActive(true)
    self.tab_Widgets.txt_buyNum.text = data.totalBuyNum
    self.tab_Widgets.txt_sigleNum.text = "x" .. data.buyNum
    self.tab_Widgets.txt_addNum.text = "+" .. data.goodData.is_buy_batch
    self.tab_Widgets.txt_subNum.text = "-" .. data.goodData.is_buy_batch
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_leftButton, function()
      self:_ClickSubBuyNum(ONCE_MIN_NUM, data)
    end)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rightButton, function()
      self:_ClickAddBuyNum(ONCE_MIN_NUM, data)
    end)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_addTen, function()
      self:_ClickAddBuyNum(data.goodData.is_buy_batch, data)
    end)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_batchBuy, function()
      self:ClickBuyGoods(data)
    end)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_subTen, function()
      self:_ClickSubBuyNum(data.goodData.is_buy_batch, data)
    end)
  else
    self.tab_Widgets.obj_batch.gameObject:SetActive(false)
  end
end

function ShopItemInfoPage:ShowDiscount(data, price)
  local discountInfo = Logic.shopLogic:GetUsableDiscountConf(data.goodsId)
  self.tab_Widgets.obj_sale:SetActive(discountInfo ~= nil)
  if discountInfo ~= nil then
    if #data.goodData.price2 == 2 then
      logError("\229\143\140\232\180\167\229\184\129\228\184\141\230\148\175\230\140\129\230\138\152\230\137\163\229\136\184")
      return
    end
    self.tab_Widgets.tog_sale.isOn = true
    self.useDiscount = true
    self.ownSameDisc = Logic.bagLogic:GetPeriodItemByTid(discountInfo.data.templateId)
    self.useDisInfoTab[1] = discountInfo
    self.tab_Widgets.tog_sale.gameObject:SetActive(discountInfo.config.discount_type == DiscountType.Universal)
    self.tab_Widgets.tx_saleCost.text = Logic.shopLogic:GetDiscountPrice(price[3], discountInfo)
    local saleStr = data.isBatch and string.format(UIHelper.GetString(2800003), data.totalBuyNum, discountInfo.config.name) or string.format(UIHelper.GetString(2800002), discountInfo.config.name)
    self.tab_Widgets.tx_sale.text = saleStr
  end
end

function ShopItemInfoPage:_ClickSubBuyNum(subNum, data)
  if #data.goodData.price2 == 2 then
    logError("\229\143\140\232\180\167\229\184\129\228\184\141\230\148\175\230\140\129\230\137\185\233\135\143\232\180\173\228\185\176")
    return
  end
  local minNum = ONCE_MIN_NUM
  local temp = data.totalBuyNum - minNum * subNum
  if minNum > temp and data.totalBuyNum == minNum then
    noticeManager:OpenTipPage(self, 270018)
    return
  elseif minNum >= temp then
    data.totalBuyNum = minNum
  else
    data.totalBuyNum = temp
  end
  self.tab_Widgets.txt_buyNum.text = data.totalBuyNum
  self.tab_Widgets.txt_price.text = data.goodData.price2[1][3] * data.totalBuyNum
  self:ShowDiscountCost(data)
end

function ShopItemInfoPage:_ClickAddBuyNum(addNum, data)
  if #data.goodData.price2 == 2 then
    logError("\229\143\140\232\180\167\229\184\129\228\184\141\230\148\175\230\140\129\230\137\185\233\135\143\232\180\173\228\185\176")
    return
  end
  local minNum = ONCE_MIN_NUM
  local maxNum = Logic.shopLogic:GetBuyMaxNum(data, data.id, self.ownSameDisc)
  local temp = 0
  if data.totalBuyNum == ONCE_MIN_NUM and addNum == data.goodData.is_buy_batch then
    temp = minNum * addNum
  else
    temp = data.totalBuyNum + minNum * addNum
  end
  if maxNum < temp and data.totalBuyNum == maxNum then
    noticeManager:OpenTipPage(self, 270019)
    return
  elseif maxNum <= temp and maxNum > data.totalBuyNum then
    data.totalBuyNum = maxNum
  else
    data.totalBuyNum = temp
  end
  self.tab_Widgets.txt_buyNum.text = data.totalBuyNum
  self.tab_Widgets.txt_price.text = data.goodData.price2[1][3] * data.totalBuyNum
  self:ShowDiscountCost(data)
end

function ShopItemInfoPage:ShowDiscountCost(data)
  if #self.useDisInfoTab ~= 0 then
    if #self.ownSameDisc <= data.totalBuyNum then
      self.useDisInfoTab = self.ownSameDisc
    elseif #self.ownSameDisc > data.totalBuyNum then
      self.useDisInfoTab = {}
      for i = 1, data.totalBuyNum do
        table.insert(self.useDisInfoTab, self.ownSameDisc[1])
      end
    end
    local sale = Logic.shopLogic:GetDiscountPrice(data.goodData.price2[1][3], self.useDisInfoTab[1])
    self.tab_Widgets.tx_saleCost.text = sale * #self.useDisInfoTab + data.goodData.price2[1][3] * (data.totalBuyNum - #self.useDisInfoTab)
    local saleStr = data.isBatch and string.format(UIHelper.GetString(2800003), #self.useDisInfoTab, self.useDisInfoTab[1].config.name) or string.format(UIHelper.GetString(2800002), self.useDisInfoTab[1].config.name)
    self.tab_Widgets.tx_sale.text = saleStr
  end
end

function ShopItemInfoPage:ClickBuyGoods(param)
  local tableInfo = Logic.shopLogic:GetTableIndexConfById(param.goodData.goods[1])
  if param.goodData.goods[1] == GoodsType.EQUIP then
    if not Logic.rewardLogic:CanGotEquip(param.totalBuyNum * param.buyNum) then
      return
    end
  elseif param.goodData.goods[1] == GoodsType.EXPAND_ITEM then
    if not Logic.shopLogic:CanExpandById(param.id) then
      return
    end
  elseif param.goodData.goods[1] == GoodsType.SHIP and not Logic.rewardLogic:CanGotShip(param.totalBuyNum * param.buyNum) then
    return
  end
  if param.goodData.recharge_id ~= 0 then
    if Logic.shopLogic:CheckBuyGoodsCondition(param.shopId, param.goodData) then
      platformManager:buyShopItem(param.shopId, param.gridId, param.buyNum, param.goodsId, param.name)
      UIHelper.ClosePage("ItemInfoPage")
    end
    return
  end
  if #self.useDisInfoTab ~= 0 and self.useDiscount then
    local valid, inProideId = Logic.shopLogic:CheckDiscountProide(self.useDisInfoTab)
    if valid then
      param.discountId = inProideId
    else
      UIHelper.ClosePage("ItemInfoPage")
      return
    end
  end
  local discountTab = self.useDiscount and self.useDisInfoTab or {}
  local tabCondition = Logic.shopLogic:GetTableBuyCurrency(param.goodData.price2, param.totalBuyNum, discountTab)
  local isCan = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
  if isCan then
    if Logic.shopLogic:CheckBuyGoodsCondition(param.shopId, param.goodData) then
      Service.shopService:SendBuyGoods(param.shopId, param.goodData.id, param.totalBuyNum, param.discountId)
      UIHelper.ClosePage("ItemInfoPage")
    else
      noticeManager:OpenTipPage(self, UIHelper.GetString(4200002))
      UIHelper.ClosePage("ItemInfoPage")
      return
    end
  end
end

function ShopItemInfoPage:_UseDiscount()
  self.useDiscount = self.tab_Widgets.tog_sale.isOn
end

return ShopItemInfoPage
