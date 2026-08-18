local PveRoomData = class("data.PveRoomData", Data.BaseData)

function PveRoomData:initialize()
  self:ResetData()
end

function PveRoomData:ResetData()
  self.pveRoomData = {}
  self.RefreshBeforeData = {}
end

function PveRoomData:SetData(data)
  if self.RefreshBeforeData.RoomId ~= self.pveRoomData.RoomId then
    self.RefreshBeforeData = {}
  end
  if next(self.pveRoomData) ~= nil and (next(self.RefreshBeforeData) == nil or self.RefreshBeforeData.RoomId == self.pveRoomData.RoomId) then
    self.RefreshBeforeData = self.pveRoomData
  end
  self.pveRoomData = data
  if #self.pveRoomData.RoomUsers > 1 and next(self.RefreshBeforeData) ~= nil then
    for _, new in pairs(self.pveRoomData.RoomUsers) do
      local isHave = false
      for _, old in pairs(self.RefreshBeforeData.RoomUsers) do
        if new.Uid == old.Uid then
          isHave = true
          break
        end
      end
      if not isHave then
        eventManager:SendEvent(LuaEvent.PveRoomAddUser, new.Name)
      end
    end
  end
end

function PveRoomData:SetRoomListData(data, state)
  local roomList = data.roomInfo
  if 1 < #roomList then
    table.sort(roomList, function(data1, data2)
      if data1.CreateTime ~= data2.CreateTime then
        return data1.CreateTime > data2.CreateTime
      end
      return data1.RoomId < data2.RoomId
    end)
  end
  eventManager:SendEvent(LuaEvent.GetRoomList, {roomList = roomList, state = state})
end

function PveRoomData:GetPveRoomData()
  return self.pveRoomData
end

function PveRoomData:GetRefreshBeforeData()
  return self.RefreshBeforeData
end

function PveRoomData:GetUserRoomInfo()
  local uid = Data.userData:GetUserUid()
  if self.pveRoomData ~= nil and self.pveRoomData.RoomUsers ~= nil then
    for index = 1, #self.pveRoomData.RoomUsers do
      local userInfo = self.pveRoomData.RoomUsers[index]
      if userInfo and userInfo.Uid == uid then
        return userInfo
      end
    end
  end
  return nil
end

return PveRoomData
