local ExchangeActivityConfirmPage = class("UI.Activity.ExchangeActivityConfirmPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local ONCE_TEN_NUM = 10
local ONCE_MIN_NUM = 1
local WhiteGay = -1

function ExchangeActivityConfirmPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.num = 1
  self.isOwnOne = false
end

function ExchangeActivityConfirmPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateBagItem, self.ShowPage, self)
  self:RegisterEvent(LuaEvent.GetExchangeMsg, self.ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickOK, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancel, self._ClickCANCEL, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_minus, function()
    self:_ClickSubBuyNum(ONCE_MIN_NUM)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_plus, function()
    self:_ClickAddBuyNum(ONCE_MIN_NUM)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_tenminus, function()
    self:_ClickSubBuyNum(ONCE_TEN_NUM)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_tenplus, function()
    self:_ClickAddBuyNum(ONCE_TEN_NUM)
  end)
end

function ExchangeActivityConfirmPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.activityId = params.activityId
  self.exchangeId = params.exchangeId
  self.num = 1
  self:ShowPage()
end

function ExchangeActivityConfirmPage:ShowPage()
  self:_ShowItems()
  self:_ShowNumberAndButton()
end

function ExchangeActivityConfirmPage:_ShowItems()
  local configData = configManager.GetDataById("config_item_exchange", self.exchangeId)
  local consume = configData.item_consume
  local reward = configData.item_reward
  local tabPart = self.tab_Widgets
  local _, nimTime = Logic.exchangeLogic:CheckTimes(self.exchangeId)
  UIHelper.SetLocText(tabPart.tx_timeLeft, 810020006, nimTime)
  local checkTimes, nimTime = Logic.exchangeLogic:CheckTimes(self.exchangeId)
  tabPart.tx_timeLeft.gameObject:SetActive(nimTime ~= 1)
  self.tab_Widgets.btn_tenminus.gameObject:SetActive(nimTime ~= 1)
  self.tab_Widgets.btn_tenplus.gameObject:SetActive(nimTime ~= 1)
  UIHelper.CreateSubPart(tabPart.consume, tabPart.Content_consume, #consume, function(indexSub, tabPartSub)
    local data = consume[indexSub]
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
    UIHelper.SetImage(tabPartSub.img_icon, itemInfo.icon)
    UIHelper.SetImage(tabPartSub.img_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetText(tabPartSub.tx_num, data[3] * self.num)
    UGUIEventListener.AddButtonOnClick(tabPartSub.btn_reward, self._ShowItemInfo, self, data)
  end)
  UIHelper.CreateSubPart(tabPart.reward, tabPart.Content_reward, #reward, function(indexSub, tabPartSub)
    local data = reward[indexSub]
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
    UIHelper.SetImage(tabPartSub.img_icon, itemInfo.icon)
    UIHelper.SetImage(tabPartSub.img_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetText(tabPartSub.tx_num, data[3] * self.num)
    UGUIEventListener.AddButtonOnClick(tabPartSub.btn_reward, self._ShowItemInfo, self, data)
    local isOwnOne = false
    if data[1] == GoodsType.FASHION and Logic.fashionLogic:CheckFashionOwn(data[2]) then
      isOwnOne = true
      self.isOwnOne = true
    end
    tabPartSub.img_alreadyget.gameObject:SetActive(isOwnOne)
  end)
end

function ExchangeActivityConfirmPage:_ShowNumberAndButton()
  local widgets = self.tab_Widgets
  UIHelper.SetText(widgets.txt_num, self.num)
  local canChange, maxChange = self:__GetCanExgUnique()
  widgets.btn_okGray.Gray = not canChange or self.isOwnOne
end

function ExchangeActivityConfirmPage:_ShowItemInfo(go, award)
  Logic.rewardLogic:ShowReward(award[1], award[2])
end

function ExchangeActivityConfirmPage:_ClickClose()
  UIHelper.ClosePage(self:GetName())
end

function ExchangeActivityConfirmPage:_ClickCANCEL()
  UIHelper.ClosePage(self:GetName())
end

function ExchangeActivityConfirmPage:_ClickOK()
  local checkTimes = Logic.exchangeLogic:CheckTimes(self.exchangeId)
  if not checkTimes then
    noticeManager:ShowTipById(810020001)
    return
  end
  local checkConsume = Logic.exchangeLogic:CheckConsume(self.exchangeId)
  if not checkConsume then
    noticeManager:ShowTipById(810020002)
    return
  end
  if self.isOwnOne then
    return
  end
  local configData = configManager.GetDataById("config_item_exchange", self.exchangeId)
  local consume = configData.item_consume
  local reward = configData.item_reward
  local consumePb = {}
  for i, v in ipairs(consume) do
    local consumePbSub = {}
    consumePbSub.Type = v[1]
    consumePbSub.Id = v[2]
    consumePbSub.Num = v[3]
    table.insert(consumePb, consumePbSub)
  end
  local rewardPb = {}
  for i, v in ipairs(reward) do
    local rewardPbSub = {}
    rewardPbSub.Type = v[1]
    rewardPbSub.Id = v[2]
    rewardPbSub.Num = v[3]
    table.insert(rewardPb, rewardPbSub)
  end
  Service.exchangeService:SendExchange({
    Id = self.exchangeId,
    Consume = consumePb,
    Reward = rewardPb,
    Time = self.num
  })
  self:_ClickClose()
end

function ExchangeActivityConfirmPage:_ClickSubBuyNum(subNum, data)
  local minNum = ONCE_MIN_NUM
  local canChange, maxNum = self:__GetCanExgUnique()
  if not canChange then
    noticeManager:OpenTipPage(self, 270018)
    return
  end
  local temp = self.num - minNum * subNum
  if minNum > temp and self.num == minNum then
    noticeManager:OpenTipPage(self, 270018)
    return
  elseif minNum >= temp then
    self.num = minNum
  else
    self.num = temp
  end
  self:ShowPage()
end

function ExchangeActivityConfirmPage:_ClickAddBuyNum(addNum, data)
  local minNum = ONCE_MIN_NUM
  local canChange, maxNum = self:__GetCanExgUnique()
  if not canChange or maxNum < 1 then
    noticeManager:OpenTipPage(self, 270019)
    return
  end
  local temp = 0
  if self.num == ONCE_MIN_NUM and addNum == ONCE_TEN_NUM then
    temp = minNum * addNum
  else
    temp = self.num + minNum * addNum
  end
  if maxNum < temp and self.num == maxNum then
    noticeManager:OpenTipPage(self, 270019)
    return
  elseif maxNum <= temp and maxNum > self.num then
    self.num = maxNum
  else
    self.num = temp
  end
  self:ShowPage()
end

function ExchangeActivityConfirmPage:_ClickAddMax(addNum, data)
  local canChange, maxNum = self:__GetCanExgUnique()
  if not canChange or maxNum < 1 then
    noticeManager:OpenTipPage(self, 270019)
    return
  end
  local temp = maxNum
  if maxNum < temp and self.num == maxNum then
    noticeManager:OpenTipPage(self, 270019)
    return
  else
    self.num = temp
  end
  self:ShowPage()
end

function ExchangeActivityConfirmPage:__GetCanExgUnique()
  local canChange = false
  local maxNum = 0
  local checkConsume, nimConsume = Logic.exchangeLogic:CheckConsume(self.exchangeId)
  local checkTimes, nimTime = Logic.exchangeLogic:CheckTimes(self.exchangeId)
  maxNum = nimConsume
  if nimConsume > nimTime then
    maxNum = nimTime
  end
  canChange = checkConsume and checkTimes
  return canChange, maxNum
end

function ExchangeActivityConfirmPage:DoOnClose()
end

return ExchangeActivityConfirmPage
