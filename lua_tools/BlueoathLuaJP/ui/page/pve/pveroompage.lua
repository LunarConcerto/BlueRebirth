local PVERoomPage = class("UI.Pve.PVERoomPage", LuaUIPage)

function PVERoomPage:DoInit()
  self.copyId = 0
  self.isOwner = false
  self.roomInfoTab = {}
  self.pveRoomPlayerMax = 0
  self.UpdatePveRoomFunc = {
    [UpdatePveRoom.RoomExit] = self._RoomExit,
    [UpdatePveRoom.RoomDissmiss] = self._RoomDissmiss,
    [UpdatePveRoom.RoomReady] = self._RoomReady,
    [UpdatePveRoom.RoomCancel] = self._RoomReady,
    [UpdatePveRoom.RoomKick] = self._RoomKick,
    [UpdatePveRoom.RoomSwitchRoomPublicState] = self._RoomSwitchRoomPublicState
  }
  Logic.pveRoomLogic:SetPageWidgets(self.tab_Widgets)
  Logic.pveRoomLogic:RegisterEvent()
  self.speedState = false
end

function PVERoomPage:DoOnOpen()
  Logic.copyLogic:SetInPveState(true)
  self.roomInfoTab = Data.pveRoomData:GetPveRoomData()
  self.roomId = self.roomInfoTab.RoomId
  self.copyId = self.roomInfoTab.CopyId
  self.pveRoomPlayerMax = Logic.pveRoomLogic:GetRoomPlayerMax(self.copyId)
  self.isOwner = Logic.pveRoomLogic:CheckIsOwner(self.roomInfoTab)
  self.tab_Widgets.tog_repaire.isOn = Logic.pveRoomLogic:GetAutoRepaireInfo()
  self:_ClickTogRepaire()
  
  local function callBack()
    if self.isOwner then
      self:_ClickDismiss()
    else
      self:_ClickExit()
    end
  end
  
  self:OpenTopPage("PVERoomPage", 1, UIHelper.GetString(6100059), self, true, callBack)
  eventManager:SendEvent(LuaEvent.TopShowPvePt)
  self.tab_Widgets.txt_startTimer.gameObject:SetActive(false)
  self:_RoomInfo()
  self:_RoomUsers()
  self:RequireRandomFactors()
  self:ShowSpeedMode()
  Logic.copyLogic:SetCurCopyId(self.copyId)
end

function PVERoomPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_changeState, self._ClickChangeState, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_start, self._ClickStart, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.tog_repaire, self._ClickTogRepaire, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_chat, self._ClickChat, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_Invite, self.ClickInvite, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.obj_randFactor, self._ShowFactorDetail, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self.ClickHelpBtn, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_jiasu, self.ClickSpeedBtn, self)
  self:RegisterEvent(LuaEvent.StartTeamPve, function()
    if self.isOwner then
      local arg = {
        RoomId = self.roomId,
        CopyId = self.copyId
      }
      Service.pveRoomService:SendStart(arg)
    end
  end, self)
  self:RegisterEvent(LuaEvent.UpdatePveRoomInfo, self._UpdatePveRoomInfo, self)
  self:RegisterEvent(LuaEvent.PveRoomTimeOut, self._PveRoomTimeOut, self)
  self:RegisterEvent(LuaEvent.HidePveRoomPage, function()
    self:ClosePveRoomPage()
  end, self)
  self:RegisterEvent(LuaEvent.CopyStartBase, function(handler, ret)
    self:CopyEnter(ret)
  end)
  self:RegisterEvent(LuaEvent.PveRoomStart, self._ClickStart, self)
  self:RegisterEvent("getRepaireMsg", self._AutoRepaireCallBack, self)
  self:RegisterEvent(LuaEvent.DisconnectServer, function()
    self:ClosePveRoomPage()
  end, self)
  self:RegisterEvent(LuaEvent.GetRandFactor, self._GetRandFactorCallback)
  self:RegisterEvent(LuaEvent.PveRoomAddUser, self.ShowNewUserTips)
end

function PVERoomPage:_RoomInfo()
  local copyName = Logic.pveRoomLogic:GetPveCopyName(self.copyId)
  UIHelper.SetText(self.tab_Widgets.txt_copyname, copyName)
  UIHelper.SetText(self.tab_Widgets.txt_roomnum, self.roomId)
  local roomState = self.roomInfoTab.IsPublic == false and UIHelper.GetString(6100033) or UIHelper.GetString(6100034)
  UIHelper.SetText(self.tab_Widgets.txt_roomstage, roomState)
  self.tab_Widgets.btn_changeState.gameObject:SetActive(self.isOwner)
  self.tab_Widgets.btn_start.gameObject:SetActive(self.isOwner)
  self.tab_Widgets.btn_exit.gameObject:SetActive(not self.isOwner)
end

function PVERoomPage:_RoomUsers()
  local sortRoomUsers = Logic.pveRoomLogic:SortRoomUsers(self.roomInfoTab.RoomUsers)
  UIHelper.CreateSubPart(self.tab_Widgets.item_copy, self.tab_Widgets.trans_content, self.pveRoomPlayerMax, function(nIndex, luaPart)
    local inRoomPlayer = sortRoomUsers[nIndex]
    luaPart.obj_team.gameObject:SetActive(inRoomPlayer ~= nil)
    luaPart.obj_empty:SetActive(inRoomPlayer == nil)
    if inRoomPlayer ~= nil then
      UIHelper.SetText(luaPart.txt_name, inRoomPlayer.Name)
      luaPart.txt_lv.gameObject:SetActive(false)
      local headIcon, qualityIcon = Data.userData:GetUserHeadIcon(inRoomPlayer)
      UIHelper.SetImage(luaPart.im_headicon, headIcon)
      UIHelper.SetImage(luaPart.im_quality, qualityIcon)
      local uid = Data.userData:GetUserUid()
      luaPart.btn_change.gameObject:SetActive(inRoomPlayer.Uid == uid and not inRoomPlayer.IsReady)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_change, self._ClickChange, self)
      local allHeroInfo = {}
      allHeroInfo = clone(inRoomPlayer.HeroList[1])
      local exFleetInfo = inRoomPlayer.HeroList[2]
      if exFleetInfo ~= nil then
        for i = 1, #exFleetInfo.HeroIdList do
          table.insert(allHeroInfo.HeroIdList, exFleetInfo.HeroIdList[i])
          table.insert(allHeroInfo.HeroInfo, exFleetInfo.HeroInfo[i])
        end
      end
      if next(allHeroInfo) ~= nil then
        luaPart.txt_strategy.gameObject:SetActive(allHeroInfo.StrategyId ~= 0)
        if allHeroInfo.StrategyId ~= 0 then
          local strategyConfig = configManager.GetDataById("config_strategy", allHeroInfo.StrategyId)
          UIHelper.SetText(luaPart.txt_strategy, strategyConfig.strategy_name)
        end
        local fleetHero = allHeroInfo.HeroIdList
        UIHelper.CreateSubPart(luaPart.item_ship, luaPart.trans_shipslot, #fleetHero, function(index, tabParts)
          local heroInfo = allHeroInfo.HeroInfo[index]
          local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.Tid)
          local showInfo = Logic.shipLogic:GetShipShowByFashionId(heroInfo.Fashioning)
          UIHelper.SetText(tabParts.tx_lv, Mathf.ToInt(heroInfo.Level))
          UIHelper.SetImage(tabParts.im_quality, HorizontalCardQulity[shipInfo.quality])
          UIHelper.SetImage(tabParts.im_icon, tostring(showInfo.ship_icon5))
          if index == 1 then
            UIHelper.SetImage(tabParts.img_typeBg, "uipic_ui_newfleetpage_bg_qijiandiban")
          end
          UIHelper.SetImage(tabParts.img_type, NewCardShipTypeImg[shipInfo.ship_type])
          UIHelper.SetStar(tabParts.Star, tabParts.StarPrt, heroInfo.Advance)
        end)
      end
      luaPart.obj_maker:SetActive(self.roomInfoTab.OwnerId == inRoomPlayer.Uid)
      luaPart.btn_prepared.gameObject:SetActive(false)
      if self.isOwner then
        luaPart.btn_quit.gameObject:SetActive(index ~= 1 and inRoomPlayer.Uid ~= self.roomInfoTab.OwnerId)
        UGUIEventListener.AddButtonOnClick(luaPart.btn_quit, self._ClickQuit, self, inRoomPlayer)
        if nIndex == 1 then
          luaPart.obj_ready:SetActive(false)
        else
          luaPart.obj_ready:SetActive(inRoomPlayer.IsReady)
        end
      else
        luaPart.btn_quit.gameObject:SetActive(false)
        luaPart.obj_ready:SetActive(false)
        luaPart.btn_prepared.gameObject:SetActive(false)
        if uid == inRoomPlayer.Uid then
          local str = inRoomPlayer.IsReady and UIHelper.GetString(6100036) or UIHelper.GetString(6100035)
          UIHelper.SetText(self.tab_Widgets.txt_prepared, str)
          UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_exit, self._ClickPrepared, self, {inRoomPlayer, luaPart})
        end
        luaPart.obj_ready:SetActive(inRoomPlayer.IsReady)
      end
      if uid == inRoomPlayer.Uid then
        self:_GetRepaireNum()
      end
    end
  end)
end

function PVERoomPage:_ClickChange()
  Logic.pveRoomLogic:SetPveTacticNum(self.copyId)
  UIHelper.OpenPage("PresetFleetPage", {
    presetFleetType = PresetFleetType.Match
  })
end

function PVERoomPage:_ClickDismiss()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.pveRoomService:SendDismissRoom(self.roomId)
      end
    end
  }
  noticeManager:ShowMsgBox(6100029, tabParams)
end

function PVERoomPage:_ClickPrepared(go, params)
  local info = params[1]
  local tabParts = params[2]
  if not info.IsReady then
    local isAutoRepaire = self:_AutoRepaire()
    if not isAutoRepaire then
      self:CheckStartCondition()
    end
    UIHelper.SetText(self.tab_Widgets.txt_prepared, UIHelper.GetString(6100036))
  elseif info.IsReady then
    Service.pveRoomService:SendCancel(self.roomId)
    UIHelper.SetText(self.tab_Widgets.txt_prepared, UIHelper.GetString(6100035))
    Logic.copyLogic:SetUserEnterBattle(false)
  end
end

function PVERoomPage:_ClickChangeState()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.pveRoomService:SendSwitchRoomState()
      end
    end
  }
  if self.roomInfoTab.IsPublic then
    noticeManager:ShowMsgBox(6100075, tabParams)
  else
    noticeManager:ShowMsgBox(6100026, tabParams)
  end
end

function PVERoomPage:_ClickExit()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.pveRoomService:SendExitRoom(self.roomId)
        self:ClosePveRoomPage()
        noticeManager:OpenTipPage(self, UIHelper.GetString(6100045))
      end
    end
  }
  noticeManager:ShowMsgBox(6100030, tabParams)
end

function PVERoomPage:_ClickStart()
  local isAutoRepaire = self:_AutoRepaire()
  if not isAutoRepaire then
    self:CheckStartCondition()
  end
end

function PVERoomPage:_ClickQuit(go, playerInfo)
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.pveRoomService:SendKick(self.roomId, playerInfo.Uid)
      end
    end
  }
  noticeManager:ShowMsgBox(6100028, tabParams)
end

function PVERoomPage:_UpdatePveRoomInfo()
  self.roomInfoTab = Data.pveRoomData:GetPveRoomData()
  if self.UpdatePveRoomFunc[self.roomInfoTab.Reason] ~= nil then
    self.UpdatePveRoomFunc[self.roomInfoTab.Reason](self)
  else
    self:_RoomInfo()
    self:_RoomUsers()
  end
end

function PVERoomPage:_RoomDissmiss()
  self:ClosePveRoomPage()
  noticeManager:OpenTipPage(self, UIHelper.GetString(6100032))
end

function PVERoomPage:_RoomSwitchRoomPublicState()
  self.tab_Widgets.btn_changeState.gameObject:SetActive(self.isOwner)
  local roomState = self.roomInfoTab.IsPublic == false and UIHelper.GetString(6100033) or UIHelper.GetString(6100034)
  UIHelper.SetText(self.tab_Widgets.txt_roomstage, roomState)
  noticeManager:OpenTipPage(self, UIHelper.GetString(6100046))
end

function PVERoomPage:_RoomKick()
  local kickUId = Logic.pveRoomLogic:GetOperationUserId(self.roomInfoTab)
  local uid = Data.userData:GetUserUid()
  if kickUId == uid then
    self:ClosePveRoomPage()
    noticeManager:OpenTipPage(self, UIHelper.GetString(6100047))
  else
    self:_RoomUsers()
  end
end

function PVERoomPage:_RoomExit()
  local exitUserName = Logic.pveRoomLogic:GetExitUserName(self.roomInfoTab)
  noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(6100031), exitUserName))
  self:_RoomUsers()
end

function PVERoomPage:_RoomReady()
  self:_RoomUsers()
end

function PVERoomPage:_PveRoomTimeOut()
  self:ClosePveRoomPage()
  noticeManager:ShowMsgBox(UIHelper.GetString(6100048))
end

function PVERoomPage:ClosePveRoomPage()
  UIHelper.ClosePage("PVERoomPage")
  Logic.copyLogic:SetUserEnterBattle(false)
  Logic.copyLogic:SetInPveState(false)
end

function PVERoomPage:_PrepareData()
  self:UnregisterEvent(LuaEvent.CacheDataRet, self.BackMatchCacheSuccess, self)
  self:RegisterEvent(LuaEvent.CacheDataRet, self.BackMatchCacheSuccess, self)
  Service.pveRoomService:GetCacheId()
end

function PVERoomPage:BackMatchCacheSuccess(cacheId)
  self:UnregisterEvent(LuaEvent.CacheDataRet, self.BackMatchCacheSuccess, self)
  self.m_cacheId = cacheId
  self:_BackReadySuc()
end

function PVERoomPage:_BackReadySuc()
  local userRoomData = Data.pveRoomData:GetUserRoomInfo()
  local copyConfig = configManager.GetDataById("config_copy", self.copyId)
  local id = Logic.copyLogic:GetChapterIdByCopyId(copyConfig.copy_id)
  local ChapterId = id
  if ChapterId == nil then
    logError("ChapterId is nil")
  end
  local RoomId = self.roomId
  local CopyId = self.copyId
  local TacticId = 1
  local IsRunningFight = false
  local CacheId = self.m_cacheId
  local BattleMode = BattleMode.Normal
  local MatchType = 1
  local HeroList = userRoomData.HeroList[1].HeroIdList
  local StrategyId = userRoomData.HeroList[1].StrategyId
  local exHeroList = userRoomData.HeroList[2].HeroIdList
  self:UnregisterEvent(LuaEvent.CacheDataRet, self.BackMatchCacheSuccess, self)
  local IsMultiple = self.speedState
  local args = {
    chapterId = ChapterId,
    baseId = CopyId,
    isRunningFight = IsRunningFight,
    tacticId = TacticId,
    cacheId = CacheId,
    heroList = HeroList,
    strategyId = StrategyId,
    roomId = RoomId,
    matchType = MatchType,
    isSpeedUpMode = IsMultiple,
    exHeroList = exHeroList
  }
  self:RoomPageStartBase(args)
end

function PVERoomPage:RoomPageStartBase(args)
  Service.copyService:SendStartBaseTeamPve(args)
end

function PVERoomPage:CheckStartCondition()
  if self.isOwner then
    self:CheckAllUserReady()
  else
    self:CheckSupply()
  end
end

function PVERoomPage:CheckAllUserReady()
  if not Logic.pveRoomLogic:CheckUserReady(self.roomInfoTab) then
    noticeManager:OpenTipPage(self, UIHelper.GetString(6100057))
    return
  else
    local maxCount = Logic.pveRoomLogic:GetRoomPlayerMax(self.copyId)
    if maxCount <= #self.roomInfoTab.RoomUsers then
      self:CheckSupply()
    else
      noticeManager:OpenTipPage(self, UIHelper.GetString(6100060))
    end
  end
end

function PVERoomPage:CheckSupply()
  if not Logic.pveRoomLogic:CheckExpend() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          UIHelper.OpenPage("ShopPage", {
            shopId = ShopId.PveRoomShop
          })
        end
      end
    }
    noticeManager:ShowMsgBox(110035, tabParams)
  else
    self:CheckUserBagFull()
  end
end

function PVERoomPage:CheckUserBagFull()
  if Logic.copyLogic:CheckDockFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          UIHelper.OpenPage("HeroRetirePage")
        end
      end,
      nameOk = UIHelper.GetString(180029)
    }
    noticeManager:ShowMsgBox(110012, tabParams)
  else
    self:CheckEquipBagFull()
  end
end

function PVERoomPage:CheckEquipBagFull()
  if Logic.copyLogic:CheckEquipBagFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          UIHelper.ClosePage("NoticePage")
          UIHelper.OpenPage("DismantlePage")
        end
      end
    }
    noticeManager:ShowMsgBox(1000014, tabParams)
  else
    self:_PrepareData()
  end
end

function PVERoomPage:CopyEnter(ret)
  local userData = Data.userData:GetUserData()
  if ret == nil or ret.Rid == nil then
    noticeManager:ShowMsgBox(UIHelper.GetString(920000185))
    return
  end
  local safeLv = 0
  local safePoint = 0
  Logic.copyLogic:SetAttackCopyInfo(self.copyId, 0, safeLv, safePoint)
  local isStrat = {}
  local SetConditions = {
    1,
    2,
    3,
    4
  }
  local SetQucikConditions = {}
  SetQucikConditions, isStrat = Logic.setLogic:GenSetCondition(self.copyId, safeLv)
  Logic.setLogic:SetQuickChallenge(isStrat)
  Logic.copyLogic:SetUserEnterBattle(true)
  Logic.copyLogic:SetEnterLevelInfo(false)
  Data.copyData:SetRecordMatchCopyData(self.copyId)
  homeEnvManager:EnterBattle()
end

function PVERoomPage:_AutoRepaire()
  local isAutoRepaire = false
  if not self.tab_Widgets.tog_repaire.isOn then
    return isAutoRepaire
  end
  local tabHero = {}
  local needRepairShip, needGold = self:_GetRepaireNum()
  if 0 < #needRepairShip then
    local userGoldData = Data.userData:GetCurrency(CurrencyType.GOLD)
    if needGold <= userGoldData then
      isAutoRepaire = true
      for k, v in pairs(needRepairShip) do
        table.insert(tabHero, v.HeroId)
      end
      Service.repaireService:SendGetRepair(tabHero)
    else
      isAutoRepaire = false
      noticeManager:ShowTipById(6100067)
      self.tab_Widgets.tog_repaire.isOn = false
      self:_ClickTogRepaire()
    end
  end
  return isAutoRepaire
end

function PVERoomPage:_GetRepaireNum()
  local curToggleShip = {}
  local uid = Data.userData:GetUserUid()
  local heroInfo = {}
  for _, v in ipairs(self.roomInfoTab.RoomUsers) do
    if v.Uid == uid then
      heroInfo = clone(v.HeroList[1].HeroIdList)
      if v.HeroList[2] then
        for _, v in pairs(v.HeroList[2].HeroIdList) do
          table.insert(heroInfo, v)
        end
      end
    end
  end
  for _, v in pairs(heroInfo) do
    if not npcAssistFleetMgr:IsNpcHeroId(v) then
      table.insert(curToggleShip, Data.heroData:GetHeroById(v))
    end
  end
  local needRepairShip = Logic.repaireLogic:GetRepairShip(curToggleShip)
  local needGold = Logic.repaireLogic:CalculateNeedAllGold(needRepairShip)
  self.tab_Widgets.txt_repaireNum.text = Mathf.ToInt(needGold)
  return needRepairShip, needGold
end

function PVERoomPage:_ClickTogRepaire()
  if self.tab_Widgets.tog_repaire.isOn then
    self.tab_Widgets.im_repaire:SetActive(self.tab_Widgets.tog_repaire.isOn)
    self.tab_Widgets.im_norepaire:SetActive(not self.tab_Widgets.tog_repaire.isOn)
  else
    self.tab_Widgets.im_norepaire:SetActive(not self.tab_Widgets.tog_repaire.isOn)
    self.tab_Widgets.im_repaire:SetActive(self.tab_Widgets.tog_repaire.isOn)
  end
  Logic.pveRoomLogic:SetAutoRepaireInfo(self.tab_Widgets.tog_repaire.isOn)
end

function PVERoomPage:_AutoRepaireCallBack()
  self:CheckStartCondition()
  self:_GetRepaireNum()
end

function PVERoomPage:DoOnClose()
  Logic.pveRoomLogic:UnregisterEvent()
  Logic.pveRoomLogic:StopCounting()
end

function PVERoomPage:_ClickChat()
  local haveUnRead = Logic.chatLogic:HaveUnReadMsgByChannel(ChatChannel.Personal)
  if haveUnRead then
    Data.chatData:SetChatChannel(ChatChannel.Personal)
    local uid = Data.chatData:GetNowChatUserInfo()
    Data.chatData:ResetUnReadNumByUid(uid)
  end
  UIHelper.OpenPage("ChatPage")
end

function PVERoomPage:ClickInvite()
  local lastTime = Logic.pveRoomLogic:GetInviteTime(self.roomId)
  if lastTime then
    local coolTime = configManager.GetDataById("config_parameter", 531).value
    local checkTime = lastTime + tonumber(coolTime) - time.getSvrTime()
    if 0 < checkTime then
      local str = string.format(UIHelper.GetString(4800117), checkTime)
      noticeManager:ShowTip(str)
      return
    end
  end
  local userInfo = Data.userData:GetUserData()
  local name = userInfo.Uname
  local copyName = Logic.pveRoomLogic:GetPveCopyName(self.copyId)
  local tag = ChatJumpType.ROOMID .. ":" .. self.roomId .. "|"
  local showMsg = tag .. string.format(UIHelper.GetString(4800104), name, copyName)
  local ok, channel, rmsg = self:_SendMsgCheck(showMsg)
  if ok then
    Service.chatService:SendMessage(channel, 0, rmsg, ChatMsgType.JUMP)
    noticeManager:ShowTipById(4800114)
    Logic.pveRoomLogic:SetInviteTime(self.roomId, time.getSvrTime())
  end
end

function PVERoomPage:_SendMsgCheck(msg, voice2text)
  if not moduleManager:CheckFunc(FunctionID.Chat, true) then
    noticeManager:ShowTip(UIHelper.GetString(920000143))
    return
  end
  local ban = Logic.chatLogic:IsInBan()
  if ban then
    noticeManager:ShowTip(UIHelper.GetString(920000144))
    return
  end
  local channel = Data.chatData:GetChatChannel()
  local curLv = Data.userData:GetUserLevel()
  local limitLv
  if channel == ChatChannel.WorldBase then
    limitLv = configManager.GetDataById("config_parameter", 45).value
    if curLv < limitLv then
      noticeManager:ShowTip(string.format(UIHelper.GetString(220006), limitLv))
      return
    end
  end
  local isCoolTime = Logic.chatLogic:IsCoolTime(channel)
  if isCoolTime then
    local time = Mathf.ToInt(Logic.chatLogic:GetAllowChatTime(channel))
    local str = string.format(UIHelper.GetString(920000145), ChatChannelStr[channel], time)
    noticeManager:ShowTip(str)
    return
  end
  if channel == ChatChannel.WorldBase then
    channel = 901
    local nowNum = Data.chatData:GetWorldSendNum()
    local numUp = Logic.chatLogic:GetWorldNumUp(curLv)
    if nowNum >= numUp then
      noticeManager:ShowTip(UIHelper.GetString(920000146))
      return
    end
  end
  if msg == nil then
    return
  end
  if msg == "" then
    noticeManager:ShowTip(UIHelper.GetString(920000147))
    return
  end
  msg = Logic.chatLogic:FilterMask(msg)
  return true, channel, msg
end

function PVERoomPage:RequireRandomFactors()
  local displayConfig = Logic.pveRoomLogic:GetPveCopyDisplay(self.copyId)
  if not table.empty(displayConfig.random_factor_sets) then
    Service.copyService:SendGetRandomFactors(displayConfig.id)
  end
end

function PVERoomPage:_GetRandFactorCallback(ret)
  self.tab_Widgets.obj_randFactor.gameObject:SetActive(#ret.Factors > 0)
  self.tab_Widgets.obj_rand.gameObject:SetActive(#ret.Factors > 0)
  local displayConfig = Logic.pveRoomLogic:GetPveCopyDisplay(self.copyId)
  Logic.copyLogic:SetRandFactors(displayConfig.id, ret)
  self.tab_Widgets.obj_randFactorSign:SetActive(ret.IsShowTips)
  local uid = Data.userData:GetUserUid()
  local needShow = true
  for _, factor in pairs(ret.Factors) do
    local setRec = configManager.GetDataById("config_random_factor_set", factor.SetId)
    if setRec.factor_skip == 0 and PlayerPrefs.GetInt(uid .. "factor" .. factor.SetId, 0) == 0 and needShow then
      self:_ShowFactorDetail()
      needShow = false
    end
    PlayerPrefs.SetInt(uid .. "factor" .. factor.SetId, 1)
  end
end

function PVERoomPage:_ShowFactorDetail()
  self.tab_Widgets.obj_randFactorSign:SetActive(false)
  local displayConfig = Logic.pveRoomLogic:GetPveCopyDisplay(self.copyId)
  UIHelper.OpenPage("RanFactorDetailsPage", {
    copyDisplayId = displayConfig.id
  })
end

function PVERoomPage:ShowSpeedMode()
  self.speedState = false
  self.tab_Widgets.obj_speedUp:SetActive(self.speedState)
  self.tab_Widgets.obj_noSpeedUp:SetActive(not self.speedState)
  local open = self:CheckSpeedModeOpen()
  self.tab_Widgets.btn_jiasu.gameObject:SetActive(open)
end

function PVERoomPage:ClickSpeedBtn()
  if not self.isOwner then
    local uid = Data.userData:GetUserUid()
    for _, v in pairs(self.roomInfoTab.RoomUsers) do
      if uid == v.Uid and v.IsReady then
        return
      end
    end
  end
  if Logic.pveRoomLogic:GetAutoCountingState() then
    return
  end
  if not self.speedState then
    local pvePtOwnNum = Data.userData:GetCurrency(CurrencyType.PVEPT)
    local multiple = configManager.GetDataById("config_parameter", 526).value
    if pvePtOwnNum < multiple then
      noticeManager:OpenTipPage(self, 4800112)
    else
      self.speedState = true
    end
  else
    self.speedState = false
  end
  self.tab_Widgets.obj_speedUp:SetActive(self.speedState)
  self.tab_Widgets.obj_noSpeedUp:SetActive(not self.speedState)
end

function PVERoomPage:CheckSpeedModeOpen()
  local copyData = Data.copyData:GetCopyInfoById(self.copyId)
  if copyData.FirstPassTime <= 0 then
    return false
  end
  local periodId = configManager.GetDataById("config_parameter", 525).value
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(periodId)
  local now = time.getSvrTime()
  if startTime <= now and endTime >= now then
    return true
  end
  return false
end

function PVERoomPage:ShowNewUserTips(name)
  local str = string.format(UIHelper.GetString(4800105), name)
  noticeManager:ShowTip(str)
end

function PVERoomPage:ClickHelpBtn()
  UIHelper.OpenPage("HelpPage", {content = 6100022})
end

return PVERoomPage
