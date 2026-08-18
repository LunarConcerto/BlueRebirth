local TaskLogic = class("logic.TaskLogic")
local TaskTopConfig = require("config.ClientConfig.TaskTopConfig")

function TaskLogic:initialize()
  self:ResetData()
end

function TaskLogic:ResetData()
  self.m_taskIndex = 0
  self.m_modIndex = 0
  self.m_kind2count = {}
  self.m_kind2total = {}
end

function TaskLogic:SetTopIconPos(positions)
  self.topPositions = positions
end

function TaskLogic:GetTopIconPos()
  return self.topPositions
end

function TaskLogic:SetTaskTagIndex(index)
  self.m_taskIndex = index or 0
end

function TaskLogic:GetTaskTagIndex()
  return self.m_taskIndex
end

function TaskLogic:SetModuleIndex(index)
  self.m_modIndex = index
end

function TaskLogic:GetModuleIndex()
  return self.m_modIndex
end

function TaskLogic:SortTask(tabTaskList)
  local prior1, prior2
  table.sort(tabTaskList, function(data1, data2)
    prior1 = self:GetPriority(data1.TaskId, data1.Progress)
    prior2 = self:GetPriority(data2.TaskId, data2.Progress)
    if prior1 ~= prior2 then
      return prior1 > prior2
    elseif data1.Progress ~= data2.Progress then
      return data1.Progress > data2.Progress
    elseif data1.Data.Type ~= data2.Data.Type then
      return data1.Data.Type < data2.Data.Type
    elseif data1.Order ~= data2.Order then
      return data1.Order > data2.Order
    else
      return data1.TaskId < data2.TaskId
    end
  end)
  return tabTaskList
end

function TaskLogic:GetPriority(taskId, progress)
  local sets = self:GetHigePriorityTasks()
  if 1 <= progress then
    return Mathf.Infinity
  else
    return sets[taskId] ~= nil and sets[taskId].TopOrder or 0
  end
end

function TaskLogic:GetHigePriorityTasks()
  return TaskTopConfig
end

function TaskLogic:GetWeedkTaskConfigById(taskId)
  return configManager.GetDataById("config_task_weekly", taskId)
end

function TaskLogic:GetGrowTaskConfigById(taskId)
  return configManager.GetDataById("config_task_grow", taskId)
end

function TaskLogic:GetDailyTaskConfigById(taskId)
  return configManager.GetDataById("config_task_daily", taskId)
end

function TaskLogic:GetMainTaskConfigById(taskId)
  return configManager.GetDataById("config_task_main", taskId)
end

function TaskLogic:GetBigActivityConfigById(taskId)
  return configManager.GetDataById("config_task_activity", taskId)
end

function TaskLogic:GetGrowConfigById(taskId)
  return configManager.GetDataById("config_achievement", taskId)
end

function TaskLogic:GetTeachConfigById(taskId)
  return configManager.GetDataById("config_task_teaching", taskId)
end

function TaskLogic:GetAchieveConfigById(achieveId)
  return configManager.GetDataById("config_achievement", achieveId)
end

function TaskLogic:GetTreatyTasById(taskId)
  return configManager.GetDataById("config_task_treaty", taskId)
end

function TaskLogic:GetReturnTasById(taskId)
  return configManager.GetDataById("config_task_return", taskId)
end

function TaskLogic:GetTaskConfig(taskId, taskType)
  if taskType == TaskType.Daily then
    return self:GetDailyTaskConfigById(taskId)
  elseif taskType == TaskType.Main then
    return self:GetMainTaskConfigById(taskId)
  elseif taskType == TaskType.Week then
    return self:GetWeedkTaskConfigById(taskId)
  elseif taskType == TaskType.Grow then
    return self:GetGrowTaskConfigById(taskId)
  elseif taskType == TaskType.Activity then
    return self:GetBigActivityConfigById(taskId)
  elseif taskType == TaskType.TeachingDaily or taskType == TaskType.TeachingStage then
    return self:GetTeachConfigById(taskId)
  elseif taskType == TaskType.Achieve then
    return self:GetAchieveConfigById(taskId)
  elseif taskType == TaskType.TreatyTask then
    return self:GetTreatyTasById(taskId)
  elseif taskType == TaskType.Return then
    return self:GetReturnTasById(taskId)
  elseif taskType == TaskType.Magazine then
    return configManager.GetDataById("config_task_magazine", taskId)
  elseif taskType == TaskType.Sport then
    return configManager.GetDataById("config_sportsmeet_achieve", taskId)
  elseif taskType == TaskType.GuildOffer then
    return configManager.GetDataById("config_task_guildoffer", taskId)
  elseif taskType == TaskType.GuildBigAct then
    return configManager.GetDataById("config_guildactivitytask", taskId)
  else
    logError("task config: can't find task config ,taskType:" .. taskType .. " taskId:" .. taskId)
  end
end

function TaskLogic:GetTaskListByTypeWithRewardSort(taskType, activityId, isAll)
  local list = {}
  if isAll ~= nil and isAll == true then
    list = self:GetAllTaskListByType(taskType, activityId)
  else
    list = self:GetTaskListByType(taskType, activityId)
  end
  local ret = {}
  for index, data in ipairs(list) do
    local retdata = {}
    retdata.Index = index
    retdata.Data = data
    table.insert(ret, retdata)
  end
  table.sort(ret, function(a, b)
    local a_isreward = a.Data.State >= TaskState.FINISH and a.Data.Data.RewardTime ~= 0 and 1 or 0
    local b_isreward = b.Data.State >= TaskState.FINISH and b.Data.Data.RewardTime ~= 0 and 1 or 0
    if a_isreward ~= b_isreward then
      return a_isreward < b_isreward
    end
    if a.Index ~= b.Index then
      return a.Index < b.Index
    end
    return false
  end)
  local retlist = {}
  for _, retdata in ipairs(ret) do
    table.insert(retlist, retdata.Data)
  end
  return retlist
end

function TaskLogic:GetTaskListByTypeWithRewardSortWithDayRefresh(taskType, activityId, isAll)
  local list = {}
  if isAll ~= nil and isAll == true then
    list = self:GetAllTaskListByType(taskType, activityId)
  else
    list = self:GetTaskListByType(taskType, activityId)
  end
  local ret = {}
  for index, data in ipairs(list) do
    local retdata = {}
    retdata.Index = index
    retdata.Data = data
    table.insert(ret, retdata)
  end
  table.sort(ret, function(a, b)
    local a_isreward = a.Data.State >= TaskState.FINISH and a.Data.Data.RewardTime ~= 0 and 1 or 0
    local b_isreward = b.Data.State >= TaskState.FINISH and b.Data.Data.RewardTime ~= 0 and 1 or 0
    local ardfID = a.Data.Config.refresh_id
    local brdfID = b.Data.Config.refresh_id
    if a_isreward ~= b_isreward then
      return a_isreward < b_isreward
    end
    if a.Data.State ~= b.Data.State then
      return a.Data.State < b.Data.State
    end
    if ardfID ~= brdfID then
      return ardfID > brdfID
    end
    if a.Index ~= b.Index then
      return a.Index < b.Index
    end
    return false
  end)
  local retlist = {}
  for _, retdata in ipairs(ret) do
    table.insert(retlist, retdata.Data)
  end
  return retlist
end

function TaskLogic:GetAllTaskListByType(taskType, activityId)
  local tabTaskList = Data.taskData:GetTaskDataByType(taskType)
  if tabTaskList == nil then
    return nil
  end
  if taskType == TaskType.Activity and activityId == nil then
    logError("activity task, need param activityId")
    return nil
  end
  local tabResult = {}
  for _, v in pairs(tabTaskList) do
    local config = self:GetTaskConfig(v.TaskId, v.Type)
    if config == nil then
      print("can't find task config,taskId:" .. v.TaskId .. "task Type:" .. v.Type)
    else
      local isOk = true
      if taskType == TaskType.Activity then
        isOk = activityId == config.activity_id
      end
      if isOk then
        local taskInfo = self:_GenTaskInfo(v, config)
        table.insert(tabResult, taskInfo)
      end
    end
  end
  return self:SortTask(tabResult)
end

function TaskLogic:GetTaskListByType(taskType, activityId)
  local tabTaskList = Data.taskData:GetTaskDataByType(taskType)
  if tabTaskList == nil then
    return nil
  end
  if taskType == TaskType.Activity and activityId == nil then
    logError("activity task, need param activityId")
    return nil
  end
  local tabResult = {}
  for _, v in pairs(tabTaskList) do
    if self:GetTaskState(v) ~= TaskState.RECEIVED then
      local config = self:GetTaskConfig(v.TaskId, v.Type)
      if config == nil then
        print("can't find task config,taskId:" .. v.TaskId .. "task Type:" .. v.Type)
      else
        local isOk = true
        if taskType == TaskType.Activity then
          isOk = activityId == config.activity_id
        end
        if isOk then
          local taskInfo = self:_GenTaskInfo(v, config)
          table.insert(tabResult, taskInfo)
        end
      end
    end
  end
  return self:SortTask(tabResult)
end

function TaskLogic:GetSortTaskListByType(tabTaskInfo)
  local received = {}
  local noReceived = {}
  for v, k in pairs(tabTaskInfo) do
    if k.Data.RewardTime == 0 then
      table.insert(noReceived, k)
    else
      table.insert(received, k)
    end
  end
  table.insertto(noReceived, received)
  return noReceived
end

function TaskLogic:GetCanReceive(tabTaskInfo, tabAllTaskInfo)
  local actMap = {}
  for k, v in pairs(tabAllTaskInfo) do
    actMap[v.TaskId] = v
  end
  for v, k in pairs(tabTaskInfo) do
    if k.State == TaskState.FINISH and k.Data.RewardTime == 0 then
      if k.Config.last_task_client == 0 then
        return true
      end
      if actMap[k.Config.last_task_client] and actMap[k.Config.last_task_client].RewardTime ~= 0 then
        return true
      end
    end
  end
  return false
end

function TaskLogic:GetTaskFinishState(taskId, taskType)
  local taskInfo = Data.taskData:GetTaskDataById(taskId, taskType)
  local status = TaskState.TODO
  if taskInfo and taskInfo.RewardTime ~= 0 then
    status = TaskState.RECEIVED
  elseif taskInfo and taskInfo.FinishTime ~= 0 then
    status = TaskState.FINISH
  end
  return status
end

function TaskLogic:GetCanOpenTask(allTaskInfo, item)
  if item.Config.last_task_client == 0 or item.Data.RewardTime ~= 0 then
    return true
  end
  for v, k in pairs(allTaskInfo) do
    if item.Config.last_task_client == k.TaskId and k.Data.RewardTime ~= 0 then
      return true
    end
  end
  return false
end

function TaskLogic:GetFirstTaskByType(type)
  local data = Logic.taskLogic:GetTaskListByType(type)
  if data then
    if 0 < #data then
      return data[1]
    else
      return nil
    end
  else
    return nil
  end
end

function TaskLogic:GetFinishTaskCount(taskType)
  local count = 0
  local taskList = Data.taskData:GetTaskDataByType(taskType)
  for _, info in pairs(taskList) do
    if info ~= nil and info.RewardTime ~= 0 then
      count = count + 1
    end
  end
  return count
end

function TaskLogic:IsAllFinishByType(taskType, activityId)
  local tasks = self:GetTaskListByType(taskType, activityId)
  if tasks == nil or #tasks == 0 then
    return true
  end
  for _, task in ipairs(tasks) do
    if task.State == TaskState.TODO then
      return false
    end
  end
  return true
end

function TaskLogic:GetTeachExamTasks()
  local tabTaskList = Data.taskData:GetTaskDataByType(TaskType.TeachingStage)
  if tabTaskList == nil then
    return nil
  end
  local tabResult = {}
  for id, tasks in pairs(tabTaskList) do
    local temp = {}
    for _, v in ipairs(tasks) do
      local config = self:GetTaskConfig(v.TaskId, v.Type)
      if config == nil then
        print("can't find task config,taskId:" .. v.TaskId .. "task Type:" .. v.Type)
      else
        local taskInfo = self:_GenTaskInfo(v, config)
        table.insert(temp, taskInfo)
      end
    end
    tabResult[id] = temp
  end
  return tabResult
end

function TaskLogic:GetTaskState(taskInfo)
  local status = TaskState.TODO
  if taskInfo and taskInfo.RewardTime ~= 0 then
    status = TaskState.RECEIVED
  elseif taskInfo and taskInfo.FinishTime ~= 0 then
    status = TaskState.FINISH
  end
  return status
end

function TaskLogic:CheckGetReward(taskInfo)
  local state = self:GetTaskState(taskInfo)
  if state == TaskState.FINISH then
    return true, ""
  else
    logError("get reward state err,cur state:" .. state)
    return false, ""
  end
end

function TaskLogic:GetTotalCount(taskId, taskType, ...)
  if next(self.m_kind2total) == nil then
    self:_InitKind2Total()
  end
  local eventType = self:GetTaskKind(taskId, taskType)
  local total
  if self.m_kind2total[eventType] then
    total = self.m_kind2total[eventType](self, taskId, taskType, ...)
  else
    total = self:_DefaultGetTotal(taskId, taskType, ...)
  end
  return Mathf.ToInt(total)
end

function TaskLogic:GetTaskKind(taskId, taskType)
  local config = self:GetTaskConfig(taskId, taskType)
  if config then
    return config.goal[1]
  else
    return 0
  end
end

function TaskLogic:GetCurentDay()
  local day = 1
  local isOpen = true
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.ActTaskLimit)
  if actId == nil then
    return 0, false
  end
  local activityInfo = configManager.GetDataById("config_activity", actId)
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(activityInfo.period)
  local now = time.getSvrTime()
  local periodconfig = configManager.GetDataById("config_period", activityInfo.period)
  local startY = periodconfig.p1
  local startM = periodconfig.p2
  local startD = periodconfig.p3
  local curD = time.formatTimerToD(now)
  if startTime > now or endTime < now then
    day = 1
    isOpen = false
  else
    day = curD - startD + 1
    local tabContentInfo = configManager.GetData("config_days_activity_limited")
    if day > #tabContentInfo then
      day = #tabContentInfo
    end
  end
  return day, isOpen
end

function TaskLogic:GetCurCount(taskInfo, max, ...)
  if taskInfo.FinishTime > 0 or 0 < taskInfo.RewardTime then
    return Mathf.ToInt(max)
  end
  local count = 0
  if next(self.m_kind2count) == nil then
    self:_InitKind2Count()
  end
  if self.m_kind2count[taskInfo.EventType] then
    count = self.m_kind2count[taskInfo.EventType](self, taskInfo, max, ...)
  else
    count = self:_DefaultGetCount(taskInfo, max, ...)
  end
  count = Mathf.Min(count, max)
  return Mathf.ToInt(count)
end

function TaskLogic:_GenTaskInfo(task, config)
  local res = {}
  res.Data = task
  res.Config = config
  res.TaskId = task.TaskId
  res.Order = config.order or 0
  local max = self:GetTotalCount(task.TaskId, task.Type)
  local cur = self:GetCurCount(task, max)
  res.Progress = cur / max
  res.ProgressStr = cur .. "/" .. max
  res.State = self:GetTaskState(task)
  return res
end

function TaskLogic:_InitKind2Count()
  self.m_kind2count = {
    [TaskKind.FININSHALLDAILY] = self._FININSHALLDAILYGetCount,
    [TaskKind.FINISHWEEK] = self._FINISHWEEKGetCount,
    [TaskKind.PASSTOWER] = self._ZeroGetCount,
    [TaskKind.SKILLLEVEL] = self._ZeroGetCount,
    [TaskKind.USERLEVEL] = self._USERLEVELGetCount,
    [TaskKind.GETEQUIPTEMPLATE] = self._GETEQUIPTEMPLATEGetCount,
    [TaskKind.GETHEROTEMPLATE] = self._GETHEROTEMPLATEGetCount,
    [TaskKind.TaskGetShipSfid] = self._GETHEROTEMPLATEGetCount,
    [TaskKind.POWERMAXCHG] = self._POWERMAXCHGGetCount,
    [TaskKind.POWERMINCHG] = self._POWERMINCHGGetCount,
    [TaskKind.HEROLVTEMPLATE] = self._ZeroGetCount,
    [TaskKind.HEROADTEMPLATE] = self._ZeroGetCount,
    [TaskKind.EQUIPLVTEMPLATE] = self._ZeroGetCount,
    [TaskKind.EQUIPADTEMPLATE] = self._ZeroGetCount,
    [TaskKind.PASSCOPY] = self._ZeroGetCount,
    [TaskKind.FULLPASSCOPY] = self._ZeroGetCount,
    [TaskKind.PASSTRAIN] = self._ZeroGetCount,
    [TaskKind.PASSRUNFIGHT] = self._ZeroGetCount,
    [TaskKind.PASSADAILYCOPY] = self._ZeroGetCount,
    [TaskKind.FRIENDCOUNT] = self._FRIENDCOUNTGetCount,
    [TaskKind.BUILDOFFICELV] = self._BUILDOFFICELVGetCount,
    [TaskKind.TOWER_ACTIVITY] = self._TowerActivityGetCount,
    [TaskKind.SHIP_LEVEL] = self._ShipLevel,
    [TaskKind.GETITEMTEMPLATE] = self.__GetItemTemplateCount,
    [TaskKind.MARRYCOUNT] = self._GetMarryCount,
    [TaskKind.TaskShipAffection] = self._Finish1Or0,
    [TaskKind.TaskShipEquip] = self._Finish1Or0,
    [TaskKind.TaskShipIllustrate] = self._Finish1Or0,
    [TaskKind.TaskMagazineShipStar] = self._CheckMagazineStar,
    [TaskKind.TaskMagazineShipAffection] = self._GetMagazineAffectionCount,
    [TaskKind.TaskMagazineShipLevel] = self._GetMagazineLevelCount,
    [TaskKind.TaskShipSkill] = self._Finish1Or0,
    [TaskKind.TaskEventMiniGameScoreCopy] = self._Finish1Or0,
    [TaskKind.TaskEventMiniGameScore] = self._Finish1Or0,
    [TaskKind.TaskRemouldSfIdStageEffect] = self._GetTaskIdFinishCount,
    [TaskKind.TaskRemouldSfIdStage] = self._GetTaskIdFinishCount,
    [TaskKind.TaskRemouldQualityStage] = self._GetTaskIdFinishCount
  }
end

function TaskLogic:_DefaultGetCount(taskInfo, max, ...)
  local config = self:GetTaskConfig(taskInfo.TaskId, taskInfo.Type)
  if config then
    return config.count_type == TaskCountType.SELF_COUNT and taskInfo.Count or taskInfo.EventCount
  else
    return 0
  end
end

function TaskLogic:_ZeroGetCount(taskInfo, max, ...)
  return 0
end

function TaskLogic:_FININSHALLDAILYGetCount(taskInfo, max, ...)
  return self:GetFinishTaskCount(TaskType.Daily)
end

function TaskLogic:_FINISHWEEKGetCount(taskInfo, max, ...)
  return self:GetFinishTaskCount(TaskType.Week)
end

function TaskLogic:_USERLEVELGetCount(taskInfo, max, ...)
  return Data.userData:GetUserLevel()
end

function TaskLogic:_GETEQUIPTEMPLATEGetCount(taskInfo, max, ...)
  local config = self:GetTaskConfig(taskInfo.TaskId, taskInfo.Type)
  if config then
    return Data.equipData:GetEquipGetNum(config.goal[2])
  else
    return 0
  end
end

function TaskLogic:_GETHEROTEMPLATEGetCount(taskInfo, max, ...)
  local config = self:GetTaskConfig(taskInfo.TaskId, taskInfo.Type)
  if config then
    return Data.heroData:GetHeroGetNum(config.goal[2])
  else
    return 0
  end
end

function TaskLogic:_POWERMAXCHGGetCount(taskInfo, max, ...)
  return Data.fleetData:GetMaxPower()
end

function TaskLogic:_POWERMINCHGGetCount(taskInfo, max, ...)
  return Data.fleetData:GetMinPower()
end

function TaskLogic:_FRIENDCOUNTGetCount(taskInfo, max, ...)
  return Logic.friendLogic:GetUserFriendNum()
end

function TaskLogic:_BUILDOFFICELVGetCount(taskInfo, max, ...)
  local config = self:GetTaskConfig(taskInfo.TaskId, taskInfo.Type)
  return Logic.buildingLogic:GetBuildMaxLevel(config.goal[2])
end

function TaskLogic:_TowerActivityGetCount(taskInfo, max, ...)
  local passNum = Logic.towerActivityLogic:GetPassNum()
  local historyMax = Data.towerActivityData:GetHistoryMax()
  return math.max(passNum, historyMax)
end

function TaskLogic:_ShipLevel(taskInfo, max, ...)
  return taskInfo.FinishTime <= 0 and 0 or 1
end

function TaskLogic:__GetItemTemplateCount(taskInfo, max, ...)
  local config = self:GetTaskConfig(taskInfo.TaskId, taskInfo.Type)
  return Data.bagData:GetItemNum(config.goal[2])
end

function TaskLogic:_GetMarryCount(taskInfo, max, ...)
  local userInfo = Data.userData:GetUserData()
  return userInfo.MarriedNum or 0
end

function TaskLogic:_Finish1Or0(taskInfo, max, ...)
  return taskInfo.FinishTime <= 0 and 0 or 1
end

function TaskLogic:_GetMagazineLevelCount(taskInfo, max, ...)
  local config = configManager.GetDataById("config_task_magazine", taskInfo.TaskId)
  local goal = config.goal
  return Logic.magazineLogic:CheckMagazineLevel(goal[2], goal[3], goal[4])
end

function TaskLogic:_GetMagazineAffectionCount(taskInfo, max, ...)
  local config = configManager.GetDataById("config_task_magazine", taskInfo.TaskId)
  local goal = config.goal
  return Logic.magazineLogic:CheckMagazineAffection(goal[2], goal[3], goal[4])
end

function TaskLogic:_CheckMagazineStar(taskInfo, max, ...)
  local config = configManager.GetDataById("config_task_magazine", taskInfo.TaskId)
  local goal = config.goal
  return Logic.magazineLogic:CheckMagazineStar(goal[2], goal[3], goal[4])
end

function TaskLogic:_GetTaskIdFinishCount(taskInfo, max, ...)
  return taskInfo.Count
end

function TaskLogic:_InitKind2Total()
  self.m_kind2total = {
    [TaskKind.FININSHALLDAILY] = self._FININSHALLDAILYGetTotal,
    [TaskKind.FINISHWEEK] = self._FINISHWEEKGetTotal,
    [TaskKind.PASSTOWER] = self._OneGetTotal,
    [TaskKind.SKILLLEVEL] = self._OneGetTotal,
    [TaskKind.HEROLVTEMPLATE] = self._OneGetTotal,
    [TaskKind.HEROADTEMPLATE] = self._OneGetTotal,
    [TaskKind.EQUIPLVTEMPLATE] = self._OneGetTotal,
    [TaskKind.EQUIPADTEMPLATE] = self._OneGetTotal,
    [TaskKind.PASSCOPY] = self._OneGetTotal,
    [TaskKind.FULLPASSCOPY] = self._OneGetTotal,
    [TaskKind.PASSTRAIN] = self._OneGetTotal,
    [TaskKind.PASSRUNFIGHT] = self._OneGetTotal,
    [TaskKind.PASSADAILYCOPY] = self._OneGetTotal,
    [TaskKind.SHIP_LEVEL] = self._ShipLevelTotal,
    [TaskKind.STARTBOX] = self._GetMaxIsOne,
    [TaskKind.AFFECTION] = self._GetMaxIsOne,
    [TaskKind.TaskShipAffection] = self._GetMaxIsOne,
    [TaskKind.TaskShipEquip] = self._GetMaxIsOne,
    [TaskKind.TaskShipIllustrate] = self._GetMaxIsOne,
    [TaskKind.TaskShipSkill] = self._GetMaxIsOne,
    [TaskKind.TaskEventMiniGameScoreCopy] = self._GetMaxIsOne,
    [TaskKind.TaskEventMiniGameScore] = self._GetMaxIsOne
  }
end

function TaskLogic:_DefaultGetTotal(taskId, taskType, ...)
  local config = self:GetTaskConfig(taskId, taskType)
  if config then
    return config.goal[#config.goal]
  else
    return 1
  end
end

function TaskLogic:_OneGetTotal(taskId, taskType, ...)
  return 1
end

function TaskLogic:_FININSHALLDAILYGetTotal(taskId, taskType, ...)
  local config = self:GetTaskConfig(taskId, taskType)
  return config.goal[2]
end

function TaskLogic:_FINISHWEEKGetTotal(taskId, taskType, ...)
  return configManager.GetDataById("config_task_weekly", 8).goal[2]
end

function TaskLogic:_ShipLevelTotal(taskId, taskType, ...)
  return 1
end

function TaskLogic:_GetMaxIsOne(taskId, taskType, ...)
  return 1
end

function TaskLogic:GetAllTaskListByTypeNoDeal(taskType, activityId)
  local tabTaskList = Data.taskData:GetTaskDataByType(taskType)
  if tabTaskList == nil then
    return nil
  end
  local tabResult = {}
  for _, v in pairs(tabTaskList) do
    local config = self:GetTaskConfig(v.TaskId, v.Type)
    if config == nil then
      print("can't find task config,taskId:" .. v.TaskId .. "task Type:" .. v.Type)
    elseif activityId == config.activity_id then
      table.insert(tabResult, v)
    end
  end
  return tabResult
end

return TaskLogic
