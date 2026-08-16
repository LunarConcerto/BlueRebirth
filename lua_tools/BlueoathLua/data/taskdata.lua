local TaskData = class("data.TaskData", Data.BaseData)

function TaskData:initialize()
  self:ResetData()
end

function TaskData:ResetData()
  self.updateTime = 0
  self.tabAllTask = {}
  self.tabMainTask = {}
  self.tabDailyTask = {}
  self.tabWeekTask = {}
  self.tabGrowTask = {}
  self.tabMagazineTask = {}
  self.m_teachDailyTask = {}
  self.m_teachStageTask = {}
  self.m_gotPtReward = {}
  self.m_stageInfo = {}
  self.m_tdcount = 0
  self.tabAchieve = {}
  self.tabActivity = {}
  self.tabMedalList = {}
  self.tabReturn = {}
end

function TaskData:SetTaskData(taskInfos)
  if not time.isSameDay(self.updateTime, time.getSvrTime()) then
    self.tabDailyTask = {}
    self.m_teachDailyTask = {}
  end
  if not time.isSameWeek(self.updateTime, time.getSvrTime()) then
    self.tabWeekTask = {}
  end
  self.updateTime = time.getSvrTime()
  self.tabAllTask = {}
  self:editAchieveTaskInfo(TaskType.Achieve, taskInfos.AchieveTask, self.tabAchieve)
  self:editTaskInfo(TaskType.Main, taskInfos.MainTask, self.tabMainTask, true)
  self:editTaskInfo(TaskType.Daily, taskInfos.DailyTask, self.tabDailyTask, true)
  self:editTaskInfo(TaskType.Week, taskInfos.WeeklyTask, self.tabWeekTask, true)
  self:editTaskInfo(TaskType.Grow, taskInfos.GrowTask, self.tabGrowTask, true)
  self:editTaskInfo(TaskType.TeachingDaily, taskInfos.TeachingDailyTask, self.m_teachDailyTask, false)
  self:editTaskInfo(TaskType.Activity, taskInfos.ActivityTask, self.tabActivity, false)
  self:editTaskInfo(TaskType.Magazine, taskInfos.MagazineTask, self.tabMagazineTask, false)
  self:editTeachTask(taskInfos.TeachingStageTask, self.m_teachStageTask, false)
  self:editAchieveTaskInfo(TaskType.Return, taskInfos.ActivityReturnTask, self.tabReturn, false)
  if taskInfos.MedalList ~= nil then
    for _, medal in ipairs(taskInfos.MedalList) do
      table.insert(self.tabMedalList, medal)
    end
  end
  if taskInfos.GotPtReward then
    for _, id in ipairs(taskInfos.GotPtReward) do
      self.m_gotPtReward[id] = true
    end
  end
  if taskInfos.StageInfo then
    for _, stage in ipairs(taskInfos.StageInfo) do
      self.m_stageInfo[stage.TaskType] = stage
    end
  end
  if taskInfos.TeachingDailyTaskCount then
    self.m_tdcount = taskInfos.TeachingDailyTaskCount
  end
end

function TaskData:editTaskInfo(taskType, arrTask, tabTask, isSetAll)
  if arrTask == nil then
    return
  end
  for _, eventList in ipairs(arrTask) do
    for _, v in ipairs(eventList.Task) do
      v.Type = taskType
      v.EventCount = eventList.Count
      v.EventType = eventList.EventType
      tabTask[v.TaskId] = v
    end
  end
  if isSetAll then
    for _, v in pairs(tabTask) do
      table.insert(self.tabAllTask, v)
    end
  end
end

function TaskData:setTaskInfo(taskType, arrTask)
  local tabTask = {}
  for _, eventList in ipairs(arrTask) do
    for _, v in ipairs(eventList.Task) do
      v.Type = taskType
      v.EventCount = eventList.Count
      v.EventType = eventList.EventType
      tabTask[v.TaskId] = v
    end
  end
  return tabTask
end

function TaskData:editTeachTask(arrTask, taskStage, clear)
  if arrTask == nil then
    return
  end
  if clear then
    taskStage = {}
  end
  local tasks = {}
  for _, eventList in ipairs(arrTask) do
    for _, v in ipairs(eventList.Task) do
      v.Type = TaskType.TeachingStage
      v.EventCount = eventList.Count
      v.EventType = eventList.EventType
      tasks[v.TaskId] = v
    end
  end
  local taskFactory = function(taskId)
    return {
      Type = TaskType.TeachingStage,
      EventCount = 0,
      TaskId = taskId,
      RewardTime = 0,
      FinishTime = 0,
      Count = 0,
      Extra = {}
    }
  end
  local GetOldData = function(old, stageId, taskId)
    if old[stageId] then
      for _, v in ipairs(old[stageId]) do
        if v.TaskId == taskId then
          return v
        end
      end
    end
    return nil
  end
  local configs = configManager.GetData("config_task_teaching_group")
  for id, config in pairs(configs) do
    local temp = {}
    for _, taskId in ipairs(config.task_assess_id) do
      local task = tasks[taskId] or GetOldData(taskStage, id, taskId)
      if task == nil then
        task = taskFactory(taskId)
      end
      table.insert(temp, task)
    end
    taskStage[id] = temp
  end
  return taskStage
end

function TaskData:editAchieveTaskInfo(taskType, arrTask, tabTask)
  for _, eventList in ipairs(arrTask) do
    if tabTask[eventList.EventType] then
      tabTask[eventList.EventType].Count = eventList.Count
    else
      tabTask[eventList.EventType] = {
        List = {},
        Count = eventList.Count
      }
    end
    for _, v in ipairs(eventList.Task) do
      v.EventCount = eventList.Count
      v.EventType = eventList.EventType
      v.Type = taskType
      tabTask[eventList.EventType].List[v.TaskId] = v
    end
  end
end

function TaskData:GetTaskDataByType(taskType)
  if taskType == TaskType.All then
    return self.tabAllTask
  elseif taskType == TaskType.Daily then
    return self.tabDailyTask
  elseif taskType == TaskType.Main then
    return self.tabMainTask
  elseif taskType == TaskType.Week then
    return self.tabWeekTask
  elseif taskType == TaskType.Grow then
    return self.tabGrowTask
  elseif taskType == TaskType.Activity then
    return self.tabActivity
  elseif taskType == TaskType.TeachingDaily then
    return self.m_teachDailyTask
  elseif taskType == TaskType.TeachingStage then
    return self.m_teachStageTask
  elseif taskType == TaskType.Magazine then
    return self.tabMagazineTask
  else
    logError("Task type error:" .. taskType)
  end
end

function TaskData:GetTaskNumByType(typ)
  if typ == TaskType.Daily then
    return GetTableLength(self.tabDailyTask)
  end
  if typ == TaskType.Week then
    return GetTableLength(self.tabWeekTask)
  end
  if typ == TaskType.Grow then
    return GetTableLength(self.tabGrowTask)
  end
  if typ == TaskType.Main then
    return GetTableLength(self.tabMainTask)
  end
  logError("type can not imp in taskdata's get task num by type")
  return -1
end

function TaskData:GetAchieveData()
  return self.tabAchieve
end

function TaskData:GetTaskReturnData()
  return self.tabReturn
end

function TaskData:GetMedalList()
  return self.tabMedalList
end

function TaskData:GetBigActivityList()
  return self.tabActivity
end

function TaskData:GetTaskDataById(id, typ)
  if typ == TaskType.Achieve then
    return self:GetAchieveDataById(id)
  end
  if typ == TaskType.All then
    logError("TASK DATA ERROR: can not find task info by type:" .. typ)
    return nil
  end
  local taskTypeAll = self:GetTaskDataByType(typ)
  if taskTypeAll then
    return taskTypeAll[id]
  end
  return nil
end

function TaskData:GetAchieveDataById(id)
  local achieveConfig = configManager.GetDataById("config_achievement", id)
  local typ = achieveConfig.type_id
  if self.tabAchieve and self.tabAchieve[typ] then
    return self.tabAchieve[typ].List[id]
  end
  return nil
end

function TaskData:GetTeachPtRewardMap()
  return self.m_gotPtReward
end

function TaskData:GetTeachStage()
  if self.m_stageInfo[TaskType.TeachingStage] == nil then
    return 0
  end
  return self.m_stageInfo[TaskType.TeachingStage].StageId or 0
end

function TaskData:GetTeachDoneStage()
  return self.m_stageInfo[TaskType.TeachingStage].GotStageId or {}
end

function TaskData:GetTDailyTaskCount()
  return self.m_tdcount
end

function TaskData:SetSTeachData(data)
  self.m_teachDailyTask = self:setTaskInfo(TaskType.TeachingDaily, data.TeachingDailyTask)
  self.m_teachStageTask = self:editTeachTask(data.TeachingStageTask, self.m_teachStageTask, true)
  for _, stage in ipairs(data.StageInfo) do
    self.m_stageInfo[stage.TaskType] = stage
  end
  if data.TeachingDailyTaskCount then
    self.m_tdcount = data.TeachingDailyTaskCount
  end
end

return TaskData
