InformationPage = class("UI.Picture.InformationPage", LuaUIPage)
local m_rightPageName = {
  "PicturePage"
}

function InformationPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function InformationPage:DoOnOpen()
  self:OpenTopPage("InformationPage", 1, "\232\191\148\229\155\158", self, true)
  self.m_tabWidgets.tog_leftGroup:SetActiveToggleIndex(0)
end

function InformationPage:RegisterAllEvent()
  self.tabLeftTogs = {
    self.m_tabWidgets.tog_grilfleet,
    self.m_tabWidgets.tog_equip,
    self.m_tabWidgets.tog_photo
  }
  for i, tog in pairs(self.tabLeftTogs) do
    self.m_tabWidgets.tog_leftGroup:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_leftGroup, self, "", self._SwitchTogs)
end

function InformationPage:_SwitchTogs(index)
  self:_LoadRightPage(index + 1)
end

function InformationPage:_LoadRightPage(nIndex)
  if nIndex == 1 then
    UIHelper.OpenPage(m_rightPageName[nIndex])
  else
    noticeManager:OpenTipPage(self, UIHelper.GetString(110025))
  end
end

function InformationPage:DoOnHide()
  self.m_tabWidgets.tog_leftGroup:ClearToggles()
end

function InformationPage:DoOnClose()
  self.m_tabWidgets.tog_leftGroup:ClearToggles()
end

return InformationPage
