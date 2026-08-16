local MultiPveActivityPage = class("ui.page.Activity.MultiPve.MultiPveActivityPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function MultiPveActivityPage:DoInit()
end

function MultiPveActivityPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function MultiPveActivityPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_battle, self._ClickBattle, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self.onGetTaskReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self.ShowPage, self)
end

function MultiPveActivityPage:DoOnHide()
end

function MultiPveActivityPage:DoOnClose()
end

function MultiPveActivityPage:ShowPage()
  self.mTabTaskInfo = Logic.taskLogic:GetTaskListByTypeWithRewardSort(TaskType.Activity, self.mActivityId, true)
  if self.mTabTaskInfo == nil then
    logError("MultiPveActivityPage tabTaskInfo is nil")
    return
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_item, #self.mTabTaskInfo, function(index, tabPart)
    self:updateItemPart(index, tabPart)
  end)
end

function MultiPveActivityPage:updateItemPart(index, part)
  local taskInfo = self.mTabTaskInfo[index]
  UIHelper.SetText(part.tx_des, taskInfo.Config.desc)
  local rewards = Logic.rewardLogic:FormatRewardById(taskInfo.Config.rewards)
  UIHelper.CreateSubPart(part.obj_rewardItem, part.trans_rewardItem, #rewards, function(nIndex, luaPart)
    local tabReward = Logic.activityLogic:GetRewardInfo(rewards[nIndex].Type, rewards[nIndex].ConfigId)
    if rewards[nIndex].Type == GoodsType.FASHION then
      UIHelper.SetImage(luaPart.im_loginIcon, tabReward.icon_small)
    else
      UIHelper.SetImage(luaPart.im_loginIcon, tabReward.icon)
    end
    UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
    UIHelper.SetText(luaPart.tx_rewardNum, rewards[nIndex].Num)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_look, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(rewards[nIndex].Type, rewards[nIndex].ConfigId))
    end)
  end)
  part.slider_progress.value = taskInfo.Progress
  part.tx_num.text = taskInfo.ProgressStr
  if taskInfo.State == TaskState.TODO then
    part.im_get:SetActive(false)
    part.btn_fetch.gameObject:SetActive(false)
    if taskInfo.Config.go_up_to > 0 then
      part.btn_go.gameObject:SetActive(true)
      UGUIEventListener.AddButtonOnClick(part.btn_go, function()
        if not Data.activityData:IsActivityOpen(self.mActivityId) then
          noticeManager:ShowTipById(270022)
          return
        end
        local taskInfo = self.mTabTaskInfo[index]
        moduleManager:JumpToFunc(taskInfo.Config.go_up_to, table.unpack(taskInfo.Config.go_up_to_parm))
      end)
    else
      part.btn_go.gameObject:SetActive(false)
    end
  else
    part.btn_go.gameObject:SetActive(false)
    if taskInfo.Data.RewardTime ~= 0 then
      part.im_get:SetActive(true)
      part.btn_fetch.gameObject:SetActive(false)
    else
      part.im_get:SetActive(false)
      part.btn_fetch.gameObject:SetActive(true)
      UGUIEventListener.AddButtonOnClick(part.btn_fetch, function()
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

function MultiPveActivityPage:onGetTaskReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "MultiPveActivityPage")
  self:ShowPage()
end

function MultiPveActivityPage:_ClickBattle()
  moduleManager:JumpToFunc(FunctionID.MultiPveEntrance)
end

return MultiPveActivityPage
