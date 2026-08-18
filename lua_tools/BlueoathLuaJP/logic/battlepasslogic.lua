local BattlePassLogic = class("logic.BattlePassLogic")

function BattlePassLogic:initialize()
end

local SpecialForBattlePassTaskGoalType = {}

function BattlePassLogic:GetTaskProcessStr(taskId)
  local ProcessStr = ""
  local ProcessVal = 0
  local cfg = configManager.GetDataById("config_battlepass_task", taskId)
  local goalType = cfg.task_goal[1]
  local specialTbl = SpecialForBattlePassTaskGoalType[goalType] or {}
  local funcGetCountMax = specialTbl.GetCountMax
  local funcGetCount = specialTbl.GetCount
  local countMax = cfg.task_goal[#cfg.task_goal]
  if funcGetCountMax ~= nil then
    countMax = funcGetCountMax(cfg)
  end
  local taskData = Data.battlepassData:GetPassTaskData(taskId)
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

function BattlePassLogic:GetPassExpMax()
  local passLevel = Data.battlepassData:GetPassLevel()
  if passLevel <= 0 then
    return 0
  end
  local levelCfg = configManager.GetDataById("config_battlepass_level", passLevel)
  return levelCfg.level_exp
end

function BattlePassLogic:GetLevelRewardList()
  local levelCfgs = configManager.GetData("config_battlepass_level")
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

function BattlePassLogic:GetDefaultBattlePassParamConfig()
  local paramCfg = configManager.GetDataById("config_battlepass_param", 1)
  return paramCfg
end

function BattlePassLogic:CanRewardGet()
  local curPassLevel = Data.battlepassData:GetPassLevel()
  for lvl = 1, curPassLevel do
    local isCan = self:CanLevelRewardGet(lvl)
    if isCan then
      return true
    end
  end
  return false
end

function BattlePassLogic:CanLevelRewardGet(passLevel)
  if self:CanLevelNormalRewardGet(passLevel) then
    return true
  end
  if self:CanLevelAdvancedRewardGet(passLevel) then
    return true
  end
  return false
end

function BattlePassLogic:CanLevelNormalRewardGet(passLevel)
  local curPassLevel = Data.battlepassData:GetPassLevel()
  if passLevel > curPassLevel then
    return false
  end
  local levelCfg = configManager.GetDataById("config_battlepass_level", passLevel)
  if levelCfg.free_level_reward > 0 and not Data.battlepassData:IsPassLevelNormalRewardGet(passLevel) then
    return true
  end
  return false
end

function BattlePassLogic:CanLevelAdvancedRewardGet(passLevel)
  local curPassLevel = Data.battlepassData:GetPassLevel()
  if passLevel > curPassLevel then
    return false
  end
  local levelCfg = configManager.GetDataById("config_battlepass_level", passLevel)
  local passType = Data.battlepassData:GetPassType()
  if passType >= BATTLEPASS_TYPE.ADVANCED and levelCfg.pay_level_reward > 0 and not Data.battlepassData:IsPassLevelAdvancedRewardGet(passLevel) then
    return true
  end
  return false
end

function BattlePassLogic:GetBattlePassMaxLevel()
  local cfgs = configManager.GetData("config_battlepass_level") or {}
  return #cfgs
end

function BattlePassLogic:GetTargetRewardLevelCfg(baselevel)
  local baselvl = baselevel or 0
  local curPassLevel = Data.battlepassData:GetPassLevel()
  local maxPassLevel = self:GetBattlePassMaxLevel()
  local startLevel = baselvl < curPassLevel and curPassLevel or baselvl
  for lvl = startLevel + 1, maxPassLevel do
    local levelCfg = configManager.GetDataById("config_battlepass_level", lvl)
    if 0 < levelCfg.target_reward then
      return levelCfg
    end
  end
  return nil
end

function BattlePassLogic:GetPerWeekPassTaskList()
  return self:GetPassTaskListByType({
    BATTLEPASS_TASK_TYPE.Const,
    BATTLEPASS_TASK_TYPE.Rand
  })
end

function BattlePassLogic:GetAchievePassTaskList()
  return self:GetPassTaskListByType({
    BATTLEPASS_TASK_TYPE.Achi
  })
end

function BattlePassLogic:GetPassTaskListByType(taskTypes)
  local ret = {}
  local tasktyps = taskTypes or {}
  local mapTyp = {}
  for _, taskType in ipairs(tasktyps) do
    mapTyp[taskType] = true
  end
  local randmap = Data.battlepassData:GetCurTaskWeekInfoRandomTaskPoolMap()
  local cfgs = configManager.GetData("config_battlepass_task") or {}
  for _, cfg in pairs(cfgs) do
    local isWant = mapTyp[cfg.task_type] or false
    if isWant then
      if cfg.task_type == BATTLEPASS_TASK_TYPE.Rand then
        if randmap[cfg.id] ~= nil then
          table.insert(ret, cfg)
        end
      else
        table.insert(ret, cfg)
      end
    end
  end
  local sort_Status = {
    [BATTLEPASS_TASK_STATUS.Finished] = 0,
    [BATTLEPASS_TASK_STATUS.Null] = 1,
    [BATTLEPASS_TASK_STATUS.Recieved] = 2
  }
  table.sort(ret, function(a, b)
    local taskData_a = Data.battlepassData:GetPassTaskData(a.id)
    local taskData_b = Data.battlepassData:GetPassTaskData(b.id)
    local sortSt_a = sort_Status[taskData_a.Status] or 0
    local sortSt_b = sort_Status[taskData_b.Status] or 0
    if sortSt_a ~= sortSt_b then
      return sortSt_a < sortSt_b
    end
    if a.task_type ~= b.task_type then
      return a.task_type < b.task_type
    end
    if a.task_type == BATTLEPASS_TASK_TYPE.Rand then
      return randmap[a.id].Index < randmap[b.id].Index
    end
    if a.id ~= b.id then
      return a.id < b.id
    end
    return false
  end)
  return ret
end

function BattlePassLogic:IsBattlePassActivityOpen()
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.BattlePass)
  if activityId == nil or activityId <= 0 then
    return false
  end
  return true
end

return BattlePassLogic
