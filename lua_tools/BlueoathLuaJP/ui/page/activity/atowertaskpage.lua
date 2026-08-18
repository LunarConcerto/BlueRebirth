local ATowerTaskPage = class("UI.Activity.ATowerTaskPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ATowerTaskPage:DoInit()
  self.openActivityData = {}
  self.activityId = nil
end

function ATowerTaskPage:DoOnOpen()
  Service.taskService:SendTaskInfo()
  local params = self:GetParam()
  local activityId = params.activityId
  self.activityId = activityId
  self:_LoadItemInfo()
  self:_ShowActivityDes()
end

function ATowerTaskPage:_ShowActivityDes()
  local configData = configManager.GetDataById("config_activity", self.activityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(configData.period, configData.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_battleTime, startTimeFormat .. "<color=#FFFFFF> - </color>" .. endTimeFormat)
end

function ATowerTaskPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_zhaoMu, self._ClickZhaoMu, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_battle, self._ClickBattle, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_shop, self._ClickShop, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._LoadItemInfo, self)
end

function ATowerTaskPage:_OnGetReward(args)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = args.Rewards
  })
  local taskInfo = Logic.taskLogic:GetTaskConfig(args.TaskId, args.TaskType)
  if taskInfo then
    self:_ShowTips({
      rewards = args.Rewards,
      config = taskInfo
    })
    self:_LoadItemInfo()
  end
end

function ATowerTaskPage:_ShowTips(taskInfo)
end

function ATowerTaskPage:_LoadItemInfo()
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  if tabTaskInfo == nil then
    logError("ATowerTaskPage _LoadItemInfo tabTaskInfo is nil")
    return
  end
  local sortTaskInfo = Logic.taskLogic:GetSortTaskListByType(tabTaskInfo)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_itemInfo, self.tab_Widgets.trans_itemInfo, #sortTaskInfo, function(index, tabPart)
    local isCanOpenTask = Logic.taskLogic:GetCanOpenTask(sortTaskInfo, sortTaskInfo[index])
    tabPart.obj_item:SetActive(isCanOpenTask)
    UIHelper.SetText(tabPart.tx_des, sortTaskInfo[index].Config.desc)
    local max = string.split(sortTaskInfo[index].ProgressStr, "/")
    UIHelper.SetText(tabPart.tx_num, "<color=#8be8ff>" .. max[1] .. "</color>" .. "/" .. max[2])
    if sortTaskInfo[index].Data.RewardTime ~= 0 then
      UIHelper.SetText(tabPart.tx_num, "<color=#8be8ff>" .. max[2] .. "</color>" .. "/" .. max[2])
    else
    end
    tabPart.im_get.gameObject:SetActive(sortTaskInfo[index].Data.RewardTime ~= 0)
    tabPart.btn_go.gameObject:SetActive(sortTaskInfo[index].State == TaskState.TODO and 0 < sortTaskInfo[index].Config.go_up_to)
    tabPart.btn_fetch.gameObject:SetActive(sortTaskInfo[index].State == TaskState.FINISH)
    local rewards = Logic.rewardLogic:FormatRewardById(sortTaskInfo[index].Config.rewards)
    UIHelper.CreateSubPart(tabPart.obj_rewardItem, tabPart.trans_rewardItem, #rewards, function(nIndex, luaPart)
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      local tabReward = ItemInfoPage.GenDisplayData(rewards[nIndex].Type, rewards[nIndex].ConfigId)
      UIHelper.SetImage(luaPart.im_loginIcon, tabReward.icon)
      UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(luaPart.tx_rewardNum, rewards[nIndex].Num)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_look, self._ShowItemInfo, self, rewards[nIndex])
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_go, self.btn_go, self, sortTaskInfo[index])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_fetch, self.btn_fetch, self, sortTaskInfo[index])
  end)
end

function ATowerTaskPage:btn_go(go, args)
  if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  moduleManager:JumpToFunc(args.Config.go_up_to, table.unpack(args.Config.go_up_to_parm))
end

function ATowerTaskPage:btn_fetch(go, args)
  if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
end

function ATowerTaskPage:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function ATowerTaskPage:_ClickZhaoMu(...)
  local activityData = configManager.GetDataById("config_activity", self.activityId)
  moduleManager:JumpToFunc(FunctionID.BuildShip, activityData.extra_ship_id)
end

function ATowerTaskPage:_ClickBattle(...)
  moduleManager:JumpToFunc(FunctionID.TowerActivity)
end

function ATowerTaskPage:_ClickShop(...)
  local activityData = configManager.GetDataById("config_activity", self.activityId)
  moduleManager:JumpToFunc(FunctionID.Shop, activityData.shop_id)
end

function ATowerTaskPage:DoOnHide()
end

function ATowerTaskPage:DoOnClose()
end

return ATowerTaskPage
