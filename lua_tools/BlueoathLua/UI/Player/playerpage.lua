local PlayerPage = class("UI.Player.PlayerPage", LuaUIPage)
local m_rightPageName = {
  "LvliPage",
  "DisplaySetPage"
}

function PlayerPage:DoInit()
end

function PlayerPage:DoOnOpen()
  self.tab_Widgets.tog_leftGroup:SetActiveToggleIndex(0)
  self:OpenTopPage("PlayerPage", 1, "\232\191\148\229\155\158", self, true)
end

function PlayerPage:RegisterAllEvent()
  self.tabLeftTogs = {
    self.tab_Widgets.tog_record,
    self.tab_Widgets.tog_setting,
    self.tab_Widgets.tog_ranking
  }
  for i, tog in pairs(self.tabLeftTogs) do
    self.tab_Widgets.tog_leftGroup:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_leftGroup, self, "", self._SwitchTogs)
end

function PlayerPage:_SwitchTogs(index)
  self:_LoadRightPage(index + 1)
end

function PlayerPage:_LoadRightPage(nIndex)
  if nIndex <= 2 and 1 <= nIndex then
    UIHelper.OpenPage(m_rightPageName[nIndex])
  else
    noticeManager:OpenTipPage(self, UIHelper.GetString(110025))
  end
end

function PlayerPage:DoOnHide()
  self.tab_Widgets.tog_leftGroup:ClearToggles()
end

function PlayerPage:DoOnClose()
  self.tab_Widgets.tog_leftGroup:ClearToggles()
end

return PlayerPage
