local TowerMaskPage = class("UI.Tower.TowerMaskPage", LuaUIPage)

function TowerMaskPage:DoInit()
end

function TowerMaskPage:DoOnOpen()
  self.isCopyMax = self.param.isCopyMax
  self.isDeadRoad = self.param.isDeadRoad
  self.page = self.param.page
  local widgets = self:GetWidgets()
  local isDeadRoad = self.isDeadRoad
  local isCopyMax = self.isCopyMax
  widgets.dead_end:SetActive(isDeadRoad and not isCopyMax)
  widgets.max_end:SetActive(isCopyMax)
  local timeLeft = Logic.towerLogic:GetLeftTime()
  if timeLeft <= 0 then
    timeLeft = 0
  end
  local timeFormat = time.getTimeStringFontTwo(timeLeft)
  UIHelper.SetLocText(widgets.tx_reopen, 1700027, timeFormat)
end

function TowerMaskPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_hide, self.btn_hide, self)
end

function TowerMaskPage:btn_hide()
  self.page:CloseSubPage("TowerMaskPage")
end

return TowerMaskPage
