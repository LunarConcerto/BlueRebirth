local NoticeInGamePage = class("ui.page.NoticeInGamePage", LuaUIPage)

function NoticeInGamePage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function NoticeInGamePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, function()
    self:_ClickClose()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_go, function()
    self:_ClickGOTo()
  end)
end

function NoticeInGamePage:DoOnOpen()
  local tipWidth, tipHeight, posLeftX, posLeftY = self:CaculateSize()
  local serverId = "Base"
  local category = 9
  platformManager:getSuperNoticeAndOpen(serverId, tipWidth, tipHeight, posLeftX, posLeftY, nil, category)
end

function NoticeInGamePage:_ShowBtn()
  local PeriodList = configManager.GetDataById("config_parameter", 364).arrValue
  local icon = SummerNoticeBtnIcon[1]
  for i, id in pairs(PeriodList) do
    if PeriodManager:IsInPeriod(id) then
      icon = SummerNoticeBtnIcon[i]
      break
    end
  end
  UIHelper.SetImage(self.m_tabWidgets.im_btn, icon)
end

function NoticeInGamePage:_ClickClose()
  UIHelper.ClosePage(self:GetName())
end

function NoticeInGamePage:_ClickGOTo()
  local params = platformManager:GetNoticeInGameParams()
  if params.jump_to_Func == 2 and params.jump_function and params.jump_function ~= -1 then
    moduleManager:JumpToFunc(params.jump_function, tonumber(params.jump_para))
  elseif params.jump_to_Func == 1 and params.web_url and params.web_url ~= "" then
    platformManager:OpenURL(params.web_url)
  end
  self:_ClickClose()
end

function NoticeInGamePage:_GetViewWidthAndHeight()
  local deviceWidth = platformManager:GetScreenWidth()
  local deviceHeight = platformManager:GetScreenHeight()
  local posX = 0
  local posY = 0
  return deviceWidth, deviceHeight, posX, posY
end

function NoticeInGamePage:CaculateSize(aType, param)
  local subwidth = self.m_tabWidgets.im_notice.rect.width
  local subheight = self.m_tabWidgets.im_notice.rect.height
  local subPosX = self.m_tabWidgets.im_notice.anchoredPosition.x
  local subPosY = self.m_tabWidgets.im_notice.anchoredPosition.y
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

function NoticeInGamePage:DoOnHide()
end

function NoticeInGamePage:DoOnClose()
  platformManager:closeCustomWebView()
  if self.param.callBack then
    self.param.callBack()
  end
end

return NoticeInGamePage
