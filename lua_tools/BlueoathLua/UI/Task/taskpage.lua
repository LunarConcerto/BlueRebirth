local TaskPage = class("UI.Task.TaskPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TaskOperate = require("ui.page.task.TaskOperate")
local AwardShowNum = 3
local taskTagMap = {
  [TaskType.Daily] = UIHelper.GetString(340012),
  [TaskType.Main] = UIHelper.GetString(340013),
  [TaskType.Week] = UIHelper.GetString(340014),
  [TaskType.Grow] = UIHelper.GetString(340018)
}
local taskTagImageMap = {
  [TaskType.Daily] = "uipic_ui_task_im_richang",
  [TaskType.Main] = "uipic_ui_task_im_zhuxian",
  [TaskType.Week] = "uipic_ui_task_im_zhouchang",
  [TaskType.Grow] = "uipic_ui_task_im_chengzhang"
}
local taskStageMap = {
  [TaskState.TODO] = UIHelper.GetString(340015),
  [TaskState.FINISH] = UIHelper.GetString(330007)
}
local taskStageFillMap = {
  [TaskState.TODO] = Color.New(0.4, 0.6039215686274509, 1.0, 255),
  [TaskState.FINISH] = Color.New(0.00784313725490196, 0.8627450980392157, 0.08627450980392157, 255)
}
local taskTypeOutline = {
  [TaskType.Daily] = {
    0.42745098039215684,
    0.09019607843137255,
    0.7254901960784313,
    1
  },
  [TaskType.Main] = {
    0.7568627450980392,
    0.054901960784313725,
    0.054901960784313725,
    1
  },
  [TaskType.Week] = {
    0.2235294117647059,
    0.6666666666666666,
    0.9725490196078431,
    1
  },
  [TaskType.Grow] = {
    0.792156862745098,
    0.3803921568627451,
    0.1568627450980392,
    1
  }
}

function TaskPage:DoInit()
  self.m_tabWidgets = nil
  self.m_fastGetLock = false
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self:_RegisterToggleGroup()
  self:_RegisterTween()
end

function TaskPage:_RegisterTween()
  local widgets = self:GetWidgets()
  self.tabTagTwns = {
    widgets.twn_task,
    widgets.twn_achieve
  }
end

function TaskPage:DoOnOpen()
  self:OpenTopPage("TaskPage", 1, "\228\187\187\229\138\161", self, true, function()
    UIHelper.Back()
  end)
  local curTog = Logic.taskLogic:GetModuleIndex()
  self.m_tabWidgets.leftGroup:SetActiveToggleIndex(curTog)
  UIHelper.OpenPage("RewardTipPage")
end

function TaskPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UIHelper.AddToggleGroupChangeValueEvent(widgets.leftGroup, self, nil, self._Switchleft)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.taskGroup, self, nil, self._SwithcTaskType)
  UGUIEventListener.AddButtonOnClick(widgets.btn_fastGet, self._GetAllReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._ShowTaskModule, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.GetAllTaskReward, self._OnGetAllReward, self)
  self:RegisterRedDot(widgets.redflag_task_all, TaskType.All)
  self:RegisterRedDot(widgets.redflag_task_daily, TaskType.Daily)
  self:RegisterRedDot(widgets.redflag_task_line, TaskType.Main)
  self:RegisterRedDot(widgets.redflag_task_week, TaskType.Week)
  self:RegisterRedDot(widgets.redflag_task_grow, TaskType.Grow)
end

function TaskPage:_Switchleft(index)
  Logic.taskLogic:SetModuleIndex(index)
  self:_ShowModule(index)
  self:_PlayTagTwn(index)
end

function TaskPage:_PlayTagTwn(index)
  if self.tabTagTwns == nil then
    return
  end
  for k, v in pairs(self.tabTagTwns) do
    if k == index + 1 then
      v:Play(true)
    else
      v:Play(false)
    end
  end
end

function TaskPage:_SwithcTaskType(index)
  self:_RefreshTask(index)
  Logic.taskLogic:SetTaskTagIndex(index)
end

function TaskPage:_ShowModule(moduleType)
  if moduleType == TaskShowModule.Task then
    self:_ShowTaskModule(moduleType)
    eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {TitleName = "\228\187\187\229\138\161"})
    self:CloseSubPage("AchievePage")
    self.m_tabWidgets.obj_main:SetActive(true)
  elseif moduleType == TaskShowModule.Achieve then
    self.m_tabWidgets.btn_fastGet:SetActive(false)
    self.m_tabWidgets.obj_main:SetActive(false)
    eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {TitleName = "\230\136\144\229\176\177"})
    self:OpenSubPage("AchievePage")
  end
end

function TaskPage:_ShowTaskModule(moduleType)
  if Logic.taskLogic:GetModuleIndex() == TaskShowModule.Task then
    local haveReward = Logic.redDotLogic.Task()
    self.m_tabWidgets.btn_fastGet:SetActive(haveReward)
  end
  local taskTag = Logic.taskLogic:GetTaskTagIndex()
  self.m_tabWidgets.taskGroup:SetActiveToggleIndex(taskTag)
  self:_RefreshTask(taskTag)
end

function TaskPage:_RefreshTask(taskType)
  local tabTaskInfo = Logic.taskLogic:GetTaskListByType(taskType)
  if tabTaskInfo == nil then
    return
  end
  local widgets = self:GetWidgets()
  UIHelper.SetInfiniteItemParam(widgets.iil_tasksv, widgets.obj_taskItem, #tabTaskInfo, function(tabPart)
    local luaParts = {}
    for k, v in pairs(tabPart) do
      luaParts[tonumber(k)] = v
    end
    for index, luaPart in pairs(luaParts) do
      local taskInfo = tabTaskInfo[index]
      local taskData = taskInfo.Data
      local taskConfig = taskInfo.Config
      UIHelper.SetImage(luaPart.im_tag, taskTagImageMap[taskData.Type])
      UIHelper.SetText(luaPart.tx_tag, taskTagMap[taskData.Type])
      local color = taskTypeOutline[taskData.Type]
      luaPart.tag_outline.effectColor = Color.New(color[1], color[2], color[3], 1)
      UIHelper.SetText(luaPart.tx_name, taskConfig.title)
      UIHelper.SetText(luaPart.tx_des, taskConfig.desc)
      self:_SetAward(luaPart, taskData.Type, taskConfig)
      UIHelper.SetText(luaPart.tx_rate, taskInfo.ProgressStr)
      luaPart.im_progressFill.color = taskStageFillMap[taskInfo.State]
      luaPart.progress.value = taskInfo.Progress
      luaPart.btn_task.gameObject:SetActive(taskConfig.go_up_to ~= -1)
      luaPart.btn_get.gameObject:SetActive(taskInfo.State == TaskState.FINISH)
      UIHelper.SetText(luaPart.tx_btn, taskStageMap[taskInfo.State])
      UGUIEventListener.AddButtonOnClick(luaPart.btn_task, self._TaskBtnCall, self, taskInfo)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_get, self._TaskBtnCall, self, taskInfo)
    end
  end)
end

function TaskPage:_SetAward(widgets, taskType, taskConfig)
  local taskAward = taskConfig.rewards
  local rewards = Logic.rewardLogic:FormatRewardById(taskAward)
  local idList = {}
  if taskType == TaskType.Daily and #taskConfig.reward_limited_period > 0 and #taskConfig.reward_limited == #taskConfig.reward_limited_period then
    for index, periodId in pairs(taskConfig.reward_limited_period) do
      if PeriodManager:IsInPeriod(periodId) then
        local taskPeriodAward = Logic.rewardLogic:FormatRewardById(taskConfig.reward_limited[index])
        table.insertto(rewards, taskPeriodAward)
        idList[#rewards] = true
      end
    end
  end
  local num = #rewards
  UIHelper.CreateSubPart(widgets.obj_award, widgets.trans_award, num, function(index, tabPart)
    local award = CommonRewardItem:new()
    award:Init(index, rewards[index], tabPart)
    tabPart.im_activitylimited.gameObject:SetActive(idList[index])
    UGUIEventListener.AddButtonOnClick(tabPart.img_frame, self._ShowItemInfo, self, rewards[index])
  end)
end

function TaskPage:_TaskBtnCall(go, args)
  if args.State == TaskState.TODO then
    TaskOperate.TaskJumpByKind(args.Config.goal[1], args.Config.go_up_to)
    local dotinfo = {
      info = "ui_task_go",
      task_type = args.Data.Type,
      task_id = args.TaskId
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  elseif args.State == TaskState.FINISH then
    local ok, msg = Logic.taskLogic:CheckGetReward(args.Data)
    if not ok then
      noticeManager:ShowTip(msg)
      return
    end
    local dotinfo = {
      info = "ui_task_get",
      task_type = args.Data.Type,
      task_id = args.TaskId
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
  end
end

function TaskPage:_ShowItemInfo(go, award)
  if award.Type == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award.ConfigId,
      showEquipType = ShowEquipType.Simple
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
  end
end

function TaskPage:_RegisterToggleGroup()
  local widgets = self:GetWidgets()
  widgets.leftGroup:RegisterToggle(widgets.tog_task)
  widgets.leftGroup:RegisterToggle(widgets.tog_achieve)
  widgets.taskGroup:RegisterToggle(widgets.tog_all)
  widgets.taskGroup:RegisterToggle(widgets.tog_line)
  widgets.taskGroup:RegisterToggle(widgets.tog_daily)
  widgets.taskGroup:RegisterToggle(widgets.tog_week)
  widgets.taskGroup:RegisterToggle(widgets.tog_grow)
end

function TaskPage:_ShowTips(taskInfo)
  eventManager:SendEvent(LuaEvent.ShowRewardTaskEffect, taskInfo)
end

function TaskPage:_OnGetReward(args)
  for _, reward in ipairs(args.Rewards) do
    if reward.Type == GoodsType.EQUIP then
      Logic.equipLogic:DotGetEquip("task_get", reward.ConfigId)
    end
  end
  if args.TaskType > TaskType.TaskEnd then
    return
  end
  local taskInfo = Logic.taskLogic:GetTaskConfig(args.TaskId, args.TaskType)
  if taskInfo then
    self:_ShowTips({
      rewards = args.Rewards,
      config = taskInfo
    })
    self:_ShowTaskModule()
  end
end

function TaskPage:_ShowMedalReplaceReward(rewards)
  local showReplace, showReward = Logic.rewardLogic:MedalReplaceReward(rewards)
  if showReplace and next(showReward) ~= nil then
    UIHelper.OpenPage("GetRewardsPage", {
      Rewards = showReward,
      Desc = "\229\139\139\231\171\160\233\135\141\229\164\141\232\142\183\229\190\151\232\189\172\228\184\186\229\165\150\229\138\177"
    })
  end
end

function TaskPage:_GetAllReward()
  local haveReward = Logic.redDotLogic.Task()
  if not haveReward then
    return
  end
  if self.m_fastGetLock then
    return
  end
  Service.taskService:SendTaskAllReward(TaskAllRewardType.TASK_LIST)
  self.m_fastGetLock = true
end

function TaskPage:_OnGetAllReward(ret)
  self.m_fastGetLock = false
  if ret.Reward == nil then
    return
  end
  for _, reward in ipairs(ret.Reward) do
    if reward.Type == GoodsType.EQUIP then
      Logic.equipLogic:DotGetEquip("task_get", reward.ConfigId)
    end
  end
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = ret.Reward
  })
end

function TaskPage:DoOnHide()
end

function TaskPage:_UnRegisterToggleGroup()
  local widgets = self:GetWidgets()
  widgets.leftGroup:ClearToggles()
  widgets.taskGroup:ClearToggles()
end

function TaskPage:DoOnClose()
  self:_UnRegisterToggleGroup()
  Logic.taskLogic:SetTaskTagIndex(0)
end

return TaskPage
