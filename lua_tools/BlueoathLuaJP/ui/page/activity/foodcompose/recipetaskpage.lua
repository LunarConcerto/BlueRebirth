local RecipeTaskPage = class("ui.page.Activity.FoodCompose.RecipeTaskPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local taskStageFillMap = {
  [TaskState.TODO] = Color.New(0.4, 0.6039215686274509, 1.0, 255),
  [TaskState.FINISH] = Color.New(0.00784313725490196, 0.8627450980392157, 0.08627450980392157, 255)
}
local taskTagMap = {
  [MissionType.DAILY] = UIHelper.GetString(940000214),
  [MissionType.GROW] = UIHelper.GetString(940000215)
}
local taskTagImageMap = {
  [MissionType.DAILY] = "uipic_ui_meishi_im_biaoqian_zi",
  [MissionType.GROW] = "uipic_ui_meishi_im_biaoqian_huang"
}

function RecipeTaskPage:DoInit()
  self.activityId = 0
  self.actConfig = 0
end

function RecipeTaskPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
end

function RecipeTaskPage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.activityId)
  self:ShowPage()
end

function RecipeTaskPage:ShowPage()
  local arrTaskId = self.actConfig.p6
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  local screenSortTask = {}
  for _, v in pairs(tabTaskInfo) do
    if v.Config.hide == 0 or v.Config.hide == 1 and v.State ~= TaskState.TODO then
      table.insert(screenSortTask, v)
    end
  end
  table.sort(screenSortTask, function(data1, data2)
    if data1.State == data2.State then
      return data1.Config.order < data2.Config.order
    else
      return data1.State < data2.State
    end
  end)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.iil_tasksv, self.tab_Widgets.obj_taskItem, #screenSortTask, function(tabPart)
    local luaParts = {}
    for k, v in pairs(tabPart) do
      luaParts[tonumber(k)] = v
    end
    for index, luaPart in pairs(luaParts) do
      local taskInfo = screenSortTask[index]
      local taskData = taskInfo.Data
      local taskConfig = taskInfo.Config
      UIHelper.SetText(luaPart.txt_tag, taskTagMap[taskConfig.label])
      UIHelper.SetImage(luaPart.achieve_label, taskTagImageMap[taskConfig.label])
      UIHelper.SetText(luaPart.tx_name, taskConfig.title)
      UIHelper.SetText(luaPart.tx_des, taskConfig.desc)
      self:_SetAward(luaPart, taskData.Type, taskConfig)
      UIHelper.SetText(luaPart.tx_rate, taskInfo.ProgressStr)
      if taskInfo.State ~= TaskState.RECEIVED then
        luaPart.img_progress.color = taskStageFillMap[taskInfo.State]
        luaPart.progress.value = taskInfo.Progress
      end
      luaPart.progress.gameObject:SetActive(taskInfo.State ~= TaskState.RECEIVED)
      luaPart.btn_noFinished.gameObject:SetActive(taskConfig.go_up_to > 0 and taskInfo.State == TaskState.TODO)
      luaPart.btn_get.gameObject:SetActive(taskInfo.State == TaskState.FINISH)
      luaPart.img_status.gameObject:SetActive(taskInfo.State == TaskState.RECEIVED)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_noFinished, self._TaskBtnCall, self, taskInfo)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_get, self._TaskBtnCall, self, taskInfo)
    end
  end)
end

function RecipeTaskPage:_TaskBtnCall(go, args)
  if args.State == TaskState.TODO then
    if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
      noticeManager:ShowTipById(270022)
      return
    end
    moduleManager:JumpToFunc(args.Config.go_up_to, table.unpack(args.Config.go_up_to_parm))
  elseif args.State == TaskState.FINISH then
    local ok, msg = Logic.taskLogic:CheckGetReward(args.Data)
    if not ok then
      noticeManager:ShowTip(msg)
      return
    end
    Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
  end
end

function RecipeTaskPage:_SetAward(widgets, taskType, taskConfig)
  local taskAward = taskConfig.show_rewards
  local rewards = Logic.rewardLogic:FormatRewardById(taskAward)
  local num = #rewards
  UIHelper.CreateSubPart(widgets.obj_award, widgets.trans_award, num, function(index, tabPart)
    local award = CommonRewardItem:new()
    award:Init(index, rewards[index], tabPart)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_bg, self._ShowItemInfo, self, rewards[index])
  end)
end

function RecipeTaskPage:_ShowItemInfo(go, award)
  if award.Type == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award.ConfigId,
      showEquipType = ShowEquipType.Simple
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
  end
end

function RecipeTaskPage:_OnGetReward(args)
  local taskInfo = Logic.taskLogic:GetTaskConfig(args.TaskId, args.TaskType)
  if taskInfo then
    Logic.rewardLogic:ShowCommonReward(args.Rewards, "RecipeTaskPage")
    self:ShowPage()
  end
end

function RecipeTaskPage:_ClickClose()
  UIHelper.ClosePage(self:GetName())
end

function RecipeTaskPage:DoOnHide()
end

function RecipeTaskPage:DoOnClose()
end

return RecipeTaskPage
