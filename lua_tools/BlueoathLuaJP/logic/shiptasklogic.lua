local ShipTaskLogic = class("logic.ShipTaskLogic")

function ShipTaskLogic:initialize()
end

local function getCountMax_One(cfg)
  return 1
end

local function getCount_Hour(count)
  return Mathf.Floor(count / 3600)
end

local function getCount_Mood(count)
  return Mathf.Floor(count / 10000)
end

local function getCount_Affection(count)
  return Mathf.Floor(count / 10000)
end

SpecialForShipTaskGoalType = {
  [7] = {GetCountMax = getCountMax_One},
  [8] = {GetCountMax = getCountMax_One},
  [12] = {GetCount = getCount_Hour},
  [13] = {GetCount = getCount_Hour},
  [14] = {GetCount = getCount_Hour},
  [15] = {GetCount = getCount_Hour},
  [16] = {GetCount = getCount_Hour},
  [17] = {GetCount = getCount_Hour},
  [18] = {GetCount = getCount_Mood},
  [20] = {GetCount = getCount_Hour},
  [22] = {GetCount = getCount_Hour},
  [26] = {
    GetCountMax = function(cfg)
      return cfg.task_goal[2]
    end
  },
  [27] = {GetCount = getCount_Affection}
}

function ShipTaskLogic:GetTaskProcessStr(taskId)
  local ProcessStr = ""
  local cfg = configManager.GetDataById("config_testship_task", taskId)
  local goalType = cfg.task_goal[1]
  local specialTbl = SpecialForShipTaskGoalType[goalType] or {}
  local funcGetCountMax = specialTbl.GetCountMax
  local funcGetCount = specialTbl.GetCount
  local countMax = cfg.task_goal[#cfg.task_goal]
  if funcGetCountMax ~= nil then
    countMax = funcGetCountMax(cfg)
  end
  local count = Data.shiptaskData:GetTaskDataCount(taskId)
  if funcGetCount ~= nil then
    count = funcGetCount(count)
  end
  if countMax <= count then
    count = countMax
  end
  ProcessStr = UIHelper.GetLocString(7400003, count .. "/" .. countMax)
  return ProcessStr
end

function ShipTaskLogic:GetTabInfoList()
  local tabInfo = {}
  local data = {}
  data.TaskType = 0
  data.TaskTypeName = UIHelper.GetString(920000611)
  tabInfo[data.TaskType] = data
  local cfgs = configManager.GetData("config_testship_task")
  for _, cfg in pairs(cfgs) do
    local taskId = cfg.id
    local taskType = cfg.test_type
    local data = tabInfo[taskType]
    if data == nil then
      data = {}
      data.TaskType = taskType
      data.TaskTypeName = cfg.test_type_name
      data.TestPoint = 0
      data.TestPointSum = 0
    end
    local status = Data.shiptaskData:GetTaskStatus(taskId)
    if status == ShipTaskStatus.Reward then
      data.TestPoint = data.TestPoint + cfg.test_point
    end
    data.TestPointSum = data.TestPointSum + cfg.test_point
    tabInfo[taskType] = data
  end
  local tabInfoList = {}
  for _, data in pairs(tabInfo) do
    table.insert(tabInfoList, data)
  end
  table.sort(tabInfoList, function(a, b)
    if a.TaskType ~= b.TaskType then
      return a.TaskType < b.TaskType
    end
    return false
  end)
  return tabInfoList
end

function ShipTaskLogic:GetTaskInfoList(taskType)
  local taskInfoList = {}
  local cfgs = configManager.GetData("config_testship_task")
  for _, cfg in pairs(cfgs) do
    if cfg.test_type == taskType then
      local data = {}
      local taskId = cfg.id
      data.TaskId = taskId
      data.Config = cfg
      local status = Data.shiptaskData:GetTaskStatus(taskId)
      data.Status = status
      data.ProcessStr = self:GetTaskProcessStr(taskId)
      table.insert(taskInfoList, data)
    end
  end
  table.sort(taskInfoList, function(a, b)
    if a.Status ~= b.Status then
      local conv = {
        [ShipTaskStatus.Finish] = 1,
        [ShipTaskStatus.Accept] = 2,
        [ShipTaskStatus.Reward] = 3
      }
      local conv_a = conv[a.Status] or 0
      local conv_b = conv[b.Status] or 0
      return conv_a < conv_b
    end
    return a.TaskId < b.TaskId
  end)
  return taskInfoList
end

function ShipTaskLogic:GetAchiInfoList()
  local achiInfoList = {}
  local tabInfo = {}
  local cfgs = configManager.GetData("config_testship_task")
  for _, cfg in pairs(cfgs) do
    local taskId = cfg.id
    local taskType = cfg.test_type
    local data = tabInfo[taskType]
    if data == nil then
      data = {}
      data.TaskType = taskType
      data.TestPoint = 0
      data.TestPointSum = 0
    end
    local status = Data.shiptaskData:GetTaskStatus(taskId)
    if status == ShipTaskStatus.Reward then
      data.TestPoint = data.TestPoint + cfg.test_point
    end
    data.TestPointSum = data.TestPointSum + cfg.test_point
    tabInfo[taskType] = data
  end
  local min = -1
  local sum = 0
  for index, data in pairs(tabInfo) do
    if min < 0 then
      min = data.TestPoint
    end
    if min > data.TestPoint then
      min = data.TestPoint
    end
    sum = sum + data.TestPoint
  end
  local achiCfgs = configManager.GetData("config_testship_reward")
  for _, cfg in pairs(achiCfgs) do
    local data = {}
    local achId = cfg.id
    data.AchId = achId
    data.Config = cfg
    data.CurMinPoint = min < cfg.task_point and min or cfg.task_point
    data.CurSumPoint = sum < cfg.task_point_total and sum or cfg.task_point_total
    local isGet = Data.shiptaskData:GetAchiIsGet(achId)
    local isCond1 = min >= cfg.task_point
    local isCond2 = sum >= cfg.task_point_total
    data.IsCond1 = isCond1
    data.IsCond2 = isCond2
    data.IsCanGetReward = not isGet and isCond1 and isCond2
    table.insert(achiInfoList, data)
  end
  table.sort(achiInfoList, function(a, b)
    if a.IsCanGetReward ~= b.IsCanGetReward then
      return a.IsCanGetReward
    end
    return a.AchId < b.AchId
  end)
  return achiInfoList
end

function ShipTaskLogic:IsShipTaskFinishOver(shipTid)
  local achiCfgs = configManager.GetData("config_testship_reward")
  for _, cfg in pairs(achiCfgs) do
    local achId = cfg.id
    local isGet = Data.shiptaskData:GetShipAchiIsGet(shipTid, achId)
    if not isGet then
      return false
    end
  end
  local cfgs = configManager.GetData("config_testship_task")
  for _, cfg in pairs(cfgs) do
    local taskId = cfg.id
    local status = Data.shiptaskData:GetShipTaskStatus(shipTid, taskId)
    if status ~= ShipTaskStatus.Reward then
      return false
    end
  end
  return true
end

return ShipTaskLogic
