PlatformWrapper = {}
local json = require("cjson")
PlatformWrapper.CallBackType = {
  LOGIN = 2,
  GETSERVERLIST = 3,
  GETHASH = 4,
  PAY = 6,
  QUIT = 7,
  LOGOUT = 8,
  CRASH = 9,
  DIFFACCOUNT = 10,
  SHAREBACK = 11,
  PLAYFINISH = 12,
  LOWMEMORY = 13,
  HANDLEOPENURL = 14,
  SHOWLOGOFINISH = 15,
  GETLOGINEDSERVERINFO = 16,
  GETNOTICE = 17,
  QUSETION = 18,
  GETAPPLEREVIEW = 19,
  GETSUPERNOTICE = 20,
  GETUSERINFORMATION = 21,
  GETBROWSEACTIVE = 22,
  REQUESTDJORDERSTATUS = 23,
  ISSUEDJORDERS = 24,
  GETFORCEFIX = 25,
  HANDLEURL = 26,
  CUSTOMWEBVIEW = 29,
  SCAN_CODE = 33,
  AR_CODE = 36,
  GIFTCARD = 1001,
  REALNAME = 1002,
  ADDICTION = 1003,
  FREESUBSCRIBE = 1004,
  SAVEPHOTO = 1005,
  GAMEANNOUNCEMENT = 1006,
  PLFUNCTION = 1007,
  USEREXTRA = 1008,
  USERAGREEMENT = 1009,
  RATE = 1010
}
local CantRemoveCallBack = {
  [PlatformWrapper.CallBackType.CUSTOMWEBVIEW] = 1,
  [PlatformWrapper.CallBackType.LOGOUT] = 2
}

function PlatformWrapper:initialize()
  self.funCallBackReply = nil
  self:registerCallBack(PlatformWrapper.CallBackType.LOGOUT, function()
    self:_LogoutDefaultCallBack()
  end)
end

function PlatformWrapper:_LogoutDefaultCallBack()
  platformManager:LogOutCallBack()
end

function PlatformWrapper:onBackCall(backType, backValue)
  local result
  if backType == PlatformWrapper.CallBackType.GETHASH or backType == PlatformWrapper.CallBackType.GETSERVERLIST or backType == PlatformWrapper.CallBackType.SHAREBACK or backType == PlatformWrapper.CallBackType.SCAN_CODE or backType == PlatformWrapper.CallBackType.AR_CODE or backType == PlatformWrapper.CallBackType.ADDICTION then
    result = json.decode(backValue)
  else
    result = self:getResult(backValue)
  end
  self:FireCallBack(backType, result)
  self:RemoveCallBack(backType)
end

function PlatformWrapper:getResult(data)
  if data == "" or data == "null" then
    return nil
  end
  local result = json.decode(data)
  if result == nil then
    return nil
  end
  if result.errornu ~= nil and result.errornu ~= "0" then
    if result.errornu and result.errordesc then
      logError(string.format("\229\185\179\229\143\176\230\149\176\230\141\174\233\148\153\232\175\175,\233\148\153\232\175\175\229\143\183\239\188\154%s\239\188\140\233\148\153\232\175\175\228\191\161\230\129\175\239\188\154%s", result.errornu, result.errordesc))
    end
    return nil
  end
  return result
end

function PlatformWrapper:getServerList(funCallBack)
  self:registerCallBack(PlatformWrapper.CallBackType.GETSERVERLIST, funCallBack)
  BabelTimeSDK.GetServiceList()
end

function PlatformWrapper:getHash(serviceId, funCallBack)
  self:registerCallBack(PlatformWrapper.CallBackType.GETHASH, funCallBack)
  local jsonData = json.encode({group_id = serviceId})
  BabelTimeSDK.SelectService(jsonData)
end

function PlatformWrapper:login(funCallBack)
  self:registerCallBack(PlatformWrapper.CallBackType.LOGIN, funCallBack)
  BabelTimeSDK.Login()
end

function PlatformWrapper:logout()
  BabelTimeSDK.Logout()
end

function PlatformWrapper:playVideo(str, funCallBack)
  self:registerCallBack(PlatformWrapper.CallBackType.PLAYFINISH, funCallBack)
  local jsonData = json.encode(str)
  BabelTimeSDK.PlayVideo(jsonData)
end

function PlatformWrapper:getLastServiceList(pid, funCallBack)
  self:registerCallBack(PlatformWrapper.CallBackType.GETLOGINEDSERVERINFO, funCallBack)
  local jsonData = json.encode({pid = pid})
  BabelTimeSDK.GetLastServiceList(jsonData)
end

function PlatformWrapper:showToolBar()
  BabelTimeSDK.ShowToolBar()
end

function PlatformWrapper:hideToolBar()
  BabelTimeSDK.HideToolBar()
end

function PlatformWrapper:isShowUserCenter()
  return BabelTimeSDK.IsShowUserCenter()
end

function PlatformWrapper:enterUserCenter()
  BabelTimeSDK.EnterUserCenter()
end

function PlatformWrapper:sendInformationToPlatform(str)
  local jsonData = json.encode(str)
  BabelTimeSDK.ChangeUserInfo(jsonData)
end

function PlatformWrapper:openCustomWebView(str, funCallBack)
  if funCallBack then
    self:registerCallBack(PlatformWrapper.CallBackType.CUSTOMWEBVIEW, funCallBack)
  end
  local jsonData = json.encode(str)
  BabelTimeSDK.OpenCustomWebView(jsonData)
end

function PlatformWrapper:closeCustomWebView()
  BabelTimeSDK.CloseCustomWebView()
end

function PlatformWrapper:getBrowseActive(str, funCallBack)
  self:registerCallBack(PlatformWrapper.CallBackType.GETBROWSEACTIVE, funCallBack)
  local jsonData = json.encode(str)
  BabelTimeSDK.GetBrowseActive(jsonData)
end

function PlatformWrapper:getSuperNotice(str, funCallBack)
  local jsonData = json.encode(str)
  local result = BabelTimeSDK.GetSuperNotice(jsonData)
  funCallBack(result)
end

function PlatformWrapper:retention(eventId, uid, defineStr)
  BabelTimeSDK.RetentionForLua(eventId, uid, defineStr)
end

function PlatformWrapper:appsflyerRetentionForLua(defineStr)
  BabelTimeSDK.AppsflyerRetentionForLua(defineStr)
end

function PlatformWrapper:refreshUUid()
  BabelTimeSDK.RefreshUUid()
end

function PlatformWrapper:getGiftCard(str, funCallBack)
  self:registerCallBack(PlatformWrapper.CallBackType.GIFTCARD, funCallBack)
  local jsonData = json.encode(str)
  BabelTimeSDK.CallWebFunction(tonumber(PlatformWrapper.CallBackType.GIFTCARD), "giftcard", jsonData)
end

function PlatformWrapper:getRealNameState(arg, funCallBack)
  self:registerCallBack(PlatformWrapper.CallBackType.REALNAME, funCallBack)
  local jsonData = json.encode(arg)
  BabelTimeSDK.CallWebFunction(tonumber(PlatformWrapper.CallBackType.REALNAME), "platform/getPlatformUserInfo", jsonData)
end

function PlatformWrapper:Addiction(arg, funCallBack)
  if funCallBack then
    self:registerCallBack(PlatformWrapper.CallBackType.ADDICTION, funCallBack)
  end
  local jsonData = json.encode(arg)
  BabelTimeSDK.CallWebFunction(tonumber(PlatformWrapper.CallBackType.ADDICTION), "addiction/getaddiction", jsonData)
end

function PlatformWrapper:GameAnnouncementState(arg, funCallBack)
  if funCallBack then
    self:registerCallBack(PlatformWrapper.CallBackType.GAMEANNOUNCEMENT, funCallBack)
  end
  local jsonData = json.encode(arg)
  BabelTimeSDK.CallWebFunction(tonumber(PlatformWrapper.CallBackType.GAMEANNOUNCEMENT), "platform/getGameMaintainNotice", jsonData)
end

function PlatformWrapper:CheckPlFunctionState(funCallBack)
  if funCallBack then
    self:registerCallBack(PlatformWrapper.CallBackType.PLFUNCTION, funCallBack)
  end
  BabelTimeSDK.CallWebFunction(tonumber(PlatformWrapper.CallBackType.PLFUNCTION), "getPlData/getPlData", "")
end

function PlatformWrapper:CheckUserAgreementVersion(funCallBack)
  if funCallBack then
    self:registerCallBack(PlatformWrapper.CallBackType.USERAGREEMENT, funCallBack)
  end
  BabelTimeSDK.CallWebFunction(tonumber(PlatformWrapper.CallBackType.USERAGREEMENT), "helper/getagreeversion", "")
end

function PlatformWrapper:CheckUserExtraFunctionState(arg, funCallBack)
  if funCallBack then
    self:registerCallBack(PlatformWrapper.CallBackType.USEREXTRA, funCallBack)
  end
  local jsonData = json.encode(arg)
  BabelTimeSDK.CallWebFunction(tonumber(PlatformWrapper.CallBackType.USEREXTRA), "getuserextra/getuserextra", jsonData)
end

function PlatformWrapper:GetFreeSubscribeState(arg, funCallBack)
  if funCallBack then
    self:registerCallBack(PlatformWrapper.CallBackType.FREESUBSCRIBE, funCallBack)
  end
  local jsonData = json.encode(arg)
  BabelTimeSDK.CallWebFunction(tonumber(PlatformWrapper.CallBackType.FREESUBSCRIBE), "platform/getPlatformExt", jsonData)
end

function PlatformWrapper:RecordRate(arg, funCallBack)
  if funCallBack then
    self:registerCallBack(PlatformWrapper.CallBackType.RATE, funCallBack)
  end
  local jsonData = json.encode(arg)
  BabelTimeSDK.CallWebFunction(tonumber(PlatformWrapper.CallBackType.RATE), "rate/rate", jsonData)
end

function PlatformWrapper:getPay(str, funCallBack)
  self:registerCallBack(PlatformWrapper.CallBackType.PAY, funCallBack)
  local jsonData = json.encode(str)
  BabelTimeSDK.Pay(jsonData)
end

function PlatformWrapper:addLocalNotification(key, body, time, repeatInterval)
  BabelTimeSDK.AddLocalNotification(key, body, time, repeatInterval)
end

function PlatformWrapper:cancelLocalNotification(key)
  BabelTimeSDK.CancelLocalNotification(key)
end

function PlatformWrapper:cancelAllLocalNotification()
  BabelTimeSDK.CancelAllLocalNotification()
end

function PlatformWrapper:useSDK()
  return BabelTimeSDK.UseSDK
end

function PlatformWrapper:sdkInitFinish()
  return BabelTimeSDK.SDKInitFinish
end

function PlatformWrapper:registerCallBack(id, funCallBack)
  if self.funCallBackReply == nil then
    self.funCallBackReply = {}
  end
  self.funCallBackReply[id] = funCallBack
end

function PlatformWrapper:RemoveCallBack(id)
  if not CantRemoveCallBack[id] and self.funCallBackReply ~= nil and self.funCallBackReply[id] ~= nil then
    self.funCallBackReply[id] = nil
  end
end

function PlatformWrapper:FireCallBack(id, param)
  if self.funCallBackReply ~= nil then
    local event = self.funCallBackReply[id]
    if event ~= nil then
      event(param)
    end
  end
end

function PlatformWrapper:GetScreenWidth()
  return BabelTimeSDK.GetScreenWidth()
end

function PlatformWrapper:GetScreenHeight()
  return BabelTimeSDK.GetScreenHeight()
end

function PlatformWrapper:GetDeviceInfo()
  return BabelTimeSDK.GetDeviceInfo()
end

function PlatformWrapper:GetPL()
  return BabelTimeSDK.GetPL()
end

function PlatformWrapper:GetOS()
  return BabelTimeSDK.GetOS()
end

function PlatformWrapper:GetGN()
  return BabelTimeSDK.GetGN()
end

function PlatformWrapper:CheckNetState()
  return BabelTimeSDK.CheckNetState()
end

function PlatformWrapper:GetNetState()
  return BabelTimeSDK.GetNetState()
end

function PlatformWrapper:GetSensorInfo()
  return BabelTimeSDK.GetSensorInfo()
end

function PlatformWrapper:GetStrDeviceInfo()
  return BabelTimeSDK.GetStrDeviceInfo()
end

function PlatformWrapper:GetLocalInfo()
  return BabelTimeSDK.GetLocalInfoJson()
end

function PlatformWrapper:GetPatchVersion()
  if isEditor then
    return "0.0.0"
  else
    return BabelTimeSDK.GetPatchVersion()
  end
end

function PlatformWrapper:IsSimulator()
  return BabelTimeSDK.IsSimulator()
end

function PlatformWrapper:CallUniversalFunction(functionName, str, id, funCallBack)
  if funCallBack then
    self:registerCallBack(id, funCallBack)
  end
  local jsonData = json.encode(str)
  log("CallUniversalFunction ", functionName, str, jsonData)
  BabelTimeSDK.CallUniversalFunction(functionName, jsonData)
end

function PlatformWrapper:Question(str, funCallBack)
  if funCallBack then
    self:registerCallBack(PlatformWrapper.CallBackType.QUSETION, funCallBack)
  end
  local jsonData = json.encode(str)
  BabelTimeSDK.Question(jsonData)
end

function PlatformWrapper:setInitRetention(qualityLv)
  BabelTimeSDK.SetInitRetention(qualityLv)
end

function PlatformWrapper:callUniversalFunctionWithBack(functionName, str)
  return BabelTimeSDK.CallUniversalFunctionWithBack(functionName, str)
end

function PlatformWrapper:AddRemoteNotification(str)
  local jsonData = json.encode(str)
  BabelTimeSDK.AddRemoteNotification(jsonData)
end

function PlatformWrapper:PressBack()
  BabelTimeSDK.PressBack()
end

function PlatformWrapper:OpenURL(url)
  BabelTimeSDK.OpenUrl(url)
end
