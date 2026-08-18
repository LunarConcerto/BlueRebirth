local FriendData = class("data.FriendData", Data.BaseData)

function FriendData:initialize()
  self:_InitHandlers()
end

function FriendData:_InitHandlers()
  self:ResetData()
end

function FriendData:ResetData()
  self.allData = {}
  self.friendData = {}
  self.blackData = {}
  self.applyData = {}
  self.applyRecordData = {}
  self.searchFriendData = nil
  self.applyRedDot = false
  self.friendRedDot = false
  self.tabUserStatus = {}
end

function FriendData:initFriendStatus()
  for k, v in pairs(self.friendData) do
    if v.OfflineTime == 0 then
      self.tabUserStatus[v.UserInfo.Uid] = UserStatusType.Online
    else
      self.tabUserStatus[v.UserInfo.Uid] = UserStatusType.Offline
    end
  end
end

function FriendData:SetFriendStatus(userStatus, uid)
  self.tabUserStatus[uid] = userStatus
end

function FriendData:GetFriendStatus(uid)
  if self.tabUserStatus[uid] == nil then
    logError("Friend Data:Can't find" .. uid .. "'s userStatus")
  end
  return self.tabUserStatus[uid]
end

function FriendData:SetData(param)
  for i, v in ipairs(param.ChangeList) do
    if v == FriendStatus.APPLY then
      self.applyData = param.ApplyList
      if next(param.ApplyList) ~= nil then
        self.applyRedDot = true
      end
    elseif v == FriendStatus.FRIEND then
      local before = self.friendData
      self.friendData = param.FriendList
      self.friendRedDot = #before < GetTableLength(self.friendData)
    elseif v == FriendStatus.BLACK then
      self.blackData = param.BlackList
    elseif v == FriendStatus.APPLYREC then
      self.applyRecordData = param.ApplyRecordList
    end
  end
  if next(self.allData) == nil then
    self.friendRedDot = false
  end
  self:initFriendStatus()
end

function FriendData:GetFriendData()
  return SetReadOnlyMeta(self.friendData)
end

function FriendData:GetApplyRecordData()
  return SetReadOnlyMeta(self.applyRecordData)
end

function FriendData:SetFriendOffLineData(paramUid, offtime)
  for k, v in pairs(self.friendData) do
    if v.UserInfo.Uid == paramUid then
      v.OfflineTime = time.getSvrTime() - offtime
    end
  end
end

function FriendData:SetFriendOnLineData(paramUid)
  for k, v in pairs(self.friendData) do
    if v.UserInfo.Uid == paramUid then
      v.OfflineTime = 0
    end
  end
end

function FriendData:GetFriendDataByUid(uid)
  local tabRes
  for k, v in pairs(self.friendData) do
    if v.UserInfo.Uid == uid then
      tabRes = v
      return SetReadOnlyMeta(tabRes)
    end
  end
end

function FriendData:GetFriendNameByUid(uid)
  local friendData = self:GetFriendDataByUid(uid)
  if friendData == nil then
    logError("Friend Data:you can get user" .. uid .. "'s name,because he is't your friend")
  else
    return friendData.UserInfo.Uname
  end
end

function FriendData:GetApplyData()
  return SetReadOnlyMeta(self.applyData)
end

function FriendData:GetBlackData()
  return SetReadOnlyMeta(self.blackData)
end

function FriendData:GetRedState()
  if self.applyRedDot or self.friendRedDot then
    return true
  end
  return false
end

function FriendData:SetRedStateFalse()
  self.applyRedDot = false
  self.friendRedDot = false
end

return FriendData
