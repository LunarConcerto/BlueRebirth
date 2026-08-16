local ShopPage = class("UI.Shop.ShopPage", LuaUIPage)
local ShopItem = require("ui.page.Shop.ShopItemShow")
local ShopList = require("ui.page.Shop.ShopListShow")
local RechargeView = require("ui.page.Recharge.RechargePage")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local SHOW_BUY_GOOD = 1
local MONTH_CARD_ID = 1004
local MONTH_IOS_CARD_ID = 1003
local BIG_MONTH_CARD_ID = 1005
local ShopModel = {
  [ShopShelfType.ShopShelf] = 96,
  [ShopShelfType.SupplyShelf] = 122
}
local onBuyBehaviour = {
  "shop_buy1",
  "shop_buy1_1",
  "shop_buy1_2"
}
local onClickBehaviour = {
  "shop_click1",
  "shop_click2",
  "shop_click3"
}

function ShopPage:DoInit()
  self.m_tabSerShopsInfo = nil
  self.m_Timer = nil
  self.shopItemView = ShopItem:new(self)
  self.rechargeView = RechargeView:new(self)
  self.shopList, _ = Logic.shopLogic:GetShowShopInfo()
  self.showCumuRecharge = false
  UIHelper.AdapteShipRT(self.tab_Widgets.trans_girl)
  self:InitShopToggle(self.shopList)
  self:InitRecommendToggle()
end

function ShopPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetShopsInfoMsg, self._GetShopsInfoCallBack, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_entrance, self._OnGiftClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_goods1, self._OnGoods1Click, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_goods2, self._OnGoods2Click, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_monthCard, self._OnMonthCardClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_girl, self._OnGirlClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_check, self._CheckPrivilege, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_iosCheck, self._CheckPrivilege, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._ClickHelper, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_iosAutoBuy, self._OnSubMonthCardClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_iosBuy, self._OnMonthCardClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_bigmonth_check, self._CheckBigMonthCardPrivilege, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_bigmonth, self._OnBigMonthCardClick, self)
  self:RegisterEvent(LuaCSharpEvent.ShowSubtitle, self._ShowSubtitle, self)
  self:RegisterEvent(LuaCSharpEvent.CloseSubtitle, self._CloseSubtitle, self)
  self:RegisterEvent(LuaEvent.UpdataRechargeInfo, self.OnBuySuccess, self)
  self:RegisterEvent(LuaEvent.RechargeGetRewards, self._ShowRechargeRewards, self)
  self:RegisterEvent(LuaEvent.GetBuyGoodsMsg, self.BuyGoodsCallBack, self)
  self:RegisterEvent(LuaEvent.ToRechargeShop, self.ToRechargeShop, self)
  self:RegisterEvent(LuaEvent.UpdateShopInfo, self.UpdateShopInfo, self)
  self:RegisterEvent(LuaEvent.FreeSubscribeStateCallBack, self._UpdateFreeState, self)
end

function ShopPage:DoOnOpen()
  self:OpenTopPage("ShopPage", 1, "\229\149\134\229\186\151", self, false)
  if Data.copyData:GetMatchingState() then
    noticeManager:ShowTip(UIHelper.GetString(6100012))
    Data.copyData:SetMatchingState(false)
    local arg = {
      uid = Data.userData:GetUserData().Uid
    }
    Service.matchService:SendMatchLeave(arg)
  end
  self.tab_Widgets.obj_bgText:SetActive(false)
  local params = self:GetParam()
  local isActivity = params and params.isActivity
  if isActivity then
    SoundManager.Instance:PlayMusic("System|Shop")
    eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
      TitleName = "\230\180\187\229\138\168\229\149\134\229\186\151"
    })
  end
  local shopId = params and params.shopId
  if shopId then
    self.shopId = shopId
  end
  if self.leavingShopId then
    self.shopId = self.leavingShopId
  end
  if self.shopId and not Logic.shopLogic:IsOpenByShopId(self.shopId, false) then
    self.shopId = ShopId.Recommand
  end
  local infoid = configManager.GetDataById("config_parameter", ShopModel[ShopShelfType.ShopShelf]).value
  self:_LoadShipModel(infoid)
  if shopId ~= ShopId.Recharge and shopId ~= ShopId.Gift and shopId ~= ShopId.LuckyRecharge then
    self:SelectShopOnOpen()
  end
  Service.shopService:SendGetShopsInfo()
  self:_DotInfo(self.shopId ~= nil)
  if not self.leavingShopId then
    self:PlayBehaviour("shop_go")
  end
end

function ShopPage:InitShopToggle(shopList)
  self.shopIdIndexMap = {}
  local widgets = self.tab_Widgets
  UIHelper.CreateSubPart(widgets.obj_listItem, widgets.trans_listContent, #shopList, function(index, luaPart)
    local shopData = shopList[index]
    self.shopIdIndexMap[shopData.id] = index
    UIHelper.SetText(luaPart.name, shopData.name)
    widgets.toggle_group:RegisterToggle(luaPart.toggle)
    UIHelper.SetImage(luaPart.icon, shopData.icon)
    UIHelper.SetImage(luaPart.icon_select, shopData.icon_select)
    if #shopData.red_dot > 0 then
      self:RegisterRedDotById(luaPart.red_dot, shopData.red_dot, shopData.red_dot[1], {1, 2})
    end
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.toggle_group, self, nil, self.OnShopToggle)
end

function ShopPage:SelectShopOnOpen()
  if self.shopId then
    local shopConfig = configManager.GetDataById("config_shop", self.shopId)
    local period = shopConfig.open_period
    local shopData = Data.shopData:GetShopDataById(self.shopId)
    if 0 < period and not shopData then
      Service.shopService:SendGetShopsInfo()
    else
      self:SelectShopById(self.shopId)
    end
  else
    self:SelectShopByIndex(1)
  end
end

function ShopPage:SelectShopById(shopId)
  local shop = configManager.GetDataById("config_shop", shopId)
  if shop.shop_type > 1 then
    self.subShopId = shopId
  end
  shopId = self:_GetLv1ShopId(shopId)
  local index = self.shopIdIndexMap[shopId]
  self.tab_Widgets.toggle_group:SetActiveToggleIndex(index - 1)
  self:FixScrollPosition(index, #self.shopList)
end

function ShopPage:_GetLv1ShopId(shopId)
  local shop = configManager.GetDataById("config_shop", shopId)
  if shop.shop_type == 1 then
    return shopId
  end
  if shop.shop_type > 1 then
    return self:_GetLv1ShopId(shop.dependence_id)
  end
end

function ShopPage:SelectShopByIndex(index)
  self.tab_Widgets.toggle_group:SetActiveToggleIndex(index - 1)
end

function ShopPage:OnShopToggle(index)
  local shopInfo = self.shopList[index + 1]
  local shopId = shopInfo.id
  self:CloseSubPage("CumulativeRechargePage")
  self:ChangeShopShow(shopId)
  self.showCumuRecharge = false
end

function ShopPage:SetLeavingShopId()
  self.leavingShopId = self.shopId
end

function ShopPage:ChangeShopShow(shopIdL1)
  if not self.subShopId then
    self.shopId = shopIdL1
  end
  self.buyGift = nil
  self:OnShopChanged(self.shopId)
  local shopCfg = configManager.GetDataById("config_shop", shopIdL1)
  local funType = shopCfg.fun_type
  self.tab_Widgets.obj_giftTips:SetActive(false)
  self.isRecommend = false
  if funType == -1 then
    self.tab_Widgets.obj_xiaofei:SetActive(true)
    self.isRecommend = true
    self:ShowRecommendPanel()
    self.shopItemView:Close()
    self.tab_Widgets.obj_itemInfoActivity:SetActive(false)
    self.tab_Widgets.obj_itemInfo:SetActive(false)
    self.tab_Widgets.obj_giftShop:SetActive(false)
    self.rechargeView:Hide()
    self:UpdateRecommendPanel()
    eventManager:SendEvent(LuaEvent.TopUpdateCurrency, shopCfg.currency_show)
  elseif funType == 2 then
    self.tab_Widgets.obj_xiaofei:SetActive(true)
    self.shopItemView:Close()
    self.tab_Widgets.obj_itemInfoActivity:SetActive(false)
    self.tab_Widgets.obj_itemInfo:SetActive(false)
    self:HideRecommendPanel()
    eventManager:SendEvent(LuaEvent.TopUpdateCurrency, shopCfg.currency_show)
    local rechargeId = self.param and self.param.rechargeId or nil
    self.rechargeView:Hide()
    self.rechargeView:Show(shopIdL1, self.subShopId, rechargeId)
    if self.param and self.param.rechargeId then
      self.param.rechargeId = nil
    end
  else
    self.tab_Widgets.obj_xiaofei:SetActive(false)
    self.tab_Widgets.obj_giftShop:SetActive(false)
    self.tab_Widgets.obj_itemInfo:SetActive(true)
    self.tab_Widgets.obj_itemInfoActivity:SetActive(true)
    self.shopItemView:Close()
    self.shopItemView:Show({
      shopId = shopIdL1,
      subShopId = self.subShopId
    })
    self.rechargeView:Hide()
    self:HideRecommendPanel()
  end
  self.subShopId = nil
end

function ShopPage:_OnGiftClick()
  local shopInfo = configManager.GetDataById("config_shop", self.shopId)
  if shopInfo.jump_shop_id > -1 then
    self:SelectShopById(shopInfo.jump_shop_id)
  end
end

function ShopPage:_OnGoods1Click()
  local goods = Logic.shopLogic:GetRecommendShopGoods()
  if not goods[1] then
    return
  end
  if not self:_checkBuyPeriod(goods[1]) then
    return
  end
  if goods[1].paytype == RechargeItemType.BigMonthCard then
    self:ShowRecharge(goods[1])
  else
    self:ShowGiftInfo(goods[1])
  end
end

function ShopPage:_OnGoods2Click()
  local goods = Logic.shopLogic:GetRecommendShopGoods()
  if not goods[2] then
    return
  end
  if not self:_checkBuyPeriod(goods[2]) then
    return
  end
  if goods[2].paytype == RechargeItemType.BigMonthCard then
    self:ShowRecharge(goods[2])
  else
    self:ShowGiftInfo(goods[2])
  end
end

function ShopPage:_checkBuyPeriod(good)
  if good.paytype ~= nil then
    return true
  end
  local isInPeriod = #goodData.period_buy <= 0
  if #goodData.period_buy > 0 then
    for _, perId in pairs(goodData.period_buy) do
      if PeriodManager:IsInPeriod(perId) then
        isInPeriod = true
        break
      end
    end
  end
  if not isInPeriod then
    Logic.shopLogic:ShowPeriodEndTips(goodData.period_show)
    return false
  end
  return true
end

function ShopPage:_OnMonthCardClick()
  local monthCard = self.monthCard
  if monthCard then
    self:ShowRecharge(monthCard)
  end
end

function ShopPage:_OnSubMonthCardClick()
  local monthCard = self.subscribeCard
  if monthCard then
    self:ShowRecharge(monthCard)
  end
end

function ShopPage:_CheckPrivilege()
  local monthCard = self.monthCard
  if monthCard then
    UIHelper.OpenPage("PrivilegePage", monthCard.privilegedesc)
  end
end

function ShopPage:_CheckBigMonthCardPrivilege()
  if self.bigmonthCard then
    UIHelper.OpenPage("PrivilegePage", self.bigmonthCard.privilegedesc)
  end
end

function ShopPage:_OnBigMonthCardClick()
  if self.bigmonthCard then
    self:ShowRecharge(self.bigmonthCard)
  end
end

function ShopPage:ShowRecharge(rechargeCfg)
  local args = {}
  
  function args.func(param)
    eventManager:SendEvent(LuaEvent.BuyRechargeItem, rechargeCfg)
  end
  
  local days = Logic.rechargeLogic:GetDaysRemaining(rechargeCfg.id)
  if days and 0 < days then
    args.days = days
  end
  args.info = rechargeCfg
  self.buyGift = rechargeCfg
  UIHelper.OpenPage("MonthCardBuyPage", args)
end

function ShopPage:ShowGiftInfo(info)
  local shopId = self.shopId
  local shopInfo = configManager.GetDataById("config_shop", self.shopId)
  if shopInfo.jump_shop_id ~= -1 then
    shopId = shopInfo.jump_shop_id
  end
  local realShopId = shopInfo.jump_shop_id
  if self.isRecommend then
    self.buyGift = info
  end
  UIHelper.OpenPage("GiftInfoPage", {configData = info, shopId = shopId})
end

function ShopPage:_ShowSubtitle(content)
  if self.showCumuRecharge then
    return
  end
  UIHelper.SetText(self.tab_Widgets.txt_girl, content)
  self.tab_Widgets.obj_bgText:SetActive(true)
end

function ShopPage:_CloseSubtitle()
  self.tab_Widgets.obj_bgText:SetActive(false)
end

function ShopPage:InitRecommendToggle()
  local widgets = self.tab_Widgets
  widgets.obj_toggleGroup:SetActive(true)
  local shopList = self.shopList[1].subShops
  UIHelper.CreateSubPart(widgets.obj_subItem, widgets.trans_subList, #shopList, function(index, luaPart)
    local shopData = shopList[index]
    UIHelper.SetText(luaPart.name, shopData.name)
    widgets.sub_toggleGroup:RegisterToggle(luaPart.toggle)
    if #shopData.red_dot > 0 then
      self:RegisterRedDotById(luaPart.red_dot, shopData.red_dot, shopData.red_dot[1], {1, 2})
    end
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.sub_toggleGroup, self, nil, self.OnSubShop)
end

function ShopPage:OnSubShop(index)
  local widgets = self.tab_Widgets
  index = index + 1
  local shopList = self.shopList[1].subShops
  local shopInfo = shopList[index]
  self:OnShopChanged(shopInfo.id)
  if index == 1 then
    widgets.obj_gift:SetActive(true)
    widgets.obj_month:SetActive(false)
    widgets.obj_bigmonth:SetActive(false)
  elseif index == 2 then
    widgets.obj_gift:SetActive(false)
    widgets.obj_month:SetActive(true)
    widgets.obj_bigmonth:SetActive(false)
  elseif index == 3 then
    widgets.obj_gift:SetActive(false)
    widgets.obj_month:SetActive(false)
    widgets.obj_bigmonth:SetActive(true)
  end
  self.showCumuRecharge = false
  if shopInfo.id == 1002 then
    widgets.obj_gift:SetActive(true)
    widgets.obj_month:SetActive(false)
    widgets.obj_bigmonth:SetActive(false)
    self:CloseSubPage("CumulativeRechargePage")
    self.tab_Widgets.img_girlRender.gameObject:SetActive(true)
    self.tab_Widgets.obj_rec_bg:SetActive(true)
  elseif shopInfo.id == 1003 or shopInfo.id == 1004 then
    widgets.obj_gift:SetActive(false)
    widgets.obj_month:SetActive(true)
    widgets.obj_bigmonth:SetActive(false)
    self:CloseSubPage("CumulativeRechargePage")
    self.tab_Widgets.img_girlRender.gameObject:SetActive(true)
    self.tab_Widgets.obj_rec_bg:SetActive(true)
  elseif shopInfo.id == 1005 then
    widgets.obj_gift:SetActive(false)
    widgets.obj_month:SetActive(false)
    widgets.obj_bigmonth:SetActive(true)
    self:CloseSubPage("CumulativeRechargePage")
    self.tab_Widgets.img_girlRender.gameObject:SetActive(true)
    self.tab_Widgets.obj_rec_bg:SetActive(true)
  elseif shopInfo.id == 1006 then
    widgets.obj_gift:SetActive(false)
    widgets.obj_month:SetActive(false)
    widgets.obj_bigmonth:SetActive(false)
    self:OpenSubPage("CumulativeRechargePage")
    self.tab_Widgets.img_girlRender.gameObject:SetActive(false)
    self.tab_Widgets.obj_bgText:SetActive(false)
    self.tab_Widgets.obj_rec_bg:SetActive(false)
    self.showCumuRecharge = true
  end
end

function ShopPage:UpdateBigMonthCardPanel()
  self.bigmonthCard = Logic.rechargeLogic:GetBigMonthCardData()
  if self.bigmonthCard then
    UIHelper.SetText(self.tab_Widgets.txt_bigmonth_name, self.bigmonthCard.show_name)
    UIHelper.SetText(self.tab_Widgets.txt_bigmonth_price, self.bigmonthCard.cost)
    local days = Logic.rechargeLogic:GetDaysRemaining(self.bigmonthCard.id)
    if days and 0 < days then
      self.tab_Widgets.txt_bigmonth_time.gameObject:SetActive(true)
      UIHelper.SetText(self.tab_Widgets.txt_bigmonth_time, "\229\137\169\228\189\153\230\151\182\233\151\180\239\188\154" .. tostring(math.tointeger(days)) .. "\229\164\169")
    else
      self.tab_Widgets.txt_bigmonth_time.gameObject:SetActive(false)
    end
  end
end

function ShopPage:UpdateMonthCardPanel()
  local os = platformManager:GetOS()
  self.tab_Widgets.obj_monthCard:SetActive(GAME_OS[os] == GAME_OS.android)
  self.tab_Widgets.obj_iosMonth:SetActive(GAME_OS[os] ~= GAME_OS.android)
  if GAME_OS[os] == GAME_OS.android then
    self.monthCard = Logic.rechargeLogic:GetMonthCardData()
    if not self.monthCard then
      return
    end
    local showName = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW and self.monthCard.name or self.monthCard.show_name
    UIHelper.SetText(self.tab_Widgets.txt_month_name, showName)
    UIHelper.SetText(self.tab_Widgets.txt_month_price, self.monthCard.cost)
    local days = Logic.rechargeLogic:GetDaysRemaining(self.monthCard.id)
    if days and 0 < days then
      self.tab_Widgets.txt_cardTime.gameObject:SetActive(true)
      UIHelper.SetText(self.tab_Widgets.txt_cardTime, "\229\137\169\228\189\153\230\151\182\233\151\180\239\188\154" .. tostring(math.tointeger(days)) .. "\229\164\169")
    else
      self.tab_Widgets.txt_cardTime.gameObject:SetActive(false)
    end
  else
    local rechargeTab = Logic.rechargeLogic:GetShowData()
    for _, v in ipairs(rechargeTab[RechargeTogType.recharge]) do
      if v.paytype == RechargeItemType.MonthCard then
        self.monthCard = v
      elseif v.paytype == RechargeItemType.Subscribe then
        self.subscribeCard = v
      end
    end
    Logic.rechargeLogic:GetFreeSubscribeState()
    if not self.monthCard then
      return
    end
    local monthDays = Logic.rechargeLogic:GetDaysRemaining(self.monthCard.id)
    if monthDays and 0 < monthDays then
      self.tab_Widgets.btn_iosBuy.enabled = false
      UIHelper.SetImage(self.tab_Widgets.img_iosBuy, "uipic_ui_common_bu_tongyonganniu")
      UIHelper.SetText(self.tab_Widgets.txt_iosBuy, "\232\180\173\228\185\176\228\184\173...")
    else
      self.tab_Widgets.btn_iosBuy.enabled = true
      UIHelper.SetImage(self.tab_Widgets.img_iosBuy, "uipic_ui_common_bu_xie_lv")
      UIHelper.SetText(self.tab_Widgets.txt_iosBuy, "\229\141\149\230\172\161\232\180\173\228\185\176")
    end
    local days = Logic.rechargeLogic:GetDaysRemaining(self.monthCard.id)
    if days and 0 < days then
      self.tab_Widgets.txt_iosMonthTime.gameObject:SetActive(true)
      UIHelper.SetText(self.tab_Widgets.txt_iosMonthTime, "\229\137\169\228\189\153\230\151\182\233\151\180\239\188\154" .. tostring(math.tointeger(days)) .. "\229\164\169")
    else
      self.tab_Widgets.txt_iosMonthTime.gameObject:SetActive(false)
    end
  end
end

function ShopPage:_UpdateFreeState(ret)
  if ret == 0 and 0 > self.subscribeCard.free_duration then
    self.tab_Widgets.btn_iosAutoBuy.enabled = true
    UIHelper.SetImage(self.tab_Widgets.img_iosAutoBuy, "uipic_ui_common_bu_tongyonganniu")
    UIHelper.SetText(self.tab_Widgets.txt_iosAuto, "\233\166\150\230\172\161\232\174\162\233\152\133")
    return
  end
  local subscribeDays = Logic.rechargeLogic:GetSubscribeRemaining()
  if subscribeDays then
    self.tab_Widgets.btn_iosAutoBuy.enabled = false
    UIHelper.SetImage(self.tab_Widgets.img_iosAutoBuy, "uipic_ui_common_bu_tongyonganniu")
    UIHelper.SetText(self.tab_Widgets.txt_iosAuto, "\232\174\162\233\152\133\228\184\173...")
  else
    self.tab_Widgets.btn_iosAutoBuy.enabled = true
    UIHelper.SetImage(self.tab_Widgets.img_iosAutoBuy, "uipic_ui_common_bu_xie_lv")
    UIHelper.SetText(self.tab_Widgets.txt_iosAuto, "\232\135\170\229\138\168\232\174\162\233\152\133")
  end
end

function ShopPage:UpdateRecommendPanel()
  local widgets = self.tab_Widgets
  local shopId = self.shopId
  local goods = Logic.shopLogic:GetRecommendShopGoods()
  local goods1 = goods[1]
  local goods2 = goods[2]
  if goods1 then
    UIHelper.SetImage(widgets.img_goods1, goods1.recommend_bg1)
  end
  if goods2 then
    UIHelper.SetImage(widgets.img_goods2, goods2.recommend_bg2)
  end
  self:SetShopGoodsPrice({
    txt_name = widgets.txt_name1,
    obj_rmb = widgets.obj_rmb1,
    img_currency = widgets.img_currency1,
    txt_cost = widgets.txt_cost1,
    obj_buy = widgets.obj_buy1,
    soldout = widgets.obj_goods1_soldout,
    icon = widgets.icon_goods1,
    txt_period = widgets.txt_period_good1,
    goods = goods1
  })
  self:SetShopGoodsPrice({
    txt_name = widgets.txt_name2,
    obj_rmb = widgets.obj_rmb2,
    img_currency = widgets.img_currency2,
    txt_cost = widgets.txt_cost2,
    obj_buy = widgets.obj_buy2,
    soldout = widgets.obj_goods2_soldout,
    icon = widgets.icon_goods2,
    txt_period = widgets.txt_period_good2,
    goods = goods2
  })
  self:RegisterRedDotById(widgets.reddot_goods1, {42}, 42, {1})
  self:RegisterRedDotById(widgets.reddot_goods2, {42}, 42, {2})
end

function ShopPage:SetShopGoodsPrice(options)
  if not options.goods then
    return
  end
  local goods = options.goods
  options.soldout:SetActive(goods.soldout)
  if goods.paytype then
    if goods.currency_type == CurrencyType.RMB then
      options.obj_rmb:SetActive(true)
      options.img_currency.gameObject:SetActive(false)
    else
      options.obj_rmb:SetActive(false)
      options.img_currency.gameObject:SetActive(true)
      local currencyIcon = Logic.currencyLogic:GetSmallIcon(goods.currency_type)
      UIHelper.SetImage(options.img_currency, currencyIcon)
    end
    UIHelper.SetText(options.txt_cost, goods.cost)
    local showName = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW and goods.name or goods.show_name
    UIHelper.SetText(options.txt_name, showName)
    UIHelper.SetImage(options.icon, goods.icon, true)
  else
    local itemInfo = Logic.bagLogic:GetItemByTempateId(goods.goods[1], goods.goods[2])
    UIHelper.SetText(options.txt_name, itemInfo.name)
    options.obj_rmb:SetActive(false)
    options.img_currency.gameObject:SetActive(true)
    local icon = Logic.goodsLogic:GetIcon(goods.goods[2], goods.goods[1])
    UIHelper.SetImage(options.icon, icon, true)
    local prices = goods.price2
    if 0 < #prices then
      local price = prices[1]
      local currencyType = price[1]
      local currencyId = price[2]
      local cost = price[3]
      local currencyIcon = Logic.goodsLogic:GetSmallIcon(currencyId, currencyType)
      UIHelper.SetImage(options.img_currency, currencyIcon, true)
      UIHelper.SetText(options.txt_cost, cost)
    else
      options.img_currency.gameObject:SetActive(false)
      UIHelper.SetText(options.txt_cost, UIHelper.GetString(430006))
    end
    self:_ShowBuyPeriodInfo(options, goods.period_buy, goods)
  end
end

function ShopPage:_ShowBuyPeriodInfo(options, periodIds, goods)
  local periodId = 0
  for _, perId in pairs(periodIds) do
    if PeriodManager:IsInPeriod(perId) then
      periodId = perId
      break
    end
  end
  options.txt_period.gameObject:SetActive(0 < periodId)
  if 0 < periodId then
    local descTime = Logic.shopLogic:GetPeriodText(periodId, goods.period_show)
    options.txt_period.text = descTime
  end
  if 0 < #periodIds and periodId == 0 then
    options.txt_period.text = UIHelper.GetString(270039)
  end
end

function ShopPage:ShowRecommendPanel()
  local widgets = self.tab_Widgets
  widgets.obj_recommend:SetActive(true)
  self:UpdateBigMonthCardPanel()
  self:UpdateMonthCardPanel()
  local index = 0
  if self.subShopId then
    local shopList = self.shopList[1].subShops
    for i, s in ipairs(shopList) do
      if s.id == self.subShopId then
        index = i - 1
        break
      end
    end
  end
  self.tab_Widgets.sub_toggleGroup:SetActiveToggleIndex(index)
end

function ShopPage:HideRecommendPanel()
  local widgets = self.tab_Widgets
  widgets.obj_recommend:SetActive(false)
end

function ShopPage:FixScrollPosition(index, total)
  local content = self.tab_Widgets.trans_listContent
  local viewportWidth = content.parent.rect.size.x
  local itemWidth = 210
  local pageNum = viewportWidth / itemWidth
  local remainNum = total - pageNum
  local unit = 1 / remainNum
  local toIndex = 3
  local offset = math.min((index - toIndex) * unit, 1)
  offset = math.max(offset, 0)
  self.tab_Widgets.scrollrect.horizontalNormalizedPosition = offset
end

function ShopPage:_GetNextShelf()
  self.shelfType = self.shelfType + 1
  if self.shelfType >= ShopShelfType.Count then
    self.shelfType = 1
  end
  while #self.m_shopShowList[self.shelfType] <= 0 do
    self.shelfType = self.shelfType + 1
    if self.shelfType >= ShopShelfType.Count then
      self.shelfType = 1
    end
  end
end

function ShopPage:_SetBtnState()
  for i = 1, ShopShelfType.Count - 1 do
    if self.shelfType == i then
      self.curChangeBtn = self.changeBtn[i]
    end
    self.changeBtn[i]:SetActive(self.shelfType == i)
  end
end

function ShopPage:_ClickChangeShelf()
  local preShelf = self.shelfType
  self:_GetNextShelf()
  if preShelf ~= self.shelfType then
    self:_SetBtnState()
    if not self.m_bShowItem then
      local preInfoId = configManager.GetDataById("config_parameter", ShopModel[preShelf]).value
      local infoid = configManager.GetDataById("config_parameter", ShopModel[self.shelfType]).value
      if preInfoId ~= infoid then
        self:_UnloadModel()
        self:_LoadShipModel(infoid)
      end
      self.m_shopShow[self.m_bShowItem]:ChangeShelf(self.shelfType)
    end
  end
end

function ShopPage:_DotInfo(isShowItem)
  if isShowItem then
    local dotinfo = {info = "ui_shop"}
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  end
end

function ShopPage:_GetShopsInfoCallBack()
  local startTime = Logic.shopLogic:GetRefreshShopTimer()
  if startTime ~= nil then
    local startPrint = function()
      Service.shopService:SendGetShopsInfo()
      self.m_Timer:Stop()
      self.m_Timer = nil
    end
    if self.m_Timer ~= nil then
      self.m_Timer:Stop()
    end
    self.m_Timer = Timer.New(startPrint, startTime - time.getSvrTime(), 1, false)
    self.m_Timer:Start()
  end
  self:SelectShopOnOpen()
  self:UpdateBigMonthCardPanel()
  self:UpdateMonthCardPanel()
  eventManager:SendEvent(LuaEvent.ShopLevelGift)
end

function ShopPage:_LoadShipModel(infoId)
  local param = {showID = infoId}
  if self.m_objModel == nil then
    self.m_objModel = UIHelper.Create3DModel(param, self.tab_Widgets.img_girlRender, CamDataType.Display)
    self.m_objModel:HideMech(false)
    self.tab_Widgets.img_girlRender.gameObject:SetActive(true)
  end
end

function ShopPage:_ClickHelper()
  local shopConfig = configManager.GetDataById("config_shop", self.shopId)
  local strId = shopConfig.help
  UIHelper.OpenPage("HelpPage", {content = strId})
end

function ShopPage:_OnGirlClick()
  local count = #onClickBehaviour
  local index = math.random(count)
  self:PlayBehaviour(onClickBehaviour[index])
end

function ShopPage:BuyGoodsCallBack(param)
  local isFashion, ssIdTab, fashionTabId = Logic.rewardLogic:_CheckFashionInReward(param.Reward)
  if isFashion then
    local dotInfo = {info = "shop_buy", fashion_id = fashionTabId}
    RetentionHelper.Retention(PlatformDotType.fashionGetLog, dotInfo)
  end
  local goodsInfo = Logic.shopLogic:GetGoodsInfoById(param.GoodId)
  local costNum = {}
  local currencyNum = {}
  local goodsNum = param.BuyNum
  for k, v in pairs(goodsInfo.price2) do
    costNum[tostring(v[2])] = tostring(v[3] * goodsNum)
    currencyNum[tostring(v[2])] = tostring(Data.userData:GetCurrency(v[2]))
  end
  local dotinfo = {
    info = "ui_shop_buy",
    item_num = {
      [tostring(goodsInfo.id)] = tostring(goodsNum)
    },
    cost_num = costNum,
    currency_num = currencyNum
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  Logic.rewardLogic:ShowFashion({
    rewards = param.Reward
  })
  local isHero, si_id, heroId = Logic.rewardLogic:_CheckHeroInReward(param.Reward)
  if isHero then
    UIHelper.OpenPage("ShowGirlPage", {
      girlId = si_id,
      HeroId = heroId,
      callback = function()
      end
    })
  else
    local buyType = goodsInfo.buy_type
    if buyType == SHOW_BUY_GOOD then
      Logic.rewardLogic:ShowCommonReward(param.Reward, "ShopPage")
    else
      noticeManager:OpenTipPage(self, 230006)
    end
  end
  self:OnBuySuccess()
end

function ShopPage:_ShowRechargeRewards()
  local rewards = Data.rechargeData:GetRechargeRewardData()
  Logic.rewardLogic:ShowCommonReward(rewards, "RechargePage", nil)
end

function ShopPage:OnBuySuccess()
  self:UpdateRecommendPanel()
  local shopCfg = configManager.GetDataById("config_shop", self.shopId)
  if shopCfg and shopCfg.dependence_id == ShopId.Recommand then
    local count = #onBuyBehaviour
    local index = math.random(count)
    self:PlayBehaviour(onBuyBehaviour[index])
  end
  if shopCfg.id == MONTH_CARD_ID or shopCfg.id == MONTH_IOS_CARD_ID then
    self:UpdateMonthCardPanel()
  end
  if shopCfg.id == BIG_MONTH_CARD_ID then
    self:UpdateBigMonthCardPanel()
  end
  if self.buyGift ~= nil and self.buyGift.paytype then
    local serverData = Logic.rechargeLogic:GetServerDataById(self.buyGift.id)
    local buyTimes = serverData == nil and 0 or serverData.BuyTimes
    local dotInfo = {
      info = "success_rechage",
      type = self.buyGift.paytype,
      cost = self.buyGift.cost,
      recharge_id = self.buyGift.id,
      buy_time = buyTimes
    }
    RetentionHelper.Retention(PlatformDotType.recharge, dotInfo)
    self.buyGift = nil
  end
end

function ShopPage:PlayBehaviour(behaviourName)
  if self.m_objModel then
    self.m_objModel:Get3dObj():playBehaviour(behaviourName, true)
  end
end

function ShopPage:ToRechargeShop(shopId)
  self:SelectShopById(shopId)
end

function ShopPage:UpdateShopInfo(shopInfo)
  self:UpdateRecommendPanel()
end

function ShopPage:OnShopChanged(shopId)
  self.shopId = shopId
  local shopConfig = configManager.GetDataById("config_shop", self.shopId)
  self.tab_Widgets.btn_help.gameObject:SetActive(shopConfig.help > 0)
end

function ShopPage:_UnloadModel()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.tab_Widgets.img_girlRender.gameObject:SetActive(false)
    self.m_objModel = nil
  end
end

function ShopPage:DoOnHide()
  self:_UnloadModel()
  if self.m_Timer then
    self.m_Timer:Stop()
    self.m_Timer = nil
  end
  self:SetLeavingShopId()
  self.rechargeView:Hide()
end

function ShopPage:DoOnClose()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.tab_Widgets.img_girlRender.gameObject:SetActive(false)
    self.m_objModel = nil
  end
  if self.m_Timer then
    self.m_Timer:Stop()
    self.m_Timer = nil
  end
  self.shopItemView:Close()
  self.rechargeView:Close()
end

return ShopPage
