local ExchangeLogic = class("logic.ExchangeLogic")

function ExchangeLogic:initialize()
end

function ExchangeLogic:CheckCondition(exchangeId)
  local configData = configManager.GetDataById("config_item_exchange", exchangeId)
  local exchange_condition = configData.exchange_condition
  if #exchange_condition <= 0 then
    return true
  end
  if exchange_condition[1] == ExchangeCondition.Level then
    local level = Data.userData:GetLevel()
    return level >= exchange_condition[2]
  elseif exchange_condition[1] == ExchangeCondition.Copy then
    return Logic.copyLogic:IsCopyPassById(exchange_condition[2])
  end
end

function ExchangeLogic:CheckConsume(exchangeId)
  local configData = configManager.GetDataById("config_item_exchange", exchangeId)
  local item_consume = configData.item_consume
  local nimnum = 0
  local nimmap = {}
  if #item_consume <= 0 then
    return true, nimnum
  end
  for i, v in ipairs(item_consume) do
    local num = Logic.bagLogic:GetConsumeCurrNum(v[1], v[2])
    if num < v[3] then
      return false, nimnum
    else
      local min = math.floor(num / v[3])
      table.insert(nimmap, min)
    end
  end
  if 0 < #nimmap then
    nimnum = clone(nimmap[1])
    for i, v in ipairs(nimmap) do
      if v < nimnum then
        nimnum = clone(v)
      end
    end
  end
  return true, nimnum
end

function ExchangeLogic:CheckTimes(exchangeId)
  local nimnum = 0
  local configData = configManager.GetDataById("config_item_exchange", exchangeId)
  local exchangeNum = Data.exchangeData:GetExchangeTimes(exchangeId)
  if 0 >= configData.change_count then
    return true, 0
  end
  local change_count = configData.change_count
  nimnum = change_count - exchangeNum
  if nimnum < 0 then
    nimnum = 0
  end
  return exchangeNum < change_count, nimnum
end

function ExchangeLogic:GetRefreshTimeFirst(id)
  local configData = configManager.GetDataById("config_activity", id)
  local refresh_id_arr = {}
  for i, exchangeId in ipairs(configData.p1) do
    local configData = configManager.GetDataById("config_item_exchange", exchangeId)
    local refresh_id = configData.refresh_id
    table.insert(refresh_id_arr, refresh_id)
  end
  if #refresh_id_arr <= 0 then
    return 0
  end
  local timeFirst = PeriodManager:GetNextRefreshTime(refresh_id_arr[1])
  for i, refresh_id in ipairs(refresh_id_arr) do
    local timeFirstTmp = PeriodManager:GetNextRefreshTime(refresh_id)
    if timeFirst > timeFirstTmp then
      return timeFirst
    end
  end
  return timeFirst
end

return ExchangeLogic
