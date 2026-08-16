local GuildPagePartial_Task = class("UI.Guild.GuildTaskPartial")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TaskOperate = require("ui.page.task.TaskOperate")

function GuildPagePartial_Task:init(page)
  if page == nil then
    logError("page is nil !!!")
    return
  end
  self.page = page
  self.tab_Widgets = page.tab_Widgets
  self.m_tab_Tags = {
    self.tab_Widgets.objGuildTaskPart,
    self.tab_Widgets.objTaskRewardPart,
    self.tab_Widgets.objLastRewardPart
  }
  self.mCurTaskList = {}
  self.mGuildTaskInfo = nil
end

function GuildPagePartial_Task:DoInit(page)
  self:init(page)
end

function GuildPagePartial_Task:DoOnOpen(page)
  self:init(page)
end

function GuildPagePartial_Task:RegisterAllEvent()
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroupLeftTask, self, "", self._SwitchTogs)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnApllyTask, self.onBtnApllyTaskClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCkeckTaskReward, self.onBtnCkeckTaskRewardClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnHelp, self.onBtnHelpClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCheckResult, self.btnCheckResultOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnDraw, self.btnDrawOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnNotDraw, self.btnDrawOnClick, self)
  self.page:RegisterEvent(LuaEvent.UPDATE_GUILDTASK_INFO, specialize(self.updatePage, self))
  self.page:RegisterEvent(LuaEvent.UPDATE_GUILDTASK_USER_INFO, specialize(self.updateUserPage, self))
  self.page:RegisterEvent(LuaEvent.PAGE_GUILDTASK_ACCEPT, specialize(self.updatePage, self))
  self.page:RegisterEvent(LuaEvent.UpdataUserInfo, specialize(self.ShowTop, self))
  self.page:RegisterEvent(LuaEvent.UpdateBagItem, specialize(self.updatePage, self))
  self.page:RegisterEvent(LuaEvent.GET_DRAWREWARD, specialize(self.getDrawReward, self))
end

function GuildPagePartial_Task:ShowPartial()
  self.tab_Widgets.tgGroupLeftTask:SetActiveToggleIndex(self:GetSelectTogIndex())
end

function GuildPagePartial_Task:updateGuildTaskInfo(data)
  self.mGuildTaskInfo = data
  self:updatePage()
end

function GuildPagePartial_Task:updatePage()
  self:ShowPage()
end

function GuildPagePartial_Task:updateUserPage()
  self:ShowPage()
end

function GuildPagePartial_Task:_SwitchTogs(index)
  for tabindex, objTab in ipairs(self.m_tab_Tags) do
    local isSelect = tabindex == index + 1
    objTab:SetActive(isSelect)
  end
  self:SetSelectTogIndex(index)
  self:ShowPage()
end

function GuildPagePartial_Task:SetSelectTogIndex(index)
  Logic.guildLogic.cache_GuildTaskPartialToggleIndex = index
end

function GuildPagePartial_Task:GetSelectTogIndex()
  return Logic.guildLogic.cache_GuildTaskPartialToggleIndex or 0
end

function GuildPagePartial_Task:ShowPage()
  local curSelectIndex = self.page:GetSelectToggleIndex() + 1
  if curSelectIndex ~= self.page.m_tab_Tags_Type.Task_4 then
    return
  end
  self:ShowTop()
  local curSelectIndex = self:GetSelectTogIndex() + 1
  if curSelectIndex == 1 then
    self:ShowGuildTaskPartial()
  elseif curSelectIndex == 2 then
    self:ShowTaskRewardPartial()
  elseif curSelectIndex == 3 then
    self:ShowLastRewardPartial()
  else
    logError("Undefined index")
  end
end

function GuildPagePartial_Task:ShowTop()
  local todayfinishnum = Data.guildtaskData:GetUserTodayFinishTaskStepCount()
  local cfg = Logic.guildLogic:GetUserPostConfig()
  UIHelper.SetText(self.tab_Widgets.textFinishNum, cfg.guildtask_finish_num - todayfinishnum .. "/" .. cfg.guildtask_finish_num)
  local curContriNum = Data.guildtaskData:GetMyTodayMemberContribute()
  UIHelper.SetLocText(self.tab_Widgets.textContriNum, 710085, curContriNum)
  local curContriCurrency = Data.userData:GetCurrency(CurrencyType.CONTRIBUTE)
  UIHelper.SetText(self.tab_Widgets.textCurrencyNum, curContriCurrency)
end

local ItemTaskType = {Task = 1, Reward = 2}

function GuildPagePartial_Task:ShowGuildTaskPartial()
  self.mCurTaskList = {}
  local myConstReward = Data.guildtaskData:GetMyGetConstantReward()
  if myConstReward ~= nil then
    local data = {}
    data.Type = ItemTaskType.Reward
    data.ConstReward = myConstReward
    table.insert(self.mCurTaskList, data)
  end
  local curTasks = Logic.guildtaskLogic:GetCurrentTaskList()
  for _, taskinfo in ipairs(curTasks) do
    if taskinfo.IsFinished <= 0 then
      local data = {}
      data.Type = ItemTaskType.Task
      data.TaskInfo = taskinfo
      table.insert(self.mCurTaskList, data)
    end
  end
  self.tab_Widgets.objTaskListEmpty:SetActive(#self.mCurTaskList == 0)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentTaskList, self.tab_Widgets.itemGuildTask, #self.mCurTaskList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local data = self.mCurTaskList[index]
      if data == nil then
        logError("data is nil")
        return
      end
      if data.Type == ItemTaskType.Reward then
        self:updateGuildTaskPart_Reward(index, part)
      elseif data.Type == ItemTaskType.Task then
        self:updateGuildTaskPart(index, part)
      else
        logError("Undefined type", data.Type)
      end
    end
  end)
  local finishTaskCount = Data.guildtaskData:GetTodayFinishTaskCount()
  UIHelper.SetText(self.tab_Widgets.textGuildTaskNum, finishTaskCount)
  local userTodayCanApplyTaskCount = Data.guildtaskData:GetUserTodayCanAcceptTaskCount()
  UIHelper.SetText(self.tab_Widgets.textCanApplyTaskNum, userTodayCanApplyTaskCount)
end

function GuildPagePartial_Task:updateGuildTaskPart_Reward(index, part)
  local taskdata = self.mCurTaskList[index] or {}
  local constreward = taskdata.ConstReward
  if constreward == nil then
    logError("constreward is nil", index, self.mCurTaskList)
    return
  end
  part.objNormalTask:SetActive(false)
  part.objRewardTask:SetActive(true)
  UIHelper.CreateSubPart(part.objConstantRewardTemplate, part.rectConstantRewardList, #constreward, function(nIndex, tabPart)
    local rewarditem = constreward[nIndex]
    local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
    UIHelper.SetLocText(tabPart.txtNum, 710082, rewarditem.Num)
    UIHelper.SetImage(tabPart.imgIcon, display.icon)
    UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btnIcon, function()
      UIHelper.OpenPage("ItemInfoPage", display)
    end)
  end)
  UGUIEventListener.AddButtonOnClick(part.btnGetConstReward, function()
    Service.guildtaskService:SendConstantRewardPoolGetReward({ConstReward = constreward})
  end)
  local myUid = Data.userData:GetUserUid()
  local memContri = Data.guildtaskData:GetMemberContribute()
  local contri = memContri[myUid] or 0
  local contriSum = 0
  for _, ctri in pairs(memContri) do
    contriSum = contriSum + ctri
  end
  UIHelper.SetText(part.textUserContriNum, contri)
  UIHelper.SetText(part.textGuildContriNum, contriSum)
end

function GuildPagePartial_Task:updateGuildTaskPart(index, part)
  local taskdata = self.mCurTaskList[index] or {}
  local taskinfo = taskdata.TaskInfo
  if taskinfo == nil then
    logError("taskinfo is nil", index, self.mCurTaskList)
    return
  end
  part.objNormalTask:SetActive(true)
  part.objRewardTask:SetActive(false)
  local cfg = configManager.GetDataById("config_task_guild", taskinfo.TaskId)
  UIHelper.SetText(part.txtName, cfg.desc)
  UIHelper.SetText(part.txtExtraReward, cfg.extra_reward_desc)
  UIHelper.SetText(part.txtPer, taskinfo.Progress .. "/" .. cfg.max_player_goal_num)
  part.sliderProcess.value = taskinfo.Progress / cfg.max_player_goal_num
  local rewards = Logic.rewardLogic:FormatRewardById(cfg.guild_rewards)
  UIHelper.CreateSubPart(part.objRewardTemplate, part.transRewardList, #rewards, function(nIndex, tabPart)
    local rewarditem = rewards[nIndex]
    local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
    UIHelper.SetLocText(tabPart.txtNum, 710082, rewarditem.Num)
    UIHelper.SetImage(tabPart.imgIcon, display.icon)
    UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btnIcon, function()
      UIHelper.OpenPage("ItemInfoPage", display)
    end)
  end)
  UIHelper.SetLocText(part.textContriNum, 710078, cfg.per_contr_num)
  UIHelper.SetLocText(part.textExpNum, 710078, cfg.guild_exp_rewards)
  if cfg.type == EnumGuildTaskType.Task then
    part.textInfo.gameObject:SetActive(true)
    UIHelper.SetLocText(part.textInfo, 710077, taskinfo.CurAcceptNum)
  else
    part.textInfo.gameObject:SetActive(false)
  end
  part.btnGoto.gameObject:SetActive(false)
  part.btnAccept.gameObject:SetActive(false)
  part.btnContri.gameObject:SetActive(false)
  part.btnGetReward.gameObject:SetActive(false)
  part.objNumPart:SetActive(false)
  if cfg.type == EnumGuildTaskType.Donate then
    part.btnContri.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btnContri, self.btnContriOnClick, self, {TaskData = taskinfo})
    part.objNumPart:SetActive(true)
    local havenum = Logic.guildtaskLogic:GetDonateItemNum(taskinfo.TaskId)
    UIHelper.SetText(part.textHaveNum, havenum)
  elseif cfg.type == EnumGuildTaskType.Task then
    local userCurTaskInfo = Data.guildtaskData:GetUserCurrentGuildTaskInfo()
    if userCurTaskInfo ~= nil and userCurTaskInfo.TaskIndex == taskinfo.TaskIndex then
      if userCurTaskInfo.IsComplete > 0 then
        local postCfg = Logic.guildLogic:GetUserPostConfig()
        local todayfinishnum = Data.guildtaskData:GetUserTodayFinishTaskStepCount()
        if todayfinishnum >= postCfg.guildtask_finish_num then
          part.btnAccept.gameObject:SetActive(true)
          UGUIEventListener.AddButtonOnClick(part.btnAccept, self.btnAcceptOnClick, self, {TaskData = taskinfo})
        else
          part.btnGetReward.gameObject:SetActive(true)
          UGUIEventListener.AddButtonOnClick(part.btnGetReward, self.btnGetRewardOnClick, self, {
            TaskData = taskinfo,
            IsExtra = userCurTaskInfo.IsExtra
          })
        end
      else
        part.btnGoto.gameObject:SetActive(true)
        UGUIEventListener.AddButtonOnClick(part.btnGoto, self.btnGotoOnClick, self, {TaskData = taskinfo})
      end
    else
      part.btnAccept.gameObject:SetActive(true)
      UGUIEventListener.AddButtonOnClick(part.btnAccept, self.btnAcceptOnClick, self, {TaskData = taskinfo})
    end
  else
    logError("Undefined type ", cfg.type)
  end
end

function GuildPagePartial_Task:ShowTaskRewardPartial()
  UIHelper.SetText(self.tab_Widgets.textTodayContriNum, Data.guildtaskData:GetMyTodayMemberContribute())
  UIHelper.SetText(self.tab_Widgets.textTodayFamilyContriNum, Data.guildtaskData:GetTotalTodayMemberContribute())
  local todayConstantRewardList = Logic.guildtaskLogic:GetTodayConstantRewardList()
  UIHelper.CreateSubPart(self.tab_Widgets.itemNormalRewardTemplate, self.tab_Widgets.rectNormalRewardList, #todayConstantRewardList, function(nIndex, tabPart)
    local rewarditem = todayConstantRewardList[nIndex]
    local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
    UIHelper.SetLocText(tabPart.txtNum, 710082, rewarditem.Num)
    UIHelper.SetImage(tabPart.imgIcon, display.icon)
    UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btnIcon, function()
      UIHelper.OpenPage("ItemInfoPage", display)
    end)
  end)
  self.mTodayRandomRewardList = Logic.guildtaskLogic:GetTodayRandomRewardList()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentDrawRewardList, self.tab_Widgets.itemDrawRewardTemplate, #self.mTodayRandomRewardList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateDrawRewardPart(index, part)
    end
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCkeckYesterdayReward, function()
    UIHelper.OpenPage("YesterdayRewardPage")
  end)
end

function GuildPagePartial_Task:updateDrawRewardPart(index, part)
  local rewarditem = self.mTodayRandomRewardList[index]
  local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
  UIHelper.SetLocText(part.txtNum, 710082, rewarditem.Num)
  UIHelper.SetImage(part.imgIcon, display.icon)
  UIHelper.SetImage(part.imgQuality, QualityIcon[display.quality])
  UGUIEventListener.AddButtonOnClick(part.btnIcon, function()
    UIHelper.OpenPage("ItemInfoPage", display)
  end)
end

function GuildPagePartial_Task:ShowLastRewardPartial()
  local can = Data.guildtaskData:CanDrawRandomReward()
  self.tab_Widgets.btnDraw.gameObject:SetActive(can)
  self.tab_Widgets.btnNotDraw.gameObject:SetActive(not can)
  local constantRewardList = Logic.guildtaskLogic:GetConstantRewardList()
  UIHelper.CreateSubPart(self.tab_Widgets.itemLastNormalRewardTemplate, self.tab_Widgets.rectLastNormalRewardList, #constantRewardList, function(nIndex, tabPart)
    local rewarditem = constantRewardList[nIndex]
    local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
    UIHelper.SetLocText(tabPart.txtNum, 710082, rewarditem.Num)
    UIHelper.SetImage(tabPart.imgIcon, display.icon)
    UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btnIcon, function()
      UIHelper.OpenPage("ItemInfoPage", display)
    end)
  end)
  self.mRandomRewardList = Logic.guildtaskLogic:GetRandomRewardList()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentLastDrawRewardList, self.tab_Widgets.itemLastDrawRewardTemplate, #self.mRandomRewardList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateRandomRewardPart(index, part)
    end
  end)
end

function GuildPagePartial_Task:updateRandomRewardPart(index, part)
  local randomItem = self.mRandomRewardList[index]
  local display = ItemInfoPage.GenDisplayData(randomItem.ItemType, randomItem.ItemId)
  UIHelper.SetLocText(part.txtNum, 710082, randomItem.ItemNum)
  UIHelper.SetImage(part.imgIcon, display.icon)
  UIHelper.SetImage(part.imgQuality, QualityIcon[display.quality])
  UGUIEventListener.AddButtonOnClick(part.btnIcon, function()
    UIHelper.OpenPage("ItemInfoPage", display)
  end)
end

function GuildPagePartial_Task:onBtnApllyTaskClick()
  UIHelper.OpenPage("ApplyTaskPage")
end

function GuildPagePartial_Task:onBtnCkeckTaskRewardClick()
  UIHelper.OpenPage("TaskRewardPage")
end

function GuildPagePartial_Task:onBtnHelpClick()
  UIHelper.OpenPage("HelpPage", {content = 710073})
end

function GuildPagePartial_Task:btnCheckResultOnClick()
  UIHelper.OpenPage("CheckRewardPage")
end

function GuildPagePartial_Task:getDrawReward(page, data)
  if self.page.mTimer_GetDraw ~= nil then
    self.page.mTimer_GetDraw:Stop()
    self.page.mTimer_GetDraw = nil
  end
  local doShowGetRewardsPage = function()
    self.tab_Widgets.objDrawRewardAnimation:SetActive(false)
    local rewards = {
      {
        Type = data.ItemType,
        ConfigId = data.ItemId,
        Num = data.ItemNum
      }
    }
    UIHelper.OpenPage("GetRewardsPage", {
      Rewards = rewards,
      Page = "GuildPage",
      DontMerge = true
    })
  end
  self.tab_Widgets.objDrawRewardAnimation:SetActive(true)
  self.page.mTimer_GetDraw = self.page:CreateTimer(function()
    doShowGetRewardsPage()
  end, 9, 1)
  self.page.mTimer_GetDraw:Start()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnDrawRewardAnimSkip, function()
    if self.page.mTimer_GetDraw ~= nil then
      self.page.mTimer_GetDraw:Stop()
      self.page.mTimer_GetDraw = nil
    end
    doShowGetRewardsPage()
  end)
end

function GuildPagePartial_Task:btnDrawOnClick()
  local randomrewardlist = Logic.guildtaskLogic:GetRandomRewardList()
  if #randomrewardlist <= 0 then
    noticeManager:ShowTip("\229\165\150\230\177\160\229\183\178\231\169\186")
    return
  end
  local count = Data.guildtaskData:GetMyMemberFinishStepCount()
  if count < GUILDTASK_REQUIRE_STEP_COUNT then
    noticeManager:ShowTip("\228\187\187\229\138\161\229\174\140\230\136\14410\230\172\161\230\137\141\232\131\189\230\138\189\229\165\150")
    return
  end
  local get = Data.guildtaskData:GetMyGetRandomRewardGet()
  if 0 < get then
    noticeManager:ShowTipById(710086)
    return
  end
  Service.guildtaskService:SendDrawTaskReward({PageName = "GuildPage"})
end

function GuildPagePartial_Task:btnContriOnClick(go, param)
  local postCfg = Logic.guildLogic:GetUserPostConfig()
  local todayfinishnum = Data.guildtaskData:GetUserTodayFinishTaskStepCount()
  if todayfinishnum >= postCfg.guildtask_finish_num then
    noticeManager:ShowTipById(710023)
    return
  end
  local paramTab = {
    Position = go.transform.position,
    Param = param
  }
  UIHelper.OpenPage("SubmitConfirmPage", paramTab)
end

function GuildPagePartial_Task:btnGotoOnClick(go, param)
  local taskinfo = param.TaskData
  local cfg = configManager.GetDataById("config_task_guild", taskinfo.TaskId)
  TaskOperate.TaskJumpByKind(cfg.goal[1], cfg.go_up_to)
end

function GuildPagePartial_Task:btnAcceptOnClick(go, param)
  local postCfg = Logic.guildLogic:GetUserPostConfig()
  local todayfinishnum = Data.guildtaskData:GetUserTodayFinishTaskStepCount()
  if todayfinishnum >= postCfg.guildtask_finish_num then
    noticeManager:ShowTipById(710023)
    return
  end
  local sendGuildTaskAcceptFun = function()
    local taskinfo = param.TaskData
    Service.guildtaskService:SendGuildTaskAccept(taskinfo)
  end
  local userCurTaskInfo = Data.guildtaskData:GetUserCurrentGuildTaskInfo()
  if userCurTaskInfo ~= nil then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          sendGuildTaskAcceptFun()
        end
      end
    }
    noticeManager:ShowMsgBox(710076, tabParams)
  else
    sendGuildTaskAcceptFun()
  end
end

function GuildPagePartial_Task:btnGetRewardOnClick(go, param)
  local taskinfo = param.TaskData
  local doSendGuildTaskFinish = function()
    Service.guildtaskService:SendGuildTaskFinish({
      TaskIndex = taskinfo.TaskIndex,
      TaskId = taskinfo.TaskId,
      IsExtra = param.IsExtra,
      PageName = "GuildPage"
    })
  end
  doSendGuildTaskFinish()
end

return GuildPagePartial_Task
