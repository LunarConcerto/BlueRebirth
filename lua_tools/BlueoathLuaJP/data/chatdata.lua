local ChatData = class("data.ChatData", Data.BaseData)
local ErrorEmojiId = 69

function ChatData:initialize()
  self:ResetData()
end

function ChatData:ResetData()
  self.chatChannel = ChatChannel.World
  self.chatWay = ChatWay.TextInput
  self.chatInfo = {}
  self.tabRecentEmoji = {}
  self.tabLastSendTime = {}
  self.tabUnReadInfoNum = {}
  self.tabRecentChatUser = nil
  self.lastPersonMsg = {}
  self.nowChatUserUid = 0
  self.isChatOpen = false
  self.isGetChatInfo = false
  self.nowRoomNum = 1
end

function ChatData:GetChatBanMsg()
  return self.chatInfo.BanMsg or ""
end

function ChatData:GetChatBanTime()
  return self.chatInfo.BanEndTime or 0
end

function ChatData:SetBlockTog(tog)
  if tog then
    PlayerPrefs.SetInt("girlChatBlockTog", 0)
  else
    PlayerPrefs.SetInt("girlChatBlockTog", 1)
  end
end

function ChatData:GetBlockTog()
  return PlayerPrefs.GetInt("girlChatBlockTog", 0)
end

function ChatData:SetChatInfoTog(tog)
  self.isGetChatInfo = tog
end

function ChatData:GetChatInfoTog()
  return self.isGetChatInfo
end

function ChatData:SetChatOpen(tog)
  self.isChatOpen = tog
end

function ChatData:GetChatOpen()
  return self.isChatOpen
end

function ChatData:SetNowChatUserInfo(uid)
  self.nowChatUserUid = uid
end

function ChatData:GetNowChatUserInfo()
  return self.nowChatUserUid
end

function ChatData:GetLastPersonMsg()
  return self.lastPersonMsg
end

function ChatData:GetUserInfoByTemplate(userInfo)
  local info = {
    Uid = userInfo.Uid,
    Level = userInfo.Level,
    Head = userInfo.Head,
    HeadFrame = userInfo.HeadFrame,
    Uname = userInfo.Uname,
    HeadShow = userInfo.HeadShow,
    Fashioning = userInfo.Fashioning
  }
  return info
end

function ChatData:AddRecentChatUser(info)
  local userInfo = info
  if info.UserInfo then
    userInfo = self:GetUserInfoByTemplate(info.UserInfo)
  end
  local persionNumUp = Data.chatData:getPersionNumUp()
  if self.tabRecentChatUser == nil then
    self.tabRecentChatUser = {}
  end
  if persionNumUp < #self.tabRecentChatUser then
    table.remove(self.tabRecentChatUser)
  end
  local pos = Data.chatData:isRecentChatUser(userInfo.Uid)
  if pos then
    table.remove(self.tabRecentChatUser, pos)
  end
  if Logic.chatLogic:IsMeUserInfo(userInfo.Uid) then
    return
  end
  self.tabRecentChatUser = Logic.chatLogic:SortUserListByChatTime(self.tabRecentChatUser)
  table.insert(self.tabRecentChatUser, 1, userInfo)
end

function ChatData:GetRecentChatUser()
  return self.tabRecentChatUser or {}
end

function ChatData:GetRecentChatUserInfoByUid(uid)
  for k, v in pairs(self.tabRecentChatUser) do
    if v.Uid == uid then
      return v
    end
  end
  logError("ChatData:" .. uid .. "isn't recent chat user")
  return nil
end

function ChatData:SetLocalRecentChatUser()
  local str = Serialize(self.tabRecentChatUser) or " "
  ChatInfoManager.SaveRecentChatUser(str)
end

function ChatData:GetLocalRecentChatUser()
  return ChatInfoManager.GetRecentChatUser()
end

function ChatData:AddUnReadInfoNum(channelId, uid, num)
  num = num or 1
  if Logic.chatLogic:IsWorldChannel(channelId) then
    self:AddWorldUnReadNum(channelId, num)
  elseif channelId == ChatChannel.Guild then
    self:AddGuildUnReadNum(num)
  elseif channelId == ChatChannel.System then
    self:AddSystemUnReadNum(num)
  elseif channelId == ChatChannel.Team then
    self:AddTeamUnReadNum(num)
  else
    self:AddPersionUnReadNum(uid, num)
  end
end

function ChatData:AddWorldUnReadNum(channelId, num)
  local roomNum = Data.chatData:GetRoomNum()
  if self.tabUnReadInfoNum[roomNum] == nil then
    self.tabUnReadInfoNum[roomNum] = 0
  end
  self.tabUnReadInfoNum[roomNum] = self.tabUnReadInfoNum[roomNum] + num
end

function ChatData:AddGuildUnReadNum(num)
  if self.tabUnReadInfoNum[ChatChannel.Guild] == nil then
    self.tabUnReadInfoNum[ChatChannel.Guild] = 0
  end
  self.tabUnReadInfoNum[ChatChannel.Guild] = self.tabUnReadInfoNum[ChatChannel.Guild] + num
end

function ChatData:AddSystemUnReadNum(num)
  if self.tabUnReadInfoNum[ChatChannel.System] == nil then
    self.tabUnReadInfoNum[ChatChannel.System] = 0
  end
  self.tabUnReadInfoNum[ChatChannel.System] = self.tabUnReadInfoNum[ChatChannel.System] + num
end

function ChatData:AddTeamUnReadNum(num)
  if self.tabUnReadInfoNum[ChatChannel.Team] == nil then
    self.tabUnReadInfoNum[ChatChannel.Team] = 0
  end
  self.tabUnReadInfoNum[ChatChannel.Team] = self.tabUnReadInfoNum[ChatChannel.Team] + num
end

function ChatData:AddPersionUnReadNum(uid, num)
  if self.tabUnReadInfoNum[uid] == nil then
    self.tabUnReadInfoNum[uid] = 0
  end
  self.tabUnReadInfoNum[uid] = self.tabUnReadInfoNum[uid] + num
end

function ChatData:GetUnReadNumByChannelType(channelType, roomNum)
  if channelType == ChatChannel.WorldBase then
    return self:GetWorldUnReadNum(roomNum)
  elseif channelType == ChatChannel.Guild then
    return self:GetGuildUnReadNum()
  elseif channelType == ChatChannel.System then
    return self:GetSystemUnReadNum()
  elseif channelType == ChatChannel.Team then
    return self:GetTeamUnReadNum()
  else
    return self:GetPersionUnReadNum()
  end
  return 0
end

function ChatData:GetWorldUnReadNum(roomNum)
  return self.tabUnReadInfoNum[roomNum]
end

function ChatData:GetGuildUnReadNum()
  return self.tabUnReadInfoNum[ChatChannel.Guild]
end

function ChatData:GetSystemUnReadNum()
  return self.tabUnReadInfoNum[ChatChannel.System]
end

function ChatData:GetTeamUnReadNum()
  return self.tabUnReadInfoNum[ChatChannel.Team]
end

function ChatData:GetPersionUnReadNum()
  local count = 0
  for k, v in pairs(self.tabUnReadInfoNum) do
    if 1000 < k then
      count = count + v
    end
  end
  return count
end

function ChatData:GetPersionUnReadNumByUid(uid)
  return self.tabUnReadInfoNum[uid]
end

function ChatData:GetUnReadNumInfo()
  return self.tabUnReadInfoNum
end

function ChatData:ResetUnReadNumByChannelType(channelType, roomNum)
  if channelType == ChatChannel.WorldBase then
    self.tabUnReadInfoNum[roomNum] = 0
  elseif channelType == ChatChannel.Guild then
    self.tabUnReadInfoNum[ChatChannel.Guild] = 0
  elseif channelType == ChatChannel.System then
    self.tabUnReadInfoNum[ChatChannel.System] = 0
  elseif channelType == ChatChannel.Team then
    self.tabUnReadInfoNum[ChatChannel.Team] = 0
  else
    return
  end
end

function ChatData:ResetUnReadNumByUid(uid)
  if self.tabUnReadInfoNum[uid] == nil then
    self.tabUnReadInfoNum[uid] = 0
  end
  self.tabUnReadInfoNum[uid] = 0
end

function ChatData:GetMyChatTemplate(chatChannel, sendTime, message, type, templateId, params)
  if chatChannel == nil or sendTime == nil or message == nil then
    logError("ChatData:chatChannel or sendTime or message is nil")
    return
  end
  local userInfo = Data.userData:GetUserData()
  local sdata = Data.heroData:GetHeroById(userInfo.SecretaryId)
  local myChatTemplate = {}
  local UserInfo = {}
  if userInfo.HeadShow then
    UserInfo.HeadShow = userInfo.HeadShow
  else
    UserInfo.HeadShow = nil
  end
  UserInfo.Uid = userInfo.Uid
  UserInfo.Uname = userInfo.Uname
  UserInfo.Level = userInfo.Level
  UserInfo.Head = userInfo.Head
  UserInfo.HeadFrame = userInfo.HeadFrame
  UserInfo.HeadShow = userInfo.HeadShow
  UserInfo.Fashioning = sdata.Fashioning
  myChatTemplate.UserInfo = UserInfo
  myChatTemplate.Channel = chatChannel
  myChatTemplate.SendTime = sendTime
  myChatTemplate.Message = message
  myChatTemplate.TemplateId = templateId or 0
  myChatTemplate.Params = params or ""
  myChatTemplate.MsgType = type
  return myChatTemplate
end

function ChatData:GetSystemChatTemplate(message, templateId, params)
  local systemChatTemplate = {}
  local UserInfo = self:GetDefaultUserInfo(UIHelper.GetString(920000039))
  systemChatTemplate.UserInfo = UserInfo
  systemChatTemplate.Channel = ChatChannel.System
  systemChatTemplate.SendTime = time.getSvrTime()
  systemChatTemplate.Message = message
  systemChatTemplate.TemplateId = templateId or 0
  systemChatTemplate.Params = params or ""
  return systemChatTemplate
end

function ChatData:GetDefaultUserInfo(title)
  return {
    Uid = 0,
    Uname = title or "",
    Level = 0,
    Head = 0,
    HeadFrame = 0
  }
end

function ChatData:AddRecentEmoji(tabEmojiInfo)
  local isUp = Logic.chatLogic:IsRecentUp(#self.tabRecentEmoji)
  if isUp then
    self.tabRecentEmoji[#self.tabRecentEmoji] = nil
  end
  for k, v in ipairs(self.tabRecentEmoji) do
    if v.id == tabEmojiInfo.id then
      table.remove(self.tabRecentEmoji, k)
      table.insert(self.tabRecentEmoji, 1, tabEmojiInfo)
      return
    end
  end
  table.insert(self.tabRecentEmoji, tabEmojiInfo)
end

function ChatData:GetRecentEmojiList()
  for k, v in ipairs(self.tabRecentEmoji) do
    if v.id == ErrorEmojiId then
      table.remove(self.tabRecentEmoji, k)
    end
  end
  return self.tabRecentEmoji
end

function ChatData:SaveRecentEmoji()
  local content = Serialize(self.tabRecentEmoji) or ""
  local uid = Data.userData:GetUserUid()
  ChatInfoManager.SaveData("RecentEmoji", uid, "lua", content)
end

function ChatData:LoadRecentEmoji()
  local uid = Data.userData:GetUserUid()
  local content = ChatInfoManager.GetData("RecentEmoji", uid, "lua") or ""
  self.tabRecentEmoji = Unserialize(content) or {}
end

function ChatData:SetLocalChatData()
  local str
  if self.chatInfo == nil or self.chatInfo.LocalMsg == nil then
    str = " "
  else
    str = Serialize(self.chatInfo.LocalMsg)
  end
  ChatInfoManager.SaveChatData(str)
end

function ChatData:GetLocalChatData()
  return ChatInfoManager.GetChatData()
end

function ChatData:SetChatInfo(chatInfo)
  for k, v in pairs(chatInfo) do
    self.chatInfo[k] = v
  end
  self:_MsgsCheck(chatInfo.GuildMsg)
  self:_MsgsCheck(chatInfo.TeamMsg)
  self:_MsgsCheck(chatInfo.SysMsg)
  local tabWorldMsg = {}
  for k, v in ipairs(chatInfo.WorldMsg) do
    local roomNum = v.Channel - ChatChannel.WorldBase
    if tabWorldMsg[roomNum] == nil then
      tabWorldMsg[roomNum] = {}
    end
    self:_MsgCheck(v)
    table.insert(tabWorldMsg[roomNum], v)
  end
  self.chatInfo.WorldMsg = tabWorldMsg
end

function ChatData:InitLocalInfo()
  self.chatInfo.LocalMsg = Unserialize(self:GetLocalChatData()) or {}
  self.tabRecentChatUser = Unserialize(self:GetLocalRecentChatUser()) or {}
  self.tabRecentChatUser = self:_TryDealRecentFormat(self.tabRecentChatUser)
  self:SetChatInfoTog(true)
  self:LoadRecentEmoji()
end

function ChatData:_TryDealRecentFormat(recent)
  local res = {}
  for i, v in ipairs(recent) do
    if v.UserInfo then
      local temp = self:GetUserInfoByTemplate(v.UserInfo)
      res[i] = temp
    else
      res[i] = v
    end
  end
  return res
end

function ChatData:AddChatInfo(chatMsg, channelType, roomNum, uid)
  if channelType == ChatChannel.WorldBase then
    self:AddWorldMsgByRoom(chatMsg, roomNum)
  elseif channelType == ChatChannel.Guild then
    self:AddGuildMsg(chatMsg)
  elseif channelType == ChatChannel.System then
    self:AddSystemMsg(chatMsg)
  elseif channelType == ChatChannel.Team then
    self:AddTeamMsg(chatMsg)
  else
    self.lastPersonMsg = chatMsg
    self:AddLocalInfoByUid(chatMsg, uid)
  end
end

function ChatData:AddChatMsg(chatMsg)
  chatMsg.New = true
  chatMsg.Channel = chatMsg.Channel or ChatChannel.WorldBase + 1
  self:_MsgCheck(chatMsg)
  if Logic.chatLogic:IsWorldChannel(chatMsg.Channel) then
    local roomNum = chatMsg.Channel - ChatChannel.WorldBase
    self:AddChatInfo(chatMsg, ChatChannel.WorldBase, roomNum, chatMsg.UserInfo.Uid)
  else
    self:AddChatInfo(chatMsg, chatMsg.Channel, nil, chatMsg.UserInfo.Uid)
  end
end

function ChatData:_MsgCheck(chatMsg)
  if next(chatMsg.UserInfo) == nil then
    chatMsg.UserInfo = self:GetDefaultUserInfo()
  end
  local tid = chatMsg.TemplateId
  if 0 < tid then
    local str = UIHelper.GetString(tid)
    if str ~= "" then
      local array = {}
      for _, v in pairs(chatMsg.Params) do
        table.insert(array, v.Value)
      end
      chatMsg.Message = string.format(str, table.unpack(array))
    end
  end
end

function ChatData:_MsgsCheck(msgs)
  for _, msg in ipairs(msgs) do
    self:_MsgCheck(msg)
  end
end

function ChatData:SetMsgRead(msg)
  if msg.New then
    msg.New = false
  end
end

function ChatData:GetChatInfo(channelType, roomNum, uid)
  if channelType == ChatChannel.WorldBase then
    return self:GetWorldMsgByRoom(roomNum)
  elseif channelType == ChatChannel.Guild then
    return self:GetGuildMsg()
  elseif channelType == ChatChannel.System then
    return self:GetSystemMsg()
  elseif channelType == ChatChannel.Team then
    return self:GetTeamMsg()
  else
    return self:GetLocalInfoByUid(uid)
  end
end

function ChatData:AddWorldMsgByRoom(chatMsg, roomNum)
  local function dataCheck()
    if self.chatInfo.WorldMsg == nil then
      self.chatInfo.WorldMsg = {}
    end
    if self.chatInfo.WorldMsg[roomNum] == nil then
      self.chatInfo.WorldMsg[roomNum] = {}
    end
  end
  
  dataCheck()
  local upNum = Data.chatData:getSaveMsgUp()
  if upNum < #self.chatInfo.WorldMsg[roomNum] then
    table.remove(self.chatInfo.WorldMsg[roomNum], 1)
  end
  table.insert(self.chatInfo.WorldMsg[roomNum], chatMsg)
end

function ChatData:GetWorldMsgByRoom(roomNum)
  local msgs = self.chatInfo.WorldMsg[roomNum]
  if msgs then
    self.chatInfo.WorldMsg[roomNum] = self:_filerUtil(msgs)
  end
  return self.chatInfo.WorldMsg[roomNum] or {}
end

function ChatData:_filerUtil(msgs)
  local block = Data.friendData:GetBlackData()
  if block == nil or msgs == nil then
    return msgs
  end
  local uidCaches = {}
  for _, v in pairs(block) do
    uidCaches[v.UserInfo.Uid] = v.OperationTime
  end
  local res = {}
  for i, v in ipairs(msgs) do
    local blockTime = uidCaches[v.UserInfo.Uid]
    if blockTime == nil or blockTime > v.SendTime then
      res[#res + 1] = v
    end
  end
  return res
end

function ChatData:AddGuildMsg(chatMsg)
  if self.chatInfo.GuildMsg == nil then
    self.chatInfo.GuildMsg = {}
  end
  local upNum = Data.chatData:getSaveMsgUp()
  if upNum < #self.chatInfo.GuildMsg then
    table.remove(self.chatInfo.GuildMsg, 1)
  end
  table.insert(self.chatInfo.GuildMsg, chatMsg)
end

function ChatData:GetGuildMsg()
  local msgs = self.chatInfo.GuildMsg
  if msgs then
    self.chatInfo.GuildMsg = self:_filerUtil(msgs)
  end
  return self.chatInfo.GuildMsg
end

function ChatData:ResetGuildMsg()
  self.chatInfo.GuildMsg = {}
end

function ChatData:AddTeamMsg(chatMsg)
  if self.chatInfo.TeamMsg == nil then
    self.chatInfo.TeamMsg = {}
  end
  local upNum = Data.chatData:getSaveMsgUp()
  if upNum < #self.chatInfo.TeamMsg then
    table.remove(self.chatInfo.TeamMsg, 1)
  end
  table.insert(self.chatInfo.TeamMsg, chatMsg)
end

function ChatData:GetTeamMsg()
  return self.chatInfo.TeamMsg
end

function ChatData:AddSystemMsg(chatMsg)
  if self.chatInfo.SysMsg == nil then
    self.chatInfo.SysMsg = {}
  end
  local upNum = Data.chatData:getSaveMsgUp()
  if upNum < #self.chatInfo.SysMsg then
    table.remove(self.chatInfo.SysMsg, 1)
  end
  table.insert(self.chatInfo.SysMsg, chatMsg)
end

function ChatData:GetSystemMsg()
  return self.chatInfo.SysMsg
end

function ChatData:AddLocalInfoByUid(chatMsg, uid)
  if self.chatInfo.LocalMsg == nil then
    self:InitLocalInfo()
  end
  local upNum = Data.chatData:getSaveMsgUp()
  if self.chatInfo.LocalMsg[uid] == nil then
    self.chatInfo.LocalMsg[uid] = {}
  end
  if upNum < #self.chatInfo.LocalMsg[uid] then
    table.remove(self.chatInfo.LocalMsg[uid], 1)
  end
  return table.insert(self.chatInfo.LocalMsg[uid], chatMsg)
end

function ChatData:GetLocalInfoByUid(uid)
  if self.chatInfo.LocalMsg == nil then
    self:InitLocalInfo()
  end
  if self.chatInfo.LocalMsg[uid] == nil then
    self.chatInfo.LocalMsg[uid] = {}
  end
  return self.chatInfo.LocalMsg[uid]
end

function ChatData:AddWorldSendNum(addNum)
  addNum = addNum or 1
  self.chatInfo.WorldNum = self.chatInfo.WorldNum + addNum
end

function ChatData:SetWorldSendNum(num)
  self.chatInfo.WorldNum = num
end

function ChatData:GetWorldSendNum()
  return self.chatInfo.WorldNum
end

function ChatData:SetChatChannel(chatChannel)
  self.chatChannel = chatChannel
end

function ChatData:GetChatChannel()
  return self.chatChannel or ChatChannel.WorldBase
end

function ChatData:SetRoomNum(roomNum)
  self.nowRoomNum = roomNum
end

function ChatData:GetRoomNum()
  return self.nowRoomNum
end

function ChatData:ResetRoomNum()
  self.nowRoomNum = 1
end

function ChatData:SetChatWay(chatWay)
  self.chatWay = chatWay
end

function ChatData:GetChatWay()
  return self.chatWay
end

function ChatData:SetlastSendTimeByChannel(channelType, lastSendTime)
  self.tabLastSendTime[channelType] = lastSendTime
end

function ChatData:GetlastSendTimeByChannel(channelType)
  return self.tabLastSendTime[channelType] or 0
end

function ChatData:ResetCoolTime()
  self.tabLastSendTime = {}
end

function ChatData:ResetCoolTimeByCannel(channelType)
  self:SetlastSendTimeByChannel(channelType, 0)
end

function ChatData:getSaveMsgUp()
  return configManager.GetDataById("config_parameter", 48).value
end

function ChatData:getPersionNumUp()
  return configManager.GetDataById("config_parameter", 97).value
end

function ChatData:isRecentChatUser(uid)
  local receentChatUser = Data.chatData:GetRecentChatUser()
  for k, v in ipairs(receentChatUser) do
    if v.Uid == uid then
      return k
    end
  end
  return nil
end

return ChatData
