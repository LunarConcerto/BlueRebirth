local ValentineSalePage = class("UI.Activity.Valentine.ValentineSalePage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local TaskOperate = require("ui.page.task.TaskOperate")

function ValentineSalePage:DoInit()
  self.activityId = 0
  self.actConfig = 0
  self.grade = 0
  self.gotRewardTime = 0
end

function ValentineSalePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_get, self.ClickGetDiscount, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self.ClickHelp, self)
  self:RegisterEvent(LuaEvent.ActivityValentineReward, self._GetDiscountOk, self)
end

function ValentineSalePage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.activityId)
  self.gotRewardTime = Data.activityValentineData:GetGotValentineRewardTime()
  self:ShowActTime()
  self:ShowTask()
  self:ShowProgress()
  self:ShowExtraReward()
  local uid = Data.userData:GetUserUid()
  PlayerPrefs.SetInt(PlayerPrefsKey.OpenValentineSale .. uid, time.getSvrTime())
  eventManager:SendEvent(LuaEvent.OpenValentineSale)
end

function ValentineSalePage:ShowActTime()
  local startTime, endTime = PeriodManager:GetPeriodTime(self.actConfig.period, self.actConfig.period_area)
  startTime = time.formatTimeToMDHM(startTime)
  endTime = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_actTime, startTime .. " - " .. endTime)
end

function ValentineSalePage:ShowTask()
  local arrTask = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  if self.gotRewardTime <= 0 then
    arrTask = self:SortTask(arrTask)
  end
  self.tab_Widgets.obj_taskBlock:SetActive(self.gotRewardTime > 0)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_task, self.tab_Widgets.trans_task, #arrTask, function(index, tabPart)
    local taskInfo = arrTask[index]
    local taskData = taskInfo.Data
    local taskConfig = taskInfo.Config
    UIHelper.SetText(tabPart.tx_task, taskConfig.desc)
    local rewards = Logic.rewardLogic:FormatRewardById(taskConfig.rewards)
    tabPart.tx_RewardValue.text = "+" .. rewards[1].Num
    if self.gotRewardTime > 0 and not time.isSameDay(self.gotRewardTime, taskData.RewardTime) then
      UIHelper.DisableButton(tabPart.btn_task, true)
      tabPart.progress.value = 0
      local proStr = "0/" .. taskConfig.goal[#taskConfig.goal]
      UIHelper.SetText(tabPart.tx_rate, proStr)
      tabPart.btn_task.gameObject:SetActive(0 < taskConfig.go_up_to)
      tabPart.obj_get:SetActive(false)
    else
      UIHelper.SetText(tabPart.tx_rate, taskInfo.ProgressStr)
      tabPart.progress.value = taskInfo.Progress
      tabPart.btn_task.gameObject:SetActive(0 < taskConfig.go_up_to and taskInfo.State == TaskState.TODO)
      tabPart.obj_get:SetActive(taskInfo.State == TaskState.RECEIVED)
      if self.gotRewardTime > 0 then
        UIHelper.DisableButton(tabPart.btn_task, true)
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_task, self._TaskBtnCall, self, taskInfo)
    end
  end)
end

function ValentineSalePage:ShowProgress()
  local itemId = self.actConfig.p5[1][2]
  local itemNum = Data.bagData:GetItemNum(itemId)
  self.tab_Widgets.slider_point.value = itemNum / self.actConfig.p5[#self.actConfig.p5][3]
  self.tab_Widgets.tx_pointValue.text = itemNum
  for i, v in ipairs(self.actConfig.p5) do
    if itemNum >= v[3] then
      self.grade = i
    else
      break
    end
  end
  if self.grade == 0 or 0 < self.gotRewardTime then
    self.tab_Widgets.btn_get.gameObject:SetActive(false)
    local str = 0 < self.gotRewardTime and UIHelper.GetString(1300060) or UIHelper.GetString(1300059)
    self.tab_Widgets.tx_getfinish.text = str
  end
end

function ValentineSalePage:ShowExtraReward()
  local rewardTab = self.actConfig.p6
  for i, v in ipairs(rewardTab) do
    local rewards = Logic.rewardLogic:FormatRewardById(v)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets["btn_reward" .. tostring(i)], self._ClickItem, self, rewards)
  end
end

function ValentineSalePage:_ClickItem(go, rewards)
  UIHelper.OpenPage("BoxRewardPage", {
    rewardState = RewardState.UnReceivable,
    rewards = rewards
  })
end

function ValentineSalePage:ClickGetDiscount()
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  if self.grade < #self.actConfig.p5 then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClickGetTrue()
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(1300054), tabParams)
  else
    self:_ClickGetTrue()
  end
end

function ValentineSalePage:_ClickGetTrue()
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  Service.activityValentineService:SendActVanlenReward(self.grade)
end

function ValentineSalePage:_GetDiscountOk(rewards)
  Logic.rewardLogic:ShowCommonReward(rewards, "ValentineSalePage", nil)
  self.tab_Widgets.btn_get.gameObject:SetActive(false)
  self.tab_Widgets.tx_getfinish.text = UIHelper.GetString(1300060)
  self.gotRewardTime = Data.activityValentineData:GetGotValentineRewardTime()
  self:ShowTask()
end

function ValentineSalePage:ClickHelp()
  UIHelper.OpenPage("HelpPage", {content = 1300056})
end

function ValentineSalePage:_ShowItemInfo(go, reward)
  Logic.itemLogic:ShowItemInfo(reward.Type, reward.ConfigId)
end

function ValentineSalePage:_TaskBtnCall(go, args)
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  if args.State == TaskState.TODO then
    TaskOperate.TaskJumpByKind(args.Config.goal[1], args.Config.go_up_to)
  end
end

function ValentineSalePage:SortTask(taskTab)
  table.sort(taskTab, function(data1, data2)
    if data1.Data.FinishTime ~= data2.Data.FinishTime then
      return data1.Data.FinishTime < data2.Data.FinishTime
    else
      return data1.Data.TaskId < data2.Data.TaskId
    end
  end)
  return taskTab
end

function ValentineSalePage:DoOnClose()
end

function ValentineSalePage:DoOnHide()
end

return ValentineSalePage
