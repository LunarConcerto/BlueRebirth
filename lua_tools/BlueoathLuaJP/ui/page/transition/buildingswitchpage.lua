BuildingSwitchPage = class("UI.SimpleTransition", LuaUIPage)
local TransHelper = require("ui.page.Transition.TransHelper")

function BuildingSwitchPage:DoInit()
  self.m_task = nil
  self.m_start = 0
end

function BuildingSwitchPage:DoOnOpen()
  local eroot = UIManager.rootEffect
  eroot.gameObject:SetActive(false)
  local param = self:GetParam()
  self.m_task = param.Task
  self:BeginTransition()
  self.m_start = time.getSvrTime()
end

function BuildingSwitchPage:_DoTimer()
end

function BuildingSwitchPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.Build3DLoadOk, self._CloseSelf, self)
end

function BuildingSwitchPage:BeginTransition()
  local widgets = self:GetWidgets()
  widgets.gameObject:SetActive(true)
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
  local ttimer = FrameTimer.New(function()
    self.m_task()
  end, 1, 1)
  ttimer:Start()
end

function BuildingSwitchPage:_CloseSelf()
  local etime = time.getSvrTime()
  local delta = etime - self.m_start
  local least = TransHelper.GetBuildLeast()
  if delta < least then
    local timer = self:CreateTimer(function()
      UIHelper.ClosePage("BuildingSwitchPage")
    end, least - delta, 1, false)
    self:StartTimer(timer)
  else
    UIHelper.ClosePage("BuildingSwitchPage")
  end
end

function BuildingSwitchPage:DoOnClose()
  local eroot = UIManager.rootEffect
  eroot.gameObject:SetActive(true)
end

function BuildingSwitchPage:EndTransition()
end

return BuildingSwitchPage
