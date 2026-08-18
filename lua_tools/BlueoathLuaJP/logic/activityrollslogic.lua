local ActivityRollsLogic = class("logic.ActivityRollsLogic")

function ActivityRollsLogic:initialize()
  self:ResetData()
end

function ActivityRollsLogic:ResetData()
end

function ActivityRollsLogic:IsHaveSeekCount()
  self.actRollsInfo = Data.activitySSRData:GetData()
end

function ActivityRollsLogic:IsShowRedDot(actType)
  local config = Logic.activityLogic:GetOpenActivityByType(actType)
  if not config or next(config) then
  end
end

return ActivityRollsLogic
