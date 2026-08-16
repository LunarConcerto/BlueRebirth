local AchieveLogic = class("logic.AchieveLogic")

function AchieveLogic:initialize()
  self.achieveIndex = 0
  self.achieveDay = 1
  self.newPlayToggle = nil
end

function AchieveLogic:ResetData()
  self.achieveIndex = 0
  self.achieveDay = 1
  self.newPlayToggle = nil
end

function AchieveLogic:SetAchieveIndex(index)
  self.achieveIndex = index
end

function AchieveLogic:GetAchieveIndex()
  return self.achieveIndex
end

function AchieveLogic:SetAchieveDay(index)
  self.achieveDay = index
end

function AchieveLogic:GetAchieveDay()
  return self.achieveDay
end

function AchieveLogic:GetAchieveByType(mType, achieveData)
  local typeTab = self:_GetConfigByType(mType)
  local achieveTab, receivedTab = self:_DisposeConfig(typeTab, achieveData)
  local achieve = self:_DisposeData(achieveTab, achieveData)
  local received = self:_DisposeData(receivedTab, achieveData)
  achieve = self:SortAchieve(achieve)
  received = self:SortReceived(received)
  table.insertto(achieve, received)
  return achieve
end

function AchieveLogic:GetAchieveByDays(dayDdata, achieveData)
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

function AchieveLogic:_GetConfigByDay(dayDdata)
  local dayInfo = {}
  local newAchieveInfo = {}
  for v, k in pairs(dayDdata) do
    dayInfo = configManager.GetDataById("config_achievement", k)
    table.insert(newAchieveInfo, dayInfo)
  end
  return newAchieveInfo
end

function AchieveLogic:_GetConfigByType(mType)
  local configTab = configManager.GetData("config_achievement")
  local achieveTab = {}
  for _, config in pairs(configTab) do
    if config.type ~= mType or config.visible_parm == 1 and not isIOS then
    else
      achieveTab[config.id] = config
    end
  end
  return achieveTab
end

function AchieveLogic:_DisposeData(tab, achieveData)
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
      local max = Logic.taskLogic:GetTotalCount(v.id, TaskType.Achieve)
      local cur = Logic.taskLogic:GetCurCount(taskInfo, max)
      achieveInfo.progress = cur / max
      achieveInfo.progressStr = cur .. " / " .. max
    end
    table.insert(achieveResult, achieveInfo)
  end
  return achieveResult
end

function AchieveLogic:_DisposeConfig(configTab, achieveData, showAll)
  local receivedTab = {}
  local achieveTab = self:_DisposeTypeConfig(configTab, achieveData)
  for _, v in pairs(configTab) do
    local eventType = v.goal[1]
    if achieveData[eventType] and achieveData[eventType].List[v.id] and achieveData[eventType].List[v.id].RewardTime ~= 0 then
      table.insert(receivedTab, v)
    elseif v.type_id == -1 then
      if v.if_invisible == 1 and achieveData[eventType] and achieveData[eventType].List[v.id] and achieveData[eventType].List[v.id].FinishTime ~= 0 then
        table.insert(achieveTab, v)
      elseif showAll then
        if v.if_invisible ~= 1 then
          table.insert(achieveTab, v)
        end
      elseif v.if_invisible ~= 1 and achieveData[eventType] and achieveData[eventType].List[v.id] then
        table.insert(achieveTab, v)
      end
    end
  end
  return achieveTab, receivedTab
end

function AchieveLogic:_DisposeTypeConfig(configTab, achieveData)
  local achieveTab = {}
  local typeConfig = configManager.GetData("config_achievement_type_id")
  for _, v in pairs(typeConfig) do
    for _, k in ipairs(v.id) do
      if not configTab[k] or configTab[k].type_id ~= v.type_id then
        break
      end
      local eventType = configTab[k].goal[1]
      if not (achieveData[eventType] and achieveData[eventType].List[k]) or achieveData[eventType].List[k].RewardTime == 0 then
        table.insert(achieveTab, configTab[k])
        break
      end
    end
  end
  return achieveTab
end

function AchieveLogic:SortAchieve(tabAchieve)
  table.sort(tabAchieve, function(data1, data2)
    if data1.progress ~= data2.progress then
      return data1.progress > data2.progress
    else
      return data1.achieveId < data2.achieveId
    end
  end)
  return tabAchieve
end

function AchieveLogic:SortReceived(tabAchieve)
  table.sort(tabAchieve, function(data1, data2)
    return data1.achieveId < data2.achieveId
  end)
  return tabAchieve
end

function AchieveLogic:GetReceivedCount(mType, achieveData)
  local count = 0
  local configTab = configManager.GetData("config_achievement")
  for _, v in pairs(configTab) do
    local eventType = v.goal[1]
    if v.type == mType and achieveData[eventType] and achieveData[eventType].List[v.id] and achieveData[eventType].List[v.id].RewardTime ~= 0 then
      count = count + 1
    end
  end
  return count
end

function AchieveLogic:_GetAchieveMedal(achieveId)
  local medalInfo = {}
  local medalId = configManager.GetDataById("config_achievement", achieveId).medal_id
  if medalId == 0 then
    return medalInfo
  end
  medalInfo.Type = GoodsType.MEDAL
  medalInfo.ConfigId = medalId
  medalInfo.Num = 1
  return medalInfo
end

function AchieveLogic:SetNewPlayerToggle(index)
  self.newPlayToggle = index
end

function AchieveLogic:GetNewPlayerToggle()
  return self.newPlayToggle
end

function AchieveLogic:IsCumuActivityNotFinish(activityId)
  local activityCfg = configManager.GetDataById("config_activity", activityId)
  if activityCfg.is_open == 0 then
    return false
  end
  local inPeriod = true
  if 0 < activityCfg.period then
    inPeriod = PeriodManager:IsInPeriod(activityCfg.period)
  elseif 0 < #activityCfg.period_list then
    for i, pid in ipairs(activityCfg.period_list) do
      if PeriodManager:IsInPeriod(pid) then
        inPeriod = true
        break
      end
    end
  end
  return inPeriod
end

function AchieveLogic:IsCumuActivityReceviable(achieveType)
  local achieveData = Data.taskData:GetAchieveData()
  local typeTab = self:_GetConfigByType(achieveType)
  local achieveTab, receivedTab = self:_DisposeConfig(typeTab, achieveData)
  local receivable = false
  for _, v in ipairs(achieveTab) do
    local eventType = v.goal[1]
    if achieveData[eventType] and achieveData[eventType].List[v.id] then
      taskInfo = achieveData[eventType].List[v.id]
      if taskInfo and taskInfo.FinishTime ~= 0 then
        receivable = true
        break
      end
    end
  end
  return receivable
end

function AchieveLogic:IsCumuRechargeReceviable()
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.CumuRecharge)
  if not activityId then
    return false
  end
  local listDatas = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, activityId)
  for i, data in ipairs(listDatas) do
    if data.Data.FinishTime > 0 and data.Data.RewardTime == 0 then
      return true
    end
  end
  return false
end

function AchieveLogic:GetCumuActivityData(achieveType)
  local achieveData = Data.taskData:GetAchieveData()
  local typeTab = self:_GetConfigByType(achieveType)
  local achieveTab, receivedTab = self:_DisposeConfig(typeTab, achieveData, true)
  local achieve = self:_DisposeData(achieveTab, achieveData)
  local received = self:_DisposeData(receivedTab, achieveData)
  achieve = self:SortAchieve(achieve)
  received = self:SortReceived(received)
  local result = {}
  for i = 1, #achieve do
    table.insert(result, achieve[i])
  end
  table.insertto(result, received)
  return result
end

return AchieveLogic
