local TeachingMissionPage = class("UI.Teaching.TeachingMissionPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TaskOperate = require("ui.page.task.TaskOperate")
local TogIndex = {Task = 0, Teach = 1}

function TeachingMissionPage:DoInit()
  self.myTeacher = {}
  self.prestigeInfo = {}
  self.teachTask = {}
  self.taskStage = 0
  self.currTaskStage = 0
  self.currTeskConf = {}
  self.selectTaskConf = {}
  self.selectTog = 0
  self.maxTaskStage = 0
  self.teachData = {}
  self.isCheckTask = false
  self.studentLevel = 0
end

function TeachingMissionPage:DoOnOpen()
  local isTeacher = Logic.teachingLogic:CheckIsTeacher()
  if isTeacher then
    local studentInfo = self:GetParam()[1]
    self.studentLevel = studentInfo.UserInfo.Level
    self.isCheckTask = true
    self.tab_Widgets.txt_topTitle.text = string.format(UIHelper.GetString(2200065), Logic.teachingLogic:DisposeUname(studentInfo.UserInfo.Uname))
  else
    self.myTeacher = Data.teachingData:GetMyTeacher()
    self.teachData = Data.teachingData:GetData()
  end
  self:_GetTaskData()
  self.tab_Widgets.obj_toppage:SetActive(self.isCheckTask)
  self.tab_Widgets.tog_group:SetActiveToggleIndex(0)
end

function TeachingMissionPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_prestige, self._OpenPrestige, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reward, self._OpenReward, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closePrestige, self._ClosePrestige, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeReward, self._CloseReward, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_beforeTask, self._ClickTaskBefore, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_afterTask, self._ClickTaskAfter, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_evaluate, self._ClickEvaluate, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_prestigeClose, self._ClosePrestige, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClosePage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeGraduate, self._CloseGraduate, self)
  self.tabTogs = {
    self.tab_Widgets.tog_task,
    self.tab_Widgets.tog_teach
  }
  for i, tog in pairs(self.tabTogs) do
    self.tab_Widgets.tog_group:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
  self:RegisterRedDot(self.tab_Widgets.redDot_task)
  self:RegisterRedDot(self.tab_Widgets.redDot_prestige)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._UpdateTaskList, self)
  self:RegisterEvent(LuaEvent.TeachingAppraise, self._AppraiseSucceed, self)
  self:RegisterEvent(LuaEvent.TeachingGetDailyReward, self._OnGetReward, self)
end

function TeachingMissionPage:_SwitchTogs(index)
  self.tab_Widgets.obj_task:SetActive(index == TogIndex.Task)
  self.tab_Widgets.obj_teach:SetActive(index ~= TogIndex.Task)
  self.selectTog = index
  if self.selectTog == TogIndex.Task then
    self:_LoadTaskInfo()
  else
    self:_LoadTeachInfo()
  end
end

function TeachingMissionPage:_GetTaskData()
  self.taskInfoTab, self.taskStage = Logic.teachingLogic:GetExamTask()
  self.currTaskStage = self.taskStage
  self.maxTaskStage = Logic.teachingLogic:GetExamedMaxStage()
  self.currTeskConf = Logic.teachingLogic:GetExamConfig(self.taskStage)
  self.prestigeInfo = self.isCheckTask and Logic.teachingLogic:GetMyTeachRewards() or Logic.teachingLogic:GetTeacherRewards()
  self.teachTask = Logic.teachingLogic:GetDailyTask()
end

function TeachingMissionPage:_UpdateTaskList()
  if self.selectTog == TogIndex.Task then
    self:_LoadTaskInfo()
  end
end

function TeachingMissionPage:_LoadTaskInfo()
  self:_SetTaskInfo()
  local taskReward = self.isCheckTask and Logic.teachingLogic:GetExamRewards(self.taskStage, self.studentLevel) or Logic.teachingLogic:GetExamRewards(self.taskStage)
  self:_SetReward(self.tab_Widgets, taskReward)
  self.tab_Widgets.txt_tip.text = UIHelper.GetString(2200063)
end

function TeachingMissionPage:_SetTaskInfo()
  local showBtn = self:CheckHaveTeacher() and self.taskStage == self.currTaskStage and self.taskStage > self.maxTaskStage and not self.isCheckTask
  local taskFinish = true
  local showFinish = function(state, teacher, maxDoneStage, stage)
    if next(teacher) ~= nil or self.isCheckTask then
      return state == TaskState.FINISH or state == TaskState.RECEIVED
    else
      return stage <= maxDoneStage
    end
  end
  self.selectTaskConf = Logic.teachingLogic:GetExamConfig(self.taskStage)
  self.tab_Widgets.txt_taskStage.text = self.selectTaskConf.title
  local taskTab = self.taskInfoTab[self.taskStage]
  UIHelper.CreateSubPart(self.tab_Widgets.obj_taskItem, self.tab_Widgets.trans_task, #taskTab, function(nIndex, tabPart)
    local taskInfo = taskTab[nIndex]
    if taskInfo.State == TaskState.TODO then
      taskFinish = false
    end
    tabPart.img_bg.enabled = nIndex % 2 == 0
    tabPart.obj_underway:SetActive(taskInfo.State == TaskState.TODO and self.isCheckTask and self.taskStage == self.currTaskStage and self.taskStage > self.maxTaskStage)
    tabPart.txt_progress.gameObject:SetActive(showBtn)
    tabPart.obj_goto:SetActive(taskInfo.State == TaskState.TODO and taskInfo.Config.go_up_to ~= -1 and showBtn)
    tabPart.txt_content.text = taskInfo.Config.title
    local color = taskInfo.State == TaskState.TODO and "7E9AC0" or "33BE53"
    UIHelper.SetTextColor(tabPart.txt_progress, taskInfo.ProgressStr, color)
    tabPart.obj_complete:SetActive(showFinish(taskInfo.State, self.myTeacher, self.maxTaskStage, self.taskStage))
    UGUIEventListener.AddButtonOnClick(tabPart.btn_goto, self._ClickTaskGoto, self, taskInfo)
  end)
  self.tab_Widgets.btn_evaluate.gameObject:SetActive(showBtn and taskFinish)
  local icon = self.isCheckTask and Logic.teachingLogic:GetRewardFactor(self.studentLevel, self.currTaskStage).tips_icon or Logic.teachingLogic:GetRewardFactor().tips_icon
  UIHelper.SetImage(self.tab_Widgets.im_tishi, icon)
  self.tab_Widgets.obj_evaFinish.gameObject:SetActive(self.taskStage <= self.maxTaskStage)
end

function TeachingMissionPage:_LoadTeachInfo()
  local refreshDTaskNum = Data.taskData:GetTDailyTaskCount()
  local maxDTaskNum = Logic.teachingLogic:GetDailyTaskUp(self.currTaskStage)
  self.tab_Widgets.txt_tip.text = string.format(UIHelper.GetString(2200062), refreshDTaskNum, maxDTaskNum)
  self.tab_Widgets.obj_dailyFinish:SetActive(true)
  if not self.isCheckTask then
    self.tab_Widgets.obj_dailyTask:SetActive(next(self.teachTask) ~= nil and self:CheckHaveTeacher())
  else
    self.tab_Widgets.obj_dailyTask:SetActive(next(self.teachTask) ~= nil)
  end
  local str = ""
  if self.isCheckTask and next(self.teachTask) == nil then
    str = UIHelper.GetString(2200071)
  else
    str = not self:CheckHaveTeacher() and UIHelper.GetString(2200068) or UIHelper.GetString(2200067)
  end
  self.tab_Widgets.txt_dailyTip.text = str
  if next(self.teachTask) == nil or not self:CheckHaveTeacher() and not self.isCheckTask then
    return
  end
  self.tab_Widgets.obj_dailyFinish:SetActive(false)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_teachItem, self.tab_Widgets.trans_teach, #self.teachTask, function(nIndex, tabPart)
    local taskInfo = self.teachTask[nIndex]
    local teachConfig = taskInfo.Config
    tabPart.tx_progress.gameObject:SetActive(self:CheckHaveTeacher())
    tabPart.slider_progress.gameObject:SetActive(self:CheckHaveTeacher())
    tabPart.btn_goto.gameObject:SetActive(taskInfo.State == TaskState.TODO and self:CheckHaveTeacher() and teachConfig.go_up_to ~= -1 and not self.isCheckTask)
    tabPart.btn_finish.gameObject:SetActive(taskInfo.State == TaskState.FINISH and taskInfo.Data.RewardTime == 0 and not self.isCheckTask)
    tabPart.obj_underway:SetActive(taskInfo.State == TaskState.TODO and self.isCheckTask)
    tabPart.tx_title.text = teachConfig.title
    tabPart.tx_detail.text = teachConfig.desc
    tabPart.tx_progress.text = taskInfo.ProgressStr
    tabPart.slider_progress.value = taskInfo.Progress
    local param = {
      teachConfig.rewards,
      teachConfig.rewards_for_teacher
    }
    local rewards = self.isCheckTask and Logic.teachingLogic:DisposeReward(param, self.studentLevel, self.taskStage) or Logic.teachingLogic:DisposeReward(param)
    self:_SetReward(tabPart, rewards)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_goto, self._ClickTaskGoto, self, taskInfo)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_finish, self._GetTeachReward, self, taskInfo)
  end)
end

function TeachingMissionPage:_SetReward(Widgets, rewards)
  UIHelper.CreateSubPart(Widgets.obj_rewardItem, Widgets.trans_reward, #rewards, function(nIndex, tabPart)
    local reward = rewards[nIndex]
    local goodsInfo = Logic.bagLogic:GetItemByTempateId(reward.Type, reward.ConfigId)
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[goodsInfo.quality])
    UIHelper.SetImage(tabPart.img_icon, goodsInfo.icon)
    tabPart.tx_num.text = "x" .. reward.Num
    tabPart.obj_teacher:SetActive(reward.isTReward ~= nil)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward, self._ClickReward, self, reward)
  end)
end

function TeachingMissionPage:_OpenPrestige()
  if not self:CheckHaveTeacher() and not self.isCheckTask then
    noticeManager:ShowTip(UIHelper.GetString(2200010))
    return
  end
  self.tab_Widgets.obj_prestige:SetActive(true)
  self.tab_Widgets.txt_prestigeTitle.text = self.currTeskConf.title
  self.tab_Widgets.txt_prestigeNum.text = "x" .. self.prestigeInfo[1].Num
  self.tab_Widgets.txt_medalNum.text = "x" .. self.prestigeInfo[2].Num
end

function TeachingMissionPage:_OpenReward()
  if self.isCheckTask then
    self.tab_Widgets.obj_rewardTips:SetActive(true)
    self.tab_Widgets.txt_rewardTips.text = Logic.teachingLogic:GetStudentRewardsTip(self.studentLevel, self.currTaskStage)
  else
    if not self:CheckHaveTeacher() then
      noticeManager:ShowTip(UIHelper.GetString(2200010))
      return
    end
    self.tab_Widgets.obj_rewardTips:SetActive(true)
    self.tab_Widgets.txt_rewardTips.text = Logic.teachingLogic:GetStudentRewardsTip()
  end
end

function TeachingMissionPage:_ClosePrestige()
  self.tab_Widgets.obj_prestige:SetActive(close)
end

function TeachingMissionPage:_CloseReward()
  self.tab_Widgets.obj_rewardTips:SetActive(false)
end

function TeachingMissionPage:_ClickTaskBefore()
  if self.selectTaskConf.last_group_id == -1 then
    noticeManager:ShowTip(UIHelper.GetString(2200053))
    return
  end
  self.taskStage = self.selectTaskConf.last_group_id
  self:_LoadTaskInfo()
end

function TeachingMissionPage:_ClickTaskAfter()
  if self.selectTaskConf.next_group_id == -1 then
    noticeManager:ShowTip(UIHelper.GetString(2200054))
    return
  end
  self.taskStage = self.selectTaskConf.next_group_id
  self:_LoadTaskInfo()
end

function TeachingMissionPage:_ClickEvaluate()
  if not self:CheckHaveTeacher() then
    noticeManager:ShowTip(UIHelper.GetString(2200056))
    return
  else
    local taskTab = self.taskInfoTab[self.taskStage]
    for _, v in ipairs(taskTab) do
      if v.State == TaskState.TODO then
        noticeManager:ShowTip(UIHelper.GetString(2200055))
        return
      end
    end
  end
  UIHelper.OpenPage("TeachingEvaluationPage", {
    teacherInfo = self.myTeacher,
    taskConf = self.selectTaskConf
  })
end

function TeachingMissionPage:_ClickTaskGoto(obj, param)
  if not self:CheckHaveTeacher() then
    noticeManager:ShowTip(UIHelper.GetString(2200057))
    return
  end
  TaskOperate.TaskJumpByKind(param.Config.goal[1], param.Config.go_up_to)
end

function TeachingMissionPage:_ClickReward(obj, reward)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId))
end

function TeachingMissionPage:_GetTeachReward(obj, param)
  local ok, msg = Logic.taskLogic:CheckGetReward(param.Data)
  if not ok then
    noticeManager:ShowTip(msg)
    return
  end
  Service.teachingService:SendDailyReward(param.TaskId)
end

function TeachingMissionPage:_OnGetReward(args)
  self.prestigeInfo = Logic.teachingLogic:GetTeacherRewards()
  self.teachTask = Logic.teachingLogic:GetDailyTask()
  Logic.rewardLogic:ShowCommonReward(args.Reward, "TeachingMissionPage")
  self:_LoadTeachInfo()
end

function TeachingMissionPage:_AppraiseSucceed()
  self.teachData = Data.teachingData:GetData()
  self:_GetTaskData()
  self:_LoadTaskInfo()
  if self.currTaskStage == self.maxTaskStage then
    noticeManager:CloseTip()
    self.tab_Widgets.obj_graduate:SetActive(true)
  end
end

function TeachingMissionPage:CheckHaveTeacher()
  return next(self.teachData) ~= nil and self.teachData.TeacherUid ~= 0
end

function TeachingMissionPage:_ClosePage()
  eventManager:SendEvent(LuaEvent.TeacherCloseCheckTask)
  UIHelper.ClosePage(self:GetName())
end

function TeachingMissionPage:_CloseGraduate()
  self.tab_Widgets.obj_graduate:SetActive(false)
end

function TeachingMissionPage:DoOnHide()
  self.tab_Widgets.tog_group:ClearToggles()
end

function TeachingMissionPage:DoOnClose()
  self.tab_Widgets.tog_group:ClearToggles()
end

return TeachingMissionPage
