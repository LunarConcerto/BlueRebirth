local ActivityAccumePage = class("ui.page.Activity.SchoolActivity.ActivityAccumePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TaskOperate = require("ui.page.task.TaskOperate")
local accumuItemId = 17001

function ActivityAccumePage:DoInit()
end

function ActivityAccumePage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  accumuItemId = configManager.GetDataById("config_parameter", 362).value
  self:ShowPage()
end

function ActivityAccumePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self.onGetTaskReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self.ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnGotoLevel, function()
    moduleManager:JumpToFunc(FunctionID.SeaCopy)
  end)
end

function ActivityAccumePage:DoOnHide()
end

function ActivityAccumePage:DoOnClose()
end

function ActivityAccumePage:ShowPage()
  self.mTabTaskInfo = Logic.taskLogic:GetTaskListByTypeWithRewardSort(TaskType.Activity, self.mActivityId)
  if self.mTabTaskInfo == nil then
    logError("SignCopyPage tabTaskInfo is nil")
    return
  end
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textTime, startTimeFormat .. "-" .. endTimeFormat)
  local ownCount = Data.bagData:GetItemNum(accumuItemId)
  local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, accumuItemId)
  UIHelper.SetText(self.tab_Widgets.textNum, ownCount)
  UIHelper.SetImage(self.tab_Widgets.imgIcon, display.icon_small)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentTask, self.tab_Widgets.itemTask, #self.mTabTaskInfo, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateItemPart(index, part)
    end
  end)
end

function ActivityAccumePage:updateItemPart(index, part)
  local taskInfo = self.mTabTaskInfo[index]
  UIHelper.SetText(part.textProcess, taskInfo.ProgressStr)
  UIHelper.SetText(part.textDesc, taskInfo.Config.desc)
  local rewards = Logic.rewardLogic:FormatRewardById(taskInfo.Config.rewards)
  UIHelper.CreateSubPart(part.objRewardItem, part.rectShowReward, #rewards, function(nIndex, luaPart)
    local tabReward = Logic.activityLogic:GetRewardInfo(rewards[nIndex].Type, rewards[nIndex].ConfigId)
    if rewards[nIndex].Type == GoodsType.FASHION then
      UIHelper.SetImage(luaPart.im_icon, tabReward.icon_small)
    else
      UIHelper.SetImage(luaPart.im_icon, tabReward.icon)
    end
    UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
    UIHelper.SetText(luaPart.tx_rewardNum, rewards[nIndex].Num)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_icon, function()
      Logic.itemLogic:ShowItemInfo(rewards[nIndex].Type, rewards[nIndex].ConfigId)
    end)
  end)
  if taskInfo.State == TaskState.TODO then
    part.objGet:SetActive(false)
    part.textProcess.gameObject:SetActive(true)
    part.btnReward.gameObject:SetActive(false)
    if taskInfo.Config.go_up_to > 0 then
      part.btnGoto.gameObject:SetActive(true)
      part.btnUncom.gameObject:SetActive(false)
      UGUIEventListener.AddButtonOnClick(part.btnGoto, function()
        if not Data.activityData:IsActivityOpen(self.mActivityId) then
          noticeManager:ShowTipById(270022)
          return
        end
        local taskInfo = self.mTabTaskInfo[index]
        moduleManager:JumpToFunc(taskInfo.Config.go_up_to)
      end)
    else
      part.btnGoto.gameObject:SetActive(false)
      part.btnUncom.gameObject:SetActive(true)
    end
  else
    part.btnGoto.gameObject:SetActive(false)
    part.btnUncom.gameObject:SetActive(false)
    if taskInfo.Data.RewardTime ~= 0 then
      part.objGet:SetActive(true)
      part.textProcess.gameObject:SetActive(false)
      part.btnReward.gameObject:SetActive(false)
    else
      part.objGet:SetActive(false)
      part.textProcess.gameObject:SetActive(true)
      part.btnReward.gameObject:SetActive(true)
      UGUIEventListener.AddButtonOnClick(part.btnReward, function()
        if not Data.activityData:IsActivityOpen(self.mActivityId) then
          noticeManager:ShowTipById(270022)
          return
        end
        local taskinfo = taskInfo.Data
        Service.taskService:SendTaskReward(taskinfo.TaskId, taskinfo.Type)
      end)
    end
  end
end

function ActivityAccumePage:onGetTaskReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "ActivityAccumePage")
  self:ShowPage()
end

return ActivityAccumePage
