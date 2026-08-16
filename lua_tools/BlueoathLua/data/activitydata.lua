local ActivityData = class("data.ActivityData", Data.BaseData)

function ActivityData:initialize()
  self:_InitHandlers()
end

function ActivityData:_InitHandlers()
  self:ResetData()
end

function ActivityData:ResetData()
  self.activityData = {}
  self.activityTypeData = {}
  self.signData = {}
  self.tag = 0
  self.Time = 0
  self.Version = 0
  self.actFashionData = {
    BuyCount = 0,
    ActivityId = 0,
    SpecialReward = {}
  }
end

function ActivityData:UpdateActivityInfo(info)
  if info.Time and info.Version then
    if self.Time > info.Time then
      return
    end
    if self.Time == info.Time and self.Version >= info.Version then
      return
    end
    self.Time = info.Time
    self.Version = info.Version
  end
  self.activityData = {}
  self.activityTypeData = {}
  for i, activityId in ipairs(info.ActivityIdList) do
    self.activityData[activityId] = true
  end
end

function ActivityData:IsActivityOpen(activityId)
  return self.activityData[activityId] or false
end

function ActivityData:SetTag(tag)
  self.tag = tag
end

function ActivityData:GetTag()
  return self.tag
end

function ActivityData:SetSignData(params)
  self.signData = params
end

function ActivityData:GetSignCount()
  return self.signData.SignCount or 0
end

function ActivityData:GetLastSignTime()
  return self.signData.SignTime or time.getSvrTime()
end

function ActivityData:GetSignReward()
  return self.signData.Reward or {}
end

function ActivityData:GetActivityData()
  return self.activityData
end

function ActivityData:SetActFashionData(params)
  self.actFashionData = params
end

function ActivityData:GetActFashionData()
  return self.actFashionData
end

return ActivityData
