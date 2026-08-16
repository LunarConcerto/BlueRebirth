local DailyCopyData = class("data.DailyCopyData", Data.BaseData)

function DailyCopyData:initialize()
  self:ResetData()
end

function DailyCopyData:ResetData()
  self.dailyCopyInfo = {}
  self.dailyGroupInfo = {}
end

function DailyCopyData:SetData(param)
  for i = 1, #param.ArrDailyCopyInfo do
    self.dailyCopyInfo[param.ArrDailyCopyInfo[i].ChapterId] = param.ArrDailyCopyInfo[i]
  end
  local dailyGroupInfo = param.ArrDailyGroupInfo
  for i = 1, #dailyGroupInfo do
    self.dailyGroupInfo[dailyGroupInfo[i].DailyGroupId] = dailyGroupInfo[i].SuccessTimes
  end
end

function DailyCopyData:GetDailyCopyData()
  return self.dailyCopyInfo
end

function DailyCopyData:GetSuccessTimesById(dailyGroupId)
  return self.dailyGroupInfo[dailyGroupId] or 0
end

return DailyCopyData
