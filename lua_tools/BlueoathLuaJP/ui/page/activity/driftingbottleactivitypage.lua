local DriftingBottleActivityPage = class("UI.Activity.DriftingBottleActivityPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local offset = 400

function DriftingBottleActivityPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
end

function DriftingBottleActivityPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.RefreshAllInteractionItem, self._ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._OpenHelpPage, self)
end

function DriftingBottleActivityPage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self:_ShowPage()
end

function DriftingBottleActivityPage:_ShowPage()
  local widgets = self.tab_Widgets
  local actConfig = configManager.GetDataById("config_activity", self.activityId)
  local positions = actConfig.p4
  local iconList = actConfig.p6
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  if tabTaskInfo == nil then
    logError("DriftingBottleActivityPage _ShowPage tabTaskInfo is nil")
    return
  end
  table.sort(tabTaskInfo, function(data1, data2)
    return data1.TaskId < data2.TaskId
  end)
  local sortTaskInfo = tabTaskInfo
  local finishtmp = {}
  for i, v in pairs(sortTaskInfo) do
    if sortTaskInfo[i].Data.RewardTime ~= 0 then
      table.insert(finishtmp, v)
    end
  end
  local tx_num_now = #finishtmp
  UIHelper.SetText(self.tab_Widgets.tx_num_now, tx_num_now)
  UIHelper.CreateSubPart(self.tab_Widgets.item, self.tab_Widgets.Content, #sortTaskInfo, function(index, tabPart)
    tabPart.item.transform.anchoredPosition = Vector2.New(positions[index][1], positions[index][2])
    local reward = configManager.GetDataById("config_rewards", sortTaskInfo[index].Config.rewards).rewards[1]
    local rewardState
    if sortTaskInfo[index].Data.RewardTime ~= 0 then
      rewardState = RewardState.Received
    elseif sortTaskInfo[index].State == TaskState.FINISH then
      rewardState = RewardState.Receivable
    else
      rewardState = RewardState.UnReceivable
    end
    UIHelper.SetImage(tabPart.im_get, iconList[rewardState])
    local data = reward
    UGUIEventListener.AddButtonOnClick(tabPart.btn_get, function()
      if rewardState == RewardState.Receivable then
        self:_GetRewards(sortTaskInfo[index])
      else
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(data[1], data[2]))
      end
    end)
    local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
    UIHelper.SetImage(tabPart.im_icon, itemInfo.icon)
    UIHelper.SetImage(tabPart.im_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetText(tabPart.tx_num, data[3])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward, function()
      if rewardState == RewardState.Receivable then
        self:_GetRewards(sortTaskInfo[index])
      else
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(data[1], data[2]))
      end
    end)
  end)
end

function DriftingBottleActivityPage:_GetRewards(args)
  if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
end

function DriftingBottleActivityPage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "DriftingBottleActivityPage")
  self:_ShowPage()
end

function DriftingBottleActivityPage:_OpenHelpPage()
  UIHelper.OpenPage("HelpPage", {content = 81020001})
end

function DriftingBottleActivityPage:DoOnClose()
end

return DriftingBottleActivityPage
