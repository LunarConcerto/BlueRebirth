local FirstRechargePage = class("UI.Activity.FirstRechargePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function FirstRechargePage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function FirstRechargePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_recharge, self._Recharge, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_fetch, self._Fetch, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self.ShowButton, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
end

function FirstRechargePage:DoOnOpen()
  local activityConfig = configManager.GetDataById("config_activity", Activity.FirstRecharge)
  self.achieveId = activityConfig.p1[1]
  self:ShowReward()
  self:ShowButton()
end

function FirstRechargePage:ShowButton()
  local widgets = self.m_tabWidgets
  local status = Logic.activityLogic:GetFirstRechargeState()
  widgets.btn_recharge.gameObject:SetActive(status == TaskState.TODO)
  widgets.btn_fetch.gameObject:SetActive(status == TaskState.FINISH)
  widgets.btn_fetched.gameObject:SetActive(status == TaskState.RECEIVED)
end

function FirstRechargePage:ShowReward()
  local widgets = self.m_tabWidgets
  local achieveConfig = configManager.GetDataById("config_achievement", self.achieveId)
  local rewardId = achieveConfig.rewards
  local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
  local num = #rewards
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, num, function(index, tabPart)
    local rewardInfo = rewards[index]
    local displayInfo = Logic.goodsLogic.AnalyGoods(rewardInfo)
    UIHelper.SetImage(tabPart.imgIcon, displayInfo.texIcon)
    UIHelper.SetImage(tabPart.imgBg, QualityIcon[displayInfo.quality])
    tabPart.textName.text = displayInfo.name
    tabPart.textNum.text = rewardInfo.Num
    UGUIEventListener.AddButtonOnClick(tabPart.button, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(rewardInfo.Type, rewardInfo.ConfigId))
    end)
  end)
end

function FirstRechargePage:DoOnClose()
  Logic.activityLogic:SetFirstRecharge(true)
end

function FirstRechargePage:DoOnHide()
end

function FirstRechargePage:_Recharge()
  if platformManager:useSDK() then
    Logic.shopLogic:OpenRechargeShop()
  end
end

function FirstRechargePage:_Fetch()
  Service.taskService:SendTaskReward(self.achieveId, TaskType.Achieve)
end

function FirstRechargePage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "FirstRechargePage")
end

return FirstRechargePage
