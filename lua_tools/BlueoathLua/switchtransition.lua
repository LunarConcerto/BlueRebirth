SwitchTransition = class("UI.Transition", LuaUIPage)

function SwitchTransition:DoInit()
end

function SwitchTransition:DoOnOpen()
  local widgets = self:GetWidgets()
  local param = self:GetParam()
  self.sType = param[1]
  self.switchFunc = param[2]
  local obj = self.sType == SwitchType.BlackType and widgets.objBlack or widgets.objWhite
  self.tweenEnter = UIHelper.GetTween(obj, ETweenType.ETT_POSITION, "forward")
  self.tweenLeave = UIHelper.GetTween(obj, ETweenType.ETT_POSITION, "reverse")
  self.tweenEnter:SetOnFinished(function()
    self.switchFunc()
    self.tweenLeave:Play(true)
  end)
  self.tweenLeave:SetOnFinished(function()
    obj:SetActive(false)
    UIHelper.ClosePage("SwitchTransition")
  end)
  widgets.gameObject:SetActive(true)
  obj:SetActive(true)
  self.tweenEnter:Play(true)
end

return SwitchTransition
