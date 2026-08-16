local MilestoneData = class("data.MilestoneData", Data.BaseData)

function MilestoneData:initialize()
  self.data = {}
end

function MilestoneData:SetData(data)
  if data.MilestoneSub then
    for i, milestoneSub in ipairs(data.MilestoneSub) do
      self.data[milestoneSub.ActivityId] = {}
      for i, milestoneSubReward in ipairs(milestoneSub.MilestoneSubReward) do
        self.data[milestoneSub.ActivityId][milestoneSubReward.Index] = milestoneSubReward.Time
      end
    end
  end
end

function MilestoneData:GetTimeById(activityId, index)
  if not self.data[activityId] then
    return 0
  end
  return self.data[activityId][index] or 0
end

return MilestoneData
