local CumulativeCostPage = class("UI.Activity.CumulativeCostPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function CumulativeCostPage:DoInit()
end

function CumulativeCostPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.OpenActivityPage, self._OnChange, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
end

function CumulativeCostPage:DoOnOpen()
  local v = Data.rechargeData:GetAccRechargeRmb()
  self.activityId = self:GetParam().activityId
  self:_RefreshList()
end

function CumulativeCostPage:_OnChange(activityId)
  self.activityId = activityId
  self:_RefreshList()
end

function CumulativeCostPage:_RefreshList()
  local activityCfg = configManager.GetDataById("config_activity", self.activityId)
  local widgets = self.tab_Widgets
  UIHelper.SetLocText(widgets.txtTitle, activityCfg.p3[1])
  UIHelper.SetImage(widgets.bg, activityCfg.p5[1])
  UIHelper.SetImage(widgets.bgTitle, activityCfg.p4[1])
  if activityCfg.period > 0 then
    local startTime, endTime = PeriodManager:GetStartAndEndPeriodFirstListTime(activityCfg.period, self.activityId)
    local startTimeFormat = time.formatTimeToMDHM(startTime)
    local endTimeFormat = time.formatTimeToMDHM(endTime)
    UIHelper.SetText(widgets.txtPeriod, string.format("%s - %s", startTimeFormat, endTimeFormat))
  else
    UIHelper.SetLocText(widgets.txtPeriod, 902008)
  end
  local listDatas = Logic.achieveLogic:GetCumuActivityData(self.activityId)
  local count = #listDatas
  UIHelper.CreateSubPart(self.tab_Widgets.listItem, self.tab_Widgets.listContent, count, function(lIndex, tabPart)
    local data = listDatas[lIndex]
    local config = data.config
    UIHelper.SetText(tabPart.count, config.goal[#config.goal])
    UIHelper.SetText(tabPart.progress, data.progressStr)
    UIHelper.SetText(tabPart.txtTarget, UIHelper.GetString(activityCfg.p7[1]))
    tabPart.slider.value = data.progress
    tabPart.btnReceive.gameObject:SetActive(data.status == TaskState.FINISH)
    tabPart.objReceived:SetActive(data.status == TaskState.RECEIVED)
    tabPart.unfinish:SetActive(data.status == TaskState.TODO)
    if data.status == TaskState.FINISH then
      UGUIEventListener.AddButtonOnClick(tabPart.btnReceive, self._GetReward, self, data)
    end
    local rewards = Logic.rewardLogic:FormatRewardById(config.rewards)
    UIHelper.CreateSubPart(tabPart.rewardItem, tabPart.rewardContent, #rewards, function(rIndex, rewardPart)
      local reward = rewards[rIndex]
      local display = ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId)
      UIHelper.SetImage(rewardPart.icon, display.icon)
      UIHelper.SetImage(rewardPart.quality, QualityIcon[display.quality])
      UIHelper.SetText(rewardPart.num, "x" .. tostring(reward.Num))
      UGUIEventListener.AddButtonOnClick(rewardPart.btn, function()
        UIHelper.OpenPage("ItemInfoPage", display)
      end)
    end)
  end)
end

function CumulativeCostPage:_GetReward(btn, data)
  Service.taskService:SendTaskReward(data.config.id, TaskType.Achieve)
end

function CumulativeCostPage:_OnGetReward(args)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = args.Rewards,
    Page = "CumulativeCostPage"
  })
  self:_RefreshList()
end

function CumulativeCostPage:DoOnClose()
end

function CumulativeCostPage:DoOnHide()
end

return CumulativeCostPage
