local ActivityNewYearPage = class("UI.Activity.ActivityNewYearPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local DayNumImage = {
  "uipic_ui_activitynewyearpage_fo_1",
  "uipic_ui_activitynewyearpage_fo_2",
  "uipic_ui_activitynewyearpage_fo_3",
  "uipic_ui_activitynewyearpage_fo_4",
  "uipic_ui_activitynewyearpage_fo_5",
  "uipic_ui_activitynewyearpage_fo_6",
  "uipic_ui_activitynewyearpage_fo_7"
}

function ActivityNewYearPage:DoInit()
  self.activityId = 0
  self.actConfig = 0
  self.selectIndex = 0
  self.selectPart = nil
  self.tabParts = {}
end

function ActivityNewYearPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self._ShowEffect, self)
end

function ActivityNewYearPage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.activityId)
  self:ShowActTime()
  self:CreateSignItem()
end

function ActivityNewYearPage:ShowActTime()
  local startTime, endTime = PeriodManager:GetPeriodTime(self.actConfig.period, self.actConfig.period_area)
  startTime = time.formatTimeToMDHM(startTime)
  endTime = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_time, startTime .. " - " .. endTime)
end

function ActivityNewYearPage:CreateSignItem()
  local arrTaskId = self.actConfig.p4
  local arrTask = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_content, #arrTaskId, function(index, tabPart)
    local taskInfo = arrTask[index]
    local taskId = arrTaskId[index]
    local rewardTime = 0
    local taskType = 0
    local status = TaskState.TODO
    if taskInfo == nil then
      local configTask = Logic.taskLogic:GetBigActivityConfigById(taskId)
      taskInfo = {}
      taskInfo.TaskId = taskId
      taskInfo.Config = configTask
      taskType = configTask.goal[0]
    else
      local taskData = taskInfo.Data
      taskType = taskData.Type
      rewardTime = taskData.RewardTime
      status = Logic.taskLogic:GetTaskFinishState(taskId, taskType)
    end
    tabPart.obj_complete:SetActive(status == TaskState.RECEIVED)
    self:ShowDayNum(tabPart, index)
    local sameTime = time.isSameDay(rewardTime, time.getSvrTime())
    if status == TaskState.FINISH or self.selectIndex == index or sameTime then
      self.selectPart = tabPart
      self:ClickSign({
        status,
        taskInfo,
        tabPart
      })
    end
    if index == #arrTask and self.selectPart == nil then
      self.selectPart = tabPart
      self:ClickSign({
        status,
        taskInfo,
        tabPart
      })
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_select, function()
      self:ClickSign({
        status,
        taskInfo,
        tabPart,
        index
      })
      self:OnClickSign({
        status,
        taskInfo,
        tabPart,
        index
      })
    end)
    local dropAloneTab = configManager.GetDataById("config_drop_item", taskInfo.Config.drop_id).drop_alone
    if #dropAloneTab ~= 0 then
      local reward = dropAloneTab[1]
      tabPart.tx_num.text = "x" .. reward[3]
      local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
      UIHelper.SetImage(tabPart.im_item, QualityIcon[rewardInfo.quality])
      UIHelper.SetImage(tabPart.im_icon, tostring(rewardInfo.icon))
      if status == TaskState.RECEIVED or status == TaskState.TODO then
        local rewardInfo = {}
        rewardInfo.Type = reward[1]
        rewardInfo.ConfigId = reward[2]
        UGUIEventListener.AddButtonOnClick(tabPart.btn_select, self._ClickItem, self, rewardInfo)
      end
    end
    table.insert(self.tabParts, tabPart)
  end)
end

function ActivityNewYearPage:ShowDayNum(part, index)
  UIHelper.SetImage(part.img_dayNum, DayNumImage[index])
end

function ActivityNewYearPage:OnClickSign(param)
end

function ActivityNewYearPage:ClickSign(param)
  local activityConfig = configManager.GetDataById("config_activity", self.activityId)
  if activityConfig.period > 0 and not PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  local status = param[1]
  local taskInfo = param[2]
  local tabPart = param[3]
  self.selectIndex = param[4]
  if self.selectPart then
    self.selectPart.obj_sign:SetActive(false)
  end
  tabPart.obj_sign:SetActive(true)
  self.selectPart = tabPart
  self.tab_Widgets.trans_drop.gameObject:SetActive(status ~= TaskState.RECEIVED)
  self.tab_Widgets.obj_box:SetActive(status ~= TaskState.RECEIVED)
  self.tab_Widgets.obj_click:SetActive(status == TaskState.RECEIVED)
  self.tab_Widgets.obj_minus:SetActive(status == TaskState.FINISH)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_box, function()
    self:_ClickGet(taskInfo, status)
  end)
  local dropTab = configManager.GetDataById("config_drop_item", taskInfo.Config.drop_id).drop
  if status == TaskState.TODO or status == TaskState.FINISH then
    self:ShowDropList(dropTab)
  elseif status == TaskState.RECEIVED then
    self:CreateGotRewards(taskInfo, dropTab)
  end
end

function ActivityNewYearPage:ShowDropList(dropTab)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_dropItem, self.tab_Widgets.trans_drop, #dropTab, function(index, tabPart)
    UIHelper.SetLocText(tabPart.tx_luck, self.actConfig.p3[index])
    local rewards = Logic.rewardLogic:GetAllShowRewardByDropId(dropTab[index][2])
    self:CreateRewardsList(rewards, tabPart.obj_rewardsItem, tabPart.trans_rewards)
  end)
end

function ActivityNewYearPage:CreateRewardsList(rewards, objItem, transItem)
  UIHelper.CreateSubPart(objItem, transItem, #rewards, function(index, tabPart)
    local reward = rewards[index]
    tabPart.tx_num.text = "x" .. reward.Num
    local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward.Type, reward.ConfigId)
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[rewardInfo.quality])
    UIHelper.SetImage(tabPart.img_icon, tostring(rewardInfo.icon))
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward, self._ClickItem, self, reward)
  end)
end

function ActivityNewYearPage:CreateGotRewards(taskInfo, dropTab)
  local index = Logic.activityLogic:GetRewardsIndex(taskInfo.Data.Reward, dropTab)
  UIHelper.SetImage(self.tab_Widgets.img_gotBg, self.actConfig.p2[index])
  self:CreateRewardsList(taskInfo.Data.Reward, self.tab_Widgets.obj_gotRewardItem, self.tab_Widgets.trans_gotReward)
end

function ActivityNewYearPage:_ClickItem(go, reward)
  local typ = reward.Type
  local id = reward.ConfigId
  Logic.itemLogic:ShowItemInfo(typ, id)
end

function ActivityNewYearPage:_ShowEffect(args)
  local showEffect = #self.actConfig.p6 == 0
  if showEffect then
    self.tab_Widgets.obj_eff:SetActive(true)
    local m_timer = self:CreateTimer(function()
      self:_OnGetReward(args)
    end, 2, 1, false)
    self:StartTimer(m_timer)
  else
    self:_OnGetReward(args)
  end
end

function ActivityNewYearPage:_OnGetReward(args)
  self.tab_Widgets.obj_eff:SetActive(false)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "ActivityNewYearPage")
  self:CreateSignItem()
end

function ActivityNewYearPage:_ClickGet(taskInfo, status)
  local activityConfig = configManager.GetDataById("config_activity", self.activityId)
  if activityConfig.period > 0 and not PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  if status == TaskState.FINISH then
    Service.taskService:SendTaskReward(taskInfo.TaskId, TaskType.Activity)
  else
    noticeManager:ShowTipById(1300051)
  end
end

function ActivityNewYearPage:DoOnClose()
end

function ActivityNewYearPage:DoOnHide()
  if self.selectPart then
    self.selectPart.obj_sign:SetActive(false)
  end
  self.selectIndex = 0
  self.selectPart = nil
end

return ActivityNewYearPage
