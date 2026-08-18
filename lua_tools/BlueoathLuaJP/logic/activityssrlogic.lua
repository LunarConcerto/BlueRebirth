local ActivitySSRLogic = class("logic.ActivitySSRLogic")

function ActivitySSRLogic:initialize()
  self:ResetData()
end

function ActivitySSRLogic:ResetData()
end

function ActivitySSRLogic:IsHaveSeekCount()
  self.actSSRInfo = Data.activitySSRData:GetData()
end

function ActivitySSRLogic:ActSSRRedDot()
  local tabRedDot = {}
  local actConfig = Logic.activityLogic:GetActivityBanner()
  table.sort(actConfig, function(data1, data2)
    return data1.order < data2.order
  end)
  for k, v in pairs(actConfig) do
    for key, value in pairs(v.red_dot) do
      table.insert(tabRedDot, {
        value,
        v.id
      })
    end
  end
  return tabRedDot
end

function ActivitySSRLogic:RegisterRed()
  local tabRedDot = self:ActSSRRedDot()
  for k, v in pairs(tabRedDot) do
    local result = redDotManager:GetStateById(v[1], RedDotType.Normal, {
      v[2]
    })
    if result then
      return v[1], v[2]
    end
  end
  return nil, nil
end

function ActivitySSRLogic:ActGotoPage()
  local tabRedDot = self:ActSSRRedDot()
  for k, v in pairs(tabRedDot) do
    local result = redDotManager:GetStateById(v[1], RedDotType.Normal, {
      v[2]
    })
    if result then
      return v[2]
    end
  end
  return 1
end

function ActivitySSRLogic:IsShowRedDot(openType)
  local config = Logic.activityLogic:GetOpenActivityByType(openType)
  if config and next(config) then
    local isOpen = Logic.activityLogic:IsOpenActivitySSR(config[1].id)
    local actSSRInfo = Data.activitySSRData:GetData()
    if isOpen and next(actSSRInfo) then
      local count = configManager.GetDataById("config_activity", config[1].id).p6
      local allCount = count[1]
      if actSSRInfo.DayShareCount ~= 0 then
        allCount = count[1] + count[2]
      end
      local remainCount = allCount - actSSRInfo.DaySelectCount
      if 0 < remainCount then
        return true
      end
    else
      return false
    end
  else
    return false
  end
end

return ActivitySSRLogic
