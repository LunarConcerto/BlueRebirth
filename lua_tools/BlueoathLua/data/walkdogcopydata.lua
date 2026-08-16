local WalkDogCopyData = class("data.WalkDogCopyData", Data.BaseData)

function WalkDogCopyData:initialize()
  self:ResetData()
end

function WalkDogCopyData:ResetData()
  self.walkDogCopyData = {}
end

function WalkDogCopyData:SetData(param)
  self.walkDogCopyData = param
end

function WalkDogCopyData:GetMaxLiveTime()
  return self.walkDogCopyData.MaxLiveTime
end

function WalkDogCopyData:GetMaxSingleKill()
  return self.walkDogCopyData.MaxSingleKill
end

function WalkDogCopyData:GetMaxSingleScore()
  return self.walkDogCopyData.MaxSingleScore
end

return WalkDogCopyData
