local ShopItemShow = class("ui.page.Shop.ShopItemShow")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local BuyStatus = {NoBuy = 0, HaveBuy = 1}
local ShopQualityIcon = {
  "uipic_ui_attribute_bg_zhuangbeikuang_hui",
  "uipic_ui_attribute_bg_zhuangbeikuang_lan",
  "uipic_ui_attribute_bg_zhuangbeikuang_zi",
  "uipic_ui_attribute_bg_zhuangbeikuang_jin",
  "uipic_ui_common_bg_zhuangbeikuang_cai"
}
local TabDotInfo = {
  [ShopId.Normal] = "ui_shop_norms_buy",
  [ShopId.MainGun] = "ui_shop_gun_buy",
  [ShopId.Torpedo] = "ui_shop_torpedo_buy",
  [ShopId.Equip] = "ui_shop_equipment_buy",
  [ShopId.Spa] = "ui_shop_spa_buy"
}
local DefaultNamePos = Vector3.New(4, 95, 0)
local LimitNamePos = Vector3.New(4, 103, 0)
local FashionNamePos = Vector3.New(0, -188, 0)
local DisplayFashion = 1

function ShopItemShow:initialize(parent)
  self.tab_Widgets = parent.tab_Widgets
  self.parent = parent
  self.selectedGoodsTab = {
    shopId = nil,
    goods = {},
    currencys = {}
  }
  self.normalGoodUiPartsTab = {}
  self.fastBuyWidgets = self.tab_Widgets.lp_FastBuy:GetLuaTableParts()
end

function ShopItemShow:Show(param)
  if param.subShopId then
    self.shopId = param.subShopId
    self.pShopId = param.shopId
  else
    self.shopId = param.shopId
  end
  self:_RegisterAllEvent()
  self:_Init()
  self:_GetConfigInfo()
  self:FixShopId()
  self:CreateSubList()
  self:SetContentPosX()
  if self:HasSubShops() then
    self:SelectDefaultSub()
  else
    self:_ShowImp()
    local shopSerData = Data.shopData:GetShopsInfo()
    if shopSerData ~= nil and shopSerData[self.shopId] ~= nil then
      self:_GetInfo()
      self:_SetInfo()
    end
  end
end

function ShopItemShow:_GetConfigInfo()
  local shopId = self.pShopId and self.pShopId or self.shopId
  local shopList, allShopConfig = Logic.shopLogic:GetShowShopInfo()
  self.shopConfigL1 = allShopConfig[shopId]
  self.allShopConfig = allShopConfig
end

function ShopItemShow:FixShopId()
  local subShops = self.shopConfigL1.subShops
  if subShops and 0 < #subShops then
    self.subShopMap = {}
    self:_GetDefaultShopId(self.shopConfigL1.id, self.pShopId == nil)
    if self.pShopId == nil then
      self.pShopId = self.shopId
    end
    self.shopConfig = configManager.GetDataById("config_shop", self.shopId)
  else
    self.shopConfig = self.shopConfigL1
  end
end

function ShopItemShow:_GetDefaultShopId(shopId, initShopId)
  local subShops = self.allShopConfig[shopId].subShops
  if subShops == nil or #subShops <= 0 then
    return
  end
  for i, sub in ipairs(subShops) do
    self.subShopMap[sub.id] = i
    if initShopId and i == 1 then
      self.shopId = sub.id
    end
    self:_GetDefaultShopId(sub.id)
  end
  return
end

function ShopItemShow:_RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.GetRefreshShopMsg, self._RefreshShopCallBack, self)
  eventManager:RegisterEvent(LuaEvent.GetBuyGoodsMsg, self._BuyGoodsCallBack, self)
  eventManager:RegisterEvent(LuaEvent.GetShopsInfoMsg, self._ShopsInfoCallBack, self)
  eventManager:RegisterEvent(LuaEvent.UpdataHeroSort, self._OnFilerSetOk, self)
  eventManager:RegisterEvent(LuaEvent.ShopBuyFastSuccess, self._ShopBuyFastCallBack, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_fresh, self._ClickRefresh, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_refreshOk, function()
    self:_ClikSureRefresh(true)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_skinfilter, self._OnFilterFashion, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_fashionshow, self._ShowFashionVideo, self)
  UGUIEventListener.AddButtonOnClick(self.fastBuyWidgets.btn_clear, self._ClickFastBuyClear, self)
  UGUIEventListener.AddButtonOnClick(self.fastBuyWidgets.btn_buyall, self._ClickFastBuyOk, self)
end

function ShopItemShow:StopAllTimers()
  if self.m_shoptimer ~= nil then
    self.m_shoptimer:Stop()
    self.m_shoptimer = nil
  end
  if self.m_fRefreshTimer ~= nil then
    self.parent:StopTimer(self.m_fRefreshTimer)
    self.m_fRefreshTimer = nil
  end
  if self.m_zeroTimer ~= nil then
    self.parent:StopTimer(self.m_zeroTimer)
    self.m_zeroTimer = nil
  end
end

function ShopItemShow:Close()
  self:_UnRegisterAllEvent()
  self:StopAllTimers()
  self.pShopId = nil
end

function ShopItemShow:_UnRegisterAllEvent()
  eventManager:UnregisterEvent(LuaEvent.GetRefreshShopMsg, self._RefreshShopCallBack)
  eventManager:UnregisterEvent(LuaEvent.GetBuyGoodsMsg, self._BuyGoodsCallBack)
  eventManager:UnregisterEvent(LuaEvent.GetShopsInfoMsg, self._ShopsInfoCallBack)
  eventManager:UnregisterEvent(LuaEvent.UpdataHeroSort, self._OnFilerSetOk, self)
  eventManager:UnregisterEvent(LuaEvent.ShopBuyFastSuccess, self._ShopBuyFastCallBack, self)
end

function ShopItemShow:_RefreshShopCallBack()
  self.shopInfo = Logic.shopLogic:GetShowGoodsInfo(self.shopId)
  self:_LoadGoodsInfo()
  self:_SetTitle()
end

function ShopItemShow:_BuyGoodsCallBack(param)
  self.shopInfo = Logic.shopLogic:GetShowGoodsInfo(self.shopId)
  self:_LoadGoodsInfo()
  self.parent:OnBuySuccess()
end

function ShopItemShow:_ShopsInfoCallBack()
  self:_GetInfo()
  self:_SetInfo()
end

function ShopItemShow:_ClickRefresh()
  noticeManager:CloseTip()
  local canUseFreeRefreshTimes = self.shopInfo.FRefreshNum
  if self.shopInfo.UsedFRefreshNum < self.shopConfig.init_times then
    canUseFreeRefreshTimes = canUseFreeRefreshTimes + self.shopConfig.init_times - self.shopInfo.UsedFRefreshNum
  end
  if 0 < canUseFreeRefreshTimes then
    local showText = string.format(UIHelper.GetString(270027), canUseFreeRefreshTimes)
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        self:_ClikFreeRefresh(bool)
      end
    }
    noticeManager:ShowMsgBox(showText, tabParams)
  elseif next(self.shopConfig.price) ~= nil and 0 < self.shopConfig.max_count then
    local isSame = time.isSameDay(Data.shopData:GetRefreshTime(), time.getSvrTime())
    local nRefreshNum = 0
    local canRefreshNum = 0
    if isSame then
      canRefreshNum = self.shopConfig.max_count - self.shopInfo.RefreshNum
      nRefreshNum = self.shopInfo.RefreshNum + 1
      if math.tointeger(nRefreshNum) > self.shopConfig.max_count then
        noticeManager:OpenTipPage(self, UIHelper.GetString(270002))
        return
      end
    else
      nRefreshNum = 1
      canRefreshNum = self.shopConfig.max_count
    end
    if nRefreshNum > #self.shopConfig.price then
      nRefreshNum = #self.shopConfig.price
    end
    self.refreshNeedCount = math.tointeger(self.shopConfig.price[nRefreshNum])
    self.refreshCurrencyId = Logic.shopLogic:GetTable_Index_Info({
      GoodsType.CURRENCY,
      self.shopConfig.currency_type
    }).id
    local currencyName = Logic.shopLogic:GetCurrencyById(self.refreshCurrencyId).name
    local needCount = self.refreshNeedCount .. currencyName
    local refreshItemId = configManager.GetDataById("config_parameter", 183).value
    local bagInfo = Logic.bagLogic:ItemInfoById(refreshItemId)
    local itemValue = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
    local showText = ""
    if itemValue ~= 0 then
      showText = string.format(UIHelper.GetString(270023), math.tointeger(canRefreshNum))
    else
      showText = string.format(UIHelper.GetString(270012), needCount, math.tointeger(canRefreshNum))
    end
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        self:_ClikSureRefresh(bool, itemValue)
      end
    }
    noticeManager:ShowMsgBox(showText, tabParams)
  else
    noticeManager:OpenTipPage(self, UIHelper.GetString(920000288))
  end
end

function ShopItemShow:_ClikFreeRefresh(bool)
  if not bool then
    return
  end
  Service.shopService:SetRefreshShopInfo(self.shopId)
  self:_RetentionDotInfo()
end

function ShopItemShow:_ClikSureRefresh(bool, itemValue)
  if not bool then
    return
  end
  if itemValue ~= 0 then
    Service.shopService:SetRefreshShopInfo(self.shopId)
    self:_RetentionDotInfo()
  else
    local tabCondition = {
      {
        CurrencyId = self.refreshCurrencyId,
        CostNum = self.refreshNeedCount
      }
    }
    local isCan = conditionCheckManager:CheckCurrencyIsEnough(tabCondition, true)
    if isCan then
      Service.shopService:SetRefreshShopInfo(self.shopId)
      self:_RetentionDotInfo()
    end
  end
end

function ShopItemShow:_RetentionDotInfo()
  local dotInfo = {
    info = "ui_shop_refresh",
    cost_num = {
      [tostring(self.refreshCurrencyId)] = tostring(self.refreshNeedCount)
    },
    currency_num = {
      [tostring(self.refreshCurrencyId)] = tostring(Data.userData:GetCurrency(self.refreshCurrencyId))
    },
    shop_id = self.shopId,
    remain_free_times = self.canFreeRefreshTimes > 0 and self.canFreeRefreshTimes - 1 or 0
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

function ShopItemShow:_Init()
  self.m_fRefreshTimer = nil
  self.m_zeroTimer = nil
end

function ShopItemShow:_GetInfo()
  self.shopInfo = Logic.shopLogic:GetShowGoodsInfo(self.shopId)
end

function ShopItemShow:_ShowImp()
  eventManager:SendEvent(LuaEvent.TopUpdateCurrency, self.shopConfig.currency_show)
  self.m_timer = Logic.shopLogic:GetRefreshShopTimerById(self.shopId)
end

function ShopItemShow:_SetInfo()
  self:_SetTopInfo()
  self:_LoadGoodsInfo()
  self:_ShowButton()
end

function ShopItemShow:_SetTopInfo()
  self:_SetTitle()
end

function ShopItemShow:_SetRefreshTime()
  if self.m_timer ~= nil and self.m_shoptimer == nil then
    local times = self.m_timer - time.getSvrTime()
    local showTime = time.getTimeStringFontDynamic(times)
    self.tab_Widgets.txt_freshTime.text = showTime
    
    local function funcShowRemianTime()
      local nCurTime = time.getSvrTime()
      local nRemainTime = self.m_timer - nCurTime
      local strShowInfo = time.getTimeStringFontDynamic(nRemainTime)
      self.tab_Widgets.txt_freshTime.text = strShowInfo
      if nRemainTime <= 0 and self.m_shoptimer ~= nil then
        self.m_shoptimer:Stop()
        self.m_shoptimer = nil
        self:_OnRefresh()
      end
    end
    
    if self.m_shoptimer == nil then
      self.m_shoptimer = Timer.New(funcShowRemianTime, 1, -1, false)
    else
      self.m_shoptimer:Stop()
      self.m_shoptimer:Reset(funcShowRemianTime, 1, -1, false)
    end
    self.m_shoptimer:Start()
  end
end

function ShopItemShow:_SetTitle()
  local bShowbtn = next(self.shopConfig.price) ~= nil and self.shopConfig.max_count > 0 or self.shopConfig.init_times ~= 0 or self.shopConfig.recovery_time ~= 0
  self.tab_Widgets.obj_refreshTop:SetActive(0 < #self.shopConfig.refresh_time)
  self.tab_Widgets.obj_normalTop:SetActive(self.shopConfig.init_times ~= 0 or self.shopConfig.recovery_time ~= 0)
  self.tab_Widgets.btn_fresh.gameObject:SetActive(bShowbtn)
  if 0 < #self.shopConfig.refresh_time then
    self.tab_Widgets.txt_freshTitle.text = UIHelper.GetString(270013)
    self:_SetRefreshTime()
  elseif self.shopConfig.init_times ~= 0 or self.shopConfig.recovery_time ~= 0 then
    self:_SetFreeRefresh()
  end
end

function ShopItemShow:_SetFreeRefresh()
  local canUseFreeRefreshTimes = self.shopInfo.FRefreshNum
  if self.shopInfo.UsedFRefreshNum < self.shopConfig.init_times then
    canUseFreeRefreshTimes = canUseFreeRefreshTimes + self.shopConfig.init_times - self.shopInfo.UsedFRefreshNum
  end
  if self.shopConfig.recovery_time > 0 and canUseFreeRefreshTimes < self.shopConfig.cumulate_times and time.getSvrTime() >= self.shopConfig.recovery_time + self.shopInfo.FRefreshTime then
    self.shopInfo.FRefreshNum = self.shopInfo.FRefreshNum + 1
    self.shopInfo.FRefreshTime = time.getSvrTime()
    canUseFreeRefreshTimes = canUseFreeRefreshTimes + 1
  end
  self.canFreeRefreshTimes = canUseFreeRefreshTimes
  if canUseFreeRefreshTimes >= self.shopConfig.cumulate_times or self.shopConfig.recovery_time <= 0 then
    self.tab_Widgets.txt_normalTitle.text = string.format(UIHelper.GetString(270029), canUseFreeRefreshTimes)
    if self.m_fRefreshTimer ~= nil then
      self.parent:StopTimer(self.m_fRefreshTimer)
      self.m_fRefreshTimer = nil
    end
    return
  end
  local countDown = time.getTimeStringFontDynamic(self.shopConfig.recovery_time + self.shopInfo.FRefreshTime - time.getSvrTime())
  self.tab_Widgets.txt_normalTitle.text = string.format(UIHelper.GetString(270028), canUseFreeRefreshTimes, countDown)
  if self.m_fRefreshTimer == nil then
    self.m_fRefreshTimer = self.parent:CreateTimer(function()
      self:_SetFreeRefresh()
    end, 1, -1, false)
    self.parent:StartTimer(self.m_fRefreshTimer)
  end
end

function ShopItemShow:_LoadGoodsInfo()
  self.shopInfo = Logic.shopLogic:GetShowGoodsInfo(self.shopId)
  local goodsSerData = {}
  local shopFuncType = self.shopConfig.fun_type
  self.tab_Widgets.obj_itemInfo:SetActive(shopFuncType ~= ShopFuncType.Activity)
  self.tab_Widgets.obj_itemInfoActivity:SetActive(shopFuncType == ShopFuncType.Activity)
  if self.shopConfig.sold_out == 1 then
    for _, v in ipairs(self.shopInfo.ShopGoodsData) do
      if v.Status ~= BuyStatus.HaveBuy then
        table.insert(goodsSerData, v)
      end
    end
  else
    goodsSerData = self.shopInfo.ShopGoodsData
  end
  goodsSerData = Logic.shopLogic:ShopSpecialSort(goodsSerData, self.shopConfig)
  local period = self.shopConfig.open_period
  self.tab_Widgets.im_period_common:SetActive(0 < period)
  if 0 < period then
    local startTime, endTime = PeriodManager:GetPeriodTime(period, self.shopConfig.open_period_area)
    local endTimeFormat = time.formatTimerToMDH(endTime)
    local strWord = UIHelper.GetString(270021)
    local timeStr = strWord .. endTimeFormat
    self.tab_Widgets.txt_period_common.text = timeStr
  end
  self:_CheckShowBuyFast()
  if shopFuncType == ShopFuncType.Activity then
    self:_LoadGoodsInfoActivity(goodsSerData)
  else
    self:_LoadGoodsInfoNormal(goodsSerData)
  end
  self:_ShowNullTip(goodsSerData)
end

function ShopItemShow:_LoadGoodsInfoNormal(goodsSerData)
  self.tab_Widgets.obj_itemShow:SetActive(self.shopConfig.display_type ~= DisplayFashion)
  self.tab_Widgets.obj_fashionShow:SetActive(self.shopConfig.display_type == DisplayFashion)
  local goodsItemObj, goodsItemTrans
  if self.shopConfig.display_type == DisplayFashion then
    goodsItemObj = self.tab_Widgets.obj_fashionItem
    goodsItemTrans = self.tab_Widgets.trans_fashionContent
  else
    goodsItemObj = self.tab_Widgets.obj_item
    goodsItemTrans = self.tab_Widgets.trans_ItemContent
  end
  self.normalGoodUiPartsTab = {}
  UIHelper.CreateSubPart(goodsItemObj, goodsItemTrans, #goodsSerData, function(index, tabPart)
    tabPart.obj_container.gameObject:SetActive(index <= #goodsSerData)
    local goodData = Logic.shopLogic:GetGoodsInfoById(goodsSerData[index].GoodsId)
    self:_SetShopGoodsInfo(goodsSerData[index], tabPart, goodData, index)
    self.normalGoodUiPartsTab[index] = tabPart
  end)
end

function ShopItemShow:_OnRefresh()
  self.m_timer = Logic.shopLogic:GetRefreshShopTimerById(self.shopId)
  if UIPageManager:IsExistPage("ShowEquipPage") then
    UIHelper.ClosePage("ShowEquipPage")
  end
  if UIPageManager:IsExistPage("ItemInfoPage") then
    UIHelper.ClosePage("ItemInfoPage")
  end
  Service.shopService:SendGetShopsInfo()
end

function ShopItemShow:_SetShopGoodsBase(goodSerData, tabPart, goodData, isActivity)
  tabPart.obj_leftTop:SetActive(false)
  local goodsInfo = Logic.bagLogic:GetItemByTempateId(goodData.goods[1], goodData.goods[2])
  self:_SetItemBasicInfo(goodsInfo, tabPart, goodData)
  self:_ShowBuyPeriodInfo(tabPart, goodData)
  self:_SetShopGoodsStock(goodSerData, tabPart, goodData)
  local goodsType = goodData.goods[1]
  if goodsType == GoodsType.FASHION then
    tabPart.img_bgNum:SetActive(false)
    tabPart.txt_num.gameObject:SetActive(false)
    tabPart.obj_fashionHero:SetActive(true)
    local shipName = Logic.fashionLogic:GetFashionShipName(goodData.goods[2])
    UIHelper.SetText(tabPart.txt_fashionHero, shipName)
    local fashionId = goodsInfo.id
    local ownFashion = Logic.fashionLogic:CheckFashionOwn(fashionId)
    if ownFashion then
      tabPart.obj_money:SetActive(false)
      tabPart.txt_have.gameObject:SetActive(true)
    else
      tabPart.obj_money:SetActive(true)
      tabPart.txt_have.gameObject:SetActive(false)
    end
    if goodData.new == 1 then
      PlayerPrefs.SetBool("ShopNewFashion" .. goodData.id, true)
      eventManager:SendEvent(LuaEvent.OpenShopFashion)
    end
    local tip = Logic.fashionLogic:GetFashionSellTip(fashionId)
    if tabPart.obj_fashiontip then
      tabPart.obj_fashiontip:SetActive(0 < #tip and self.shopConfig.display_type == DisplayFashion)
      if 0 < #tip and self.shopConfig.display_type == DisplayFashion then
        UIHelper.SetImage(tabPart.img_fashiontip, tip)
      end
    else
      logError("fashion product have't widget show tip")
    end
    if self.shopConfig.display_type == DisplayFashion then
      local icon = Logic.fashionLogic:GetFashionDraw(fashionId)
      UIHelper.SetImage(tabPart.im_goodIcon, icon)
      local pos, scale = Logic.shopLogic:FashionGoodsPosScale(fashionId)
      tabPart.im_goodIcon.transform.localPosition = Vector3.New(pos[1], pos[2], 0)
      tabPart.im_goodIcon.transform.localScale = scale
      tabPart.txt_name.gameObject.transform.localPosition = FashionNamePos
    end
  else
    tabPart.obj_money:SetActive(true)
    tabPart.txt_have.gameObject:SetActive(false)
    tabPart.img_bgNum:SetActive(true)
    tabPart.txt_num.gameObject:SetActive(true)
    tabPart.obj_fashionHero:SetActive(false)
    tabPart.txt_num.text = "x" .. goodData.goods[3]
    if tabPart.obj_fashiontip then
      tabPart.obj_fashiontip:SetActive(false)
    end
    if tabPart.obj_fashiontip and goodData.id == 5999 then
      tabPart.obj_fashiontip:SetActive(true)
    end
  end
  if tabPart.tog_fastbuy then
    local isFastBuy = self.shopConfig.fun_type == 1 and self.shopConfig.quick_buy == 1
    local canBuy = Logic.shopLogic:CheckGoodCanBuy(self.shopId, goodData.id)
    tabPart.tog_fastbuy.gameObject:SetActive(isFastBuy and canBuy)
    self:_UpdateSelectMask(goodSerData, goodData, tabPart)
    UGUIEventListener.AddButtonToggleChanged(tabPart.tog_fastbuy, function(go, isOn)
      self:_DisposeSelectedGoods(isOn, goodSerData, goodData)
      self:_UpdateFastBuy()
      self.shopInfo = Logic.shopLogic:GetShowGoodsInfo(self.shopId)
      local goodsSerData = {}
      if self.shopConfig.sold_out == 1 then
        for _, v in ipairs(self.shopInfo.ShopGoodsData) do
          if v.Status ~= BuyStatus.HaveBuy then
            table.insert(goodsSerData, v)
          end
        end
      else
        goodsSerData = self.shopInfo.ShopGoodsData
      end
      goodsSerData = Logic.shopLogic:ShopSpecialSort(goodsSerData, self.shopConfig)
      for index, goodSerData in ipairs(goodsSerData) do
        local goodDataInfo = Logic.shopLogic:GetGoodsInfoById(goodsSerData[index].GoodsId)
        self:_UpdateSelectMask(goodSerData, goodDataInfo, self.normalGoodUiPartsTab[index])
      end
    end)
  end
end

function ShopItemShow:_ResetSelectedGoodsTab()
  self.selectedGoodsTab = {
    shopId = self.shopId,
    goods = {},
    currencys = {}
  }
end

function ShopItemShow:_DisposeSelectedGoods(isAdd, goodSerData, goodData)
  local commodityId = goodData.id
  local goodType = goodData.goods[1]
  local goodId = goodData.goods[2]
  local goodNum = goodData.goods[3]
  local haveSameGood = false
  for index, selcetGood in ipairs(self.selectedGoodsTab.goods) do
    if selcetGood.commodityId == commodityId then
      haveSameGood = true
      if not isAdd then
        table.remove(self.selectedGoodsTab.goods, index)
        break
      end
    end
  end
  if not haveSameGood and isAdd then
    table.insert(self.selectedGoodsTab.goods, {
      id = goodId,
      type = goodType,
      num = goodNum,
      commodityId = commodityId
    })
  end
  for i, currencyInfo in pairs(goodData.currency) do
    local currencyType = currencyInfo[1]
    local currencyId = currencyInfo[2]
    local priceIndex = #goodData.price[i] < goodSerData.Num + 1 and #goodData.price[i] or goodSerData.Num + 1
    local currencyNum = goodData.price[i][priceIndex]
    local haveSameCurrency = false
    for index, currency in ipairs(self.selectedGoodsTab.currencys) do
      if currency.id == currencyId then
        haveSameCurrency = true
        if isAdd then
          currency.num = currency.num + currencyNum
        else
          currency.num = currency.num - currencyNum
          if currency.num <= 0 then
            table.remove(self.selectedGoodsTab.currencys, index)
          end
        end
      end
    end
    if not haveSameCurrency and isAdd then
      table.insert(self.selectedGoodsTab.currencys, {
        id = currencyId,
        type = currencyType,
        num = currencyNum
      })
    end
  end
end

function ShopItemShow:_UpdateFastBuy()
  local fastBuyPart = self.parent.tab_Widgets.lp_FastBuy
  local hideFastBuy = self.selectedGoodsTab.currencys == nil or #self.selectedGoodsTab.currencys == 0
  if hideFastBuy then
    fastBuyPart.gameObject:SetActive(false)
  else
    fastBuyPart.gameObject:SetActive(true)
    UIHelper.CreateSubPart(self.fastBuyWidgets.obj_priceItem, self.fastBuyWidgets.trans_price, #self.selectedGoodsTab.currencys, function(index, uipart)
      local currency = self.selectedGoodsTab.currencys[index]
      UIHelper.SetText(uipart.tx_price, currency.num)
      local icon = Logic.currencyLogic:GetIcon(currency.id)
      UIHelper.SetImage(uipart.im_icon, icon)
    end)
  end
  if not hideFastBuy then
    self.tab_Widgets.obj_refreshTop:SetActive(false)
    self.tab_Widgets.obj_normalTop:SetActive(false)
    self.tab_Widgets.im_period_common:SetActive(false)
    self.tab_Widgets.btn_fresh.gameObject:SetActive(false)
    self.tab_Widgets.btn_fashionshow:SetActive(false)
    self.tab_Widgets.btn_skinfilter:SetActive(false)
  else
    self.tab_Widgets.obj_refreshTop:SetActive(0 < #self.shopConfig.refresh_time)
    self.tab_Widgets.obj_normalTop:SetActive(self.shopConfig.init_times ~= 0 or self.shopConfig.recovery_time ~= 0)
    local period = self.shopConfig.open_period
    self.tab_Widgets.im_period_common:SetActive(0 < period)
    local bShowbtn = next(self.shopConfig.price) ~= nil and 0 < self.shopConfig.max_count or self.shopConfig.init_times ~= 0 or self.shopConfig.recovery_time ~= 0
    self.tab_Widgets.btn_fresh.gameObject:SetActive(bShowbtn)
    self.tab_Widgets.btn_fashionshow:SetActive(self.shopConfig.display_type == DisplayFashion)
    self.tab_Widgets.btn_skinfilter:SetActive(self.shopConfig.display_type == DisplayFashion)
  end
end

function ShopItemShow:_UpdateSelectMask(goodSerData, goodData, uiPart)
  for _, selectedGood in pairs(self.selectedGoodsTab.goods) do
    if selectedGood.commodityId == goodData.id then
      return
    end
  end
  for i, currencyInfo in pairs(goodData.currency) do
    local currencyId = currencyInfo[2]
    local priceIndex = #goodData.price[i] < goodSerData.Num + 1 and #goodData.price[i] or goodSerData.Num + 1
    local itemCurrencyNum = goodData.price[i][priceIndex]
    local allCostNum = 0
    local haveNum = Data.userData:GetCurrency(currencyId)
    for _, currency in ipairs(self.selectedGoodsTab.currencys) do
      if currencyId == currency.id then
        allCostNum = currency.num
      end
    end
    local remainNum = haveNum - allCostNum
    local isFastBuy = self.shopConfig.fun_type == 1 and self.shopConfig.quick_buy == 1
    local canBuy = Logic.shopLogic:CheckGoodCanBuy(self.shopId, goodData.id)
    if itemCurrencyNum > remainNum and isFastBuy and canBuy then
      uiPart.obj_mask:SetActive(true)
    else
      uiPart.obj_mask:SetActive(false)
    end
  end
end

function ShopItemShow:_CheckShowBuyFast()
  self:_ResetSelectedGoodsTab()
  local shopCfg = self.shopConfig
  local isShow = shopCfg.fun_type == 1 and shopCfg.quick_buy == 1
  self.parent.tab_Widgets.lp_FastBuy.gameObject:SetActive(isShow)
  if isShow then
    self:_UpdateFastBuy()
  end
end

function ShopItemShow:_ClickFastBuyOk()
  UIHelper.OpenPage("ShopFastBuyPage", {
    selectedTab = self.selectedGoodsTab
  })
end

function ShopItemShow:_ClickFastBuyClear()
  self:_ResetSelectedGoodsTab()
  for index, uipart in ipairs(self.normalGoodUiPartsTab) do
    if uipart.tog_fastbuy and uipart.obj_mask then
      uipart.tog_fastbuy.isOn = false
      uipart.obj_mask:SetActive(false)
    end
  end
  self.parent.tab_Widgets.lp_FastBuy.gameObject:SetActive(false)
  self.shopInfo = Logic.shopLogic:GetShowGoodsInfo(self.shopId)
  self:_LoadGoodsInfo()
end

function ShopItemShow:_ShopBuyFastCallBack()
  self.shopInfo = Logic.shopLogic:GetShowGoodsInfo(self.shopId)
  self:_LoadGoodsInfo()
  self.parent:OnBuySuccess()
end

function ShopItemShow:_SetShopGoodsStock(goodSerData, tabPart, goodData)
  local canBuyNum = -1
  if goodData.stock ~= -1 then
    canBuyNum = math.tointeger(goodData.stock) - math.tointeger(goodSerData.Num)
  end
  if canBuyNum == 0 or goodData.id == 90188 and canBuyNum == 1 or goodData.stock == -1 then
    tabPart.obj_times:SetActive(false)
  else
    tabPart.obj_times:SetActive(true)
    local str = string.format(UIHelper.GetString(270031), canBuyNum)
    if goodData.id == 90188 then
      str = string.format(UIHelper.GetString(270031), 1)
    end
    tabPart.txt_times.text = str
  end
  local bIsRefresh = Logic.shopLogic:IsShopRefreshById(self.shopId)
  local soldout = goodSerData.Status == BuyStatus.HaveBuy and bIsRefresh or canBuyNum == 0
  if goodData.goods[1] == GoodsType.FASHION then
    soldout = false
  end
  if goodData.undercarriage == 1 then
    soldout = true
  end
  tabPart.obj_sellOut:SetActive(soldout)
end

function ShopItemShow:_SetShopGoodsInfo(goodSerData, tabPart, goodData, index)
  local isActivity = false
  self:_SetShopGoodsBase(goodSerData, tabPart, goodData, isActivity)
  self:_ShowCurrencyInfo(goodData, tabPart, goodSerData)
  self:_BuyNeedCurrency(tabPart, goodData, goodSerData, index)
end

function ShopItemShow:_SetItemBasicInfo(goodsInfo, tabPart, goodData)
  tabPart.txt_name.gameObject.transform.localPosition = DefaultNamePos
  tabPart.txt_name.text = goodsInfo.name
  UIHelper.SetImage(tabPart.im_goodIcon, tostring(goodsInfo.icon))
  UIHelper.SetImage(tabPart.im_quality, ShopQualityIcon[goodsInfo.quality])
  if tabPart.obj_ringEff then
    tabPart.obj_ringEff:SetActive(goodsInfo.id == 10180)
  end
  tabPart.obj_effect:SetActive(false)
  local tableInfo = Logic.shopLogic:GetTableIndexConfById(goodData.goods[1])
  if tableInfo.bag_index == 2 and tabPart.obj_effect ~= nil then
    local isHave = Logic.equipLogic:EquipIsHaveEffect(goodsInfo.id)
    tabPart.obj_effect:SetActive(isHave)
  end
end

function ShopItemShow:_BuyNeedCurrency(tabPart, goodData, goodSerData, index)
  local goodsInfo = Logic.bagLogic:GetItemByTempateId(goodData.goods[1], goodData.goods[2])
  local canBuyNum = -1
  if goodData.stock ~= -1 then
    canBuyNum = math.tointeger(goodData.stock) - math.tointeger(goodSerData.Num)
  end
  local bIsRefresh = Logic.shopLogic:IsShopRefreshById(self.shopId)
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
      tabPart.txt_limit.text = msg
      break
    end
  end
  tabPart.obj_limit:SetActive(not reachLimit)
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
  UGUIEventListener.AddButtonOnClick(tabPart.btn_buy, function()
    if goodData.goods[1] == GoodsType.FASHION then
      local fashionId = goodsInfo.id
      local ownFashion = Logic.fashionLogic:CheckFashionOwn(fashionId)
      if ownFashion then
        local previewHero = Logic.fashionLogic:GetHeroByFashionId(fashionId)
        local heroId = previewHero and previewHero.HeroId
        UIHelper.OpenPage("FashionPage", {
          isPreview = true,
          fashionId = fashionId,
          heroId = heroId
        })
        return
      end
    end
    self.buyGoodsId = goodData.id
    local goodType = goodData.goods[1]
    if soldout then
      noticeManager:OpenTipPage(self, 270007)
    elseif not reachLimit then
      noticeManager:OpenTipPage(self, msg)
    elseif not isInPeriod then
      Logic.shopLogic:ShowPeriodEndTips(goodData.period_show)
    else
      noticeManager:CloseTip()
      local buyNum = goodData.is_buy_batch ~= 0 and goodData.goods[3] or 1
      local tableInfo = Logic.shopLogic:GetTableIndexConfById(goodType)
      local dotInfo = TabDotInfo[self.shopId]
      local gridId = goodSerData.GridId
      local canBuyBatch = goodData.is_buy_batch ~= 0
      if goodData.stock == 1 and goodData.is_buy_batch ~= 0 then
        logError("\229\186\147\229\173\152\228\184\1861\231\154\132\229\149\134\229\147\129\239\188\140\228\184\141\232\131\189\230\137\185\233\135\143\232\180\173\228\185\176\239\188\140\233\128\154\231\159\165\231\173\150\229\136\146\228\191\174\230\148\185\227\128\130\229\149\134\229\147\129id\239\188\154", goodData.id)
      end
      if tableInfo.bag_index == 2 then
        local data = {
          shopId = self.shopId,
          buyNum = buyNum,
          dotInfo = dotInfo,
          goodData = goodData,
          isBatch = canBuyBatch == 1,
          gridId = gridId,
          goodsSerData = goodSerData
        }
        UIHelper.OpenPage("ShowEquipPage", {
          templateId = goodData.goods[2],
          showEquipType = ShowEquipType.Shop,
          customParam = data
        })
      elseif goodType == GoodsType.FASHION then
        local param = ItemInfoPage:GenFashionData(self.shopId, 1, goodsInfo, goodData, dotInfo, gridId, goodSerData)
        UIHelper.OpenPage("ItemInfoPage", param)
      else
        local param = ItemInfoPage:BuyShopItemPage(self.shopId, buyNum, goodsInfo, goodData, dotInfo, canBuyBatch, gridId, goodSerData)
        UIHelper.OpenPage("ItemInfoPage", param)
      end
    end
  end)
end

function ShopItemShow:_ShowCurrencyInfo(goodData, tabPart, goodSerData)
  local buyNeedType = goodData.currency
  UIHelper.CreateSubPart(tabPart.obj_currItem, tabPart.trans_curr, #buyNeedType, function(nIndex, part)
    local currencyInfo = buyNeedType[nIndex]
    local currType = currencyInfo[1]
    local currencyId = currencyInfo[2]
    local priceIndex = #goodData.price[nIndex] < goodSerData.Num + 1 and #goodData.price[nIndex] or goodSerData.Num + 1
    local discountAfter = goodData.price[nIndex][priceIndex]
    local discountIndex = #goodData.discount < goodSerData.Num + 1 and #goodData.discount or goodSerData.Num + 1
    local discountNum = goodData.discount[discountIndex]
    local icon = Logic.goodsLogic:GetSmallIcon(currencyId, currType)
    UIHelper.SetImage(part.im_currIcon, tostring(icon), true)
    part.im_fenge:SetActive(goodData.cur_relation == 2 and nIndex ~= #buyNeedType)
    part.txt_after.text = discountAfter
    part.im_currIcon.gameObject:SetActive(currencyId ~= CurrencyType.RMB)
    part.tx_money:SetActive(currencyId == CurrencyType.RMB)
    if nIndex == 1 then
      tabPart.obj_disout:SetActive(discountNum ~= 100)
      tabPart.txt_discount.text = Logic.mathLogic:FormatNumber(10 - discountNum / 10)
    end
  end)
end

function ShopItemShow:_ShowBuyPeriodInfo(tabPart, goodData)
  local periodId = 0
  for _, perId in pairs(goodData.period_buy) do
    if PeriodManager:IsInPeriod(perId) then
      periodId = perId
      break
    end
  end
  tabPart.im_period:SetActive(false)
  if 0 < periodId and goodData.period_show ~= 0 then
    local descTime = Logic.shopLogic:GetPeriodText(periodId, goodData.period_show)
    tabPart.txt_period.text = descTime
    tabPart.im_period:SetActive(true)
    tabPart.txt_name.gameObject.transform.localPosition = LimitNamePos
  end
  if 0 < #goodData.period_buy and periodId == 0 and goodData.period_show ~= 0 then
    tabPart.txt_period.text = UIHelper.GetString(270039)
    tabPart.im_period:SetActive(true)
    tabPart.txt_name.gameObject.transform.localPosition = LimitNamePos
  end
end

function ShopItemShow:_LoadGoodsInfoActivity(goodsSerData)
  local period = self.shopConfig.open_period
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(period)
  local endTimeFormat = time.formatTimeToYMDHM(endTime)
  local strWord = UIHelper.GetString(270021)
  local timeStr = strWord .. endTimeFormat
  self.tab_Widgets.txt_period.text = timeStr
  UIHelper.CreateSubPart(self.tab_Widgets.obj_itemActivity, self.tab_Widgets.trans_ItemContentActivity, #goodsSerData, function(index, tabPart)
    tabPart.obj_container.gameObject:SetActive(index <= #goodsSerData)
    local goodData = Logic.shopLogic:GetGoodsInfoById(goodsSerData[index].GoodsId)
    self:_SetShopGoodsInfoActivity(goodsSerData[index], tabPart, goodData, index)
  end)
end

function ShopItemShow:_SetShopGoodsInfoActivity(goodSerData, tabPart, goodData, index)
  local isActivity = true
  self:_SetShopGoodsBase(goodSerData, tabPart, goodData, isActivity)
  self:_ShowCurrencyInfoActivity(goodData, tabPart, goodSerData)
  self:_BuyNeedCurrency(tabPart, goodData, goodSerData, index)
end

function ShopItemShow:_ShowCurrencyInfoActivity(goodData, tabPart, goodSerData)
  tabPart.obj_leftTop:SetActive(false)
  local buyNeedType = goodData.currency
  tabPart.obj_disout:SetActive(false)
  for index = 1, #buyNeedType do
    local buyNeedCurrency = buyNeedType[index]
    tabPart["txt_after" .. index].gameObject:SetActive(buyNeedCurrency ~= nil)
    if buyNeedCurrency then
      local type = buyNeedCurrency[1]
      local currencyId = buyNeedCurrency[2]
      local priceIndex = #goodData.price[nIndex] < goodSerData.Num + 1 and #goodData.price[index] or goodSerData.Num + 1
      local txt_discountAfter = goodData.price[index][priceIndex]
      local icon = Logic.goodsLogic:GetSmallIcon(currencyId, type)
      UIHelper.SetImage(tabPart["im_icon" .. index], tostring(icon), true)
      tabPart["txt_after" .. index].text = txt_discountAfter
    end
  end
end

function ShopItemShow:HasSubShops()
  return self.pShopId ~= nil
end

function ShopItemShow:HasExtraSubShops()
  return self.shopConfig.shop_type == 3
end

function ShopItemShow:CreateSubList()
  local widgets = self.tab_Widgets
  widgets.obj_lock:SetActive(false)
  if not self:HasSubShops() then
    widgets.obj_itemSubList:SetActive(false)
    return
  end
  widgets.obj_itemSubList:SetActive(true)
  widgets.group_itemSubList:ClearToggles()
  local subShops = self.shopConfigL1.subShops
  UIHelper.CreateSubPart(widgets.obj_itemSubItem, widgets.trans_itemSubList, #subShops, function(index, tabPart)
    local shopData = subShops[index]
    if #shopData.red_dot > 0 then
      self.parent:RegisterRedDotById(tabPart.red_dot, shopData.red_dot, shopData.id)
    else
      tabPart.red_dot.gameObject:SetActive(false)
    end
    UIHelper.SetText(tabPart.name, shopData.name)
    widgets.group_itemSubList:RegisterToggle(tabPart.toggle)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.group_itemSubList, self, nil, self.OnSubShop)
end

function ShopItemShow:_CreateExtraSubList(extraSubShops)
  local widgets = self.tab_Widgets
  if extraSubShops == nil or #extraSubShops <= 0 then
    widgets.obj_itemExtraSubList:SetActive(false)
    return
  end
  widgets.obj_itemExtraSubList:SetActive(true)
  widgets.group_itemExtraSubList:ClearToggles()
  UIHelper.CreateSubPart(widgets.obj_itemExtraSubItem, widgets.trans_itemExtraSubList, #extraSubShops, function(index, tabPart)
    local shopData = extraSubShops[index]
    UIHelper.SetText(tabPart.name, shopData.name)
    widgets.group_itemExtraSubList:RegisterToggle(tabPart.toggle)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.group_itemExtraSubList, self, nil, self.OnExtraSubShop)
end

function ShopItemShow:SetContentPosX()
  local pos = self.tab_Widgets.trans_itemGrid.anchoredPosition
  if self:HasExtraSubShops() then
    pos.x = 165
  elseif self:HasSubShops() then
    pos.x = 130
  else
    pos.x = 64.5
  end
  self.tab_Widgets.trans_itemGrid.anchoredPosition = pos
end

function ShopItemShow:SelectDefaultSub()
  if self.pShopId then
    local index = self.subShopMap[self.shopId]
    self.tab_Widgets.group_itemSubList:SetActiveToggleIndex(index - 1)
  else
    self.tab_Widgets.group_itemSubList:SetActiveToggleIndex(0)
  end
end

function ShopItemShow:OnSubShop(index)
  self:StopAllTimers()
  index = index + 1
  local subShops = self.shopConfigL1.subShops
  local shopData = subShops[index]
  self.shopId = shopData.id
  if shopData.dependence_id == ShopId.DailyCopy then
    PlayerPrefs.SetBool("DailySubShop" .. self.shopId, false)
    eventManager:SendEvent(LuaEvent.UpdateDailyShop)
  end
  local extraSubShops = self.allShopConfig[self.shopId].subShops
  self:_CreateExtraSubList(extraSubShops)
  if extraSubShops ~= nil and 0 < #extraSubShops then
    self.tab_Widgets.group_itemExtraSubList:SetActiveToggleIndex(0)
    return
  end
  self:_OnShowShop()
end

function ShopItemShow:OnExtraSubShop(index)
  self:StopAllTimers()
  index = index + 1
  local extraSubShops = {}
  if self.shopConfig.shop_type == 2 then
    extraSubShops = self.allShopConfig[self.shopId].subShops
  elseif self.shopConfig.shop_type == 3 then
    extraSubShops = self.allShopConfig[self.shopConfig.dependence_id].subShops
  end
  if extraSubShops ~= nil and 0 < #extraSubShops then
    self.shopId = extraSubShops[index].id
  end
  self:_OnShowShop()
end

function ShopItemShow:_OnShowShop()
  self.shopConfig = configManager.GetDataById("config_shop", self.shopId)
  local isUnlock = Logic.shopLogic:IsUnLockBeforeShop(self.shopConfig.unlock_before_shop_id)
  self.tab_Widgets.obj_lock:SetActive(not isUnlock)
  self.parent:OnShopChanged(self.shopId)
  self:_ShowImp()
  self:_GetInfo()
  self:_SetInfo()
  self:SetContentPosX()
end

function ShopItemShow:_ShowButton()
  local widgets = self.tab_Widgets
  local shopId = self.shopId
  widgets.btn_skinfilter:SetActive(self.shopConfig.display_type == DisplayFashion)
  widgets.btn_fashionshow:SetActive(self.shopConfig.display_type == DisplayFashion)
end

function ShopItemShow:_OnFilerSetOk(data)
  if self.shopId == ShopId.Fashion then
    Logic.sortLogic:SetHeroSort(CommonHeroItem.ShopFashion, {false, data})
  elseif self.shopId == ShopId.BrokenFashion then
    Logic.sortLogic:SetHeroSort(CommonHeroItem.ShopBrokenFashion, {false, data})
  end
  self:_SetInfo()
end

function ShopItemShow:_OnFilterFashion()
  local data = {}
  if self.shopId == ShopId.Fashion then
    data = Logic.sortLogic:GetHeroSort(CommonHeroItem.ShopFashion)
  elseif self.shopId == ShopId.BrokenFashion then
    data = Logic.sortLogic:GetHeroSort(CommonHeroItem.ShopBrokenFashion)
  end
  UIHelper.OpenPage("SortPage", {
    data[2][1],
    data[2][2],
    SortType = MHeroSortType.ShopFashion
  })
end

function ShopItemShow:_ShowNullTip(goods)
  local widgets = self.tab_Widgets
  local shopId = self.shopId
  local show = #goods <= 0
  widgets.obj_tipgirl:SetActive(show)
  if show then
    local tip = UIHelper.GetString(self.shopConfig.display_type == DisplayFashion and 270047 or 270048)
    UIHelper.SetText(widgets.tx_tipgirl, tip)
  end
end

function ShopItemShow:_ShowFashionVideo()
  local str = configManager.GetDataById("config_parameter", 374).name
  local deviceWidth = platformManager:GetScreenWidth()
  local deviceHeight = platformManager:GetScreenHeight()
  local posX = 0
  local posY = 0
  if isWindows then
    deviceWidth = 700
    deviceHeight = 400
    posX = -1
    posY = -1
  end
  platformManager:openCustomWebView(str, deviceWidth, deviceHeight, posX, posY, "1", nil, true)
end

return ShopItemShow
