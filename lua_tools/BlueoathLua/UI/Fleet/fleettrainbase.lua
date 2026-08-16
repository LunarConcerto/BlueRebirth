local FleetTrainBase = class("UI.Fleet.FleetTrainBase")
local zelf

function FleetTrainBase:Init(owner)
  zelf = owner
end

function FleetTrainBase:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.GetRandFactor, self._GetRandFactorCallback, self)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btnBarrageOpen, self.OnBarrageOpen, self)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btnBarrageClose, self.OnBarrageClose, self)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btnBarrageInput, self.OnBarrageInput, self)
end

function FleetTrainBase:DoOnOpen()
  self:RequireRandomFactors()
  self:InitBarrage()
  self:SetScollText()
  self:RemoveBtnAnim()
end

function FleetTrainBase:InitBarrage()
  zelf.tab_Widgets.btnBarrageOpen.gameObject:SetActive(true)
  local funcOpen = moduleManager:CheckFunc(FunctionID.TrainBarrage, false)
  local state = Logic.chatLogic:GetBarrageState()
  local open = funcOpen and state == 1
  zelf.tab_Widgets.btnBarrageClose.gameObject:SetActive(open)
  zelf.tab_Widgets.btnBarrageInput.gameObject:SetActive(open)
  if open then
    UIHelper.OpenPage("BarragePage", {
      btype = BarrageType.Train,
      sceneId = self.copyId
    })
  end
end

function FleetTrainBase:OnBarrageOpen()
  if moduleManager:CheckFunc(FunctionID.TrainBarrage, true) then
    Logic.chatLogic:SetBarrageState(1)
    zelf.tab_Widgets.btnBarrageClose.gameObject:SetActive(true)
    UIHelper.OpenPage("BarragePage", {
      btype = BarrageType.Train,
      sceneId = self.copyId
    })
    zelf.tab_Widgets.btnBarrageInput.gameObject:SetActive(true)
  end
end

function FleetTrainBase:OnBarrageClose()
  UIHelper.ClosePage("BarragePage")
  zelf.tab_Widgets.btnBarrageClose.gameObject:SetActive(false)
  zelf.tab_Widgets.btnBarrageInput.gameObject:SetActive(false)
  Logic.chatLogic:SetBarrageState(0)
end

function FleetTrainBase:OnBarrageInput()
  eventManager:SendEvent(LuaEvent.BarrageInput)
end

function FleetTrainBase:SetScollText()
  local copyDisplay = configManager.GetDataById("config_copy_display", self.copyId)
  UIHelper.SetText(zelf.tab_Widgets.txtTrainTips, copyDisplay.training_tips)
  local textHeight = zelf.tab_Widgets.txtTrainTips.preferredHeight
  local sizeDelta = zelf.tab_Widgets.txtTrainScroll.sizeDelta
  zelf.tab_Widgets.txtTrainScroll.sizeDelta = Vector2.New(sizeDelta.x, textHeight)
end

function FleetTrainBase:RemoveBtnAnim()
  zelf.tab_Widgets.tweenStrategy:ResetToInit()
  zelf.tab_Widgets.tweenStrategy.duration = 0.01
  zelf.tab_Widgets.tweenStrategy:Play(true)
end

function FleetTrainBase:RequireRandomFactors()
  local copyDisplay = configManager.GetDataById("config_copy_display", self.copyId)
  if not table.empty(copyDisplay.random_factor_sets) then
    Service.copyService:SendGetRandomFactors(self.copyId)
  end
end

function FleetTrainBase:_GetRandFactorCallback(ret)
  self.randFactor = ret
  Logic.copyLogic:SetRandFactors(self.copyId, ret)
end

function FleetTrainBase:DoOnHide()
  eventManager:UnregisterEvent(LuaEvent.GetRandFactor, self._GetRandFactorCallback)
end

function FleetTrainBase:DoOnClose()
  UIHelper.ClosePage("BarragePage")
  Logic.sortLogic:ClearHeroSortTemp()
  eventManager:UnregisterEvent(LuaEvent.GetRandFactor, self._GetRandFactorCallback)
  zelf = nil
end

return FleetTrainBase
