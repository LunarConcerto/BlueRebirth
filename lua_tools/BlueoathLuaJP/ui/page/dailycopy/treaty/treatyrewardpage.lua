local TreatyRewardPage = class("UI.DailyCopy.Treaty.TreatyRewardPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TaskOperate = require("ui.page.task.TaskOperate")

function TreatyRewardPage:DoInit()
end

function TreatyRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self._ClickClose, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
end

function TreatyRewardPage:DoOnOpen()
  self:_CreateTreatyReward()
end

function TreatyRewardPage:_CreateTreatyReward()
  local taskInfoTab = Logic.taskLogic:GetAllTaskListByType(TaskType.TreatyTask)
  taskInfoTab = self:_SortTask(taskInfoTab)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentRewardList, self.tab_Widgets.obj_item, #taskInfoTab, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local taskInfo = taskInfoTab[index]
      local rewards = Logic.rewardLogic:FormatRewardById(taskInfo.Config.rewards)
      UIHelper.SetText(part.textTitle, taskInfo.Config.title)
      part.btn_goto.gameObject:SetActive(taskInfo.State == TaskState.TODO and taskInfo.Config.go_up_to ~= -1)
      part.btn_get.gameObject:SetActive(taskInfo.State == TaskState.FINISH and taskInfo.Data.RewardTime == 0)
      part.obj_finish:SetActive(taskInfo.State == TaskState.RECEIVED)
      UGUIEventListener.AddButtonOnClick(part.btn_get, self._GetReward, self, taskInfo)
      UIHelper.CreateSubPart(part.objRewardTemplate, part.rectRewardList, #rewards, function(nIndex, tabPart)
        local rewarditem = rewards[nIndex]
        local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
        UIHelper.SetLocText(tabPart.textNum, 710082, rewarditem.Num)
        UIHelper.SetImage(tabPart.imgIcon, display.icon)
        UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
        UGUIEventListener.AddButtonOnClick(tabPart.btnIcon, function()
          UIHelper.OpenPage("ItemInfoPage", display)
        end)
      end)
    end
  end)
end

function TreatyRewardPage:_SortTask(taskTab)
  table.sort(taskTab, function(data1, data2)
    if data1.Data.RewardTime ~= data2.Data.RewardTime then
      return data1.Data.RewardTime < data2.Data.RewardTime
    else
      return data1.Config.order < data2.Config.order
    end
  end)
  return taskTab
end

function TreatyRewardPage:_GetReward(obj, param)
  Service.taskService:SendTaskReward(param.TaskId, param.Data.Type)
end

function TreatyRewardPage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "TreatyRewardPage")
  self:_CreateTreatyReward()
end

function TreatyRewardPage:_ClickClose()
  UIHelper.ClosePage(self:GetName())
end

return TreatyRewardPage
