local ARkitCreatePage = class("UI.ARkit.ARkitCreatePage", LuaUIPage)

function ARkitCreatePage:DoInit()
end

function ARkitCreatePage:DoOnOpen()
  self:_LoadContent(self.param)
  XR:SetActive(true)
end

function ARkitCreatePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancel, self._ClickCancel, self)
  self:RegisterEvent("createBattleMsg", self._ReceiveCreateBattle, self)
end

function ARkitCreatePage:_ReceiveCreateBattle()
  noticeManager:ShowTip(UIHelper.GetString(1430010))
  UIHelper.ClosePage("ARkitCreatePage")
  Logic.copyLogic:RegisterARBattleResult()
end

function ARkitCreatePage:_LoadContent(num)
  self.tab_Widgets.text_num.text = string.format(UIHelper.GetString(1430006), num)
end

function ARkitCreatePage:_ClickCancel()
  XR:SetActive(false)
  Service.roomService:SendExitRoom({ZoneId = 1})
  UIHelper.ClosePage("ARkitCreatePage")
  noticeManager:ShowTip(UIHelper.GetString(1430009))
end

return ARkitCreatePage
