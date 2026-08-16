local TaskReturnLogic = class("logic.TaskReturnLogic")

function TaskReturnLogic:initialize()
  self.returnDay = 1
  self.returnPlayToggle = nil
  self.noOpenReturnPage = true
end

function TaskReturnLogic:ResetData()
  self.returnDay = 1
  self.returnPlayToggle = nil
end

function TaskReturnLogic:SetReturnDay(index)
  self.returnDay = index
end

function TaskReturnLogic:GetReturnDay()
  return self.returnDay
end

function TaskReturnLogic:SetReturnPlayerToggle(index)
  self.returnPlayToggle = index
end

function TaskReturnLogic:GetReturnPlayerToggle()
  return self.returnPlayToggle
end

function TaskReturnLogic:SetReturnDayActivity(_bool)
  self.noOpenReturnPage = _bool
end

function TaskReturnLogic:GetReturnByDays(dayDdata, achieveData)
  local dayTab = self:_GetConfigByDay(dayDdata)
  local achieve = self:_DisposeData(dayTab, achieveData)
  local achieveTab = {}
  local receivedTab = {}
  for v, k in pairs(achieve) do
    if k.status ~= TaskState.RECEIVED then
      table.insert(achieveTab, k)
    else
      table.insert(receivedTab, k)
    end
  end
  achieveTab = self:SortAchieve(achieveTab)
  receivedTab = self:SortReceived(receivedTab)
  table.insertto(achieveTab, receivedTab)
  return achieveTab
end

function TaskReturnLogic:_GetConfigByDay(dayDdata)
  local dayInfo = {}
  local newAchieveInfo = {}
  for v, k in pairs(dayDdata) do
    dayInfo = configManager.GetDataById("config_task_return", k)
    table.insert(newAchieveInfo, dayInfo)
  end
  return newAchieveInfo
end

function TaskReturnLogic:_DisposeData(tab, achieveData)
  local achieveResult = {}
  if #tab == 0 then
    return achieveResult
  end
  for _, v in ipairs(tab) do
    local achieveInfo = {}
    achieveInfo.config = v
    achieveInfo.achieveId = v.id
    achieveInfo.progress = 0
    achieveInfo.progressStr = "0/" .. v.goal[#v.goal]
    achieveInfo.status = TaskState.TODO
    local eventType = v.goal[1]
    if achieveData[eventType] and achieveData[eventType].List[v.id] then
      taskInfo = achieveData[eventType].List[v.id]
      achieveInfo.status = Logic.taskLogic:GetTaskState(taskInfo)
      local max = Logic.taskLogic:GetTotalCount(v.id, TaskType.Return)
      local cur = Logic.taskLogic:GetCurCount(taskInfo, max)
      achieveInfo.progress = cur / max
      achieveInfo.progressStr = cur .. " / " .. max
    end
    table.insert(achieveResult, achieveInfo)
  end
  return achieveResult
end

function TaskReturnLogic:SortAchieve(tabAchieve)
  table.sort(tabAchieve, function(data1, data2)
    if data1.progress ~= data2.progress then
      return data1.progress > data2.progress
    else
      return data1.achieveId < data2.achieveId
    end
  end)
  return tabAchieve
end

function TaskReturnLogic:SortReceived(tabAchieve)
  table.sort(tabAchieve, function(data1, data2)
    return data1.achieveId < data2.achieveId
  end)
  return tabAchieve
end

function TaskReturnLogic:IsCanShowRedDot(...)
  local userInfo = Data.userData:GetUserData()
  local curDay = userInfo.TaskReturnStage
  local num = configManager.GetData("config_return_stage")
  local achieveData = Data.taskData:GetTaskReturnData()
  if curDay > #num then
    curDay = #num
  end
  for i = 1, curDay do
    local args = configManager.GetDataById("config_return_stage", i)
    local logintabReward = {}
    table.insert(logintabReward, args.task_stage)
    local tabAchieveLogin = Logic.taskReturnLogic:GetReturnByDays(logintabReward, achieveData)
    if tabAchieveLogin[1].status == TaskState.FINISH then
      return true
    end
    local tabAchieve = Logic.taskReturnLogic:GetReturnByDays(num[i].task_return, achieveData)
    for n = 1, #tabAchieve do
      if tabAchieve[n].status == TaskState.FINISH then
        return true
      end
    end
  end
  local firstLoginToday = Data.userData:IsFirstLoginToday()
  return self.noOpenReturnPage and firstLoginToday
end

function TaskReturnLogic:IsHaveDaysRedDot(index)
  local userInfo = Data.userData:GetUserData()
  local num = configManager.GetData("config_return_stage")
  local achieveData = Data.taskData:GetTaskReturnData()
  local curDay = userInfo.TaskReturnStage
  if index > curDay then
    return false
  end
  local args = configManager.GetDataById("config_return_stage", index)
  local logintabReward = {}
  table.insert(logintabReward, args.task_stage)
  local tabAchieveLogin = Logic.taskReturnLogic:GetReturnByDays(logintabReward, achieveData)
  if tabAchieveLogin[1].status == TaskState.FINISH then
    return true
  end
  local tabAchieve = Logic.taskReturnLogic:GetReturnByDays(num[index].task_return, achieveData)
  for n = 1, #tabAchieve do
    if tabAchieve[n].status == TaskState.FINISH then
      return true
    end
  end
  return false
end

return TaskReturnLogic
