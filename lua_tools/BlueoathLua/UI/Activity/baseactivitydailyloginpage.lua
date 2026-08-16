local BaseActivityDailyLoginPage = class("UI.Activity.BaseActivityDailyLoginPage", LuaUIPage)
local index_start = 7

function BaseActivityDailyLoginPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function BaseActivityDailyLoginPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
end

function BaseActivityDailyLoginPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local params = self:GetParam()
  local activityId = params.activityId
  self.activityId = activityId
  local config = configManager.GetDataById("config_activity", activityId)
  if config.bg ~= "" then
    UIHelper.SetImage(widgets.im_bg, config.bg)
  end
  self.dailyConfigAll = Logic.activityLogic:GetDailyTask(self.activityId)
  self:ShowPage()
  self:CreateDailyLogin()
  self:ShowContent()
  widgets.scrollRect.onValueChanged:AddListener(function()
    self:showLine()
  end)
  local params = self:GetParam() or {}
  local custom = params.custom
  local contentIndex = custom or self:getContentIndex()
  self.m_tabWidgets.contentDay.transform.localPosition = Vector3.New((contentIndex - 1) * -207, 0, 0)
  self:showLine()
end

function BaseActivityDailyLoginPage:ShowPage()
  self.tab_Widgets.time:SetActive(false)
  self.tab_Widgets.objSchoolActivity:SetActive(false)
  self.tab_Widgets.objNationDay:SetActive(false)
  self:CheckReward()
end

function BaseActivityDailyLoginPage:showLine()
  local widgets = self:GetWidgets()
  local pos = widgets.scrollRect.horizontalNormalizedPosition
  widgets.im_line_left:SetActive(0.01 <= pos)
  widgets.im_line_right:SetActive(pos <= 0.99)
end

function BaseActivityDailyLoginPage:ShowContent()
  local widgets = self:GetWidgets()
  local params = self:GetParam()
  local activityId = params.activityId
  local config = configManager.GetDataById("config_activity", activityId)
  local info = config.p1
  local len = #info
  widgets.imgName.gameObject:SetActive(0 < len)
  widgets.imgGirl.gameObject:SetActive(0 < len)
  if len <= 0 then
    return
  end
  local indexShow = len
  for index, showInfo in ipairs(info) do
    local day = showInfo[1]
    local config = self.dailyConfigAll[day]
    local achieveTyp = config.login_type[1]
    local achieveId = config.login_type[2]
    local status = Logic.taskLogic:GetTaskFinishState(achieveId, achieveTyp)
    if status ~= TaskState.RECEIVED then
      indexShow = index
      break
    end
  end
  local showInfo = info[indexShow]
  UIHelper.SetImage(widgets.imgName, showInfo[3], true)
  UIHelper.SetImage(widgets.imgGirl, showInfo[4], true)
end

function BaseActivityDailyLoginPage:CreateDailyLogin()
  local widgets = self:GetWidgets()
  local configAll = self.dailyConfigAll
  local len = #configAll
  UIHelper.CreateSubPart(widgets.objDay, widgets.contentDay, len, function(index, tabPart)
    local config = configAll[index]
    local title = config.name
    local achieveTyp = config.login_type[1]
    local achieveId = config.login_type[2]
    local achieveConfig
    if achieveTyp == TaskType.Achieve then
      achieveConfig = configManager.GetDataById("config_achievement", achieveId)
    elseif achieveTyp == TaskType.Activity then
      achieveConfig = configManager.GetDataById("config_task_activity", achieveId)
    end
    local rewardId = achieveConfig.rewards
    local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    local reward = rewards[1]
    local typ = reward.Type
    local id = reward.ConfigId
    local num = reward.Num
    local icon = Logic.goodsLogic:GetIcon(id, typ)
    local name = Logic.goodsLogic:GetName(id, typ)
    local quality = Logic.goodsLogic:GetQuality(id, typ)
    local achieveTyp = config.login_type[1]
    local achieveId = config.login_type[2]
    local status = Logic.taskLogic:GetTaskFinishState(achieveId, achieveTyp)
    UIHelper.SetText(tabPart.tx_name_todo, name)
    UIHelper.SetText(tabPart.tx_num_todo, "x" .. num)
    UIHelper.SetImage(tabPart.img_icon_todo, icon)
    UIHelper.SetText(tabPart.tx_name_fetch, name)
    UIHelper.SetText(tabPart.tx_num_fetch, "x" .. num)
    UIHelper.SetImage(tabPart.img_icon_fetch, icon)
    UIHelper.SetText(tabPart.tx_name_fetched, name)
    UIHelper.SetText(tabPart.tx_num_fetched, "x" .. num)
    UIHelper.SetImage(tabPart.img_icon_fetched, icon)
    UIHelper.SetImageByQuality(tabPart.img_quality_todo, quality)
    UIHelper.SetImageByQuality(tabPart.img_quality_fetch, quality)
    UIHelper.SetImageByQuality(tabPart.img_quality_fetched, quality)
    tabPart.img_quality_fetch.gameObject:SetActive(typ ~= GoodsType.SHIP)
    tabPart.img_quality_fetched.gameObject:SetActive(typ ~= GoodsType.SHIP)
    if typ == GoodsType.SHIP then
      UIHelper.SetImage(tabPart.img_girl_fetch, config.fetch_icon, true)
      UIHelper.SetImage(tabPart.img_girl_fetched, config.fetched_icon, true)
    end
    tabPart.obj_girl_fetch.gameObject:SetActive(typ == GoodsType.SHIP)
    tabPart.obj_girl_fetched.gameObject:SetActive(typ == GoodsType.SHIP)
    UIHelper.SetText(tabPart.tx_day_todo, title)
    UIHelper.SetText(tabPart.tx_day_fetch, title)
    UIHelper.SetText(tabPart.tx_day_fetched, title)
    tabPart.todo:SetActive(status == TaskState.TODO)
    tabPart.fetch:SetActive(status == TaskState.FINISH)
    tabPart.fetched:SetActive(status == TaskState.RECEIVED)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item_todo, self.btnItem, self, reward)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item_fetch, self.btnFetch, self, index)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item_fetched, self.btnItem, self, reward)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_girl_fetch, self.btnFetch, self, index)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_girl_fetched, self.btnItem, self, reward)
    UGUIEventListener.AddButtonOnClick(tabPart.btnFetch, self.btnFetch, self, index)
  end)
end

function BaseActivityDailyLoginPage:DoOnClose()
end

function BaseActivityDailyLoginPage:btnFetch(go, index)
  local activityConfig = configManager.GetDataById("config_activity", self.activityId)
  if activityConfig.period > 0 and not PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  local config = self.dailyConfigAll[index]
  Service.taskService:SendTaskReward(config.login_type[2], config.login_type[1])
  self:Retention(index)
end

function BaseActivityDailyLoginPage:Retention(index)
  local dotinfo = {
    info = "ui_dailylogin_get",
    day_id = index
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function BaseActivityDailyLoginPage:btnItem(go, reward)
  local typ = reward.Type
  local id = reward.ConfigId
  Logic.itemLogic:ShowItemInfo(typ, id)
end

function BaseActivityDailyLoginPage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "BaseActivityDailyLoginPage")
  self:CreateDailyLogin()
  self:ShowContent()
end

function BaseActivityDailyLoginPage:getContentIndex()
  local configAll = self.dailyConfigAll
  for index = 1, index_start do
    local config = configAll[index]
    local achieveTyp = config.login_type[1]
    local achieveId = config.login_type[2]
    local status = Logic.taskLogic:GetTaskFinishState(achieveId, achieveTyp)
    if status ~= TaskState.RECEIVED then
      return 1
    end
  end
  for index = index_start, #configAll do
    local config = configAll[index]
    local achieveTyp = config.login_type[1]
    local achieveId = config.login_type[2]
    local status = Logic.taskLogic:GetTaskFinishState(achieveId, achieveTyp)
    if status ~= TaskState.RECEIVED then
      return index
    end
  end
  return 1
end

function BaseActivityDailyLoginPage:CheckReward()
  local activityConfig = configManager.GetDataById("config_activity", self.activityId)
  if activityConfig.period > 0 and not PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area) then
    return
  end
  local configAll = Logic.activityLogic:GetDailyTask(self.activityId)
  for _, config in ipairs(configAll) do
    local achieveTyp = config.login_type[1]
    local achieveId = config.login_type[2]
    local status = Logic.taskLogic:GetTaskFinishState(achieveId, achieveTyp)
    if status == TaskState.FINISH then
      Service.taskService:SendTaskReward(achieveId, achieveTyp)
      return
    end
  end
end

function BaseActivityDailyLoginPage:ShowTime()
  local widgets = self:GetWidgets()
  local config = configManager.GetDataById("config_activity", self.activityId)
  widgets.time:SetActive(config.period > 0)
  if config.period > 0 then
    local startTime, endTime = PeriodManager:GetPeriodTime(config.period, config.period_area)
    local startTimeFormat = time.formatTimeToMDHM(startTime)
    local endTimeFormat = time.formatTimeToMDHM(endTime)
    local str = startTimeFormat .. " - " .. endTimeFormat
    UIHelper.SetText(widgets.text_time, str)
  end
  local tabTaskInfo = Logic.taskLogic:GetTaskListByType(TaskType.Activity, self.activityId)
  if tabTaskInfo == nil then
    logError("SignCopyPage tabTaskInfo is nil")
    return
  end
  local len = #self.dailyConfigAll
  local signDays = len
  if tabTaskInfo[#tabTaskInfo] then
    local theLastInfo = tabTaskInfo[#tabTaskInfo]
    local info = theLastInfo.Data
    signDays = info.Count
  end
  UIHelper.SetText(self.tab_Widgets.textActDayTime, signDays)
end

return BaseActivityDailyLoginPage
