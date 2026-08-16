local MarryLogic = class("logic.MarryLogic")
local mood_addtime, mood_normal_add, bath_add, mood_normal_limit, mood_bound, mood_marry_add
local favorData = {}
local moodData = {}
local noMarry, marryed, affection_secretaryl_limit

function MarryLogic:initialize()
  self.tab_tabPart = {}
  self:ResetData()
end

function MarryLogic:ResetData()
  mood_addtime = configManager.GetDataById("config_parameter", 139).value
  mood_normal_add = configManager.GetDataById("config_parameter", 140).value
  bath_add = configManager.GetDataById("config_parameter", 141).value
  mood_normal_limit = configManager.GetDataById("config_parameter", 144).value
  mood_bound = configManager.GetDataById("config_parameter", 142).arrValue
  mood_marry_add = configManager.GetDataById("config_parameter", 145).value
  favorData = configManager.GetData("config_affection_favor")
  moodData = configManager.GetData("config_affection_mood")
  noMarry = configManager.GetDataById("config_parameter", 155).arrValue
  marryed = configManager.GetDataById("config_parameter", 156).arrValue
  affection_secretaryl_limit = configManager.GetDataById("config_parameter", 152).value
end

function MarryLogic:GetLoveInfo(heroId, type)
  local girlData = Data.heroData:GetHeroById(heroId)
  if type == MarryType.Love then
    local loveNum = Logic.marryLogic:GetLoveNum(girlData)
    if loveNum then
      for v, k in pairs(favorData) do
        if girlData.MarryTime == 0 and k.affection_marry == 0 then
          if loveNum <= noMarry[1] then
            loveNum = noMarry[1]
          elseif loveNum >= noMarry[2] then
            loveNum = noMarry[2]
          end
          if loveNum >= k.affection_min and loveNum <= k.affection_max then
            return k, loveNum
          end
        elseif girlData.MarryTime ~= 0 and k.affection_marry == 1 then
          if loveNum <= marryed[1] then
            loveNum = marryed[1]
          elseif loveNum >= marryed[2] then
            loveNum = marryed[2]
          end
          if loveNum >= k.affection_min and loveNum <= k.affection_max then
            return k, loveNum
          end
        end
      end
    end
  elseif type == MarryType.Mood then
    local moodNum = Logic.marryLogic:GetMoodNum(girlData, heroId)
    if moodNum then
      for v, k in pairs(moodData) do
        if moodNum >= k.mood_min and moodNum <= k.mood_max then
          return k, moodNum
        end
      end
    end
  elseif type == MarryType.Kuang then
    return girlData
  end
end

function MarryLogic:GetLoveNum(girlData)
  local curTime = time.getSvrTime()
  if girlData.beforeAffectionCurTime ~= nil and curTime - girlData.beforeAffectionCurTime < 10 then
    return girlData.beforeAffection
  end
  local startTime = girlData.UpdateTime
  local createTime = time.formatTimerToHMSColon(startTime)
  local tTime = string.split(createTime, ":")
  local hour = tonumber(tTime[1])
  local deltaTime = 0
  local nearTime = 0
  local paramter = configManager.GetData("config_parameter")
  local addExp = {}
  local affection = 0
  for v, k in pairs(paramter) do
    if k.name == "affection_secretaryl_add1" then
      addExp = k.arrValue
    end
  end
  local secretaryId = Data.userData:GetSecretaryId()
  if secretaryId ~= girlData.HeroId then
    affection = girlData.Affection
  else
    hour = (hour / addExp[1] + 1) * addExp[1]
    nearTime = startTime + (hour - tonumber(tTime[1])) * 60 * 60
    deltaTime = curTime - nearTime
    if 0 <= deltaTime then
      if girlData.MarryTime == 0 and noMarry[2] < girlData.Affection + (math.floor(deltaTime / (addExp[1] * 60 * 60)) + 1) * addExp[2] then
        if 0 <= noMarry[2] - girlData.Affection then
          affection = girlData.Affection + (noMarry[2] - girlData.Affection)
        else
          affection = girlData.Affection
        end
      elseif girlData.MarryTime ~= 0 and marryed[2] < girlData.Affection + (math.floor(deltaTime / (addExp[1] * 60 * 60)) + 1) * addExp[2] then
        if 0 <= marryed[2] - girlData.Affection then
          affection = girlData.Affection + (marryed[2] - girlData.Affection)
        else
          affection = girlData.Affection
        end
      else
        affection = girlData.Affection + (math.floor(deltaTime / (addExp[1] * 60 * 60)) + 1) * addExp[2]
      end
      if affection >= affection_secretaryl_limit then
        affection = girlData.Affection
      end
    else
      affection = girlData.Affection
    end
  end
  girlData.beforeAffectionCurTime = curTime
  girlData.beforeAffection = affection
  return affection
end

function MarryLogic:GetMoodNum(girlInfo, heroId)
  local curTime = time.getSvrTime()
  if girlInfo.beforeMoodCurTime ~= nil and curTime - girlInfo.beforeMoodCurTime < 10 then
    return girlInfo.beforeMood
  end
  local createTime = time.formatTimerToHMSColon(girlInfo.UpdateTime)
  local nearTime = 0
  local deltaTime = 0
  local tTime = string.split(createTime, ":")
  local minute = tonumber(tTime[2])
  local mood = 0
  minute = math.floor(minute / mood_addtime + 1) * mood_addtime
  nearTime = girlInfo.UpdateTime + (minute - tTime[2]) * 60
  deltaTime = curTime - nearTime
  local moodAdd = 0
  if girlInfo.MarryTime ~= 0 then
    moodAdd = mood_normal_add + mood_marry_add
  else
    moodAdd = mood_normal_add
  end
  if 0 <= deltaTime then
    if mood_normal_limit < girlInfo.Mood + (math.floor(deltaTime / (mood_addtime * 60)) + 1) * moodAdd then
      if 0 <= mood_normal_limit - girlInfo.Mood then
        mood = girlInfo.Mood + (mood_normal_limit - girlInfo.Mood)
      else
        mood = girlInfo.Mood
      end
    else
      mood = girlInfo.Mood + (math.floor(deltaTime / (mood_addtime * 60)) + 1) * moodAdd
    end
  else
    mood = girlInfo.Mood
  end
  local heroBuildingMoodChange = Logic.buildingLogic:CheckoutHeroMoodChange(heroId)
  mood = mood + heroBuildingMoodChange
  if mood <= mood_bound[1] then
    mood = mood_bound[1]
  elseif mood >= mood_bound[2] then
    mood = mood_bound[2]
  end
  girlInfo.beforeMoodCurTime = curTime
  girlInfo.beforeMood = mood
  return mood
end

function MarryLogic:isCanMarry(heroId)
  local marry_cost = configManager.GetDataById("config_parameter", 162).arrValue
  local marry_allow_affection = configManager.GetDataById("config_parameter", 163).value
  local girlData = Data.heroData:GetHeroById(heroId)
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
  local ringNum = Logic.bagLogic:ItemInfoById(marry_cost[2])
  if ringNum == nil then
    ringNum = 0
  else
    ringNum = math.tointeger(ringNum.num)
  end
  if marry_allow_affection <= num and girlData.MarryTime == 0 then
    return true
  else
    return false
  end
end

function MarryLogic.GetMarryAttrBuff(heroId)
  local ret = {}
  local buffInfo = {}
  if heroId then
    local loveInfo, num1 = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
    for v, k in pairs(loveInfo.affection_value_effect) do
      buffInfo = configManager.GetDataById("config_value_effect", k)
      table.insert(ret, {
        power = loveInfo.value_effect_power[v],
        values = buffInfo.values
      })
    end
  end
  return ret
end

return MarryLogic
