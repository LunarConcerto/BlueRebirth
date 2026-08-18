local CodeExchangeConfirmPage = class("UI.Activity.CodeExchangeConfirmPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local ONCE_TEN_NUM = 10
local ONCE_MIN_NUM = 1
local WhiteGay = -1
local rate_num = configManager.GetDataById("config_parameter", 357).value

function CodeExchangeConfirmPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.num = 1
end

function CodeExchangeConfirmPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.RefreshCodeExgItem, self.ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_confirm, self._ClickConfirm, self)
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
    self:_ClickAddMax()
  end)
end

function CodeExchangeConfirmPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.actId
  self.exgid = params.exgid
  self.teamId = params.teamId
  self.pageType = params.pageType
  self.num = 1
  local actTeam = {}
  if self.pageType == codeExgType.Code then
    actTeam = configManager.GetDataById("config_activity", self.mActivityId).p5
  end
  self.team = actTeam[self.teamId]
  self:ShowPage()
end

function CodeExchangeConfirmPage:ShowPageCode()
  self:_ShowConsumeCode(self.team[1])
  self:_ShowRewardCode(self.team[2])
  self:_ShowNumberAndButton()
end

function CodeExchangeConfirmPage:ShowPageReward()
  local actData = configManager.GetDataById("config_activity", self.mActivityId)
  local x, y = Logic.activityCodeExchangeLogic:GetAxesByExgId(self.mActivityId, self.exgid)
  if self.exgid == WhiteGay then
    self:_ClickConfirm()
  end
  self.tab_Widgets.im_plus.gameObject:SetActive(true)
  self:_ShowItemX(actData.p1[x])
  self:_ShowItemY(actData.p2[y])
  self:_ShowReward(actData.p4[self.exgid][1])
  self:_ShowNumberAndButton()
end

function CodeExchangeConfirmPage:ShowPage()
  if self.pageType == codeExgType.Reward then
    self:ShowPageReward()
  else
    self:ShowPageCode()
  end
end

function CodeExchangeConfirmPage:_ShowConsumeCode(itemId)
  self.tab_Widgets.item_x.gameObject:SetActive(true)
  self.tab_Widgets.item_y.gameObject:SetActive(false)
  self.tab_Widgets.im_plus.gameObject:SetActive(false)
  local itemInfo = configManager.GetDataById("config_item_info", itemId)
  UIHelper.SetImage(self.tab_Widgets.im_icon_x, itemInfo.icon)
  UIHelper.SetImage(self.tab_Widgets.im_quality_x, QualityIcon[itemInfo.quality])
  UIHelper.SetText(self.tab_Widgets.tx_neednum_x, rate_num)
  local BagNum = Logic.bagLogic:GetBagItemNum(itemId)
  UIHelper.SetText(self.tab_Widgets.tx_curnum_x, BagNum)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_icon_x, function()
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(math.floor(itemId / 10000), itemId))
  end)
end

function CodeExchangeConfirmPage:_ShowRewardCode(itemId)
  local itemInfo = configManager.GetDataById("config_item_info", itemId)
  UIHelper.SetImage(self.tab_Widgets.im_icon_r, itemInfo.icon)
  UIHelper.SetImage(self.tab_Widgets.im_quality_r, QualityIcon[itemInfo.quality])
  UIHelper.SetText(self.tab_Widgets.tx_getnum_r, 1)
  local BagNum = Logic.bagLogic:GetBagItemNum(itemId)
  UIHelper.SetText(self.tab_Widgets.tx_curnum_r, BagNum)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_icon_r, function()
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(math.floor(itemId / 10000), itemId))
  end)
end

function CodeExchangeConfirmPage:_ShowItemX(itemId)
  self.tab_Widgets.item_x.gameObject:SetActive(itemId ~= WhiteGay)
  if itemId ~= WhiteGay then
    local itemInfo = configManager.GetDataById("config_item_info", itemId)
    UIHelper.SetImage(self.tab_Widgets.im_icon_x, itemInfo.icon)
    UIHelper.SetImage(self.tab_Widgets.im_quality_x, QualityIcon[itemInfo.quality])
    UIHelper.SetText(self.tab_Widgets.tx_neednum_x, 1)
    local BagNum = Logic.bagLogic:GetBagItemNum(itemId)
    UIHelper.SetText(self.tab_Widgets.tx_curnum_x, BagNum)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_icon_x, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(math.floor(itemId / 10000), itemId))
    end)
  else
    self.tab_Widgets.im_plus.gameObject:SetActive(false)
  end
end

function CodeExchangeConfirmPage:_ShowItemY(itemId)
  self.tab_Widgets.item_y.gameObject:SetActive(itemId ~= WhiteGay)
  if itemId ~= WhiteGay then
    local itemInfo = configManager.GetDataById("config_item_info", itemId)
    UIHelper.SetImage(self.tab_Widgets.im_icon_y, itemInfo.icon)
    UIHelper.SetImage(self.tab_Widgets.im_quality_y, QualityIcon[itemInfo.quality])
    UIHelper.SetText(self.tab_Widgets.tx_neednum_y, 1)
    local BagNum = Logic.bagLogic:GetBagItemNum(itemId)
    UIHelper.SetText(self.tab_Widgets.tx_curnum_y, BagNum)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_icon_y, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(math.floor(itemId / 10000), itemId))
    end)
  else
    self.tab_Widgets.im_plus.gameObject:SetActive(false)
  end
end

function CodeExchangeConfirmPage:_ShowReward(itemId)
  local rewardConfig = configManager.GetDataById("config_rewards", itemId)
  local data = rewardConfig.rewards[1]
  local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
  UIHelper.SetImage(self.tab_Widgets.im_icon_r, itemInfo.icon)
  UIHelper.SetImage(self.tab_Widgets.im_quality_r, QualityIcon[itemInfo.quality])
  UIHelper.SetText(self.tab_Widgets.tx_getnum_r, data[3])
  local datax = {
    type = data[1],
    id = data[2]
  }
  local _, value = Logic.itemLogic:GetItemOwnCount(datax)
  UIHelper.SetText(self.tab_Widgets.tx_curnum_r, value)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_icon_r, function()
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(data[1], data[2]))
  end)
end

function CodeExchangeConfirmPage:_ShowNumberAndButton()
  local widgets = self.tab_Widgets
  UIHelper.SetText(widgets.txt_buynum, self.num)
  local canChange, maxChange = self:__GetCanExgUnique()
  widgets.Gray_confirm.Gray = not canChange
end

function CodeExchangeConfirmPage:_ClickClose()
  UIHelper.ClosePage("CodeExchangeConfirmPage")
end

function CodeExchangeConfirmPage:_ClickConfirm()
  local configData = configManager.GetDataById("config_activity", self.mActivityId)
  local isInPeriod = configData.period > 0 and PeriodManager:IsInPeriodArea(configData.period, configData.period_area)
  if not isInPeriod then
    noticeManager:OpenTipPage(self, 330001)
    return
  end
  local canChange, maxChange = self:__GetCanExgUnique()
  if not canChange then
    noticeManager:OpenTipPage(self, 810020002)
    return
  end
  if self.pageType == codeExgType.Reward then
    local tab = {
      RewardId = self.exgid,
      Number = self.num
    }
    Service.activityCodeExchangeService:SendExchangeReward(tab, {
      id = self.exgid,
      num = self.num
    })
  elseif self.pageType == codeExgType.Code then
    local tab = {
      CodeTeamId = self.teamId,
      Number = self.num
    }
    Service.activityCodeExchangeService:SendExchangeCode(tab, {
      Type = math.floor(self.team[2] / 10000),
      ConfigId = self.team[2],
      Num = self.num
    })
  end
  self:_ClickClose()
end

function CodeExchangeConfirmPage:_ClickSubBuyNum(subNum, data)
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
  self:_ShowNumberAndButton()
end

function CodeExchangeConfirmPage:_ClickAddBuyNum(addNum, data)
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
  self:_ShowNumberAndButton()
end

function CodeExchangeConfirmPage:_ClickAddMax(addNum, data)
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
  self:_ShowNumberAndButton()
end

function CodeExchangeConfirmPage:__GetCanExgUnique()
  local canChange = false
  local maxNum = 1
  if self.pageType == codeExgType.Reward then
    canChange, maxNum = Logic.activityCodeExchangeLogic:GetCanExg(self.mActivityId, self.exgid)
  else
    canChange, maxNum = Logic.activityCodeExchangeLogic:GetCanExgCode(self.team)
  end
  return canChange, maxNum
end

function CodeExchangeConfirmPage:DoOnClose()
end

return CodeExchangeConfirmPage
