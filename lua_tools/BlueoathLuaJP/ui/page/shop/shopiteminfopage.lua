local ShopItemInfoPage = class("UI.Shop.ShopItemInfoPage")
local ONCE_MAX_NUM = 10
local ONCE_MIN_NUM = 1

function ShopItemInfoPage:Init(page, widgets)
  self.page = page
  self.tab_Widgets = widgets
  self.data = nil
  self.selectCurrTab = {}
  self.priceItem = {}
  self.priceIndex = -1
  self.goodsSerData = nil
end

function ShopItemInfoPage:ShowItemInfo(data)
  self.data = data
  self.goodsSerData = data.goodsSerData
  if self.data.goodData.goods[1] == GoodsType.CURRENCY then
    self.tab_Widgets.txt_repertory.gameObject:SetActive(true)
  else
    local tableInfo = Logic.shopLogic:GetTableIndexConfById(self.data.goodData.goods[1])
    self.tab_Widgets.txt_repertory.gameObject:SetActive(tableInfo.bag_index ~= 0)
  end
  self:_ShowCurrencyInfo()
  self:_SetAllPrice()
  self:ShowBatchBuy()
end

function ShopItemInfoPage:_ShowCurrencyInfo()
  self.tab_Widgets.obj_price:SetActive(true)
  self.selectCurrTab = self.data.goodData.currency
  self:_CreateCurrency()
end

function ShopItemInfoPage:_CreateCurrency()
  self.priceItem = {}
  UIHelper.CreateSubPart(self.tab_Widgets.obj_priceItem, self.tab_Widgets.trans_price, #self.selectCurrTab, function(nIndex, tabPart)
    local currencyInfo = self.selectCurrTab[nIndex]
    local currType = currencyInfo[1]
    local currencyId = currencyInfo[2]
    local selectPrice = self.priceIndex == -1 and nIndex or self.priceIndex + 1
    local pIndex = #self.data.goodData.price[selectPrice] < self.goodsSerData.Num + 1 and #self.data.goodData.price[selectPrice] or self.goodsSerData.Num + 1
    local price = self.data.goodData.price[selectPrice][pIndex]
    local icon = Logic.goodsLogic:GetSmallIcon(currencyId, currType)
    UIHelper.SetImage(tabPart.im_currIcon, tostring(icon), true)
    tabPart.txt_price.text = price
    tabPart.im_currIcon.gameObject:SetActive(currencyId ~= CurrencyType.RMB)
    tabPart.tx_money:SetActive(currencyId == CurrencyType.RMB)
    if self.data.goodData.cur_relation == 2 then
      tabPart.tog_payway.gameObject:SetActive(true)
      self.tab_Widgets.tog_group:RegisterToggle(tabPart.tog_payway)
    end
    table.insert(self.priceItem, tabPart)
  end)
  if self.data.goodData.cur_relation == 2 then
    UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
    self.tab_Widgets.tog_group:SetActiveToggleIndex(0)
  end
end

function ShopItemInfoPage:_SwitchTogs(index)
  if self.priceIndex ~= -1 then
    self.data.totalBuyNum = 1
    self.tab_Widgets.txt_buyNum.text = self.data.totalBuyNum
    local price = Logic.shopLogic:GetPriceByNum(self.data.goodData.price[self.priceIndex + 1], self.goodsSerData.Num, self.data.totalBuyNum)
    self.priceItem[self.priceIndex + 1].txt_price.text = price
  end
  self.priceIndex = index
  self.selectCurrTab = {
    self.data.goodData.currency[index + 1]
  }
  self:_SetAllPrice()
end

function ShopItemInfoPage:ShowBatchBuy()
  if self.data.isBatch then
    self.tab_Widgets.obj_batch.gameObject:SetActive(true)
    self.tab_Widgets.txt_buyNum.text = self.data.totalBuyNum
    self.tab_Widgets.txt_sigleNum.text = "x" .. self.data.buyNum
    self.tab_Widgets.txt_addNum.text = "+" .. self.data.goodData.is_buy_batch
    self.tab_Widgets.txt_subNum.text = "-" .. self.data.goodData.is_buy_batch
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_leftButton, function()
      self:_ClickSubBuyNum(ONCE_MIN_NUM)
    end)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rightButton, function()
      self:_ClickAddBuyNum(ONCE_MIN_NUM)
    end)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_addTen, function()
      self:_ClickAddBuyNum(self.data.goodData.is_buy_batch)
    end)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_batchBuy, function()
      self:ClickBuyGoods(self.data)
    end)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_subTen, function()
      self:_ClickSubBuyNum(self.data.goodData.is_buy_batch)
    end)
  else
    self.tab_Widgets.obj_batch.gameObject:SetActive(false)
  end
end

function ShopItemInfoPage:_ClickSubBuyNum(subNum, data)
  local minNum = ONCE_MIN_NUM
  local temp = self.data.totalBuyNum - minNum * subNum
  if minNum > temp and self.data.totalBuyNum == minNum then
    noticeManager:OpenTipPage(self, 270018)
    return
  elseif minNum >= temp then
    self.data.totalBuyNum = minNum
  else
    self.data.totalBuyNum = temp
  end
  self.tab_Widgets.txt_buyNum.text = self.data.totalBuyNum
  self:_SetAllPrice()
end

function ShopItemInfoPage:_ClickAddBuyNum(addNum, data)
  local minNum = ONCE_MIN_NUM
  local maxNum = Logic.shopLogic:GetBuyMaxNum(self.data, self.data.id, self.priceIndex + 1)
  local temp = 0
  if self.data.totalBuyNum == ONCE_MIN_NUM and addNum == self.data.goodData.is_buy_batch then
    temp = minNum * addNum
  else
    temp = self.data.totalBuyNum + minNum * addNum
  end
  if maxNum < temp and self.data.totalBuyNum == maxNum then
    noticeManager:OpenTipPage(self, 270019)
    return
  elseif maxNum <= temp and maxNum > self.data.totalBuyNum then
    self.data.totalBuyNum = maxNum
  else
    self.data.totalBuyNum = temp
  end
  self.tab_Widgets.txt_buyNum.text = self.data.totalBuyNum
  self:_SetAllPrice()
end

function ShopItemInfoPage:_SetAllPrice()
  for i, v in ipairs(self.selectCurrTab) do
    if self.priceItem[i] ~= nil then
      local priceTab = self.priceIndex ~= -1 and self.data.goodData.price[self.priceIndex + 1] or self.data.goodData.price[i]
      local price = Logic.shopLogic:GetPriceByNum(priceTab, self.goodsSerData.Num, self.data.totalBuyNum)
      v[3] = price
      local selectPrice = self.priceIndex == -1 and i or self.priceIndex + 1
      self.priceItem[selectPrice].txt_price.text = price
    end
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
  local tabCondition = Logic.shopLogic:GetTableBuyCurrency(self.selectCurrTab)
  local isCan = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
  if isCan then
    if Logic.shopLogic:CheckBuyGoodsCondition(param.shopId, param.goodData) then
      self.priceIndex = self.priceIndex ~= -1 and self.priceIndex or nil
      Service.shopService:SendBuyGoods(param.shopId, param.goodData.id, param.totalBuyNum, self.priceIndex)
      UIHelper.ClosePage("ItemInfoPage")
    else
      noticeManager:OpenTipPage(self, UIHelper.GetString(4200002))
      UIHelper.ClosePage("ItemInfoPage")
      return
    end
  end
end

return ShopItemInfoPage
