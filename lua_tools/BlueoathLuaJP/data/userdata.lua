local UserData = class("data.UserData", Data.BaseData)
RECOVER = {SUPPLY = 1, PVEPT = 2}
local recovertab = {
  [CurrencyType.SUPPLY] = RECOVER.SUPPLY,
  [CurrencyType.PVEPT] = RECOVER.PVEPT
}

function UserData:initialize()
  self:_InitHandlers()
end

function UserData:_InitHandlers()
  self:ResetData()
end

function UserData:ResetData()
  self.userInfo = {}
  self.loginTime = 0
  self.loginTimePre = 0
  self.medalReplaceReward = {}
end

function UserData:SetData(param)
  if next(self.userInfo) ~= nil then
    for k, v in pairs(param) do
      if self.userInfo[k] ~= nil then
        if type(v) == "table" and next(v) ~= nil then
          self.userInfo[k] = v
        elseif type(v) ~= "table" then
          self.userInfo[k] = v
        end
      else
        self.userInfo[k] = v
      end
    end
  else
    self.userInfo = param
  end
  self:SetCurrency(self.userInfo)
  self:UpdateRecoverData(self.userInfo.RecoverData)
end

function UserData:GetUserData()
  return SetReadOnlyMeta(self.userInfo)
end

function UserData:GetCurrency(currencyId)
  if currencyId == CurrencyType.PVEPT then
    local point = self.userInfo.PvePt
    return point
  end
  if currencyId == CurrencyType.STRENGTH then
    local strength = Logic.buildingLogic:RecoverStrength()
    return strength
  end
  local count = self.m_TypeNumMap[currencyId] or 0
  local curr = count
  local max = self:GetCurrencyMax(currencyId)
  if curr < max then
    local recoverNum = self:GetCoverNum(currencyId)
    curr = curr + recoverNum
    if max < curr then
      curr = max
    end
  end
  if curr ~= count then
    self.m_TypeNumMap[currencyId] = curr
  end
  return curr
end

function UserData:GetCoverNum(currencyId)
  local recoverId = recovertab[currencyId]
  if recoverId == nil then
    return 0
  end
  local t = self:GetRecoverTime(recoverId)
  if t <= 0 then
    return 0
  end
  local timeNow = time:getSvrTime()
  if t >= timeNow then
    return 0
  end
  local speed = self:GetCurrencyRecoverSpeed(currencyId)
  local n = math.floor((timeNow - t) / speed[2])
  if 0 < n then
    self:UpdateRecoverById(recoverId, t + speed[2] * n)
  end
  return n * speed[1]
end

function UserData:ChangeNameTimes()
  return self.userInfo.ChangeNameTimes
end

function UserData:GetCurrencyMax(currencyId)
  local level = self.userInfo.Level
  local lvupRec = configManager.GetDataById("config_player_levelup", level)
  if currencyId == CurrencyType.SUPPLY then
    local max = lvupRec.supply_max_limit
    if Logic.userLogic:CheckMonthCardPrivilege() then
      max = max + lvupRec.month_supply_max_add
    end
    if Logic.userLogic:CheckBigMonthCardPrivilege() then
      local bigmonthAdd = configManager.GetDataById("config_parameter", 256).value
      max = max + bigmonthAdd
    end
    return max
  elseif currencyId == CurrencyType.PVEPT then
    return lvupRec.pvept_num
  else
    return Mathf.Infinity
  end
end

function UserData:GetCurrencyRecoverSpeed(currencyId)
  if currencyId == CurrencyType.SUPPLY then
    local level = self.userInfo.Level
    local lvupRec = configManager.GetDataById("config_player_levelup", level)
    local speed = clone(lvupRec.supply_increase_speed)
    if Logic.userLogic:CheckMonthCardPrivilege() then
      local speedAdd = lvupRec.month_supply_speed_add
      if speedAdd[2] ~= speed[2] then
        logError("currency recover month config error")
      end
      speed[1] = speed[1] + speedAdd[1]
    end
    return speed
  else
    return {0, 0}
  end
end

function UserData:SetCurrency(userInfo)
  self.m_TypeNumMap = {
    [CurrencyType.GOLD] = self.userInfo.Gold,
    [CurrencyType.DIAMOND] = self.userInfo.Diamond,
    [CurrencyType.GAS] = self.userInfo.Gas,
    [CurrencyType.SUPPLY] = self.userInfo.Supply,
    [CurrencyType.MAINGUN] = self.userInfo.MainGun,
    [CurrencyType.TORPEDO] = self.userInfo.Torpedo,
    [CurrencyType.PLANE] = self.userInfo.Plane,
    [CurrencyType.OTHER] = self.userInfo.Other,
    [CurrencyType.RETIRE] = self.userInfo.Retire,
    [CurrencyType.SPA] = self.userInfo.Bath,
    [CurrencyType.STRATEGY] = self.userInfo.Strategy,
    [CurrencyType.MEDAL] = self.userInfo.Medal,
    [CurrencyType.EXERCISES] = self.userInfo.CopyTrainPoint,
    [CurrencyType.TOWER] = self.userInfo.Tower,
    [CurrencyType.FASHION] = self.userInfo.FashionPoint,
    [CurrencyType.LUCKY] = self.userInfo.Lucky,
    [CurrencyType.CONTRIBUTE] = self.userInfo.GuildContri,
    [CurrencyType.TEACHINGMERITS] = self.userInfo.TeacherMedal,
    [CurrencyType.TEACHINGPOP] = self.userInfo.TeacherPrestige,
    [CurrencyType.BATTLEPASSEXP] = self.userInfo.BattlePassExp,
    [CurrencyType.BATTLEPASSGOLD] = self.userInfo.BattlePassGold,
    [CurrencyType.PVEPT] = self.userInfo.PvePt,
    [CurrencyType.GUILD_COIN_II] = self.userInfo.GuildCoinII,
    [CurrencyType.UREQUIPCOIN] = self.userInfo.UrEquipCoin,
    [CurrencyType.ACTIVITYBATTLEPASSEXP] = self.userInfo.ActivityBattlePassExp
  }
end

function UserData:UpdateRecoverData(recoverData)
  if recoverData == nil or #recoverData < 1 then
    return
  end
  self.mRecoverData = self.mRecoverData or {}
  for i, rec in ipairs(recoverData) do
    self.mRecoverData[rec.RecoverId] = rec.RecoverTime
  end
end

function UserData:UpdateRecoverById(recoverId, time)
  self.mRecoverData = self.mRecoverData or {}
  self.mRecoverData[recoverId] = time
end

function UserData:GetRecoverTime(recoverId)
  if self.mRecoverData == nil then
    return 0
  end
  return self.mRecoverData[recoverId] or 0
end

function UserData:GetOrderRecord(index)
  local record = self.userInfo.OrderRecord[index]
  return record
end

function UserData:GetUserLevel()
  return self.userInfo.Level
end

function UserData:GetUserUid()
  return self.userInfo.Uid
end

function UserData:GetUserName()
  return self.userInfo.Uname
end

function UserData:GetUserExp()
  return self.userInfo.Exp
end

function UserData:GetSecretaryId()
  return self.userInfo.SecretaryId
end

function UserData:GetVipLevel()
  return self.userInfo.VipLevel
end

function UserData:GetCreateTime()
  return self.userInfo.CreateTime
end

function UserData:GetUserHead()
  return self.userInfo.Head
end

function UserData:GetUserGold()
  return self.userInfo.Gold
end

function UserData:GetUserHeadIcon(userDate)
  local config = configManager.GetDataById("config_profile", userDate.Head)
  if config == nil then
    logError("UserData:GetUserHead profile_config[id:%d] is nil", userDate.Head)
    local shipShowConfig = Logic.shipLogic:GetShipShowByHeroId(userDate.SecretaryId)
    if shipShowConfig then
      return shipShowConfig.ship_icon5, UserHeadQualityImg[ShipHeadQuality]
    else
      return "", ""
    end
  end
  local icon = config.image
  local qualityIcon = UserHeadQualityImg[ShipHeadQuality]
  return icon, qualityIcon
end

function UserData:SetLoginTime(data)
  self.loginTime = data.LoginTime
  self.loginTimePre = data.LoginTimePre
end

function UserData:IsFirstLoginToday()
  local timePreFormat = os.date("*t", self.loginTimePre)
  local timeFormat = os.date("*t", self.loginTime)
  local isSameDay = self.loginTime > self.loginTimePre and timePreFormat.day == timeFormat.day
  return not isSameDay
end

function UserData:GetLevel()
  if self.userInfo and self.userInfo.Level then
    return self.userInfo.Level, true
  end
  return -1, false
end

function UserData:GetTchRankPrestige()
  return self.userInfo.TchRankPrestige or 0
end

function UserData:GetPlayerHeadFrame()
  return self.userInfo.HeadFrame or 0
end

function UserData:SetMedalReplaceReward(data)
  self.medalReplaceReward = data
end

function UserData:GetMedalReplaceReward()
  return self.medalReplaceReward
end

return UserData
