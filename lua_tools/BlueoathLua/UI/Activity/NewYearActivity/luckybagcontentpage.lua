local LuckyBagContentPage = class("UI.Activity.NewYearActivity.LuckyBagContentPage", LuaUIPage)
local ONCE_MAX_NUM = 10
local ONCE_MIN_NUM = 1

function LuckyBagContentPage:DoInit()
  self.selectNum = 1
  self.activityInfo = {}
end

function LuckyBagContentPage:DoOnOpen()
  self.activityId = self:GetParam()
  self.activityInfo = configManager.GetDataById("config_activity", self.activityId)
  self:InitPage()
  self:_ShowContentInfo()
end

function LuckyBagContentPage:InitPage()
  local actFahionData = Data.activityData:GetActFashionData()
  local money = self.activityInfo.p4
  local max = self.activityInfo.p6
  self.maxNum = max[1] - actFahionData.BuyCount
  UIHelper.SetText(self.tab_Widgets.txt_num, self.selectNum)
  UIHelper.SetText(self.tab_Widgets.txt_bagitem, UIHelper.GetString(7500003))
  UIHelper.SetText(self.tab_Widgets.txt_costNum, self.selectNum * money[1][1])
end

function LuckyBagContentPage:_ShowContentInfo()
  local itemInfo = {}
  local mapItem = {}
  local mapReward = {}
  if next(self.activityInfo) ~= nil then
    for k, v in pairs(self.activityInfo.p1) do
      local rewards = Logic.rewardLogic:GetAllShowRewardByDropId(v)
      for _, value in pairs(rewards) do
        if mapReward[value.Type] == nil then
          mapReward[value.Type] = {}
        end
        mapReward[value.Type][value.ConfigId] = value.Num
      end
    end
  end
  if next(self.activityInfo) ~= nil then
    for k, v in pairs(self.activityInfo.p1) do
      local dropGoodsConf, dropItemConfig = Logic.itemLogic:GetConfByDropId(v)
      for _, value in pairs(dropGoodsConf) do
        table.insertto(value, {
          num = mapReward[value.tabIndex][value.id]
        })
        value.num = mapReward[value.tabIndex][value.id]
        if mapItem[value.tabIndex] == nil then
          mapItem[value.tabIndex] = {}
        end
        if mapItem[value.tabIndex][value.id] == nil then
          if value.tabIndex == GoodsType.FASHION then
            table.insert(itemInfo, 1, value)
          else
            table.insert(itemInfo, value)
          end
          mapItem[value.tabIndex][value.id] = true
        end
      end
    end
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_item, #itemInfo, function(index, tabPart)
    local itemContent = itemInfo[index]
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[itemContent.quality])
    UIHelper.SetImage(tabPart.img_icon, itemContent.icon)
    UIHelper.SetText(tabPart.tx_name, itemContent.name)
    UIHelper.SetText(tabPart.tx_num, "x" .. itemContent.num)
    local cost = {
      itemContent.tabIndex,
      itemContent.id
    }
    UGUIEventListener.AddButtonOnClick(tabPart.btn_click, self._ShowWay, self, cost)
  end)
end

function LuckyBagContentPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeTip, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_decreaseNum, function()
    self:_DecreaseNum(ONCE_MIN_NUM)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_add, function()
    self:_AddNum(ONCE_MIN_NUM)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_tenButton, function()
    self:_AddNum(ONCE_MAX_NUM)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_subButton, function()
    self:_DecreaseNum(ONCE_MAX_NUM)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_buy, self._BuyLuckyBag, self)
  self:RegisterEvent(LuaEvent.BuyActFashionSuc, self._BuyActFashionSuc, self)
  self:RegisterEvent(LuaEvent.ActFashionSucError, self._ErrorActData, self)
end

function LuckyBagContentPage:_AddNum(num)
  if self.selectNum == ONCE_MIN_NUM and num == ONCE_MAX_NUM then
    self.selectNum = num
  else
    self.selectNum = self.selectNum + num
  end
  local money = self.activityInfo.p4
  self.selectNum = self.selectNum > self.maxNum and self.maxNum or self.selectNum
  UIHelper.SetText(self.tab_Widgets.txt_num, self.selectNum)
  UIHelper.SetText(self.tab_Widgets.txt_costNum, self.selectNum * money[1][1])
end

function LuckyBagContentPage:_DecreaseNum(num)
  local money = self.activityInfo.p4
  self.selectNum = self.selectNum - num
  self.selectNum = self.selectNum < ONCE_MIN_NUM and ONCE_MIN_NUM or self.selectNum
  if self.maxNum == 0 then
    self.selectNum = 0
  end
  UIHelper.SetText(self.tab_Widgets.txt_num, self.selectNum)
  UIHelper.SetText(self.tab_Widgets.txt_costNum, self.selectNum * money[1][1])
end

function LuckyBagContentPage:_BuyLuckyBag()
  local inPeriod = PeriodManager:IsInPeriod(self.activityInfo.period)
  if not inPeriod then
    noticeManager:ShowTip(UIHelper.GetString(2900003))
    return
  end
  local actFahionData = Data.activityData:GetActFashionData()
  local data = {type = 5, id = 25}
  local showObj, value = Logic.itemLogic:GetItemOwnCount(data)
  local money = self.activityInfo.p4
  if value < self.selectNum * money[1][1] then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          Logic.shopLogic:OpenLuckyRechargeShop()
        end
      end
    }
    local tips = UIHelper.GetString(270043)
    noticeManager:ShowMsgBox(tips, tabParams)
  elseif self.selectNum > self.maxNum or self.selectNum == 0 then
    noticeManager:ShowTip(UIHelper.GetString(7500007))
  else
    Service.activityService:SendActivityFashionBuy(self.selectNum)
  end
end

function LuckyBagContentPage:_ShowWay(go, cost)
  Logic.itemLogic:ShowItemInfo(cost[1], cost[2])
end

function LuckyBagContentPage:_BuyActFashionSuc(args)
  for v, k in pairs(args) do
    Logic.rewardLogic:ShowCommonReward(k, "LuckyBagContentPage", nil)
  end
  self:InitPage()
end

function LuckyBagContentPage:_ErrorActData(err)
  if err == ErrorCode.ErrActivityFashionPeriod then
    noticeManager:ShowTip(UIHelper.GetString(2900003))
  elseif err == ErrorCode.ErrActivityFashionLimit then
    noticeManager:ShowTip(UIHelper.GetString(7500007))
  end
end

function LuckyBagContentPage:_ClickClose()
  eventManager:SendEvent(LuaEvent.CloseRemouldEffectPage)
  UIHelper.ClosePage("LuckyBagContentPage")
end

function LuckyBagContentPage:DoOnHide()
end

function LuckyBagContentPage:DoOnClose()
end

return LuckyBagContentPage
