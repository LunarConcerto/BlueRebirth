local ActivityRollsData = class("data.ActivityRollsData", Data.BaseData)
ActivityRollsSelect = {CHOOSE_SAVE_OLD = 1, CHOOSE_SELECT_NEW = 2}

function ActivityRollsData:initialize()
  self:_InitHandlers()
end

function ActivityRollsData:_InitHandlers()
  self:ResetData()
end

function ActivityRollsData:ResetData()
  self.actRollsInfo = {
    ActivityId = 0,
    DaySelectCount = 0,
    RewardTime = 0,
    SelectShipTeam = {
      ShipId = {}
    },
    SaveShipTeam = {
      ShipId = {}
    }
  }
  self.havedata = false
end

function ActivityRollsData:SetData(param)
  self.havedata = true
  self.actRollsInfo = param
end

function ActivityRollsData:GetData()
  return SetReadOnlyMeta(self.actRollsInfo)
end

function ActivityRollsData:GetRollsFreshState()
  return self.havedata
end

return ActivityRollsData
