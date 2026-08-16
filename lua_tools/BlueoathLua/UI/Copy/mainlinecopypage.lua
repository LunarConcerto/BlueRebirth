local MainLineCopyPage = class("UI.Copy.MainLineCopyPage", LuaUIPage)
local m_rightPageName = {
  "CopyPage",
  "CrusadePage",
  "TeachCopyPage"
}

function MainLineCopyPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function MainLineCopyPage:DoOnOpen()
  local param = self:GetParam()
  local sign = param or Logic.copyLogic:GetCopySign()
  local togsIndex = Logic.copyLogic:GetTogsIndex()
  if sign == EnterCopySign.Home then
    self.m_tabWidgets.tog_leftGroup:SetActiveToggleIndex(0)
  elseif sign == EnterCopySign.Crusade then
    self.m_tabWidgets.tog_leftGroup:SetActiveToggleIndex(1)
    local isHasFleet = Logic.fleetLogic:IsHasFleet()
    if not isHasFleet then
      self.m_tabWidgets.tog_leftGroup:ResigterToggleUnActive(0, self._StopToggle)
    end
  else
    self.m_tabWidgets.tog_leftGroup:SetActiveToggleIndex(togsIndex - 1)
  end
  Logic.copyLogic:SetCopySign(EnterCopySign.Other)
  self:OpenTopPage("MainLineCopyPage", 1, "\229\135\186\229\190\129", self, true)
end

function MainLineCopyPage:RegisterAllEvent()
  self.tabLeftTogs = {
    self.m_tabWidgets.tog_mainLine,
    self.m_tabWidgets.tog_crusade,
    self.m_tabWidgets.tog_daily
  }
  for i, tog in pairs(self.tabLeftTogs) do
    self.m_tabWidgets.tog_leftGroup:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_leftGroup, self, "", self._SwitchTogs)
end

function MainLineCopyPage:_SwitchTogs(index)
  self:SaveNewParam(EnterCopySign.Other)
  self:_LoadRightPage(index + 1)
end

function MainLineCopyPage:_LoadRightPage(nIndex)
  Logic.copyLogic:SetTogsIndex(nIndex)
  UIHelper.OpenPage(m_rightPageName[nIndex])
end

function MainLineCopyPage:_StopToggle()
  noticeManager:OpenTipPage(self, 110007)
end

function MainLineCopyPage:_ClickBeforeBack()
  UIHelper.ClosePage("MainLineCopyPage")
end

function MainLineCopyPage:DoOnHide()
  self.m_tabWidgets.tog_leftGroup:ClearToggles()
end

function MainLineCopyPage:DoOnClose()
  self.m_tabWidgets.tog_leftGroup:ClearToggles()
end

return MainLineCopyPage
