local PlatformManager = class("util.PlatformManager")
local json = require("cjson")
local Socket_net = require("socket_net")

function PlatformManager:initialize()
  self.AllServiceNotic = nil
  self.ServiceList = nil
  self.pid = nil
  self.isLogined = false
  self.hashValue = nil
  self.isAdult = nil
  self.idcardStatus = nil
  PlatformWrapper:initialize()
end

function PlatformManager:getServiceListAndAllServiceNotic(funBackCall)
  PlatformWrapper:getServerList(function(result)
    if result == nil or result.errornu ~= "0" then
      funBackCall(result)
      return
    end
    self.AllServiceNotic = nil
    self.recommendServer = {}
    self.AllServiceNotic = result.root.notice
    self.ServiceList = {}
    self.ServiceListByGroup = {}
    local serviceItem
    for k, v in pairs(result.root.item) do
      serviceItem = {}
      serviceItem.Data = v
      serviceItem.name = v.name
      serviceItem.serviceIndex = v.serverIndex
      serviceItem.new = v.new
      serviceItem.groupid = v.groupid
      serviceItem.openTime = v.openDateTime
      serviceItem.status = v.status
      serviceItem.recommend = v.tj
      serviceItem.hot = v.hot
      serviceItem.host = v.host
      serviceItem.port = v.port
      if v.recommend_weight > 0 then
        table.insert(self.recommendServer, serviceItem)
      end
      table.insert(self.ServiceList, serviceItem)
      self.ServiceListByGroup[v.groupid] = serviceItem
    end
    table.sort(self.recommendServer, function(a, b)
      local da = a.Data
      local db = b.Data
      if da.recommend_weight ~= db.recommend_weight then
        return da.recommend_weight > db.recommend_weight
      end
      if da.serverIndex ~= db.serverIndex then
        return da.serverIndex < db.serverIndex
      end
      return false
    end)
    funBackCall(result)
  end)
end

function PlatformManager:GetRecommendServer()
  if #self.recommendServer > 0 then
    return self.recommendServer[1]
  end
  return nil
end

function PlatformManager:getSDKHash(serviceId, funBackCall)
  if self.isLogined then
    PlatformWrapper:getHash(serviceId, function(ret)
      self.hashValue = ret
      funBackCall(ret)
    end)
  end
end

function PlatformManager:retention(eventId, uid, defineStr)
  PlatformWrapper:retention(eventId, uid, defineStr)
end

function PlatformManager:login(funBackCall)
  PlatformWrapper:login(function(result)
    if result then
      self.isLogined = true
      self.pid = result.uid
      if not self:CheckZyxSDK() then
        self.isAdult = result.isAdult
        self.idcardStatus = result.idcardStatus
        self.isFastUser = result.isFastUser
        self.idcardInfo = result.idcardInfo
      end
    else
      self.isLogined = false
    end
    if funBackCall ~= nil then
      funBackCall(result)
    end
  end)
end

function PlatformManager:LogOutCallBack(ret)
  self.isLogined = false
  self.AllServiceNotic = nil
  self.ServiceList = nil
  self.pid = nil
  self.hashValue = nil
  if self._logoutCallBack ~= nil then
    self._logoutCallBack()
    self._logoutCallBack = nil
  elseif Logic.loginLogic.loginOk then
    Logic.loginLogic:SetOptOff(true)
    Socket_net.Disconnect()
    stageMgr:Goto(EStageType.eStageLaunch)
  else
    eventManager:SendEvent(LuaEvent.SDKLogOut, ret)
  end
end

function PlatformManager:logout(funBackCall)
  Socket_net.Disconnect()
  if not self:useSDK() then
    funBackCall()
    return
  end
  if self.isLogined then
    self._logoutCallBack = funBackCall
    PlatformWrapper:logout(function(ret)
      self.isLogined = false
      self.AllServiceNotic = nil
      self.ServiceList = nil
      self.pid = nil
      self.hashValue = nil
      funBackCall()
    end)
  end
end

function PlatformManager:getLastServiceList(funBackCall)
  if not self.pid then
    if funBackCall then
      funBackCall(nil)
    end
    return
  end
  PlatformWrapper:getLastServiceList(self.pid, function(result)
    if result == nil then
      if funBackCall then
        funBackCall(nil)
      end
      return
    end
    self.lastServiceList = result.root.role
    if funBackCall then
      funBackCall(self.lastServiceList)
    end
  end)
end

function PlatformManager:getRoleId()
  if self.hashValue then
    return self.hashValue.feignRoleId
  else
    return nil
  end
end

function PlatformManager:lastServer()
  return self.lastServiceList
end

function PlatformManager:showToolBar()
  PlatformWrapper:showToolBar()
end

function PlatformManager:hideToolBar()
  PlatformWrapper:hideToolBar()
end

function PlatformManager:sendUserInfo(type)
  local uId = Data.userData:GetUserUid()
  local uName = Data.userData:GetUserName()
  local level = Data.userData:GetUserLevel()
  local sName = ""
  local sId = ""
  local sInfo = Logic.loginLogic.SDKInfo
  if sInfo then
    sName = sInfo.name
    sId = sInfo.groupid
  end
  local vip = Data.userData:GetVipLevel()
  local balance = Data.userData:GetCurrency(CurrencyType.DIAMOND)
  local guild = "\230\151\160"
  local gender = "\230\151\160"
  local power = "1"
  local createTime = Data.userData:GetCreateTime()
  local userInfo = {
    Type = type,
    UID = tostring(uId),
    Uname = uName,
    Ulevel = tostring(level),
    ServerID = sId,
    ServerName = sName,
    RoleCreateTime = tostring(createTime),
    Balance = balance,
    VIP = vip,
    Guild = guild,
    Power = power,
    Gender = gender
  }
  PlatformWrapper:sendInformationToPlatform(userInfo)
end

function PlatformManager:sendUserInfoToMtp()
  local info = Logic.loginLogic.SDKInfo
  if info == nil then
    return
  end
  local pl = self:GetPL()
  local serverid = info.groupid
  local pid = self.pid
  local uid = Data.userData:GetUserUid()
  MtpManager.Login(pl, serverid, pid, uid)
end

function PlatformManager:isShowUserCenter()
  local ret = PlatformWrapper:isShowUserCenter()
  return ret
end

function PlatformManager:enterUserCenter()
  PlatformWrapper:enterUserCenter()
end

function PlatformManager:openCustomWebView(url, width, high, posX, posY, showCloseBtn, title, isExclusive, windowsIsShowBtn)
  local pl = self:GetPL()
  pl = string.lower(pl)
  if windowsIsShowBtn == nil then
    windowsIsShowBtn = true
  end
  showCloseBtn = isWindows and windowsIsShowBtn and 1 or showCloseBtn
  local web = {
    url = url,
    webW = width,
    webH = high,
    webPx = posX,
    webPy = posY,
    showCloseBtn = showCloseBtn,
    showBg = "0"
  }
  if title then
    web.title = title
  end
  if isExclusive then
    web.exclusive = "1"
  end
  PlatformWrapper:openCustomWebView(web, function(ret)
    if ret then
      if ret.sdkAction == "open" then
        if isWindows and not isEditor then
          eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, true)
          UIHelper.SetUILock(true)
        end
        ResolutionHandler.RegisteResolutionChangeEvent(self._CustomWebViewChange)
      elseif ret.sdkAction == "close" then
        if isWindows and not isEditor then
          eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, false)
          UIHelper.SetUILock(false)
        end
        eventManager:SendEvent(LuaEvent.CloseWebView)
        ResolutionHandler.UnRegisteResolutionChangeEvent(self._CustomWebViewChange)
      end
    end
    if ret and ret.answer ~= nil and ret.answer == "1" then
      local tab = Logic.homeLogic:GetAnswerQuestion()
      if tab == nil then
        tab = {}
      end
      local has = false
      for k, v in pairs(tab) do
        if v == ret.actid then
          has = true
          break
        end
      end
      if not has then
        table.insert(tab, ret.actid)
      end
      local param = Serialize(tab)
      Service.guideService:SendUserSetting({
        {
          Key = "sdk_question",
          Value = param
        }
      })
      Logic.homeLogic:QuestionAnswerOver(ret.actid)
    end
    eventManager:SendEvent(LuaEvent.SDKQuestionCallBack, ret)
  end)
end

function PlatformManager._CustomWebViewChange(width, height)
  eventManager:SendEvent(LuaEvent.ChangeWebViewSize, {w = width, h = height})
end

function PlatformManager:closeCustomWebView()
  PlatformWrapper:closeCustomWebView()
end

function PlatformManager:getSuperNoticeTpl(serviceId, width, funBackCall, category)
  category = category and category or 1
  local version = self:GetPatchVersion()
  local active = {
    returntype = "tpl",
    serverKey = serviceId,
    reserve01 = "1",
    reserve02 = "2",
    category = category,
    action = "get",
    version = version
  }
  if width then
    active.browser_width = width
  end
  PlatformWrapper:getSuperNotice(active, function(ret)
    if funBackCall ~= nil then
      funBackCall(ret)
    end
  end)
end

function PlatformManager:getSuperNoticeJson(serviceId, width, funBackCall, category)
  category = category and category or 1
  local version = self:GetPatchVersion()
  local active = {
    returntype = "json",
    serverKey = serviceId,
    reserve01 = "1",
    reserve02 = "2",
    category = category,
    action = "get",
    version = version
  }
  if width then
    active.browser_width = width
  end
  PlatformWrapper:getSuperNotice(active, function(ret)
    if funBackCall ~= nil then
      funBackCall(ret)
    end
  end)
end

function PlatformManager:getSuperNoticeAndOpen(serviceId, width, high, posX, posY, funBackCall, category, title)
  category = category and category or 1
  local version = self:GetPatchVersion()
  local active = {
    returntype = "tpl",
    serverKey = serviceId,
    browser_width = width,
    reserve01 = "1",
    reserve02 = "2",
    category = category,
    action = "get",
    version = version
  }
  PlatformWrapper:getSuperNotice(active, function(ret)
    platformManager:openCustomWebView(ret, width, high, posX, posY, "0", title)
    if funBackCall ~= nil then
      funBackCall()
    end
  end)
end

function PlatformManager:getBrowseActive(funBackCall)
  local value = self:getHashValue()
  if not value then
    return
  end
  local serverId = value.serverID
  serverId = string.sub(serverId, 5, string.len(serverId))
  local active = {
    reserve01 = "1",
    reserve02 = "1",
    getType = "1",
    serverKey = serverId
  }
  PlatformWrapper:getBrowseActive(active, function(ret)
    if ret == nil then
      funBackCall(nil)
      return
    end
    self.browseList = ret.noticear
    funBackCall(ret.noticear)
  end)
end

function PlatformManager:GetBrowseInfo()
  return self.browseList
end

function PlatformManager:GameAnnouncementState(funBackCall)
  local sInfo = Logic.loginLogic.SDKInfo
  local sId = ""
  if sInfo then
    sId = sInfo.groupid
  end
  local arg = {serverId = sId}
  PlatformWrapper:GameAnnouncementState(arg, funBackCall)
end

function PlatformManager:buyShopItem(shopId, gridId, buyNum, goodsId, pName)
  if isWindows and platformManager:GetOS() == "ios" then
    noticeManager:ShowMsgBox(430002)
    return
  end
  local goodsInfo = Logic.shopLogic:GetGoodsInfoById(goodsId)
  if goodsInfo ~= nil then
    local rechargeId = goodsInfo.recharge_id
    local info = configManager.GetDataById("config_recharge", rechargeId)
    if info then
      self:_BuyImp(function()
        local eData = tostring(shopId) .. "," .. tostring(goodsId) .. "," .. tostring(buyNum)
        self:getPay(info.id, pName, info.cost, info.paytype, pName, function(ret)
          if not ret then
            logError("\232\180\173\228\185\176\229\164\177\232\180\165")
          end
        end, eData)
      end)
    end
  end
end

function PlatformManager:_BuyImp(funBackCall)
  self:getRealNameState(function(ret)
    if ret and ret.data then
      if ret.data.idcardStatus == 1 then
        funBackCall()
      else
        self:_GoToRealName()
      end
    end
  end)
end

function PlatformManager:_GoToRealName()
  local tabParam = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        platformManager:enterUserCenter()
      end
    end
  }
  noticeManager:ShowMsgBox(430001, tabParam)
end

function PlatformManager:getPay(pId, pName, pPrice, payType, pDesc, funBackCall, extraData)
  local level = Data.userData:GetUserLevel()
  local uId = Data.userData:GetUserUid()
  local uName = Data.userData:GetUserName()
  local vip = Data.userData:GetVipLevel()
  local balance = Data.userData:GetCurrency(CurrencyType.DIAMOND)
  local sInfo = Logic.loginLogic.SDKInfo
  local sName = ""
  local sId = ""
  local cName = pName
  local eData = extraData and extraData or ""
  payType = 0 < payType and "04" or "00"
  pDesc = pDesc or ""
  if sInfo then
    sName = sInfo.name
    sId = sInfo.groupid
  end
  local param = {
    ProductId = tostring(pId),
    ProductName = pName,
    ProductPrice = tostring(pPrice),
    UID = tostring(uId),
    Uname = tostring(uName),
    Ulevel = tostring(level),
    ServerID = sId,
    ServerName = sName,
    Balance = tostring(balance),
    VIP = tostring(vip),
    Guild = "\230\151\160",
    PayType = payType,
    isVisitor = "0",
    ExtraData = eData,
    CurrencyName = cName,
    ProductDesc = pDesc,
    isAdult = self.isAdult and tostring(self.isAdult) or "",
    idcardStatus = self.idcardStatus and tostring(self.idcardStatus) or "",
    isFastUser = self.isFastUser and tostring(self.isFastUser) or "",
    idcardInfo = self.idcardInfo and self.idcardInfo or ""
  }
  PlatformWrapper:getPay(param, funBackCall)
end

function PlatformManager:GetFinallyQuestionnaire(content)
  local str = ""
  local param = self:GetQuestionnaire()
  if string.find(content, "?") then
    str = content .. "&" .. param
  else
    str = content .. "?" .. param
  end
  return str
end

function PlatformManager:GetQuestionnaire()
  local value = self:getHashValue()
  if not value then
    return
  end
  local sign = "9c98948d616ccdAE962e@#@_shipgirl"
  local time = time.getSvrTime()
  local serverId = value.serverID
  serverId = string.sub(serverId, 5, string.len(serverId))
  local dailyTask = Logic.taskLogic:IsAllFinishByType(TaskType.Daily)
  local isSend = dailyTask and 1 or 0
  local args = {
    ["login_name="] = value.feignRoleId,
    ["groupid="] = serverId,
    ["qid="] = value.qid,
    ["uuid="] = value.uuid,
    ["time="] = time,
    ["is_send="] = isSend,
    ["create_time="] = Data.userData:GetCreateTime()
  }
  local key_table = {}
  for i in pairs(args) do
    table.insert(key_table, i)
  end
  table.sort(key_table, function(a, b)
    local result = false
    if string.byte(a, 1) < string.byte(b, 1) then
      result = true
    else
      result = false
    end
    return result
  end)
  local str = ""
  for k, v in pairs(key_table) do
    str = str .. v .. args[v]
  end
  local encrypt = md5.sumhexa(str .. sign)
  local result = ""
  for k, v in pairs(key_table) do
    if result == "" then
      result = v .. args[v]
    else
      result = result .. "&" .. v .. args[v]
    end
  end
  result = result .. "&sign=" .. encrypt
  return result
end

function PlatformManager:getServiceInfoById(serviceId)
  if self.ServiceListByGroup == nil then
    return nil
  end
  return self.ServiceListByGroup[serviceId]
end

function PlatformManager:getNewServiceInfo()
  if self.ServiceList == nil then
    return nil
  end
  for k, v in pairs(self.ServiceList) do
    if v.new == 1 then
      return v
    end
  end
  local key = next(self.ServiceList)
  if key ~= nil then
    return self.ServiceList[key]
  end
  return nil
end

function PlatformManager:getServiceList()
  if self.ServiceList == nil then
    return nil
  end
  return self.ServiceList
end

function PlatformManager:getServerOpenTime()
  local id = PrefsSettings.GetServerId()
  local server = self:getServiceInfoById(id)
  if server then
    return server.openTime
  else
    local sTime = "20171109140000"
    local tDate_y = string.sub(sTime, 1, 4)
    local tDate_m = string.sub(sTime, 5, 6)
    local tDate_d = string.sub(sTime, 7, 8)
    local tTime_h = string.sub(sTime, 9, 10)
    local tTime_m = string.sub(sTime, 11, 12)
    local tTime_s = string.sub(sTime, 13, 14)
    local openDate = os.time({
      year = tDate_y,
      month = tDate_m,
      day = tDate_d,
      hour = tTime_h,
      min = tTime_m,
      sec = tTime_s
    })
    return openDate
  end
end

function PlatformManager:getHashValue()
  if self.hashValue then
    return self.hashValue
  end
  return nil
end

function PlatformManager:getAllServiceNotic()
  return self.AllServiceNotic
end

function PlatformManager:playVideo(args, funBackCall)
  if self:useSDK() and not isEditor then
    if args ~= nil then
      local path = args.path
      if isAndroid then
        path = "assets/" .. path
      end
      local param = {
        path = path,
        orientation = args.orientation or "2",
        fit = tostring(args.fit)
      }
      PlatformWrapper:playVideo(param, function(ret)
        funBackCall()
      end)
    end
  else
    funBackCall()
  end
end

function PlatformManager:getGiftCard(code, funBackCall)
  local value = self:getHashValue()
  local userInfo = Data.userData:GetUserData()
  local serverId = value.serverID
  serverId = string.gsub(serverId, "game", "")
  local arg = {
    pl = self:GetPL(),
    os = self:GetOS(),
    gn = self:GetGN(),
    pid = value.pid,
    code = code,
    serverid = serverId,
    uid = tostring(userInfo.Uid),
    level = userInfo.Level,
    vip = userInfo.VipLevel
  }
  PlatformWrapper:getGiftCard(arg, function(ret)
    funBackCall(ret)
  end)
end

function PlatformManager:getRealNameState(funBackCall)
  local arg = {
    xpid = tostring(self.pid)
  }
  PlatformWrapper:getRealNameState(arg, function(ret)
    if ret and self:CheckZyxSDK() then
      self.isAdult = ret.data.isAdult
      self.idcardStatus = ret.data.idcardStatus
      self.isFastUser = ret.data.isFastUser
    end
    if funBackCall then
      funBackCall(ret)
    end
  end)
end

function PlatformManager:CheckFastUser()
  return self.isFastUser == 1 or self.isFastUser == "1"
end

function PlatformManager:getOldUserGift()
  if self.extraInfo and self.extraInfo.oldUser then
    local info = self.extraInfo.oldUser
    if info.returnUserReceiveGift and info.returnUserReceiveGift ~= 0 and not self.hadOldGift then
      self:getGiftCard(info.returnUserReceiveGift, function(result)
        if result.code == "0" then
          self.hadOldGift = true
        end
      end)
    end
  end
end

function PlatformManager:useSDK()
  return PlatformWrapper:useSDK()
end

function PlatformManager:loginSuccess()
  return self.isLogined
end

function PlatformManager:GetScreenWidth()
  return PlatformWrapper:GetScreenWidth()
end

function PlatformManager:GetScreenHeight()
  return PlatformWrapper:GetScreenHeight()
end

function PlatformManager:GetDeviceInfo()
  return PlatformWrapper:GetDeviceInfo()
end

function PlatformManager:GetOS()
  return PlatformWrapper:GetOS()
end

function PlatformManager:GetGN()
  return PlatformWrapper:GetGN()
end

function PlatformManager:GetPL()
  return PlatformWrapper:GetPL()
end

function PlatformManager:CheckNetState()
  return PlatformWrapper:CheckNetState()
end

function PlatformManager:GetNetState()
  return PlatformWrapper:GetNetState()
end

function PlatformManager:GetSensorInfo()
  return PlatformWrapper:GetSensorInfo()
end

function PlatformManager:GetStrDeviceInfo()
  return PlatformWrapper:GetStrDeviceInfo()
end

function PlatformManager:ShareWeiXin(imagPath, language, funBackCall)
  local arg = {
    gameName = "\232\139\141\232\147\157\232\170\147\231\186\166",
    scene = "1",
    type = "2",
    pDes = language,
    pImagePath = imagPath,
    isCompress = "0",
    pIcon = UIHelper.GetShareIcon()
  }
  PlatformWrapper:CallUniversalFunction("shareWeixin", arg, PlatformWrapper.CallBackType.SHAREBACK, funBackCall)
end

function PlatformManager:ShareWeibo(imagPath, language, funBackCall)
  local arg = {
    type = "2",
    pDes = language,
    pImagePath = imagPath,
    isCompress = "0"
  }
  PlatformWrapper:CallUniversalFunction("shareWeiBo", arg, PlatformWrapper.CallBackType.SHAREBACK, funBackCall)
end

function PlatformManager:ShareQQZone(imagPath, language, funBackCall)
  local arg = {
    scene = "1",
    type = "2",
    pDes = language,
    pImagePath = imagPath,
    isCompress = "0"
  }
  PlatformWrapper:CallUniversalFunction("shareQQ", arg, PlatformWrapper.CallBackType.SHAREBACK, funBackCall)
end

function PlatformManager:ShareQQFriend(imagPath, language, funBackCall)
  local arg = {
    scene = "0",
    type = "2",
    pDes = language,
    pImagePath = imagPath,
    isCompress = "0"
  }
  PlatformWrapper:CallUniversalFunction("shareQQ", arg, PlatformWrapper.CallBackType.SHAREBACK, funBackCall)
end

function PlatformManager:ViewSizeChange(webW, webH, webPx, webPy, showCloseBtn)
  local arg = {
    webW = width,
    webH = high,
    webPx = posX,
    webPy = posY,
    showCloseBtn = showCloseBtn
  }
  PlatformWrapper:CallUniversalFunction("viewSizeChange", arg)
end

function PlatformManager:OpenUserAgreement()
  PlatformWrapper:CallUniversalFunction("openAgreement", "", 1111)
end

function PlatformManager:OpenNewUserAgreement()
  local tab = {type = "userAgree"}
  PlatformWrapper:CallUniversalFunction("openAgreement", tab)
end

function PlatformManager:OpenUserTreaty()
  local tab = {
    type = "userPrivacy"
  }
  PlatformWrapper:CallUniversalFunction("openAgreement", tab)
end

function PlatformManager:SubmitQuestion()
  if self:useSDK() then
    if not self.hostf then
      self.hostf = CS.Platform.getHostF()
    end
    local url = self.hostf .. "/phone/question"
    local value = Logic.loginLogic.SDKInfo
    local serverId = value.groupid
    local args = {
      action = "index",
      gn = self:GetGN(),
      os = self:GetOS(),
      pid = tostring(self.pid),
      pl = self:GetPL(),
      server_id = tostring(serverId),
      time = time.getSvrTime()
    }
    local key_table = {}
    for i in pairs(args) do
      table.insert(key_table, i)
    end
    table.sort(key_table)
    local str = ""
    for k, v in pairs(key_table) do
      str = str .. v .. "=" .. args[v]
    end
    local sign = "9c98948d616ccdAE962e@#@_shipgirl"
    local encrypt = md5.sumhexa(str .. sign)
    local result = ""
    for k, v in pairs(key_table) do
      if result == "" then
        result = v .. "=" .. args[v]
      else
        result = result .. "&" .. v .. "=" .. args[v]
      end
    end
    result = result .. "&sign=" .. encrypt
    if string.find(url, "?") then
      str = url .. "&" .. result
    else
      str = url .. "?" .. result
    end
    return str
  end
  return nil
end

function PlatformManager:GetAnswer(funBackCall)
  local value = Logic.loginLogic.SDKInfo
  local serverId = value.groupid
  local arg = {
    action = "answer",
    server_id = tostring(serverId),
    pid = tostring(self.pid)
  }
  PlatformWrapper:Question(arg, funBackCall)
end

function PlatformManager:Addiction(limitTime, funBackCall)
  local value = Logic.loginLogic.SDKInfo
  local serverId = value.groupid
  if self.isAdult or self.idcardStatus or self.isFastUser or self.idcardInfo then
    local arg = {
      pid = tostring(self.pid),
      serverid = tostring(serverId),
      isAdult = tostring(self.isAdult),
      idcardStatus = tostring(self.idcardStatus),
      isFastUser = tostring(self.isFastUser),
      idcardInfo = self.idcardInfo,
      limit_time = limitTime
    }
    PlatformWrapper:Addiction(arg, funBackCall)
  end
end

function PlatformManager:CheckPlFunctionState()
  local strJson = SDKConfigGetter.configStr
  if strJson and strJson ~= "" then
    local ret = json.decode(strJson)
    if ret and ret.errornu == "0" and ret.data then
      self.checkPlSuccess = true
      local info = ret.data.qrcodeinfo
      if info then
        self.shareOpen = info.status == 1
        self.qrcode = info.downloadurl
      end
      self.shareSwitch = ret.data.shareswitch
      self.noticeBoard = ret.data.noticeBoard
    end
  end
end

function PlatformManager:CheckUserAgreementVersion(funBackCall)
  PlatformWrapper:CheckUserAgreementVersion(function(ret)
    if funBackCall then
      funBackCall(ret)
    end
  end)
end

function PlatformManager:CheckUserExtraFunctionState()
  local sId = ""
  local sInfo = Logic.loginLogic.SDKInfo
  if sInfo then
    sId = sInfo.groupid
  end
  local arg = {
    pid = tostring(self.pid),
    serverid = sId
  }
  PlatformWrapper:CheckUserExtraFunctionState(arg, function(ret)
    if ret then
      self.extraInfo = ret.data
      self.userInfo = ret.data.userInfo
      if self.userInfo and self.userInfo.readQuestion then
        eventManager:SendEvent(LuaEvent.UpdateGMAnswer, self.userInfo.readQuestion == 1)
      end
      self:GetPayBackReward()
      self:getOldUserGift()
    end
  end)
end

function PlatformManager:GetPayBackReward()
  if self:CheckRechargeReturn() then
    local payBackInfo = self.extraInfo.payBack
    local goldNum = payBackInfo and payBackInfo.returnGold or 0
    local cardNum = payBackInfo and payBackInfo.returnMonthCard or 0
    Service.rechargeService:GetPaybackReward(goldNum, cardNum)
  end
end

function PlatformManager:GetPayBackInfo()
  if self.extraInfo then
    return self.extraInfo.payBack
  end
  return nil
end

function PlatformManager:GetFreeSubscribeState(funBackCall)
  local arg = {
    xpid = tostring(self.pid)
  }
  PlatformWrapper:GetFreeSubscribeState(arg, funBackCall)
end

function PlatformManager:SaveImgToPhotos(imagPath, funBackCall)
  local arg = {
    eventType = tostring(PlatformWrapper.CallBackType.SAVEPHOTO),
    path = imagPath
  }
  PlatformWrapper:CallUniversalFunction("saveImageToPhotosAlbum", arg, PlatformWrapper.CallBackType.SAVEPHOTO, funBackCall)
end

function PlatformManager:ShowShare()
  if not self.checkPlSuccess then
    self:CheckPlFunctionState()
  end
  local show = false
  if self.shareOpen then
    show = self.shareOpen
    local flag = 0
    if self.shareSwitch then
      for k, v in pairs(self.shareSwitch) do
        if v == 1 then
          flag = 1
        end
      end
    end
    if flag == 0 then
      show = false
    end
  end
  return show
end

function PlatformManager:GetAnnounceState(announcType)
  if not self.checkPlSuccess then
    self:CheckPlFunctionState()
  end
  if self.noticeBoard then
    local announceInfo = announcType == AnnouncementType.Base and self.noticeBoard.beforgame or self.noticeBoard.ingame
    if announceInfo then
      local status = announceInfo.status
      if status == AnnouncementPushType.FirstLogin then
        local key = PlayerPrefs.FormatKey("announcePush")
        local lastLoginTime = PlayerPrefs.GetInt(key, 0)
        local serverTime = time.getSvrTime()
        local isSame = time.isSameDay(lastLoginTime, serverTime)
        PlayerPrefs.SetInt(key, serverTime)
        PlayerPrefs.Save()
        if isSame then
          announcementManager.opened = true
        end
        return not isSame
      elseif status == AnnouncementPushType.EveryLogin then
        return true
      elseif status == AnnouncementPushType.NoAuto then
        return false
      elseif status == AnnouncementPushType.TimeAuto then
        local time = time.getSvrTime()
        local begin_time = announceInfo.begintime
        local end_time = announceInfo.endtime
        return time >= begin_time and time <= end_time
      end
    end
  end
  return false
end

function PlatformManager:ShowSharePlatform(platType)
  if platType == ShareType.WeiXin then
    return self.shareSwitch.wx == 1
  elseif platType == ShareType.WeiBo then
    return self.shareSwitch.sina == 1
  elseif platType == ShareType.QQFriend then
    return self.shareSwitch.qqfriend == 1
  elseif platType == ShareType.QQZone then
    return self.shareSwitch.qqzone == 1
  end
end

function PlatformManager:CheckZyxSDK()
  local str = PlatformWrapper:callUniversalFunctionWithBack("isZYXSDK", "")
  return str == "1"
end

function PlatformManager:GetUserPid()
  return self.pid
end

function PlatformManager:CheckRechargeReturn()
  local result = false
  if self.extraInfo and self.extraInfo.payBack then
    local payBackInfo = self.extraInfo.payBack
    if payBackInfo.returnGold ~= nil and payBackInfo.returnGold > 0 or payBackInfo.returnMonthCard ~= nil and 0 < payBackInfo.returnMonthCard then
      result = true
    end
  end
  return result
end

function PlatformManager:AddLocalNotification(key, body, time, repeatInterval)
  if isIOS then
    PlatformWrapper:addLocalNotification(key, body, time, repeatInterval)
  end
end

function PlatformManager:CancelLocalNotification(key)
  if isIOS then
    PlatformWrapper:cancelLocalNotification(key)
  end
end

function PlatformManager:CancelAllLocalNotification()
  if isIOS then
    PlatformWrapper:cancelAllLocalNotification()
  end
end

function PlatformManager:GetTimeZoneOffset()
  if self.hashValue then
    return self.hashValue.offset
  end
  return nil
end

function PlatformManager:IsSimulator()
  return PlatformWrapper:IsSimulator()
end

function PlatformManager:GetPatchVersion()
  return PlatformWrapper:GetPatchVersion()
end

function PlatformManager:StartRecord()
  PlatformWrapper:StartRecord()
end

function PlatformManager:StopRecord()
  PlatformWrapper:StopRecord()
end

function PlatformManager:CancelRecord()
  PlatformWrapper:CancelRecord()
end

function PlatformManager:DownloadVoice(url)
  PlatformWrapper:DownloadVoice(url)
end

function PlatformManager:PlayVoice(filePath)
  PlatformWrapper:PlayVoice(filePath)
end

function PlatformManager:StopPlay()
  PlatformWrapper:StopPlay()
end

function PlatformManager:CheckVoiceInit()
  return PlatformWrapper:CheckVoiceInit()
end

function PlatformManager:SendVivoSDKinfo(strId, strContent)
  local strjson = {
    [strId] = strContent
  }
  PlatformWrapper:CallUniversalFunction("vivoSendMessage", strjson)
end

function PlatformManager:GetTid()
  local result = PlatformWrapper:callUniversalFunctionWithBack("getTid", "")
  return result
end

function PlatformManager:GetEquipEffectUrl(content, effectId)
  local str = ""
  local param = "skill_fashion_id=" .. effectId
  if string.find(content, "?") then
    str = content .. "&" .. param
  else
    str = content .. "?" .. param
  end
  return str
end

return PlatformManager
