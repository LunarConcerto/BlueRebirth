local UserLogic = class("logic.UserLogic")

function UserLogic:initialize()
  eventManager:RegisterEvent(LuaEvent.UserLevelUp, self._UserLevelUp, self)
  eventManager:RegisterEvent(LuaEvent.CreaterCharacterSuccess, self._CreateUser, self)
  eventManager:RegisterEvent(LuaEvent.LoginOk, self._LoginOK, self)
end

function UserLogic:ResetData()
  self.userLevel = nil
  self.newUser = false
  self.firstLoginToday = false
end

function UserLogic:_CreateUser()
  self.newUser = true
end

function UserLogic:_LoginOK()
  if self.newUser then
    platformManager:sendUserInfo(SendUserInfoType.CreateUser)
  end
  platformManager:sendUserInfoToMtp()
end

function UserLogic:_UserLevelUp()
  local curLv = Data.userData:GetUserLevel()
  if self.userLevel == nil then
    self.userLevel = curLv
  elseif curLv > self.userLevel then
    self.userLevel = curLv
    platformManager:sendUserInfo(SendUserInfoType.LevelUp)
  end
end

function UserLogic:GetMaxExp(lv)
  if lv <= 0 then
    return 0
  end
  local lvlConfig = configManager.GetDataById("config_player_levelup", lv)
  local curLvExp = 0
  for i = 1, lv do
    local exp = configManager.GetDataById("config_player_levelup", i).exp
    curLvExp = curLvExp + exp
  end
  return curLvExp
end

function UserLogic:GetLvExp(lv)
  if lv <= 0 then
    return 0
  end
  local lvlConfig = configManager.GetDataById("config_player_levelup", lv)
  return lvlConfig.exp
end

function UserLogic:GetLvByExp(exp)
  if exp <= 0 then
    return 0
  end
  lv = 0
  while 0 <= exp do
    exp = exp - self:GetLvExp(lv + 1)
    lv = lv + 1
  end
  return lv
end

function UserLogic:CheckMonthCardPrivilege()
  local monthData = Data.rechargeData:GetRechargeData().MonthCard
  if monthData and monthData.DueDate then
    return monthData.DueDate > time.getSvrTime()
  end
  return false
end

function UserLogic:CheckBigMonthCardPrivilege()
  local bigmonthData = Data.rechargeData:GetRechargeData().SupperMonthCard
  if bigmonthData and bigmonthData.DueDate then
    return bigmonthData.DueDate > time.getSvrTime()
  end
  return false
end

function UserLogic:GetUsrLvUpRewards(oldLv, newLv)
  if newLv <= oldLv then
    return {}
  end
  local ids = {}
  for i = oldLv, newLv - 1 do
    local id = configManager.GetDataById("config_player_levelup", i).levelup_rewards
    table.insert(ids, id)
  end
  local res = Logic.rewardLogic:FormatRewards(ids)
  return res
end

function UserLogic:CheckNeedCostItem()
  local lv = Data.userData:GetUserLevel()
  local downLv = self:getChangeNameCostDown()
  return lv > downLv and self:getChangeNameCost().Num > 0, self:getChangeNameCost()
end

function UserLogic:getChangeNameCost()
  local num = configManager.GetDataById("config_parameter", 229).value
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.DIAMOND,
    Num = num
  }
end

function UserLogic:getChangeNameCostDown()
  return configManager.GetDataById("config_parameter", 230).value
end

function UserLogic:CheckChangeName(newName)
  if type(newName) ~= "string" or newName == "" then
    return false, UIHelper.GetString(290003)
  end
  local _, len = string.gsub(newName, ".[\128-\191]*", "")
  local lenMin = configManager.GetDataById("config_parameter", 65).value
  if len < lenMin then
    return false, "\232\167\146\232\137\178\229\144\141\229\164\170\231\159\173"
  end
  local oldName = Data.userData:GetUserName()
  if newName == oldName then
    return false, UIHelper.GetString(290004)
  end
  local need, costs = self:CheckNeedCostItem()
  if need and not Logic.currencyLogic:CheckCurrencyEnough(costs.ConfigId, costs.Num) then
    return false, "\233\146\187\231\159\179\228\184\141\232\182\179"
  end
  return true, ""
end

function UserLogic:GetMedalAcquiredTime(medalId, medalTab)
  for _, v in pairs(medalTab) do
    if v.MedalId == medalId then
      return v.Time
    end
  end
  return
end

function UserLogic:GetMedalIdTab(medalTab)
  local medalIdTab = {}
  table.sort(medalTab, function(a, b)
    if a.Time == b.Time then
      return a.MedalId < b.MedalId
    end
    return a.Time < b.Time
  end)
  for _, v in pairs(medalTab) do
    table.insert(medalIdTab, v.MedalId)
  end
  return medalIdTab
end

return UserLogic
