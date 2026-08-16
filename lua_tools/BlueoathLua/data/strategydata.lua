local StrategyData = class("data.StrategyData", Data.BaseData)

function StrategyData:initialize()
  self:_InitHandlers()
end

function StrategyData:_InitHandlers()
  self:ResetData()
end

function StrategyData:ResetData()
  self.StrategyInfo = {}
  self.ResetNum = 0
  self.CurCost = 0
end

function StrategyData:SetData(data)
  for i, v in pairs(data.StrategyList) do
    if v.Level > 0 then
      self.StrategyInfo[v.Id] = v.Level
    else
      self.StrategyInfo[v.Id] = nil
    end
  end
  if data.ResetNum then
    self.ResetNum = data.ResetNum
  end
  if data.CurCost then
    self.CurCost = data.CurCost
  end
end

function StrategyData:GetStrategyData()
  return SetReadOnlyMeta(self.StrategyInfo)
end

function StrategyData:GetStrategyDataById(strategyId)
  return SetReadOnlyMeta(self.StrategyInfo[strategyId])
end

function StrategyData:GetResetNum()
  return self.ResetNum
end

function StrategyData:GetCurCost()
  local sum = 0
  for strategyId, level in pairs(self.StrategyInfo) do
    if strategyId and 0 < strategyId then
      local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
      if strategyConfig then
        sum = sum + strategyConfig.activation_cost
      end
    end
  end
  return sum
end

return StrategyData
