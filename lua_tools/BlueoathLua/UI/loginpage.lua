local LoginPage = class("UI.LoginPage", LuaUIPage)
local Socket_net = require("socket_net")
local json = require("cjson")
local USER_TREATY_KEY = "user_treaty"
local USER_TREATY_VERSION_KEY = "treaty_version"

function LoginPage:DoInit()
  self.userId = ""
  self.Server = nil
  Socket_net.Init()
  BattleLauncher:Init()
  self.tblServer = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.sdkLoginOk = false
  self.serverListOk = false
  self.lastServerOk = false
  self.zyxSdk = platformManager:CheckZyxSDK()
  self.agreementType = 2
  if self.zyxSdk then
    local packageVersion = HotPatchFacade.PackageVersion
    if packageVersion == "1.2.0" then
      self.agreementType = 1
    else
      self.agreementType = 2
    end
  end
  self.m_tabWidgets.btn_agreement:SetActive(self.agreementType == 1)
  self.m_tabWidgets.obj_usertreaty:SetActive(self.agreementType == 2)
end

function LoginPage:DoOnOpen()
  self.clickEnter = false
  self.openServerPage = false
  self.useSDK = platformManager:useSDK()
  self.m_tabWidgets.txt_ServerName.text = "\232\175\183\233\128\137\230\139\169\230\156\141\229\138\161\229\153\168"
  self.m_tabWidgets.obj_Account:SetActive(not self.useSDK)
  self.m_tabWidgets.obj_SDKLogin:SetActive(self.useSDK)
  if self.useSDK then
    if platformManager:GetAnnounceState(AnnouncementType.Base) then
      self:_OpenAnnouncePage()
    end
    self:_SDKInterface()
  else
    local serverId = PlayerPrefs.GetString("serverIp")
    if serverId ~= "" then
      self.m_tabWidgets.txt_address.text = serverId
    end
    self.userId = PlayerPrefs.GetString("userId")
    if self.userId == "" then
      self.m_tabWidgets.txt_id.text = "\232\175\183\232\190\147\229\133\165\229\184\144\229\143\183"
    else
      self.m_tabWidgets.txt_id.text = self.userId
      self.m_tabWidgets.input_id.text = self.userId
    end
  end
  Logic.loginLogic:SetOptOff(false)
  self:_PlayVideo()
end

function LoginPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_start, function()
    self:_InitSocket()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Enter, function()
    self:_InitSDKSocket()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_server, function()
    self:_OnServerSelect()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ChangeAccount, function()
    self:_ChangeSdkAccount()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_agreement, self._OpenUserAgreement, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_notice, self._OpenAnnouncePage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_user, self._OpenNewUserAgreement, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_treaty, self._OpenUserTreaty, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_checkmark, function(go, isOn)
    self.isUserTreatyOn = isOn
    self:_SaveUserTreatyState(isOn)
  end)
  self:RegisterEvent(LuaEvent.ChangeServer, self._ChangeServer, self)
  self:RegisterEvent(LuaEvent.LoginOk, self._LoginOk, self)
  self:RegisterEvent(LuaEvent.LoginError, self._LoginError, self)
  self:RegisterEvent(LuaEvent.DisconnectServer, self._LoginError, self)
  self:RegisterEvent(LuaEvent.ServerPageClose, self._ServerPageClose, self)
  self:RegisterEvent(LuaEvent.GetHashFail, self._GetHashFail, self)
  self:RegisterEvent(LuaEvent.SDKLogOut, self._LogOutCallBack, self)
  self:RegisterEvent(LuaCSharpEvent.LoseFocus, self._OnFocusOn, self)
end

function LoginPage:_ServerPageClose()
  if self.agreementType == 2 and not self.isUserTreatyOn then
    noticeManager:OpenTipPage(self, 920000001)
  end
  self.openServerPage = false
end

function LoginPage:_LoginOk()
  self.loginOver = true
end

function LoginPage:_LoginError()
  self.clickEnter = false
  self.loginOver = false
end

function LoginPage:_PlayVideo()
  local videoPath = "movie/cg/logincg.mp4"
  local videoDisplay = self.m_tabWidgets.mediaDisplay
  self.objVideoPlayProcess = UIHelper.InitAndPlayVideo(videoPath, videoDisplay)
  UIHelper.SetVideoLoop(self.objVideoPlayProcess, true)
end

function LoginPage:_OnFocusOn()
  if IsNil(self.objVideoPlayProcess) then
    return
  end
  local bPause = UIHelper.IsVideoPause(self.objVideoPlayProcess)
  if bPause then
    UIHelper.ContinueVideo(self.objVideoPlayProcess)
  end
end

function LoginPage:_SdkLoginSuccess(ret)
  if ret then
    if self.zyxSdk then
      self:_SetUserTreatyState(ret.protocolStatus)
    else
      platformManager:CheckUserAgreementVersion(function(ret)
        if ret then
          self.otherplAgree = ret.data
          self:_OpenOtherPlAgreement()
        end
      end)
    end
    self.sdkLoginOk = true
    self:_CheckRealName(false)
    self:_SDKInterface()
  end
end

function LoginPage:_SetUserTreatyState(status)
  if isEditor and not status then
    local pid = platformManager:GetUserPid()
    if pid then
      local key = pid .. USER_TREATY_KEY
      local on = PlayerPrefs.GetInt(key, 0)
      self.tab_Widgets.tog_checkmark.isOn = on ~= 0
    end
  end
  if status == "0" then
    local pid = platformManager:GetUserPid()
    if pid then
      local key = pid .. USER_TREATY_KEY
      local on = PlayerPrefs.GetInt(key, 0)
      self.tab_Widgets.tog_checkmark.isOn = on ~= 0
    end
  elseif status == "1" then
    self.tab_Widgets.tog_checkmark.isOn = false
    self:_SaveUserTreatyState(false)
  elseif status == "2" then
    self.tab_Widgets.tog_checkmark.isOn = true
    self:_SaveUserTreatyState(true)
  end
  self.isUserTreatyOn = self.tab_Widgets.tog_checkmark.isOn
end

function LoginPage:_SaveUserTreatyState(isOn)
  local pid = platformManager:GetUserPid()
  if pid then
    local key = pid .. USER_TREATY_KEY
    local value = isOn and 1 or 0
    PlayerPrefs.SetInt(key, value)
    PlayerPrefs.Save()
  end
end

function LoginPage:_OpenAnnouncePage()
  if isWindows then
    platformManager:getSuperNoticeAndOpen("base", 1000, 532, -1, -1, nil, nil, "\231\179\187\231\187\159\229\133\172\229\145\138")
  else
    platformManager:getSuperNoticeTpl("base", nil, function(ret)
      if ret then
        local param = {
          aType = AnnouncementType.Base
        }
        UIHelper.OpenPage("AnnouncementPage", param, 5)
      end
    end)
  end
end

function LoginPage:_CheckRealName(isEnter)
  platformManager:getRealNameState(function(ret)
    if ret and ret.data then
      local erealName = isEnter and (ret.data.idcardStatus == 1 or ret.data.OnNoRealnameLogin ~= 20)
      local lrealName = not isEnter and (ret.data.idcardStatus == 1 or ret.data.OnNoRealnameLogin == 0)
      if ret.data.isFastUser == 1 then
        if isEnter then
          self:OnSDKEnterGame()
        end
      elseif erealName or lrealName then
        if isEnter then
          self:OnSDKEnterGame()
        end
      else
        self:_GoToRealName()
      end
    else
      self.clickEnter = false
    end
  end)
end

function LoginPage:_GoToRealName()
  self.clickEnter = false
  local param = {
    callback = function(bool)
      platformManager:enterUserCenter()
    end
  }
  noticeManager:ShowMsgBox(700001, param)
end

function LoginPage:_ChangeServer(serverInfo)
  self.selectServer = serverInfo
  self:_ShowServerInfo(serverInfo)
end

function LoginPage:_ShowServerInfo(serverInfo)
  if serverInfo == nil then
    return
  end
  self.m_tabWidgets.txt_ServerName.text = serverInfo.name
  local data = serverInfo.Data
  local isHot = false
  local isFluent = false
  local isMaintenance = false
  if data.status == 1 then
    if data.hot > 0 then
      isHot = true
    else
      isFluent = true
    end
  else
    isMaintenance = true
  end
  self.tab_Widgets.objStateHot:SetActive(isHot)
  self.tab_Widgets.objStateFluent:SetActive(isFluent)
  self.tab_Widgets.objStateMaintain:SetActive(isMaintenance)
end

function LoginPage:_GetLastServiceListSuccess(ret)
  if ret then
    if self.dontHaveServer then
      logError("\232\142\183\229\143\150\230\156\128\232\191\145\230\156\141\229\138\161\229\153\168\229\136\151\232\161\168\229\155\158\232\176\131\239\188\140\230\178\161\230\156\137\230\156\141\229\138\161\229\153\168")
      return
    end
    self.lastServerOk = true
    if 0 < #ret then
      local lastServerIndex = 0
      for i = 1, #ret do
        local id = ret[i].groupid
        local s = platformManager:getServiceInfoById(id)
        if s then
          lastServerIndex = i
          break
        end
      end
      if 0 < lastServerIndex then
        local id = ret[lastServerIndex].groupid
        self.selectServer = platformManager:getServiceInfoById(id)
      else
        local s = Logic.loginLogic:GetCacheServerInfo()
        if s then
          self.selectServer = s
        else
          self.selectServer = platformManager:GetRecommendServer()
        end
      end
    else
      local s = Logic.loginLogic:GetCacheServerInfo()
      if s then
        self.selectServer = s
      else
        self.selectServer = platformManager:GetRecommendServer()
      end
    end
    if self.selectServer then
      self:_ShowServerInfo(self.selectServer)
    end
  end
end

function LoginPage:_SDKGetServerListCallBack(ret)
  if ret.errornu == "203" then
    self.dontHaveServer = true
  else
    self.dontHaveServer = false
  end
  if ret.errornu ~= "0" then
    return
  end
  local serverList = platformManager:getServiceList()
  self.serverListOk = true
  if serverList ~= nil and 0 < #serverList then
    local server = platformManager:GetRecommendServer()
    self:_ShowServerInfo(server)
  end
  self:_SDKInterface()
end

function LoginPage:_OnServerSelect(nIndex)
  if self.loginOver or self.clickEnter then
    return
  end
  if self.dontHaveServer then
    noticeManager:ShowMsgBox("\228\186\178\231\136\177\231\154\132\230\140\135\230\140\165\229\174\152\239\188\140\232\191\152\230\178\161\230\156\137\229\136\176\229\188\128\230\156\141\230\151\182\233\151\180\229\147\166,\232\175\183\232\128\144\229\191\131\231\173\137\229\190\133\229\147\159~")
  end
  if self:_SDKOK() then
    self.openServerPage = true
    UIHelper.OpenPage("ServerPage")
  else
    self:_SDKInterface()
  end
end

function LoginPage:_LogOutCallBack()
  self.serverListOk = false
  self.sdkLoginOk = false
  self.lastServerOk = false
  self.tab_Widgets.tog_checkmark.isOn = false
  self.isUserTreatyOn = false
  self:_SDKInterface()
end

function LoginPage:_ChangeSdkAccount()
  if self.loginOver or self.clickEnter then
    return
  end
  if platformManager:loginSuccess() then
    platformManager:logout(function()
      self:_LogOutCallBack()
    end)
  else
    self:_SDKInterface()
  end
end

function LoginPage:_OpenUserAgreement()
  platformManager:OpenUserAgreement()
end

function LoginPage:_OpenNewUserAgreement()
  if self.zyxSdk then
    platformManager:OpenNewUserAgreement()
  else
    local param = {
      aType = UserAgreementType.Agreement,
      url = self.otherplAgree.newUserAgree
    }
    UIHelper.OpenPage("AgreementPage", param)
  end
end

function LoginPage:_OpenUserTreaty()
  if self.zyxSdk then
    platformManager:OpenUserTreaty()
  else
    local param = {
      aType = UserAgreementType.Privacy,
      url = self.otherplAgree.newUserPrivacy
    }
    UIHelper.OpenPage("AgreementPage", param)
  end
end

function LoginPage:_OpenOtherPlAgreement()
  local pid = platformManager:GetUserPid()
  local pop = false
  if pid then
    local key = pid .. USER_TREATY_KEY
    local on = PlayerPrefs.GetInt(key, 0)
    if on == 0 then
      pop = true
    else
      local version = PlayerPrefs.GetString(USER_TREATY_VERSION_KEY, "")
      if version ~= self.otherplAgree.version then
        pop = true
      end
    end
    PlayerPrefs.SetString(USER_TREATY_VERSION_KEY, self.otherplAgree.version)
    self.tab_Widgets.tog_checkmark.isOn = not pop
    self.isUserTreatyOn = self.tab_Widgets.tog_checkmark.isOn
  end
  if pop then
    local param = {
      aType = UserAgreementType.AgreementAndPrivacy,
      url = self.otherplAgree.agreeUrl,
      callBack = function(ret)
        self:_SetUserTreatyState(ret)
      end
    }
    UIHelper.OpenPage("AgreementPage", param)
  end
end

function LoginPage:_SDKOK()
  return self.serverListOk and self.sdkLoginOk and self.lastServerOk
end

function LoginPage:_SDKInterface()
  if not self.sdkLoginOk then
    self:_SDKLogin()
  elseif self.dontHaveServer or not self.serverListOk then
    self:_SDKGetServerList()
  elseif not self.dontHaveServer and not self.lastServerOk and self.sdkLoginOk then
    self:_SDKGetLastServerList()
  end
end

function LoginPage:_SDKGetLastServerList()
  platformManager:getLastServiceList(function(result)
    self:_GetLastServiceListSuccess(result)
  end)
end

function LoginPage:_SDKGetServerList()
  platformManager:getServiceListAndAllServiceNotic(function(serviceresult)
    if serviceresult then
      self:_SDKGetServerListCallBack(serviceresult)
    end
  end)
end

function LoginPage:_SDKLogin()
  platformManager:login(function(ret)
    self:_SdkLoginSuccess(ret)
  end)
end

function LoginPage:_InitSDKSocket()
  if self.loginOver or self.clickEnter or self.openServerPage then
    return
  end
  if self.dontHaveServer then
    self.clickEnter = false
    noticeManager:ShowMsgBox("\228\186\178\231\136\177\231\154\132\230\140\135\230\140\165\229\174\152\239\188\140\232\191\152\230\178\161\230\156\137\229\136\176\229\188\128\230\156\141\230\151\182\233\151\180\229\147\166,\232\175\183\232\128\144\229\191\131\231\173\137\229\190\133\229\147\159~")
  end
  if self:_SDKOK() then
    if self.selectServer == nil then
      noticeManager:ShowTip("\232\175\183\233\128\137\230\139\169\230\156\141\229\138\161\229\153\168")
      return
    end
    self.clickEnter = true
    Logic.loginLogic:SetSDKInfo(self.selectServer)
    self:_CheckRealName(true)
  else
    self.clickEnter = false
    self:_SDKInterface()
  end
end

function LoginPage:_InitSocket()
  if self.loginOver or self.clickEnter then
    return
  end
  local inputIp = self.m_tabWidgets.input_address.text
  if inputIp == "" then
    local serverIp = PlayerPrefs.GetString("serverIp")
    if serverIp == "" then
      inputIp = "192.168.2.60"
      PlayerPrefs.SetString("serverIp", inputIp)
    else
      inputIp = serverIp
    end
  else
    PlayerPrefs.SetString("serverIp", inputIp)
  end
  local postType = self.m_tabWidgets.txt_Port.text
  local post = 30008
  if postType == "8\230\156\136\230\181\139\232\175\149\231\137\136" then
    post = 30006
  elseif postType == "\230\181\139\232\175\149\231\137\136" then
    post = 30014
  elseif postType == "40001" then
    post = 40001
  end
  PlayerPrefs.SetString("post", post)
  local inputId = self.m_tabWidgets.input_id.text
  if inputId == "" then
    if self.userId == "" then
      inputId = "198405"
      return
    else
      inputId = self.userId
    end
  else
    PlayerPrefs.SetString("userId", inputId)
  end
  Socket_net.ConnectImp(tostring(inputIp), post)
end

function LoginPage:OnSDKEnterGame()
  if self.agreementType == 2 and not self.isUserTreatyOn then
    self.clickEnter = false
    noticeManager:OpenTipPage(self, 920000001)
    return
  end
  if self.dontHaveServer then
    self.clickEnter = false
    noticeManager:ShowMsgBox("\228\186\178\231\136\177\231\154\132\230\140\135\230\140\165\229\174\152\239\188\140\232\191\152\230\178\161\230\156\137\229\136\176\229\188\128\230\156\141\230\151\182\233\151\180\229\147\166,\232\175\183\232\128\144\229\191\131\231\173\137\229\190\133\229\147\159~")
    return
  end
  Logic.loginLogic:CheckUpdate()
end

function LoginPage:_GetHashFail()
  self.clickEnter = false
end

function LoginPage:__CloseVideo()
  if not IsNil(self.objVideoPlayProcess) then
    UIHelper.DestroyVideoProcess(self.objVideoPlayProcess)
    self.objVideoPlayProcess = nil
  end
end

function LoginPage:DoOnHide()
  GR.sceneManager:HideCurScene()
  self:__CloseVideo()
end

function LoginPage:DoOnClose()
  GR.sceneManager:HideCurScene()
  PlayerPrefs.Save()
  UIHelper.ClosePage("AnnouncementPage")
  self:__CloseVideo()
end

return LoginPage
