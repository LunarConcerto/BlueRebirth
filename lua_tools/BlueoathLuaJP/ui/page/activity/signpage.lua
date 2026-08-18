local SignPage = class("UI.Activity.SignPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local CommonRewardItem = require("ui.page.CommonItem")

function SignPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_curReward = nil
end

function SignPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.SignFinished, self._SignSuccessTip, self)
end

function SignPage:DoOnOpen()
  self:_ShowItem()
  local isSign = Logic.activityLogic:IsSignToday()
  if not isSign then
    Service.activityService:SendSign()
  end
  local dotinfo = {info = "sign_in"}
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function SignPage:_SignSuccessTip(rewards)
  Logic.rewardLogic:ShowCommonReward(rewards, "SignPage", nil)
  local dotinfo = {
    info = "sign_in_gift",
    itemID = rewards[1].ConfigId
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  self:_ShowItem()
end

function SignPage:_ShowItemDetail(go, reward)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId))
end

function SignPage:_ShowItem()
  local widgets = self.m_tabWidgets
  local month, dayAmount = time.GetCurMonthAndDays()
  local monthConfig = Logic.activityLogic:GetSignConfigByMonth(month)
  monthConfig = Logic.rewardLogic:FormatRewardByIds(monthConfig)
  local signDays = Mathf.ToInt(Data.activityData:GetSignCount())
  UIHelper.SetText(widgets.tx_num, signDays)
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, dayAmount, function(index, tabPart)
    local reward = monthConfig[index][1]
    local item = CommonRewardItem:new()
    item:Init(index, reward, tabPart)
    tabPart.obj_get:SetActive(index <= signDays)
    UGUIEventListener.AddButtonOnClick(tabPart.im_frame, self._ShowItemDetail, self, reward)
  end)
end

function SignPage:DoOnClose()
end

function SignPage:DoOnHide()
end

return SignPage
