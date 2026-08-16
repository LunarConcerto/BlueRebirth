local LoginLogic = class("logic.LoginLogic")
local Socket_net = require("socket_net")
local json = require("cjson")

function LoginLogic:initialize()
  self.bAutoSound = true
  self.bAutoGame = true
  self.bAutoCharacter = true
  self:RegisterAllEvent()
  self:ResetData()
end

function LoginLogic:ResetData()
  self.bAutoSound = true
  self.bAutoGame = true
  self.bAutoCharacter = true
  self.SDKInfo = nil
  self.SDKHashMsg = nil
  self.hashMsg = nil
  self.userOptOff = false
  LoginLogic.userKick = false
  LoginLogic.kickType = 104
  self.Relink = 0
  self.mTimer = nil
  self.loginOk = false
  self.loginConnected = false
end

function LoginLogic:SetOptOff(tog)
  self.userOptOff = tog
end

function LoginLogic:GetOptOff()
  return self.userOptOff
end

function LoginLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.ConnectServer, self._ConnectOk, self)
  eventManager:RegisterEvent(LuaEvent.LoginOk, self._LoginOk, self)
  eventManager:RegisterEvent(LuaEvent.GetUserList, self._GetUserList, self)
  eventManager:RegisterEvent(LuaEvent.DisconnectServer, self._DisconnectServer, self)
end

function LoginLogic:SetSDKInfo(info)
  local key = tostring(platformManager.pid) .. "server"
  PlayerPrefs.SetString(key, info.groupid)
  PlayerPrefs.Save()
  self.SDKInfo = info
end

function LoginLogic:GetCacheServerId()
  local key = tostring(platformManager.pid) .. "server"
  local groupid = PlayerPrefs.GetString(key, "")
  return groupid
end

function LoginLogic:GetCacheServerInfo()
  local groupid = self:GetCacheServerId()
  local info
  if groupid ~= "" then
    info = platformManager:getServiceInfoById(groupid)
  end
  return info
end

function LoginLogic:SetSDKHashMsg(hash)
  self.hashMsg = hash
end

function LoginLogic:_Reconnect()
  local useSDK = platformManager:useSDK()
  self.Relink = 1
  if useSDK then
    self:CheckUpdate()
  else
    local serverIp = PlayerPrefs.GetString("serverIp")
    local post = PlayerPrefs.GetString("post")
    Socket_net.ConnectImp(serverIp, post)
  end
end

function LoginLogic:CheckUpdate()
  if BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW then
    self:_HasUpdate(false)
  elseif platformManager:CheckNetState() then
    HotPatchFacade.HasUpdate(function(bool)
      self:_HasUpdate(bool)
    end)
    self:_StartCheckTimer()
  elseif self.loginOk then
    eventManager:SendEvent(LuaEvent.ReconnectNetworkExc)
  else
    noticeManager:ShowMsgBox("\231\189\145\231\187\156\228\184\141\229\143\175\231\148\168", nil, UILayer.NETWORK)
  end
end

function LoginLogic:_StartCheckTimer()
  if self.mTimer == nil then
    self.mTimer = Timer.New(function()
      self:_CheckUpdateOvertime()
    end, 10, 1, false)
  end
  eventManager:FireEventToCSharp(LuaCSharpEvent.OnWaitBegin)
  self.mTimer:Start()
end

function LoginLogic:_StopCheckTimer()
  if self.mTimer ~= nil then
    eventManager:FireEventToCSharp(LuaCSharpEvent.OnWaitEnd)
    self.mTimer:Stop()
  end
  self.mTimer = nil
end

function LoginLogic:_CheckUpdateOvertime()
  self:_StopCheckTimer()
  HotPatchFacade.ClearCheckUpdate()
  eventManager:SendEvent(LuaEvent.GetHashFail)
  self:_HotUpdateCallBack(false)
end

function LoginLogic:_HasUpdate(param)
  self:_StopCheckTimer()
  if param then
    self:_HotUpdateCallBack(true)
  elseif platformManager:loginSuccess() then
    self:GetSDKHash()
  end
end

function LoginLogic:_HotUpdateCallBack(hasUpdate)
  if hasUpdate then
    local str = UIHelper.GetString(420007)
    Logic.loginLogic:SetOptOff(true)
    UIHelper.SetUILock(false)
    local param = {
      callback = function(bool)
        if self.loginOk or hasUpdate then
          stageMgr:Goto(EStageType.eStageLaunch, nil, true)
        end
      end
    }
    noticeManager:ShowMsgBox(str, param, UILayer.NETWORK)
  elseif self.loginOk then
    eventManager:SendEvent(LuaEvent.ReconnectNetworkExc)
  else
    noticeManager:ShowMsgBox("\231\189\145\231\187\156\228\184\141\229\143\175\231\148\168", nil, UILayer.NETWORK)
  end
end

function LoginLogic:_ConnectOk()
  local useSDK = platformManager:useSDK()
  if useSDK then
    Service.userService:SendLogin(self.hashMsg)
    return
  end
  local userId = PlayerPrefs.GetString("userId")
  self:_Login(userId)
end

function LoginLogic:_DisconnectServer()
  self.loginConnected = false
end

function LoginLogic:_Login(pid)
  local msg = player_pb.TArgLogin()
  msg.Pid = pid
  msg.Relink = self.Relink
  msg.ChatRoom = Data.chatData:GetRoomNum()
  msg.ClientVersion = platformManager:GetPatchVersion()
  Service.userService:SendLogin(msg)
end

function LoginLogic:GetAutoSoundInfo()
  return self.bAutoSound
end

function LoginLogic:SetAutoSoundInfo(isAuto)
  self.bAutoSound = isAuto
end

function LoginLogic:GetAutoGameInfo()
  return self.bAutoGame
end

function LoginLogic:SetAutoGameInfo(isAuto)
  self.bAutoGame = isAuto
end

function LoginLogic:GetAutoCharacterInfo()
  return self.bAutoCharacter
end

function LoginLogic:SetAutoCharacterInfo(isAuto)
  self.bAutoCharacter = isAuto
end

function LoginLogic:_GetUserList(msg)
  local userListSize = #msg.ArrUser
  if userListSize == 0 then
    if platformManager:useSDK() then
      local hash = platformManager:getHashValue()
      if hash and hash.canCreateUser == 0 then
        UIHelper.SetUILock(false)
        noticeManager:ShowMsgBox("\228\186\178\231\136\177\231\154\132\230\140\135\230\140\165\229\174\152\239\188\140\230\154\130\230\151\182\232\191\152\228\184\141\232\131\189\229\136\155\229\187\186\231\148\168\230\136\183\229\147\159~\232\175\183\230\130\168\231\168\141\229\144\142\229\134\141\230\157\165~", nil, UILayer.NETWORK)
        return
      end
    end
    eventManager:RegisterEvent(LuaEvent.CreaterCharacterSuccess, self._CreateSuccess, self)
    local msg = player_pb.TArgCreateUser()
    msg.Uname = "test1"
    msg.Class = 1
    Service.userService:CreateUser(msg)
    return
  end
  local arg = user_pb.TUserLoginArg()
  arg.Uid = msg.ArrUser[1].Uid
  Service.userService:UserLogin(arg)
end

function LoginLogic:_CreateSuccess(msg)
  local arg = user_pb.TUserLoginArg()
  arg.Uid = msg.Uid
  Service.userService:UserLogin(arg)
  eventManager:UnregisterEvent(LuaEvent.CreaterCharacterSuccess, self._CreateSuccess)
end

function LoginLogic:_LoginOk()
  local seacopyId = Data.copyData:GetFarestSeaCopyId()
  local plotcopyId = Data.copyData:GetFarestPlotCopyId()
  local dailyMax = Logic.dailyCopyLogic:GetDailyCopyInfo()
  local towerInfo = Data.towerData:GetTowerDetail()
  local dotInfo = {
    info = "ui_user_login",
    plot_max = plotcopyId,
    sea_max = seacopyId,
    daily_max = dailyMax,
    tower_info = towerInfo
  }
  local chapterTypeConfig = configManager.GetData("config_chapter_type")
  for key, config in pairs(chapterTypeConfig) do
    if config.dot_key ~= "" then
      dotInfo[config.dot_key] = Data.copyData:GetFarestCopyId(key)
    end
  end
  RetentionHelper.Retention(PlatformDotType.copyMaxLog, dotInfo)
  self.loginOk = true
  self.loginConnected = true
  announcementManager:GetAnnouncementState()
  platformManager:CheckUserExtraFunctionState()
  UIHelper.SetUILock(false)
  collectgarbage("collect")
  eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, false)
end

function LoginLogic:SetUserKick(type)
  if LoginLogic.userKick then
    return
  end
  LoginLogic.userKick = true
  LoginLogic.kickType = type
  eventManager:SendEvent(LuaEvent.UserKick)
  Socket_net.Disconnect()
end

function LoginLogic:CheckUserKick()
  return LoginLogic.userKick
end

function LoginLogic:GetUserKickType()
  return LoginLogic.kickType
end

function LoginLogic:GetSDKHash()
  local param = {
    callback = function(bool)
      if self.loginOk then
        excMgr:_ClickClose()
      end
    end
  }
  platformManager:getSDKHash(self.SDKInfo.groupid, function(ret)
    if not ret or ret.errornu ~= "0" then
      UIHelper.SetUILock(false)
      eventManager:SendEvent(LuaEvent.GetHashFail)
    end
    if ret == nil then
      noticeManager:ShowMsgBox(UIHelper.GetString(420008), param, UILayer.NETWORK)
    elseif ret.errornu == "0" then
      self.SDKHashMsg = ret
      local hash = json.encode(ret)
      self.hashMsg = player_pb.TArgLogin()
      self.hashMsg.Pid = ret.pid
      self.hashMsg.Hash = hash
      self.hashMsg.Relink = self.Relink
      self.hashMsg.ChatRoom = Data.chatData:GetRoomNum()
      self.hashMsg.ClientVersion = platformManager:GetPatchVersion()
      Logic.loginLogic:SetSDKHashMsg(self.hashMsg)
      platformManager:getBrowseActive(function(ret)
        if ret then
          Logic.homeLogic:SetBrowseActiveInfo()
        end
      end)
      if Socket.curState == SocketConnState.Connected then
        Service.userService:SendLogin(self.hashMsg)
      else
        Socket_net.ConnectImp(self.SDKInfo.host, self.SDKInfo.port)
      end
    elseif ret.errornu == "101" then
      noticeManager:ShowMsgBox(UIHelper.GetString(420008), param, UILayer.NETWORK)
    elseif ret.errornu == "102" then
      noticeManager:ShowMsgBox(UIHelper.GetString(420009), param, UILayer.NETWORK)
    elseif ret.errornu == "103" then
      noticeManager:ShowMsgBox(UIHelper.GetString(420010), param, UILayer.NETWORK)
    elseif ret.errornu == "104" then
      logError(ret.notice)
      if ret.notice then
        noticeManager:ShowMsgBox(ret.notice, param, UILayer.NETWORK)
      else
        local notice = platformManager:getAllServiceNotic()
        logError(printTable(notice))
        if notice.open == 1 then
          noticeManager:ShowMsgBox(notice.desc, param, UILayer.NETWORK)
        else
          noticeManager:ShowMsgBox(UIHelper.GetString(420011), param, UILayer.NETWORK)
        end
      end
    elseif ret.errornu == "105" then
      noticeManager:ShowMsgBox(UIHelper.GetString(420012), param, UILayer.NETWORK)
    elseif ret.errornu == "-1" then
      if self.Relink == 0 then
        noticeManager:ShowMsgBox(UIHelper.GetString(420013), param, UILayer.NETWORK)
      else
        eventManager:SendEvent(LuaEvent.ReconnectNetworkExc)
      end
    else
      noticeManager:ShowMsgBox(ret.errordesc, param, UILayer.NETWORK)
    end
  end)
end

function LoginLogic:GetLoginState()
  return self.loginConnected
end

function LoginLogic:GetLoginOK()
  if self.loginOk == nil then
    return 0
  else
    return self.loginOk
  end
end

return LoginLogic
