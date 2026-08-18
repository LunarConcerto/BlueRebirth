local ShareManager = class("util.ShareManager")
local shareImpl = {
  [ShareType.WeiXin] = function(self)
    self:_ShareWeixin()
  end,
  [ShareType.WeiBo] = function(self)
    self:_ShareWeibo()
  end,
  [ShareType.QQFriend] = function(self)
    self:_ShareQQFriend()
  end,
  [ShareType.QQZone] = function(self)
    self:_ShareQQZone()
  end,
  [ShareType.Twitter] = function(self)
    self:_ShareTwitter()
  end
}
local DotKey = {
  HomePage = "User.sharefb.homepage",
  BuildOneGirl = "User.sharefb.character",
  BuildTenGirl = "User.sharefb.character.10",
  BuildOneEquip = "User.sharefb.equipment",
  BuildTenEquip = "User.sharefb.equipment.10"
}
local ShareLanguage = {
  HomePage = isWindows and 480007 or 480000,
  LvliPage = isWindows and 480008 or 480001,
  IllustrateInfo = isWindows and 480009 or 480002,
  ShowGirlPage = isWindows and 480010 or 480003,
  BuildShipPage = isWindows and 480011 or 480004,
  GetRewardsPage = isWindows and 480012 or 480005,
  ARKitPage = isWindows and 480013 or 480006
}

function ShareManager:initialize()
  self.strPath = nil
end

function ShareManager:Share(pageName, param, pathType, shareSource)
  self.shareSource = shareSource
  eventManager:SendEvent(LuaEvent.ShareStart)
  if shareSource then
    local m_dotKey = DotKey[shareSource]
    if m_dotKey then
      local dotInfo = {
        os = platformManager:GetOS()
      }
      RetentionHelper.Retention(m_dotKey, dotInfo)
    end
  end
  if isWindows then
    noticeManager:ShowTip(UIHelper.GetString(422000))
    eventManager:SendEvent(LuaEvent.ShareOver)
  else
    self.pageName = pageName
    UIManager.rootEffect.gameObject:SetActive(false)
    UIHelper.OpenPage("QRCodePage", param, nil, false)
    if pathType == nil then
      pathType = OpenSharePage.Other
    end
    coroutine.start(function()
      coroutine.wait(0.1)
      self.strPath = UIHelper.CaptureScreen()
      eventManager:SendEvent(LuaEvent.CreateShareEffect, true)
      coroutine.wait(1.2)
      eventManager:SendEvent(LuaEvent.CreateShareEffect, false)
      UIManager.rootEffect.gameObject:SetActive(true)
      UIHelper.OpenPage("SharePage", pathType, nil, false)
    end)
  end
end

function ShareManager:_SavePhoto()
  if platformManager:GetOS() == "ios" then
    platformManager:SaveImgToPhotos(self.strPath, function(ret)
      self:_SavePhotoCallBack(ret)
    end)
  end
end

function ShareManager:ShareToApp(type)
  Service.taskService:SendTaskTrigger(TaskKind.SHARE)
  local languageId = ShareLanguage[self.pageName]
  if languageId then
    local lConfig = configManager.GetDataById("config_language", languageId)
    if lConfig then
      self.language = lConfig.content
    end
  end
  self:CloseShare()
  if platformManager:useSDK() then
    shareImpl[type](self)
  end
  self.language = nil
end

function ShareManager:_ShareTwitter()
  platformManager:ShareTwitter(self.strPath, self.language, function(ret)
    self:_ShareCallBack(ret)
  end)
end

function ShareManager:_ShareWeixin()
  platformManager:ShareWeiXin(self.strPath, self.language, function(ret)
    self:_ShareCallBack(ret)
  end)
end

function ShareManager:_ShareWeibo()
  platformManager:ShareWeibo(self.strPath, self.language, function(ret)
    self:_ShareCallBack(ret)
  end)
end

function ShareManager:_ShareQQFriend()
  platformManager:ShareQQFriend(self.strPath, self.language, function(ret)
    self:_ShareCallBack(ret)
  end)
end

function ShareManager:_ShareQQZone()
  platformManager:ShareQQZone(self.strPath, self.language, function(ret)
    self:_ShareCallBack(ret)
  end)
end

function ShareManager:_ShareCallBack(ret)
  if ret and ret.errornu == "0" and self.shareSource then
    local m_dotKey = DotKey[self.shareSource]
    if m_dotKey then
      local dotInfo = {
        os = platformManager:GetOS()
      }
      RetentionHelper.Retention(m_dotKey .. ".success", dotInfo)
    end
  end
end

function ShareManager:CloseShare()
  eventManager:SendEvent(LuaEvent.ShareOver)
end

return ShareManager
