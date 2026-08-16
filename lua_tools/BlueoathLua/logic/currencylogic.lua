local CurrencyLogic = class("logic.CurrencyLogic")

function CurrencyLogic:GetIcon(id)
  local config = configManager.GetDataById("config_currency", id)
  return config.icon
end

function CurrencyLogic:GetSmallIcon(id)
  local config = configManager.GetDataById("config_currency", id)
  return config.icon_small
end

function CurrencyLogic:GetName(id)
  local config = configManager.GetDataById("config_currency", id)
  return config.name
end

function CurrencyLogic:GetDesc(id)
  local config = configManager.GetDataById("config_currency", id)
  return config.description
end

function CurrencyLogic:GetQuality(id)
  local config = configManager.GetDataById("config_currency", id)
  return config.quality
end

function CurrencyLogic:GetFrame(id)
  return "", ""
end

function CurrencyLogic:GetTexIcon(id)
  local config = configManager.GetDataById("config_currency", id)
  return config.icon
end

function CurrencyLogic:CheckCurrencyEnough(cType, costNum)
  local haveNum = Data.userData:GetCurrency(cType)
  return costNum <= haveNum
end

function CurrencyLogic:CheckCurrencyEnoughAndTips(cType, costNum)
  if not self:CheckCurrencyEnough(cType, costNum) then
    local name = self:GetName(cType)
    local str = string.format(UIHelper.GetString(440002), name)
    globalNoitceManager:ShowItemInfoPage(GoodsType.CURRENCY, cType)
    noticeManager:ShowTip(str)
    return false
  end
  return true
end

function CurrencyLogic:GetSupplyconfig()
  local config = configManager.GetData("config_supply_get")
  local tidyConfig = {}
  for _, v in ipairs(config) do
    table.insert(tidyConfig, v.id, v)
  end
  return tidyConfig
end

function CurrencyLogic:SupplyStatus(configTime, getTime)
  local nowTime = time.getSvrTime()
  if not getTime then
    return self:CheckGetSupplyTime(configTime)
  elseif time.isSameDay(getTime.GetTime, nowTime) then
    return GetSupplyStatus.RECEIVED
  else
    return self:CheckGetSupplyTime(configTime)
  end
end

function CurrencyLogic:CheckGetSupplyTime(configTime)
  local nowTime = time.getSvrTime()
  local timeBegin = time.str2time(configTime[1] * 10000, nowTime)
  local timeEnd = time.str2time(configTime[2] * 10000, nowTime)
  if nowTime >= timeBegin and nowTime <= timeEnd then
    return GetSupplyStatus.CANGET
  end
  return GetSupplyStatus.NOTINTIME
end

function CurrencyLogic:GetMedalIconTab()
  local config = configManager.GetDataById("config_currency", 15)
  return config.icon_multilevel_small
end

return CurrencyLogic
