local NewYearLuckyBagPage = class("UI.Activity.NewYearActivity.NewYearLuckyBagPage", LuaUIPage)

function NewYearLuckyBagPage:DoInit()
  self.buyCount = 0
  self.SpecialReward = {}
  self.m_timer = nil
  self.wishEff = nil
  self.goodEff = nil
end

function NewYearLuckyBagPage:DoOnOpen()
  local param = self:GetParam()
  self.mActivityId = param.activityId
  local actFahionData = Data.activityData:GetActFashionData()
  self:_ShowActivityDes(actFahionData)
end

function NewYearLuckyBagPage:_ShowActivityDes(actFahionData)
  local widgets = self:GetWidgets()
  self.activityInfo = configManager.GetDataById("config_activity", self.mActivityId)
  local periodInfo = configManager.GetDataById("config_period", self.activityInfo.period)
  local startTime, endTime = PeriodManager:GetPeriodTime(self.activityInfo.period, self.activityInfo.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(startTime + periodInfo.duration)
  UIHelper.SetText(widgets.textTime, startTimeFormat .. "-" .. endTimeFormat)
  UIHelper.SetText(widgets.tx_actContent, UIHelper.GetString(7300001))
  local fashion = self.activityInfo.p5
  local money = self.activityInfo.p4
  UIHelper.SetText(widgets.txt_money, money[1][1])
  local shipShowConfig = Logic.shipLogic:GetShipShowByFashionId(fashion[1][1])
  UIHelper.SetImage(widgets.im_girl, shipShowConfig.ship_draw)
  self:_TickCharge(endTime)
  UIHelper.SetText(widgets.tx_ten, UIHelper.GetString(7500005))
  UIHelper.SetText(widgets.tx_thirty, UIHelper.GetString(7500006))
  local name = configManager.GetDataById("config_fashion", fashion[1][1]).name
  UIHelper.SetText(widgets.tx_girl, name)
  local shipCVConfig = configManager.GetDataById("config_ship_handbook", shipShowConfig.sf_id)
  UIHelper.SetText(widgets.tx_cv, shipCVConfig.ship_character_voice)
  self:UpdateInfo(actFahionData)
end

function NewYearLuckyBagPage:_TickCharge(endTime)
  local stopTimer = function()
    if self.m_timer ~= nil then
      self.m_timer:Stop()
      self.m_timer = nil
    end
  end
  local doTimer = function()
    local svrTime = time.getSvrTime()
    local surplusTime = endTime - svrTime
    if surplusTime <= 0 then
      stopTimer()
      UIHelper.SetText(self.tab_Widgets.textLeftTime, "")
    else
      UIHelper.SetText(self.tab_Widgets.textLeftTime, UIHelper.GetCountDownStr(surplusTime))
    end
  end
  stopTimer()
  self.m_timer = self:CreateTimer(function()
    doTimer()
  end, 1, -1)
  self.m_timer:Start()
  doTimer()
end

function NewYearLuckyBagPage:UpdateInfo(actFahionData)
  local widgets = self:GetWidgets()
  local isShowWish = true
  local isShowGood = true
  self.buyCount = actFahionData.BuyCount
  self.SpecialReward = actFahionData.SpecialReward
  local fashion = self.activityInfo.p5
  local maxNum = self.activityInfo.p6
  UIHelper.SetText(widgets.tx_num, self.buyCount .. "/" .. maxNum[1])
  for k, v in pairs(self.SpecialReward) do
    if v == 1 then
      isShowWish = false
    elseif v == 2 then
      isShowGood = false
    end
  end
  local boxCfg = configManager.GetDataById("config_starbox", 8)
  if self.buyCount < 10 then
    self:_DestroyRingEffect(self.wishEff)
    UIHelper.SetImage(widgets.im_wishIcon, boxCfg.unopen_icon)
  elseif self.buyCount >= 10 and isShowWish then
    UIHelper.SetImage(widgets.im_wishIcon, boxCfg.open_icon)
    if self.wishEff == nil then
      self.wishEff = UIHelper.CreateUIEffect(boxCfg.open_effect, self.tab_Widgets.obj_wishReward)
    end
  else
    self:_DestroyRingEffect(self.wishEff)
    UIHelper.SetImage(widgets.im_wishIcon, boxCfg.recieved_icon)
  end
  if self.buyCount < 30 then
    self:_DestroyRingEffect(self.goodEff)
    UIHelper.SetImage(widgets.im_goodIcon, boxCfg.unopen_icon)
  elseif self.buyCount >= 30 and isShowGood then
    UIHelper.SetImage(widgets.im_goodIcon, boxCfg.open_icon)
    if self.goodEff == nil then
      self.goodEff = UIHelper.CreateUIEffect(boxCfg.open_effect, self.tab_Widgets.obj_goodReward)
    end
  else
    self:_DestroyRingEffect(self.goodEff)
    UIHelper.SetImage(widgets.im_goodIcon, boxCfg.recieved_icon)
  end
  local isHave = Logic.fashionLogic:CheckFashionOwn(fashion[1][1])
  widgets.obj_have:SetActive(isHave)
  widgets.obj_noHave:SetActive(not isHave)
  widgets.slider.value = self.buyCount / maxNum[1]
  widgets.slider.interactable = false
  widgets.btn_grayBuy.Gray = self.buyCount == maxNum[1]
end

function NewYearLuckyBagPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_buy, self._BuyLuckyBag, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_wishReward, self._GetWishReward, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_goodReward, self._GetGoodReward, self)
  self:RegisterEvent(LuaEvent.GetActivityfashion, self.UpdateInfo, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_tip, self._ClickTip, self)
  self:RegisterEvent(LuaEvent.RewardActFashionSuc, self._RewardActFashionSuc, self)
end

function NewYearLuckyBagPage:_GetWishReward(...)
  local inPeriod = PeriodManager:IsInPeriod(self.activityInfo.period)
  if not inPeriod then
    noticeManager:ShowTip(UIHelper.GetString(2900003))
    return
  end
  local num = self.activityInfo.p2
  self:_ClickBox(1, num[1], self.activityInfo.p2)
end

function NewYearLuckyBagPage:_GetGoodReward(...)
  local inPeriod = PeriodManager:IsInPeriod(self.activityInfo.period)
  if not inPeriod then
    noticeManager:ShowTip(UIHelper.GetString(2900003))
    return
  end
  local num = self.activityInfo.p3
  self:_ClickBox(2, num[1], self.activityInfo.p3)
end

function NewYearLuckyBagPage:_ClickBox(index, num, rewardData)
  local get = false
  for _, v in pairs(self.SpecialReward) do
    if v == index then
      get = true
    end
  end
  local rewards = Logic.rewardLogic:GetAllShowRewardByDropId(rewardData[2])
  if num <= self.buyCount and not get then
    Service.activityService:SendActivityFashionReward(index)
  elseif num <= self.buyCount and get then
    UIHelper.OpenPage("BoxRewardPage", {
      rewardState = RewardState.Received,
      rewards = rewards
    })
  else
    UIHelper.OpenPage("BoxRewardPage", {
      rewardState = RewardState.UnReceivable,
      rewards = rewards
    })
  end
end

function NewYearLuckyBagPage:_BuyLuckyBag()
  local inPeriod = PeriodManager:IsInPeriod(self.activityInfo.period)
  if not inPeriod then
    noticeManager:ShowTip(UIHelper.GetString(2900003))
    return
  end
  local maxNum = self.activityInfo.p6
  if self.buyCount == maxNum[1] then
    noticeManager:ShowTip(UIHelper.GetString(7500007))
  else
    UIHelper.OpenPage("LuckyBagContentPage", self.mActivityId)
  end
end

function NewYearLuckyBagPage:_ClickTip()
  UIHelper.OpenPage("HelpPage", {content = 7500004})
end

function NewYearLuckyBagPage:_RewardActFashionSuc(args)
  for v, k in pairs(args) do
    Logic.rewardLogic:ShowCommonReward(k, "LuckyBagContentPage", nil)
  end
end

function NewYearLuckyBagPage:_DestroyRingEffect(objEff)
  if objEff ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(objEff)
    objEff = nil
  end
end

function NewYearLuckyBagPage:DoOnHide()
end

function NewYearLuckyBagPage:DoOnClose()
  if self.goodEff ~= nil then
    self:_DestroyRingEffect(self.goodEff)
  end
  if self.wishEff ~= nil then
    self:_DestroyRingEffect(self.wishEff)
  end
end

return NewYearLuckyBagPage
