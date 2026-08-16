local StrategyPage = class("UI.Illustrate.StrategyPage", LuaUIPage)

function StrategyPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function StrategyPage:DoOnOpen()
  local illustrateId = self:GetParam()
  self:_ShowStrategy(illustrateId)
  local id = Logic.illustrateLogic:GetRecommand(illustrateId)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.im_quality, self._ShowIllustrate, self, id)
end

function StrategyPage:_ShowStrategy(illustrateId)
  self:_ShowRecommend(illustrateId)
  self:_ShowApproach(illustrateId)
end

function StrategyPage:_ShowRecommend(illustrateId)
  local widgets = self:GetWidgets()
  local id = Logic.illustrateLogic:GetRecommand(illustrateId)
  local display = {}
  display.icon = Logic.illustrateLogic:GetRecommandIcon(id)
  display.name = Data.illustrateData:GetIllustrateById(id).Name
  display.reason = Logic.illustrateLogic:GetRecommandReason(illustrateId)
  local recommand = Data.illustrateData:GetIllustrateById(id)
  display.quality = recommand.quality
  display.type = recommand.type
  display.get = Logic.illustrateLogic:GetHaveStr(id)
  local get = Logic.illustrateLogic:HaveIllustrate(id)
  widgets.obj_mask:SetActive(not get)
  UIHelper.SetImage(widgets.im_quality, VerCardQualityImg[display.quality])
  UIHelper.SetImage(widgets.im_icon, display.icon)
  UIHelper.SetImage(widgets.im_type, NewCardShipTypeImg[display.type])
  UIHelper.SetText(widgets.tx_name, display.name)
  UIHelper.SetText(widgets.tx_reason, display.reason)
  UIHelper.SetText(widgets.tx_get, display.get)
end

function StrategyPage:_ShowApproach(illustrateId)
  local id = Logic.illustrateLogic:GetRecommand(illustrateId)
  local approachList = Logic.illustrateLogic:GetApproachConfig(id)
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.obj_approach, widgets.trans_approach, #approachList, function(index, tabPart)
    local str = Logic.illustrateLogic:GetApproachStr(approachList[index])
    UIHelper.SetText(tabPart.tx_approach, str)
  end)
end

function StrategyPage:_ShowIllustrate(go, illustrateId)
  if Logic.illustrateLogic:HaveIllustrate(illustrateId) then
    local param = {illustrateId, 3}
    eventManager:SendEvent(LuaEvent.UpdateIllustrate, param)
  else
    local param = {illustrateId, 2}
    eventManager:SendEvent(LuaEvent.UpdateIllustrate, param)
  end
end

function StrategyPage:DoOnHide()
end

function StrategyPage:DoOnClose()
end

return StrategyPage
