local FriendPage = class("UI.Bag.FriendPage", LuaUIPage)
local MAX_SHOW_NUM = 4
local Teaching_Function_Id = 61
local HintText = {
  {
    "\229\165\189\229\143\139",
    "uipic_ui_friend_icon_haoyou",
    UIHelper.GetString(210020)
  },
  {
    "\230\183\187\229\138\160",
    "uipic_ui_friend_icon_tianjia",
    UIHelper.GetString(210025)
  },
  {
    "\231\148\179\232\175\183",
    "uipic_ui_friend_icon_shenqing",
    UIHelper.GetString(210021),
    {8}
  },
  {
    "\233\187\145\229\144\141\229\141\149",
    "uipic_ui_friend_icon_heimingdan",
    UIHelper.GetString(210022)
  },
  {
    "\229\175\188\229\184\136",
    "uipic_ui_teaching_im_daoshirukou",
    "",
    {
      71,
      72,
      73,
      74,
      75
    },
    {81}
  }
}

function FriendPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_tabUserInfo = nil
  self.m_nUserMaxFriendNum = 0
  self.m_tabSerfriendData = nil
  self.m_nUserFriendNum = 0
  self.reFreshCDTimer = nil
  self.m_tabDeleteFreindInfo = nil
  self.FriendButttonNumList = {
    {
      {
        "uipic_ui_friend_fo_liaotian",
        "uipic_ui_friend_fo_shanchu"
      },
      {
        self._ClickChat,
        self._ClickFriendDelete
      },
      {
        "uipic_ui_friend_im_qipao",
        "uipic_ui_friend_im_shanchu"
      },
      813
    },
    {
      {
        "uipic_ui_friend_fo_shenqing"
      },
      {
        self._ClickApply
      },
      {
        "uipic_ui_friend_im_shenqing"
      },
      933
    },
    {
      {
        "uipic_ui_friend_fo_tongyi",
        "uipic_ui_friend_fo_jujue"
      },
      {
        self._ClickAddAccept,
        self._ClickAddRefuse
      },
      {
        "uipic_ui_friend_im_tongyi",
        "uipic_ui_friend_im_jujue"
      },
      813
    },
    {
      {
        "uipic_ui_friend_fo_shanchu"
      },
      {
        self._ClickBlackListDelete
      },
      {
        "uipic_ui_friend_im_shanchu"
      },
      933
    },
    {
      {
        "uipic_ui_friend_fo_tianjia"
      },
      {
        self._ClickCurrentAdd
      },
      {
        "uipic_ui_friend_fo_tianjia"
      },
      933
    }
  }
  self.m_selectRigth = nil
  self.currSelect = -1
end

function FriendPage:DoOnOpen()
  self:OpenTopPage("FriendPage", 1, "\229\165\189\229\143\139", self, true)
  if self.currSelect ~= -1 then
    local titleStr = self.currSelect == FriendList.Teaching and "\229\175\188\229\184\136" or "\229\165\189\229\143\139"
    eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {TitleName = titleStr})
  end
  self.m_tabUserInfo = Data.userData:GetUserData()
  self.m_nUserMaxFriendNum = Logic.friendLogic:GetUserFreindMaxNum(self.m_tabUserInfo.Level)
  self:_CreateRightBtn()
  local dotinfo = {info = "ui_friends"}
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  Service.friendService:_GetFriendMainData()
end

function FriendPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetFriendsInfo, self._GetFriendsInfoCallBack, self)
  self:RegisterEvent(LuaEvent.FriendSearchUser, self._GetSearchFriendCallBack, self)
  self:RegisterEvent(LuaEvent.GetRecommendInfo, self._GetRecommendCallBack, self)
  self:RegisterEvent(LuaEvent.ApplyFriend, self._GetApplyFreindCallBack, self)
  self:RegisterEvent(LuaEvent.UpdateUserOnLineState, self._UpdateUserState, self)
  self:RegisterEvent("SucessDeleteUserFromBlack", self._SucessDeleteUserFromBlackCallBack, self)
  self:RegisterEvent(LuaEvent.SetFriendBlackSuccess, self._SetBlackSuccessCallBack, self)
  self:RegisterEvent(LuaEvent.AddFriendSucceed, self._AddFrinedSucceed, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_search, self._ClickSearchFunction, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_refresh, function()
    self:_ClickRefreshFunction(false)
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_top, self._ClickTopButtonFunction, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_bottom, self._ClickBottomButtonFunction, self)
  UGUIEventListener.AddOnDrag(self.m_tabWidgets.ScrRect_FreindList, function()
    self:_DragScrollFunction()
  end, nil, nil)
end

function FriendPage:_CreateRightBtn()
  local currTogIndex = Logic.friendLogic:GetTogIndex() == -1 and 1 or Logic.friendLogic:GetTogIndex()
  local isJump = self.param ~= nil and self.param.selectTog ~= nil and currTogIndex == 1
  currTogIndex = isJump and self.param.selectTog or currTogIndex
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_rightItem, self.m_tabWidgets.trans_rightBtn, #HintText, function(nIndex, tabPart)
    tabPart.txt_title.text = HintText[nIndex][1]
    UIHelper.SetImage(tabPart.img_icon, HintText[nIndex][2])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_select, function()
      self:_SelectRightBtn(tabPart, nIndex)
    end)
    if HintText[nIndex][4] ~= nil then
      self:RegisterRedDotById(tabPart.redDot, HintText[nIndex][4])
    end
    if HintText[nIndex][5] ~= nil then
      self:RegisterRedDotById(tabPart.redNew, HintText[nIndex][5])
    end
    if self.m_selectRigth == nil and nIndex == currTogIndex then
      self:_SelectRightBtn(tabPart, nIndex)
    end
  end)
end

function FriendPage:_SelectOther()
  noticeManager:OpenTipPage(self, 270016)
end

function FriendPage:_SelectRightBtn(tabPart, nIndex)
  if nIndex == self.currSelect then
    return
  else
    UIHelper.ClosePage("TeachingPage")
  end
  if self.m_selectRigth ~= nil then
    self.m_selectRigth.tween_pos:Play(false)
    self.m_selectRigth.obj_line:SetActive(false)
  end
  self.currSelect = nIndex
  tabPart.tween_pos:Play(true)
  tabPart.obj_line:SetActive(true)
  self.m_selectRigth = tabPart
  self:_GetTopFriendNumText(nIndex)
  self.m_tabWidgets.obj_recommendNum:SetActive(nIndex == FriendList.Add)
  self.m_tabWidgets.obj_right:SetActive(nIndex ~= FriendList.Teaching)
  local titleStr = self.currSelect == FriendList.Teaching and "\229\175\188\229\184\136" or "\229\165\189\229\143\139"
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {TitleName = titleStr})
  if nIndex == FriendList.Teaching then
    if Logic.friendLogic:GetTogIndex() ~= FriendList.Teaching then
      moduleManager:JumpToFunc(FunctionID.Teaching)
    end
  elseif nIndex == FriendList.Add then
    self.m_tabWidgets.txt_InputPlayerId.text = ""
    self:_ClickRefreshFunction(true)
    self.m_tabWidgets.trans_friendsListView.offsetMax = Vector2.New(self.m_tabWidgets.trans_friendsListView.offsetMax.x, -48)
    self.m_tabWidgets.trans_friendsListView.offsetMin = Vector2.New(self.m_tabWidgets.trans_friendsListView.offsetMin.x, 14)
    self.m_tabWidgets.rect_content.offsetMax = Vector2.New(self.m_tabWidgets.rect_content.offsetMax.x, self.m_tabWidgets.rect_content.offsetMax.y - 48)
    self.m_tabWidgets.rect_content.offsetMin = Vector2.New(self.m_tabWidgets.rect_content.offsetMin.x, self.m_tabWidgets.rect_content.offsetMin.y - 14)
  else
    if nIndex == FriendList.Apply then
      Data.friendData:SetRedStateFalse()
    end
    self.m_tabSerfriendData = Logic.friendLogic:LoadFriendTypeInfo(nIndex)
    self:_LoadFriendsListInfo(nIndex, self.m_tabSerfriendData)
    self.m_tabWidgets.trans_friendsListView.offsetMax = Vector2.New(self.m_tabWidgets.trans_friendsListView.offsetMax.x, -33.1)
    self.m_tabWidgets.trans_friendsListView.offsetMin = Vector2.New(self.m_tabWidgets.trans_friendsListView.offsetMin.x, 63)
    self.m_tabWidgets.rect_content.offsetMax = Vector2.New(self.m_tabWidgets.rect_content.offsetMax.x, self.m_tabWidgets.rect_content.offsetMax.y - 33.1)
    self.m_tabWidgets.rect_content.offsetMin = Vector2.New(self.m_tabWidgets.rect_content.offsetMin.x, self.m_tabWidgets.rect_content.offsetMin.y - 63)
  end
  Logic.friendLogic:SetTogIndex(nIndex)
end

function FriendPage:_UpdateUserState(param)
  if param.Type == UserStatusType.Offline then
    local offtime = os.time()
    Data.friendData:SetFriendOffLineData(param.Uid, offtime)
  end
  if param.Type == UserStatusType.Online then
    Data.friendData:SetFriendOnLineData(param.Uid)
  end
  local togIndex = Logic.friendLogic:GetTogIndex()
  if togIndex == FriendList.Friend then
    self.m_tabSerfriendData = Data.friendData:GetFriendData()
    self:_LoadFriendsListInfo(togIndex, self.m_tabSerfriendData)
  end
end

function FriendPage:_DragScrollFunction()
  if #self.m_tabSerfriendData <= MAX_SHOW_NUM then
    self.m_tabWidgets.btn_top.gameObject:SetActive(false)
    self.m_tabWidgets.btn_bottom.gameObject:SetActive(false)
  else
    self.m_tabWidgets.btn_top.gameObject:SetActive(self.m_tabWidgets.ScrollbarVer.value ~= 1)
    self.m_tabWidgets.btn_bottom.gameObject:SetActive(self.m_tabWidgets.ScrollbarVer.value ~= 0)
  end
end

function FriendPage:_ClickTopButtonFunction()
  self.m_tabWidgets.ScrollbarVer.value = 1
  self.m_tabWidgets.btn_top.gameObject:SetActive(false)
  self.m_tabWidgets.btn_bottom.gameObject:SetActive(true)
end

function FriendPage:_ClickBottomButtonFunction()
  self.m_tabWidgets.ScrollbarVer.value = 0
  self.m_tabWidgets.btn_top.gameObject:SetActive(true)
  self.m_tabWidgets.btn_bottom.gameObject:SetActive(false)
end

function FriendPage:_GetFriendsInfoCallBack()
  local togIndex = Logic.friendLogic:GetTogIndex()
  if togIndex == FriendList.Teaching then
    return
  end
  self:_GetTopFriendNumText(togIndex)
  if togIndex ~= FriendList.Add then
    self.m_tabSerfriendData = Logic.friendLogic:LoadFriendTypeInfo(togIndex)
    self:_LoadFriendsListInfo(togIndex, self.m_tabSerfriendData)
  end
end

function FriendPage:_ClickSearchFunction()
  local searchContent = self.m_tabWidgets.txt_InputPlayerId.text
  if #searchContent == 0 then
    local showText = string.format(UIHelper.GetString(210005))
    noticeManager:OpenTipPage(self, showText)
    return
  end
  local arg
  arg = {Id = 0, Name = searchContent}
  Service.friendService:SendSearchUser(arg)
end

function FriendPage:_GetSearchFriendCallBack(param)
  if type(param) ~= "table" then
    if param == 2002 then
      noticeManager:OpenTipPage(self, "\231\148\168\230\136\183\230\156\172\232\186\171")
    elseif param == -1015 then
      noticeManager:OpenTipPage(self, 210005)
    elseif param == ErrorCode.ErrSearchName then
      noticeManager:OpenTipPage(self, 420020)
    end
    return
  end
  self.m_tabSerfriendData = param.List
  if #self.m_tabSerfriendData == 0 then
    noticeManager:OpenTipPage(self, 210005)
    return
  end
  if self.m_tabSerfriendData[1].Status == FriendStatus.APPLY then
    noticeManager:OpenTipPage(self, "\232\175\165\229\165\189\229\143\139\229\183\178\229\156\168\231\148\179\232\175\183\229\136\151\232\161\168\228\184\173")
  elseif self.m_tabSerfriendData[1].Status == FriendStatus.FRIEND then
    local showText = string.format(UIHelper.GetString(210016), self.m_tabSerfriendData[1].UserInfo.Uname)
    noticeManager:OpenTipPage(self, showText)
  elseif self.m_tabSerfriendData[1].Status == FriendStatus.BLACK then
    noticeManager:OpenTipPage(self, 210017)
  else
    self:_LoadFriendsListInfo(FriendList.Add, self.m_tabSerfriendData)
  end
end

function FriendPage:_ClickRefreshFunction(isChangeTog)
  local refreshCDTtime = configManager.GetDataById("config_parameter", 43).value / 1000
  if self.reFreshCDTimer == nil then
    Service.friendService:SendGetRecommend()
    if not isChangeTog then
      noticeManager:ShowTip("\229\136\183\230\150\176\230\136\144\229\138\159")
    end
    self.reFreshCDTimer = self:CreateTimer(function()
      self:StopTimer(self.reFreshCDTimer)
      self.reFreshCDTimer = nil
    end, math.tointeger(refreshCDTtime), 1, false)
  elseif not isChangeTog then
    noticeManager:ShowTip(UIHelper.GetString(210023))
  else
    self:_RefreshRecommendList()
  end
  self:StartTimer(self.reFreshCDTimer)
end

function FriendPage:_GetRecommendCallBack(info)
  Logic.friendLogic:SetRecommendData(info)
  self.m_tabSerfriendData = Logic.friendLogic:SortFriendRecommendList(info)
  self:_LoadFriendsListInfo(FriendList.Add, self.m_tabSerfriendData)
end

function FriendPage:_LoadFriendsListInfo(togIndex, tabSerfriendListData)
  local listNum = GetTableLength(tabSerfriendListData)
  if listNum ~= 0 then
    self:_LoadFriendItem(listNum, tabSerfriendListData, togIndex)
  end
  self.m_tabWidgets.tx_content.text = HintText[togIndex][3]
  self.m_tabWidgets.im_girl:SetActive(listNum == 0)
  self.m_tabWidgets.iil_FriendSV.gameObject:SetActive(listNum ~= 0)
  self.m_tabWidgets.btn_top.gameObject:SetActive(listNum ~= 0 and self.m_tabWidgets.ScrollbarVer.value ~= 1)
  self.m_tabWidgets.btn_bottom.gameObject:SetActive(listNum > MAX_SHOW_NUM)
end

function FriendPage:_LoadFriendItem(listNum, tabSerfriendListData, togIndex)
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_FriendSV, self.m_tabWidgets.obj_friendItem, listNum, function(tabPart)
    local tabTemp = {}
    for k, v in pairs(tabPart) do
      tabTemp[tonumber(k)] = v
    end
    for index, luaPart in pairs(tabTemp) do
      luaPart.txt_name.text = tabSerfriendListData[index].UserInfo.Uname
      luaPart.txt_level.text = "LV." .. math.tointeger(tabSerfriendListData[index].UserInfo.Level)
      luaPart.txt_state.text = Logic.friendLogic:GetUserStatus(math.tointeger(tonumber(tabSerfriendListData[index].OfflineTime)), tabSerfriendListData[index].UserInfo.Uid)
      local icon, qualityIcon = Logic.chatLogic:GetUserHead(tabSerfriendListData[index].UserInfo)
      UIHelper.SetImage(luaPart.im_headIcon, icon)
      UIHelper.SetImage(luaPart.img_headBg, qualityIcon)
      if tonumber(tabSerfriendListData[index].OfflineTime) == 0 then
        UIHelper.SetTextColor(luaPart.txt_state, luaPart.txt_state.text, "33be53")
      else
        UIHelper.SetTextColor(luaPart.txt_state, luaPart.txt_state.text, "5e718a")
      end
      if tabSerfriendListData[index].UserInfo.message ~= "" then
        luaPart.txt_describe.text = tabSerfriendListData[index].UserInfo.message
      else
        luaPart.txt_describe.text = " \232\191\153\229\174\182\228\188\153\229\190\136\230\135\146\239\188\140\228\187\128\228\185\136\233\131\189\230\178\161\229\134\153"
      end
      local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(tabSerfriendListData[index].UserInfo)
      luaPart.im_kuang.gameObject:SetActive(true)
      UIHelper.SetImage(luaPart.im_kuang, headFrameInfo.icon)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_headIcon.gameObject, function()
        local paramTab = {
          Uid = tabSerfriendListData[index].UserInfo.Uid,
          Position = luaPart.trans_Icon.position
        }
        if tabSerfriendListData[index].UserInfo.Uid ~= self.m_tabUserInfo.Uid then
          UIHelper.OpenPage("UserInfoTip", paramTab)
        end
      end)
      self:_LoadButtonInfo(luaPart, togIndex, tabSerfriendListData[index])
    end
  end)
end

function FriendPage:_LoadButtonInfo(luaPart, togIndex, tabSerfriendData)
  local tabBtn = self.FriendButttonNumList[togIndex]
  local btnName = tabBtn[1]
  local btnFun = tabBtn[2]
  local btnIcon = tabBtn[3]
  local bgWidth = tabBtn[4]
  luaPart.rect_infoBg.sizeDelta = Vector2.New(bgWidth, luaPart.rect_infoBg.sizeDelta.y)
  UIHelper.CreateSubPart(luaPart.obj_button, luaPart.trans_btnList, #btnName, function(index, part)
    UIHelper.SetImage(part.img_btnName, btnName[index])
    UIHelper.SetImage(part.im_btnIcon, btnIcon[index])
    UGUIEventListener.AddButtonOnClick(part.btn_button.gameObject, function()
      btnFun[index](self, tabSerfriendData)
    end)
  end)
end

function FriendPage:_ClickChat(tabSerfriendData)
  Data.chatData:SetChatChannel(ChatChannel.Friend)
  UIHelper.OpenPage("ChatPage", tabSerfriendData.UserInfo)
end

function FriendPage:_ClickAfterHome()
  noticeManager:OpenTipPage(self, "\229\144\142\229\174\133\229\138\159\232\131\189\230\154\130\230\156\170\229\188\128\230\148\190")
end

function FriendPage:_ClickFriendDelete(tabSerfriendData)
  self.m_tabDeleteFreindInfo = tabSerfriendData
  local showText = string.format(UIHelper.GetString(210010), self.m_tabDeleteFreindInfo.UserInfo.Uname)
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        self:_ClikSureDeleteFreind()
      end
    end
  }
  noticeManager:ShowMsgBox(showText, tabParams)
end

function FriendPage:_ClikSureDeleteFreind()
  local applyUid = self.m_tabDeleteFreindInfo.UserInfo.Uid
  Service.friendService:SendDeleteFriend(applyUid)
end

function FriendPage:_ClickApply(tabSerfriendData)
  local checkResule = Logic.friendLogic:CheckApplyReq(tabSerfriendData.UserInfo.Uid)
  if checkResule then
    noticeManager:OpenTipPage(self, "\229\183\178\230\143\144\228\186\164\232\191\135\231\148\179\232\175\183")
  elseif tabSerfriendData.UserInfo.Uid == self.m_tabUserInfo.Uid then
    noticeManager:OpenTipPage(self, "\228\184\141\232\131\189\230\183\187\229\138\160\232\135\170\229\183\177\228\184\186\229\165\189\229\143\139")
  else
    Logic.friendLogic:ClickApplyLogic(tabSerfriendData.UserInfo.Uid, self)
  end
end

function FriendPage:_ClickAddAccept(tabSerfriendData)
  self.m_nUserFriendNum = Logic.friendLogic:GetUserFriendNum()
  if self.m_nUserFriendNum >= self.m_nUserMaxFriendNum then
    noticeManager:OpenTipPage(self, 210007)
  else
    local applyUid = tabSerfriendData.UserInfo.Uid
    Service.friendService:SendAccept(applyUid)
  end
end

function FriendPage:_ClickAddRefuse(tabSerfriendData)
  local applyUid = tabSerfriendData.UserInfo.Uid
  Service.friendService:SendRefuse(applyUid)
  noticeManager:OpenTipPage(self, 210018)
end

function FriendPage:_ClickBlackListDelete(tabSerfriendData)
  local applyUid = tabSerfriendData.UserInfo.Uid
  Service.friendService:SendDeleteBlack(applyUid)
end

function FriendPage:_ClickCurrentAdd()
  noticeManager:OpenTipPage(self, "\229\138\159\232\131\189\230\156\170\229\188\128\229\144\175")
end

function FriendPage:_GetTopFriendNumText(togIndex)
  self.m_tabWidgets.obj_topSearch.gameObject:SetActive(togIndex == FriendList.Add)
  self.m_tabWidgets.txt_topFriendNum.gameObject:SetActive(togIndex ~= FriendList.Add)
  if togIndex == FriendList.Add then
    self.m_tabWidgets.trans_friendsViewport.sizeDelta = Vector2.New(0, -95)
  else
    self.m_tabWidgets.trans_friendsViewport.sizeDelta = Vector2.New(0, 0)
  end
  if togIndex == FriendList.Add then
    self.m_tabWidgets.txt_topPlayerId.text = platformManager:getRoleId() or math.tointeger(self.m_tabUserInfo.Uid)
  else
    local tabSerData = Data.friendData:GetFriendData()
    for v, k in pairs(tabSerData) do
      self.m_nUserFriendNum = v
    end
    self.m_tabWidgets.txt_topFriendNum.text = self.m_nUserFriendNum .. "/" .. self.m_nUserMaxFriendNum
    if self.m_nUserFriendNum == 0 then
      self.m_tabWidgets.im_girl:SetActive(true)
    else
      self.m_tabWidgets.im_girl:SetActive(false)
    end
  end
end

function FriendPage:_AddFrinedSucceed(err)
  if err == 2004 then
    noticeManager:OpenTipPage(self, 210009)
  elseif err == 2001 then
    noticeManager:OpenTipPage(self, 210007)
  else
    noticeManager:OpenTipPage(self, 210008)
  end
end

function FriendPage:_GetApplyFreindCallBack(err)
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
    Logic.friendLogic:RemoveRecommendUser()
    self:_RefreshRecommendList()
  end
end

function FriendPage:_RefreshRecommendList()
  if self.currSelect ~= FriendList.Add then
    return
  end
  local listData = Logic.friendLogic:GetRecommendData()
  if next(listData) == nil then
    Service.friendService:SendGetRecommend()
  else
    self.m_tabSerfriendData = Logic.friendLogic:LoadFriendTypeInfo(FriendList.Add)
    self:_LoadFriendsListInfo(FriendList.Add, self.m_tabSerfriendData)
  end
end

function FriendPage:_SucessDeleteUserFromBlackCallBack()
  noticeManager:OpenTipPage(self, 210019)
end

function FriendPage:_SetBlackSuccessCallBack()
  noticeManager:OpenTipPage(self, 210003)
end

function FriendPage:DoOnHide()
  if self.reFreshCDTimer ~= nil then
    self:StopTimer(self.reFreshCDTimer)
    self.reFreshCDTimer = nil
  end
end

function FriendPage:DoOnClose()
  Logic.friendLogic:SetTogIndex(-1)
  if self.reFreshCDTimer ~= nil then
    self:StopTimer(self.reFreshCDTimer)
  end
end

return FriendPage
