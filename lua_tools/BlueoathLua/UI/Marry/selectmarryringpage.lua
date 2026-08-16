local SelectMarryRingPage = class("UI.Marry.SelectMarryRingPage", LuaUIPage)

function SelectMarryRingPage:DoInit()
  self.tabTogs = {
    self.tab_Widgets.tog_ringOne
  }
  self.ringIndex = 1
  SoundManager.Instance:PlayMusic("System|Wedding_RingBox")
end

function SelectMarryRingPage:DoOnOpen()
  self.param = self:GetParam()
  self:_LoadToggle()
  self:_LoadRingInfo()
end

function SelectMarryRingPage:_LoadToggle()
  for i, tog in ipairs(self.tabTogs) do
    self.tab_Widgets.tog_group:RegisterToggle(tog)
  end
  self.tab_Widgets.tog_group:SetActiveToggleIndex(0)
end

function SelectMarryRingPage:RegisterAllEvent()
  local str = string.format(UIHelper.GetString(1500009), self.param[2])
  UIHelper.SetText(self.tab_Widgets.tx_needRing, str)
  UIHelper.SetText(self.tab_Widgets.tx_shuxingNum, UIHelper.GetString(1500018))
end

function SelectMarryRingPage:_LoadRingInfo()
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_back, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_confirm, self._ClickConfirm, self)
  self:RegisterEvent(LuaEvent.MarrySuccess, self._MarrySucess, self)
end

function SelectMarryRingPage:_SwitchTogs(index)
  self.ringIndex = index + 1
end

function SelectMarryRingPage:_ClickConfirm()
  local args = {
    HeroId = self.param[1],
    MarryType = self.ringIndex
  }
  Service.heroService:SendMarry(args)
end

function SelectMarryRingPage:_Dotinfo()
  local shipInfoId = Logic.shipLogic:GetShipInfoIdByHeroId(self.param[1])
  local name = Logic.shipLogic:GetName(shipInfoId)
  local dotinfo = {
    info = "ui_select_ring",
    ship_name = name,
    type = self.ringIndex
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function SelectMarryRingPage:_MarrySucess(...)
  self:_Dotinfo()
  UIHelper.ClosePage("SelectMarryRingPage")
  UIHelper.ClosePage("MarryBookPage")
  UIHelper.OpenPage("MarryProcessPage", {
    self.param[1],
    MarryProcess.Before,
    self.ringIndex
  })
end

function SelectMarryRingPage:_ClickClose()
  SoundManager.Instance:ResumLastMusic()
  UIHelper.ClosePage("SelectMarryRingPage")
end

function SelectMarryRingPage:DoOnHide()
end

function SelectMarryRingPage:DoOnClose()
end

return SelectMarryRingPage
