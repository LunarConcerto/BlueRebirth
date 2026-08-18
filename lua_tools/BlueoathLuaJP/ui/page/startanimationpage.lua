local StartAnimationPage = class("ui.page.StartAnimationPage", LuaUIPage)

function StartAnimationPage:DoInit()
  UIHelper.SetUILock(true)
end

function StartAnimationPage:DoOnOpen()
  self.tab_Widgets.obj_effect:SetActive(true)
end

function StartAnimationPage:DoOnClose()
  UIHelper.SetUILock(false)
end

return StartAnimationPage
