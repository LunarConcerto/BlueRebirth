local ExchangeActivityPage = class("UI.Activity.ExchangeActivityPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ExchangeActivityPage:DoInit()
  self.openActivityData = {}
  self.activityId = nil
  self.refreshTime = nil
end

function ExchangeActivityPage:DoOnOpen()
  Service.exchangeService:GetExchangeInfo()
  local params = self:GetParam()
  local activityId = params.activityId
  self.activityId = activityId
  local configData = configManager.GetDataById("config_activity", self.activityId)
  self.configData = configData
  UIHelper.SetImage(self.tab_Widgets.im_bg, configData.p3[1])
  self:StopAllTimer()
  self:_ShowActivityTime()
  self:_ShowMaterial()
  self:_ShowExchange()
end

function ExchangeActivityPage:Refresh()
  self:StopAllTimer()
  self:_ShowActivityTime()
  self:_ShowMaterial()
  self:_ShowExchange()
end

function ExchangeActivityPage:_ShowActivityTime()
  local configData = configManager.GetDataById("config_activity", self.activityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(configData.period, configData.period_area)
  self.endTime = endTime
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_time, startTimeFormat .. "<color=#FFFFFF> - </color>" .. endTimeFormat)
  local timer = self:CreateTimer(function()
    local timeLeft = endTime - time.getSvrTime()
    local timeLeftFormat = time.formatTimerToDHMSColor(timeLeft)
    UIHelper.SetText(self.tab_Widgets.tx_time_left, timeLeftFormat)
    if timeLeft < 0 then
      UIHelper.ClosePage("ActivityPage")
    end
  end, 0.5, -1)
  self:StartTimer(timer)
  self.tab_Widgets.im_grey:SetActive(PeriodManager:IsInPeriodArea(configData.period, configData.p6))
end

function ExchangeActivityPage:_ShowMaterial()
  local p2 = self.configData.p2
  UIHelper.CreateSubPart(self.tab_Widgets.item_left, self.tab_Widgets.Content_left, #p2, function(index, tabPart)
    local data = p2[index]
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
    UIHelper.SetImage(tabPart.img_icon, itemInfo.icon)
    UIHelper.SetText(tabPart.tx_item_name, itemInfo.name)
    local num = Logic.bagLogic:GetConsumeCurrNum(data[1], data[2])
    UIHelper.SetText(tabPart.tx_num, num)
  end)
end

function ExchangeActivityPage:_ShowExchange()
  local p1 = self:getExchangeItem()
  UIHelper.CreateSubPart(self.tab_Widgets.item, self.tab_Widgets.Content, #p1, function(index, tabPart)
    local exchangeId = p1[index]
    local configData = configManager.GetDataById("config_item_exchange", p1[index])
    local consume = configData.item_consume
    UIHelper.CreateSubPart(tabPart.consume, tabPart.Content_consume, #consume, function(indexSub, tabPartSub)
      local data = consume[indexSub]
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
      UIHelper.SetImage(tabPartSub.img_icon, itemInfo.icon)
      UIHelper.SetImage(tabPartSub.img_quality, QualityIcon[itemInfo.quality])
      UIHelper.SetText(tabPartSub.tx_num, data[3])
      UGUIEventListener.AddButtonOnClick(tabPartSub.btn_reward, self._ShowItemInfo, self, data)
    end)
    local reward = configData.item_reward
    UIHelper.CreateSubPart(tabPart.consume, tabPart.Content_reward, #reward, function(indexSub, tabPartSub)
      local data = reward[indexSub]
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
      UIHelper.SetImage(tabPartSub.img_icon, itemInfo.icon)
      UIHelper.SetImage(tabPartSub.img_quality, QualityIcon[itemInfo.quality])
      UIHelper.SetText(tabPartSub.tx_num, data[3])
      UGUIEventListener.AddButtonOnClick(tabPartSub.btn_reward, self._ShowItemInfo, self, data)
    end)
    local refresh_id = configData.refresh_id
    local change_count = configData.change_count
    tabPart.tx_refresh.gameObject:SetActive(0 < refresh_id)
    if 0 < refresh_id then
      local timer = self:CreateTimer(function()
        local currRefreshTime = PeriodManager:GetNextRefreshTime(refresh_id)
        if currRefreshTime >= self.endTime then
          UIHelper.SetLocText(tabPart.tx_refresh, 810020004)
          return
        end
        local timeLeft = currRefreshTime - time.getSvrTime()
        if timeLeft < 0 then
          Service.exchangeService:GetExchangeInfo()
        end
        timeLeft = 0 <= timeLeft and timeLeft or 0
        local timeLeftFormat = time.formatTimerToHMS(timeLeft)
        UIHelper.SetLocText(tabPart.tx_refresh, 810020005, timeLeftFormat)
      end, 0.5, -1)
      self:StartTimer(timer)
    end
    tabPart.tx_num.gameObject:SetActive(0 < change_count)
    if 0 < change_count then
      local exchangeNum = Data.exchangeData:GetExchangeTimes(exchangeId)
      UIHelper.SetText(tabPart.tx_num, change_count - exchangeNum .. "/" .. change_count)
    end
    local checkCondition = Logic.exchangeLogic:CheckCondition(exchangeId)
    tabPart.obj_unable:SetActive(not checkCondition)
    local checkConsume = Logic.exchangeLogic:CheckConsume(exchangeId)
    local checkTimes = Logic.exchangeLogic:CheckTimes(exchangeId)
    tabPart.gray.Gray = not checkTimes
    UIHelper.SetText(tabPart.tx_unable, configData.condition_desc)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_get, function()
      local checkTimes = Logic.exchangeLogic:CheckTimes(exchangeId)
      if not checkTimes then
        noticeManager:ShowTipById(810020001)
        return
      end
      UIHelper.OpenPage("ExchangeActivityConfirmPage", {
        activityId = self.activityId,
        exchangeId = p1[index]
      })
    end)
  end)
end

function ExchangeActivityPage:getExchangeItem()
  local p1 = self.configData.p1
  local data = clone(p1)
  table.sort(data, function(a, b)
    local checkCondition_a = Logic.exchangeLogic:CheckCondition(a)
    local checkConsume_a = Logic.exchangeLogic:CheckConsume(a)
    local checkTimes_a = Logic.exchangeLogic:CheckTimes(a)
    local check_a = checkCondition_a and checkTimes_a
    local checkCondition_b = Logic.exchangeLogic:CheckCondition(b)
    local checkConsume_b = Logic.exchangeLogic:CheckConsume(b)
    local checkTimes_b = Logic.exchangeLogic:CheckTimes(b)
    local check_b = checkCondition_b and checkTimes_b
    if check_a ~= check_b then
      return check_a
    else
      return a < b
    end
  end)
  return data
end

function ExchangeActivityPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateBagItem, self.Refresh, self)
  self:RegisterEvent(LuaEvent.GetExchangeMsg, self.Refresh, self)
  self:RegisterEvent(LuaEvent.Exchange, self.GetReward, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_copy, function()
    moduleManager:JumpToFunc(FunctionID.SeaCopy)
  end)
end

function ExchangeActivityPage:_ShowItemInfo(go, award)
  Logic.rewardLogic:ShowReward(award[1], award[2])
end

function ExchangeActivityPage:GetReward(arg)
  local exchangeId = arg.Id
  local time = arg.Time
  local configData = configManager.GetDataById("config_item_exchange", exchangeId)
  local Rewards = {}
  for i, v in ipairs(configData.item_reward) do
    local RewardsSub = {}
    RewardsSub.Type = v[1]
    RewardsSub.ConfigId = v[2]
    RewardsSub.Num = v[3] * time
    table.insert(Rewards, RewardsSub)
  end
  Logic.rewardLogic:ShowCommonReward(Rewards)
end

return ExchangeActivityPage
