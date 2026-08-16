local ActivityMiniGamePage = class("UI.Activity.ActivityMiniGamePage", LuaUIPage)
local TaskOperate = require("ui.page.task.TaskOperate")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ActivityMiniGamePage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.toggle = 1
end

function ActivityMiniGamePage:DoOnOpen()
  local params = self:GetParam() or {}
  self.activityId = params.activityId
  self:InitToggle()
  self:GetDefaultToggle()
  self:_ShowPage()
end

function ActivityMiniGamePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_go, self._GoTo, self)
  self:RegisterEvent(LuaEvent.FetchRewardBox, self._ShowPage, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._UpdateShowTask, self)
end

function ActivityMiniGamePage:InitToggle()
  local widgets = self.tab_Widgets
  local _, phaseList = self:GetToggleAreaMap()
  local actConfig = configManager.GetDataById("config_activity", self.activityId)
  local phaseName = actConfig.p1
  UIHelper.CreateSubPart(widgets.item_phase, widgets.content_phase, #phaseList, function(index, luaPart)
    local phaseId = phaseList[index]
    UIHelper.SetText(luaPart.tx_title, phaseName[index])
    widgets.toggle_group_phase:RegisterToggle(luaPart.toggle_phase)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.toggle_group_phase, self, nil, self.OnPhaseToggle)
end

function ActivityMiniGamePage:OnPhaseToggle(index)
  local _, phaseList = self:GetToggleAreaMap()
  self:SetToggle(phaseList[index + 1])
  self:_ShowTask()
end

function ActivityMiniGamePage:_ShowPage()
  self.tab_Widgets.toggle_group_phase:SetActiveToggleIndex(self.toggle - 1)
  self:_ShowTask()
end

function ActivityMiniGamePage:_ShowTask()
  local toggle = self.toggle
  local actConfig = configManager.GetDataById("config_activity", self.activityId)
  local allTaskConfList = actConfig.p4
  local aTaskInfo = allTaskConfList[toggle]
  local maskNameList = actConfig.p5
  local titleList = actConfig.p2
  local curOpen = self:_GetCurMaskId()
  local maskName = maskNameList[curOpen]
  local isCurToggleOpen = self:_GetCurToggleIsOpen(toggle)
  local sortTaskInfo = {}
  if not isCurToggleOpen then
    sortTaskInfo = self:GetActTaskWithoutData(aTaskInfo)
  else
    sortTaskInfo = self:GetActTaskWithData(aTaskInfo)
  end
  self.tab_Widgets.obj_mask:SetActive(not isCurToggleOpen)
  UIHelper.SetText(self.tab_Widgets.tx_mask, maskName[toggle])
  UIHelper.SetImage(self.tab_Widgets.im_title, titleList[toggle])
  UIHelper.CreateSubPart(self.tab_Widgets.item_task, self.tab_Widgets.content_task, #sortTaskInfo, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_des, sortTaskInfo[index].Config.desc)
    UIHelper.SetText(tabPart.tx_num, sortTaskInfo[index].ProgressStr)
    if sortTaskInfo[index].State == TaskState.TODO then
      local isJump = TaskOperate.ReturnPlayerIsJump(sortTaskInfo[index].Config.goal[1], sortTaskInfo[index].Config.go_up_to)
      tabPart.btn_anniu.gameObject:SetActive(isJump)
      tabPart.tx_num.gameObject:SetActive(isJump)
    else
      tabPart.btn_anniu.gameObject:SetActive(true)
      tabPart.tx_num.gameObject:SetActive(true)
    end
    if sortTaskInfo[index].State == TaskState.RECEIVED then
      tabPart.im_anniu.gameObject:SetActive(false)
    end
    tabPart.tx_num.gameObject:SetActive(true)
    tabPart.im_get.gameObject:SetActive(sortTaskInfo[index].State == TaskState.RECEIVED)
    local rewardState
    if sortTaskInfo[index].State == TaskState.TODO then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(800005))
      rewardState = RewardState.UnReceivable
    elseif sortTaskInfo[index].State == TaskState.FINISH then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(330007))
      rewardState = RewardState.Receivable
    elseif sortTaskInfo[index].State == TaskState.RECEIVED then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(330006))
      tabPart.tx_num.gameObject:SetActive(false)
      rewardState = RewardState.Received
    end
    local rewardid = sortTaskInfo[index].Config.rewards
    local rewards = Logic.rewardLogic:FormatRewardById(rewardid)
    local param = {}
    param.rewardState = rewardState
    param.rewards = rewards
    
    function param.callback()
      if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
        noticeManager:ShowTipById(270022)
        return
      end
      Service.taskService:SendTaskReward(sortTaskInfo[index].TaskId, sortTaskInfo[index].Data.Type)
    end
    
    UGUIEventListener.AddButtonOnClick(tabPart.btn_anniu, function()
      if sortTaskInfo[index].State == TaskState.TODO then
        local isJump = TaskOperate.ReturnPlayerIsJump(sortTaskInfo[index].Config.goal[1], sortTaskInfo[index].Config.go_up_to)
        if isJump then
          moduleManager:JumpToFunc(sortTaskInfo[index].Config.go_up_to, table.unpack(sortTaskInfo[index].Config.go_up_to_parm))
        end
      else
        self:_BtnRewardBox(param)
      end
    end)
    local reward = configManager.GetDataById("config_rewards", rewardid).rewards
    UIHelper.CreateSubPart(tabPart.obj_item, tabPart.trans_rewards, #reward, function(i, t)
      local tabReward = Logic.bagLogic:GetItemByTempateId(reward[i][1], reward[i][2])
      UIHelper.SetImage(t.im_icon, tabReward.icon)
      UIHelper.SetImage(t.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(t.tx_rewardNum, "x" .. reward[i][3])
      UGUIEventListener.AddButtonOnClick(t.btn_icon, function()
        self:_ShowItemInfo(reward[i])
      end)
    end)
  end)
end

function ActivityMiniGamePage:_BtnRewardBox(param)
  UIHelper.OpenPage("BoxRewardPage", param)
end

function ActivityMiniGamePage:_ShowItemInfo(award)
  if award[1] == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award[2],
      showEquipType = ShowEquipType.Simple,
      showDrop = false
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award[1], award[2]))
  end
end

function ActivityMiniGamePage:_NewPlayerCall(go, args)
end

function ActivityMiniGamePage:_FindIdInTable(tabTaskInfo, vId)
  for i, v in pairs(tabTaskInfo) do
    if v.TaskId == vId then
      return true, i
    end
  end
  return false, 0
end

function ActivityMiniGamePage:SetToggle(toggle)
  self.toggle = toggle
end

function ActivityMiniGamePage:GetDefaultToggle()
  local curOpen = self:_GetCurPhase()
  if self.toggle == 1 then
    self:SetToggle(curOpen)
  end
  return self.toggle
end

function ActivityMiniGamePage:_GetCurToggleIsOpen(curToggle)
  local actConfig = configManager.GetDataById("config_activity", self.activityId)
  local phaseAreMap = self:GetToggleAreaMap()
  local isInPeriod = PeriodManager:IsInPeriodArea(actConfig.period, phaseAreMap[curToggle])
  return isInPeriod
end

function ActivityMiniGamePage:_GetCurPhase()
  local actConfig = configManager.GetDataById("config_activity", self.activityId)
  local phaseareList = self:GetToggleAreaMap()
  local index = 1
  for i, v in pairs(phaseareList) do
    local isInPeriod = PeriodManager:IsInPeriodArea(actConfig.period, v)
    if isInPeriod then
      index = i
    end
  end
  return index
end

function ActivityMiniGamePage:GetActTaskWithoutData(tabTaskIdList)
  local tmp = {}
  for i, taskId in pairs(tabTaskIdList) do
    local info = {}
    local config = configManager.GetDataById("config_task_activity", taskId)
    info.Config = config
    info.ProgressStr = ""
    info.State = TaskState.TODO
    table.insert(tmp, info)
  end
  return tmp
end

function ActivityMiniGamePage:GetActTaskWithData(tabTaskIdList)
  local tmp = {}
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  if tabTaskInfo == nil then
    logError("ActivityMiniGamePage _ShowTask tabTaskInfo is nil")
    return
  end
  for _, vId in pairs(tabTaskIdList) do
    local isFind, index = self:_FindIdInTable(tabTaskInfo, vId)
    if not isFind then
      logError(" Activity and task comparison failed! taskId:", vId, "activityId:", self.activityId)
      return
    else
      table.insert(tmp, tabTaskInfo[index])
    end
  end
  return tmp
end

function ActivityMiniGamePage:GetToggleAreaMap()
  local actConfig = configManager.GetDataById("config_activity", self.activityId)
  local taskList = actConfig.p4
  local tmp = {}
  local tabtmp = {}
  for i, v in pairs(taskList) do
    local config = configManager.GetDataById("config_task_activity", v[1])
    local periodArea = config.period_area
    tmp[i] = periodArea
    table.insert(tabtmp, i)
  end
  return tmp, tabtmp
end

function ActivityMiniGamePage:_GetCurMaskId()
  local actConfig = configManager.GetDataById("config_activity", self.activityId)
  local areaList = actConfig.p3
  for i, v in pairs(areaList) do
    local isInPeriod = PeriodManager:IsInPeriodArea(actConfig.period, v)
    if isInPeriod then
      return i
    end
  end
  return 1
end

function ActivityMiniGamePage:_UpdateShowTask(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "ActivityMiniGamePage")
  self:_ShowPage()
end

function ActivityMiniGamePage:_GoTo()
  local actConfig = configManager.GetDataById("config_activity", self.activityId)
  local taskList = actConfig.p4
  local config = configManager.GetDataById("config_task_activity", taskList[1][1])
  moduleManager:JumpToFunc(config.go_up_to, table.unpack(config.go_up_to_parm))
end

function ActivityMiniGamePage:_CloseMySelf()
  UIHelper.ClosePage("ActivityMiniGamePage")
end

function ActivityMiniGamePage:DoOnHide()
end

function ActivityMiniGamePage:DoOnClose()
end

return ActivityMiniGamePage
