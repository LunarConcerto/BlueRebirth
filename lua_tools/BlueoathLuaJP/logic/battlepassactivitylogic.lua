local BattlePassActivityLogic = class("logic.BattlePassActivityLogic")

function BattlePassActivityLogic:initialize()
end

local SpecialForBattlePassTaskGoalType = {}

function BattlePassActivityLogic:GetTaskProcessStr(taskId)
  local ProcessStr = ""
  local ProcessVal = 0
  local cfg = configManager.GetDataById("config_battlepass_task_activity", taskId)
  local goalType = cfg.task_goal[1]
  local specialTbl = SpecialForBattlePassTaskGoalType[goalType] or {}
  local funcGetCountMax = specialTbl.GetCountMax
  local funcGetCount = specialTbl.GetCount
  local countMax = cfg.task_goal[#cfg.task_goal]
  if funcGetCountMax ~= nil then
    countMax = funcGetCountMax(cfg)
  end
  local taskData = Data.battlepassactivityData:GetPassTaskData(taskId)
  local count = taskData.Count
  if funcGetCount ~= nil then
    count = funcGetCount(count)
  end
  if countMax <= count then
    count = countMax
  end
  ProcessStr = "" .. count .. "/" .. countMax
  ProcessVal = count / countMax
  return ProcessStr, ProcessVal
end

function BattlePassActivityLogic:GetPassExpMax()
  local passLevel = Data.battlepassactivityData:GetPassLevel()
  if passLevel <= 0 then
    return 0
  end
  local levelCfg = configManager.GetDataById("config_battlepass_level_activity", passLevel)
  return levelCfg.level_exp
end

function BattlePassActivityLogic:GetLevelRewardList()
  local levelCfgs = configManager.GetData("config_battlepass_level_activity")
  local cfgList = {}
  for _, cfg in pairs(levelCfgs) do
    table.insert(cfgList, cfg)
  end
  table.sort(cfgList, function(a, b)
    if a.level ~= b.level then
      return a.level < b.level
    end
    return false
  end)
  return cfgList
end

function BattlePassActivityLogic:GetDefaultBattlePassParamConfig()
  local paramCfg = configManager.GetDataById("config_battlepass_param_activity", 1)
  return paramCfg
end

function BattlePassActivityLogic:CanRewardGet()
  local curPassLevel = Data.battlepassactivityData:GetPassLevel()
  for lvl = 1, curPassLevel do
    local isCan = self:CanLevelRewardGet(lvl)
    if isCan then
      return true
    end
  end
  return false
end

function BattlePassActivityLogic:CanLevelRewardGet(passLevel)
  if self:CanLevelNormalRewardGet(passLevel) then
    return true
  end
  if self:CanLevelAdvancedRewardGet(passLevel) then
    return true
  end
  return false
end

function BattlePassActivityLogic:CanLevelNormalRewardGet(passLevel)
  local curPassLevel = Data.battlepassactivityData:GetPassLevel()
  if passLevel > curPassLevel then
    return false
  end
  local levelCfg = configManager.GetDataById("config_battlepass_level_activity", passLevel)
  if levelCfg.free_level_reward > 0 and not Data.battlepassactivityData:IsPassLevelNormalRewardGet(passLevel) then
    return true
  end
  return false
end

function BattlePassActivityLogic:CanLevelAdvancedRewardGet(passLevel)
  local curPassLevel = Data.battlepassactivityData:GetPassLevel()
  if passLevel > curPassLevel then
    return false
  end
  local levelCfg = configManager.GetDataById("config_battlepass_level_activity", passLevel)
  local passType = Data.battlepassactivityData:GetPassType()
  if passType >= BATTLEPASSACTIVITY_TYPE.ADVANCED and levelCfg.pay_level_reward > 0 and not Data.battlepassactivityData:IsPassLevelAdvancedRewardGet(passLevel) then
    return true
  end
  return false
end

function BattlePassActivityLogic:GetBattlePassMaxLevel()
  local cfgs = configManager.GetData("config_battlepass_level_activity") or {}
  return #cfgs
end

function BattlePassActivityLogic:GetTargetRewardLevelCfg(baselevel)
  local baselvl = baselevel or 0
  local curPassLevel = Data.battlepassactivityData:GetPassLevel()
  local maxPassLevel = self:GetBattlePassMaxLevel()
  local startLevel = baselvl < curPassLevel and curPassLevel or baselvl
  for lvl = startLevel + 1, maxPassLevel do
    local levelCfg = configManager.GetDataById("config_battlepass_level_activity", lvl)
    if 0 < levelCfg.target_reward then
      return levelCfg
    end
  end
  return nil
end

function BattlePassActivityLogic:GetPerWeekPassTaskList()
  return self:GetPassTaskListByType({
    BATTLEPASSACTIVITY_TASK_TYPE.Const,
    BATTLEPASSACTIVITY_TASK_TYPE.Rand
  })
end

function BattlePassActivityLogic:GetAchievePassTaskList()
  return self:GetPassTaskListByType({
    BATTLEPASSACTIVITY_TASK_TYPE.Achi
  })
end

function BattlePassActivityLogic:GetPassTaskListByType(taskTypes)
  local ret = {}
  local tasktyps = taskTypes or {}
  local mapTyp = {}
  for _, taskType in ipairs(tasktyps) do
    mapTyp[taskType] = true
  end
  local randmap = Data.battlepassactivityData:GetCurTaskWeekInfoRandomTaskPoolMap()
  local cfgs = configManager.GetData("config_battlepass_task_activity") or {}
  for _, cfg in pairs(cfgs) do
    local isWant = mapTyp[cfg.task_type] or false
    if isWant then
      if cfg.task_type == BATTLEPASSACTIVITY_TASK_TYPE.Rand then
        if randmap[cfg.id] ~= nil then
          table.insert(ret, cfg)
        end
      else
        table.insert(ret, cfg)
      end
    end
  end
  local sort_Status = {
    [BATTLEPASSACTIVITY_TASK_STATUS.Finished] = 0,
    [BATTLEPASSACTIVITY_TASK_STATUS.Null] = 1,
    [BATTLEPASSACTIVITY_TASK_STATUS.Recieved] = 2
  }
  table.sort(ret, function(a, b)
    local taskData_a = Data.battlepassactivityData:GetPassTaskData(a.id)
    local taskData_b = Data.battlepassactivityData:GetPassTaskData(b.id)
    local sortSt_a = sort_Status[taskData_a.Status] or 0
    local sortSt_b = sort_Status[taskData_b.Status] or 0
    if sortSt_a ~= sortSt_b then
      return sortSt_a < sortSt_b
    end
    if a.task_type ~= b.task_type then
      return a.task_type < b.task_type
    end
    if a.task_type == BATTLEPASSACTIVITY_TASK_TYPE.Rand then
      return randmap[a.id].Index < randmap[b.id].Index
    end
    if a.id ~= b.id then
      return a.id < b.id
    end
    return false
  end)
  return ret
end

function BattlePassActivityLogic:IsBattlePassActivityOpen()
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.BattlePassActivity)
  if activityId == nil or activityId <= 0 then
    return false
  end
  return true
end

return BattlePassActivityLogic
