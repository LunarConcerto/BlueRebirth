local ChatLogic = class("logic.ChatLogic")
ChatLogic.VOICEMAX = 60

function ChatLogic:initialize()
  self:RegisterAllEvent()
  self:CreateBarrageLookupTable()
  self:ResetData()
end

function ChatLogic:ResetData()
  self.m_tryPlay = {
    Try = false,
    Msg = {}
  }
  self.m_playingTag = false
  self.m_playingVoice = {}
  self.m_recordTag = false
  self.m_personChatType = 0
  self:ResetChatContext()
  self.m_initPos = nil
end

function ChatLogic:ResetChatContext()
  self.m_chatContext = {
    voiceWay = VoiceWay.VOICE,
    chatKind = ChatKind.PLC,
    recordTime = 0,
    slideState = ChatRecordSlideState.NONE,
    recordState = MChatVoiceCommonState.NO,
    playing = false,
    playingVoice = nil,
    chatType = ChatMsgType.TEXT,
    voiceAnim = nil
  }
end

function ChatLogic:GetChatContext()
  return self.m_chatContext
end

function ChatLogic:SetVoiceWay(way)
  self.m_chatContext.voiceWay = way
end

function ChatLogic:SetChatKind(kind)
  self.m_chatContext.chatKind = kind
end

function ChatLogic:SetRecordTime(time)
  self.m_chatContext.recordTime = time
end

function ChatLogic:SetRecordSlideState(state)
  self.m_chatContext.slideState = state
  if state == ChatRecordSlideState.NONE then
    self.m_initPos = nil
  end
end

function ChatLogic:SetRecording(state)
  self.m_chatContext.recordState = state
end

function ChatLogic:SetChatType(type)
  self.m_chatContext.chatType = type
end

function ChatLogic:SetIsPlaying(isOn)
  self.m_chatContext.playing = isOn
end

function ChatLogic:SetPlayingVoice(msg)
  self.m_chatContext.playingVoice = msg
end

function ChatLogic:SetCurVoiceAnim(widget)
  self.m_chatContext.voiceAnim = widget
end

function ChatLogic:SetTryPlayVoice(bo, msg)
  self.m_tryPlay = {Try = bo, Msg = msg}
end

function ChatLogic:GetTryPlayVoice()
  return self.m_tryPlay.Try, self.m_tryPlay.Msg
end

function ChatLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaCSharpEvent.SaveChatInfo, function(self, param)
    if param == ChatSaveScene.AppClose then
      memoryUtil.RecordFinish()
      memoryUtil.LuaMemory("\230\184\184\230\136\143\229\133\179\233\151\173", false, true)
    end
    if not Data.chatData:GetChatInfoTog() then
      return
    end
    Data.chatData:SaveRecentEmoji()
  end, self)
  eventManager:RegisterEvent(LuaCSharpEvent.InitLocalChat, function()
    Data.chatData:InitLocalInfo()
  end)
  eventManager:RegisterEvent(LuaCSharpEvent.TryStopVoice, function(self, param)
    local playing = Logic.chatLogic:GetChatContext().playing
    if playing then
      Logic.chatLogic:StopPlay()
      Logic.chatLogic:SetIsPlaying(false)
    end
  end, self)
  eventManager:RegisterEvent(LuaEvent.UpdateUserOnLineState, self.AddFriendStateMsg, self)
end

function ChatLogic:AddFriendStateMsg(params)
  local friendStatusStr = {
    [UserStatusType.Online] = UIHelper.GetString(210013),
    [UserStatusType.Offline] = UIHelper.GetString(210014)
  }
  local userStatus = params.Type
  local uid = params.Uid
  if friendStatusStr[userStatus] == nil then
    logError("Chat Logic:There is no such user status")
    return
  end
  local userName = Data.friendData:GetFriendNameByUid(uid)
  local resStr = string.format(friendStatusStr[userStatus], userName)
  local sysMsg = Data.chatData:GetSystemChatTemplate(resStr)
  Data.chatData:AddChatMsg(sysMsg)
end

function ChatLogic:IsChatInterval(nowTime, lastChatTime)
  if lastChatTime == 0 or lastChatTime == nil then
    return true
  end
  return nowTime - lastChatTime < 15
end

function ChatLogic:GetChannelCoolTime(channelType)
  return configManager.GetDataById("config_chat_send_interval", channelType).time
end

function ChatLogic:IsCoolTime(channelType)
  local coolTime = self:GetChannelCoolTime(channelType)
  local lastSendTime = Data.chatData:GetlastSendTimeByChannel(channelType)
  return coolTime > time.getSvrTime() - lastSendTime
end

function ChatLogic:GetAllowChatTime(channelType)
  local coolTime = self:GetChannelCoolTime(channelType)
  local lastSendTime = Data.chatData:GetlastSendTimeByChannel(channelType)
  return coolTime - (time.getSvrTime() - lastSendTime)
end

function ChatLogic:IsInfoInterval(chatMsg1, chatMsg2)
  if chatMsg1 == nil or chatMsg2 == nil then
    return true
  end
  return math.abs(chatMsg2.SendTime - chatMsg1.SendTime) > 300
end

function ChatLogic:IsChatInfoToday(chatInfo)
  return time.isSameDay(time.getSvrTime(), chatInfo.SendTime)
end

function ChatLogic:SetChatSet(key, value)
  PlayerPrefs.SetInt(key, value)
end

function ChatLogic:GetChatSet(key)
  return PlayerPrefs.GetInt(key, 0)
end

function ChatLogic:GetChatSetConfig()
  return configManager.GetData("config_chat_set")
end

function ChatLogic:GetChatSetConfigById(id)
  return configManager.GetDataById("config_chat_set", id)
end

function ChatLogic:GetChatTipChannel()
  local tabTemp = {}
  local config = self:GetChatSetConfig()
  for k, v in pairs(config) do
    if v.belong == 3 and self:GetChatSet(v.key) == 2 then
      table.insert(tabTemp, v.channel)
    end
  end
  return tabTemp
end

function ChatLogic:GetEmojiConfgByTag(emojiTag)
  emojiTag = emojiTag or ChatEmojiTags.Default
  if emojiTag == ChatEmojiTags.Recent then
    return self:GetRecentEmojiInfo()
  elseif emojiTag == ChatEmojiTags.Default then
    return self:GetDefaultEmojiInfo()
  else
    logError("Chat Logic Error:Can't fine" .. emojiTag .. "emoji tag")
  end
end

function ChatLogic:GetAllEmojiData()
  local data = {}
  local packs = configManager.GetData("config_emoji_pack")
  for i, pack in ipairs(packs) do
    local list = {}
    for i, id in pairs(pack.picture) do
      local emoji = configManager.GetDataById("config_emoji", id)
      table.insert(list, emoji)
    end
    table.insert(data, list)
  end
  local recent = Data.chatData:GetRecentEmojiList()
  table.insert(data, 1, recent)
  return data
end

function ChatLogic:GetColConstraintCount(pageCol, pageRow, total)
  local pageCount = pageCol * pageRow
  local pages = math.floor(total / pageCount)
  local lastPageCount = total - pages * pageCount
  local lastPageCol = pageCol > lastPageCount and lastPageCount or pageCol
  local colConstraintCount = pages * pageCol + lastPageCol
  return colConstraintCount
end

function ChatLogic:GetDefaultEmojiInfo()
  local tabTemp = {}
  local config = configManager.GetData("config_chat_emoji")
  for k, v in pairs(config) do
    tabTemp[#tabTemp + 1] = v
  end
  return tabTemp
end

function ChatLogic:IsEmojiMsg(msg, isMe)
  local ret = string.match(msg, "^<%d+>$")
  local conf
  local id = string.match(msg, "%d+")
  local unlock = true
  if id then
    conf = configManager.GetDataById("config_emoji", id, true)
    if isMe then
      unlock = self:IsEmojiUnlock(id).isUnlock
    end
  end
  return ret ~= nil and conf ~= nil and unlock
end

function ChatLogic:GetEmojiInfoById(id)
  return configManager.GetDataById("config_emoji", id)
end

function ChatLogic:GetRecentEmojiInfo()
  return Data.chatData:GetRecentEmojiList()
end

function ChatLogic:IsRecentUp(emojiNum)
  return emojiNum >= self:GetRecentEmojiSaveUp()
end

function ChatLogic:GetRecentEmojiSaveUp()
  return 30
end

function ChatLogic:HaveMask(msg)
  return self:_HaveRichText(msg)
end

function ChatLogic:_HaveRichText(msg)
  return RichTextUtil.Have(msg)
end

function ChatLogic:FilterMask(msg)
  return self:_ReplaceRichText(msg)
end

function ChatLogic:_ReplaceRichText(msg)
  return RichTextUtil.Replace(msg)
end

function ChatLogic:GetLastChat(uid)
  local lastMsg = ""
  local tabChatInfo = Data.chatData:GetLocalInfoByUid(uid)
  if tabChatInfo == nil or #tabChatInfo == 0 then
    return lastMsg
  end
  if tabChatInfo[#tabChatInfo].MsgType == ChatMsgType.VOICE then
    return UIHelper.GetString(220005)
  end
  return tabChatInfo[#tabChatInfo].Message
end

function ChatLogic:GetEmojiSlot(totalNums, columns)
  local slotValue = 0
  if totalNums % columns == 0 then
    slotValue = totalNums
  else
    slotValue = totalNums + columns - totalNums % columns
  end
  return slotValue
end

function ChatLogic:GetMsgChannel(chatMsg)
  return chatMsg.Channel
end

function ChatLogic:IsNowRoomWorldMsg(chatMsg)
  local channel = self:GetMsgChannel(chatMsg)
  if self:IsWorldChannel(channel) then
    local roomNum = Data.chatData:GetRoomNum()
    return roomNum == channel - ChatChannel.WorldBase
  end
  return false
end

function ChatLogic:IsPersionMsg(chatMsg)
  local channel = self:GetMsgChannel(chatMsg)
  if channel == ChatChannel.Friend or channel == ChatChannel.Personal then
    return true
  else
    return false
  end
end

function ChatLogic:IsNowChannel(chatMsg)
  local channel = self:GetMsgChannel(chatMsg)
  local nowChannelType = Data.chatData:GetChatChannel()
  if self:IsWorldChannel(channel) then
    return nowChannelType == ChatChannel.WorldBase
  end
  if self:IsPersonChanalType(channel) then
    return true
  else
    return nowChannelType == channel
  end
end

function ChatLogic:IsMySendMsg(chatMsg)
  local myUid = Data.userData:GetUserData().Uid
  return chatMsg.UserInfo.Uid == myUid
end

function ChatLogic:IsWorldChannel(channelId)
  return 900 <= channelId and channelId < 1000
end

function ChatLogic:IsPublicChanelType(channelType)
  return channelType == ChatChannel.WorldBase or channelType == ChatChannel.Guild or channelType == ChatChannel.System or channelType == ChatChannel.Team or channelType == 901
end

function ChatLogic:IsPersonChanalType(channelType)
  return channelType == ChatChannel.Personal or channelType == ChatChannel.Friend
end

function ChatLogic:GetWorldNumUp(lv)
  return configManager.GetDataById("config_player_levelup", lv).world_chat_count_limit or 0
end

function ChatLogic:HaveUnReadMsgByChannel(channelType, roomNum)
  local num = Data.chatData:GetUnReadNumByChannelType(channelType, roomNum)
  if num == 0 or num == nil then
    return false
  end
  return true
end

function ChatLogic:IsMeUserInfo(uid)
  return uid == Data.userData:GetUserData().Uid
end

function ChatLogic:DealFriendList(tabFriend)
  local tabTemp = tabFriend
  local tabRes = {}
  for _, v in pairs(tabTemp) do
    local block = Logic.friendLogic:IsMyBlock(v.UserInfo.Uid)
    if not block then
      tabRes[#tabRes + 1] = v.UserInfo
    end
  end
  return tabRes
end

function ChatLogic:MsgCut(msg, up)
  if up < utf8.len(msg) then
    return utf8.sub(msg, 1, up + 1), true
  else
    return msg, false
  end
end

function ChatLogic:GetUserHead(usr)
  local fid = usr.Fashioning
  local config = Logic.shipLogic:GetShipShowByFashionId(fid)
  local shipInfo = Logic.shipLogic:GetShipInfoById(usr.Head)
  local icon, qualityIcon
  if config and shipInfo then
    icon = config.ship_icon5
    qualityIcon = UserHeadQualityImg[shipInfo.quality]
    return icon, qualityIcon
  end
  local myData = Data.userData:GetUserData()
  config = Logic.shipLogic:GetShipShowByHeroId(myData.SecretaryId)
  shipInfo = Logic.shipLogic:GetShipInfoByHeroId(myData.SecretaryId)
  if usr.Uid and usr.Uid == myData.Uid and config and shipInfo then
    icon = config.ship_icon5
    qualityIcon = UserHeadQualityImg[shipInfo.quality]
    return icon, qualityIcon
  end
  local ss_id = usr.Head
  if ss_id == 0 then
    ss_id = configManager.GetDataById("config_parameter", 17).value
  end
  config = Logic.shipLogic:GetShipShowById(ss_id)
  shipInfo = Logic.shipLogic:GetShipInfoById(ss_id)
  icon = config.ship_icon5
  qualityIcon = UserHeadQualityImg[shipInfo.quality]
  return icon, qualityIcon
end

function ChatLogic:SortUserListByChatTime(tabUserList)
  if #tabUserList <= 1 then
    return tabUserList
  end
  table.sort(tabUserList, function(data1, data2)
    local lastTime1 = self:GetLastChatTime(data1.Uid)
    local lastTime2 = self:GetLastChatTime(data2.Uid)
    return lastTime1 > lastTime2
  end)
  return tabUserList
end

function ChatLogic:GetLastChatTime(uid)
  local lastTime = 0
  local tabChatInfo = Data.chatData:GetLocalInfoByUid(uid)
  if tabChatInfo == nil or #tabChatInfo == 0 then
    return lastTime
  end
  return tabChatInfo[#tabChatInfo].SendTime
end

function ChatLogic:IsInBan()
  local bantime = Data.chatData:GetChatBanTime()
  local msg = Data.chatData:GetChatBanMsg()
  return bantime > time.getSvrTime(), msg
end

function ChatLogic:GetRecentChatUser()
  local base = Data.chatData:GetRecentChatUser()
  local res = {}
  for _, v in ipairs(base) do
    local block = Logic.friendLogic:IsMyBlock(v.Uid)
    if not block then
      table.insert(res, v)
    end
  end
  return res
end

function ChatLogic:GetNowChatUserInfo()
  local uid = Data.chatData:GetNowChatUserInfo()
  if uid then
    local block = Logic.friendLogic:IsMyBlock(uid)
    if block then
      return 0
    end
    return uid
  end
  return 0
end

function ChatLogic:StartRecord()
  platformManager:StartRecord()
end

function ChatLogic:StopRecord()
  platformManager:StopRecord()
end

function ChatLogic:CancelRecord()
  platformManager:CancelRecord()
end

function ChatLogic:DownloadVoice(url)
  platformManager:DownloadVoice(url)
end

function ChatLogic:PlayVoice(filePath)
  platformManager:PlayVoice(filePath)
end

function ChatLogic:StopPlay()
  platformManager:StopPlay()
end

function ChatLogic:IsVoiceSDKInit()
  return platformManager:CheckVoiceInit()
end

function ChatLogic:GetVocieTimeMax()
  return Mathf.Min(configManager.GetDataById("config_parameter", 133).value, ChatLogic.VOICEMAX)
end

function ChatLogic:CheckVoiceTime(time)
  local res = self:GetVocieTimeMax() - time
  return 0 < res, res
end

function ChatLogic:CheckMsgType(msg)
  if msg.MsgType == nil then
    return ChatMsgType.TEXT
  end
  return msg.MsgType
end

function ChatLogic:CheckMsgNew(msg)
  if msg.New == nil then
    return false
  end
  return msg.New
end

function ChatLogic:CheckDownloadVoice(message)
  return message and message.code and message.code == 0 and message.voiceUrl
end

function ChatLogic:CheckVoiceMsg(message)
  return message and message.code and message.code == 0 and message.voiceUrl and message.savePath
end

function ChatLogic:AssertVoiceCode(code)
  if code == 0 then
    return true, ""
  end
  local data = configManager.GetDataById("config_voice_chat_err", code)
  local msg = data ~= nil and data.notice or "\232\175\173\233\159\179\230\168\161\229\157\151\230\156\170\231\159\165\233\148\153\232\175\175,\233\148\153\232\175\175\231\160\129:" .. code
  return code == 0, msg
end

function ChatLogic:GetRecordThreshold()
  return 50
end

function ChatLogic:GetRecordState(eventData)
  local position = eventData.position
  if self.m_initPos == nil then
    self.m_initPos = position
  end
  local delta = position.y - self.m_initPos.y
  local threshold = self:GetRecordThreshold()
  local state = self:GetChatContext().slideState
  if state == ChatRecordSlideState.NONE then
    if delta > threshold then
      self:SetRecordSlideState(ChatRecordSlideState.UP)
    elseif delta < -threshold then
      self:SetRecordSlideState(ChatRecordSlideState.DOWN)
    end
  elseif state == ChatRecordSlideState.UP then
    if delta < 0 then
      self:SetRecordSlideState(ChatRecordSlideState.DOWN)
    else
      self:SetRecordSlideState(ChatRecordSlideState.UP)
    end
  elseif delta > threshold then
    self:SetRecordSlideState(ChatRecordSlideState.UP)
  else
    self:SetRecordSlideState(ChatRecordSlideState.DOWN)
  end
  state = self:GetChatContext().slideState
  return state
end

function ChatLogic:GetVoiceDurtion(msg)
  local table = Unserialize(msg)
  if table and table.duration then
    return Mathf.ToInt(tonumber(table.duration))
  end
  return 0
end

function ChatLogic:GetFriendTagUnReadNum()
  local info = Data.chatData:GetUnReadNumInfo()
  local friends = Data.friendData:GetFriendData()
  if info == nil or friends == nil then
    return 0
  end
  local uidCaches = {}
  for _, v in pairs(friends) do
    uidCaches[v.UserInfo.Uid] = 0
  end
  local res = 0
  for id, num in pairs(info) do
    if uidCaches[id] then
      res = res + num
    end
  end
  return res
end

function ChatLogic:GetPersonTagUnReadNum()
  return Data.chatData:GetPersionUnReadNum()
end

function ChatLogic:GetUserUnReadNum(uid)
  return Data.chatData:GetPersionUnReadNumByUid(uid) or 0
end

function ChatLogic:CreateBarrageLookupTable()
  local lookup = {}
  local barrageCfg = configManager.GetData("config_barrage_library")
  for i, barrage in pairs(barrageCfg) do
    lookup[barrage.scene_id_type] = lookup[barrage.scene_id_type] or {}
    local typeTable = lookup[barrage.scene_id_type]
    local br = {}
    br.chat_id = barrage.barrage_library_id
    br.scene_id = barrage.scene_id
    br.track_closed = barrage.is_orbital_colse
    typeTable[barrage.scene_id] = br
  end
  self.barrageLookupTable = lookup
end

function ChatLogic:GetBarrageRec(sceneId, btype)
  local rec = self.barrageLookupTable[btype][sceneId]
  assert(rec ~= nil, string.format("GetBarrageRec not found type %d, sceneId %d", btype, sceneId))
  return rec
end

function ChatLogic:ParseBarrageParam(paramStr)
  local params = string.split(paramStr, ",")
  local data = {}
  data.time = params[1]
  data.mode = params[2]
  data.size = params[3]
  data.color = params[4]
  data.timestamp = params[5]
  data.pool = params[6]
  data.uid = params[7]
  data.rowId = params[8]
  return data
end

function ChatLogic:SetBarrageCD()
  local cd = configManager.GetDataById("config_parameter", 135).value
  local now = time.getSvrTime()
  self.barrageCDTime = now + cd
end

function ChatLogic:GetBarrageCD()
  local ret = 0
  if self.barrageCDTime then
    local now = time.getSvrTime()
    ret = self.barrageCDTime - now
    if ret < 0 then
      ret = 0
    end
  end
  return ret
end

function ChatLogic:SetBarrageState(state)
  local uid = Data.userData:GetUserUid()
  PlayerPrefs.SetInt("BarrageState" .. uid, state)
end

function ChatLogic:GetBarrageState()
  local uid = Data.userData:GetUserUid()
  return PlayerPrefs.GetInt("BarrageState" .. uid, 1)
end

function ChatLogic:IsOnLine(uid)
  local isfriend = Logic.friendLogic:IsMyFriend(uid)
  if isfriend then
    return Logic.friendLogic:IsOnLine(uid)
  else
    return true
  end
end

function ChatLogic:GetUserStatus(uid)
  local isfriend, info = Logic.friendLogic:IsMyFriend(uid)
  if isfriend then
    return Logic.friendLogic:GetUserStatus(info.OfflineTime, uid)
  else
    return ""
  end
end

function ChatLogic:ModifyChatChannelStatus(channel, isRecv)
  if not isRecv then
    local cur_channel = Data.chatData:GetChatChannel()
    if cur_channel == channel then
      Data.chatData:SetChatChannel(ChatChannel.WorldBase)
    end
    Data.chatData:ResetGuildMsg()
  end
  eventManager:SendEvent(LuaEvent.CHAT_ChatChannelRecvChange, channel)
end

function ChatLogic:IsEmojiUnlock(emojiId)
  local emojiCfg = configManager.GetDataById("config_emoji", emojiId, true)
  if emojiCfg == nil then
    return {
      isUnlock = false,
      lockPlotId = 0,
      lockItemId = 0
    }
  end
  local plotIdArr = emojiCfg.plot_id
  local plotMap = {}
  local datas = Data.illustrateData:GetHeroMemorys()
  for heroId, plots in pairs(datas) do
    for pid, _ in pairs(plots) do
      plotMap[pid] = true
    end
  end
  for i, plotId in ipairs(plotIdArr) do
    if not plotMap[plotId] then
      return {
        isUnlock = false,
        lockPlotId = plotId,
        lockItemId = 0
      }
    end
  end
  if 0 < emojiCfg.item_unlock then
    local count = Data.bagData:GetItemNum(emojiCfg.item_unlock)
    if count <= 0 then
      return {
        isUnlock = false,
        lockPlotId = 0,
        lockItemId = emojiCfg.item_unlock
      }
    end
  end
  return {
    isUnlock = true,
    lockPlotId = 0,
    lockItemId = 0
  }
end

function ChatLogic:CheckEmojiUnlockItem(emojiId)
  local emojiCfg = configManager.GetDataById("config_emoji", emojiId)
  if emojiCfg == nil then
    return false
  end
  if emojiCfg.item_unlock > 0 then
    local count = Data.bagData:GetItemNum(emojiCfg.item_unlock)
    return 0 < count
  end
  return true
end

function ChatLogic:GetLockedEmoji()
  local locked = {}
  local plotMap = {}
  local emojiCfg = configManager.GetData("config_emoji")
  local datas = Data.illustrateData:GetHeroMemorys()
  for heroId, plots in pairs(datas) do
    for pid, _ in pairs(plots) do
      plotMap[pid] = true
    end
  end
  for i, cfg in pairs(emojiCfg) do
    for i, plotId in ipairs(cfg.plot_id) do
      if not plotMap[plotId] then
        locked[cfg.id] = true
        break
      end
    end
  end
  return locked
end

function ChatLogic:InitLockedEmoji(dirty)
  if not self.lockedEmoji or dirty then
    self.lockedEmoji = self:GetLockedEmoji()
  end
end

function ChatLogic:GetNewUnlockEmoji()
  local new = {}
  local now = self:GetLockedEmoji()
  local old = self.lockedEmoji
  for eid, v in pairs(old) do
    if not now[eid] then
      table.insert(new, eid)
    end
  end
  return new
end

function ChatLogic:CheckFastUser()
  return platformManager:CheckFastUser()
end

return ChatLogic
