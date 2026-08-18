local LoginPage = class("UI.LoginPage", LuaUIPage)
local Socket_net = require("socket_net")
local json = require("cjson")
local LOGIN_KEY = "login_type"
local GM_URL = "https://clsyjp.blueoath.com/cservice.html"

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
  self.sdkLogining = false
  local showAgreement = platformManager:CheckZyxSDK()
  self.m_tabWidgets.btn_agreement.gameObject:SetActive(showAgreement)
  self.m_tabWidgets.btn_notice.gameObject:SetActive(BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW)
  self.m_tabWidgets.btn_delete.gameObject:SetActive(false)
  self.m_tabWidgets.btn_chooseLogin.gameObject:SetActive(not isWindows and BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW)
  self.m_tabWidgets.btn_saomiao.gameObject:SetActive(false)
  self.m_tabWidgets.btn_cs.gameObject:SetActive(BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW)
end

function LoginPage:DoOnOpen()
  self.clickEnter = false
  self.openServerPage = false
  self.useSDK = platformManager:useSDK()
  self.m_tabWidgets.txt_ServerName.text = UIHelper.GetString(920000263)
  self.m_tabWidgets.obj_Account:SetActive(not self.useSDK)
  self.m_tabWidgets.obj_SDKLogin:SetActive(self.useSDK)
  if self.useSDK then
    local doLogin = true
    if platformManager:GetAnnounceState(AnnouncementType.Base) then
      self:_OpenAnnouncePage()
      if isWindows then
        doLogin = false
        self.openNotLogin = true
      end
    end
    self.loginType = PlayerPrefs.GetInt(LOGIN_KEY, 0)
    self:_ShowSDKLoginButton(self.loginType == 0)
    if doLogin then
      if isWindows then
        self:_SDKInterface()
      elseif self.loginType > 0 or BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW then
        self:_SDKInterface()
      end
    end
  else
    local serverId = PlayerPrefs.GetString("serverIp")
    if serverId ~= "" then
      self.m_tabWidgets.txt_address.text = serverId
    end
    self.userId = PlayerPrefs.GetString("userId")
    if self.userId == "" then
      self.m_tabWidgets.txt_id.text = UIHelper.GetString(920000264)
    else
      self.m_tabWidgets.txt_id.text = self.userId
      self.m_tabWidgets.input_id.text = self.userId
    end
  end
  Logic.loginLogic:SetOptOff(false)
  local androidShow = false
  if isAndroid then
    local packageVersion = HotPatchFacade.PackageVersion
    local verTab = string.split(packageVersion, ".")
    local totalNum = 0
    for i = 1, #verTab do
      local num = tonumber(verTab[i])
      if num then
        totalNum = totalNum + num * 100000 ^ (3 - i)
      end
    end
    androidShow = 1.000000006E10 <= totalNum
  end
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
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_devLogin, function()
    self:_ClickLogin(LoginType.Device)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_chooseLogin, function()
    self:_ClickLogin(LoginType.Authorization)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_saomiao, function()
    platformManager:ShowScanCode()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cs, function()
    platformManager:OpenURL(GM_URL)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_agreement, self._OpenUserAgreement, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_notice, self._OpenAnnouncePage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_delete, self._DeleteAccount, self)
  self:RegisterEvent(LuaEvent.ChangeServer, self._ChangeServer, self)
  self:RegisterEvent(LuaEvent.LoginOk, self._LoginOk, self)
  self:RegisterEvent(LuaEvent.LoginError, self._LoginError, self)
  self:RegisterEvent(LuaEvent.DisconnectServer, self._LoginError, self)
  self:RegisterEvent(LuaEvent.ServerPageClose, self._ServerPageClose, self)
  self:RegisterEvent(LuaEvent.GetHashFail, self._GetHashFail, self)
  self:RegisterEvent(LuaEvent.SDKLogOut, self._LogOutCallBack, self)
  self:RegisterEvent(LuaEvent.IsCloseHomeGirl, self._CloseCustomWebView, self)
  self:RegisterEvent(LuaCSharpEvent.LoseFocus, self._OnFocusOn, self)
end

function LoginPage:_ShowSDKLoginButton(show)
  self.m_tabWidgets.btn_devLogin.gameObject:SetActive(show)
  self.m_tabWidgets.btn_chooseLogin.gameObject:SetActive(show and not isWindows and BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW)
end

function LoginPage:_ServerPageClose()
  self.openServerPage = false
end

function LoginPage:_CloseCustomWebView(isOpen)
  if not isOpen and isWindows and self.openNotLogin then
    self.openNotLogin = false
    self:_SDKInterface()
  end
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
  self.sdkLogining = false
  if ret then
    local userType = ret.userType and ret.userType or ""
    self.loginType = string.lower(userType) == "loginwayguest" and LoginType.Device or self.loginType
    self:_SaveLoginType(self.loginType)
    self.sdkLoginOk = true
    self:_ShowSDKLoginButton(false)
    self:_CheckRealName(false)
    local appReview = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW
    self.m_tabWidgets.btn_saomiao.gameObject:SetActive(not appReview and not isWindows)
    self:_SDKInterface()
  else
    self.loginType = 0
    self:_SaveLoginType(self.loginType)
    self:_ShowSDKLoginButton(true)
  end
end

function LoginPage:_SaveLoginType(value)
  if value == LoginType.AccountInherit then
    value = LoginType.Device
  end
  PlayerPrefs.SetInt(LOGIN_KEY, value)
  PlayerPrefs.Save()
end

function LoginPage:_OpenAnnouncePage()
  if isWindows then
    platformManager:getSuperNoticeAndOpen("base", 1000, 532, -1, -1, nil, nil, UIHelper.GetString(920000265))
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

function LoginPage:_DeleteAccount()
  local param = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        local ret = platformManager:DeleteGustAccount()
        local result = json.decode(ret)
        if result.errornu == "0" then
          platformManager:logout(function()
          end)
          self:_LogOutCallBack()
          platformManager:RefreshUUid()
        elseif result.errornu == "1" then
          noticeManager:ShowTip(UIHelper.GetString(101025))
        end
      end
    end
  }
  noticeManager:ShowMsgBox(101024, param)
end

function LoginPage:_CheckRealName(isEnter)
  platformManager:getRealNameState(function(ret)
    if ret and ret.data then
      local erealName = isEnter and (ret.data.idcardStatus == 1 or ret.data.OnNoRealnameLogin ~= 20)
      local lrealName = not isEnter and (ret.data.idcardStatus == 1 or ret.data.OnNoRealnameLogin == 0)
      if erealName or lrealName then
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
    elseif self.recomendServer then
      self:_ShowServerInfo(self.recomendServer)
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
    self.recomendServer = server
  end
  self:_SDKInterface()
end

function LoginPage:_OnServerSelect(nIndex)
  if self.loginOver or self.clickEnter then
    return
  end
  if self.dontHaveServer then
    noticeManager:ShowMsgBox(UIHelper.GetString(920000266))
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
  self.loginType = 0
  self:_SaveLoginType(self.loginType)
  self:_ShowSDKLoginButton(self.loginType == 0)
  self.m_tabWidgets.txt_ServerName.text = UIHelper.GetString(920000263)
  self.tab_Widgets.objStateHot:SetActive(false)
  self.tab_Widgets.objStateFluent:SetActive(false)
  self.tab_Widgets.objStateMaintain:SetActive(false)
  self.m_tabWidgets.btn_delete.gameObject:SetActive(false)
  self.m_tabWidgets.btn_saomiao.gameObject:SetActive(false)
  if BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW then
    self:_SDKInterface()
  end
end

function LoginPage:_ChangeSdkAccount()
  if self.loginOver or self.clickEnter then
    return
  end
  if platformManager:loginSuccess() then
    local param = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          platformManager:logout(function()
            if BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW then
              local _param
              if isWindows then
                _param = {
                  callback = function()
                    self:_ClickLogin(LoginType.Device)
                  end
                }
              end
              noticeManager:ShowMsgBox(UIHelper.GetString(920000734), _param)
            end
            self:_LogOutCallBack()
          end)
        end
      end
    }
    local l_id = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW and 101024 or 920000735
    noticeManager:ShowMsgBox(l_id, param)
  end
end

function LoginPage:_OpenUserAgreement()
  platformManager:OpenUserAgreement()
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
  self.sdkLogining = true
  if BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW then
    self.loginType = 0
  end
  platformManager:login(self.loginType, function(ret)
    self:_SdkLoginSuccess(ret)
  end)
end

function LoginPage:_ClickLogin(loginType)
  if self.sdkLogining then
    return
  end
  if not self.loginType or self.loginType <= 0 then
    self.loginType = loginType
  end
  self:_InitSDKSocket()
end

function LoginPage:_InitSDKSocket()
  if self.loginOver or self.clickEnter or self.openServerPage then
    return
  end
  if self.dontHaveServer then
    self.clickEnter = false
    noticeManager:ShowMsgBox(UIHelper.GetString(920000266))
  end
  if self:_SDKOK() then
    if self.selectServer == nil then
      noticeManager:ShowTip(UIHelper.GetString(920000263))
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
  if postType == UIHelper.GetString(920000267) then
    post = 30006
  elseif postType == UIHelper.GetString(920000268) then
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
  if self.dontHaveServer then
    self.clickEnter = false
    noticeManager:ShowMsgBox(UIHelper.GetString(920000266))
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
