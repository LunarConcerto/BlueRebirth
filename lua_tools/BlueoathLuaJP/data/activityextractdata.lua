local ActivityExtractData = class("data.ActivityExtractData", Data.BaseData)

function ActivityExtractData:initialize()
  self:ResetData()
end

function ActivityExtractData:ResetData()
  self.data = nil
  self.drawId = 0
  self.realDrawId = 0
  self.rewardsMap = {}
end

function ActivityExtractData:SetData(data)
  self:SetActExtractInfo(data)
end

function ActivityExtractData:SetActExtractInfo(data)
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
  eventManager:SendEvent(LuaEvent.ActExtraUpdate)
end

function ActivityExtractData:GetDrawID()
  return self.drawId or 0
end

function ActivityExtractData:GetRealDrawID()
  return self.realDrawId or 0
end

function ActivityExtractData:GetDrawRewardsMap()
  return self.rewardsMap or {}
end

function ActivityExtractData:GetRemainCount()
  local num = 0
  for i, v in pairs(self.rewardsMap) do
    num = num + v
  end
  return num
end

function ActivityExtractData:GetDrawRewardsData()
  return self.data
end

return ActivityExtractData
