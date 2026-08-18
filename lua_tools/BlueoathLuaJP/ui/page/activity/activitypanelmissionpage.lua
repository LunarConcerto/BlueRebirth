local ActivityPanelMissionPage = class("UI.Activity.ActivityPanelMissionPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ActivityPanelMissionPage:DoInit()
  self.openActivityData = {}
  self.activityId = nil
end

function ActivityPanelMissionPage:DoOnOpen()
  local params = self:GetParam()
  local activityId = params.activityId
  self.activityId = activityId
  local activityCfg = configManager.GetDataById("config_activity", self.activityId)
  self.activityCfg = activityCfg
  self:_LoadItemInfo()
  self:_ShowAttr()
end

function ActivityPanelMissionPage:_ShowInfo()
  local widgets = self:GetWidgets()
  local activityCfg = self.activityCfg
  local isAllReceive = Logic.activityLogic:CheckJOpenTaskReceive()
  local fetchHeroTime = Data.jOpenData:GetFetchHeroTime()
  local isFetchHero = 0 < fetchHeroTime
  local fetchEquipTime = Data.jOpenData:GetFetchEquipTime()
  local isFetchEquip = 0 < fetchEquipTime
  local isMonth = Logic.userLogic:CheckMonthCardPrivilege()
  widgets.ExtraPackage:SetActive(isAllReceive and isFetchHero)
  widgets.bu_goto.gameObject:SetActive(isAllReceive and isFetchHero and not isMonth and not isFetchEquip)
  widgets.bu_buy.gameObject:SetActive(isAllReceive and isFetchHero and isMonth and not isFetchEquip)
  widgets.im_complete:SetActive(isFetchEquip)
  widgets.obj_time:SetActive(isAllReceive and isFetchHero)
  if isAllReceive and isFetchHero then
    local timer = self:CreateTimer(function()
      local timeLeft = fetchHeroTime + activityCfg.p8[1] - time.getSvrTime()
      local timeLeftFormat = time.formatTimerToDHMSColor(timeLeft)
      UIHelper.SetText(widgets.txt_time, timeLeftFormat)
      if timeLeft < 0 then
        UIHelper.ClosePage("ActivityPage")
      end
    end, 0.5, -1)
    self:StartTimer(timer)
  end
  if not isFetchHero then
    widgets.trans_reward.gameObject:SetActive(isAllReceive)
    if isAllReceive then
      UIHelper.SetLocText(widgets.tx_desc, activityCfg.p7[1])
    else
      UIHelper.SetLocText(widgets.tx_desc, activityCfg.p6[1])
    end
    local rewards = Logic.rewardLogic:FormatRewardById(activityCfg.p2[1])
    UIHelper.CreateSubPart(widgets.reward, widgets.trans_reward, #rewards, function(nIndex, luaPart)
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      local tabReward = ItemInfoPage.GenDisplayData(rewards[nIndex].Type, rewards[nIndex].ConfigId)
      UIHelper.SetImage(luaPart.icon, tabReward.icon)
      UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(luaPart.tx_num, rewards[nIndex].Num)
      UGUIEventListener.AddButtonOnClick(luaPart.reward, self._ShowItemInfo, self, rewards[nIndex])
    end)
    widgets.tx_mission_progress.gameObject:SetActive(false)
    widgets.tx_progress.gameObject:SetActive(false)
    widgets.btn_fetch.gameObject:SetActive(isAllReceive)
    UGUIEventListener.AddButtonOnClick(widgets.btn_fetch, function()
      Service.jOpenService:FetchHero()
    end)
    widgets.btn_go.gameObject:SetActive(false)
  end
end

function ActivityPanelMissionPage:_ShowAttr()
  local activityCfg = self.activityCfg
  local attrList = activityCfg.p4
  local attr = Logic.attrLogic:GetAttrById(table.unpack(activityCfg.p3))
  UIHelper.CreateSubPart(self.tab_Widgets.attr, self.tab_Widgets.trans_attr, #attrList, function(index, tabPart)
    local attrId = attrList[index]
    local attrConfig = configManager.GetDataById("config_attribute", attrId)
    UIHelper.SetImage(tabPart.icon, attrConfig.attr_icon)
    UIHelper.SetText(tabPart.text_des, attrConfig.attr_name)
    UIHelper.SetText(tabPart.text_num, attr[attrId])
  end)
end

function ActivityPanelMissionPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._LoadItemInfo, self)
  self:RegisterEvent(LuaEvent.GetJOpen, self._LoadItemInfo, self)
  self:RegisterEvent(LuaEvent.JOpenFetchHero, self.JOpenFetchHero, self)
  self:RegisterEvent(LuaEvent.JOpenFetchEquip, self.JOpenFetchEquip, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_goto, function()
    UIHelper.OpenPage("ShopPage", {
      shopId = ShopId.Recharge
    })
  end)
  UGUIEventListener.AddButtonOnClick(widgets.bu_buy, function()
    Service.jOpenService:FetchEquip()
  end)
  for i = 1, 4 do
    UGUIEventListener.AddButtonOnClick(widgets["bu_item" .. i], function()
      local activityCfg = self.activityCfg
      local itemInfo = activityCfg.p12[i]
      globalNoitceManager:ShowItemInfoPage(itemInfo[1], itemInfo[2])
    end)
  end
end

function ActivityPanelMissionPage:_OnGetReward(args)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = args.Rewards
  })
  local taskInfo = Logic.taskLogic:GetTaskConfig(args.TaskId, args.TaskType)
  if taskInfo then
    self:_LoadItemInfo()
  end
end

function ActivityPanelMissionPage:JOpenFetchHero(rewards)
  Logic.rewardLogic:ShowCommonReward(rewards.Reward, "ActivityPanelMissionPage")
end

function ActivityPanelMissionPage:JOpenFetchEquip(args)
  local rewardId = self.activityCfg.p9[1]
  local rewards = Logic.rewardLogic:FormatRewards({rewardId})
  UIHelper.OpenPage("GetRewardsPage", {Rewards = rewards})
end

function ActivityPanelMissionPage:_LoadItemInfo()
  local isOpen = Logic.activityLogic:CheckActivityOpenById(self.activityId)
  if not isOpen then
    UIHelper.ClosePage("ActivityPage")
    return
  end
  local widgets = self:GetWidgets()
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  if tabTaskInfo == nil then
    logError("ActivityPanelMissionPage _LoadItemInfo tabTaskInfo is nil")
    return
  end
  table.sort(tabTaskInfo, function(a, b)
    return a.Config.id < b.Config.id
  end)
  self.sortTaskInfo = tabTaskInfo
  widgets.tgGroup:ClearToggles()
  UIHelper.CreateSubPart(self.tab_Widgets.mission, self.tab_Widgets.trans_mission, #tabTaskInfo, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_mission_desc, tabTaskInfo[index].Config.desc)
    tabPart.toggle.gameObject:SetActive(tabTaskInfo[index].State ~= TaskState.RECEIVED)
    tabPart.im_mission_finish:SetActive(tabTaskInfo[index].State == TaskState.FINISH)
    widgets.tgGroup:RegisterToggle(tabPart.toggle)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tgGroup, self, nil, self._Switch)
  self:_ShowInfo()
  local selectIndex = Data.jOpenData:GetSelectIndex()
  if selectIndex then
    local taskInfo = self.sortTaskInfo[selectIndex + 1]
    if taskInfo.State ~= TaskState.RECEIVED then
      widgets.tgGroup:SetActiveToggleIndex(selectIndex)
      self:_Switch(selectIndex)
    else
      Data.jOpenData:ResetSelectIndex()
    end
  end
end

function ActivityPanelMissionPage:_Switch(index)
  Data.jOpenData:SetSelectIndex(index)
  local sortTaskInfo = self.sortTaskInfo
  local widgets = self:GetWidgets()
  local taskInfo = sortTaskInfo[index + 1]
  widgets.trans_reward.gameObject:SetActive(true)
  widgets.tx_mission_progress.gameObject:SetActive(true)
  widgets.tx_progress.gameObject:SetActive(true)
  if taskInfo.State == TaskState.TODO then
    UIHelper.SetLocText(widgets.tx_desc, taskInfo.Config.desc_language)
  elseif taskInfo.State == TaskState.FINISH then
    UIHelper.SetLocText(widgets.tx_desc, self.activityCfg.p11[1])
  end
  UIHelper.SetText(widgets.tx_progress, taskInfo.ProgressStr)
  local rewards = Logic.rewardLogic:FormatRewardById(taskInfo.Config.rewards)
  UIHelper.CreateSubPart(widgets.reward, widgets.trans_reward, #rewards, function(nIndex, luaPart)
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    local tabReward = ItemInfoPage.GenDisplayData(rewards[nIndex].Type, rewards[nIndex].ConfigId)
    UIHelper.SetImage(luaPart.icon, tabReward.icon)
    UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
    UIHelper.SetText(luaPart.tx_num, rewards[nIndex].Num)
    UGUIEventListener.AddButtonOnClick(luaPart.reward, self._ShowItemInfo, self, rewards[nIndex])
  end)
  widgets.btn_fetch.gameObject:SetActive(taskInfo.State == TaskState.FINISH)
  widgets.btn_go.gameObject:SetActive(taskInfo.State == TaskState.TODO and taskInfo.Config.go_up_to > 0)
  UGUIEventListener.AddButtonOnClick(widgets.btn_go, self.btn_go, self, taskInfo)
  UGUIEventListener.AddButtonOnClick(widgets.btn_fetch, self.btn_fetch, self, taskInfo)
end

function ActivityPanelMissionPage:btn_go(go, args)
  moduleManager:JumpToFunc(args.Config.go_up_to, table.unpack(args.Config.go_up_to_parm))
end

function ActivityPanelMissionPage:btn_fetch(go, args)
  Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
end

function ActivityPanelMissionPage:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function ActivityPanelMissionPage:DoOnHide()
end

function ActivityPanelMissionPage:DoOnClose()
end

return ActivityPanelMissionPage
