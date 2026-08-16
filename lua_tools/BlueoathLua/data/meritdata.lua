local MeritData = class("data.MeritData", Data.BaseData)

function MeritData:initialize()
  self:_InitHandlers()
end

function MeritData:_InitHandlers()
  self:ResetData()
end

function MeritData:ResetData()
  self.meritInfo = {}
  self.rankInfo = {}
end

function MeritData:SetData(param)
  self.meritInfo = param
end

function MeritData:GetData()
  return SetReadOnlyMeta(self.meritInfo)
end

return MeritData
