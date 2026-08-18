local AnnouncementPage = class("UI.AnnouncementPage", LuaUIPage)

function AnnouncementPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.tabObj = {
    [AnnouncementType.Base] = {
      obj_bg = self.m_tabWidgets.obj_bg,
      im_notice = self.m_tabWidgets.im_notice,
      btn_close = self.m_tabWidgets.btn_close
    },
    [AnnouncementType.Maintenance] = {
      obj_bg = self.m_tabWidgets.obj_m_bg,
      im_notice = self.m_tabWidgets.im_m_notice,
      btn_close = self.m_tabWidgets.btn_m_close
    }
  }
end

function AnnouncementPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tabObj[self.param.aType].btn_close, function()
    self:_ClickClose()
  end)
end

function AnnouncementPage:DoOnOpen()
  self.aType = self.param.aType
  local aType = self.aType
  for k, v in pairs(self.tabObj) do
    for p, q in pairs(v) do
      q.gameObject:SetActive(k == aType)
    end
  end
  local tipWidth, tipHeight, posLeftX, posLeftY = self:CaculateSize(self.aType)
  local serverId = ""
  local category = 1
  if aType == AnnouncementType.Base then
    serverId = "Base"
  elseif aType == AnnouncementType.Maintenance then
    category = 7
    serverId = Logic.loginLogic.SDKInfo.groupid
  end
  platformManager:getSuperNoticeAndOpen(serverId, tipWidth, tipHeight, posLeftX, posLeftY, nil, category)
end

function AnnouncementPage:CaculateSize(aType, param)
  local subwidth = self.tabObj[aType].im_notice.rect.width
  local subheight = self.tabObj[aType].im_notice.rect.height
  local subPosX = self.tabObj[aType].im_notice.anchoredPosition.x
  local subPosY = self.tabObj[aType].im_notice.anchoredPosition.y
  log("subPosX" .. subPosX .. "subPosY" .. subPosY)
  log("subwidth" .. subwidth .. "subheight" .. subheight)
  local uiRoot = UIManager.rootUI:GetComponent(RectTransform.GetClassType())
  local rootWidth = uiRoot.rect.width
  local rootHeight = uiRoot.rect.height
  log("rootW" .. rootWidth .. "  rootH" .. rootHeight)
  local deviceWidth = platformManager:GetScreenWidth()
  local deviceHeight = platformManager:GetScreenHeight()
  if isWindows then
    if param then
      deviceWidth = param.w
      deviceHeight = param.h
    else
      deviceWidth = Screen.width
      deviceHeight = Screen.height
    end
  end
  log("\229\185\179\229\143\176\230\149\176\230\141\174\229\174\189 " .. deviceWidth)
  log("\229\185\179\229\143\176\230\149\176\230\141\174\233\171\152 " .. deviceHeight)
  local tipWidth = subwidth * deviceWidth / rootWidth
  local tipHeight = subheight * deviceHeight / rootHeight
  subPosX = subPosX * deviceWidth / rootWidth
  subPosY = subPosY * deviceHeight / rootHeight
  local posLeftX = deviceWidth / 2 - tipWidth / 2 + subPosX
  local posLeftY = deviceHeight / 2 - tipHeight / 2 - subPosY
  log("posLeftX " .. posLeftX .. "  posLeftY" .. posLeftY)
  log("tipWidth " .. tipWidth .. "  tipHeight" .. tipHeight)
  return tipWidth, tipHeight, posLeftX, posLeftY
end

function AnnouncementPage:DoOnHide()
end

function AnnouncementPage:DoOnClose()
  platformManager:closeCustomWebView()
  if self.param.callBack then
    self.param.callBack()
  end
end

function AnnouncementPage:_ClickClose()
  UIHelper.ClosePage("AnnouncementPage")
end

return AnnouncementPage
