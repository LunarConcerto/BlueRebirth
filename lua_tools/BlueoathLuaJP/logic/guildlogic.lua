local GuildLogic = class("logic.GuildLogic")

function GuildLogic:initialize()
  self.cache_GuildPageToggleIndex = 0
  self.cache_GuildTaskPartialToggleIndex = 0
  self.cache_GuildMemberSort_Sort = 0
  self.cache_GuildMemberSort_Index = 0
  self.rewardTab = nil
  self.guildRewardTab = nil
  self.pointsBoxImgs = {}
  self:ResetData()
end

function GuildLogic:ResetData()
  self.bigActCfg = configManager.GetDataById("config_activity", ActivityType.GuildBigAct)
  self.bigActPeriod = {}
  for k, v in pairs(self.bigActCfg.p1) do
    self.bigActPeriod[k] = configManager.GetDataById("config_period", v)
  end
  self.bigActRankRewards = {}
  self.bigActRankRewardsCount = 0
  local bigActRankRewardsCfg = configManager.GetData("config_guildactivityrankreward")
  for _, v in pairs(bigActRankRewardsCfg) do
    for i = v.ranklist[1], v.ranklist[2] do
      self.bigActRankRewards[i] = v.reward
    end
    self.bigActRankRewardsCount = self.bigActRankRewardsCount + 1
  end
  self.curAddition = {}
  self.curPeriod = {}
  self.nextAddition = {}
  self.nextPeriod = {}
  local config = configManager.GetDataById("config_activity", ActivityType.GuildWarAct)
  self.curPeriod, self.curAddition = self:RecombinDamageAddition(config.p6)
  self.nextPeriod, self.nextAddition = self:RecombinDamageAddition(config.p7)
end

function GuildLogic:GetUserPostConfig()
  local myGuild = Data.guildData:getMyGuildInfo()
  local post = myGuild:getPost()
  local cfg = configManager.GetDataById("config_guildpost", GuildPostCfgID[post])
  return cfg
end

function GuildLogic:GetGuildParamConfig()
  local paramRec = configManager.GetDataById("config_guildparam", GUILD_PARAM_DEFAULT)
  return paramRec
end

function GuildLogic:GetGuildofferRankRewardConfig()
  if self.rewardTab ~= nil then
    return self.rewardTab
  end
  local rewardTab = {}
  local paramRec = configManager.GetData("config_guildoffer_rankreward")
  for _, v in pairs(paramRec) do
    rewardTab[v.id] = v
    if #v.rankid ~= 2 then
      logError("guildoffer_rankreward id[%d] rankid is error", v.id)
    end
  end
  return rewardTab
end

function GuildLogic:GetGuildofferGuildRankRewardConfig()
  if self.guildRewardTab ~= nil then
    return self.guildRewardTab
  end
  local guildRewardTab = {}
  local paramRec = configManager.GetData("config_guildoffer_guildrankreward")
  for _, v in pairs(paramRec) do
    guildRewardTab[v.id] = v
    if #v.rankid ~= 2 then
      logError("guildoffer_guildrankreward id[%d] rankid is error", v.id)
    end
  end
  return guildRewardTab
end

function GuildLogic:GetPointsBoxImgByCount(count)
  if #self.pointsBoxImgs <= 0 then
    local paramRec = configManager.GetData("config_guildboxparam")
    if #paramRec == 1 then
      if paramRec[1].num ~= 0 then
        logError("config_guildboxparam num[0] is Error")
      end
      self.pointsBoxImgs[1] = paramRec[1].image
    else
      for i = 1, #paramRec - 1 do
        local nextRec = configManager.GetDataById("config_guildboxparam", paramRec[i].id + 1)
        for j = paramRec[i].num, nextRec.num - 1 do
          self.pointsBoxImgs[j] = paramRec[i].image
        end
      end
      self.pointsBoxImgs[paramRec[#paramRec].num] = paramRec[#paramRec].image
    end
  end
  if count > #self.pointsBoxImgs then
    count = #self.pointsBoxImgs
  end
  return self.pointsBoxImgs[count]
end

function GuildLogic:GetBigActCfg()
  return self.bigActCfg
end

function GuildLogic:GetBigActScoreItem()
  return self.bigActCfg.p2[1]
end

function GuildLogic:GetBigActMultipleItem()
  return self.bigActCfg.p3[1]
end

function GuildLogic:GetBigActPeriod()
  return self.bigActPeriod
end

function GuildLogic:CheckBigActIsInPeriod(index)
  if self.bigActCfg.p1[index] == nil then
    return false
  end
  local now = time.getSvrTime()
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(self.bigActCfg.p1[index])
  if now >= startTime and now <= endTime then
    return true
  end
  return false
end

function GuildLogic:CheckBigActPeriodGetReward(index)
  if self.bigActCfg.p1[index] == nil then
    return false
  end
  local now = time.getSvrTime()
  local startTime, _ = PeriodManager:GetStartAndEndPeriodTime(self.bigActCfg.p1[index])
  if now >= startTime then
    return true
  end
  return false
end

function GuildLogic:GetBigActPeriodTime(index)
  if self.bigActCfg.p1[index] == nil then
    return "", ""
  end
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(self.bigActCfg.p1[index])
  local startStr = time.formatTimeToMD1(startTime)
  local endStr = time.formatTimeToMD1(endTime)
  return startStr, endStr
end

function GuildLogic:GetBigActRankRewardByNum(numb)
  return self.bigActRankRewards[numb]
end

function GuildLogic:GetBigActRankRewardCount()
  return self.bigActRankRewardsCount
end

function GuildLogic:RecombinDamageAddition(configure)
  local addition = {}
  local period = {}
  if 0 < #configure then
    for _, v in pairs(configure) do
      if addition[v[2]] == nil then
        addition[v[2]] = {}
        table.insert(period, v[2])
      end
      table.insert(addition[v[2]], v[1])
    end
  end
  table.sort(period, function(data1, data2)
    if data1 ~= data2 then
      return data1 < data2
    end
    return false
  end)
  return period, addition
end

function GuildLogic:GetPeriodAdditionByPeriod(period)
  if period == 1 then
    return self.curPeriod
  else
    return self.nextPeriod
  end
end

function GuildLogic:GetPeriodAdditionFleet(period, rate)
  if period == 1 then
    return self.curAddition[rate]
  else
    return self.nextAddition[rate]
  end
end

return GuildLogic
