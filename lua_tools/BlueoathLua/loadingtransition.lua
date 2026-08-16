LoadingTransition = class("UI.Transition", LuaUIPage)
local TransHelper = require("ui.page.Transition.TransHelper")

function LoadingTransition:DoInit()
end

function LoadingTransition:DoOnOpen()
  local widgets = self:GetWidgets()
  local param = self:GetParam()
  self.nextState = param[1]
  self.isLoading = false
  self.tweenArr = widgets.gameObject:GetComponentsInChildren(typeof(UITweener), true)
  self:BeginTransition()
end

function LoadingTransition:RegisterAllEvent()
  UpdateBeat:Add(self.Update, self)
end

function LoadingTransition:UnregisterAllEvent()
  UpdateBeat:Remove(self.Update, self)
end

function LoadingTransition:DoOnClose()
  if self.closeCo then
    coroutine.stop(self.closeCo)
    self.closeCo = nil
  end
end

function LoadingTransition:Update()
  if self.isLoading then
    self:OnTransition()
  end
end

function LoadingTransition:BeginTransition()
  self.isLoading = true
  local widgets = self:GetWidgets()
  widgets.gameObject:SetActive(true)
  if BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW then
    widgets.slider.gameObject:SetActive(false)
  else
    widgets.slider.gameObject:SetActive(true)
  end
  local loadingPath = configManager.GetData("config_loading")
  local index = TransHelper.GetLoadTexIndex()
  local default = TransitionManager.GetLoadingTexture()
  if 0 < default then
    index = Mathf.Clamp(default, 1, #loadingPath)
    TransitionManager.SetLoadingTexture(0)
  end
  UIHelper.SetImage(widgets.img_top, loadingPath[index].loading_up)
  UIHelper.SetImage(widgets.img_bg_di, loadingPath[index].loading_down)
  local str = TransHelper.GetLoadingTip()
  UIHelper.SetText(widgets.tx_tips, str)
  local rectTran = widgets.rectTran
  rectTran:SetInsetAndSizeFromParentEdge(RectTransform.Edge.Left, 0, Screen.width)
  rectTran:SetInsetAndSizeFromParentEdge(RectTransform.Edge.Top, 0, Screen.height)
  rectTran:SetInsetAndSizeFromParentEdge(RectTransform.Edge.Right, 0, 0)
  rectTran:SetInsetAndSizeFromParentEdge(RectTransform.Edge.Bottom, 0, 0)
  rectTran.anchorMin = Vector2.zero
  rectTran.anchorMax = Vector2.one
  self:ResetUI()
  local tweenArr = self.tweenArr
  for i = 0, tweenArr.Length - 1 do
    tweenArr[i]:Play(true)
  end
  vivoSDKInterface:sendChangeScene(vivoSDKInterface.sceneNames.LOADING_SELF_SCENE)
end

function LoadingTransition:EndTransition()
  Service.cacheDataService:ClearLocalCacheId()
  self:BeforeLeave()
  self:Close()
  self.isLoading = false
end

function LoadingTransition:ResetUI()
  local widgets = self:GetWidgets()
  widgets.slider.value = 0
  widgets.tx_progress.text = self:ToPercent(0)
end

function LoadingTransition:ToPercent(num)
  return string.format("%02d%%", math.floor(num * 100))
end

function LoadingTransition:OnTransition()
  local widgets = self:GetWidgets()
  local stage = stageMgr:GetCurStage()
  local loadingFinish = stageMgr:IsLoading() == false and stage:IsLoading() == false
  if stage.changeState == CS.BabelTime.GD.StageBase.StatgeChangeState.Loading or loadingFinish then
    local progress = stageMgr:GetLoadProgress() * 0.1 + stage:GetLoadProgress() * 0.9
    widgets.slider.value = progress
    widgets.tx_progress.text = self:ToPercent(progress)
  end
  if loadingFinish then
    self:EndTransition()
  end
end

function LoadingTransition:Close()
  if self.closeNow then
    self:CloseNow()
  else
    self:CloseThen()
  end
  self.closeNow = false
end

function LoadingTransition:CloseNow()
  local widgets = self:GetWidgets()
  widgets.slider.value = 0
  widgets.tx_progress.text = self:ToPercent(0)
  widgets.gameObject:SetActive(false)
  UIHelper.ClosePage("LoadingTransition")
end

function LoadingTransition:CloseThen()
  local widgets = self:GetWidgets()
  widgets.slider.value = 1
  widgets.tx_progress.text = self:ToPercent(1)
  self.closeCo = coroutine.start(function()
    self:DisableLoading()
  end)
end

function LoadingTransition:DisableLoading()
  local widgets = self:GetWidgets()
  local stage = stageMgr:GetCurStage()
  if stage:GetLoadProgress() == 1 then
    coroutine.wait(0.1, self.closeCo)
  else
    while stage:GetLoadProgress() < 1 do
      coroutine.wait(0.1, self.closeCo)
    end
  end
  self:ResetUI()
  widgets.slider.gameObject:SetActive(false)
  local tweenArr = self.tweenArr
  for i = 0, tweenArr.Length - 1 do
    tweenArr[i]:Play(false)
  end
  widgets.gameObject:SetActive(false)
  UIHelper.ClosePage("LoadingTransition")
  eventManager:SendEvent(LuaEvent.LoadingTranslateClose, self.nextState)
end

function LoadingTransition:BeforeLeave()
  if CS.BabelTime.Net.NetLogic:GetNetState() == false and self.nextState ~= EStageType.eStageLogin then
    self.closeNow = true
  end
end

return LoadingTransition
