local RoomData = class("data.RoomData", Data.BaseData)

function RoomData:initialize()
  self:_InitHandlers()
end

function RoomData:_InitHandlers()
  self:ResetData()
end

function RoomData:ResetData()
  self.data = {}
end

function RoomData:SetData(data)
  logError("RoomData:", data)
  self.data = data
end

function RoomData:GetIdentity()
  return self.data.Identity
end

return RoomData
