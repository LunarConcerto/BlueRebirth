local ShipTaskData = class("data.ShipTaskData")
ShipTaskStatus = {
  Accept = 0,
  Finish = 1,
  Reward = 2
}

function ShipTaskData:initialize()
  self.mShipTaskData = {}
  self.mShipAchiData = {}
  self.mCurrentShipTid = 0
  self.mCurrentHeroTemplateId = 0
  self.mSetShipTime = 0
  self.mExtraMvpData = {}
end

function ShipTaskData:SetAchieveData(data)
  if data == nil then
    return
  end
  local shipInfo = data.info
  for i = 1, #shipInfo do
    local TRet = shipInfo[i]
    local shipTid = TRet.ShipTid
    local mAchiData = self.mShipAchiData[shipTid] or {}
    if TRet.AchievementRewardData ~= nil and #TRet.AchievementRewardData > 0 then
      for _, data in ipairs(TRet.AchievementRewardData) do
        if data.STAid == nil or 0 >= data.STAid then
          mAchiData = {}
        else
          mAchiData[data.STAid] = data
        end
      end
    end
    self.mShipAchiData[shipTid] = mAchiData
  end
end

function ShipTaskData:UpdateData(TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  local shipTid = TRet.ShipTid or 0
  if shipTid <= 0 then
    logError("err ship tid")
    return
  end
  local mTaskData = self.mShipTaskData[shipTid] or {}
  if TRet.TaskData ~= nil and 0 < #TRet.TaskData then
    for _, taskdata in ipairs(TRet.TaskData) do
      if taskdata.TaskId == nil or 0 >= taskdata.TaskId then
        mTaskData = {}
      else
        mTaskData[taskdata.TaskId] = taskdata
      end
    end
  end
  self.mShipTaskData[shipTid] = mTaskData
  local mAchiData = self.mShipAchiData[shipTid] or {}
  if TRet.AchievementRewardData ~= nil and 0 < #TRet.AchievementRewardData then
    for _, data in ipairs(TRet.AchievementRewardData) do
      if data.STAid == nil or 0 >= data.STAid then
        mAchiData = {}
      else
        mAchiData[data.STAid] = data
      end
    end
  end
  self.mShipAchiData[shipTid] = mAchiData
  local mMvpData = self.mExtraMvpData[shipTid] or {}
  if TRet.ExtraMvpData ~= nil and 0 < #TRet.ExtraMvpData then
    for _, data in ipairs(TRet.ExtraMvpData) do
      if data.CopyId == nil or 0 >= data.CopyId then
        mMvpData = {}
      else
        mMvpData[data.CopyId] = data.Count
      end
    end
  end
  self.mExtraMvpData[shipTid] = mMvpData
end

function ShipTaskData:UpdateActivityData(TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  if TRet.CurrentShipTid ~= nil then
    self.mCurrentShipTid = TRet.CurrentShipTid
  end
  if TRet.SetShipTime ~= nil then
    self.mSetShipTime = TRet.SetShipTime
  end
  if TRet.CurrentHeroTemplateId ~= nil then
    self.mCurrentHeroTemplateId = TRet.CurrentHeroTemplateId
  end
end

function ShipTaskData:GetCurrentShipTid()
  return self.mCurrentShipTid or 0
end

function ShipTaskData:GetCurrentHeroTemplateId()
  return self.mCurrentHeroTemplateId or 0
end

function ShipTaskData:GetSetShipTime()
  return self.mSetShipTime or 0
end

function ShipTaskData:GetTaskData(shipTid, taskId)
  local mTaskData = self.mShipTaskData[shipTid] or {}
  local taskData = mTaskData[taskId]
  return taskData
end

function ShipTaskData:GetAchiData(shipTid, achId)
  local mAchiData = self.mShipAchiData[shipTid] or {}
  local achiData = mAchiData[achId]
  return achiData
end

function ShipTaskData:GetShipTaskStatus(shipTid, taskId)
  if shipTid <= 0 then
    return ShipTaskStatus.Accept
  end
  local taskData = self:GetTaskData(shipTid, taskId)
  if taskData == nil then
    return ShipTaskStatus.Accept
  end
  return taskData.Status
end

function ShipTaskData:GetTaskStatus(taskId)
  local shipTid = self:GetCurrentShipTid()
  return self:GetShipTaskStatus(shipTid, taskId)
end

function ShipTaskData:GetTaskDataCount(taskId)
  local shipTid = self:GetCurrentShipTid()
  if shipTid <= 0 then
    return 0
  end
  local taskData = self:GetTaskData(shipTid, taskId)
  if taskData == nil then
    return 0
  end
  return taskData.Count
end

function ShipTaskData:GetShipAchiIsGet(shipTid, achId)
  if shipTid <= 0 then
    return false
  end
  local achiData = self:GetAchiData(shipTid, achId)
  if achiData == nil then
    return false
  end
  return 0 < achiData.Get
end

function ShipTaskData:GetAchiIsGet(achId)
  local shipTid = self:GetCurrentShipTid()
  return self:GetShipAchiIsGet(shipTid, achId)
end

function ShipTaskData:GetExtraMvpCount(copyId)
  local shipTid = self:GetCurrentShipTid()
  if shipTid <= 0 then
    return 0
  end
  local mMvpData = self.mExtraMvpData[shipTid] or {}
  local count = mMvpData[copyId] or 0
  return count
end

return ShipTaskData
