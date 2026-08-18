local BattlePassData = class("data.BattlePassData")
BATTLEPASS_TYPE = {NORMAL = 0, ADVANCED = 1}
BATTLEPASS_TASK_TYPE = {
  Const = 1,
  Rand = 2,
  Achi = 3
}
BATTLEPASS_TASK_STATUS = {
  Null = 0,
  Finished = 1,
  Recieved = 2
}
BATTLEPASS_BUYTYPE = {Advance1 = 1, Advance2 = 2}
TgTaskIndexType = {WeekTask_1 = 1, AchiTask_2 = 2}

function BattlePassData:initialize()
  self.mData = {}
  self.mData.NormalRewardInfo = {}
  self.mData.AdvancedRewardInfo = {}
  self.mData.AchievementTaskInfo = {}
  self.mData.PassWeekInfo = {}
end

function BattlePassData:UpdateData(TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  logDebug("BattlePassData:UpdateData", traceTable(TRet))
  if TRet.PassType ~= nil then
    self.mData.PassType = TRet.PassType
  end
  if TRet.PassLevel ~= nil then
    self.mData.PassLevel = TRet.PassLevel
  end
  if TRet.PassExp ~= nil then
    self.mData.PassExp = TRet.PassExp
  end
  if TRet.NormalRewardInfo ~= nil and #TRet.NormalRewardInfo > 0 then
    for _, data in ipairs(TRet.NormalRewardInfo) do
      if data.PassLevel == nil or data.PassLevel <= 0 then
        self.mData.NormalRewardInfo = {}
      else
        self.mData.NormalRewardInfo[data.PassLevel] = data
      end
    end
  end
  if TRet.AdvancedRewardInfo ~= nil and 0 < #TRet.AdvancedRewardInfo then
    for _, data in ipairs(TRet.AdvancedRewardInfo) do
      if data.PassLevel == nil or data.PassLevel <= 0 then
        self.mData.AdvancedRewardInfo = {}
      else
        self.mData.AdvancedRewardInfo[data.PassLevel] = data
      end
    end
  end
  if TRet.CurWeekIndex ~= nil then
    self.mData.CurWeekIndex = TRet.CurWeekIndex
  end
  if TRet.PassWeekInfo ~= nil and 0 < #TRet.PassWeekInfo then
    for _, data in ipairs(TRet.PassWeekInfo) do
      if data.WeekIndex == nil or 0 >= data.WeekIndex then
        self.mData.PassWeekInfo = {}
      else
        local weekdata = self.mData.PassWeekInfo[data.WeekIndex] or {}
        if data.WeekIndex ~= nil then
          weekdata.WeekIndex = data.WeekIndex
        end
        if data.TaskInfo ~= nil and 0 < #data.TaskInfo then
          for _, datatask in ipairs(data.TaskInfo) do
            if datatask.TaskId == nil or 0 >= datatask.TaskId then
              weekdata.TaskInfo = {}
            else
              weekdata.TaskInfo[datatask.TaskId] = datatask
            end
          end
        end
        local RandomTaskPool = weekdata.RandomTaskPool or {}
        local RandomTaskPoolMap = weekdata.RandomTaskPoolMap or {}
        if data.RandomTaskPool ~= nil and 0 < #data.RandomTaskPool then
          for _, randdata in ipairs(data.RandomTaskPool) do
            if randdata.TaskId == nil or 0 >= randdata.TaskId then
              RandomTaskPool = {}
              RandomTaskPoolMap = {}
            else
              local olddata = RandomTaskPool[randdata.Index]
              if olddata ~= nil then
                RandomTaskPoolMap[olddata.TaskId] = nil
              end
              RandomTaskPool[randdata.Index] = randdata
              RandomTaskPoolMap[randdata.TaskId] = randdata
            end
          end
        end
        weekdata.RandomTaskPool = RandomTaskPool
        weekdata.RandomTaskPoolMap = RandomTaskPoolMap
        if data.RefreshCountFree ~= nil then
          weekdata.RefreshCountFree = data.RefreshCountFree
        end
        if data.RefreshCountPay ~= nil then
          weekdata.RefreshCountPay = data.RefreshCountPay
        end
        self.mData.PassWeekInfo[data.WeekIndex] = weekdata
      end
    end
  end
  if TRet.AchievementTaskInfo ~= nil and 0 < #TRet.AchievementTaskInfo then
    for _, data in ipairs(TRet.AchievementTaskInfo) do
      if data.TaskId == nil or 0 >= data.TaskId then
        self.mData.AchievementTaskInfo = {}
      else
        self.mData.AchievementTaskInfo[data.TaskId] = data
      end
    end
  end
end

function BattlePassData:GetPassType()
  return self.mData.PassType or BATTLEPASS_TYPE.NORMAL
end

function BattlePassData:GetPassLevel()
  return self.mData.PassLevel or 0
end

function BattlePassData:GetPassExp()
  return self.mData.PassExp or 0
end

function BattlePassData:GetCurWeekIndex()
  return self.mData.CurWeekIndex or 0
end

function BattlePassData:IsPassLevelNormalRewardGet(level)
  local info = self.mData.NormalRewardInfo[level] or {}
  local isGet = info.IsGet or false
  return isGet
end

function BattlePassData:IsPassLevelAdvancedRewardGet(level)
  local info = self.mData.AdvancedRewardInfo[level] or {}
  local isGet = info.IsGet or false
  return isGet
end

function BattlePassData:GetCurTaskWeekInfo()
  local curWeekIndex = self:GetCurWeekIndex()
  local info = self.mData.PassWeekInfo[curWeekIndex]
  if info == nil then
    logError("get week info err,", curWeekIndex, traceTable(self.mData.PassWeekInfo))
    return nil, false
  end
  return info, true
end

function BattlePassData:GetCurTaskWeekInfoRandomTaskPool()
  local weekinfo, ok = self:GetCurTaskWeekInfo()
  if not ok then
    logError("can not get task data", taskId)
    return {}
  end
  return weekinfo.RandomTaskPool or {}
end

function BattlePassData:GetCurTaskWeekInfoRandomTaskPoolMap()
  local weekinfo, ok = self:GetCurTaskWeekInfo()
  if not ok then
    logError("can not get task data", taskId)
    return {}
  end
  return weekinfo.RandomTaskPoolMap or {}
end

function BattlePassData:NewDefaultTaskData(taskId)
  local taskData = {}
  taskData.TaskId = taskId
  taskData.Count = 0
  taskData.Status = BATTLEPASS_TASK_STATUS.Null
  taskData.FinishCount = 0
  return taskData
end

function BattlePassData:GetPassTaskData(taskId)
  local taskData
  local cfg = configManager.GetDataById("config_battlepass_task", taskId)
  if cfg.task_type == BATTLEPASS_TASK_TYPE.Achi then
    local AchievementTaskInfo = self.mData.AchievementTaskInfo or {}
    taskData = AchievementTaskInfo[taskId]
  else
    local weekinfo, ok = self:GetCurTaskWeekInfo()
    if not ok then
      logError("can not get task data", taskId)
      return self:NewDefaultTaskData(taskId)
    end
    local taskinfo = weekinfo.TaskInfo or {}
    taskData = taskinfo[taskId]
  end
  if taskData == nil then
    taskData = self:NewDefaultTaskData(taskId)
  end
  return taskData
end

function BattlePassData:GetCurRefreshCount()
  local weekinfo, ok = self:GetCurTaskWeekInfo()
  if not ok then
    return 0, 0
  end
  local refreshCountFree = weekinfo.RefreshCountFree or 0
  local refreshCountPay = weekinfo.RefreshCountPay or 0
  return refreshCountFree, refreshCountPay
end

return BattlePassData
