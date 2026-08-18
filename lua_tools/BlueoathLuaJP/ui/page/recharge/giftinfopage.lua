local GiftInfoPage = class("UI.Recharge.GiftInfoPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function GiftInfoPage:DoInit()
  self.m_tabWidgets = nil
end

function GiftInfoPage:DoOnOpen()
  self.configData = self.param.configData
  self.shopId = self.param.shopId
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
    if configData.drop_reward > 0 then
      self.tab_Widgets.obj_Tips:SetActive(false)
      self.tab_Widgets.obj_DropTips:SetActive(true)
      rewards = Logic.rewardLogic:GetAllRewardByDropId(configData.drop_reward)
    else
      self.tab_Widgets.obj_Tips:SetActive(true)
      self.tab_Widgets.obj_DropTips:SetActive(false)
      if 0 < configData.reward then
        rewards = clone(configManager.GetDataById("config_rewards", configData.reward).rewards)
      end
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
    local extra_reward = {}
    if doubleActive then
      extra_reward = configManager.GetDataById("config_rewards", configData.extra_reward).rewards
    elseif 0 < configData.nodouble_extra_reward then
      extra_reward = configManager.GetDataById("config_rewards", configData.nodouble_extra_reward).rewards
    end
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
    self.tab_Widgets.img_icon.gameObject:SetActive(configData.currency_type ~= CurrencyType.RMB and 0 < configData.true_cost)
    local str = configData.currency_type == CurrencyType.RMB and string.format("\239\191\165%s", configData.true_cost) or configData.cost
    if configData.true_cost == 0 then
      str = UIHelper.GetString(430006)
    end
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
    if 0 < #configData.currency then
      local currencyType = configData.currency[1][1]
      local currencyId = configData.currency[1][2]
      local cost = configData.price[1][1]
      local currencyIcon = Logic.goodsLogic:GetSmallIcon(currencyId, currencyType)
      UIHelper.SetImage(self.tab_Widgets.img_icon, currencyIcon)
      UIHelper.SetText(self.tab_Widgets.txt_cost, cost)
    else
      self.tab_Widgets.img_icon.gameObject:SetActive(false)
      UIHelper.SetText(self.tab_Widgets.txt_cost, UIHelper.GetString(430006))
    end
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
    local tabInfo = {
      Type = GoodsType.CURRENCY,
      CurrencyId = self.configData.currency_type,
      CostNum = self.configData.true_cost
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
  for _, v in ipairs(goodsData.buy_limits) do
    local reachLimit, msg = Logic.gameLimitLogic.CheckConditionById(v)
    if not reachLimit then
      local limitConfig = configManager.GetDataById("config_game_limits", v)
      local msg = limitConfig.desc .. UIHelper.GetString(920000280)
      noticeManager:OpenTipPage(self, msg)
      return
    end
  end
  local buyNum = goodsData.is_buy_batch ~= 0 and goodsData.goods[3] or 1
  local gridId = Logic.shopLogic:GetRecommendShopGoodsGridId(goodsData.id)
  local shopId = self.shopId
  local num = 1
  local priceTab = {}
  local serverData = Logic.rechargeLogic:GetServerDataById(self.configData.id)
  local purchaseNum = serverData ~= nil and serverData.Num or 0
  for i, v in ipairs(goodsData.currency) do
    local price = Logic.shopLogic:GetPriceByNum(goodsData.price[i], purchaseNum, num)
    table.insert(priceTab, {
      goodsData.currency[i][1],
      goodsData.currency[i][2],
      price
    })
  end
  local tabCondition = Logic.shopLogic:GetTableBuyCurrency(priceTab)
  local isCan = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
  if isCan and Logic.shopLogic:CheckBuyGoodsCondition(shopId, goodsData) then
    Service.shopService:SendBuyGoods(shopId, goodsData.id, num)
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

return GiftInfoPage
