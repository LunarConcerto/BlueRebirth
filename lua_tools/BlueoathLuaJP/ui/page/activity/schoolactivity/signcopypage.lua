local SignCopyPage = class("UI.Activity.SchoolActivity.SignCopyPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local CommonRewardItem = require("ui.page.CommonItem")

function SignCopyPage:DoInit()
end

function SignCopyPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function SignCopyPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self.onGetTaskReward, self)
end

function SignCopyPage:DoOnHide()
end

function SignCopyPage:DoOnClose()
end

function SignCopyPage:ShowPage()
  self.mTabTaskInfo = Logic.taskLogic:GetTaskListByType(TaskType.Activity, self.mActivityId)
  if self.mTabTaskInfo == nil then
    logError("SignCopyPage tabTaskInfo is nil")
    return
  end
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_time, "\230\180\187\229\138\168\229\176\134\228\186\142" .. endTimeFormat .. "\231\187\147\230\157\159")
  local theLastInfo = self.mTabTaskInfo[#self.mTabTaskInfo]
  local info = theLastInfo.Data
  local signDays = info.Count
  UIHelper.SetText(self.tab_Widgets.tx_num, signDays)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_item, #self.mTabTaskInfo, function(index, tabPart)
    local taskinfo = self.mTabTaskInfo[index]
    local rewards = Logic.rewardLogic:FormatRewardById(taskinfo.Config.rewards)
    if #rewards ~= 1 then
      logError("#rewards is not 1 ,", taskinfo.Config.rewards)
      return
    end
    local reward = rewards[1]
    local item = CommonRewardItem:new()
    item:Init(index, reward, tabPart)
    if taskinfo.State == TaskState.Todo then
      tabPart.obj_get:SetActive(false)
      tabPart.obj_canget:SetActive(false)
    elseif taskinfo.Data.RewardTime ~= 0 then
      tabPart.obj_get:SetActive(true)
      tabPart.obj_canget:SetActive(false)
    else
      tabPart.obj_get:SetActive(false)
      tabPart.obj_canget:SetActive(true)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.im_frame, function()
      if taskinfo.State == TaskState.Finish and taskinfo.Data.RewardTime == 0 then
        Service.taskService:SendTaskReward(taskinfo.TaskId, taskinfo.Data.Type)
      else
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId))
      end
    end)
  end)
end

function SignCopyPage:onGetTaskReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "SignCopyPage")
  self:ShowPage()
end

return SignCopyPage
