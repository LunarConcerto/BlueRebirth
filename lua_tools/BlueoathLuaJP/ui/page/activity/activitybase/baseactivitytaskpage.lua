local BaseActivityTaskPage = class("ui.page.Activity.ActivityBase.BaseActivityTaskPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local accumuItemId = 17001

function BaseActivityTaskPage:DoInit()
end

function BaseActivityTaskPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  accumuItemId = configManager.GetDataById("config_parameter", 362).value
  self:ShowPage()
end

function BaseActivityTaskPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self.onGetTaskReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self.ShowPage, self)
end

function BaseActivityTaskPage:DoOnHide()
end

function BaseActivityTaskPage:DoOnClose()
end

function BaseActivityTaskPage:ShowPage()
  self.mTabTaskInfo = Logic.taskLogic:GetTaskListByTypeWithRewardSort(TaskType.Activity, self.mActivityId)
  if self.mTabTaskInfo == nil then
    logError("BaseActivityTaskPage tabTaskInfo is nil")
    return
  end
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentTask, self.tab_Widgets.itemTask, #self.mTabTaskInfo, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateItemPart(index, part)
    end
  end)
end

function BaseActivityTaskPage:updateItemPart(index, part)
  local taskInfo = self.mTabTaskInfo[index]
  UIHelper.SetText(part.textProcess, taskInfo.ProgressStr)
  UIHelper.SetText(part.textDesc, taskInfo.Config.desc)
  local rewards = Logic.rewardLogic:FormatRewardById(taskInfo.Config.rewards)
  UIHelper.CreateSubPart(part.objItem, part.rectRewards, #rewards, function(nIndex, luaPart)
    local tabReward = Logic.activityLogic:GetRewardInfo(rewards[nIndex].Type, rewards[nIndex].ConfigId)
    UIHelper.SetImage(luaPart.im_icon, tabReward.icon)
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
    end
  else
    part.btnGoto.gameObject:SetActive(false)
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

function BaseActivityTaskPage:onGetTaskReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "BaseActivityTaskPage")
  self:ShowPage()
end

return BaseActivityTaskPage
