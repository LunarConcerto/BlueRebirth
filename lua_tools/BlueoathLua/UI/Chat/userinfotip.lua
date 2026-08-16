local UserInfoTip = class("UI.Chat.UserInfoTip", LuaUIPage)
local tab_UserInfo = {
  [1] = {
    1,
    2,
    3,
    4,
    5
  },
  [2] = {
    1,
    2,
    3,
    4,
    5
  },
  [3] = {
    1,
    2,
    3,
    4,
    5,
    6
  },
  [4] = {
    1,
    2,
    3,
    4,
    5,
    6
  },
  [5] = {
    1,
    2,
    4,
    8
  },
  [6] = {
    1,
    2,
    4,
    8
  }
}
local tabPosition = {
  maxX = 1.77,
  minX = -1.77,
  maxY = 1.0,
  minY = -1.0
}

function UserInfoTip:DoInit()
  self.m_tabWidgets = nil
  self.tab_UserInfoPageBtnInfo = {
    [1] = {
      "\229\177\165\229\142\134",
      self._ClickResume
    },
    [2] = {
      "\229\159\186\229\187\186",
      self._ClickAfterHome
    },
    [3] = {
      "\229\175\134\232\129\138",
      self._ClickCloseChat
    },
    [4] = {
      "\228\184\190\230\138\165",
      self._ClickReport
    },
    [5] = {
      "\229\138\160\229\133\165\233\187\145\229\144\141\229\141\149",
      self._ClickBlackList
    },
    [6] = {
      "\231\148\179\232\175\183\229\165\189\229\143\139",
      self._ClickApplyFriend
    },
    [7] = {
      "\233\130\128\232\175\183\229\133\165\228\188\154",
      self._ClickInviteMembership
    },
    [8] = {
      "\229\136\160\233\153\164\233\187\145\229\144\141\229\141\149",
      self._ClickDeleteBalck
    },
    [9] = {
      "\231\148\179\232\175\183\229\133\165\229\173\166",
      self._OnClickRequesetStudy
    },
    [10] = {
      "\230\139\155\230\148\182\229\173\166\229\145\152",
      self._OnClickRecruitStudent
    }
  }
  self.m_tabBtnLevelInfoList = {}
  self.m_tabUserInfo = nil
  self.nUserUid = nil
  self.m_trpc = false
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function UserInfoTip:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.obj_bg, function()
    self:_CloseSelf()
  end, self)
  self:RegisterEvent(LuaEvent.GetOtherUserInfoByUid, self._GetOtherUserInfoCallBack, self)
  self:RegisterEvent(LuaEvent.ApplyFriend, self._GetApplyFreindCallBack, self)
  self:RegisterEvent(LuaEvent.TEACHING_GetTeachOrStudyInfo, self._OnGetTeachInfo, self)
  self:RegisterEvent(LuaEvent.TEACHING_SendApplyErr, self._OnSendApplyErr, self)
  self:RegisterEvent(LuaEvent.TEACHING_SendApplyOk, self._OnSendApplyOk, self)
  self:RegisterEvent(LuaEvent.SetFriendBlackFail, self._SetBlackCallBackFail, self)
  self:RegisterEvent(LuaEvent.SetFriendBlackSuccess, self._SetBlackCallBackSuccess, self)
end

function UserInfoTip:_GetOtherUserInfoCallBack(param)
  self:_showInfo(true)
  self.m_tabUserInfo = param
  if param ~= nil then
    self:_SetUserMenuInfo(param)
    local otheruserStatus = Logic.friendLogic:GetUserStatusInfo(self.nUserUid)
    self:_GetTargetUserStatus(otheruserStatus)
  end
end

function UserInfoTip:_OnGetTeachInfo()
  local state = Logic.friendLogic:GetUserStatusInfo(self.nUserUid)
  self:_GetTargetUserStatus(state)
end

function UserInfoTip:DoOnOpen()
  local tabParam = self:GetParam()
  self.nUserUid = tabParam.Uid
  local tipTemporaryPos = tabParam.Position
  self.m_tabWidgets.trans_userTip.position = tipTemporaryPos
  self.m_tabWidgets.trans_userTip.position = self:GetUserTipPosition(tipTemporaryPos)
  Logic.friendLogic:SetTipsOpen(true)
  Service.userService:SendGetOtherInfo(self.nUserUid)
  self:_showInfo(false)
end

function UserInfoTip:_showInfo(enable)
  local widgets = self:GetWidgets()
  widgets.trans_userTip.gameObject:SetActive(enable)
end

function UserInfoTip:GetUserTipPosition(tipTemporaryPos)
  local left = self.m_tabWidgets.tipLeftTop.position.x
  local top = self.m_tabWidgets.tipLeftTop.position.y
  local right = self.m_tabWidgets.tipRightBottom.position.x
  local bottom = self.m_tabWidgets.tipRightBottom.position.y
  local height = top - bottom
  local width = right - left
  if bottom < tabPosition.minY then
    tipTemporaryPos.y = tabPosition.minY + height
  end
  if right > tabPosition.maxX then
    tipTemporaryPos.x = tabPosition.maxX - width
  end
  return tipTemporaryPos
end

function UserInfoTip:_SetUserMenuInfo(userInfo)
  local icon, qualityIcon = Logic.chatLogic:GetUserHead(userInfo)
  UIHelper.SetImage(self.m_tabWidgets.img_headBg, qualityIcon)
  UIHelper.SetImage(self.m_tabWidgets.im_head, icon)
  UIHelper.SetText(self.m_tabWidgets.tx_name, userInfo.Uname)
  UIHelper.SetText(self.m_tabWidgets.tx_lv, "LV." .. math.tointeger(userInfo.Level))
  local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(userInfo)
  self.m_tabWidgets.im_kuang.gameObject:SetActive(true)
  UIHelper.SetImage(self.m_tabWidgets.im_kuang, headFrameInfo.icon)
  if userInfo.GuildId ~= nil and userInfo.GuildId > 0 then
    UIHelper.SetLocText(self.m_tabWidgets.tx_conference, 710063, userInfo.GuildName)
  else
    UIHelper.SetLocText(self.m_tabWidgets.tx_conference, 710062)
  end
end

function UserInfoTip:_GetBtnInfoByIndex(btnIndex)
  for index = 1, #self.tab_UserInfoPageBtnInfo do
    if index == btnIndex then
      return self.tab_UserInfoPageBtnInfo[index]
    end
  end
end

function UserInfoTip:_GetTargetUserStatus(status)
  local btnInfo
  if status == FriendStatus.FRIEND then
    btnInfo = tab_UserInfo[1]
  elseif status == FriendStatus.BLACK then
    btnInfo = tab_UserInfo[5]
  else
    btnInfo = tab_UserInfo[3]
  end
  self:_addTeachBtnInfo(self.m_tabUserInfo, btnInfo)
  self:_showBtnList(btnInfo)
end

function UserInfoTip:_showBtnList(btnInfo)
  self.m_tabBtnLevelInfoList = {}
  for i = 1, #btnInfo do
    local show = self:_GetBtnInfoByIndex(btnInfo[i])
    table.insert(self.m_tabBtnLevelInfoList, show)
  end
  self:_LoadUserButtonListInfo(self.m_tabBtnLevelInfoList)
end

function UserInfoTip:_addTeachBtnInfo(userInfo, btnInfo)
  if Logic.friendLogic:IsMyFriend(userInfo.Uid) then
    local have, need = Logic.teachingLogic:HaveGetTeach()
    if need and not have and not self.m_trpcTag then
      Logic.teachingLogic:ForceGetTeach()
      self.m_trpc = true
      return
    end
    local isTeacher = Logic.teachingLogic:CheckIsTeacher(userInfo.Level)
    local have = function(sets, value)
      return table.containV(sets, value)
    end
    local ok
    if isTeacher then
      ok = Logic.teachingLogic:CheckShowApplyStudy(userInfo) and not have(btnInfo, 9)
      if ok then
        table.insert(btnInfo, 9)
      end
    else
      ok = Logic.teachingLogic:CheckShowRecruitNew(userInfo) and not have(btnInfo, 10)
      if ok then
        table.insert(btnInfo, 10)
      end
    end
  end
end

function UserInfoTip:_LoadUserButtonListInfo(m_tabBtnLevelInfoList)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_MenuSelect, self.m_tabWidgets.trans_MenuSelect, #m_tabBtnLevelInfoList, function(index, tabPart)
    self:_SetButtonItemInfo(tabPart, m_tabBtnLevelInfoList[index])
  end)
end

function UserInfoTip:_SetButtonItemInfo(tabPart, m_tabBtnDetailInfo)
  tabPart.txt_btntext.text = m_tabBtnDetailInfo[1]
  UGUIEventListener.AddButtonOnClick(tabPart.btn_info, function()
    m_tabBtnDetailInfo[2](self)
  end)
end

function UserInfoTip:_ClickResume()
  local curOrder = self:GetAdditionOrder()
  self:_CloseSelf()
  local pageObj = UIHelper.OpenPage("ResumePage", self.m_tabUserInfo)
  pageObj:SetAdditionOrder(curOrder)
  pageObj = nil
end

function UserInfoTip:_ClickAfterHome()
  noticeManager:ShowTip("\232\174\191\233\151\174\229\133\182\228\187\150\231\142\169\229\174\182\229\159\186\229\187\186\229\138\159\232\131\189\230\154\130\230\156\170\229\188\128\230\148\190")
end

function UserInfoTip:_ClickCloseChat()
  self:_CloseSelf()
  if Logic.friendLogic:IsMyFriend(self.m_tabUserInfo.Uid) then
    Data.chatData:SetChatChannel(ChatChannel.Friend)
  else
    Data.chatData:SetChatChannel(ChatChannel.Personal)
  end
  if Data.chatData:GetChatOpen() then
    eventManager:SendEvent(LuaEvent.SwitchChatChannel, self.m_tabUserInfo)
  else
    UIHelper.OpenPage("ChatPage", self.m_tabUserInfo)
  end
end

function UserInfoTip:_ClickReport()
  noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(210024), "\228\184\190\230\138\165"))
end

function UserInfoTip:_ClickBlackList()
  local blackMaxNum = configManager.GetDataById("config_parameter", 49).value
  local curBlackNum = Data.friendData:GetBlackData()
  if blackMaxNum <= #curBlackNum then
    noticeManager:ShowTip("\233\187\145\229\144\141\229\141\149\229\136\151\232\161\168\229\183\178\232\190\190\229\136\176\228\184\138\233\153\144")
    return
  end
  Service.friendService:SendSetBlack(self.nUserUid)
end

function UserInfoTip:_SetBlackCallBackSuccess()
  local togindex = Logic.friendLogic:GetTogIndex()
  if togindex == FriendList.Add then
    Service.friendService:SendGetRecommend()
  end
  self:_CloseSelf()
  noticeManager:ShowTip(UIHelper.GetString(210003))
  return
end

function UserInfoTip:_SetBlackCallBackFail(err)
  if err == -1027 then
    noticeManager:ShowTip(UIHelper.GetString(2200089))
    self:_CloseSelf()
    return
  end
end

function UserInfoTip:_ClickApplyFriend()
  if not moduleManager:CheckFunc(FunctionID.Friend, true) then
    noticeManager:ShowTip("\229\165\189\229\143\139\229\138\159\232\131\189\230\156\170\229\188\128\229\144\175")
    return
  end
  local checkResule = Logic.friendLogic:CheckApplyReq(self.nUserUid)
  if checkResule then
    noticeManager:OpenTipPage(self, "\229\183\178\230\143\144\228\186\164\232\191\135\231\148\179\232\175\183")
  else
    Logic.friendLogic:ClickApplyLogic(self.nUserUid, self)
  end
end

function UserInfoTip:_GetApplyFreindCallBack(err)
  if err == 2004 then
    noticeManager:OpenTipPage(self, 210009)
  elseif err == 2001 then
    noticeManager:OpenTipPage(self, 210007)
  elseif err == 2010 then
    noticeManager:OpenTipPage(self, 210026)
  elseif err == -1027 then
    noticeManager:OpenTipPage(self, 2200088)
  else
    noticeManager:OpenTipPage(self, 210012)
  end
  self:_CloseSelf()
end

function UserInfoTip:_ClickInviteMembership()
  noticeManager:OpenTipPage(self, "\233\130\128\232\175\183\229\133\165\228\188\154\229\138\159\232\131\189\230\156\170\229\188\128\230\148\190")
end

function UserInfoTip:_ClickDeleteBalck()
  Service.friendService:SendDeleteBlack(self.nUserUid)
  self:_CloseSelf()
  noticeManager:ShowTip(UIHelper.GetString(210019))
end

function UserInfoTip:_OnClickRequesetStudy()
  Logic.teachingLogic:RStudyBaseWrap(self.m_tabUserInfo)
end

function UserInfoTip:_OnClickRecruitStudent()
  Logic.teachingLogic:RTeachBaseWrap(self.m_tabUserInfo)
end

function UserInfoTip:_OnSendApplyErr(err)
  self:_CloseSelf()
end

function UserInfoTip:_OnSendApplyOk(uid)
  noticeManager:ShowTip(UIHelper.GetString(210012))
  self:_CloseSelf()
end

function UserInfoTip:_CloseSelf()
  UIHelper.ClosePage("UserInfoTip")
end

function UserInfoTip:DoOnHide()
  Logic.friendLogic:SetTipsOpen(false)
end

function UserInfoTip:DoOnClose()
  Logic.friendLogic:SetTipsOpen(false)
end

return UserInfoTip
