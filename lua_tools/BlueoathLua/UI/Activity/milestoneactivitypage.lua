local MilestoneActivityPage = class("UI.Activity.MilestoneActivityPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function MilestoneActivityPage:DoInit()
  self.openActivityData = {}
  self.activityId = nil
end

function MilestoneActivityPage:DoOnOpen()
  local params = self:GetParam()
  local activityId = params.activityId
  self.activityId = activityId
  self:_LoadItemInfo()
  self:_LoadPointInfo()
  self:_ShowActivityDes()
end

function MilestoneActivityPage:_ShowActivityDes()
  local configData = configManager.GetDataById("config_activity", self.activityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(configData.period, configData.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_time, startTimeFormat .. " - " .. endTimeFormat)
end

function MilestoneActivityPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._LoadItemInfo, self)
  self:RegisterEvent(LuaEvent.GetMilestoneMsg, self._OnMilestone, self)
  self:RegisterEvent(LuaEvent.MilestoneFetchReward, self._OnMilestoneReward, self)
end

function MilestoneActivityPage:_OnMilestone()
  self:_LoadPointInfo()
end

function MilestoneActivityPage:_OnMilestoneReward(args)
  local configData = configManager.GetDataById("config_activity", self.activityId)
  local rewardInfo = configData.p4
  local rewardSub = rewardInfo[args.Index]
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = Logic.rewardLogic:FormatRewardById(rewardSub[2])
  })
  self:_LoadPointInfo()
end

function MilestoneActivityPage:_OnGetReward(args)
  local taskInfo = Logic.taskLogic:GetTaskConfig(args.TaskId, args.TaskType)
  if taskInfo then
    self:_ShowTips({
      rewards = args.Rewards,
      config = taskInfo
    })
    self:_LoadItemInfo()
    self:_LoadPointInfo()
  end
end

function MilestoneActivityPage:_ShowTips(taskInfo)
  eventManager:SendEvent(LuaEvent.ShowRewardTaskEffect, taskInfo)
end

function MilestoneActivityPage:_LoadItemInfo()
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  if tabTaskInfo == nil then
    logError("MilestoneActivityPage _LoadItemInfo tabTaskInfo is nil")
    return
  end
  local sortTaskInfo = Logic.taskLogic:GetSortTaskListByType(tabTaskInfo)
  UIHelper.CreateSubPart(self.tab_Widgets.item, self.tab_Widgets.Content, #sortTaskInfo, function(index, tabPart)
    local isCanOpenTask = Logic.taskLogic:GetCanOpenTask(sortTaskInfo, sortTaskInfo[index])
    tabPart.item:SetActive(isCanOpenTask)
    UIHelper.SetText(tabPart.tx_des, sortTaskInfo[index].Config.desc)
    local max = string.split(sortTaskInfo[index].ProgressStr, "/")
    UIHelper.SetText(tabPart.tx_num, "" .. max[1] .. "/" .. max[2])
    if sortTaskInfo[index].Data.RewardTime ~= 0 then
      UIHelper.SetText(tabPart.tx_num, "" .. max[2] .. "/" .. max[2])
    end
    tabPart.sliderProgress.value = sortTaskInfo[index].Progress
    tabPart.obj_get:SetActive(sortTaskInfo[index].Data.RewardTime ~= 0)
    tabPart.btn_go.gameObject:SetActive(sortTaskInfo[index].State == TaskState.TODO and 0 < sortTaskInfo[index].Config.go_up_to)
    tabPart.btn_fetch.gameObject:SetActive(sortTaskInfo[index].State == TaskState.FINISH)
    tabPart.tx_num.gameObject:SetActive(sortTaskInfo[index].Data.RewardTime == 0)
    local rewards = Logic.rewardLogic:FormatRewardById(sortTaskInfo[index].Config.rewards)
    UIHelper.CreateSubPart(tabPart.item, tabPart.rewards, #rewards, function(nIndex, luaPart)
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      local tabReward = ItemInfoPage.GenDisplayData(rewards[nIndex].Type, rewards[nIndex].ConfigId)
      UIHelper.SetImage(luaPart.im_icon, tabReward.icon)
      UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(luaPart.tx_rewardNum, rewards[nIndex].Num)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_icon, self._ShowItemInfo, self, rewards[nIndex])
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_go, self.btn_go, self, sortTaskInfo[index])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_fetch, self.btn_fetch, self, sortTaskInfo[index])
  end)
end

function MilestoneActivityPage:_LoadPointInfo()
  local configData = configManager.GetDataById("config_activity", self.activityId)
  local rewardInfo = configData.p4
  local pointHave = Logic.bagLogic:GetConsumeCurrNum(configData.p1[1], configData.p1[2])
  local pointMax = rewardInfo[#rewardInfo][1]
  self.tab_Widgets.slider.value = pointHave / pointMax
  UIHelper.SetText(self.tab_Widgets.tx_point_value, pointHave)
  UIHelper.CreateSubPart(self.tab_Widgets.item_point, self.tab_Widgets.content_point, #rewardInfo, function(index, tabPart)
    local rewardTime = Data.milestoneData:GetTimeById(self.activityId, index)
    local rewardSub = rewardInfo[index]
    local point = rewardSub[1]
    UIHelper.SetText(tabPart.tx_num, point)
    tabPart.btn_reward_show.gameObject:SetActive(rewardTime <= 0 and point > pointHave)
    tabPart.btn_reward_fetch.gameObject:SetActive(rewardTime <= 0 and point <= pointHave)
    tabPart.btn_reward_fetched:SetActive(0 < rewardTime)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward_fetch, function()
      if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
        noticeManager:ShowTipById(270022)
        return
      end
      Service.milestoneService:SendMilestoneFetchReward({
        ActivityId = self.activityId,
        Index = index
      })
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward_show, function()
      local rewards = Logic.rewardLogic:FormatRewards({
        rewardSub[2]
      })
      UIHelper.OpenPage("BoxRewardPage", {
        rewardState = RewardState.UnReceivable,
        rewards = rewards
      })
    end)
  end)
end

function MilestoneActivityPage:btn_go(go, args)
  if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  moduleManager:JumpToFunc(args.Config.go_up_to, table.unpack(args.Config.go_up_to_parm))
end

function MilestoneActivityPage:btn_fetch(go, args)
  if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
end

function MilestoneActivityPage:_ShowItemInfo(go, award)
  Logic.itemLogic:ShowItemInfo(award.Type, award.ConfigId)
end

return MilestoneActivityPage
