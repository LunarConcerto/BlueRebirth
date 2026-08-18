local AchievePage = class("UI.Task.AchievePage", LuaUIPage)
local AwardShowNum = 3
local CommonRewardItem = require("ui.page.CommonItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local achieveSign = {
  "uipic_ui_achievement_im_shoucang",
  "uipic_ui_achievement_im_yangcheng",
  "uipic_ui_achievement_im_tansuo",
  "uipic_ui_achievement_im_zonghe"
}
local stageFillColor = {
  [TaskState.TODO] = Color.New(0.4, 0.6039215686274509, 1.0, 255),
  [TaskState.FINISH] = Color.New(0.00784313725490196, 0.8627450980392157, 0.08627450980392157, 255),
  [TaskState.RECEIVED] = Color.New(1.0, 0.8823529411764706, 1.0, 255)
}

function AchievePage:DoInit()
  self.achieveData = nil
  self.achieveId = 0
end

function AchievePage:DoOnOpen()
  self:_LoadTogGroup()
  self.achieveData = Data.taskData:GetAchieveData()
  local selectTog = Logic.achieveLogic:GetAchieveIndex()
  self.tab_Widgets.tog_group:SetActiveToggleIndex(selectTog)
end

function AchievePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.GetAllTaskReward, self._RefreshPage, self)
  self:RegisterEvent(LuaEvent.GetAllTaskReward, self._OnGetAllReward, self)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_fastGet, self._GetAllReward, self)
end

function AchievePage:_LoadTogGroup()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_tog, self.tab_Widgets.trans_togGroup, 4, function(nIndex, tabPart)
    tabPart.txt_name.text = UIHelper.GetString(340001 + nIndex)
    self.tab_Widgets.tog_group:RegisterToggle(tabPart.tog_all)
    self:RegisterRedDot(tabPart.redDot, nIndex)
  end)
end

function AchievePage:_SwitchTogs(index)
  Logic.achieveLogic:SetAchieveIndex(index)
  self.tab_Widgets.obj_achieve:SetActive(true)
  self.tab_Widgets.obj_total:SetActive(false)
  self:_LoadAchieveItem(index + 1)
end

function AchievePage:_LoadTotal()
  local tabUserInfo = Data.userData:GetUserData()
  self.tab_Widgets.txt_count.text = math.tointeger(tabUserInfo.AchievePoint)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_totalItem, self.tab_Widgets.trans_total, 4, function(nIndex, tabPart)
    tabPart.txt_name.text = UIHelper.GetString(340005 + nIndex)
    local recCount = Logic.achieveLogic:GetReceivedCount(nIndex, self.achieveData)
    tabPart.txt_achieve.text = string.format(UIHelper.GetString(340010), recCount)
    UIHelper.SetImage(tabPart.img_icon, achieveSign[nIndex])
  end)
end

function AchievePage:_LoadAchieveItem(mType)
  local haveReward = Logic.redDotLogic.Achieve()
  self.tab_Widgets.btn_fastGet.gameObject:SetActive(haveReward)
  local tabAchieve = Logic.achieveLogic:GetAchieveByType(mType, self.achieveData)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.Infinite_achieve, self.tab_Widgets.obj_achieveItem, #tabAchieve, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local achieveInfo = tabAchieve[nIndex]
      local achieveConfig = achieveInfo.config
      tabPart.txt_count.text = string.format(UIHelper.GetString(340011), achieveConfig.point)
      UIHelper.SetText(tabPart.tx_name, achieveConfig.title)
      UIHelper.SetText(tabPart.tx_des, achieveConfig.desc)
      self:_SetReward(tabPart, achieveConfig.rewards, achieveInfo.achieveId, achieveInfo.status)
      tabPart.tx_rate.text = achieveInfo.progressStr
      tabPart.progress.value = achieveInfo.progress
      tabPart.btn_achieve.gameObject:SetActive(achieveInfo.status == TaskState.FINISH)
      tabPart.btn_noFinished.gameObject:SetActive(achieveInfo.status == TaskState.TODO)
      tabPart.img_status.gameObject:SetActive(achieveInfo.status == TaskState.RECEIVED)
      tabPart.progress.gameObject:SetActive(achieveInfo.status ~= TaskState.RECEIVED)
      tabPart.img_progress.color = stageFillColor[achieveInfo.status]
      UGUIEventListener.AddButtonOnClick(tabPart.btn_achieve, self._GetReward, self, achieveInfo)
    end
  end)
end

function AchievePage:_GetReward(go, args)
  self.achieveId = args.achieveId
  Service.taskService:SendTaskReward(args.achieveId, TaskType.Achieve)
end

function AchievePage:_SetReward(widgets, taskAward, achieveId, status)
  local rewards = Logic.rewardLogic:FormatRewardById(taskAward)
  local medal = Logic.achieveLogic:_GetAchieveMedal(achieveId)
  if next(medal) then
    table.insert(rewards, medal)
  end
  local num = #rewards > AwardShowNum and AwardShowNum or #rewards
  UIHelper.CreateSubPart(widgets.obj_award, widgets.trans_award, num, function(index, tabPart)
    local award = CommonRewardItem:new()
    award:Init(index, rewards[index], tabPart)
    if status == TaskState.RECEIVED then
      tabPart.obj_bg:SetActive(true)
    else
      tabPart.obj_bg:SetActive(false)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.img_frame, self._ShowItemInfo, self, rewards[index])
  end)
end

function AchievePage:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function AchievePage:_ShowTips(taskInfo)
  eventManager:SendEvent(LuaEvent.ShowRewardTaskEffect, taskInfo)
end

function AchievePage:_OnGetReward(args)
  local dotInfo = {
    info = "ui_achievement_get",
    achievement_id = self.achieveId
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
  local taskInfo = configManager.GetDataById("config_achievement", args.TaskId)
  if taskInfo then
    self:_ShowTips({
      rewards = args.Rewards,
      config = taskInfo
    })
  end
  self:_RefreshPage()
end

function AchievePage:_GetAllReward()
  local haveReward = Logic.redDotLogic.Achieve()
  if not haveReward then
    return
  end
  if self.m_fastGetLock then
    return
  end
  Service.taskService:SendTaskAllReward(TaskAllRewardType.TASK_ACHIEVE)
  self.m_fastGetLock = true
end

function AchievePage:_OnGetAllReward(ret)
  self.m_fastGetLock = false
  if ret.Reward == nil then
    return
  end
end

function AchievePage:_RefreshPage()
  local selectTog = Logic.achieveLogic:GetAchieveIndex()
  self.achieveData = Data.taskData:GetAchieveData()
  self:_LoadAchieveItem(selectTog + 1)
end

function AchievePage:DoOnHide()
  self.tab_Widgets.tog_group:ClearToggles()
end

function AchievePage:DoOnClose()
  self.tab_Widgets.tog_group:ClearToggles()
end

return AchievePage
