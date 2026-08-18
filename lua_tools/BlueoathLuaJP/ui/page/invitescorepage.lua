local InviteScorePage = class("ui.page.InviteScorePage", LuaUIPage)

function InviteScorePage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
end

function InviteScorePage:DoOnOpen()
end

function InviteScorePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnGo, self._ClickGo, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnLater, self._ClickLater, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnNoMore, self._ClickNoMore, self)
end

function InviteScorePage:_ClickGo()
  platformManager:RecordRate(InviteScoreChooseType.ClickGo, function()
    self:_CallBackFunc()
  end)
  print("\230\137\147\229\188\128Google\232\175\132\228\187\183")
  PlatformWrapper:CallUniversalFunction("showInAppComment", "")
end

function InviteScorePage:_ClickLater()
  UIHelper.ClosePage("InviteScorePage")
end

function InviteScorePage:_ClickNoMore()
  platformManager:RecordRate(InviteScoreChooseType.ClickNoMore, function()
    self:_CallBackFunc()
  end)
  Data.inviteScoreData:SetIsScored(InviteScoreSign.Scored)
  UIHelper.ClosePage("InviteScorePage")
end

function InviteScorePage:_GetBrowseInfoCallBack(str)
  local deviceWidth, deviceHeight, posX, posY = self:_GetViewWidthAndHeight()
  platformManager:openCustomWebView(str, deviceWidth, deviceHeight, posX, posY, "1", nil, true)
end

function InviteScorePage:_GetViewWidthAndHeight()
  local deviceWidth = platformManager:GetScreenWidth()
  local deviceHeight = platformManager:GetScreenHeight()
  local posX = 0
  local posY = 0
  return deviceWidth, deviceHeight, posX, posY
end

function InviteScorePage:DoOnHide()
end

function InviteScorePage:DoOnClose()
end

function InviteScorePage:_CallBackFunc()
end

return InviteScorePage
