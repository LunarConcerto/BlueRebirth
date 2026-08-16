local GiftInfoPage = class("UI.Recharge.GiftInfoPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function GiftInfoPage:DoInit()
  self.m_tabWidgets = nil
  self.useDisInfoTab = {}
  self.openDiscountDP = false
end

function GiftInfoPage:DoOnOpen()
  self.configData = self.param.configData
  self.shopId = self.param.shopId
  self.openDiscountDP = self.param.openDiscountDP ~= nil and self.param.openDiscountDP or false
  self:_LoadContent(self.configData)
end

function GiftInfoPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_buy, self.OnBtnBuy, self)
end

function GiftInfoPage:_LoadContent(configData)
  local rewards = {}
  if configData.paytype then
    UIHelper.SetText(self.tab_Widgets.text_itemName, configData.show_name)
    UIHelper.SetImage(self.tab_Widgets.img_item, tostring(configData.icon), true)
    if configData.reward > 0 then
      rewards = clone(configManager.GetDataById("config_rewards", configData.reward).rewards)
    end
    local serverData = Logic.rechargeLogic:GetServerDataById(configData.id)
    local doubleActive = false
    if serverData then
      doubleActive = serverData.Status == 1
    else
      doubleActive = 0 < configData.extra_reward
    end
    self.tab_Widgets.obj_title:SetActive(configData.tagid ~= RechargeTogType.recharge)
    self.tab_Widgets.obj_titleShop:SetActive(configData.tagid == RechargeTogType.recharge)
    if doubleActive then
      local extra_reward = configManager.GetDataById("config_rewards", configData.extra_reward).rewards
      for k, v in pairs(extra_reward) do
        local same = false
        for x, y in pairs(rewards) do
          if y[1] == v[1] and y[2] == v[2] then
            y[3] = y[3] + v[3]
            same = true
            break
          end
        end
        if not same then
          table.insert(rewards, v)
        end
      end
    end
    self.tab_Widgets.img_icon.gameObject:SetActive(configData.currency_type ~= CurrencyType.RMB)
    local str = configData.currency_type == CurrencyType.RMB and string.format("\239\191\165%s", configData.cost) or configData.cost
    UIHelper.SetText(self.tab_Widgets.txt_cost, str)
    if configData.currency_type ~= CurrencyType.RMB then
      local currencyIcon = Logic.currencyLogic:GetSmallIcon(configData.currency_type)
      UIHelper.SetImage(self.tab_Widgets.img_icon, currencyIcon)
    end
  else
    local goods = configData.goods
    local icon = Logic.goodsLogic:GetIcon(goods[2], goods[1])
    UIHelper.SetText(self.tab_Widgets.text_itemName, configData.name)
    UIHelper.SetImage(self.tab_Widgets.img_item, tostring(icon), true)
    local itemInfo = Logic.bagLogic:GetItemByTempateId(goods[1], goods[2])
    local drop = configManager.GetDataById("config_drop_item", itemInfo.drop_id)
    rewards = drop.drop_alone
    local prices = configData.price2
    if 0 < #prices then
      local price = prices[1]
      local currencyType = price[1]
      local currencyId = price[2]
      local cost = price[3]
      local currencyIcon = Logic.goodsLogic:GetSmallIcon(currencyId, currencyType)
      UIHelper.SetImage(self.tab_Widgets.img_icon, currencyIcon)
      UIHelper.SetText(self.tab_Widgets.txt_cost, cost)
    else
      self.tab_Widgets.img_icon.gameObject:SetActive(false)
      UIHelper.SetText(self.tab_Widgets.txt_cost, UIHelper.GetString(430006))
    end
  end
  self.configData.discountId = {}
  local discountInfo = Logic.shopLogic:GetUsableDiscountConf(configData.id, configData.paytype)
  self.tab_Widgets.tx_saleCost.gameObject:SetActive(discountInfo ~= nil)
  self.tab_Widgets.obj_saleline.gameObject:SetActive(discountInfo ~= nil)
  if discountInfo ~= nil then
    self.useDisInfoTab[1] = discountInfo
    local cost = configData.paytype and configData.cost or configData.price2[3]
    self.tab_Widgets.tx_saleCost.text = Logic.shopLogic:GetDiscountPrice(cost, discountInfo)
    self.tab_Widgets.tx_sale.text = string.format(UIHelper.GetString(2800001), discountInfo.config.name)
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_itemReward, self.tab_Widgets.trans_itemReward, #rewards, function(index, tabPart)
    local reward = rewards[index]
    UIHelper.SetText(tabPart.text_num, reward[3])
    local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[rewardInfo.quality])
    UIHelper.SetImage(tabPart.img_icon, tostring(rewardInfo.icon))
    UIHelper.SetText(tabPart.text_name, rewardInfo.name)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
      if reward[1] == GoodsType.EQUIP then
        UIHelper.OpenPage("ShowEquipPage", {
          templateId = reward[2],
          showEquipType = ShowEquipType.Simple
        })
      else
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward[1], reward[2]))
      end
    end, self)
  end)
end

function GiftInfoPage:OnBtnBuy()
  if #self.useDisInfoTab ~= 0 then
    local valid, inProideId = Logic.shopLogic:CheckDiscountProide(self.useDisInfoTab)
    if valid then
      self.configData.discountId = inProideId
    end
  else
    local goPath = self:_GotoDiscountDropPath()
    if goPath then
      return
    end
  end
  if self.configData.paytype then
    self:_BuyRechargeGift()
  else
    self:_BuyShopGoodsGift()
  end
end

function GiftInfoPage:_BuyRechargeGift()
  local reachLimit, msg = Logic.gameLimitLogic.CheckConditionByArrId(self.configData.buy_limit)
  if not reachLimit then
    noticeManager:OpenTipPage(self, msg .. UIHelper.GetString(270035))
    return
  end
  local isInPeriod = true
  if self.configData.paytype ~= RechargeItemType.LuckyRecharge then
    isInPeriod = #self.configData.double_period <= 0
    if #self.configData.double_period > 0 then
      for _, perId in pairs(self.configData.double_period) do
        if PeriodManager:IsInPeriod(perId) then
          isInPeriod = true
          break
        end
        isInPeriod = false
      end
    end
  end
  if (self.configData.paytype == RechargeItemType.SpacingItem or self.configData.paytype == RechargeItemType.LuckyBuy) and not isInPeriod then
    noticeManager:OpenTipPage(self, UIHelper.GetString(270038))
    return
  end
  if self.configData.currency_type == CurrencyType.RMB and Logic.loginLogic.SDKHashMsg.canPay == 0 then
    UIHelper.ClosePage("GiftInfoPage")
    noticeManager:ShowMsgBox(430003)
    return
  end
  if self.configData.currency_type ~= CurrencyType.RMB then
    local cost = Logic.shopLogic:GetDiscountPrice(self.configData.cost, self.useDisInfoTab[1])
    local tabInfo = {
      Type = GoodsType.CURRENCY,
      CurrencyId = self.configData.currency_type,
      CostNum = cost
    }
    local tabCondition = {tabInfo}
    local isCan = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
    if not isCan then
      UIHelper.ClosePage("GiftInfoPage")
      return
    end
  end
  eventManager:SendEvent(LuaEvent.BuyRechargeItem, self.configData)
  UIHelper.ClosePage("GiftInfoPage")
end

function GiftInfoPage:_BuyShopGoodsGift()
  local goodsData = self.configData
  local shopId = self.shopId
  local num = 1
  local tabCondition = Logic.shopLogic:GetTableBuyCurrency(goodsData.price2, num, self.useDisInfoTab)
  local isCan = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
  if isCan and Logic.shopLogic:CheckBuyGoodsCondition(shopId, goodsData) then
    Service.shopService:SendBuyGoods(shopId, goodsData.id, num, self.configData.discountId)
    local costNum = {}
    local currencyNum = {}
    for k, v in pairs(tabCondition) do
      costNum[tostring(v.CurrencyId)] = tostring(v.CostNum)
      currencyNum[tostring(v.CurrencyId)] = tostring(Data.userData:GetCurrency(v.CurrencyId))
    end
    local dotinfo = {
      info = "ui_shop_buy",
      item_num = {
        [tostring(goodsData.goods[2])] = tostring(num)
      },
      cost_num = costNum,
      currency_num = currencyNum
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  end
  UIHelper.ClosePage("GiftInfoPage")
end

function GiftInfoPage:_ClickClose()
  UIHelper.ClosePage("GiftInfoPage")
end

function GiftInfoPage:_GotoDiscountDropPath()
  if self.openDiscountDP and #self.configData.discount_id ~= 0 then
    local accessId = Logic.itemLogic:GetDiscountConfig(self.configData.discount_id[1]).drop_path
    if next(accessId) ~= nil then
      do
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              local dropConfig = configManager.GetDataById("config_access", accessId[1])
              local functionId = dropConfig.drop_path[1]
              if functionId == FunctionID.Activity then
                local activityId = dropConfig.drop_path[2]
                local isOpen = moduleManager:CheckFunc(functionId, false) and Logic.activityLogic:CheckActivityOpenById(activityId)
                if isOpen then
                  UIHelper.ClosePage("GiftInfoPage")
                  moduleManager:JumpToFunc(functionId, activityId)
                else
                  noticeManager:ShowTipById(110025)
                end
              end
            elseif self.configData.paytype then
              self:_BuyRechargeGift()
            else
              self:_BuyShopGoodsGift()
            end
          end
        }
        noticeManager:ShowMsgBox(UIHelper.GetString(1300055), tabParams)
        return true
      end
    end
  end
  return false
end

return GiftInfoPage
