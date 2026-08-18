local MeritLogic = class("logic.MeritLogic")

function MeritLogic:initialize()
  self:ResetData()
end

function MeritLogic:ResetData()
end

function MeritLogic:GetExtraReward(index)
  local meritData = Data.meritData:GetData()
  if next(meritData.NumberList) == nil then
    return 0
  end
  for _, v in ipairs(meritData.NumberList) do
    if v.Index == index - 1 then
      return v.Number
    end
  end
  return 0
end

function MeritLogic:GetExtraRewardTimes(activityId)
  local activityConfig = configManager.GetDataById("config_activity", activityId)
  local times = activityConfig.p11[1]
  if Logic.userLogic:CheckMonthCardPrivilege() then
    times = times + activityConfig.p12[1]
  end
  return times
end

return MeritLogic
