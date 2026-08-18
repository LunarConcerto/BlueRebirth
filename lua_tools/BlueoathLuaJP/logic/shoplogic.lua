local ShopLogic = class("logic.ShopLogic")
local tblInsert = table.insert
local PeriodTextTab = {
  {
    270036,
    270037,
    270040
  },
  {
    270049,
    270050,
    270051
  }
}
local PeriodEndTips = {270038, 270052}

function ShopLogic:initialize()
  self.nWholeDayTime = 86400
  self.nWholeWeekInterval = 7 * self.nWholeDayTime
  self.weekDay = time.getWeekday()
  self.curYearTime = nil
  self.curMonthTime = nil
  self.curDay = nil
  self.curDayZeroTime = nil
  self.nCurMonthInterval = nil
  self:__initTime()
end

function ShopLogic:ResetData()
  self.nWholeDayTime = 86400
  self.nWholeWeekInterval = 7 * self.nWholeDayTime
  self.weekDay = time.getWeekday()
  self.curYearTime = nil
  self.curMonthTime = nil
  self.curDay = nil
  self.curDayZeroTime = nil
  self.nCurMonthInterval = nil
  self.buyItemInfo = {}
  self:__initTime()
  self:RegisterEvent()
end

function ShopLogic:RegisterEvent()
  eventManager:RegisterEvent(LuaEvent.PassNewDailyCopy, self._RefreshDailyShopRed, self)
end

function ShopLogic:__initTime()
  local curTime = time.getSvrTime()
  local tblFormat = os.date("*t", curTime)
  self.curYearTime = tblFormat.year
  self.curMonthTime = tblFormat.month
  self.curDay = tblFormat.day
  self.curDayZeroTime = time.getIntervalByString(self.curYearTime .. self.__GetDayStr(self.curMonthTime) .. self.__GetDayStr(self.curDay) .. "000000")
  self.nCurMonthInterval = self:__GetCurMonthInterval()
end

function ShopLogic:GetShopInfoById(shopId)
  return configManager.GetDataById("config_shop", shopId)
end

function ShopLogic:GetGoodsInfoById(goodId)
  return configManager.GetDataById("config_shop_goods", goodId)
end

function ShopLogic:GetCurrencyById(currencyId)
  return configManager.GetDataById("config_currency", currencyId)
end

function ShopLogic:GetShopConfigInfo()
  return configManager.GetData("config_shop")
end

function ShopLogic:GetSubShops(shopId)
  local subShops = {}
  local cfg = configManager.GetData("config_shop")
  for k, shop in pairs(cfg) do
    if shop.dependence_id == shopId then
      table.insert(subShops, shop)
    end
  end
  return subShops
end

function ShopLogic:GetGoodsParam(goodId)
  local good = self:GetGoodsInfoById(goodId).goods
  local goodType = good[1]
  local configInfo = self:GetTable_Index_Info(good)
  return goodType, configInfo
end

function ShopLogic:GetTable_Index_Info(param)
  local table_idnex_Info = configManager.GetDataById("config_table_index", param[1])
  local configInfo = configManager.GetDataById(table_idnex_Info.file_name, param[2])
  return configInfo
end

function ShopLogic:GetTableIndexConfById(id)
  return configManager.GetDataById("config_table_index", id)
end

function ShopLogic:GetShowShopInfo()
  local tabAllShopInfo = self:GetShopConfigInfo()
  local shopStates = {}
  local tabFilter = {}
  for k, v in pairs(tabAllShopInfo) do
    local isMonthCardShopShow = self:IsMonthCardShopShow(v.fun_type)
    local isInOpenPeriod = self:IsOpenByShopId(v.id)
    local isNotLimited = self:IsShopNotLimited(v.limit)
    local isShowPlatform = self:IsShowPlatform(v.platform)
    shopStates[v.id] = {
      info = v,
      isOpen = isInOpenPeriod and isNotLimited and isMonthCardShopShow and isShowPlatform
    }
  end
  for id, state in pairs(shopStates) do
    local pshopId = state.info.dependence_id
    if pshopId ~= -1 and shopStates[pshopId] and shopStates[pshopId].isOpen then
      shopStates[pshopId].subShops = shopStates[pshopId].subShops or {}
      table.insert(shopStates[pshopId].subShops, state)
    end
  end
  local allShop = {}
  for id, state in pairs(shopStates) do
    local isOpen = state.isOpen
    local info = clone(state.info)
    if state.subShops then
      table.sort(state.subShops, function(l, r)
        return l.info.order < r.info.order
      end)
      info.subShops = {}
      for _, st in ipairs(state.subShops) do
        table.insert(info.subShops, st.info)
      end
    end
    if isOpen and state.info.shop_type == 1 then
      local subShops = state.subShops
      local openSubs = {}
      isOpen, openSubs = self:_checkSubShop(subShops)
      if isOpen then
        if subShops then
          info.subShops = openSubs
        end
        table.insert(tabFilter, info)
      end
    end
    allShop[id] = info
  end
  table.sort(tabFilter, function(data1, data2)
    return data1.order < data2.order
  end)
  return tabFilter, allShop
end

function ShopLogic:_checkSubShop(subShops)
  local openSubs = {}
  local isOpen = true
  if subShops then
    for i, state in ipairs(subShops) do
      if state.isOpen then
        local isop = true
        if state.subShops then
          local isop, _ = self:_checkSubShop(state.subShops)
        end
        if isop then
          table.insert(openSubs, state.info)
        end
      end
    end
    isOpen = 0 < #openSubs
  end
  return isOpen, openSubs
end

function ShopLogic:IsShowPlatform(platform)
  if platform == GAME_OS.all then
    return true
  end
  local os = platformManager:GetOS()
  if platform == GAME_OS[os] then
    return true
  end
  return false
end

function ShopLogic:IsMonthCardShopShow(funType)
  local show = true
  if funType == ShopFuncType.MonthCard then
    show = BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW
  end
  return show
end

function ShopLogic:IsUnLockBeforeShop(beforeShopId)
  if beforeShopId <= 0 then
    return true
  end
  local shopInfo = Data.shopData:GetShopInfoById(beforeShopId)
  local shopGoods = shopInfo.ShopGoodsData
  if shopGoods == nil or #shopGoods <= 0 then
    return false
  end
  for _, v in pairs(shopGoods) do
    if v.Status ~= 1 then
      return false
    end
  end
  return true
end

function ShopLogic:IsShopNotLimited(limitIdList)
  local isOpen = true
  for k, lid in pairs(limitIdList) do
    local pass = Logic.gameLimitLogic.CheckConditionById(limitId)
    if not pass then
      isOpen = false
      break
    end
  end
  return isOpen
end

function ShopLogic:OpenRechargeShop()
  local currName = UIHelper.GetCurMainPageName()
  if currName == "ShopPage" then
    eventManager:SendEvent(LuaEvent.ToRechargeShop, ShopId.Recharge)
  else
    UIHelper.OpenPage("ShopPage", {
      shopId = ShopId.Recharge
    })
  end
end

function ShopLogic:OpenLuckyRechargeShop()
  local currName = UIHelper.GetCurMainPageName()
  if currName == "ShopPage" then
    eventManager:SendEvent(LuaEvent.ToRechargeShop, ShopId.LuckyRecharge)
  else
    UIHelper.OpenPage("ShopPage", {
      shopId = ShopId.LuckyRecharge
    })
  end
end

function ShopLogic:GetRefreshShopTimer()
  local config = configManager.GetData("config_shop")
  local timeTbl = {}
  for shopId, v in pairs(config) do
    local _time = self:GetRefreshShopTimerById(shopId)
    if _time and _time > time.getSvrTime() then
      table.insert(timeTbl, _time)
    end
  end
end

function ShopLogic:GetRecommendShopInfo()
  local infos = {}
  local mainShopId = 1001
  local shopCfgs = configManager.GetData("config_shop")
  for id, cfg in pairs(shopCfgs) do
    if cfg.dependence_id == mainShopId then
      table.insert(infos, cfg)
    end
  end
  return infos
end

function ShopLogic:GetTableLength(t)
  local leng = 0
  for k, v in pairs(t) do
    leng = leng + 1
  end
  return leng
end

function ShopLogic:CheckRecommendShopGoodsIsUnlock()
  local result = self:GetRecommendShopGoods()
  local resultInfo = {}
  local ServerData = Data.rechargeData:GetRechargeData().Info
  local tempList = {}
  local recommendNum = 2
  if #result < 2 then
    logError("\230\142\168\232\141\144\229\136\151\232\161\168\229\176\143\228\186\1422")
  end
  for i = 1, #result do
    local goodInfo = result[i]
    local severInfo = {
      id = goodInfo.id,
      order = goodInfo.order,
      name = goodInfo.name,
      soldout = goodInfo.soldout,
      last_id = goodInfo.last_id
    }
    table.insert(resultInfo, severInfo)
    local reachLimit, msg = Logic.gameLimitLogic.CheckConditionByArrId(goodInfo.buy_limit)
    local lastServerData = Data.rechargeData:GetRechargeData().Info
    if not reachLimit then
      logError("not reachLimit:", goodInfo)
    else
      local last_id_isOpen = false
      if goodInfo.last_id > 0 then
        if lastServerData ~= nil then
          for k, v in pairs(lastServerData) do
            if v.RechargeId == goodInfo.last_id then
              last_id_isOpen = true
            end
          end
        end
      else
        last_id_isOpen = true
      end
      local soldOut = false
      if last_id_isOpen then
        if lastServerData ~= nil then
          for k, v in pairs(lastServerData) do
            if v.RechargeId == goodInfo.id then
              soldOut = v.soldout
            end
          end
        end
        if not soldOut and recommendNum > self:GetTableLength(tempList) then
          tempList[goodInfo.id] = goodInfo
        end
      end
    end
  end
  local modifyGoods = {}
  for k, v in pairs(tempList) do
    local good = v
    local goodInfo = {
      GoodId = good.id,
      Status = good.soldout == true and 1 or 0,
      Type = good.type and RecommandGoodsType.ShopGoods or RecommandGoodsType.Recharge,
      Order = good.order or 0
    }
    table.insert(modifyGoods, goodInfo)
  end
  if recommendNum <= #modifyGoods then
    table.sort(modifyGoods, function(l, r)
      if l.Status == r.Status then
        if l.Order == r.Order then
          return l.GoodId < r.GoodId
        else
          return l.Order < r.Order
        end
      else
        return l.Status < r.Status
      end
    end)
  end
  return modifyGoods
end

function ShopLogic:CheckGoodShowIsOpen(serverRecommandData, shopData)
  local isopen = false
  local lastServerData = Data.rechargeData:GetRechargeData().Info
  for i = 1, #serverRecommandData do
    if serverRecommandData[i].id == shopData.id then
      return isopen
    end
    local goodInfo = shopData
    if lastServerData ~= nil then
      for k, v in pairs(lastServerData) do
        if v.RechargeId == goodInfo.id and v.LimitBuyTimes <= v.BuyTimes then
          return isopen
        end
      end
    end
    if goodInfo.type and goodInfo.type == RecommandGoodsType.ShopGoods then
      local shopGoods = clone(configManager.GetDataById("config_shop_goods", goodInfo.id))
      local itemInfo = Logic.bagLogic:GetItemByTempateId(shopGoods.goods[1], shopGoods.goods[2])
      if shopGoods.buy_limits or shopGoods.last_id or shopGoods.price[1][1] == 0 then
        return isopen
      end
    end
    if goodInfo.last_id and goodInfo.last_id > 0 then
      if lastServerData ~= nil then
        for k, v in pairs(lastServerData) do
          if v.RechargeId == goodInfo.last_id then
            isopen = true
          end
        end
      end
    else
      isopen = true
    end
  end
  return isopen
end

function ShopLogic:RefreshRecommendShopGoods()
  local shopsInfo = Data.shopData:GetTempMsgData()
  local modifyInfo = Logic.shopLogic:CheckRecommendShopGoodsIsUnlock()
  if 2 <= #modifyInfo and shopsInfo then
    shopsInfo.GoodList = modifyInfo
    Data.shopData:SetShopsInfo(shopsInfo)
  end
end

function ShopLogic:GetRecommendShopGoods()
  local result = {}
  local goodsList = Data.shopData:GetRecommendGoods()
  for i, info in ipairs(goodsList) do
    if info.Type == RecommandGoodsType.Recharge then
      local recharge = clone(configManager.GetDataById("config_recharge", info.GoodId))
      recharge.soldout = info.Status == 1
      table.insert(result, recharge)
    else
      local shopGoods = clone(configManager.GetDataById("config_shop_goods", info.GoodId))
      local itemInfo = Logic.bagLogic:GetItemByTempateId(shopGoods.goods[1], shopGoods.goods[2])
      shopGoods.soldout = info.Status == 1
      shopGoods.recommend_bg1 = itemInfo.recommend_bg1
      shopGoods.recommend_bg2 = itemInfo.recommend_bg2
      table.insert(result, shopGoods)
    end
  end
  return result
end

function ShopLogic:GetRecommendShopGoodsGridId(goodsId)
  local shopInfo = Data.shopData:GetShopInfoById(ShopId.Gift)
  local shopGoods = shopInfo.ShopGoodsData
  for k, v in pairs(shopGoods) do
    if v.GoodsId == goodsId then
      return v.GridId
    end
  end
  return -1
end

function ShopLogic:GetOpenOrRefreshAllTimer()
  local tabShopFreshOrOpenTime = {}
  local tabShopTimer = self:GetShopConfigInfo()
  for k, v in pairs(tabShopTimer) do
    local tblRes = self:GetOneShopRefreshData(v)
    tblInsert(tabShopFreshOrOpenTime, tblRes)
  end
  table.sort(timeTbl, function(a, b)
    return a < b
  end)
  if #timeTbl <= 0 then
    return nil
  else
    return timeTbl[1]
  end
end

function ShopLogic:GetRefreshShopTimerById(shopId)
  local shopConfig = configManager.GetDataById("config_shop", shopId)
  local refreshIds = shopConfig.refresh_time
  if #refreshIds == 0 then
    return nil
  else
    return PeriodManager:GetNextRefreshTimeInIds(refreshIds)
  end
  return nil
end

function ShopLogic.__GetDayStr(nDay)
  if nDay < 10 then
    return "0" .. nDay
  else
    return tostring(nDay)
  end
end

function ShopLogic:__GetCurMonthInterval()
  local curDay = self.curDay
  local curMonth = self.curMonthTime
  local curYear = self.curYearTime
  local nNextYear, strNextMonthIndex = self.__GetNextMonthIndex(curYear, curMonth)
  local strDay = self.__GetDayStr(curDay)
  local nNextMonthTime = time.getIntervalByString(nNextYear .. strNextMonthIndex .. strDay .. "000000")
  local nCurDayZeroTime = self.curDayZeroTime
  return nNextMonthTime - nCurDayZeroTime
end

function ShopLogic.__GetNextMonthIndex(nCurYear, nCurMonth)
  if nCurMonth == 12 then
    return nCurYear + 1, "01"
  end
  local nNextMonth = nCurMonth + 1
  if nNextMonth < 10 then
    return nCurYear, "0" .. nNextMonth
  else
    return nCurYear, tostring(nNextMonth)
  end
end

function ShopLogic:GetTableBuyCurrency(currency)
  local tabCondition = {}
  for i = 1, #currency do
    local currencyInfo = currency[i]
    local tabInfo = {
      Type = currencyInfo[1],
      CurrencyId = currencyInfo[2],
      CostNum = currencyInfo[3]
    }
    table.insert(tabCondition, tabInfo)
  end
  return tabCondition
end

function ShopLogic:GetUserCurrencyNum(currencyId)
  return Data.userData:GetCurrency(currencyId)
end

function ShopLogic:GetNeedCurrencInfoByShopId(shopId)
  local tabCurrencyInfo = {
    [ShopId.Spa] = self:GetCurrencyById(CurrencyType.SPA),
    [ShopId.Retire] = self:GetCurrencyById(CurrencyType.RETIRE),
    [ShopId.Equip] = self:GetCurrencyById(CurrencyType.MAINGUN),
    [ShopId.MainGun] = self:GetCurrencyById(CurrencyType.TORPEDO),
    [ShopId.Torpedo] = self:GetCurrencyById(CurrencyType.TORPEDO)
  }
  return tabCurrencyInfo[shopId]
end

function ShopLogic:IsOpenByShopId(shopId, isNoti)
  local shopConfig = configManager.GetDataById("config_shop", shopId)
  if shopConfig.activatetime ~= 0 and time.getSvrTime() < shopConfig.activatetime then
    return false
  end
  if 0 < shopConfig.activity_id and not Logic.activityLogic:CheckActivityOpenById(shopConfig.activity_id) then
    return false
  end
  local isHide = shopConfig.is_hide
  if isHide == 0 then
    local periodId = shopConfig.open_period
    local periodArea = shopConfig.open_period_area
    if periodId <= 0 then
      return true
    else
      local periodResult = PeriodManager:IsInPeriodArea(periodId, periodArea)
      if periodResult then
        return true
      else
        if isNoti == true then
          noticeManager:ShowTip(UIHelper.GetString(270022))
        end
        return false
      end
    end
  end
  return false
end

function ShopLogic:CheckBuyGoodsCondition(shopId, goodsData)
  local isOpen = self:IsOpenByShopId(shopId, true)
  if not isOpen then
    return false
  end
  local isInPeriod = #goodsData.period_buy <= 0
  if #goodsData.period_buy > 0 then
    for _, perId in pairs(goodsData.period_buy) do
      if PeriodManager:IsInPeriod(perId) then
        isInPeriod = true
        break
      end
      isInPeriod = false
    end
  end
  if not isInPeriod then
    Logic.shopLogic:ShowPeriodEndTips(goodsData.period_show)
    return false
  end
  return true
end

function ShopLogic:IsShopRefreshById(shopId)
  local shopConfig = configManager.GetDataById("config_shop", shopId)
  local refreshIds = shopConfig.refresh_time
  return 0 < #refreshIds
end

function ShopLogic:CanExpandById(itemId)
  if itemId == EXPANDITEM.SHIP then
    local limit = configManager.GetDataById("config_parameter", 129).value
    local currDock = Logic.shipLogic:GetBaseShipNum()
    if limit <= currDock then
      noticeManager:OpenTipPage(self, UIHelper.GetString(920000073))
      return false
    end
  elseif itemId == EXPANDITEM.EQUIP then
    local limit = configManager.GetDataById("config_parameter", 131).value
    local currEquipBag = Data.equipData:GetEquipBagSize()
    if limit <= currEquipBag then
      noticeManager:OpenTipPage(self, UIHelper.GetString(920000074))
      return false
    end
  end
  return true
end

function ShopLogic:BuyGoods(param)
  local num = param.buyNum
  local priceTab = {}
  for i, v in ipairs(param.goodData.currency) do
    local price = self:GetPriceByNum(param.goodData.price[i], param.purchaseNum, num)
    table.insert(priceTab, {
      goodsData.currency[i][1],
      goodsData.currency[i][2],
      price
    })
  end
  local tabCondition = Logic.shopLogic:GetTableBuyCurrency(priceTab, num)
  local isCan = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
  if isCan then
    Service.shopService:SendBuyGoods(param.shopId, param.goodId, num)
    noticeManager:ShowTip(UIHelper.GetString(230006))
    local costNum = {}
    local currencyNum = {}
    for k, v in pairs(tabCondition) do
      costNum[tostring(v.CurrencyId)] = tostring(v.CostNum)
      currencyNum[tostring(v.CurrencyId)] = tostring(Data.userData:GetCurrency(v.CurrencyId))
    end
    local dotinfo = {
      info = "ui_shop_buy",
      item_num = {
        [tostring(param.goodData.goods[2])] = tostring(num)
      },
      cost_num = costNum,
      currency_num = currencyNum
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    UIHelper.CloseCurrentPage()
  end
end

function ShopLogic:GetGoodDataById(shopId, grid)
  local shopInfo = Data.shopData:GetShopInfoById(shopId)
  return shopInfo.ShopGoodsData[grid + 1]
end

function ShopLogic:GetItemShopInfo(itemId, shopId)
  local buyShopId = shopId or ShopId.Diamond
  if next(self.buyItemInfo) == nil or self.buyItemInfo[itemId] == nil then
    local shopData = Data.shopData:GetShopInfoById(buyShopId)
    for _, goodsTab in ipairs(shopData.ShopGoodsData) do
      local goodsInfo = Logic.shopLogic:GetGoodsInfoById(goodsTab.GoodsId)
      if goodsInfo.goods[2] == itemId then
        local info = {}
        info.shopId = buyShopId
        info.goodId = goodsInfo.id
        info.goodsData = goodsTab
        info.goodsCurrency = goodsInfo.currency
        info.goodsPrice = goodsInfo.price
        self.buyItemInfo[itemId] = info
        break
      end
    end
  end
  return self.buyItemInfo[itemId]
end

function ShopLogic:BuyExpendItem(itemId, buyNum, shopId, str)
  local shopInfo = self:GetItemShopInfo(itemId, shopId)
  if not shopInfo then
    logError("\229\149\134\229\186\151\230\178\161\230\156\137\231\137\169\229\147\129\228\191\161\230\129\175 itemId: " .. itemId)
    return
  end
  local priceTab = {}
  local price = self:GetPriceByNum(shopInfo.goodsPrice[1], shopInfo.goodsData.Num, buyNum)
  table.insert(priceTab, {
    shopInfo.goodsCurrency[1][1],
    shopInfo.goodsCurrency[1][2],
    price
  })
  local config = Logic.bagLogic:GetItemByConfig(itemId)
  local costNum = price
  local costName = Logic.goodsLogic:GetName(shopInfo.goodsCurrency[1][2], shopInfo.goodsCurrency[1][1])
  local cost = costNum .. costName
  str = string.format(str, config.name, cost, config.name, buyNum)
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        local tabCondition = Logic.shopLogic:GetTableBuyCurrency(priceTab, buyNum)
        local canBuy = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
        if canBuy then
          Service.shopService:SendBuyGoods(shopInfo.shopId, shopInfo.goodId, buyNum)
        end
      end
    end
  }
  noticeManager:ShowMsgBox(str, tabParams)
end

function ShopLogic:GetBuyMaxNum(data, itemId, selectPrice)
  local goodsData = data.goodData
  local goodsType = goodsData.goods[1]
  local goodsSerData = data.goodsSerData
  local maxNum = goodsData.is_buy_batch * 10
  if goodsType == GoodsType.EXPAND_ITEM then
    local expandNum = configManager.GetDataById("config_expand_item", itemId).expand_num
    if itemId == EXPANDITEM.SHIP then
      local limit = configManager.GetDataById("config_parameter", 129).value
      local currDock = Logic.shipLogic:GetBaseShipNum()
      local num = limit - currDock == 0 and 1 or math.floor((limit - currDock) / expandNum)
      if maxNum > num then
        maxNum = num or maxNum
      end
    elseif itemId == EXPANDITEM.EQUIP then
      local limit = configManager.GetDataById("config_parameter", 131).value
      local currEquipBag = Data.equipData:GetEquipBagSize()
      local num = limit - currEquipBag == 0 and 1 or math.floor((limit - currEquipBag) / expandNum)
      maxNum = maxNum > num and num or maxNum
    end
  end
  local stock = goodsData.stock
  if stock ~= -1 then
    local goodsSerInfo = self:GetGoodDataById(data.shopId, data.gridId)
    local availableNum = stock - goodsSerInfo.Num
    maxNum = math.min(availableNum, maxNum)
  end
  for i, v in ipairs(goodsData.currency) do
    if selectPrice == 0 or selectPrice == i then
      local mType = v[1]
      local mId = v[2]
      local priceTab = goodsData.price[i]
      local value = 0
      if mType == GoodsType.CURRENCY then
        value = self:GetUserCurrencyNum(mId)
      else
        local bagInfo = Logic.bagLogic:GetAllBagItem(mId)
        value = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
      end
      local tempNum = 0
      local buyNum = goodsSerData.Num + 1
      if buyNum < #priceTab then
        for i = 1, #priceTab - goodsSerData.Num do
          local cost = priceTab[goodsSerData.Num + i]
          value = value - cost
          tempNum = value <= 0 and 1 or i
          if value <= 0 then
            break
          end
        end
        if value >= priceTab[#priceTab] then
          tempNum = tempNum + math.floor(value / priceTab[#priceTab])
        end
      else
        local price = priceTab[#priceTab]
        tempNum = value == 0 and 1 or math.floor(value / price)
      end
      if tempNum == 0 then
        maxNum = 1
      else
        maxNum = tempNum < maxNum and tempNum or maxNum
      end
    end
  end
  return maxNum
end

function ShopLogic:IsOpendCondGood(goodType, goodId)
  local condGood = Data.shopData:GetOpendCondGood(goodType, goodId)
  if condGood[goodType] == nil then
    return false
  end
  return condGood[goodType][goodId] ~= nil
end

function ShopLogic:GetShowGoodsInfo(shopId)
  local shopInfo = Data.shopData:GetShopInfoById(shopId)
  local goodsInfo = clone(shopInfo)
  local temp = {}
  local goodsData = shopInfo.ShopGoodsData
  for i = 1, #goodsData do
    if goodsData[i].Visible then
      table.insert(temp, goodsData[i])
    end
  end
  goodsInfo.ShopGoodsData = temp
  return goodsInfo
end

function ShopLogic:GetFashionShopInfo(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  local shopId = fashionCfg.shop_id
  local fashionShop = Data.shopData:GetShopInfoById(shopId)
  if fashionShop then
    for i, goodsData in ipairs(fashionShop.ShopGoodsData) do
      local goodsCfg = configManager.GetDataById("config_shop_goods", goodsData.GoodsId)
      if goodsCfg.goods[2] == fashionId then
        local isInPeriod = #goodsCfg.period_buy <= 0
        if #goodsCfg.period_buy > 0 then
          for _, perId in pairs(goodsCfg.period_buy) do
            if PeriodManager:IsInPeriod(perId) then
              isInPeriod = true
              break
            end
            isInPeriod = false
          end
        end
        if isInPeriod then
          return goodsData.GridId, goodsCfg, goodsData
        end
      end
    end
  end
  return nil, nil
end

function ShopLogic:GetFashionBuyParams(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  local params = {}
  params.shopId = fashionCfg.shop_id
  local gridId, goodsCfg, goodsSerData = self:GetFashionShopInfo(fashionId)
  if not gridId then
    return nil, UIHelper.GetString(920000075)
  end
  params.gridId = gridId
  params.goodsCfg = goodsCfg
  params.fashionCfg = fashionCfg
  params.buyNum = 1
  params.dotInfo = "ui_shop_fashion_buy"
  params.goodsSerData = goodsSerData
  return params, nil
end

local DailyShopId = {
  ["7"] = 20001,
  ["15"] = 20002,
  ["16"] = 20003,
  ["17"] = 20004
}

function ShopLogic:_RefreshDailyShopRed(ret)
  if ret.CopyType ~= ChapterType.DailyCopy then
    return
  end
  local newDailyId = Data.copyData:GetPassDailyCopyId()
  if newDailyId == 0 then
    return
  end
  local chapter = Logic.copyLogic:GetChapterIdByCopyId(newDailyId)
  if chapter == nil then
    return
  end
  for shopId, chapterId in pairs(DailyShopId) do
    if chapterId == chapter then
      local goodsSerData = Data.shopData:GetShopInfoById(tonumber(shopId))
      if goodsSerData == nil then
        return
      end
      for _, goodsInfo in ipairs(goodsSerData.ShopGoodsData) do
        local goodData = Logic.shopLogic:GetGoodsInfoById(goodsInfo.GoodsId)
        for _, v in ipairs(goodData.buy_limits) do
          local reachLimit, _ = Logic.gameLimitLogic.CheckConditionById(v)
          if reachLimit then
            PlayerPrefs.SetBool("DailySubShop" .. shopId, true)
            eventManager:SendEvent(LuaEvent.UpdateDailyShop)
            return
          end
        end
      end
    end
  end
end

function ShopLogic:DailySubShop()
  for shopId, v in pairs(DailyShopId) do
    local temp = PlayerPrefs.GetBool("DailySubShop" .. shopId, false)
    if temp then
      return true
    end
  end
  return false
end

function ShopLogic:DailyShopSort(ShopGoodsData)
  local reachLimitTab = {}
  local normalTab = {}
  for i, goodsInfo in ipairs(ShopGoodsData) do
    local goodData = Logic.shopLogic:GetGoodsInfoById(goodsInfo.GoodsId)
    if #goodData.buy_limits == 0 then
      table.insert(normalTab, goodsInfo)
    else
      for _, v in ipairs(goodData.buy_limits) do
        local reachLimit, _ = Logic.gameLimitLogic.CheckConditionById(v)
        if reachLimit then
          table.insert(reachLimitTab, goodsInfo)
        else
          table.insert(normalTab, goodsInfo)
        end
      end
    end
  end
  if next(reachLimitTab) ~= nil then
    table.insertto(reachLimitTab, normalTab)
    return reachLimitTab
  else
    return normalTab
  end
end

function ShopLogic:SetHasRechargeState(state)
  self.rechargeState = state
end

function ShopLogic:GetHasRechage()
  return self.rechargeState
end

function ShopLogic:FashionShopSort(shopGoodsData, shopId)
  local fashionId, shipId, temp = 0, 0
  for i, v in ipairs(shopGoodsData) do
    fashionId = Logic.shopLogic:GetGoodsInfoById(v.GoodsId).goods[2]
    shipId = Logic.fashionLogic:ftos(fashionId)
    temp = shopGoodsData[i]
    temp.fashionId = fashionId
    temp.ship = shipId
    temp.type = Logic.illustrateLogic:GetIllustrateConfigById(shipId).type
    temp.shipCountry = Logic.illustrateLogic:GetIllustrateConfigById(shipId).ship_country
    temp.quality = Logic.illustrateLogic:GetIllustrateConfigById(shipId).quality
  end
  local sets = {}
  if shopId == ShopId.Fashion then
    sets = Logic.sortLogic:GetHeroSort(CommonHeroItem.ShopFashion)
  elseif shopId == ShopId.BrokenFashion then
    sets = Logic.sortLogic:GetHeroSort(CommonHeroItem.ShopBrokenFashion)
  end
  local filterGoods = HeroSortHelper.ShopFashionFiler(shopGoodsData, sets[2][1])
  local ownTab = {}
  local otherTab = {}
  for i, goodsInfo in ipairs(filterGoods) do
    local goodsConfig = Logic.shopLogic:GetGoodsInfoById(goodsInfo.GoodsId)
    local ownFashion = Logic.fashionLogic:CheckFashionOwn(goodsConfig.goods[2])
    if ownFashion then
      table.insert(ownTab, goodsInfo)
    else
      table.insert(otherTab, goodsInfo)
    end
  end
  if next(ownTab) ~= nil then
    table.insertto(otherTab, ownTab)
  end
  return otherTab
end

function ShopLogic:ShopSpecialSort(shopGoodsData, shopConfig)
  if shopConfig.dependence_id == ShopId.DailyCopy then
    return self:DailyShopSort(shopGoodsData)
  elseif shopConfig.id == ShopId.Fashion or shopConfig.id == ShopId.BrokenFashion then
    return self:FashionShopSort(shopGoodsData, shopConfig.id)
  end
  return shopGoodsData
end

function ShopLogic:CheckShopNewFashion(shopId)
  local status = false
  local fashionData = Data.shopData:GetShopInfoById(shopId)
  if fashionData then
    for i, goodsData in ipairs(fashionData.ShopGoodsData) do
      local goodsCfg = Logic.shopLogic:GetGoodsInfoById(goodsData.GoodsId)
      if goodsCfg.new == 1 then
        local isRecord = PlayerPrefs.GetBool("ShopNewFashion" .. goodsData.GoodsId, false)
        if not isRecord then
          return true
        end
      end
    end
  end
  return status
end

function ShopLogic:GetPriceByNum(priceTab, serNum, buyNum)
  local price = 0
  if #priceTab > serNum + 1 then
    for i = 1, #priceTab - serNum do
      price = price + priceTab[serNum + i]
      buyNum = buyNum - 1
      if buyNum <= 0 then
        break
      end
    end
    if 1 <= buyNum then
      price = price + priceTab[#priceTab] * buyNum
    end
  else
    price = priceTab[#priceTab] * buyNum
  end
  return price
end

function ShopLogic:BuyExtendItemWrap(id)
  local shopInfo = Logic.shopLogic:GetShowGoodsInfo(ShopId.Diamond)
  if shopInfo == nil or shopInfo.ShopGoodsData == nil then
    logError("find shop data failure")
    return
  end
  local shopConfig = configManager.GetDataById("config_shop", ShopId.Diamond)
  if shopConfig == nil then
    logError("find shop config failure")
    return
  end
  local goodsSerData = {}
  if shopConfig.sold_out == 1 then
    for _, v in ipairs(shopInfo.ShopGoodsData) do
      if v.Status ~= BuyStatus.HaveBuy then
        table.insert(goodsSerData, v)
      end
    end
  else
    goodsSerData = shopInfo.ShopGoodsData
  end
  local goodData, goodSerData, goodsInfo
  for _, v in pairs(goodsSerData) do
    goodData = Logic.shopLogic:GetGoodsInfoById(v.GoodsId)
    if goodData.goods[1] == GoodsType.EXPAND_ITEM and goodData.goods[2] == id then
      goodSerData = v
      break
    end
  end
  if goodSerData then
    goodsInfo = Logic.bagLogic:GetItemByTempateId(goodData.goods[1], goodData.goods[2])
    if goodsInfo == nil then
      logError("find product config failure")
      return
    end
  else
    logError("find product data failure")
    return
  end
  local canBuyNum = -1
  if goodData.stock ~= -1 then
    canBuyNum = goodData.stock - goodSerData.Num
  end
  local bIsRefresh = self:IsShopRefreshById(ShopId.Diamond)
  local soldout = goodSerData.Status == BuyStatus.HaveBuy and bIsRefresh or canBuyNum == 0
  if goodData.undercarriage == 1 then
    soldout = true
  end
  local reachLimit = true
  local msg = ""
  for _, v in ipairs(goodData.buy_limits) do
    reachLimit, msg = Logic.gameLimitLogic.CheckConditionById(v)
    if not reachLimit then
      local limitConfig = configManager.GetDataById("config_game_limits", v)
      msg = limitConfig.desc .. UIHelper.GetString(270035)
      break
    end
  end
  local isInPeriod = 0 >= #goodData.period_buy
  if 0 < #goodData.period_buy then
    for _, perId in pairs(goodData.period_buy) do
      if PeriodManager:IsInPeriod(perId) then
        isInPeriod = true
        break
      end
      isInPeriod = false
    end
  end
  if soldout then
    noticeManager:OpenTipPage(self, 270007)
  elseif not reachLimit then
    noticeManager:OpenTipPage(self, msg)
  elseif not isInPeriod then
    Logic.shopLogic:ShowPeriodEndTips(goodData.period_show)
  else
    noticeManager:CloseTip()
    local buyNum = goodData.is_buy_batch ~= 0 and goodData.goods[3] or 1
    local canBuyBatch = goodData.is_buy_batch ~= 0
    if goodData.stock == 1 and goodData.is_buy_batch ~= 0 then
      logError("\229\186\147\229\173\152\228\184\1861\231\154\132\229\149\134\229\147\129\239\188\140\228\184\141\232\131\189\230\137\185\233\135\143\232\180\173\228\185\176\239\188\140\233\128\154\231\159\165\231\173\150\229\136\146\228\191\174\230\148\185\227\128\130\229\149\134\229\147\129id\239\188\154", goodData.id)
    end
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    local param = ItemInfoPage:BuyShopItemPage(ShopId.Diamond, buyNum, goodsInfo, goodData, nil, canBuyBatch, goodSerData.GridId, goodSerData)
    UIHelper.OpenPage("ItemInfoPage", param)
  end
end

function ShopLogic:ShowItemInfo(shopId, itemID)
  local shopInfo = Logic.shopLogic:GetShowGoodsInfo(shopId)
  if shopInfo == nil or shopInfo.ShopGoodsData == nil then
    logError("find shop data failure")
    return
  end
  local goodsSerData = shopInfo.ShopGoodsData
  local goodData = {}
  local goodsShowTab = {}
  local soldout = false
  local reachLimit = true
  local msg = ""
  local isInPeriod = true
  for _, v in pairs(goodsSerData) do
    goodData = Logic.shopLogic:GetGoodsInfoById(v.GoodsId)
    if goodData.goods[2] == itemID then
      local canBuyNum = -1
      if goodData.stock ~= -1 then
        canBuyNum = goodData.stock - v.Num
      end
      local bIsRefresh = self:IsShopRefreshById(shopId)
      soldout = v.Status == BuyStatus.HaveBuy and bIsRefresh or canBuyNum == 0
      if goodData.undercarriage == 1 then
        soldout = true
      end
      for _, limitID in ipairs(goodData.buy_limits) do
        reachLimit, msg = Logic.gameLimitLogic.CheckConditionById(limitID)
        if not reachLimit then
          local limitConfig = configManager.GetDataById("config_game_limits", limitID)
          msg = limitConfig.desc .. UIHelper.GetString(270035)
          break
        end
      end
      isInPeriod = 0 >= #goodData.period_buy
      if 0 < #goodData.period_buy then
        for _, perId in pairs(goodData.period_buy) do
          if PeriodManager:IsInPeriod(perId) then
            isInPeriod = true
            break
          end
          isInPeriod = false
        end
      end
      if not soldout and reachLimit and isInPeriod then
        table.insert(goodsShowTab, {goodData = goodData, goodSerData = v})
      end
    end
  end
  if 0 < #goodsShowTab then
    table.sort(goodsShowTab, function(data1, data2)
      return data1.goodSerData.GridId < data2.goodSerData.GridId
    end)
    local goodInfo = goodsShowTab[1]
    noticeManager:CloseTip()
    local buyNum = goodInfo.goodData.is_buy_batch ~= 0 and goodInfo.goodData.goods[3] or 1
    local canBuyBatch = goodInfo.goodData.is_buy_batch ~= 0
    if goodInfo.goodData.stock == 1 and goodInfo.goodData.is_buy_batch ~= 0 then
      logError("\229\186\147\229\173\152\228\184\1861\231\154\132\229\149\134\229\147\129\239\188\140\228\184\141\232\131\189\230\137\185\233\135\143\232\180\173\228\185\176\239\188\140\233\128\154\231\159\165\231\173\150\229\136\146\228\191\174\230\148\185\227\128\130\229\149\134\229\147\129id\239\188\154", goodInfo.goodData.id)
    end
    local bagInfo = Logic.bagLogic:GetItemByTempateId(goodInfo.goodData.goods[1], goodInfo.goodData.goods[2])
    if bagInfo == nil then
      logError("find product config failure")
      return
    end
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    local param = ItemInfoPage:BuyShopItemPage(shopId, buyNum, bagInfo, goodInfo.goodData, nil, canBuyBatch, goodInfo.goodSerData.GridId, goodInfo.goodSerData)
    UIHelper.OpenPage("ItemInfoPage", param)
  elseif soldout then
    noticeManager:OpenTipPage(self, 270007)
  elseif not reachLimit then
    noticeManager:OpenTipPage(self, msg)
  elseif not isInPeriod then
    Logic.shopLogic:ShowPeriodEndTips(goodData.period_show)
  end
end

function ShopLogic:BuyExtendItemOkWrap(param)
  local goodsInfo = Logic.shopLogic:GetGoodsInfoById(param.GoodId)
  local costNum = {}
  local currencyNum = {}
  local goodsNum = param.BuyNum
  for k, v in pairs(goodsInfo.currency) do
    costNum[tostring(v[2])] = tostring(goodsInfo.price[k][1] * goodsNum)
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
  noticeManager:OpenTipPage(self, 230006)
end

function ShopLogic:GetPeriodText(periodId, timeLimitType)
  timeLimitType = timeLimitType == nil and 1 or timeLimitType
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(periodId)
  local day, hour, min = time.getDHMDiff(endTime)
  local descTime = ""
  if 0 < day then
    descTime = string.format(UIHelper.GetString(PeriodTextTab[timeLimitType][1]), tostring(day))
  elseif 0 < hour then
    descTime = string.format(UIHelper.GetString(PeriodTextTab[timeLimitType][2]), tostring(hour))
  else
    min = 0 < min and min or 1
    descTime = string.format(UIHelper.GetString(PeriodTextTab[timeLimitType][3]), tostring(min))
  end
  return descTime
end

function ShopLogic:ShowPeriodEndTips(timeLimitType)
  timeLimitType = timeLimitType == nil and 1 or timeLimitType
  timeLimitType = timeLimitType == 0 and 1 or timeLimitType
  local txt = UIHelper.GetString(PeriodEndTips[timeLimitType])
  noticeManager:OpenTipPage(self, txt)
end

function ShopLogic:FashionGoodsPosScale(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  local ss_config = configManager.GetDataById("config_ship_show", fashionCfg.ship_show_id)
  local shipPosConf = configManager.GetDataById("config_ship_position", ss_config.ss_id)
  local position = shipPosConf.fashion_shop_position
  local scaleSize = shipPosConf.fashion_shop_scale / 10000
  local mirror = shipPosConf.fashion_shop_inversion
  local scale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  return position, scale
end

function ShopLogic:CheckGoodCanBuy(shopId, goodId)
  local shopInfo = Logic.shopLogic:GetShowGoodsInfo(shopId)
  if shopInfo == nil or shopInfo.ShopGoodsData == nil then
    logError("find shop data failure")
    return
  end
  local goodsSerData = shopInfo.ShopGoodsData
  local goodData = {}
  local soldout = false
  local reachLimit = true
  local isInPeriod = true
  for _, v in pairs(goodsSerData) do
    goodData = Logic.shopLogic:GetGoodsInfoById(v.GoodsId)
    if goodData.id == goodId then
      local canBuyNum = -1
      if goodData.stock ~= -1 then
        canBuyNum = goodData.stock - v.Num
      end
      local bIsRefresh = self:IsShopRefreshById(shopId)
      soldout = v.Status == BuyStatus.HaveBuy and bIsRefresh or canBuyNum == 0
      if goodData.undercarriage == 1 then
        soldout = true
      end
      for _, limitID in ipairs(goodData.buy_limits) do
        reachLimit, _ = Logic.gameLimitLogic.CheckConditionById(limitID)
      end
      isInPeriod = 0 >= #goodData.period_buy
      if 0 < #goodData.period_buy then
        for _, perId in pairs(goodData.period_buy) do
          if PeriodManager:IsInPeriod(perId) then
            isInPeriod = true
            break
          end
          isInPeriod = false
        end
      end
      return not soldout and reachLimit and isInPeriod
    end
  end
  return false
end

return ShopLogic
