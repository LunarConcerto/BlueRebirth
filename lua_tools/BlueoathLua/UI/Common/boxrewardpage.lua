local BoxRewardPage = class("UI.Common.BoxRewardPage", LuaUIPage)

function BoxRewardPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function BoxRewardPage:DoOnOpen()
  if self.param == nil then
    logError("self.param is nil")
    return
  end
  local widgets = self:GetWidgets()
  widgets.btn_confirm.gameObject:SetActive(self.param.rewardState == RewardState.UnReceivable)
  widgets.obj_recieved:SetActive(self.param.rewardState == RewardState.Received)
  widgets.btn_get.gameObject:SetActive(self.param.rewardState == RewardState.Receivable)
  local rewards = self.param.rewards
  local len = #rewards
  UIHelper.CreateSubPart(widgets.obj, widgets.content, len, function(index, tabPart)
    local reward = rewards[index]
    UIHelper.ShowReward(reward, tabPart.tx_num, tabPart.im_icon, tabPart.im_quality, tabPart.tx_name)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward, self.btn_item, self, reward)
  end)
end

function BoxRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_confirm, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_mask, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_get, self.btn_get, self)
  self:RegisterEvent(LuaEvent.FetchRewardBox, self._OnGetReward, self)
end

function BoxRewardPage:_OnGetReward(args)
  if args then
    Logic.rewardLogic:ShowCommonReward(args.Reward, "BoxRewardPage")
  end
  UIHelper.ClosePage("BoxRewardPage")
end

function BoxRewardPage:btn_get()
  if self.param.callback then
    self.param.callback()
  end
end

function BoxRewardPage:btn_close()
  UIHelper.ClosePage("BoxRewardPage")
end

function BoxRewardPage:btn_item(go, reward)
  local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId))
end

return BoxRewardPage
