local EquipTestResultPage = class("UI.WalkDog.EquipTestResultPage", LuaUIPage)

function EquipTestResultPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_skip, self._OnBtnSkip, self)
end

function EquipTestResultPage:DoOnOpen()
  local param = self.param
  local result = {}
  for k, v in pairs(param.result) do
    result[v.Key] = v.Value
  end
  local curDamage = result.CurDamage
  local maxDamage = result.MaxDamage
  UIHelper.SetText(self.tab_Widgets.txt_curdamage, curDamage)
  UIHelper.SetText(self.tab_Widgets.txt_maxdamage, maxDamage)
end

function EquipTestResultPage:_OnBtnSkip()
  UIHelper.ClosePage(self:GetName())
  local callback = self.param.callback
  callback()
end

return EquipTestResultPage
