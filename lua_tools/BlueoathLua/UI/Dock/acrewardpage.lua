local AcRewardPage = class("UI.Dock.AcRewardPage", LuaUIPage)
local testParam = {
  merits = 125,
  dayIndex = 133,
  dayTotal = 542,
  percent = 50,
  callback = nil
}
local eff1Path = "effects/prefabs/ui/eff_ui_gongxun_result_01"
local eff2Path = "effects/prefabs/ui/eff_ui_gongxun_result_02"
local sliderDurationBase = 2

function AcRewardPage:DoInit()
  self.m_tabWidgets = nil
end

function AcRewardPage:DoOnOpen()
  self.m_param = self:GetParam() or testParam
  self:Refresh(self.m_param)
end

function AcRewardPage:Refresh(param)
  local widgets = self:GetWidgets()
  local num = 100
  widgets.slr_res.value = 1 - num * 0.01
  UIHelper.SetText(widgets.tx_num, string.format("%.0f%%", num))
  UIHelper.SetText(widgets.tx_thisnum, Mathf.ToInt(param.merits))
  UIHelper.SetText(widgets.tx_todaymax, Mathf.ToInt(param.dayIndex))
  UIHelper.SetText(widgets.tx_servermax, Mathf.ToInt(param.dayTotal))
  self:_ShowPercentEff(param)
end

function AcRewardPage:_ShowPercentEff(param)
  local widgets = self:GetWidgets()
  local eff1 = self:CreateUIEffect(eff1Path, widgets.eff_base)
  eff1.transform.localPosition = Vector3.New(0, -28, 0)
  local num = param.percent == -1 and 100 or Mathf.Clamp(param.percent, 0, 100)
  res = 1 - num * 0.01
  local time = sliderDurationBase
  local timer = self:CreateTimer(function()
    self:_UpdatePercent()
  end, 0.1, -1, false)
  local seq = UISequence.NewSequence(widgets.slr_res.gameObject)
  seq:Append(widgets.slr_res:TweenValue(0, res, time))
  seq:AppendCallback(function()
    self:DestroyEffect(eff1)
    self:StopTimer(timer)
    UIHelper.SetText(widgets.tx_num, string.format("%.0f%%", num))
    local eff2 = self:CreateUIEffect(eff2Path, widgets.eff_base)
    eff2.transform.localPosition = Vector3.New(0, -11.5, 0)
    SoundManager.Instance:PlayMusic("Effect_Eff_gongxunflash")
  end)
  self:StartTimer(timer)
  seq:Play(true)
end

function AcRewardPage:_UpdatePercent()
  local widgets = self:GetWidgets()
  local num = (1 - widgets.slr_res.value) * 100
  UIHelper.SetText(widgets.tx_num, string.format("%.0f%%", num))
end

function AcRewardPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._Close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_skip, self._Close, self)
end

function AcRewardPage:_Close()
  UIHelper.ClosePage("AcRewardPage")
end

function AcRewardPage:DoOnHide()
end

function AcRewardPage:DoOnClose()
  if self.m_param.callback then
    self.m_param.callback()
    self.m_param.callback = nil
  end
end

return AcRewardPage
