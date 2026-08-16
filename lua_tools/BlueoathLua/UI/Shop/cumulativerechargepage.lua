local CumulativeRechargePage = class("UI.Shop.CumulativeRechargePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function CumulativeRechargePage:DoInit()
end

function CumulativeRechargePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._OnUpdateTask, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._OnBtnHelp, self)
end

function CumulativeRechargePage:DoOnOpen()
  local rechargeCount = Data.rechargeData:GetActivityAccRechargeRmb()
  UIHelper.SetText(self.tab_Widgets.txt_recharge, UIHelper.GetString(430012))
  UIHelper.SetText(self.tab_Widgets.txt_recharge_count, rechargeCount)
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.CumuRecharge)
  if self.activityId ~= nil and activityId == nil then
    return
  end
  if self.activityId == nil and activityId == nil then
    logError("========No CumuRechare Activity, Check Config========")
    return
  end
  self.activityId = activityId
  self:SetOpenTime()
  self:CheckDirty()
  if not self.dirty then
    self:_RefreshList()
  end
  self:WriteOpenedFlag()
end

function CumulativeRechargePage:SetOpenTime()
  self.dirty = false
  local activityCfg = configManager.GetDataById("config_activity", self.activityId)
  for i, pid in ipairs(activityCfg.period_list) do
    if PeriodManager:IsInPeriod(pid) then
      local startTime, endTime = PeriodManager:GetPeriodTime(pid)
      local startTimeFormat = time.formatTimerToMDH(startTime)
      local endTimeFormat = time.formatTimerToMDH(endTime)
      UIHelper.SetLocText(self.tab_Widgets.txt_time, 430017, startTimeFormat, endTimeFormat)
      if self.startTime ~= nil and startTime ~= self.startTime then
        self.dirty = true
      end
      self.startTime = startTime
      self.endTime = endTime
      break
    end
  end
end

function CumulativeRechargePage:CheckDirty()
  if self.dirty then
    Service.taskService:SendTaskInfo()
  end
end

function CumulativeRechargePage:WriteOpenedFlag()
  local userId = Data.userData:GetUserUid()
  PlayerPrefs.SetString("crch", string.format("crch%s%s", userId, self.startTime))
  eventManager:SendEvent(LuaEvent.UpdataTaskList)
end

function CumulativeRechargePage:_OnUpdateTask()
  self:_RefreshList()
  self.dirty = false
end

function CumulativeRechargePage:_RefreshList()
  local listDatas = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  listDatas = self:Filter(listDatas)
  self:Sort(listDatas)
  local count = #listDatas
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_list, count, function(lIndex, tabPart)
    local data = listDatas[lIndex]
    local config = data.Config
    local status = data.Status
    UIHelper.SetText(tabPart.txt_recharge, UIHelper.GetString(430011))
    UIHelper.SetText(tabPart.txt_recharge_count, config.goal[#config.goal])
    tabPart.btn_receive.gameObject:SetActive(status == TaskState.FINISH)
    tabPart.obj_get:SetActive(status == TaskState.RECEIVED)
    tabPart.obj_unfinish.gameObject:SetActive(status == TaskState.TODO)
    UIHelper.SetText(tabPart.txt_unfinish, UIHelper.GetString(430013))
    if status == TaskState.FINISH then
      UGUIEventListener.AddButtonOnClick(tabPart.btn_receive, self._GetReward, self, data)
    end
    local rewards = Logic.rewardLogic:FormatRewardById(config.rewards)
    if config.show_reward_num ~= -1 then
      local first = rewards[config.show_reward_num]
      local firstPart = tabPart.obj_first:GetLuaTableParts()
      local firstDisplay = ItemInfoPage.GenDisplayData(first.Type, first.ConfigId)
      UIHelper.SetImage(firstPart.im_icon, firstDisplay.icon)
      UIHelper.SetImage(firstPart.im_frame, QualityIcon[firstDisplay.quality])
      UIHelper.SetText(firstPart.tx_num, "x" .. tostring(first.Num))
      UIHelper.SetText(firstPart.tx_name, firstDisplay.name)
      UGUIEventListener.AddButtonOnClick(firstPart.btn_icon, function()
        UIHelper.OpenPage("ItemInfoPage", firstDisplay)
      end)
    else
      local firstPart = tabPart.obj_first:GetLuaTableParts()
      firstPart.gameObject:SetActive(false)
    end
    local others = {}
    for i, v in ipairs(rewards) do
      if config.show_reward_num == -1 or config.show_reward_num ~= i then
        table.insert(others, v)
      end
    end
    UIHelper.CreateSubPart(tabPart.obj_reward, tabPart.list_rewards, #others, function(rIndex, rewardPart)
      local reward = others[rIndex]
      local display = ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId)
      UIHelper.SetImage(rewardPart.img_icon, display.icon)
      UIHelper.SetImage(rewardPart.img_quality, QualityIcon[display.quality])
      UIHelper.SetText(rewardPart.txt_num, "x" .. tostring(reward.Num))
      UGUIEventListener.AddButtonOnClick(rewardPart.btn_reward, function()
        UIHelper.OpenPage("ItemInfoPage", display)
      end)
    end)
  end)
end

function CumulativeRechargePage:Filter(datas)
  local result = {}
  local startTime = self.startTime
  local endTime = self.endTime
  for i, data in ipairs(datas) do
    local inPeriod = PeriodManager:IsInPeriodArea(data.Config.period, data.Config.period_area)
    if inPeriod then
      local rewardTime = data.Data.RewardTime
      if rewardTime == 0 or startTime <= rewardTime and endTime >= rewardTime then
        table.insert(result, data)
      end
    end
  end
  return result
end

function CumulativeRechargePage:Sort(datas)
  for i, data in ipairs(datas) do
    data.Status = data.Data.FinishTime == 0 and TaskState.TODO or data.Data.RewardTime == 0 and TaskState.FINISH or TaskState.RECEIVED
  end
  table.sort(datas, function(l, r)
    if l.Status == r.Status then
      return l.Config.id < r.Config.id
    else
      return l.Status < r.Status
    end
  end)
end

function CumulativeRechargePage:_GetReward(btn, data)
  local isOpen = false
  if not self.activityId then
    noticeManager:ShowTip(UIHelper.GetString(430018))
    return
  end
  local activityCfg = configManager.GetDataById("config_activity", self.activityId)
  for i, pid in ipairs(activityCfg.period_list) do
    if PeriodManager:IsInPeriod(pid) then
      isOpen = true
      break
    end
  end
  if isOpen then
    Service.taskService:SendTaskReward(data.Config.id, TaskType.Activity)
  else
    noticeManager:ShowTip(UIHelper.GetString(430018))
  end
end

function CumulativeRechargePage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "CumulativeRechargePage")
  self:_RefreshList()
end

function CumulativeRechargePage:_OnBtnHelp()
  UIHelper.OpenPage("HelpPage", {content = 430016})
end

function CumulativeRechargePage:DoOnHide()
end

function CumulativeRechargePage:DoOnClose()
end

return CumulativeRechargePage
