local ActivityCodeExchangeData = class("data.ActivityCodeExchangeData", Data.BaseData)
codeExgType = {Reward = 1, Code = 2}

function ActivityCodeExchangeData:initialize()
  self:ResetData()
end

function ActivityCodeExchangeData:ResetData()
  self.m_ReceiptData = {}
end

function ActivityCodeExchangeData:SetData(data)
  if data and data.ReceiptData ~= nil and #data.ReceiptData > 0 then
    for _, v in pairs(data.ReceiptData) do
      if v then
        self.m_ReceiptData[v.RewardId] = v.Count
      end
    end
    self:RefreshEvent()
  end
end

function ActivityCodeExchangeData:GetReceiptData()
  return self.m_ReceiptData
end

function ActivityCodeExchangeData:RefreshEvent()
  eventManager:SendEvent(LuaEvent.RefreshCodeExgItem)
end

return ActivityCodeExchangeData
