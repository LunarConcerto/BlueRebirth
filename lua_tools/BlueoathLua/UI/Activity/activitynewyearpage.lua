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
end

function ActivityNewYearPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self._ShowEffect, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_openBook, self._OpenBook, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeBook, self._CloseBook, self)
end

function ActivityNewYearPage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.activityId)
  self:_ShowActTime()
  self:_CreateSignItem()
end

function ActivityNewYearPage:_ShowActTime()
  local startTime, endTime = PeriodManager:GetPeriodTime(self.actConfig.period, self.actConfig.period_area)
  startTime = time.formatTimeToMDHM(startTime)
  endTime = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_time, startTime .. " - " .. endTime)
end

function ActivityNewYearPage:_CreateSignItem()
  local arrTaskId = self.actConfig.p4
  local arrTask = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_content, #arrTaskId, function(index, tabPart)
    local taskInfo = arrTask[index]
    local taskId = arrTaskId[index]
    local rewardTime = 0
    local taskType = 0
    local status = TaskState.TODO
    local randomTextIndex = 0
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
    self:ShowDayNum(tabPart.img_dayNum, index)
    local sameTime = time.isSameDay(rewardTime, time.getSvrTime())
    if status == TaskState.RECEIVED then
      randomTextIndex = self:_ShowRandomText(index)
    end
    if status == TaskState.FINISH or self.selectIndex == index or sameTime then
      self.selectPart = tabPart
      self:ClickSign({
        status,
        taskInfo,
        tabPart,
        nil,
        randomTextIndex
      })
    end
    if index == #arrTask and self.selectPart == nil then
      self.selectPart = tabPart
      self:ClickSign({
        status,
        taskInfo,
        tabPart,
        nil,
        randomTextIndex
      })
    end
    if tabPart.obj_itemBg ~= nil then
      tabPart.obj_itemBg:SetActive(index ~= #arrTaskId)
      tabPart.obj_seventhBg:SetActive(index == #arrTaskId)
      tabPart.obj_day:SetActive(index ~= #arrTaskId)
      tabPart.obj_daySeventh:SetActive(index == #arrTaskId)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_select, function()
      self:ClickSign({
        status,
        taskInfo,
        tabPart,
        index,
        randomTextIndex
      })
    end)
  end)
end

function ActivityNewYearPage:ShowDayNum(img, index)
  UIHelper.SetImage(img, self.actConfig.p6[index])
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
  local randomTextIndex = param[5]
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
  local dropConfig = configManager.GetDataById("config_drop_item", taskInfo.Config.drop_id)
  local dropTab = 0 < dropConfig.drop_alone_count and dropConfig.drop_alone or dropConfig.drop
  self:ShowRewardList(randomTextIndex, dropTab)
  if dropTab[2] == GoodsType.DROP then
    self:ShowDropList(dropTab)
  else
    logError(taskInfo.Config.drop_id)
    local rewards = Logic.rewardLogic:GetAllShowRewardByDropId(taskInfo.Config.drop_id)
    self:CreateRewardsList(rewards, self.tab_Widgets.obj_reward, self.tab_Widgets.trans_reward)
  end
end

function ActivityNewYearPage:ShowDropList(dropTab)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_dropItem, self.tab_Widgets.trans_drop, #dropTab, function(index, tabPart)
    tabPart.tx_luck.gameObject:SetActive(#self.actConfig.p3 > 0)
    if #self.actConfig.p3 > 0 then
      UIHelper.SetLocText(tabPart.tx_luck, self.actConfig.p3[index])
    end
    local rewards = Logic.rewardLogic:GetAllShowRewardByDropId(dropTab[index][2])
    self:CreateRewardsList(rewards, tabPart.obj_rewardsItem, tabPart.trans_rewards)
  end)
end

function ActivityNewYearPage:CreateRewardsList(rewards, objItem, transItem)
  logError(rewards)
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
  self.tab_Widgets.obj_eff:SetActive(true)
  local m_timer = self:CreateTimer(function()
    self:_OnGetReward(args)
  end, 2, 1, false)
  self:StartTimer(m_timer)
end

function ActivityNewYearPage:_OnGetReward(args)
  self.tab_Widgets.obj_eff:SetActive(false)
  logError(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "ActivityNewYearPage")
  self:_CreateSignItem()
end

function ActivityNewYearPage:_ClickGet(taskInfo, status)
  local activityConfig = configManager.GetDataById("config_activity", self.activityId)
  if activityConfig.period > 0 and not PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  if status == TaskState.FINISH then
    if self.tab_Widgets.reddot ~= nil then
      self.tab_Widgets.reddot:SetActive(false)
    end
    Service.taskService:SendTaskReward(taskInfo.TaskId, TaskType.Activity)
  else
    noticeManager:ShowTipById(1300051)
  end
end

function ActivityNewYearPage:_ShowRandomText(index)
  if #self.actConfig.p5 == 0 then
    return 0
  end
  local uid = Data.userData:GetUserUid()
  local lastNum = string.sub(uid, string.len(uid), string.len(uid))
  local textIndex = lastNum % 7 + index
  textIndex = 7 < textIndex and textIndex - 7 or textIndex
  return textIndex
end

function ActivityNewYearPage:ShowRewardList(randomTextIndex, dropTab)
  self.tab_Widgets.obj_rewardList:SetActive(dropTab[2] ~= GoodsType.DROP)
  self.tab_Widgets.sv_luck:SetActive(dropTab[2] == GoodsType.DROP)
  self.tab_Widgets.tx_note.gameObject:SetActive(randomTextIndex ~= 0)
  if randomTextIndex ~= 0 then
    self.tab_Widgets.tx_note.text = UIHelper.GetString(self.actConfig.p5[randomTextIndex][1])
    self.tab_Widgets.tx_noteleft.text = UIHelper.GetString(self.actConfig.p5[randomTextIndex][2])
    self.tab_Widgets.tx_noteBook.text = UIHelper.GetString(self.actConfig.p5[randomTextIndex][1])
    self.tab_Widgets.tx_noteLeftBook.text = UIHelper.GetString(self.actConfig.p5[randomTextIndex][2])
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

function ActivityNewYearPage:_OpenBook()
  self.tab_Widgets.obj_openBook:SetActive(true)
end

function ActivityNewYearPage:_CloseBook()
  self.tab_Widgets.obj_openBook:SetActive(false)
end

return ActivityNewYearPage
