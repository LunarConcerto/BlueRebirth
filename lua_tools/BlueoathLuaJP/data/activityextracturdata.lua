local ActivityExtractURData = class("data.ActivityExtractURData", Data.BaseData)

function ActivityExtractURData:initialize()
end

function ActivityExtractURData:SetData()
  self:ResetData()
end

function ActivityExtractURData:ResetData()
  self.data = nil
  self.drawId = 0
  self.realDrawId = 0
  self.rewardsMap = {}
end

function ActivityExtractURData:SetData(data)
  self:SetActDrawInfo(data)
end

function ActivityExtractURData:SetActDrawInfo(data)
  self.data = data
  if data.DrawId then
    self.drawId = data.DrawId
  end
  if data.RealDrawId then
    self.realDrawId = data.RealDrawId
  end
  self.rewardsMap = {}
  if data.Rewards ~= nil and #data.Rewards > 0 then
    for _, v in pairs(data.Rewards) do
      self.rewardsMap[v.RewardId] = v.Num
    end
  end
  logWarning("\230\180\187\229\138\168\230\149\176\230\141\174\239\188\154data", self.drawId, self.realDrawId, self.rewardsMap)
  eventManager:SendEvent(LuaEvent.ActExtractURUpdate)
end

function ActivityExtractURData:GetDrawID()
  return self.drawId or 0
end

function ActivityExtractURData:GetRealDrawID()
  return self.realDrawId or 0
end

function ActivityExtractURData:GetDrawRewardsMap()
  return self.rewardsMap or {}
end

function ActivityExtractURData:GetRemainCount()
  local num = 0
  for i, v in pairs(self.rewardsMap) do
    num = num + v
  end
  return num
end

function ActivityExtractURData:GetDrawRewardsData()
  return self.data
end

return ActivityExtractURData
