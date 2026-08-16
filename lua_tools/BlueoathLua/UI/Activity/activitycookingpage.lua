local ActivityCookingPage = class("UI.Activity.ActivityCookingPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ActivityCookingPage:DoInit()
  self.openActivityData = {}
  self.activityId = nil
end

function ActivityCookingPage:DoOnOpen()
  local params = self:GetParam()
  local activityId = params.activityId
  self.activityId = activityId
  self:_LoadItemInfo()
  self:_ShowActivityDes()
end

function ActivityCookingPage:_ShowActivityDes()
  local configData = configManager.GetDataById("config_activity", self.activityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(configData.period, configData.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textTime, startTimeFormat .. "-" .. endTimeFormat)
  local item = configData.p13
  local itemInfo = ItemInfoPage.GenDisplayData(item[1], item[2])
  UIHelper.SetImage(self.tab_Widgets.im_fish, itemInfo.icon)
  local num = Logic.rewardLogic:GetPossessNum(item[1], item[2])
  UIHelper.SetText(self.tab_Widgets.tx_num, num .. "g")
end

function ActivityCookingPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_go, self.btn_go, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._LoadItemInfo, self)
end

function ActivityCookingPage:_OnGetReward(args)
  local taskInfo = Logic.taskLogic:GetTaskConfig(args.TaskId, args.TaskType)
  if taskInfo then
    self:_ShowTips({
      rewards = args.Rewards,
      config = taskInfo
    })
    self:_LoadItemInfo()
  end
end

function ActivityCookingPage:_ShowTips(taskInfo)
  eventManager:SendEvent(LuaEvent.ShowRewardTaskEffect, taskInfo)
end

function ActivityCookingPage:_LoadItemInfo()
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  if tabTaskInfo == nil then
    logError("ActivityCookingPage _LoadItemInfo tabTaskInfo is nil")
    return
  end
  local sortTaskInfo = Logic.taskLogic:GetSortTaskListByType(tabTaskInfo)
  local configData = configManager.GetDataById("config_activity", self.activityId)
  UIHelper.CreateSubPart(self.tab_Widgets.item, self.tab_Widgets.Content, #sortTaskInfo, function(index, tabPart)
    local max = string.split(sortTaskInfo[index].ProgressStr, "/")
    UIHelper.SetText(tabPart.tx_num, max[2] .. "g")
    local item = configData.p13
    local itemInfo = ItemInfoPage.GenDisplayData(item[1], item[2])
    UIHelper.SetImage(tabPart.im_fish, itemInfo.icon)
    tabPart.im_complete.gameObject:SetActive(sortTaskInfo[index].Data.RewardTime ~= 0)
    tabPart.btn_get.gameObject:SetActive(sortTaskInfo[index].State == TaskState.FINISH)
    local rewards = Logic.rewardLogic:FormatRewardById(sortTaskInfo[index].Config.rewards)
    UIHelper.CreateSubPart(tabPart.img_quality, tabPart.Content, #rewards, function(nIndex, luaPart)
      local tabReward = ItemInfoPage.GenDisplayData(rewards[nIndex].Type, rewards[nIndex].ConfigId)
      UIHelper.SetImage(luaPart.img_icon, tabReward.icon)
      UIHelper.SetImage(luaPart.img_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(luaPart.tx_num, rewards[nIndex].Num)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_reward, self._ShowItemInfo, self, rewards[nIndex])
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_get, self.btn_fetch, self, sortTaskInfo[index])
  end)
end

function ActivityCookingPage:btn_fetch(go, args)
  if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
end

function ActivityCookingPage:_ShowItemInfo(go, award)
  Logic.rewardLogic:ShowReward(award.Type, award.ConfigId)
end

function ActivityCookingPage:btn_go(...)
  if not moduleManager:CheckFunc(FunctionID.ActPlotCopy, true) then
    return
  end
  UIHelper.OpenPage("ActivityCopyPage", {
    activityId = self.activityId
  })
end

return ActivityCookingPage
