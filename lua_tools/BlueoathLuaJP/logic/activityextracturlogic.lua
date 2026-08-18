local ActivityExtractURLogic = class("logic.ActivityExtractURLogic")

function ActivityExtractURLogic:initialize()
end

function ActivityExtractURLogic:SortDrawLists(poolId)
  local poolConf = configManager.GetDataById("config_activity_extract_ur", poolId)
  local tab_key = {}
  local tab_common = {}
  local tab_superise = {}
  local keyMap = {}
  for i, v in pairs(poolConf.reward_key) do
    keyMap[v] = true
  end
  for i, v in pairs(poolConf.drop_reward_id) do
    if keyMap[v[1]] == true then
      table.insert(tab_key, v)
    else
      table.insert(tab_common, v)
    end
  end
  table.insert(tab_superise, poolConf.surprise_drop)
  return tab_key, tab_common, tab_superise
end

function ActivityExtractURLogic:GetDrawAllNum(poolId)
  local poolConf = configManager.GetDataById("config_activity_extract_ur", poolId)
  local num = 0
  for i, v in pairs(poolConf.drop_reward_id) do
    num = num + v[2]
  end
  return num
end

function ActivityExtractURLogic:CheckHaveGotKey(poolId)
  local poolConf = configManager.GetDataById("config_activity_extract_ur", poolId)
  local restList = Data.activityExtractURData:GetDrawRewardsMap()
  for k, rewardId in pairs(poolConf.reward_key) do
    if restList[rewardId] == nil or restList[rewardId] <= 0 then
      return true
    end
  end
  return false
end

function ActivityExtractURLogic:CheckHaveGotAllKey(poolId)
  local poolConf = configManager.GetDataById("config_activity_extract_ur", poolId)
  local restList = Data.activityExtractURData:GetDrawRewardsMap()
  for k, rewardId in pairs(poolConf.reward_key) do
    if restList[rewardId] ~= nil and 0 < restList[rewardId] then
      return false
    end
  end
  return true
end

function ActivityExtractURLogic:FormatRewardsByURIds(poolId, rewardIdList)
  local poolConf = configManager.GetDataById("config_activity_extract_ur", poolId)
  local infoMap = {}
  for _, v in pairs(poolConf.drop_reward_id) do
    infoMap[v[1]] = v[#v]
  end
  local s = poolConf.surprise_drop
  infoMap[s[1]] = s[#s]
  local r_tbl = {}
  for _, rewardId in pairs(rewardIdList) do
    local Quality_UR = infoMap[rewardId] or 0
    local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    for _, v in pairs(rewards) do
      v.Quality_UR = Quality_UR
      table.insert(r_tbl, v)
    end
  end
  return r_tbl
end

return ActivityExtractURLogic
