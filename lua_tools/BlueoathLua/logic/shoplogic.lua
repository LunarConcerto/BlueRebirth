local ShopLogic = class("logic.ShopLogic")
local tblInsert = table.insert
local expandDockId = 140001
local expandEquipId = 140002
local PeriodTextTab = {
  {
    270036,
    270037,
    270040
  },
  {
    270050,
    270051,
    270052
  }
}
local PeriodEndTips = {270038, 270053}

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

function ShopLogic:GetTableBuyCurrency(currency, goodsNum, discountInfo)
  local tabCondition = {}
  for i = 1, #currency do
    local currencyInfo = currency[i]
    local cost = 0
    if #discountInfo ~= 0 then
      for _, v in ipairs(discountInfo) do
        goodsNum = goodsNum - 1
        cost = cost + self:GetDiscountPrice(currencyInfo[3], v)
      end
    end
    cost = cost + currencyInfo[3] * goodsNum
    local tabInfo = {
      Type = currencyInfo[1],
      CurrencyId = currencyInfo[2],
      CostNum = cost
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
  if itemId == expandDockId then
    local limit = configManager.GetDataById("config_parameter", 129).value
    local currDock = Logic.shipLogic:GetBaseShipNum()
    if limit <= currDock then
      noticeManager:OpenTipPage(self, "\232\136\185\229\157\158\229\183\178\230\137\169\229\177\149\229\136\176\230\156\128\229\164\167\229\174\185\233\135\143")
      return false
    end
  elseif itemId == expandEquipId then
    local limit = configManager.GetDataById("config_parameter", 131).value
    local currEquipBag = Data.equipData:GetEquipBagSize()
    if limit <= currEquipBag then
      noticeManager:OpenTipPage(self, "\228\187\147\229\186\147\229\183\178\230\137\169\229\177\149\229\136\176\230\156\128\229\164\167\229\174\185\233\135\143")
      return false
    end
  end
  return true
end

function ShopLogic:BuyGoods(param)
  local num = param.buyNum
  local tabCondition = Logic.shopLogic:GetTableBuyCurrency(param.goodData.price2, num)
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

function ShopLogic:GetItemShopInfo(itemId)
  if next(self.buyItemInfo) == nil or self.buyItemInfo[itemId] == nil then
    local shopData = Data.shopData:GetShopInfoById(ShopId.Diamond)
    for _, goodsTab in ipairs(shopData.ShopGoodsData) do
      local goodsInfo = Logic.shopLogic:GetGoodsInfoById(goodsTab.GoodsId)
      if goodsInfo.goods[2] == itemId then
        local info = {}
        info.shopId = ShopId.Diamond
        info.goodId = goodsInfo.id
        info.goodsData = goodsTab
        info.goodsPrice = goodsInfo.price2
        self.buyItemInfo[itemId] = info
        break
      end
    end
  end
  return self.buyItemInfo[itemId]
end

function ShopLogic:BuyExpendItem(itemId, buyNum, str)
  local shopInfo = self:GetItemShopInfo(itemId)
  if not shopInfo then
    logError("\229\149\134\229\186\151\230\178\161\230\156\137\231\137\169\229\147\129\228\191\161\230\129\175 itemId: " .. itemId)
    return
  end
  local config = Logic.bagLogic:GetItemByConfig(itemId)
  local costNum = shopInfo.goodsPrice[1][3] * buyNum
  local discountInfo = Logic.shopLogic:GetUsableDiscountConf(shopInfo.goodId)
  local useDisInfoTab = {}
  if discountInfo ~= nil then
    local ownSameDisc = Logic.bagLogic:GetPeriodItemByTid(discountInfo.data.templateId)
    if buyNum >= #ownSameDisc then
      useDisInfoTab = ownSameDisc
    elseif buyNum < #ownSameDisc then
      for i = 1, buyNum do
        table.insert(useDisInfoTab, ownSameDisc[1])
      end
    end
    local sale = Logic.shopLogic:GetDiscountPrice(shopInfo.goodsPrice[1][3], useDisInfoTab[1])
    costNum = sale * #useDisInfoTab + shopInfo.goodsPrice[1][3] * (buyNum - #useDisInfoTab)
  end
  local costName = Logic.goodsLogic:GetName(shopInfo.goodsPrice[1][2], shopInfo.goodsPrice[1][1])
  local cost = costNum .. costName
  str = string.format(str, config.name, cost, buyNum, config.name)
  if discountInfo ~= nil then
    local discountStr = string.format(UIHelper.GetString(2800005), #useDisInfoTab, discountInfo.config.name)
    str = str .. discountStr
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        local valid = false
        local inProideId = {}
        if #useDisInfoTab ~= 0 then
          valid, inProideId = Logic.shopLogic:CheckDiscountProide(useDisInfoTab)
          if not valid then
            return
          end
        end
        local tabCondition = Logic.shopLogic:GetTableBuyCurrency(shopInfo.goodsPrice, buyNum, useDisInfoTab)
        local canBuy = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
        if canBuy then
          Service.shopService:SendBuyGoods(shopInfo.shopId, shopInfo.goodId, buyNum, inProideId)
        end
      end
    end
  }
  noticeManager:ShowMsgBox(str, tabParams)
end

function ShopLogic:GetBuyMaxNum(data, itemId, discountInfo)
  local goodsData = data.goodData
  local goodsType = goodsData.goods[1]
  local maxNum = goodsData.is_buy_batch * 10
  if goodsType == GoodsType.EXPAND_ITEM then
    local expandNum = configManager.GetDataById("config_expand_item", itemId).expand_num
    if itemId == expandDockId then
      local limit = configManager.GetDataById("config_parameter", 129).value
      local currDock = Logic.shipLogic:GetBaseShipNum()
      local num = limit - currDock == 0 and 1 or math.floor((limit - currDock) / expandNum)
      if maxNum > num then
        maxNum = num or maxNum
      end
    elseif itemId == expandEquipId then
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
  for _, v in ipairs(goodsData.price2) do
    local mType = v[1]
    local mId = v[2]
    local price = v[3]
    local value = 0
    if mType == GoodsType.CURRENCY then
      value = self:GetUserCurrencyNum(mId)
    else
      value = Data.bagData:GetItemNum(mId)
    end
    local tempNum = 0
    if #discountInfo ~= 0 and value ~= 0 then
      local single = Logic.shopLogic:GetDiscountPrice(price, discountInfo[1])
      local saleNum = 0
      for i = 1, #discountInfo do
        if value > single * i then
          saleNum = i
        else
          break
        end
      end
      tempNum = saleNum + math.floor((value - single * saleNum) / price)
    else
      tempNum = value == 0 and 1 or math.floor(value / price)
    end
    if tempNum == 0 then
      maxNum = 1
    else
      maxNum = tempNum < maxNum and tempNum or maxNum
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
  local fashionShop = Data.shopData:GetShopInfoById(ShopId.Fashion)
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
          return goodsData.GridId, goodsCfg
        end
      end
    end
  end
  return nil, nil
end

function ShopLogic:GetFashionBuyParams(fashionId)
  local params = {}
  params.shopId = ShopId.Fashion
  local gridId, goodsCfg = self:GetFashionShopInfo(fashionId)
  if not gridId then
    return nil, "\230\151\182\232\163\133\229\149\134\229\186\151\230\151\160\230\173\164\230\151\182\232\163\133"
  end
  params.gridId = gridId
  params.goodsCfg = goodsCfg
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  params.fashionCfg = fashionCfg
  params.buyNum = 1
  params.dotInfo = "ui_shop_fashion_buy"
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

function ShopLogic:FashionShopSort(shopGoodsData)
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
  local sets = Logic.sortLogic:GetHeroSort(CommonHeroItem.ShopFashion)
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
  elseif shopConfig.id == ShopId.Fashion then
    return self:FashionShopSort(shopGoodsData)
  end
  return shopGoodsData
end

function ShopLogic:CheckShopNewFashion()
  local status = false
  local fashionData = Data.shopData:GetShopInfoById(ShopId.Fashion)
  if fashionData then
    for i, goodsData in ipairs(fashionData.ShopGoodsData) do
      local goodsCfg = Logic.shopLogic:GetGoodsInfoById(goodsData.GoodsId)
      if goodsCfg.new == 1 then
        local isRecord = PlayerPrefs.GetBool("ShopNewFashion" .. goodsData.GoodsId, false)
        if not isRecord then
          status = true
        end
      end
    end
  end
  return status
end

function ShopLogic:GetUsableDiscountConf(goodsId, isRecharge)
  local discountTab
  if isRecharge then
    discountTab = configManager.GetDataById("config_recharge", goodsId).discount_id
  else
    discountTab = self:GetGoodsInfoById(goodsId).discount_id
  end
  if #discountTab == 0 then
    return
  end
  local usableDiscount
  local exclusiveInfo = {}
  local universalInfo = {}
  for _, tId in ipairs(discountTab) do
    local inBagTab = Logic.bagLogic:GetPeriodItemByTid(tId)
    if #inBagTab ~= 0 then
      for _, v in ipairs(inBagTab) do
        if v.config.discount_type == DiscountType.Exclusive then
          table.insert(exclusiveInfo, v)
        else
          table.insert(universalInfo, v)
        end
      end
    end
  end
  if next(exclusiveInfo) ~= nil then
    usableDiscount = self:SortOwnDiscount(exclusiveInfo)
  elseif next(universalInfo) ~= nil then
    usableDiscount = self:SortOwnDiscount(universalInfo)
  end
  return usableDiscount and usableDiscount[1] or nil
end

function ShopLogic:SortOwnDiscount(discountTab)
  local r = false
  table.sort(discountTab, function(data1, data2)
    if data1.config.discount_rate == data2.config.discount_rate then
      local time1 = Logic.bagLogic:GetPeriodItemTime(data1.config.time_duration, data1.data.createTime)
      local time2 = Logic.bagLogic:GetPeriodItemTime(data2.config.time_duration, data2.data.createTime)
      if time1 == time2 then
        if data1.data.templateId == data2.data.templateId then
          r = data1.data.itemId < data2.data.itemId
        else
          r = data1.data.templateId < data2.data.templateId
        end
      else
        r = time1 < time2
      end
    else
      r = data1.config.discount_rate < data2.config.discount_rate
    end
    return r
  end)
  return discountTab
end

function ShopLogic:GetDiscountPrice(cost, discountInfo)
  if discountInfo == nil then
    return cost
  else
    return math.floor(cost * (discountInfo.config.discount_rate / 10000))
  end
end

function ShopLogic:CheckDiscountProide(disInfoTab)
  local discountIdTab = {}
  for _, v in ipairs(disInfoTab) do
    local inPeriod = Logic.bagLogic:CheckInPeriod(v.data)
    if not inPeriod then
      noticeManager:OpenTipPage(self, UIHelper.GetString(2800004))
      return false, nil
    else
      table.insert(discountIdTab, v.data.itemId)
    end
  end
  return true, discountIdTab
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

return ShopLogic
