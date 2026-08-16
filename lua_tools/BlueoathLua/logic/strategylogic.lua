local StrategyLogic = class("logic.StrategyLogic")

function StrategyLogic:initialize()
  self:ResetData()
end

function StrategyLogic:ResetData()
end

function StrategyLogic:GetAllStrategy()
  local strategyConfig = configManager.GetData("config_strategy")
  table.sort(strategyConfig, function(data1, data2)
    if data1.order ~= data2.order then
      return data1.order < data2.order
    else
      return data1.id < data2.id
    end
  end)
  return strategyConfig
end

function StrategyLogic:IsStrategyApply(strategyId)
  for i = 1, Fleet.Max do
    local fleetInfo = Data.fleetData:GetFleetDataById(i)
    if fleetInfo.strategyId == strategyId then
      return true
    end
  end
  return false
end

function StrategyLogic:GetStrategyDes(strategyId)
  local result = {}
  local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
  for i = 1, 3 do
    local str = strategyConfig["strategy_dec" .. i]
    if str ~= "" then
      table.insert(result, str)
    end
  end
  return result
end

function StrategyLogic:CheckApply(strategyId)
  if not Data.strategyData:GetStrategyDataById(strategyId) then
    noticeManager:ShowTip(UIHelper.GetString(980001))
    return false
  end
  return true
end

function StrategyLogic:CheckLearn(strategyId)
  if Data.strategyData:GetStrategyDataById(strategyId) then
    noticeManager:ShowTip(UIHelper.GetString(980002))
    return false
  end
  local level = Data.userData:GetUserLevel()
  local playerConfig = configManager.GetDataById("config_player_levelup", level)
  local numMax = playerConfig.tactic_poin
  local numNow = numMax - math.ceil(Data.strategyData:GetCurCost())
  local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
  local numNeed = strategyConfig.activation_cost
  if numNow < numNeed then
    noticeManager:ShowTip(UIHelper.GetString(980003))
    return false
  end
  return true
end

function StrategyLogic:CheckResetCur()
  local config104 = configManager.GetDataById("config_parameter", 104).arrValue
  local config105 = configManager.GetDataById("config_parameter", 105).arrValue
  local config106 = configManager.GetDataById("config_parameter", 106).arrValue
  local config107 = configManager.GetDataById("config_parameter", 107).arrValue
  local resetNum = Data.strategyData:GetResetNum()
  local cur1Num = config105[#config105]
  if resetNum < #config105 then
    cur1Num = config105[resetNum + 1]
  end
  if not Logic.currencyLogic:CheckCurrencyEnoughAndTips(config104[2], cur1Num) then
    return false
  end
  local cur2Num = config107[#config107]
  if resetNum < #config107 then
    cur2Num = config107[resetNum + 1]
  end
  if not Logic.currencyLogic:CheckCurrencyEnoughAndTips(config106[2], cur2Num) then
    return false
  end
  return true
end

function StrategyLogic:GetResetCur()
  local cur1Id, cur1Num = self:GetResetCur1()
  local cur2Id, cur2Num = self:GetResetCur2()
  return cur1Id .. ":" .. cur1Num .. "," .. cur2Id .. ":" .. cur2Num
end

function StrategyLogic:GetResetCur1()
  local config104 = configManager.GetDataById("config_parameter", 104).arrValue
  local config105 = configManager.GetDataById("config_parameter", 105).arrValue
  local resetNum = Data.strategyData:GetResetNum()
  local cur1Num = config105[#config105]
  if resetNum < #config105 then
    cur1Num = config105[resetNum + 1]
  end
  return config104[2], cur1Num
end

function StrategyLogic:GetResetCurTip1()
  local cur1Id, cur1Num = self:GetResetCur1()
  if 0 < cur1Num then
    local curName = Logic.currencyLogic:GetName(cur1Id)
    return cur1Num .. curName
  else
    return nil
  end
end

function StrategyLogic:GetResetCur2()
  local config106 = configManager.GetDataById("config_parameter", 106).arrValue
  local config107 = configManager.GetDataById("config_parameter", 107).arrValue
  local resetNum = Data.strategyData:GetResetNum()
  local cur2Num = config107[#config107]
  if resetNum < #config107 then
    cur2Num = config107[resetNum + 1]
  end
  return config106[2], cur2Num
end

function StrategyLogic:GetResetCurTip2()
  local cur2Id, cur2Num = self:GetResetCur2()
  if 0 < cur2Num then
    local curName = Logic.currencyLogic:GetName(cur2Id)
    return cur2Num .. curName
  else
    return nil
  end
end

function StrategyLogic:GetStrategyTips(strategyId)
  local result = ""
  local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
  for i = 1, 3 do
    local str = strategyConfig["tip" .. i]
    if str ~= "" then
      result = result .. str .. "  "
    end
  end
  return result
end

function StrategyLogic:GetRecommendByFleet(fleetId, fleetType)
  local strategyId = Data.fleetData:GetStrategyDataById(fleetId, fleetType)
  local recommendTbl = {}
  if 0 < strategyId then
    local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
    local recommend = strategyConfig.recommend
    for i, v in pairs(recommend) do
      recommendTbl[v] = true
    end
  end
  return recommendTbl
end

function StrategyLogic:CheckConditionByFleet(fleetId, typ, strategyP)
  local strategyId = 0
  if typ == FleetType.Preset then
    strategyId = strategyP
  else
    strategyId = Data.fleetData:GetStrategyDataById(fleetId, typ)
  end
  if 0 < strategyId then
    local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
    for i = 1, 3 do
      local conditionList = strategyConfig["strategy" .. i .. "_condition"]
      for index, condition in pairs(conditionList) do
        local res, _ = Logic.gameLimitLogic.CheckConditionById(condition, fleetId, typ)
        if not res then
          return false
        end
      end
    end
  else
    return false
  end
  return true
end

function StrategyLogic:CheckUnlockByFleet(fleetId, typ)
  local strategyId = Data.fleetData:GetStrategyDataById(fleetId, typ)
  if 0 < strategyId then
    local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
    for i = 1, 3 do
      local conditionList = strategyConfig["strategy" .. i .. "_condition"]
      local result = true
      if strategyConfig["strategy_dec" .. i] == "" then
        result = false
      end
      for index, condition in pairs(conditionList) do
        local res, _ = Logic.gameLimitLogic.CheckConditionById(condition, fleetId, typ)
        if not res then
          result = false
        end
      end
      if result == true then
        return true
      end
    end
  end
  return false
end

function StrategyLogic:GetNameById(strategyId)
  local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
  return strategyConfig.strategy_name
end

function StrategyLogic:GetFleetMaxByType(fleetType)
  if fleetType == FleetType.Preset then
    return 1
  else
    local fleetInfo = Data.fleetData:GetFleetData(fleetType)
    return #fleetInfo
  end
end

return StrategyLogic
