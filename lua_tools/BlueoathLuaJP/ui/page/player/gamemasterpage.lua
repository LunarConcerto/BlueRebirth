local GameMasterPage = class("UI.Player.GameMasterPage", LuaUIPage)

function GameMasterPage:DoInit()
end

function GameMasterPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, function()
    self:_ClickClose()
  end)
end

function GameMasterPage:DoOnOpen()
  local tipWidth, tipHeight, posLeftX, posLeftY = self:CaculateSize()
  local ret = platformManager:SubmitQuestion()
  platformManager:openCustomWebView(ret, tipWidth, tipHeight, posLeftX, posLeftY, "0")
end

function GameMasterPage:CaculateSize(param)
  local subwidth = self.tab_Widgets.im_notice.rect.width
  local subheight = self.tab_Widgets.im_notice.rect.height
  local subPosX = self.tab_Widgets.im_notice.anchoredPosition.x
  local subPosY = self.tab_Widgets.im_notice.anchoredPosition.y
  local uiRoot = UIManager.rootUI:GetComponent(RectTransform.GetClassType())
  local rootWidth = uiRoot.rect.width
  local rootHeight = uiRoot.rect.height
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
  local tipWidth = subwidth * deviceWidth / rootWidth
  local tipHeight = subheight * deviceHeight / rootHeight
  subPosX = subPosX * deviceWidth / rootWidth
  subPosY = subPosY * deviceHeight / rootHeight
  local posLeftX = deviceWidth / 2 - tipWidth / 2 + subPosX
  local posLeftY = deviceHeight / 2 - tipHeight / 2 - subPosY
  return tipWidth, tipHeight, posLeftX, posLeftY
end

function GameMasterPage:DoOnHide()
end

function GameMasterPage:DoOnClose()
  platformManager:closeCustomWebView()
end

function GameMasterPage:_ClickClose()
  UIHelper.ClosePage("GameMasterPage")
end

return GameMasterPage
