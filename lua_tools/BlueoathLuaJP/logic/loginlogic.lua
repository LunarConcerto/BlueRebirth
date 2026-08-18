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
  eventManager:RegisterEvent(LuaCSharpEvent.InitLocalChat, self._InitSetButton, self)
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
    noticeManager:ShowMsgBox(UIHelper.GetString(920000066), nil, UILayer.NETWORK)
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
    noticeManager:ShowMsgBox(UIHelper.GetString(920000066), nil, UILayer.NETWORK)
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
  msg.AreaInfo = platformManager:GetTimeZoneID()
  msg.DeviceModel = SystemInfo.deviceModel
  msg.GraphicsDevice = SystemInfo.graphicsDeviceName
  msg.DeviceName = SystemInfo.deviceName
  msg.ProcessorType = SystemInfo.processorType
  msg.ProcessorCount = SystemInfo.processorCount
  msg.ProcessorFrequency = SystemInfo.processorFrequency
  msg.GraphicsDeviceType = tostring(SystemInfo.graphicsDeviceType)
  msg.SystemMemorySize = SystemInfo.systemMemorySize
  msg.GraphicsMemorySize = SystemInfo.graphicsMemorySize
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
        noticeManager:ShowMsgBox(UIHelper.GetString(920000067), nil, UILayer.NETWORK)
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
  self.isNewCreate = true
  PlayerPrefs.SetInt(msg.Uid .. "isNewCreateNum", 1)
  local arg = user_pb.TUserLoginArg()
  arg.Uid = msg.Uid
  Service.userService:UserLogin(arg)
  eventManager:UnregisterEvent(LuaEvent.CreaterCharacterSuccess, self._CreateSuccess)
end

function LoginLogic:_LoginOk()
  if self.isNewCreate and self.SDKInfo then
    local lastServer = platformManager:lastServer()
    local serverInfo = {}
    local serverId = Logic.loginLogic.SDKInfo.groupid
    for _, v in pairs(lastServer) do
      if v.groupid ~= serverId then
        serverInfo[v.groupid] = v.uname
      end
    end
    local roleInfo = {
      [serverId] = Data.userData:GetUserName()
    }
    local dotInfo = {role = roleInfo, all_role = serverInfo}
    RetentionHelper.Retention(PlatformDotType.createRole, dotInfo)
    self.isNewCreate = false
  end
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
  if self.SDKInfo then
    dotInfo = {
      info = self.SDKInfo.groupid
    }
    RetentionHelper.Retention(PlatformDotType.serverpick, dotInfo)
  end
  self.loginOk = true
  self.loginConnected = true
  platformManager:AddRemoteNotification()
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
  announcementManager:GetAnnouncementState()
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
      self.hashMsg.AreaInfo = platformManager:GetTimeZoneID()
      self.hashMsg.DeviceModel = SystemInfo.deviceModel
      self.hashMsg.GraphicsDevice = SystemInfo.graphicsDeviceName
      self.hashMsg.DeviceName = SystemInfo.deviceName
      self.hashMsg.ProcessorType = SystemInfo.processorType
      self.hashMsg.ProcessorCount = SystemInfo.processorCount
      self.hashMsg.ProcessorFrequency = SystemInfo.processorFrequency
      self.hashMsg.GraphicsDeviceType = tostring(SystemInfo.graphicsDeviceType)
      self.hashMsg.SystemMemorySize = SystemInfo.systemMemorySize
      self.hashMsg.GraphicsMemorySize = SystemInfo.graphicsMemorySize
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

function LoginLogic:_InitSetButton()
  local uid = Data.userData:GetUserData().Uid
  if self.loginOk == true and uid ~= nil then
    local isNewCreateNum = PlayerPrefs.GetInt(uid .. "isNewCreateNum", 0)
    if isNewCreateNum == 1 then
      CacheUtil.SetSkipIsSkillAnimIndex(true, false)
      CacheUtil.SetSkipIsSkillAnimIndex(false, false)
      CacheUtil.SetSkipSkillAnimResul(false)
      CacheUtil.SetSkipEnemyTorpedoPlayAnim(false)
      PlayerPrefs.SetInt(uid .. "isNewCreateNum", 10000)
    end
  else
    logError("\231\153\187\233\153\134\229\164\177\232\180\165")
  end
end

return LoginLogic
