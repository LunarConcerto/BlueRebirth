local ChatPage = class("UI.Chat.ChatPage", LuaUIPage)
local ShowType = {chat = 1, user = 2}
local layerDelta = 100
local emojiToggleMaxWidth = 160
local CHAT_MsgTextMaxWidth = 306
local CHAT_MsgItemMinHeight = 135
local ChannelShowType = {
  [ChatChannel.WorldBase] = ShowType.chat,
  [ChatChannel.Guild] = ShowType.chat,
  [ChatChannel.Friend] = ShowType.user,
  [ChatChannel.Personal] = ShowType.user,
  [ChatChannel.System] = ShowType.chat,
  [ChatChannel.Team] = nil
}
local ChannelTipStr = {
  [ChatChannel.WorldBase] = nil,
  [ChatChannel.Guild] = nil,
  [ChatChannel.Friend] = "\232\175\183\233\128\137\230\139\169\228\184\128\228\189\141\229\165\189\229\143\139\229\188\128\229\167\139\232\129\138\229\164\169",
  [ChatChannel.Personal] = "\232\175\183\233\128\137\230\139\169\228\184\128\228\189\141\231\142\169\229\174\182\229\188\128\229\167\139\229\175\134\232\129\138",
  [ChatChannel.System] = "\231\179\187\231\187\159\233\162\145\233\129\147\228\184\141\232\131\189\229\143\145\233\128\129\230\182\136\230\129\175",
  [ChatChannel.Team] = nil
}
local ChannelTogMap = {
  [ChatChannel.WorldBase] = 1,
  [ChatChannel.Guild] = 2,
  [ChatChannel.Friend] = 3,
  [ChatChannel.Personal] = 4,
  [ChatChannel.System] = 5,
  [ChatChannel.Team] = 6
}
local emojiPosX = {
  [ChatKind.PLC] = 122,
  [ChatKind.PSN] = 678
}
local CHAT_voiceRootPoxS = {
  [ChatKind.PLC] = 30,
  [ChatKind.PSN] = 590
}
local VoiceFuncMap = {}
local PersonChatFuncMap = {}

function ChatPage:DoInit()
  self.m_tabWidgets = nil
  self.m_tabTips = {}
  self.m_pvTabTips = {}
  self.m_togEmoji = false
  self.m_togPvEmoji = false
  self.m_userInfo = nil
  self.m_tabSelectUserObj = {}
  self.m_tabSelectUserObjIcon = {}
  self.m_onRecord = false
  self.scaleZeroTimer = nil
  self.scaleOneTimer = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self:_CacheWidgets()
  self:_RegisterListeners()
  self:_InitVoiceFuncMap()
end

function ChatPage:_CacheWidgets()
  local widgets = self:GetWidgets()
  self.tabInput = {
    [ChatKind.PLC] = widgets.input_content,
    [ChatKind.PSN] = widgets.input_pvtcontent
  }
  self.tabTogs = {
    widgets.tog_world,
    widgets.tog_guild,
    widgets.tog_friend,
    widgets.tog_personal,
    widgets.tog_system,
    widgets.tog_team
  }
  self.m_pvEmojiTag = {
    widgets.tog_recent,
    widgets.tog_default
  }
end

function ChatPage:_RegisterListeners()
  local widgets = self:GetWidgets()
  for i, tog in ipairs(self.tabTogs) do
    widgets.tog_group:RegisterToggle(tog)
  end
  self:_initChannelTog()
  local packs = clone(configManager.GetData("config_emoji_pack"))
  table.insert(packs, 1, {type_name = "\230\156\128\232\191\145"})
  local packCount = #packs
  self.emojiParts = {}
  UIHelper.CreateSubPart(widgets.tog_item, widgets.trans_emojiGroup, packCount, function(index, part)
    local data = packs[index]
    UIHelper.SetText(part.name, data.type_name)
    UIHelper.SetText(part.name_selected, data.type_name)
    table.insert(self.emojiParts, part)
    part.obj_selected:SetActive(true)
    part.obj_normal:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btn, self.SwitchEmojiToggle, self, index)
  end)
  local ftimer = FrameTimer.New(function()
    for _, widgets in ipairs(self.emojiParts) do
      if not IsNil(widgets.obj_selected) then
        widgets.obj_selected:SetActive(false)
      end
    end
  end, 1, 1)
  ftimer:Start()
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group, self, nil, self._SwitchTogs)
  widgets.input_content.onValueChanged:AddListener(function(msg)
    local res, ischarUp = Logic.chatLogic:MsgCut(msg, 40)
    if ischarUp then
      noticeManager:ShowTip(UIHelper.GetString(220001))
    end
    widgets.input_content.text = res
    Logic.chatLogic:SetChatType(ChatMsgType.TEXT)
  end)
  widgets.input_pvtcontent.onValueChanged:AddListener(function(msg)
    local res, ischarUp = Logic.chatLogic:MsgCut(msg, 40)
    if ischarUp then
      noticeManager:ShowTip(UIHelper.GetString(220001))
    end
    widgets.input_pvtcontent.text = res
    Logic.chatLogic:SetChatType(ChatMsgType.TEXT)
  end)
end

function ChatPage:_InitVoiceFuncMap()
  VoiceFuncMap = {
    [VoiceBackType.OnInitVoiceSDK] = self._OnVoiceSDKInit,
    [VoiceBackType.OnStartRecord] = self._OnStartRecord,
    [VoiceBackType.OnStopRecord] = self._OnStopRecord,
    [VoiceBackType.OnCancelRecord] = self._OnCancelRecord,
    [VoiceBackType.OnDownloadFile] = self._OnDownloadFile,
    [VoiceBackType.OnPlayComplete] = self._OnPlayVoice,
    [VoiceBackType.OnStopPlay] = self._OnStopPlay
  }
end

function ChatPage:DoOnOpen()
  self:_handleUiOrder()
  self.m_userInfo = self:GetParam()
  if self.m_userInfo ~= nil then
    Data.chatData:AddRecentChatUser(self.m_userInfo)
    Data.chatData:SetNowChatUserInfo(self.m_userInfo.Uid)
  end
  self:_LoadChat()
  Data.chatData:SetChatOpen(true)
end

function ChatPage:_handleUiOrder()
  local isbattle = self.cs_page.param:GetBool("isBattle", false)
  if isbattle then
    self:SetAdditionOrder(2000)
  end
end

function ChatPage:RegisterAllEvent()
  local widgets = self.m_tabWidgets
  UGUIEventListener.AddButtonOnClick(widgets.btn_set, self._OpenChatSet, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_room, self._ChangeChatRoom, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close1, self._CloseChat, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close2, self._ShowChatWindow, self, false)
  UGUIEventListener.AddOnEndDrag(widgets.sv_controller, self._SetEmojiTips, self)
  UGUIEventListener.AddButtonOnClick(widgets.obj_unReadTips, self._LoadChat, self)
  UGUIEventListener.AddButtonOnClick(widgets.obj_unReadPvTips, self._UpdataPersonChat, self)
  UGUIEventListener.AddButtonOnPointUp(widgets.im_mask, self._CloseChat, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_recordPlc, self._ShowSelectVoiceWay, self, true)
  UGUIEventListener.AddButtonOnLongPress(widgets.btn_recordPlc, self._OnLongPressRecord, self)
  UGUIEventListener.AddButtonOnPointUp(widgets.btn_recordPlc, self._OnPointUpRecord, self)
  UGUIEventListener.AddOnDrag(widgets.btn_recordPlc, self._OnDragRecord, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_voice, self._SwitchVoiceWay, self, VoiceWay.VOICE)
  UGUIEventListener.AddButtonOnClick(widgets.btn_voiceText, self._SwitchVoiceWay, self, VoiceWay.VOICE2TEXT)
  UGUIEventListener.AddButtonOnClick(widgets.btn_recordPsn, self._ShowSelectVoiceWay, self, true)
  UGUIEventListener.AddButtonOnLongPress(widgets.btn_recordPsn, self._OnLongPressRecord, self)
  UGUIEventListener.AddButtonOnPointUp(widgets.btn_recordPsn, self._OnPointUpRecord, self)
  UGUIEventListener.AddOnDrag(widgets.btn_recordPsn, self._OnDragRecord, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_emoji, self._CloseEmoji, self)
  self:RegisterEvent(LuaEvent.UpdataChatInfo, self._UpdataChat, self)
  self:RegisterEvent(LuaEvent.SwitchChatChannel, self._SwitchChannel, self)
  self:RegisterEvent(LuaEvent.UpdateUserOnLineState, self._LoadChat, self)
  self:RegisterEvent(LuaEvent.SetFriendBlackSuccess, self._UpdataChat, self)
  self:RegisterEvent(LuaEvent.GetFriendsInfo, self._OnGetFriendsInfo, self)
  self:RegisterEvent(LuaEvent.ChatMsgMask, self._OnMsgMask, self)
  self:RegisterEvent(LuaEvent.VoiceCallBack, self._RecordCallBack, self)
  self:RegisterEvent(LuaEvent.TryCancelRecordOrPlay, self._OnTryCancelRecordAndPlay, self)
  self:RegisterEvent(LuaCSharpEvent.LoseFocus, function(self, param)
    self:_OnLoseFocus()
  end)
  self:RegisterEvent(LuaEvent.CHAT_ChatChannelRecvChange, self._OnChannelRecvChange, self)
end

function ChatPage:_OnChannelRecvChange()
  self:_initChannelTog()
  self:_LoadChat()
end

function ChatPage:_initChannelTog()
  local widgets = self:GetWidgets()
  if Data.guildData:inGuild() then
    widgets.tog_group:RemoveToggleUnActive(1)
  else
    widgets.tog_group:ResigterToggleUnActive(1, function()
      noticeManager:ShowTip(UIHelper.GetString(710055))
    end)
  end
  local tip = function()
    noticeManager:ShowTip("\229\138\159\232\131\189\230\154\130\230\156\170\229\188\128\229\144\175")
  end
  widgets.tog_group:ResigterToggleUnActive(5, tip)
end

function ChatPage:_OnLoseFocus()
  self:_OnTryStopVoice()
  self:_OnTryCancelRecord()
  self:_ShowCancelRecordTip(false)
  self:_ShowRecordingTip(false)
  if self.m_recordTimer then
    self:StopTimer(self.m_recordTimer)
  end
end

function ChatPage:_RecordCallBack(ret)
  if VoiceFuncMap[ret.type] then
    VoiceFuncMap[ret.type](self, ret)
  else
    logError("try call unknown vocie callback type:" .. ret.type)
  end
end

function ChatPage:_OnMsgMask(param)
  if param == ErrorCode.ErrChatMask then
    local curChannel = Data.chatData:GetChatChannel()
    Data.chatData:ResetCoolTimeByCannel(curChannel)
    noticeManager:ShowTip(UIHelper.GetString(220003))
  elseif param == ErrorCode.ErrChatRepeat then
    noticeManager:ShowTip(UIHelper.GetString(220007))
  else
    logError("send message return errmsg:" .. param)
  end
  return
end

function ChatPage:_SwitchChannel(params)
  self.m_userInfo = params
  if self.m_userInfo ~= nil then
    Data.chatData:AddRecentChatUser(self.m_userInfo)
    Data.chatData:SetNowChatUserInfo(self.m_userInfo.Uid)
  end
  local widgets = self:GetWidgets()
  local channelType = Data.chatData:GetChatChannel()
  widgets.tog_group:SetActiveToggleIndex(ChannelTogMap[channelType] - 1)
end

function ChatPage:_UpdataPersonChat()
  local widgets = self.m_tabWidgets
  local uid = Data.chatData:GetNowChatUserInfo()
  local channelType = Data.chatData:GetChatChannel()
  local tabChatList = Data.chatData:GetChatInfo(channelType, nil, uid)
  self:_LoadChatList(widgets.pv_tableview, widgets.obj_pvtChatItem, widgets.sbar_chatWindow, tabChatList)
  widgets.obj_unReadPvTips:SetActive(false)
  Data.chatData:ResetUnReadNumByUid(uid)
end

function ChatPage:_UpdataChat(isSelf)
  local widgets = self.m_tabWidgets
  local channelType = Data.chatData:GetChatChannel()
  local roomNum
  if channelType == ChatChannel.WorldBase then
    roomNum = Data.chatData:GetRoomNum()
  end
  if Logic.chatLogic:IsPublicChanelType(channelType) then
    if self:_IsSvDwon(widgets.sv_publicchat) or isSelf then
      self:_LoadChat()
    else
      local num = Data.chatData:GetUnReadNumByChannelType(channelType, roomNum) or 0
      if 0 < num then
        widgets.obj_unReadTips:SetActive(true)
        UIHelper.SetText(widgets.tx_unReadTips, "\230\130\168\230\156\137" .. num .. "\230\157\161\230\156\170\232\175\187\230\182\136\230\129\175")
      else
        self:_LoadChat()
      end
    end
  else
    local uid = Logic.chatLogic:GetNowChatUserInfo()
    if uid == 0 then
      self:_ShowChatWindow(nil, false)
    elseif self:_IsSvDwon(widgets.sv_personchat) or isSelf then
      local tabChatList = Data.chatData:GetChatInfo(channelType, nil, uid)
      self:_LoadChatList(widgets.pv_tableview, widgets.obj_pvtChatItem, widgets.sbar_chatWindow, tabChatList)
      Data.chatData:ResetUnReadNumByUid(uid)
    else
      local num = Data.chatData:GetPersionUnReadNumByUid(uid) or 0
      widgets.obj_unReadPvTips:SetActive(true)
      UIHelper.SetText(widgets.tx_unReadPvTips, "\230\130\168\230\156\137" .. num .. "\230\157\161\230\156\170\232\175\187\230\182\136\230\129\175")
    end
    self:_ShowUserInfo(widgets, channelType)
  end
end

function ChatPage:_SwitchTogs(index)
  eventManager:SendEvent(LuaEvent.TryCancelRecordOrPlay)
  local channelType = table.keyof(ChannelTogMap, index + 1)
  if channelType ~= nil then
    Data.chatData:SetChatChannel(channelType)
    local kind = ChannelShowType[channelType] == ShowType.user and ChatKind.PSN or ChatKind.PLC
    Logic.chatLogic:SetChatKind(kind)
    Data.chatData:SetNowChatUserInfo(0)
    self:_LoadChat()
    local roomNum = Data.chatData:GetRoomNum()
    Data.chatData:ResetUnReadNumByChannelType(channelType, roomNum)
  else
    logError("Chat View:Can't find channel")
  end
  self:_CloseEmoji()
end

function ChatPage:_EmojiTogs(index)
  local chatType = self.chatType
  local datas = Logic.chatLogic:GetAllEmojiData()
  self:_LoadEmoji(self.m_tabWidgets, index - 1, datas[index], chatType)
end

function ChatPage:SwitchEmojiToggle(target, index)
  if not self.selectedEmojiPart then
    local newPart = self.emojiParts[index]
    newPart.obj_normal:SetActive(false)
    newPart.obj_selected:SetActive(true)
    local duration = newPart.tween_scale.duration
    newPart.tween_scale.duration = 0
    newPart.tween_scale:Play()
    newPart.layout.preferredWidth = emojiToggleMaxWidth
    self.selectedEmojiPart = newPart
    self:PerformDelay(0.1, function()
      newPart.tween_scale.duration = duration
    end)
    return
  end
  local newPart = self.emojiParts[index]
  local oldPart = self.selectedEmojiPart
  local timerReset = function(timer)
    if timer then
      timer:Stop()
      timer = nil
    end
  end
  timerReset(self.scaleZeroTimer)
  self.scaleZeroTimer = FrameTimer.New(function()
    if oldPart.obj_selected.activeInHierarchy then
      local curWidth = emojiToggleMaxWidth * oldPart.tween_scale.value.x
      oldPart.layout.preferredWidth = curWidth
    else
      timerReset(self.scaleZeroTimer)
    end
  end, 1, -1)
  oldPart.tween_scale:Play(false)
  self.scaleZeroTimer:Start()
  self:PerformDelay(0.2, function()
    timerReset(self.scaleZeroTimer)
    oldPart.layout.preferredWidth = 0
    oldPart.obj_selected:SetActive(false)
    oldPart.obj_normal:SetActive(true)
    timerReset(self.scaleOneTimer)
    self.scaleOneTimer = FrameTimer.New(function()
      if newPart.obj_selected.activeInHierarchy then
        local curWidth = emojiToggleMaxWidth * newPart.tween_scale.value.x
        newPart.layout.preferredWidth = curWidth
      else
        timerReset(self.scaleOneTimer)
      end
    end, 1, -1)
    newPart.obj_normal:SetActive(false)
    newPart.obj_selected:SetActive(true)
    newPart.tween_scale:Play(true)
    self.scaleOneTimer:Start()
    self:PerformDelay(0.2, function()
      timerReset(self.scaleOneTimer)
      newPart.layout.preferredWidth = emojiToggleMaxWidth
    end)
  end)
  self.selectedEmojiPart = newPart
  self:_EmojiTogs(index)
end

function ChatPage:_LoadChat()
  local inputType = Data.chatData:GetChatWay()
  local channelType = Data.chatData:GetChatChannel()
  local widgets = self.m_tabWidgets
  local room = Data.chatData:GetRoomNum()
  local isWorld = Logic.chatLogic:IsWorldChannel(channelType)
  widgets.btn_room.gameObject:SetActive(isWorld)
  if isWorld then
    channelType = ChatChannel.WorldBase
  end
  local index = ChannelTogMap[channelType]
  for i, v in ipairs(self.tabTogs) do
    if i == index then
      self.tabTogs[i]:Set(true, false)
    else
      self.tabTogs[i]:Set(false, false)
    end
  end
  local channelShowType = ChannelShowType[channelType]
  local kind = channelShowType == ShowType.user and ChatKind.PSN or ChatKind.PLC
  Logic.chatLogic:SetChatKind(kind)
  widgets.tx_tip.gameObject:SetActive(channelShowType == ShowType.user or channelType == ChatChannel.System)
  if ChannelTipStr[channelType] ~= nil then
    UIHelper.SetText(widgets.tx_tip, ChannelTipStr[channelType])
  end
  widgets.obj_list:SetActive(channelShowType == ShowType.user)
  widgets.obj_input:SetActive(channelShowType == ShowType.chat and channelType ~= ChatChannel.System)
  widgets.obj_chat:SetActive(channelShowType == ShowType.chat)
  UIHelper.SetText(widgets.tx_room, room)
  if channelShowType == ShowType.chat then
    self:_ShowChatInfo(widgets, channelType, inputType)
    self:_ShowChatWindowBase(nil, false)
  else
    self:_ShowUserInfo(widgets, channelType)
  end
  self:_ShowBottom()
end

function ChatPage:_ShowUserInfo(widgets, channelType)
  local tabUserList = {}
  if channelType == ChatChannel.Friend then
    Service.friendService:_GetFriendMainData()
    return
  elseif channelType == ChatChannel.Personal then
    tabUserList = Logic.chatLogic:GetRecentChatUser()
  else
    logError(ChatChannelStr[channelType] .. "\233\162\145\233\129\147\228\184\141\228\188\154\230\152\190\231\164\186\231\148\168\230\136\183\229\136\151\232\161\168,\232\175\183\230\163\128\230\159\165ChatPage:_ShowUserInfo()")
    return
  end
  self:_LoadUserList(widgets.iil_usersv, widgets.obj_userItem, tabUserList)
  local uid = Logic.chatLogic:GetNowChatUserInfo()
  local personCheck = self:_personChatCheck(tabUserList)
  self:_ShowChatWindow(nil, personCheck)
  if not personCheck then
    return
  end
  local userInfo = Data.chatData:GetRecentChatUserInfoByUid(uid)
  self:_ShowUserChatInfo(nil, userInfo)
end

function ChatPage:_personChatCheck(usrlist)
  if #usrlist < 0 then
    return false
  end
  local uid = Logic.chatLogic:GetNowChatUserInfo()
  if uid == 0 then
    return false
  end
  for _, info in ipairs(usrlist) do
    if info.Uid == uid then
      return true
    end
  end
  return false
end

function ChatPage:_OnGetFriendsInfo()
  local channel = Data.chatData:GetChatChannel()
  if channel ~= ChatChannel.Friend then
    return
  end
  local widgets = self:GetWidgets()
  local tabUserList = Data.friendData:GetFriendData()
  tabUserList = Logic.chatLogic:DealFriendList(tabUserList)
  self:_LoadUserList(widgets.iil_usersv, widgets.obj_userItem, tabUserList)
  local uid = Logic.chatLogic:GetNowChatUserInfo()
  local personCheck = self:_personChatCheck(tabUserList)
  self:_ShowChatWindow(nil, personCheck)
  if not personCheck then
    return
  end
  local userInfo = Data.chatData:GetRecentChatUserInfoByUid(uid)
  if userInfo == nil then
    logError("FATAL ERROR: can not find friend info,uid :" .. uid)
    return
  end
  self:_ShowUserChatInfo(nil, userInfo)
end

function ChatPage:_LoadUserList(iil, obj, tabUserList)
  if self.m_userInfo == nil then
    tabUserList = Logic.chatLogic:SortUserListByChatTime(tabUserList)
  end
  UIHelper.SetInfiniteItemParam(iil, obj, #tabUserList, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    local receiveUid
    if Data.chatData:GetNowChatUserInfo() then
      receiveUid = Data.chatData:GetNowChatUserInfo()
    end
    for index, luaPart in pairs(tabTemp) do
      local info = tabUserList[index]
      luaPart.grayGroup.Gray = not Logic.chatLogic:IsOnLine(info.Uid)
      UIHelper.SetText(luaPart.tx_time, Logic.chatLogic:GetUserStatus(info.Uid))
      local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(info)
      luaPart.im_kuang.gameObject:SetActive(true)
      UIHelper.SetImage(luaPart.im_kuang, headFrameInfo.icon)
      local icon, quality = Logic.chatLogic:GetUserHead(info)
      UIHelper.SetImage(luaPart.im_frame, quality)
      UIHelper.SetImage(luaPart.im_head, icon)
      UIHelper.SetText(luaPart.tx_name, info.Uname)
      UIHelper.SetText(luaPart.tx_Lv, "Lv" .. Mathf.ToInt(info.Level))
      local lastMsg = Logic.chatLogic:GetLastChat(info.Uid)
      if Logic.chatLogic:IsEmojiMsg(lastMsg, false) then
        local id = string.match(lastMsg, "%d+")
        local emoji = configManager.GetDataById("config_emoji", id)
        lastMsg = emoji.name
      end
      UIHelper.SetText(luaPart.tx_lastInfo, lastMsg)
      if index == #tabUserList then
        luaPart.obj_fengexian:SetActive(false)
      else
        luaPart.obj_fengexian:SetActive(true)
      end
      self.m_tabSelectUserObj[info.Uid] = luaPart.obj_xuanzhong
      self.m_tabSelectUserObjIcon[info.Uid] = luaPart.obj_xuanzhongicon
      if receiveUid == info.Uid then
        self:_ShowSelect(receiveUid)
      end
      UGUIEventListener.AddButtonOnClick(luaPart.obj_chat, self._ShowUserChatInfo, self, info)
      UGUIEventListener.AddButtonOnClick(luaPart.im_head.gameObject, self._ShowHeadInfo, self, info.Uid)
      self:RegisterRedDot(luaPart.dot_unRead, info.Uid)
    end
  end)
end

function ChatPage:_ShowSelect(uid)
  for k, v in pairs(self.m_tabSelectUserObj) do
    v:SetActive(k == uid)
  end
  for k, v in pairs(self.m_tabSelectUserObjIcon) do
    v:SetActive(k == uid)
  end
end

function ChatPage:_ShowUserChatInfo(go, userInfo)
  eventManager:SendEvent(LuaEvent.TryCancelRecordOrPlay)
  Data.chatData:ResetUnReadNumByUid(userInfo.Uid)
  eventManager:SendEvent(LuaEvent.ChatResetUnreadById, userInfo.Uid)
  Data.chatData:AddRecentChatUser(userInfo)
  Data.chatData:SetNowChatUserInfo(userInfo.Uid)
  UIHelper.SetText(self.m_tabWidgets.tx_chatName, userInfo.Uname)
  self:_ShowSelect(userInfo.Uid)
  local widgets = self.m_tabWidgets
  self:_ShowChatWindow(nil, true)
  UGUIEventListener.AddButtonOnClick(widgets.btn_pvticon, self._OpenEmoji, self, ChatKind.PSN)
  UGUIEventListener.AddButtonOnClick(widgets.btn_pvtsend, self._SendTextMsg, self, ChatKind.PSN)
  local channel = Data.chatData:GetChatChannel()
  local tabChatList = Data.chatData:GetChatInfo(channel, nil, userInfo.Uid)
  self:_LoadChatList(widgets.pv_tableview, widgets.obj_pvtChatItem, widgets.sbar_chatWindow, tabChatList)
end

function ChatPage:_ShowChatInfo(widgets, channelType, inputType)
  UGUIEventListener.AddButtonOnClick(widgets.btn_icon, self._OpenEmoji, self, ChatKind.PLC)
  UGUIEventListener.AddButtonOnClick(widgets.btn_send, self._SendTextMsg, self, ChatKind.PLC)
  local roomNum = Data.chatData:GetRoomNum()
  local tabChatList = Data.chatData:GetChatInfo(channelType, roomNum, nil)
  self:_LoadChatList(widgets.tableview, widgets.obj_chatItem, widgets.sbar_chat, tabChatList)
  Data.chatData:ResetUnReadNumByChannelType(channelType, roomNum)
  widgets.obj_unReadTips:SetActive(false)
  widgets.obj_unReadPvTips:SetActive(false)
end

function ChatPage:_LoadChatList(tableview, obj, sbar, tabChatList)
  if tabChatList == nil then
    return
  end
  local channelType = Data.chatData:GetChatChannel()
  UIHelper.SetTableViewParam(tableview, obj, #tabChatList, CHAT_MsgItemMinHeight, function(index, luaPart)
    self:_FillMsgItem(index, luaPart, tabChatList, channelType)
  end, function(index)
    return self:_GetMsgItemHeight(index, tabChatList[index])
  end)
end

function ChatPage:_FillMsgItem(index, luaPart, tabChatList, channelType)
  local lastMsg = tabChatList[index - 1]
  local curMsg = tabChatList[index]
  local isMyMsg = Logic.chatLogic:IsMySendMsg(curMsg)
  local isShowTime = Logic.chatLogic:IsInfoInterval(lastMsg, curMsg)
  if isShowTime then
    local isToday = Logic.chatLogic:IsChatInfoToday(curMsg)
    local timeStr = ""
    if isToday then
      timeStr = time.formatTimerToHMSColon(curMsg.SendTime)
    else
      timeStr = time.formatTimerToMDHM(curMsg.SendTime)
    end
    UIHelper.SetText(luaPart.tx_time, timeStr)
  else
    UIHelper.SetText(luaPart.tx_time, "")
  end
  luaPart.obj_other:SetActive(not isMyMsg)
  luaPart.obj_me:SetActive(isMyMsg)
  local icon, quality = Logic.chatLogic:GetUserHead(curMsg.UserInfo)
  local msgType = Logic.chatLogic:CheckMsgType(curMsg)
  local refreshlayout = function(rt)
    LayoutRebuilder.ForceRebuildLayoutImmediate(rt)
  end
  local new = Logic.chatLogic:CheckMsgNew(curMsg)
  luaPart.tx_meVoiceTime.gameObject:SetActive(isMyMsg and msgType == ChatMsgType.VOICE)
  luaPart.tx_otherVoiceTime.gameObject:SetActive(not isMyMsg and msgType == ChatMsgType.VOICE)
  if isMyMsg then
    UIHelper.SetImage(luaPart.im_meFrame, quality)
    UIHelper.SetImage(luaPart.im_meHead, icon)
    UIHelper.SetText(luaPart.tx_meName, curMsg.UserInfo.Uname)
    luaPart.obj_meVoice:SetActive(msgType == ChatMsgType.VOICE)
    local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(curMsg.UserInfo)
    luaPart.im_meKuang.gameObject:SetActive(true)
    UIHelper.SetImage(luaPart.im_meKuang, headFrameInfo.icon)
    if msgType == ChatMsgType.TEXT then
      if Logic.chatLogic:IsEmojiMsg(curMsg.Message, true) then
        luaPart.obj_meText:SetActive(false)
        luaPart.obj_meEmoji.gameObject:SetActive(true)
        self:_SetEmojiMessage(luaPart.obj_meEmoji, curMsg.Message)
      else
        luaPart.obj_meText:SetActive(true)
        luaPart.obj_meEmoji.gameObject:SetActive(false)
        self:_SetMsgSize(luaPart.rt_memsg, curMsg.Message)
        self:_SetTxtMessage(luaPart.tx_meInfo, curMsg.Message)
        refreshlayout(luaPart.rt_me)
      end
    elseif msgType == ChatMsgType.VOICE then
      luaPart.obj_meDot:SetActive(new)
      luaPart.obj_meText:SetActive(false)
      luaPart.obj_meEmoji.gameObject:SetActive(false)
      local durtion = Logic.chatLogic:GetVoiceDurtion(curMsg.Message)
      UIHelper.SetText(luaPart.tx_meVoiceTime, durtion .. "''")
      UGUIEventListener.AddButtonOnClick(luaPart.obj_meVoice, self._OnClickMeVoice, self, {data = curMsg, widgets = luaPart})
    end
  else
    UIHelper.SetImage(luaPart.im_otherFrame, quality)
    UIHelper.SetImage(luaPart.im_otherHead, icon)
    UIHelper.SetText(luaPart.tx_otherName, curMsg.UserInfo.Uname)
    local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(curMsg.UserInfo)
    luaPart.im_otherKuang.gameObject:SetActive(true)
    UIHelper.SetImage(luaPart.im_otherKuang, headFrameInfo.icon)
    luaPart.obj_otherVoice:SetActive(msgType == ChatMsgType.VOICE)
    if msgType == ChatMsgType.TEXT then
      if Logic.chatLogic:IsEmojiMsg(curMsg.Message, false) then
        luaPart.obj_otherText:SetActive(false)
        luaPart.obj_otherEmoji.gameObject:SetActive(true)
        self:_SetEmojiMessage(luaPart.obj_otherEmoji, curMsg.Message)
      else
        luaPart.obj_otherText:SetActive(true)
        luaPart.obj_otherEmoji.gameObject:SetActive(false)
        self:_SetMsgSize(luaPart.rt_othermsg, curMsg.Message)
        self:_SetTxtMessage(luaPart.tx_otherInfo, curMsg.Message)
        refreshlayout(luaPart.rt_other)
      end
    elseif msgType == ChatMsgType.VOICE then
      luaPart.obj_otherText:SetActive(false)
      luaPart.obj_otherEmoji.gameObject:SetActive(false)
      luaPart.obj_otherDot:SetActive(new)
      local durtion = Logic.chatLogic:GetVoiceDurtion(curMsg.Message)
      UIHelper.SetText(luaPart.tx_otherVoiceTime, durtion .. "''")
      UGUIEventListener.AddButtonOnClick(luaPart.obj_otherVoice, self._OnClickOtherVoice, self, {data = curMsg, widgets = luaPart})
    end
    UGUIEventListener.ClearButtonEventListener(luaPart.im_otherHead.gameObject)
    if channelType ~= ChatChannel.System then
      UGUIEventListener.AddButtonOnClick(luaPart.im_otherHead.gameObject, self._ShowHeadInfo, self, curMsg.UserInfo.Uid)
    end
  end
end

function ChatPage:_SetTxtMessage(txt, msg)
  UIHelper.SetText(txt, msg)
end

function ChatPage:_SetMsgSize(rt_tx, msg)
  local indicator = self:GetWidgets().txt_indicator
  UIHelper.SetText(indicator, msg)
  local preferredWidth = indicator.preferredWidth
  local width = Mathf.Min(CHAT_MsgTextMaxWidth, preferredWidth)
  local height = rt_tx.sizeDelta.y
  rt_tx.sizeDelta = Vector2.New(width, height)
end

function ChatPage:_SetEmojiMessage(img, msg)
  local id = string.match(msg, "%d+")
  local emoji = configManager.GetDataById("config_emoji", id)
  if emoji then
    UIHelper.SetImage(img, emoji.picture)
  end
end

function ChatPage:_GetMsgItemHeight(index, msgData)
  local msgType = Logic.chatLogic:CheckMsgType(msgData)
  local indicator = self.tab_Widgets.txt_indicator
  local startPosY = indicator.rectTransform.anchoredPosition.y
  local preferredHeight = 0
  if msgType == ChatMsgType.TEXT then
    if Logic.chatLogic:IsEmojiMsg(msgData.Message, Logic.chatLogic:IsMySendMsg(msgData)) then
      preferredHeight = 128
    else
      self:_SetTxtMessage(indicator, msgData.Message)
      preferredHeight = indicator.preferredHeight
    end
  end
  local endPosY = math.abs(startPosY - preferredHeight)
  local itemHeight = CHAT_MsgItemMinHeight
  if endPosY > CHAT_MsgItemMinHeight then
    itemHeight = endPosY
  end
  return itemHeight
end

function ChatPage:_OnClickMeVoice(go, param)
  local msg = param.data
  local playing = Logic.chatLogic:GetChatContext().playing
  if playing then
    self:_StopPlay()
    Logic.chatLogic:SetPlayingVoice(msg)
  else
    self:_playMyVoice(msg)
  end
end

function ChatPage:_playMyVoice(msg)
  local voice = Unserialize(msg.Message)
  if voice == nil then
    return
  end
  local ok = Logic.chatLogic:CheckVoiceMsg(voice)
  if ok then
    self:_TryPlayVoice(voice)
    Data.chatData:SetMsgRead(msg)
  else
    logError("invalid voice play param" .. logError(voice))
  end
end

function ChatPage:_playOtherVoice(msg)
  local voice = Unserialize(msg.Message)
  if voice == nil then
    return
  end
  local ok = Logic.chatLogic:CheckDownloadVoice(voice)
  if ok then
    self:_DownloadFile(voice.voiceUrl)
    Data.chatData:SetMsgRead(msg)
  else
    logError("invalid voice download url" .. voice.voiceUrl)
  end
end

function ChatPage:_OnClickOtherVoice(go, param)
  local msg = param.data
  local widgets = param.widgets
  if widgets.obj_otherDot then
    widgets.obj_otherDot:SetActive(false)
  end
  local playing = Logic.chatLogic:GetChatContext().playing
  if playing then
    self:_StopPlay()
    Logic.chatLogic:SetPlayingVoice(msg)
  else
    self:_playOtherVoice(msg)
  end
end

function ChatPage:_ShowHeadInfo(go, uid)
  eventManager:SendEvent(LuaEvent.TryCancelRecordOrPlay)
  local paramTab = {
    Uid = uid,
    Position = go.transform.position
  }
  local pageObj = UIHelper.OpenPage("UserInfoTip", paramTab)
  pageObj:SetAdditionOrder(self:GetAdditionOrder() + layerDelta)
  pageObj = nil
end

function ChatPage:_OpenChatSet()
  eventManager:SendEvent(LuaEvent.TryCancelRecordOrPlay)
  local pageObj = UIHelper.OpenPage("ChatSetPage")
  pageObj:SetAdditionOrder(self:GetAdditionOrder() + layerDelta)
  pageObj = nil
end

function ChatPage:_ChangeChatRoom()
  local playing = Logic.chatLogic:GetChatContext().playing
  if playing then
    self:_StopPlay()
  end
  eventManager:SendEvent(LuaEvent.TryCancelRecordOrPlay)
  local pageObj = UIHelper.OpenPage("ChangeRoomPage")
  pageObj:SetAdditionOrder(self:GetAdditionOrder() + layerDelta)
  pageObj = nil
end

function ChatPage:_SendMsgCheck(msg, voice2text)
  if not moduleManager:CheckFunc(FunctionID.Chat, true) then
    noticeManager:ShowTip("\232\129\138\229\164\169\229\138\159\232\131\189\230\156\170\229\188\128\229\144\175")
    return
  end
  local ban = Logic.chatLogic:IsInBan()
  if ban then
    noticeManager:ShowTip("\230\130\168\229\183\178\232\162\171\231\179\187\231\187\159\231\166\129\232\168\128")
    return
  end
  if Logic.friendLogic:GetTipsOpen() then
    logError("please close user info tip first!!!")
    return
  end
  local channel = Data.chatData:GetChatChannel()
  local roomNum = Data.chatData:GetRoomNum()
  local curLv = Data.userData:GetUserLevel()
  local limitLv = configManager.GetDataById("config_parameter", 363).value
  if curLv < limitLv then
    noticeManager:ShowTip(string.format(UIHelper.GetString(220011), limitLv))
    return
  end
  if channel == ChatChannel.WorldBase then
    limitLv = configManager.GetDataById("config_parameter", 45).value
    if curLv < limitLv then
      noticeManager:ShowTip(string.format(UIHelper.GetString(220006), limitLv))
      return
    end
  end
  if Logic.chatLogic:CheckFastUser() then
    noticeManager:ShowTipById(220010)
    return
  end
  local isCoolTime = Logic.chatLogic:IsCoolTime(channel)
  if isCoolTime then
    local time = Mathf.ToInt(Logic.chatLogic:GetAllowChatTime(channel))
    local str = ChatChannelStr[channel] .. "\233\162\145\233\129\147\232\191\152\233\156\128\232\166\129" .. time .. "\231\167\146\229\144\142\230\137\141\232\131\189\229\143\145\232\168\128"
    noticeManager:ShowTip(str)
    return
  end
  if channel == ChatChannel.WorldBase then
    channel = 901
    local nowNum = Data.chatData:GetWorldSendNum()
    local numUp = Logic.chatLogic:GetWorldNumUp(curLv)
    if nowNum >= numUp then
      noticeManager:ShowTip("\228\187\138\230\151\165\229\143\145\233\128\129\228\184\150\231\149\140\230\182\136\230\129\175\230\172\161\230\149\176\231\148\168\229\176\189")
      return
    end
  end
  if msg == nil then
    return
  end
  if msg == "" then
    noticeManager:ShowTip("\230\182\136\230\129\175\228\184\141\232\131\189\228\184\186\231\169\186")
    return
  end
  msg = Logic.chatLogic:FilterMask(msg)
  local receiveUid = 0
  local isPublic = Logic.chatLogic:IsPublicChanelType(channel)
  if not isPublic then
    receiveUid = Data.chatData:GetNowChatUserInfo()
    local isMyFriend = Logic.friendLogic:IsMyFriend(receiveUid)
    if not isMyFriend then
      limitLv = configManager.GetDataById("config_parameter", 227).value
      if curLv < limitLv then
        noticeManager:ShowTip(string.format(UIHelper.GetString(220008), limitLv))
        return
      end
    end
  end
  return true, channel, receiveUid, msg
end

function ChatPage:_SendVoiceMsg(msg, text)
  local ok, channel, receiveUid, rmsg = self:_SendMsgCheck(msg, text)
  if ok then
    Service.chatService:SendMessage(channel, receiveUid, rmsg, ChatMsgType.VOICE, text)
    if Logic.chatLogic:IsWorldChannel(channel) then
      channel = ChatChannel.WorldBase
      Data.chatData:AddWorldSendNum()
    end
    Data.chatData:SetlastSendTimeByChannel(channel, time.getSvrTime())
  end
end

function ChatPage:_SendTextMsg(go, param, customMsg)
  local msg = customMsg or self.tabInput[param].text
  local ok, channel, receiveUid, rmsg = self:_SendMsgCheck(msg)
  if ok then
    Service.chatService:SendMessage(channel, receiveUid, rmsg, ChatMsgType.TEXT)
    if Logic.chatLogic:IsWorldChannel(channel) then
      channel = ChatChannel.WorldBase
      Data.chatData:AddWorldSendNum()
    end
    if not customMsg then
      self.tabInput[param].text = ""
    end
    Data.chatData:SetlastSendTimeByChannel(channel, time.getSvrTime())
  else
    self.tabInput[param].text = ""
  end
end

function ChatPage:_OpenEmoji(go, chatType)
  eventManager:SendEvent(LuaEvent.TryCancelRecordOrPlay)
  self.chatType = chatType
  self.m_togEmoji = not self.m_togEmoji
  self:_UpdateEmojiBtnBg()
  local widgets = self.m_tabWidgets
  local oldPos = widgets.trans_emojiBase.anchoredPosition
  widgets.trans_emojiBase.anchoredPosition = Vector2.New(emojiPosX[chatType], oldPos.y)
  widgets.obj_emojiBase:SetActive(self.m_togEmoji)
  self:SwitchEmojiToggle(nil, 1)
  local datas = Logic.chatLogic:GetAllEmojiData()
  self:_LoadEmoji(self.m_tabWidgets, 1, datas[1], chatType)
end

function ChatPage:_UpdateEmojiBtnBg()
  local widgets = self.tab_Widgets
  if not self.m_togEmoji then
    UIHelper.SetImage(widgets.pv_img_emoji, "uipic_ui_chat_bg_zuobiandadiban")
    UIHelper.SetImage(widgets.img_emoji, "uipic_ui_chat_bg_zuobiandadiban")
  else
    UIHelper.SetImage(widgets.pv_img_emoji, "uipic_ui_chat_bu_fasong_anniu")
    UIHelper.SetImage(widgets.img_emoji, "uipic_ui_chat_bu_fasong_anniu")
  end
end

function ChatPage:_CloseEmoji()
  self:_tryStopTimer()
  self.m_tabWidgets.obj_emojiBase:SetActive(false)
  self.m_togEmoji = false
  self:_UpdateEmojiBtnBg()
end

function ChatPage:_tryStopTimer()
  if self.scaleZeroTimer then
    self.scaleZeroTimer:Stop()
    self.scaleZeroTimer = nil
  end
  if self.scaleOneTimer then
    self.scaleOneTimer:Stop()
    self.scaleOneTimer = nil
  end
end

function ChatPage:FilterItemLockedEmoji(emojiDatas)
  if emojiDatas == nil then
    return
  end
  for i = #emojiDatas, 1, -1 do
    local emojiId = emojiDatas[i].id
    local unlock = Logic.chatLogic:CheckEmojiUnlockItem(emojiId)
    if not unlock then
      table.remove(emojiDatas, i)
    end
  end
end

function ChatPage:_LoadEmoji(widgets, tagIndex, tabData, chatType)
  local total = #tabData
  widgets.grid_layout.constraint = 1
  widgets.grid_layout.constraintCount = 4
  local high = total % 4 == 0 and math.floor(total / 4) or math.floor(total / 4) + 1
  widgets.rect_grid_layout.sizeDelta = Vector2.New(526.6, 136 * high)
  widgets.sv_controller.CurPage = 1
  self.emojiUnlockMap = self.emojiUnlockMap or {}
  UIHelper.CreateSubPart(widgets.obj_emoji, widgets.trans_emoji, total, function(index, tabPart)
    tabPart.im_emoji.enabled = tabData[index] ~= nil
    if tabData[index] ~= nil then
      local lockData = Logic.chatLogic:IsEmojiUnlock(tabData[index].id)
      tabPart.gray_group.Gray = not lockData.isUnlock
      self.emojiUnlockMap[tabData[index].id] = lockData
      UIHelper.SetImage(tabPart.im_emoji, tabData[index].picture)
      UGUIEventListener.AddButtonOnClickCB(tabPart.btn_emoji, self._SendEmoji, self, {
        id = tabData[index].id,
        chatType = chatType
      })
    end
  end)
end

function ChatPage:_SendEmoji(go, params)
  local id = params.id
  local chatType = params.chatType
  local lockData = self.emojiUnlockMap[id] or Logic.chatLogic:IsEmojiUnlock(id)
  if lockData.lockPlotId > 0 then
    local plotCfg = configManager.GetDataById("config_building_character_story", lockData.lockPlotId)
    noticeManager:ShowTip(UIHelper.GetLocString(220009, plotCfg.plot_title))
    return
  end
  if 0 < lockData.lockItemId then
    local emojiCfg = configManager.GetDataById("config_emoji", id)
    noticeManager:ShowTip(UIHelper.GetString(emojiCfg.unlock_tip))
    return
  end
  local emojiInfo = Logic.chatLogic:GetEmojiInfoById(id)
  Data.chatData:AddRecentEmoji(emojiInfo)
  Logic.chatLogic:SetChatType(ChatMsgType.TEXT)
  self:_SendTextMsg(nil, chatType, "<" .. id .. ">")
  self:_CloseEmoji()
end

function ChatPage:_SetEmojiTips()
  local intervalIndex = self.m_tabWidgets.sv_controller.CurPage
  for k, v in pairs(self.m_tabTips) do
    v:SetActive(k == intervalIndex)
  end
end

function ChatPage:_CloseChat()
  eventManager:SendEvent(LuaEvent.UpdataHomeChat, nil)
  UIHelper.ClosePage("ChatPage")
end

function ChatPage:_ShowChatWindow(go, enable)
  self:_ShowChatWindowBase(go, enable)
  if not enable then
    self:_CloseEmoji()
    self:_ShowSelectVoiceWay(nil, false)
  end
end

function ChatPage:_ShowChatWindowBase(go, enable)
  self.m_tabWidgets.obj_chatWindow:SetActive(enable)
end

function ChatPage:_IsSvDwon(scrollRect)
  return scrollRect.verticalNormalizedPosition <= 0
end

function ChatPage:DoOnHide()
  self:_RemoveUnityListener()
  self:_ResetLogicCache()
end

function ChatPage:DoOnClose()
  local playing = Logic.chatLogic:GetChatContext().playing
  if playing then
    self:_StopPlay()
  end
  self:_tryStopTimer()
  self:_RemoveUnityListener()
  self:_ResetLogicCache()
  self:_OnTryCancelRecord()
  Logic.chatLogic:ResetChatContext()
end

function ChatPage:_ResetLogicCache()
  Data.chatData:SetChatOpen(false)
  Logic.chatLogic:SetPlayingVoice(nil)
  Logic.chatLogic:SetTryPlayVoice(false, {})
end

function ChatPage:_RemoveUnityListener()
  local widgets = self:GetWidgets()
  widgets.input_content.onValueChanged:RemoveAllListeners()
  widgets.input_pvtcontent.onValueChanged:RemoveAllListeners()
end

function ChatPage:_StartRecord()
  local isInit = Logic.chatLogic:IsVoiceSDKInit()
  if not isInit then
    self:_ShowRecordInitTip(true)
  end
  Logic.chatLogic:StartRecord()
  Logic.chatLogic:SetRecording(MChatVoiceCommonState.WAIT)
end

function ChatPage:_StopRecord()
  local record = Logic.chatLogic:GetChatContext().recordState
  if record == MChatVoiceCommonState.YES then
    Logic.chatLogic:StopRecord()
    Logic.chatLogic:SetRecording(MChatVoiceCommonState.WAIT)
  end
  self:_TryStopVoiceTimer("stop")
end

function ChatPage:_CancelRecord()
  local record = Logic.chatLogic:GetChatContext().recordState
  if record == MChatVoiceCommonState.YES then
    Logic.chatLogic:CancelRecord()
    Logic.chatLogic:SetRecording(MChatVoiceCommonState.WAIT)
  end
  self:_TryStopVoiceTimer("cancel")
end

function ChatPage:_DownloadFile(url)
  local isInit = Logic.chatLogic:IsVoiceSDKInit()
  if not isInit then
    self:_ShowRecordInitTip(true)
  end
  Logic.chatLogic:DownloadVoice(url)
end

function ChatPage:_TryPlayVoice(msg)
  Logic.chatLogic:SetTryPlayVoice(true, msg)
  self:_PlayVoice(msg.savePath)
end

function ChatPage:_PlayVoice(filePath)
  local record = Logic.chatLogic:GetChatContext().recordState
  if record ~= MChatVoiceCommonState.NO then
    noticeManager:ShowTip("\230\173\163\229\156\168\229\189\149\233\159\179,\230\151\160\230\179\149\230\146\173\230\148\190\232\175\173\233\159\179")
    return
  end
  local isInit = Logic.chatLogic:IsVoiceSDKInit()
  if not isInit then
    self:_ShowRecordInitTip(true)
  end
  Logic.chatLogic:PlayVoice(filePath)
  Logic.chatLogic:SetIsPlaying(true)
end

function ChatPage:_OnTryCancelRecord()
  self:_CancelRecord()
  self:_CloseVoiceUI()
end

function ChatPage:_OnTryCancelRecordAndPlay()
  self:_OnTryCancelRecord()
  self:_OnTryStopVoice()
end

function ChatPage:_OnTryStopVoice()
  local playing = Logic.chatLogic:GetChatContext().playing
  if playing then
    self:_StopPlay()
  end
end

function ChatPage:_StopPlay()
  Logic.chatLogic:StopPlay()
end

function ChatPage:_OnVoiceSDKInit(param)
  local ok, msg = Logic.chatLogic:AssertVoiceCode(param.code)
  if ok then
    self:_ShowRecordInitTip(false)
  else
    noticeManager:ShowTip(msg)
  end
  Logic.chatLogic:SetRecording(MChatVoiceCommonState.NO)
end

function ChatPage:_OnStartRecord(param)
  local ok, msg = Logic.chatLogic:AssertVoiceCode(param.code)
  if ok then
    self:_ShowRecordingTip(true)
    self:_RefreshRecordTime()
    self:_TryStopVoiceTimer("start")
    local count = 0
    self.m_recordTimer = self:CreateTimer(function()
      count = count + 1
      Logic.chatLogic:SetRecordTime(count)
      local down = self:_RefreshRecordTime()
      if not down then
        noticeManager:ShowTip("\229\189\149\233\159\179\232\182\133\230\151\182\228\186\134")
        local context = Logic.chatLogic:GetChatContext()
        local slideState = context.slideState
        local record = context.recordState
        if record == MChatVoiceCommonState.YES then
          if slideState == ChatRecordSlideState.UP then
            self:_CancelRecord()
          else
            self:_StopRecord()
          end
        end
        self:_ShowCancelRecordTip(false)
        self:_ShowRecordingTip(false)
        self:StopTimer(self.m_recordTimer)
      end
    end, 1, -1, true)
    self:StartTimer(self.m_recordTimer)
  else
    noticeManager:ShowTip(msg)
  end
  if ok then
    Logic.chatLogic:SetRecording(MChatVoiceCommonState.YES)
  else
    Logic.chatLogic:SetRecording(MChatVoiceCommonState.NO)
  end
end

function ChatPage:_TryStopVoiceTimer(str)
  if self.m_recordTimer then
    self:StopTimer(self.m_recordTimer)
    self.m_recordTimer = nil
  end
end

function ChatPage:_OnStopRecord(param)
  local ok, msg = Logic.chatLogic:AssertVoiceCode(param.code)
  if ok then
    local max = Logic.chatLogic:GetVocieTimeMax()
    if max < param.duration then
      return
    end
    local str = Serialize(param)
    local way = Logic.chatLogic:GetChatContext().voiceWay
    if way == VoiceWay.VOICE then
      self:_SendVoiceMsg(str, param.strText)
    else
      local chatKind = Logic.chatLogic:GetChatContext().chatKind
      local res, up = Logic.chatLogic:MsgCut(param.strText, 40)
      if up then
        noticeManager:ShowTip(UIHelper.GetString(220001))
      end
      self.tabInput[chatKind].text = res
    end
  else
    noticeManager:ShowTip(msg)
  end
  Logic.chatLogic:SetRecording(MChatVoiceCommonState.NO)
end

function ChatPage:_OnCancelRecord(param)
  local ok, msg = Logic.chatLogic:AssertVoiceCode(param.code)
  if not ok then
    noticeManager:ShowTip(msg)
  end
  Logic.chatLogic:SetRecording(MChatVoiceCommonState.NO)
end

function ChatPage:_OnDownloadFile(param)
  local ok, msg = Logic.chatLogic:AssertVoiceCode(param.code)
  if ok then
    self:_PlayVoice(param.savePath)
  else
    noticeManager:ShowTip(msg)
  end
end

function ChatPage:_OnPlayVoice(param)
  local ok, msg = Logic.chatLogic:AssertVoiceCode(param.code)
  if ok then
    Logic.chatLogic:SetIsPlaying(false)
    if self.m_startImp then
      self.m_startImp(self)
      self.m_startImp = nil
    end
  else
    local try, msg = Logic.chatLogic:GetTryPlayVoice()
    if try and next(msg) ~= nil then
      self:_DownloadFile(msg.voiceUrl)
      Logic.chatLogic:SetTryPlayVoice(false, {})
    end
  end
end

function ChatPage:_OnStopPlay(param)
  local ok, msg = Logic.chatLogic:AssertVoiceCode(param.code)
  if not ok then
    noticeManager:ShowTip(msg)
  end
  Logic.chatLogic:SetIsPlaying(false)
  local context = Logic.chatLogic:GetChatContext()
  if context.playingVoice then
    self:_playOtherVoice(context.playingVoice)
    Logic.chatLogic:SetPlayingVoice(nil)
  end
end

function ChatPage:_ShowSelectVoiceWay(go, isOn)
  local widgets = self:GetWidgets()
  self:_setVoiceRoot()
  widgets.obj_voiceSelect:SetActive(isOn)
end

function ChatPage:_SwitchVoiceWay(go, way)
  Logic.chatLogic:SetVoiceWay(way)
  self:_ShowSelectVoiceWay(nil, false)
  self:_ShowPublicVoiceWay()
  self:_ShowPersonVoiceWay()
end

function ChatPage:_ShowPublicVoiceWay()
  local widgets = self:GetWidgets()
  local way = Logic.chatLogic:GetChatContext().voiceWay
  widgets.obj_voiceWayPlc:SetActive(way == VoiceWay.VOICE)
  widgets.obj_voiceTextWayPlc:SetActive(way == VoiceWay.VOICE2TEXT)
end

function ChatPage:_ShowPersonVoiceWay()
  local widgets = self:GetWidgets()
  local way = Logic.chatLogic:GetChatContext().voiceWay
  widgets.obj_voiceWayPsn:SetActive(way == VoiceWay.VOICE)
  widgets.obj_voiceTextWayPsn:SetActive(way == VoiceWay.VOICE2TEXT)
end

function ChatPage:_CloseVoiceUI()
  self:_ShowCancelRecordTip(false)
  self:_ShowRecordingTip(false)
  self:_ShowRecordInitTip(false)
end

function ChatPage:_ShowCancelRecordTip(isOn)
  local widgets = self:GetWidgets()
  self:_setVoiceRoot()
  widgets.obj_voiceCancelRecord:SetActive(isOn)
end

function ChatPage:_ShowRecordingTip(isOn)
  local widgets = self:GetWidgets()
  self:_setVoiceRoot()
  widgets.obj_voiceRecording:SetActive(isOn)
end

function ChatPage:_ShowRecordInitTip(isOn)
  local widgets = self:GetWidgets()
  self:_setVoiceRoot()
  widgets.obj_voiceInitRecord:SetActive(isOn)
end

function ChatPage:_setVoiceRoot()
  local widgets = self:GetWidgets()
  local kind = Logic.chatLogic:GetChatContext().chatKind
  local oldPos = widgets.trans_voiceBase.anchoredPosition
  widgets.trans_voiceBase.anchoredPosition = Vector2.New(CHAT_voiceRootPoxS[kind], oldPos.y)
end

function ChatPage:_RefreshRecordTime()
  local context = Logic.chatLogic:GetChatContext()
  local down, time = Logic.chatLogic:CheckVoiceTime(context.recordTime)
  UIHelper.SetText(self:GetWidgets().tx_recordingTime, time)
  return down
end

function ChatPage:_ResetRecordTime()
  local time = Logic.chatLogic:GetVocieTimeMax()
  UIHelper.SetText(self:GetWidgets().tx_recordingTime, time)
end

function ChatPage:_ShowBottom()
  self:_ShowPublicVoiceWay()
  self:_ShowPersonVoiceWay()
end

function ChatPage:_startRecordImp()
  local context = Logic.chatLogic:GetChatContext()
  if context.recordState ~= MChatVoiceCommonState.NO then
    noticeManager:ShowTip("\230\173\163\229\156\168\229\189\149\233\159\179")
    return
  else
    self:_StartRecord()
  end
  Logic.chatLogic:SetRecordSlideState(ChatRecordSlideState.NONE)
  Logic.chatLogic:SetChatType(ChatMsgType.VOICE)
end

function ChatPage:_OnLongPressRecord(go, param)
  local context = Logic.chatLogic:GetChatContext()
  if context.playing then
    self:_StopPlay()
    self.m_startImp = self._startRecordImp
  else
    self:_startRecordImp()
  end
end

function ChatPage:_OnPointUpRecord(go, param)
  local context = Logic.chatLogic:GetChatContext()
  if context.recordState == MChatVoiceCommonState.YES then
    if context.slideState == ChatRecordSlideState.UP then
      self:_CancelRecord()
    else
      self:_StopRecord()
    end
  end
  self:StopTimer(self.m_recordTimer)
  Logic.chatLogic:SetRecordSlideState(ChatRecordSlideState.NONE)
  Logic.chatLogic:SetRecordTime(0)
  self:_ResetRecordTime()
  self:_ShowCancelRecordTip(false)
  self:_ShowRecordingTip(false)
end

function ChatPage:_OnDragRecord(go, eventData, param)
  local state = Logic.chatLogic:GetRecordState(eventData)
  local down = Logic.chatLogic:CheckVoiceTime(Logic.chatLogic:GetChatContext().recordTime)
  local record = Logic.chatLogic:GetChatContext().recordState ~= MChatVoiceCommonState.NO
  self:_ShowCancelRecordTip(state == ChatRecordSlideState.UP and down and record)
  self:_ShowRecordingTip(state ~= ChatRecordSlideState.UP and down and record)
end

return ChatPage
