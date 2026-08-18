local ActivityExtractLogic = class("logic.ActivityExtractLogic")

function ActivityExtractLogic:initialize()
  self:ResetData()
end

function ActivityExtractLogic:ResetData()
end

function ActivityExtractLogic:GetActivityDrawJackpot(curPoolId)
  local curPoolConf = configManager.GetDataById("config_activity_extract", curPoolId)
  if #curPoolConf.reward_key == 0 then
    return 0
  end
  local restList = Data.activityExtractData:GetDrawRewardsMap()
  for k, rewardId in pairs(curPoolConf.reward_key) do
    if restList[rewardId] ~= nil and 0 < restList[rewardId] then
      return false
    end
  end
  return true
end

function ActivityExtractLogic:GetActivityRunOut(curPoolId)
  local restList = Data.activityExtractData:GetDrawRewardsMap()
  local haveRest = false
  for i, v in pairs(restList) do
    if 0 < v then
      haveRest = true
    end
  end
  return not haveRest
end

function ActivityExtractLogic:GetPassCopyEffectAll()
  local copyIdList = Data.copyData:GetCopyProcessInfo()
  local seacopy_type = 0
  local activityOpen = Logic.activityLogic:CheckOpenActivityByType(ActivityType.Actyishi)
  if activityOpen then
    local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.Actyishi)
    if actId == nil or actId <= 0 then
      logError(" No ActivityOpen ! ActType:", ActivityType.Actyishi)
      return
    end
    local activityConfig = configManager.GetDataById("config_activity", actId)
    seacopy_type = activityConfig.seacopy_type
  end
  local tabTemp = {}
  local chaterConf = configManager.GetData("config_chapter")
  for k, v in pairs(chaterConf) do
    if v.class_type == seacopy_type then
      for _, cid in pairs(v.level_list) do
        tabTemp[cid] = true
      end
    end
  end
  local countList = {}
  local effectList = {}
  local effectAddList = {}
  for id, info in pairs(copyIdList) do
    local count = Data.copyData:GetPassCopyCountById(id)
    if tabTemp[id] == true then
      countList[id] = count
    end
  end
  for id, count in pairs(countList) do
    local copyDisplay = configManager.GetDataById("config_copy_display", id)
    local valueList = copyDisplay.copy_activity_value
    for _, valueinfo in pairs(valueList) do
      if count >= valueinfo[1] then
        table.insert(effectList, valueinfo[2])
        table.insert(effectAddList, valueinfo[3])
      end
    end
  end
  local effValue = {}
  local effDescid = {}
  for index, effectid in pairs(effectList) do
    local effectconf = configManager.GetDataById("config_value_effect", effectid)
    local type = effectconf.activity_effect_type
    if type ~= 0 then
      local orinum = effValue[type] or 0
      local totalnum = orinum + math.floor(effectconf.activity_value_show[1] * effectAddList[index])
      effValue[type] = totalnum
      effDescid[type] = effectid
    end
  end
  local tabSort = {}
  for type, num in pairs(effValue) do
    table.insert(tabSort, type)
  end
  table.sort(tabSort, function(a, b)
    return a < b
  end)
  return effValue, effDescid, tabSort
end

function ActivityExtractLogic:SortRandomList(drop_rewardList, restList)
  local pre = {}
  local next = {}
  for i, v in pairs(drop_rewardList) do
    if restList[v[1]] ~= nil and restList[v[1]] > 0 then
      table.insert(pre, v)
    else
      table.insert(next, v)
    end
  end
  for i, v in pairs(next) do
    table.insert(pre, v)
  end
  return pre
end

function ActivityExtractLogic:GetDayLeft(actId)
  local actConf = configManager.GetDataById("config_activity", actId)
  local startTime, endTime = PeriodManager:GetPeriodTime(actConf.period, actConf.period_area)
  local deltaDay = time.getDaysDiff(endTime, true)
  return deltaDay
end

function ActivityExtractLogic:GetRewardLeft(curPoolId)
  local curPoolConf = configManager.GetDataById("config_activity_extract", curPoolId)
  local drop_reward_id = curPoolConf.drop_reward_id
  local restList = Data.activityExtractData:GetDrawRewardsMap()
  local total = 0
  for i, v in pairs(drop_reward_id) do
    total = total + v[2]
  end
  local rest = 0
  for i, v in pairs(restList) do
    rest = rest + v
  end
  local str = rest .. "/" .. total
  return str
end

function ActivityExtractLogic:GetJackpotMap(curPoolId)
  local reward = {}
  local curPoolConf = configManager.GetDataById("config_activity_extract", curPoolId)
  if #curPoolConf.reward_key == 0 then
    return reward
  end
  for k, rewardId in pairs(curPoolConf.reward_key) do
    local rinfo = configManager.GetDataById("config_rewards", rewardId).rewards[1]
    table.insert(reward, rinfo)
  end
  return reward
end

function ActivityExtractLogic:GetDrawJackPot(curPoolId, rewards)
  local JackRewards = self:GetJackpotMap(curPoolId)
  for k, JackReward in pairs(JackRewards) do
    for k, v in pairs(rewards) do
      if v.Type == JackReward[1] and v.ConfigId == JackReward[2] then
        return true
      end
    end
  end
  return false
end

function ActivityExtractLogic:_ClickShowDetail()
  local _, _, tabSort = self:GetPassCopyEffectAll()
  if #tabSort == 0 then
    noticeManager:ShowMsgBox(6100072)
    return
  end
  UIHelper.OpenPage("CopyProcessDetailsPage")
end

function ActivityExtractLogic:_GetCopyProcessPercent(copyid)
  local processdata = Data.copyData:GetPassCopyCountById(copyid)
  local copyDisplay = configManager.GetDataById("config_copy_display", copyid)
  local processList = copyDisplay.copy_progress
  local totalNum = processList[2]
  if totalNum == nil then
    return ""
  end
  if processdata > totalNum then
    processdata = totalNum
  end
  local num = processdata * 100 / totalNum
  local txt = num .. "%"
  return txt, processdata / totalNum
end

function ActivityExtractLogic:ResetData()
end

return ActivityExtractLogic
