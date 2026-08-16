local RechargePage = class("ui.page.Recharge.RechargePage")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local MAXGOODSNUM = 5
local SpecialIconId = 13
local SpecialIconId2 = 129
local TabDotInfo = {
  [ShopId.Normal] = "ui_shop_norms_buy",
  [ShopId.MainGun] = "ui_shop_gun_buy",
  [ShopId.Torpedo] = "ui_shop_torpedo_buy",
  [ShopId.Equip] = "ui_shop_equipment_buy",
  [ShopId.Spa] = "ui_shop_spa_buy"
}
local ShopGiftRedDotId = 45

function RechargePage:initialize(parent)
  self.tab_Widgets = parent.tab_Widgets
  self.parent = parent
  self.anim_delay = 0.2
  eventManager:RegisterEvent(LuaEvent.BuyRechargeItem, self._BuyItem, self)
end

function RechargePage:Show(shopId, subShopId, rechargeId)
  self:RegisterAllEvent()
  local showData = Logic.rechargeLogic:GetConfigShowData()
  self.showLucky = showData[RechargeTogType.luckybag] and #showData[RechargeTogType.luckybag] > 0
  if shopId == ShopId.Recharge then
    if self.showLucky then
      self.subShopId = subShopId
    else
      self.rechargeType = RechargeTogType.recharge
    end
  elseif shopId == ShopId.Gift then
    self.rechargeType = RechargeTogType.gift
  end
  self.jumpRec = rechargeId
  self.isGift = shopId == ShopId.Gift
  self.shopId = shopId
  self.shopInfo = Logic.shopLogic:GetShowGoodsInfo(shopId)
  self.tab_Widgets.obj_giftTips:SetActive(self.isGift)
  self.tab_Widgets.obj_giftShop:SetActive(not self.showLucky or self.shopId == ShopId.Gift)
  self.tab_Widgets.obj_rechargeShop:SetActive(self.showLucky and self.shopId == ShopId.Recharge)
  self:_CreateSubList()
  if shopId == ShopId.Gift or not self.showLucky then
    self:_ShowItem(self.jumpRec == nil)
  end
end

function RechargePage:_CreateSubList()
  self.tab_Widgets.group_reItemSubList:ClearToggles()
  if self.shopId == ShopId.Recharge and self.showLucky then
    local shopList, allShopConfig = Logic.shopLogic:GetShowShopInfo()
    local shopConfigL1 = allShopConfig[self.shopId]
    self.subShops = shopConfigL1.subShops
    UIHelper.CreateSubPart(self.tab_Widgets.obj_reSubItem, self.tab_Widgets.trans_reSubList, #self.subShops, function(index, tabPart)
      local shopData = self.subShops[index]
      if #shopData.red_dot > 0 then
        self.parent:RegisterRedDotById(tabPart.red_dot, shopData.red_dot, shopData.id)
      else
        tabPart.red_dot.gameObject:SetActive(false)
      end
      UIHelper.SetText(tabPart.name, shopData.name)
      self.tab_Widgets.group_reItemSubList:RegisterToggle(tabPart.toggle)
    end)
    UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.group_reItemSubList, self, nil, self._OnSubShop)
    local index = 0
    if self.subShopId then
      for i = 1, #self.subShops do
        if self.subShops[i].id == self.subShopId then
          index = i - 1
          break
        end
      end
    end
    self.tab_Widgets.group_reItemSubList:SetActiveToggleIndex(index)
  end
end

function RechargePage:_OnSubShop(index)
  local shopInfo = self.subShops[index + 1]
  self.rechargeType = shopInfo.id == ShopId.DiamondRecharge and RechargeTogType.recharge or RechargeTogType.luckybag
  eventManager:SendEvent(LuaEvent.TopUpdateCurrency, shopInfo.currency_show)
  self:_ShowItem()
end

function RechargePage:_UpdateFreeState(ret)
  if ret == 0 and self.subscribePart and 0 < self.subscribeInfo.free_duration then
    self.subscribePart.obj_subs:SetActive(false)
    self.subscribePart.obj_freeSubs:SetActive(true)
    self.subscribePart.obj_freeText:SetActive(true)
    UIHelper.SetText(self.subscribePart.text_freeDays, self.subscribeInfo.free_duration)
  end
end

function RechargePage:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.UpdataRechargeInfo, self._UpdateRechargeInfo, self)
  eventManager:RegisterEvent(LuaEvent.GetBuyGoodsMsg, self._BuyGoodsCallBack, self)
  eventManager:RegisterEvent(LuaEvent.FreeSubscribeStateCallBack, self._UpdateFreeState, self)
end

function RechargePage:UnRegisterAllEvent()
  eventManager:UnregisterEvent(LuaEvent.UpdataRechargeInfo, self._UpdateRechargeInfo)
  eventManager:UnregisterEvent(LuaEvent.GetBuyGoodsMsg, self._BuyGoodsCallBack)
  eventManager:UnregisterEvent(LuaEvent.FreeSubscribeStateCallBack, self._UpdateFreeState)
end

function RechargePage:_LoadShipModel()
  local param = {
    showID = configManager.GetDataById("config_parameter", 114).value
  }
  if self.m_objModel == nil then
    self.m_objModel = UIHelper.Create3DModel(param, self.tab_Widgets.img_girl, CamDataType.Display)
    self.tab_Widgets.img_girl.gameObject:SetActive(true)
  end
end

function RechargePage:_UnloadShipModel()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.tab_Widgets.img_girl.gameObject:SetActive(false)
    self.m_objModel = nil
  end
end

function RechargePage:_ShowItem(withAnim)
  withAnim = withAnim == nil and true or withAnim
  local totalData = Logic.rechargeLogic:GetShowData()
  local shopGoods = self.shopInfo.ShopGoodsData
  local shopGoodsCount = #shopGoods
  if self.showNextBuyTimer ~= nil then
    for _, timer in pairs(self.showNextBuyTimer) do
      self.parent:StopTimer(timer)
    end
    self.showNextBuyTimer = nil
  end
  local showData = clone(totalData[self.rechargeType])
  local soldoutIndex = #showData + 1
  for i = 1, #showData do
    if showData[i].newItem == 1 then
      soldoutIndex = i
      break
    end
  end
  if 0 < shopGoodsCount then
    self.goodsGridIdMap = {}
    for k, v in pairs(shopGoods) do
      if v.Status == 0 then
        table.insert(showData, soldoutIndex, v)
        soldoutIndex = soldoutIndex + 1
      end
      self.goodsGridIdMap[v.GoodsId] = v.GridId
    end
  end
  if #showData <= 0 then
    return
  end
  local useRechargeObj = self.shopId == ShopId.Recharge and self.showLucky
  local trans_content = useRechargeObj and self.tab_Widgets.trans_reItemList or self.tab_Widgets.trans_giftContent
  local obj_item = useRechargeObj and self.tab_Widgets.obj_reItem or self.tab_Widgets.obj_giftItem
  self.subscribePart = nil
  local tab_tabparts = {}
  local jumpIndex
  self.parent:UnRegisterRedDotById(ShopGiftRedDotId)
  UIHelper.CreateSubPart(obj_item, trans_content, #showData, function(index, tabPart)
    table.insert(tab_tabparts, tabPart)
    if withAnim then
      tabPart.gameObject:SetActive(false)
    end
    local info = showData[index]
    if info.paytype then
      self:_FillRecharge(info, tabPart)
    else
      self:_FilleShopGoods(info, tabPart)
    end
    if self.jumpRec and self.jumpRec == info.id then
      jumpIndex = index
      self.jumpRec = nil
    end
    if withAnim and index == #showData then
      local num = #tab_tabparts
      local aNum = num > MAXGOODSNUM and MAXGOODSNUM or num
      local curIndex = 1
      
      function PlayAnim()
        self.anim_delay = 0
        tab_tabparts[curIndex].tween_alpha:SetOnFinished(function()
          if curIndex < aNum then
            curIndex = curIndex + 1
            PlayAnim()
          elseif num > aNum then
            for i = aNum + 1, num do
              tab_tabparts[i].gameObject:SetActive(true)
            end
          end
        end)
        tab_tabparts[curIndex].tween_alpha:ResetToBeginning()
        tab_tabparts[curIndex].tween_scale:ResetToBeginning()
        tab_tabparts[curIndex].gameObject:SetActive(true)
        tab_tabparts[curIndex].tween_scale:Play(true)
        tab_tabparts[curIndex].tween_alpha:Play(true)
      end
      
      if self.anim_delay > 0 then
        self.anim_timer = self.parent:CreateTimer(PlayAnim, self.anim_delay, 1, false)
        self.parent:StartTimer(self.anim_timer)
      else
        PlayAnim()
      end
    end
  end)
  if self.subscribePart then
    Logic.rechargeLogic:GetFreeSubscribeState()
  end
  if jumpIndex then
    if self.jumpCor ~= nil then
      coroutine.stop(self.jumpCor)
      self.jumpCor = nil
    end
    self.jumpCor = coroutine.start(function()
      coroutine.wait(0.06)
      local m_cellSize = self.tab_Widgets.grid_Layout.cellSize.x + self.tab_Widgets.grid_Layout.spacing.x / 2
      local pos = self.tab_Widgets.grid_rect.anchoredPosition
      pos.x = pos.x - m_cellSize * (jumpIndex - 1)
      if Mathf.Abs(pos.x) > self.tab_Widgets.grid_rect.sizeDelta.x then
        pos.x = -1 * self.tab_Widgets.grid_rect.sizeDelta.x
      end
      self.tab_Widgets.grid_rect.anchoredPosition = pos
      jumpIndex = nil
    end)
  end
end

function RechargePage:_FillRecharge(info, tabPart)
  local serverData = Logic.rechargeLogic:GetServerDataById(info.id)
  tabPart.red_dot.gameObject:SetActive(false)
  if info.paytype == RechargeItemType.Subscribe then
    self.subscribePart = tabPart
    self.subscribeInfo = info
  end
  tabPart.img_currency.gameObject:SetActive(info.currency_type ~= CurrencyType.RMB)
  tabPart.obj_cost:SetActive(info.paytype ~= RechargeItemType.Subscribe)
  tabPart.obj_subs:SetActive(info.paytype == RechargeItemType.Subscribe)
  tabPart.obj_freeSubs:SetActive(false)
  tabPart.obj_freeText:SetActive(false)
  tabPart.obj_special:SetActive(info.show_reddot == 1)
  UIHelper.SetImage(tabPart.bg_goods, info.shop_bg)
  UIHelper.SetText(tabPart.text_subsCost, info.cost)
  local cost = info.currency_type == CurrencyType.RMB and string.format("\239\191\165%s", info.cost) or info.cost
  UIHelper.SetText(tabPart.text_buy, cost)
  if info.currency_type ~= CurrencyType.RMB then
    local currencyIcon = Logic.currencyLogic:GetSmallIcon(info.currency_type)
    UIHelper.SetImage(tabPart.img_currency, currencyIcon)
  end
  local isMonth = Logic.rechargeLogic:IsMonthCard(info.paytype)
  tabPart.text_name.gameObject:SetActive(not isMonth)
  tabPart.obj_month:SetActive(info.paytype == RechargeItemType.MonthCard)
  local isGiftShop = self.isGift
  tabPart.text_name.gameObject:SetActive(not isGiftShop)
  tabPart.txt_nameGift.gameObject:SetActive(isGiftShop)
  tabPart.img_icon.gameObject:SetActive(not isGiftShop)
  tabPart.img_iconGift.gameObject:SetActive(isGiftShop)
  local showName = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW and info.name or info.show_name
  if isGiftShop then
    UIHelper.SetText(tabPart.txt_nameGift, showName)
  else
    UIHelper.SetText(tabPart.text_name, showName)
    tabPart.obj_title_fd:SetActive(info.paytype == RechargeItemType.Lucky)
    if info.paytype == RechargeItemType.MonthCard then
      UIHelper.SetText(tabPart.text_monthName, showName)
    end
  end
  tabPart.obj_continuity:SetActive(info.channel == GAME_OS.android and info.paytype == RechargeItemType.MonthCard and info.buynum == 0)
  if info.icon ~= "" then
    if isGiftShop and info.id ~= SpecialIconId and info.id ~= SpecialIconId2 then
      UIHelper.SetImage(tabPart.img_iconGift, info.icon)
      tabPart.img_iconGift:SetNativeSize()
    elseif isGiftShop and (info.id == SpecialIconId or info.id == SpecialIconId2) then
      UIHelper.SetImage(tabPart.img_iconGift, "uipic_ui_shop_im_xinrenchaozhifudai_6_da_8", true)
    else
      UIHelper.SetImage(tabPart.img_icon, info.icon)
      tabPart.img_icon:SetNativeSize()
    end
  end
  local doubleActive = false
  if serverData then
    doubleActive = serverData.Status == 1
  else
    doubleActive = 0 < info.extra_reward
  end
  tabPart.obj_double:SetActive(doubleActive)
  tabPart.obj_soldout:SetActive(false)
  local reachLimit, msg = Logic.gameLimitLogic.CheckConditionByArrId(info.buy_limit)
  if not reachLimit then
    tabPart.txt_limit.text = msg .. UIHelper.GetString(270035)
  end
  tabPart.txt_limit.gameObject:SetActive(not reachLimit)
  tabPart.text_buytimes.gameObject:SetActive(info.buynum > 0 and not isGiftShop)
  if not isGiftShop then
    local limitTime = serverData and serverData.LimitBuyTimes or 0
    local showTime = limitTime < info.buynum and math.tointeger(info.buynum - limitTime) or 0
    UIHelper.SetText(tabPart.text_buytimes, string.format(UIHelper.GetString(430005), showTime))
  end
  local limitBuyTimes = serverData and serverData.LimitBuyTimes or 0
  local isShowGift = false
  if info.paytype == RechargeItemType.Item or info.paytype == RechargeItemType.SpacingItem or info.paytype == RechargeItemType.ShopGoods or info.paytype == RechargeItemType.LuckyBuy then
    isShowGift = info.buynum > 0 and limitBuyTimes < info.buynum
  end
  tabPart.obj_times:SetActive(isShowGift)
  if info.buynum > 0 then
    tabPart.txt_times.text = string.format(UIHelper.GetString(270031), info.buynum - limitBuyTimes)
    tabPart.rect_times.sizeDelta = Vector2.New(92, 24)
  end
  self:_ShowNextBuyTime(info, tabPart, limitBuyTimes)
  if info.paytype == RechargeItemType.SpacingItem or info.paytype == RechargeItemType.LuckyBuy then
    self:_ShowBuyPeriodInfo(info.double_period, tabPart, info)
  else
    tabPart.txt_period.gameObject:SetActive(false)
    tabPart.obj_timeLimited:SetActive(false)
  end
  if info.tagid == RechargeTogType.recharge or info.tagid == RechargeTogType.luckybag then
    self:_ShowRechargeInfo(tabPart, info, serverData)
  else
    self:_ShowGiftInfo(tabPart, info, serverData)
  end
  tabPart.obj_subsSign:SetActive(info.paytype == RechargeItemType.Subscribe)
  tabPart.obj_subsName:SetActive(info.paytype == RechargeItemType.Subscribe)
  tabPart.btn_privilege.gameObject:SetActive(0 < #info.privilegedesc)
  tabPart.obj_discountPart:SetActive(info.originalcost ~= 0)
  tabPart.obj_discountSign:SetActive(info.originalcost ~= 0)
  tabPart.txt_discountCost.gameObject:SetActive(info.originalcost ~= 0)
  if info.originalcost ~= 0 then
    local discount = string.format("%.1f", info.cost / info.originalcost * 10)
    UIHelper.SetText(tabPart.txt_discount, discount)
    UIHelper.SetText(tabPart.txt_discountCost, string.format("\239\191\165%s", info.cost))
    UIHelper.SetText(tabPart.text_buy, string.format("\239\191\165%s", info.originalcost))
  end
  local ownDiscount = Logic.shopLogic:GetUsableDiscountConf(info.id, true)
  tabPart.obj_discount:SetActive(ownDiscount)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_privilege, self._ShowPrivilege, self, info)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_buy, function()
    local isInPeriod = #info.double_period <= 0
    if #info.double_period > 0 then
      for _, perId in pairs(info.double_period) do
        if PeriodManager:IsInPeriod(perId) then
          isInPeriod = true
          break
        end
        isInPeriod = false
      end
    end
    if (info.paytype == RechargeItemType.SpacingItem or info.paytype == RechargeItemType.LuckyBuy) and not isInPeriod then
      noticeManager:OpenTipPage(self, UIHelper.GetString(270038))
      return
    end
    if (isGiftShop or info.paytype == RechargeItemType.LuckyRecharge) and info.paytype ~= RechargeItemType.BigMonthCard then
      self.parent:ShowGiftInfo(info)
    elseif info.paytype == RechargeItemType.MonthCard or info.paytype == RechargeItemType.Subscribe or info.paytype == RechargeItemType.BigMonthCard then
      local args = {}
      
      function args.func(param)
        self:_BuyItem(param)
      end
      
      local days = Logic.rechargeLogic:GetDaysRemaining(info.id)
      if days and 0 < days then
        args.days = days
      end
      args.info = info
      UIHelper.OpenPage("MonthCardBuyPage", args)
    else
      self:_BuyItem(info)
    end
  end)
end

function RechargePage:_ShowNextBuyTime(info, tabPart, limitBuyTimes)
  local isSoldout = info.buynum > 0 and limitBuyTimes >= info.buynum
  tabPart.obj_soldout:SetActive(isSoldout)
  if not isSoldout or 0 >= #info.refreshid then
    return
  end
  tabPart.textNextBuyTime.gameObject:SetActive(true)
  local nextTime = PeriodManager:GetNextRefreshTime(info.refreshid[1])
  if #info.refreshid > 1 then
    for _, refId in pairs(info.refreshid) do
      local nt = PeriodManager:GetNextRefreshTime(refId)
      if nextTime > nt then
        nextTime = nt
      end
    end
  end
  local showRemianTime = function()
    local curTime = time.getSvrTime()
    local remainTime = nextTime - curTime
    if remainTime <= 0 then
      self:_ShowItem()
      return
    end
    local descTime = time.getTimeStringFontOnly(remainTime, false)
    tabPart.textNextBuyTime.text = string.format(UIHelper.GetString(430007), descTime)
  end
  if self.showNextBuyTimer == nil then
    self.showNextBuyTimer = {}
  end
  self.showNextBuyTimer[info.id] = self.parent:CreateTimer(showRemianTime, 1, -1, false)
  self.parent:StartTimer(self.showNextBuyTimer[info.id])
end

function RechargePage:_ShowBuyPeriodInfo(arrPeriod, tabPart, goodsData)
  tabPart.txt_period.gameObject:SetActive(#arrPeriod ~= 0)
  tabPart.obj_timeLimited:SetActive(#arrPeriod ~= 0)
  local periodId = 0
  for _, perId in pairs(arrPeriod) do
    if PeriodManager:IsInPeriod(perId) then
      periodId = perId
      break
    end
  end
  if 0 < periodId then
    local descTime = Logic.shopLogic:GetPeriodText(periodId, goodsData.period_show)
    tabPart.txt_period.text = descTime
  end
  if 0 < #arrPeriod and periodId == 0 then
    tabPart.txt_period.text = UIHelper.GetString(270039)
  end
end

function RechargePage:_FilleShopGoods(serverGoods, tabPart)
  local goodsData = Logic.shopLogic:GetGoodsInfoById(serverGoods.GoodsId)
  self:_RegisterRedDot(tabPart, goodsData)
  tabPart.img_currency.gameObject:SetActive(true)
  tabPart.obj_cost:SetActive(true)
  tabPart.obj_subs:SetActive(false)
  tabPart.obj_subsName:SetActive(false)
  tabPart.obj_continuity:SetActive(false)
  tabPart.obj_month:SetActive(false)
  tabPart.obj_subsSign:SetActive(false)
  tabPart.obj_freeSubs:SetActive(false)
  tabPart.obj_freeText:SetActive(false)
  tabPart.obj_special:SetActive(false)
  tabPart.obj_double:SetActive(false)
  tabPart.btn_privilege.gameObject:SetActive(false)
  UIHelper.SetText(tabPart.text_buytimes, "")
  UIHelper.SetText(tabPart.text_desc, "")
  tabPart.obj_gift:SetActive(true)
  tabPart.obj_reward:SetActive(false)
  tabPart.text_name.gameObject:SetActive(false)
  tabPart.txt_nameGift.gameObject:SetActive(true)
  tabPart.img_icon.gameObject:SetActive(false)
  tabPart.img_iconGift.gameObject:SetActive(true)
  local goods = goodsData.goods
  local icon = Logic.goodsLogic:GetIcon(goods[2], goods[1])
  UIHelper.SetImage(tabPart.img_iconGift, icon)
  tabPart.img_iconGift:SetNativeSize()
  local prices = goodsData.price2
  if 0 < #prices then
    local price = prices[1]
    local currencyType = price[1]
    local currencyId = price[2]
    local cost = price[3]
    local currencyIcon = Logic.goodsLogic:GetSmallIcon(currencyId, currencyType)
    UIHelper.SetImage(tabPart.img_currency, currencyIcon)
    UIHelper.SetText(tabPart.text_subsCost, cost)
    UIHelper.SetText(tabPart.text_buy, cost)
  else
    tabPart.img_currency.gameObject:SetActive(false)
    UIHelper.SetText(tabPart.text_buy, UIHelper.GetString(430006))
  end
  local itemInfo = Logic.bagLogic:GetItemByTempateId(goods[1], goods[2])
  UIHelper.SetText(tabPart.txt_nameGift, itemInfo.name)
  UIHelper.SetImage(tabPart.bg_goods, itemInfo.shop_bg)
  if goodsData.period_buy ~= nil and 0 < #goodsData.period_buy then
    self:_ShowBuyPeriodInfo(goodsData.period_buy, tabPart, goodsData)
  else
    tabPart.txt_period.gameObject:SetActive(false)
    tabPart.obj_timeLimited:SetActive(false)
  end
  tabPart.obj_soldout:SetActive(serverGoods.Status == BuyStatus.HaveBuy)
  local reachLimit = true
  local msg = ""
  for _, v in ipairs(goodsData.buy_limits) do
    reachLimit, msg = Logic.gameLimitLogic.CheckConditionById(v)
    if not reachLimit then
      local limitConfig = configManager.GetDataById("config_game_limits", v)
      msg = limitConfig.desc .. "\229\143\175\232\180\173\228\185\176"
      tabPart.txt_limit.text = msg
      break
    end
  end
  tabPart.txt_limit.gameObject:SetActive(not reachLimit)
  tabPart.obj_discountPart:SetActive(false)
  tabPart.obj_discountSign:SetActive(false)
  tabPart.txt_discountCost.gameObject:SetActive(false)
  local ownDiscount = Logic.shopLogic:GetUsableDiscountConf(goodsData.id, false)
  tabPart.obj_discount:SetActive(ownDiscount)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_buy, function()
    self.buyGoodsId = goodsData.id
    local goodType = goodsData.goods[1]
    if soldout then
      noticeManager:OpenTipPage(self, 270007)
    elseif not reachLimit then
      noticeManager:OpenTipPage(self, msg)
    else
      self.parent:ShowGiftInfo(goodsData)
    end
  end)
end

function RechargePage:_RegisterRedDot(tabPart, shopGoods)
  self.parent:RegisterRedDotById(tabPart.red_dot, {ShopGiftRedDotId}, ShopGiftRedDotId, shopGoods.id)
end

function RechargePage:_BuyGoodsCallBack(param)
  self.shopInfo = Logic.shopLogic:GetShowGoodsInfo(self.shopId)
  self:_ShowItem()
  self.parent:OnBuySuccess()
end

function RechargePage:_ShowRechargeInfo(tabPart, c_info, s_info)
  tabPart.obj_reward:SetActive(true)
  self:_ShowReward(tabPart, c_info)
  local doubleActive = false
  if s_info then
    doubleActive = s_info.Status == 1
  else
    doubleActive = c_info.extra_reward > 0
  end
  local descContent = doubleActive and c_info.desc or c_info.nodouble_desc
  local days = Logic.rechargeLogic:GetDaysRemaining(c_info.id)
  if Logic.rechargeLogic:IsMonthCard(c_info.paytype) then
    descContent = ""
  end
  if days and 0 < days then
    local strDay = string.format(configManager.GetDataById("config_language", 270045).content, tostring(math.tointeger(days)))
    descContent = descContent .. strDay
  end
  tabPart.obj_monthCardSoldOut:SetActive(days and 0 < days and c_info.channel == GAME_OS.ios and c_info.paytype == RechargeItemType.MonthCard)
  UIHelper.SetText(tabPart.text_desc, descContent)
  tabPart.obj_gift:SetActive(false)
  tabPart.obj_extra_reward:SetActive(false)
  if 0 < c_info.nodouble_extra_reward and not doubleActive then
    tabPart.obj_extra_reward:SetActive(true)
    tabPart.txt_extra_reward.text = c_info.nodouble_extra_reward_desc
  end
end

function RechargePage:_ShowGiftInfo(tabPart, c_info, s_info)
  tabPart.obj_gift:SetActive(true)
  tabPart.obj_monthCardSoldOut:SetActive(false)
  UIHelper.SetText(tabPart.text_desc, "")
  UIHelper.SetText(tabPart.text_giftDesc, c_info.nodouble_desc)
  tabPart.obj_reward:SetActive(false)
  local rewards = {}
  if c_info.reward > 0 then
    rewards = configManager.GetDataById("config_rewards", c_info.reward).rewards
  end
  if c_info.paytype == RechargeItemType.BigMonthCard then
    local descContent = ""
    local days = Logic.rechargeLogic:GetDaysRemaining(c_info.id)
    if days and 0 < days then
      local strDay = string.format(configManager.GetDataById("config_language", 270045).content, tostring(math.tointeger(days)))
      descContent = descContent .. strDay
    end
    UIHelper.SetText(tabPart.text_desc, descContent)
  end
  UIHelper.CreateSubPart(tabPart.obj_giftRewardItem, tabPart.trans_giftReward, #rewards, function(index, giftPart)
    local reward = rewards[index]
    UIHelper.SetText(giftPart.text_num, reward[3])
    local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
    UIHelper.SetImage(giftPart.img_quality, QualityIcon[rewardInfo.quality])
    UIHelper.SetImage(giftPart.img_icon, tostring(rewardInfo.icon))
    giftPart.img_quality.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(giftPart.btn_icon, function()
      UIHelper.OpenPage("GiftInfoPage", c_info.id)
    end, self)
  end)
end

function RechargePage:_ShowReward(tabPart, info)
  if info.reward and info.reward > 0 then
    local arrReward = configManager.GetDataById("config_rewards", info.reward).rewards
    UIHelper.CreateSubPart(tabPart.obj_rewardItem, tabPart.obj_reward.transform, #arrReward, function(index, rewardPart)
      local reward = arrReward[index]
      if #reward < 3 then
        logError("Recharge \232\161\168\228\184\173\229\165\150\229\138\177\228\191\161\230\129\175\233\133\141\231\189\174\233\148\153\232\175\175\239\188\140 \233\148\153\232\175\175id\228\184\186" .. info.id)
      end
      rewardPart.img_currency.gameObject:SetActive(true)
      rewardPart.text_currencyNum.gameObject:SetActive(true)
      UIHelper.SetText(rewardPart.text_currencyNum, reward[3])
      local currencyInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
      if currencyInfo.id == CurrencyType.LUCKY then
        rewardPart.img_currency.gameObject.transform.localScale = Vector3.New(1, 1, 1)
      else
        rewardPart.img_currency.gameObject.transform.localScale = Vector3.New(-1, 1, 1)
      end
      UIHelper.SetImage(rewardPart.img_currency, tostring(currencyInfo.icon))
    end)
  else
    tabPart.obj_reward:SetActive(false)
  end
end

function RechargePage:_ShowPrivilege(self, info)
  local content = info.privilegedesc
  UIHelper.OpenPage("PrivilegePage", content)
end

function RechargePage:_BuyItem(info)
  if not platformManager:useSDK() then
    return
  end
  if info.paytype == RechargeItemType.BigMonthCard then
    local tabCondition = {
      {
        CurrencyId = info.currency_type,
        CostNum = info.cost
      }
    }
    local isCan = conditionCheckManager:CheckCurrencyIsEnough(tabCondition, true)
    if not isCan then
      return
    end
  end
  if info.paytype == RechargeItemType.DirPay and Logic.loginLogic.SDKHashMsg.canPay == 0 then
    noticeManager:ShowMsgBox(430003)
    return
  end
  if info.paytype ~= RechargeItemType.LuckyBuy and info.paytype ~= RechargeItemType.BigMonthCard and info.paytype ~= RechargeItemType.LuckyRecharge and isWindows and platformManager:GetOS() == "ios" then
    noticeManager:ShowMsgBox(430002)
    return
  end
  self.buy_info = info
  local serverData = Logic.rechargeLogic:GetServerDataById(info.id)
  local buyTimes = serverData == nil and 0 or serverData.BuyTimes
  local dotInfo = {
    info = "click_rechage",
    type = info.paytype,
    cost = info.cost,
    recharge_id = info.id,
    buy_time = buyTimes
  }
  RetentionHelper.Retention(PlatformDotType.recharge, dotInfo)
  if info.paytype == RechargeItemType.LuckyBuy or info.paytype == RechargeItemType.BigMonthCard or info.paytype == RechargeItemType.LuckyRecharge then
    Service.rechargeService:DirectBuyItemCallBack(info.id, info.discountId)
  elseif info.paytype == RechargeItemType.Subscribe then
    local args = {}
    
    function args.func(param)
      self:_CheckRealName(param)
    end
    
    args.subscribeIng = Logic.rechargeLogic:GetSubscribeRemaining()
    args.info = info
    UIHelper.OpenPage("subscribeInfoPage", args)
  elseif info.paytype == RechargeItemType.MonthCard then
    local buyType = Logic.rechargeLogic:CheckMonthCardBuyType(info)
    if buyType == 0 then
      self:_CheckRealName(info)
    elseif buyType == -1 then
      noticeManager:ShowMsgBox(470010)
    elseif buyType == -2 then
      noticeManager:ShowMsgBox(470009)
    end
  else
    self:_CheckRealName(info)
  end
end

function RechargePage:_CheckRealName(info)
  platformManager:getRealNameState(function(ret)
    if ret and ret.data then
      if ret.data.idcardStatus == 1 then
        if info.cost == 0 then
          local showName = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW and info.name or info.show_name
          local strTip = string.format(UIHelper.GetString(430000), showName)
          local tabParam = {
            msgType = NoticeType.TwoButton,
            callback = function(bool)
              if bool then
                self:_BuyItemImp(info)
              end
            end
          }
          noticeManager:ShowMsgBox(strTip, tabParam)
        else
          self:_BuyItemImp(info)
        end
      else
        self:_GoToRealName()
      end
    end
  end)
end

function RechargePage:_GoToRealName()
  local tabParam = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        platformManager:enterUserCenter()
      end
    end
  }
  noticeManager:ShowMsgBox(430001, tabParam)
end

function RechargePage:_BuyItemImp(info)
  local serverData = Logic.rechargeLogic:GetServerDataById(info.id)
  local buyTimes = serverData == nil and 0 or serverData.BuyTimes
  local dotInfo = {
    info = "start_rechage",
    type = info.paytype,
    cost = info.cost,
    recharge_id = info.id,
    buy_time = buyTimes
  }
  RetentionHelper.Retention(PlatformDotType.recharge, dotInfo)
  if info.cost == 0 then
    Service.rechargeService:SendBuyFreeItem(info.id)
  else
    platformManager:getPay(info.id, info.name, info.cost, info.paytype, info.sdkdesc, function(ret)
      if not ret then
        logError("\232\180\173\228\185\176\229\164\177\232\180\165")
      end
    end)
  end
end

function RechargePage:_ShowRechargeRewards()
  local rewards = Data.rechargeData:GetRechargeRewardData()
  Logic.rewardLogic:ShowCommonReward(rewards, "RechargePage", nil)
end

function RechargePage:_UpdateRechargeInfo()
  if self.buy_info ~= nil then
    local serverData = Logic.rechargeLogic:GetServerDataById(self.buy_info.id)
    local buyTimes = serverData == nil and 0 or serverData.BuyTimes
    local dotInfo = {
      info = "success_rechage",
      type = self.buy_info.paytype,
      cost = self.buy_info.cost,
      recharge_id = self.buy_info.id,
      buy_time = buyTimes
    }
    RetentionHelper.Retention(PlatformDotType.recharge, dotInfo)
    self.buy_info = nil
  end
  self:_ShowItem()
  self.parent:OnBuySuccess()
end

function RechargePage:Hide()
  if self.jumpCor ~= nil then
    coroutine.stop(self.jumpCor)
    self.jumpCor = nil
  end
  self.tab_Widgets.obj_rechargeShop:SetActive(false)
  self:UnRegisterAllEvent()
end

function RechargePage:Close()
  self:UnRegisterAllEvent()
  eventManager:UnregisterEvent(LuaEvent.BuyRechargeItem, self._BuyItem, self)
end

return RechargePage
