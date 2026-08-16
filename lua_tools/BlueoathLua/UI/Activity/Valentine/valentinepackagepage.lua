local ValentinePackagePage = class("UI.Activity.Valentine.ValentinePackagePage", LuaUIPage)

function ValentinePackagePage:DoInit()
  self.activityId = 0
  self.actConfig = 0
  self.goodsInfo = nil
end

function ValentinePackagePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_get, self.ClickBuy, self)
  self:RegisterEvent(LuaEvent.BuyRechargeItem, self._BuyItem, self)
  self:RegisterEvent(LuaEvent.RechargeGetRewards, self._ShowRechargeRewards, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.bu_tips, self.ClicTips, self)
end

function ValentinePackagePage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.activityId)
  self:ShowActTime()
  self:ShowGiftInfo()
  eventManager:SendEvent(LuaEvent.OpenValentinePackage)
end

function ValentinePackagePage:ShowActTime()
  local startTime, endTime = PeriodManager:GetPeriodTime(self.actConfig.period, self.actConfig.period_area)
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  local isFirst = PlayerPrefs.GetInt(uid .. "ValentinePackagePage", 0)
  if isFirst == 0 or isFirst ~= startTime then
    PlayerPrefs.SetInt(uid .. "ValentinePackagePage", startTime)
  end
  local endTimeCount = endTime
  startTime = time.formatTimeToMDHM(startTime)
  endTime = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_actTime, startTime .. " - " .. endTime)
  local stopTimer = function()
    if self.mTimer ~= nil then
      self.mTimer:Stop()
      self.mTimer = nil
    end
  end
  local doTimer = function()
    local svrTime = time.getSvrTime()
    local surplusTime = endTimeCount - svrTime
    local str = self:ShowTimeContent(surplusTime)
    if surplusTime <= 0 then
      stopTimer()
      UIHelper.SetText(self.tab_Widgets.tx_time, string.format(UIHelper.GetString(1300067), "00:00:00"))
    else
      UIHelper.SetText(self.tab_Widgets.tx_time, string.format(UIHelper.GetString(1300067), str))
    end
  end
  stopTimer()
  self.mTimer = self:CreateTimer(function()
    doTimer()
  end, 1, -1)
  self.mTimer:Start()
  doTimer()
end

function ValentinePackagePage:ShowTimeContent(surplusTime)
  local days = math.floor(surplusTime / 86400)
  local remainHours = surplusTime - days * 86400
  local hours = math.floor(remainHours / 3600)
  local str
  if 0 < days and 0 < hours then
    if 0 < hours then
      str = string.format(UIHelper.GetString(1300072), days) .. string.format(UIHelper.GetString(1300073), hours)
    else
      str = string.format(UIHelper.GetString(1300072), days)
    end
  elseif days == 0 then
    str = UIHelper.GetCountDownStr(surplusTime)
  end
  return str
end

function ValentinePackagePage:ShowGiftInfo()
  local goodsId = self.actConfig.p1[1]
  local goodsConf = configManager.GetDataById("config_recharge", tostring(goodsId))
  local isInPeriod = #goodsConf.double_period <= 0
  if not isInPeriod then
    for _, perId in pairs(goodsConf.double_period) do
      if PeriodManager:IsInPeriod(perId) then
        isInPeriod = true
        break
      end
    end
  end
  local serverData = Logic.rechargeLogic:GetServerDataById(goodsId)
  local num = serverData and serverData.LimitBuyTimes or 0
  local canBuy = 0 >= goodsConf.buynum or num < goodsConf.buynum
  if isInPeriod and canBuy then
    self.goodsInfo = goodsConf
  end
  local discountInfo = Logic.shopLogic:GetUsableDiscountConf(goodsId, true)
  if discountInfo == nil then
    self.tab_Widgets.tx_descDiscount.text = UIHelper.GetString(1300058)
  else
    local discountConf = Logic.itemLogic:GetDiscountConfig(discountInfo.config.id)
    self.tab_Widgets.tx_descDiscount.text = string.format(UIHelper.GetString(1300057), math.floor(discountConf.discount_rate / 1000))
  end
  if not self.goodsInfo then
    self.tab_Widgets.obj_complete:SetActive(true)
    self.tab_Widgets.obj_get:SetActive(false)
    self.tab_Widgets.tx_descDiscount.gameObject:SetActive(false)
  end
end

function ValentinePackagePage:ClickBuy()
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  local gotRewardTime = Data.activityValentineData:GetGotValentineRewardTime()
  if gotRewardTime == 0 then
    if self.goodsInfo.discount_id ~= 0 then
      local accessId = Logic.itemLogic:GetDiscountConfig(self.goodsInfo.discount_id[1]).drop_path
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
              else
                UIHelper.OpenPage("GiftInfoPage", {
                  configData = self.goodsInfo,
                  shopId = ShopId.Gift,
                  openDiscountDP = false
                })
              end
            end
          }
          noticeManager:ShowMsgBox(UIHelper.GetString(1300055), tabParams)
        end
      end
    end
  else
    UIHelper.OpenPage("GiftInfoPage", {
      configData = self.goodsInfo,
      shopId = ShopId.Gift,
      openDiscountDP = false
    })
  end
end

function ValentinePackagePage:_BuyItem(info)
  if not platformManager:useSDK() then
    return
  end
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
  if info.paytype == RechargeItemType.LuckyBuy then
    Service.rechargeService:DirectBuyItemCallBack(info.id, info.discountId)
  end
end

function ValentinePackagePage:_ShowRechargeRewards()
  local rewards = Data.rechargeData:GetRechargeRewardData()
  Logic.rewardLogic:ShowCommonReward(rewards, "ValentinePackagePage", nil)
  self.tab_Widgets.obj_complete:SetActive(true)
  self.tab_Widgets.obj_get:SetActive(false)
  self.tab_Widgets.tx_descDiscount.gameObject:SetActive(false)
end

function ValentinePackagePage:ClicTips()
  UIHelper.OpenPage("HelpPage", {content = 1300068})
end

function ValentinePackagePage:DoOnClose()
end

function ValentinePackagePage:DoOnHide()
end

return ValentinePackagePage
