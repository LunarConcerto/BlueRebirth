local ActivityValentineData = class("data.ActivityValentineData")

function ActivityValentineData:initialize()
  self.valentineData = {}
end

function ActivityValentineData:SetValentineData(data)
  self.valentineData = data
end

function ActivityValentineData:GetGotValentineRewardTime()
  if self.valentineData == nil or next(self.valentineData) == nil then
    return 0
  end
  return self.valentineData.GotRewardTime
end

return ActivityValentineData
