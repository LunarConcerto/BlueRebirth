local TowerOpenPage = class("UI.Tower.TowerOpenPage", LuaUIPage)

function TowerOpenPage:DoInit()
end

function TowerOpenPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local params = self:GetParam() or {}
  UIHelper.SetText(widgets.tx_description, params.text)
  UIHelper.SetImage(widgets.im_title, params.img)
end

function TowerOpenPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_Close, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self.btn_close, self)
end

function TowerOpenPage:btn_close()
  UIHelper.ClosePage("TowerOpenPage")
end

function TowerOpenPage:DoOnClose()
  local params = self:GetParam() or {}
  if params.callback then
    params.callback()
  end
end

return TowerOpenPage
