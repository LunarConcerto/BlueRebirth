local ChatService = class("service.ChatService", Service.BaseService)

function ChatService:initialize()
  self:_InitHandlers()
end

function ChatService:_InitHandlers()
  self:BindEvent("chat.ChatInfo", self._ChatInfo, self)
  self:BindEvent("chat.ChangeWorldChannel", self._ChangeWorldChannel, self)
  self:BindEvent("chat.SendMessage", self._SendMessage, self)
  self:BindEvent("chat.NewMessage", self._NewMessage, self)
  self:BindEvent("chat.SendBarrage", self._SendBarrageCallback, self)
  self:BindEvent("chat.GetBarrageById", self._GetBarragesCallback, self)
end

function ChatService:SendChangeWorldChannel(channel)
  local args = {Channel = channel}
  args = dataChangeManager:LuaToPb(args, chat_pb.TCHATCHANGECHANNELARG)
  self:SendNetEvent("chat.ChangeWorldChannel", args)
end

function ChatService:SendMessage(channel, receiveUid, message, type, text)
  local args = {
    Channel = channel,
    ReceiveUid = receiveUid,
    Message = message,
    MsgType = type,
    Voice = text
  }
  args = dataChangeManager:LuaToPb(args, chat_pb.TCHATSENDMESSAGEARG)
  self:SendNetEvent("chat.SendMessage", args, type)
end

function ChatService:_ChatInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("chat info return errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, chat_pb.TCHATINFORET)
    Data.chatData:SetChatInfo(args)
  end
end

function ChatService:_ChangeWorldChannel(ret, state, err, errmsg)
  self:SendLuaEvent(LuaEvent.UpdataChatInfo, nil)
end

function ChatService:_SendMessage(ret, state, err, errmsg)
  if err ~= 0 then
    self:SendLuaEvent(LuaEvent.ChatMsgMask, err)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, chat_pb.TCHATSENDMESSAGERET)
    local channelType = Data.chatData:GetChatChannel()
    local channel = channelType
    local roomNum = Data.chatData:GetRoomNum()
    if channelType == ChatChannel.WorldBase then
      channel = roomNum + ChatChannel.WorldBase
    end
    local receiveUid = 0
    local isPublic = Logic.chatLogic:IsPublicChanelType(channel)
    if not isPublic then
      receiveUid = Data.chatData:GetNowChatUserInfo()
    end
    local myMsgTemplate = Data.chatData:GetMyChatTemplate(channel, time.getSvrTime(), args.Message, state)
    Data.chatData:AddChatInfo(myMsgTemplate, channelType, roomNum, receiveUid)
    self:SendLuaEvent(LuaEvent.UpdataChatInfo, true)
  end
end

function ChatService:_NewMessage(ret, state, err, errmsg)
  if err ~= 0 then
    logError("new message return errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, chat_pb.TCHATMSG)
    if Data.chatData:GetBlockTog() and Logic.friendLogic:IsMyBlock(args.UserInfo.Uid) then
      return
    end
    local isSelf = Logic.chatLogic:IsMeUserInfo(args.UserInfo.Uid)
    if not isSelf or 0 < args.TemplateId then
      Data.chatData:AddChatMsg(args)
      local room = Data.chatData:GetRoomNum()
      Data.chatData:AddUnReadInfoNum(args.Channel, args.UserInfo.Uid, room)
    end
    if Logic.chatLogic:IsPersionMsg(args) or Logic.chatLogic:IsNowRoomWorldMsg(args) then
      if Logic.chatLogic:IsPersionMsg(args) then
        Data.chatData:AddRecentChatUser(args)
        Data.chatData:SetNowChatUserInfo(args.UserInfo.Uid)
      end
      self:SendLuaEvent(LuaEvent.UpdataHomeChat, nil)
    end
    if Logic.chatLogic:IsNowChannel(args) then
      self:SendLuaEvent(LuaEvent.UpdataChatInfo, nil)
    end
  end
end

function ChatService:SendBarrage(chatId, offset, content)
  local args = {
    Id = chatId,
    Offset = offset,
    Content = content
  }
  args = dataChangeManager:LuaToPb(args, chat_pb.TSENDBARRAGEDATAARG)
  self:SendNetEvent("chat.SendBarrage", args, args)
end

function ChatService:_SendBarrageCallback(ret, state, err, errmsg)
  if err ~= 0 then
    if err == 2106 then
      noticeManager:ShowTip(UIHelper.GetString(941003))
    else
      logError("_SendBarrageCallback return errmsg:" .. errmsg)
    end
    return
  end
  if ret ~= nil then
    self:SendLuaEvent(LuaEvent.SendBarrage, state)
  end
end

function ChatService:GetBarrages(chatId, beginIndex, len)
  local args = {
    Id = chatId,
    BeginIndex = beginIndex,
    Len = len
  }
  args = dataChangeManager:LuaToPb(args, chat_pb.TGETBARRAGEDATAARG)
  self:SendNetEvent("chat.GetBarrageById", args)
end

function ChatService:_GetBarragesCallback(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetBarragesCallback return errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, chat_pb.TGETBARRAGEDATARET)
    self:SendLuaEvent(LuaEvent.GetBarrage, args)
  end
end

return ChatService
