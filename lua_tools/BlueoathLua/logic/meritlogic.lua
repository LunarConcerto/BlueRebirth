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

function MeritLogic:GetUserHead(userDate)
  local icon, qualityIcon, config, shipInfo
  if userDate.Fashioning then
    config = Logic.shipLogic:GetShipShowByFashionId(userDate.Fashioning)
    shipInfo = Logic.shipLogic:GetShipInfoById(userDate.Head)
  elseif userDate.SecretaryId then
    config = Logic.shipLogic:GetShipShowByHeroId(userDate.SecretaryId)
    shipInfo = Logic.shipLogic:GetShipInfoByHeroId(userDate.SecretaryId)
  end
  if config and shipInfo then
    icon = config.ship_icon5
    qualityIcon = UserHeadQualityImg[shipInfo.quality]
    return icon, qualityIcon
  end
  if userDate.Head == 0 then
    return "", ""
  end
  local shipShowInfo = Logic.shipLogic:GetShipShowById(userDate.Head)
  shipInfo = Logic.shipLogic:GetShipInfoById(userDate.Head)
  local icon = shipShowInfo.ship_icon5
  local qualityIcon = UserHeadQualityImg[shipInfo.quality]
  return icon, qualityIcon
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
