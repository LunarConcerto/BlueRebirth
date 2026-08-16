local AssistNewData = class("data.AssistNewData", Data.BaseData)

function AssistNewData:initialize()
  self:_InitHandlers()
end

function AssistNewData:_InitHandlers()
  self:ResetData()
end

function AssistNewData:ResetData()
  self.m_data = {}
end

function AssistNewData:SetAssistData(data)
  self.m_data = data
end

function AssistNewData:GetAssistData()
  return self.m_data
end

function AssistNewData:GetAssistById(id)
  for i, v in ipairs(self.m_data) do
    if v.Id == id then
      return v
    end
  end
end

return AssistNewData
