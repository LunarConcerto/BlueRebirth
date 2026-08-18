local ExchangeData = class("data.ExchangeData", Data.BaseData)

function ExchangeData:initialize()
  self.ExchangeMap = {}
end

function ExchangeData:SetData(data)
  if data then
    self.ExchangeMap = {}
    for i, v in ipairs(data.ExchangeInfo) do
      self.ExchangeMap[v.Id] = v.Times
    end
  end
end

function ExchangeData:GetExchangeTimes(exchangeId)
  return self.ExchangeMap[exchangeId] or 0
end

return ExchangeData
