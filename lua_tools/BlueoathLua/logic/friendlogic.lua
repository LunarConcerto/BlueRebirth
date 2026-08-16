local FriendLogic = class("logic.FriendLogic")

function FriendLogic:initialize()
  self.m_leftTogIndex = 1
  self.isUserTipsOpen = false
end

function FriendLogic:ResetData()
  self.m_leftTogIndex = -1
  self.isUserTipsOpen = false
  self.recommendData = {}
  self.currApplyUid = 0
end

function FriendLogic:SetTogIndex(index)
  if Logic.copyLogic:GetUserCurStatus() then
    return
  end
  self.m_leftTogIndex = index
end

function FriendLogic:GetTogIndex()
  return self.m_leftTogIndex
end

function FriendLogic:SetTipsOpen(enabled)
  self.isUserTipsOpen = enabled
end

function FriendLogic:GetTipsOpen()
  return self.isUserTipsOpen
end

function FriendLogic:GetUserStatus(offlineTime, uid)
  local userStatus
  if self:IsMyFriend(uid) and self:IsOnLine(uid) or offlineTime == 0 then
    userStatus = "\229\156\168\231\186\191"
  else
    local time = 0
    if offlineTime <= 3600 then
      time = offlineTime / 60 - offlineTime / 60 % 1 + 1
      userStatus = string.format("%s\229\136\134\233\146\159\229\137\141", math.tointeger(time))
    elseif 3600 < offlineTime and offlineTime < 86400 then
      time = offlineTime / 3600 - offlineTime / 3600 % 1 + 1
      userStatus = string.format("%s\229\176\143\230\151\182\229\137\141", math.tointeger(time))
    elseif 86400 <= offlineTime then
      time = offlineTime / 86400 - offlineTime / 86400 % 1 + 1
      userStatus = string.format("%s\229\164\169\229\137\141", math.tointeger(time))
    end
  end
  return userStatus
end

function FriendLogic:LoadFriendTypeInfo(togIndex)
  local tabSerData = {}
  local listData = {}
  if togIndex == FriendList.Friend then
    listData = Data.friendData:GetFriendData()
  end
  if togIndex == FriendList.Add then
    listData = self:GetRecommendData()
  end
  if togIndex == FriendList.Apply then
    listData = Data.friendData:GetApplyData()
  end
  if togIndex == FriendList.BlackList then
    listData = Data.friendData:GetBlackData()
  end
  tabSerData = self:SortFriendRecommendList(listData)
  return tabSerData
end

function FriendLogic:GetUserFriendNum()
  local tabSerData = Data.friendData:GetFriendData()
  return GetTableLength(tabSerData)
end

function FriendLogic:GetUserFreindMaxNum(levle)
  local userFriendMaxNum = configManager.GetDataById("config_player_levelup", levle).friends_count
  return userFriendMaxNum
end

function FriendLogic:ClickApplyLogic(Uid, hander)
  local nUserMaxFriendNum = self:GetUserFreindMaxNum(Data.userData:GetUserData().Level)
  local nUserFriendNum = self:GetUserFriendNum()
  if nUserMaxFriendNum <= nUserFriendNum then
    noticeManager:OpenTipPage(hander, UIHelper.GetString(210007))
  else
    self.currApplyUid = Uid
    Service.friendService:SendApply(Uid)
  end
end

function FriendLogic:GetUserStatusInfo(nUserUid)
  local friendData = Data.friendData:GetFriendData()
  for k, v in pairs(friendData) do
    if v.UserInfo.Uid == nUserUid then
      return FriendStatus.FRIEND
    end
  end
  local blackData = Data.friendData:GetBlackData()
  for k, v in pairs(blackData) do
    if v.UserInfo.Uid == nUserUid then
      return FriendStatus.BLACK
    end
  end
  return FriendStatus.NORMAL
end

function FriendLogic:IsMyFriend(uid)
  local friendData = Data.friendData:GetFriendData()
  for k, v in pairs(friendData) do
    if v.UserInfo.Uid == uid then
      return true, SetReadOnlyMeta(v)
    end
  end
  return false, nil
end

function FriendLogic:IsMyBlock(uid)
  local blockData = Data.friendData:GetBlackData()
  for k, v in pairs(blockData) do
    if v.UserInfo.Uid == uid then
      return true
    end
  end
  return false
end

function FriendLogic:IsOnLine(uid)
  return Data.friendData:GetFriendStatus(uid) == UserStatusType.Online
end

function FriendLogic:SortFriendRecommendList(m_tabSerfriendData)
  table.sort(m_tabSerfriendData, function(data1, data2)
    if data1.OfflineTime ~= data2.OfflineTime then
      return data1.OfflineTime < data2.OfflineTime
    elseif data1.UserInfo.Level ~= data2.UserInfo.Level then
      return data1.UserInfo.Level > data2.UserInfo.Level
    else
      return data1.UserInfo.Uid < data2.UserInfo.Uid
    end
  end)
  return m_tabSerfriendData
end

function FriendLogic:SortApplyAndBlackListData(m_tabSerfriendData)
  table.sort(m_tabSerfriendData, function(data1, data2)
    return data1.OperationTime > data2.OperationTime
  end)
  return m_tabSerfriendData
end

function FriendLogic:SortRecommendListData(m_tabSerfriendData)
  table.sort(m_tabSerfriendData, function(data1, data2)
    if data1.OfflineTime ~= data2.OfflineTime then
      return data1.OfflineTime < data2.OfflineTime
    else
      return data1.UserInfo.Uid < data2.UserInfo.Uid
    end
  end)
  return m_tabSerfriendData
end

function FriendLogic:CheckApplyReq(uid)
  local applyRet = Data.friendData:GetApplyRecordData()
  for k, v in pairs(applyRet) do
    if v.UserInfo.Uid == uid then
      return true
    end
  end
  return false
end

function FriendLogic:SetRecommendData(ret)
  self.recommendData = {}
  for _, v in ipairs(ret) do
    self.recommendData[v.UserInfo.Uid] = v
  end
end

function FriendLogic:RemoveRecommendUser()
  if self.currApplyUid == 0 or self.currApplyUid == nil then
    return
  end
  self.recommendData[self.currApplyUid] = nil
  self.currApplyUid = 0
end

function FriendLogic:GetRecommendData()
  local ret = {}
  for k, v in pairs(self.recommendData) do
    table.insert(ret, v)
  end
  return ret
end

return FriendLogic
