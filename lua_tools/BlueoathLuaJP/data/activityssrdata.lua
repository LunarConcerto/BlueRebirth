local ActivitySSRData = class("data.ActivitySSRData", Data.BaseData)

function ActivitySSRData:initialize()
  self:_InitHandlers()
end

function ActivitySSRData:_InitHandlers()
  self:ResetData()
end

function ActivitySSRData:ResetData()
  self.actSSRInfo = {
    DayShareCount = 0,
    RewardTime = 0,
    SelectShipId = 0,
    SaveShipId = 0,
    DaySelectCount = 0,
    ActivityId = 0
  }
end

function ActivitySSRData:SetData(param)
  self.actSSRInfo = param
end

function ActivitySSRData:GetData()
  return SetReadOnlyMeta(self.actSSRInfo)
end

return ActivitySSRData
