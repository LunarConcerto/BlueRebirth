local ARkitJoinPage = class("UI.ARkit.ARkitJoinPage", LuaUIPage)

function ARkitJoinPage:DoInit()
end

function ARkitJoinPage:DoOnOpen()
  XR:SetActive(true)
end

function ARkitJoinPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickOK, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancel, self._ClickCancel, self)
  self:RegisterEvent(LuaEvent.JoinRoom, self._JoinRoomCallBack, self)
  self:RegisterEvent("createBattleMsg", self._ReceiveCreateBattle, self)
end

function ARkitJoinPage:_ReceiveCreateBattle()
  noticeManager:ShowTip(UIHelper.GetString(1430010))
  self:_Close()
end

function ARkitJoinPage:_JoinRoomCallBack(errNum)
  if errNum ~= 0 then
    self.tab_Widgets.input_content.text = ""
    noticeManager:ShowTip(UIHelper.GetString(1430014))
  else
    Logic.copyLogic:RegisterARBattleResult()
    self:_Close()
    noticeManager:ShowTip(UIHelper.GetString(1430010))
  end
end

function ARkitJoinPage:_ClickOK()
  local input = self.tab_Widgets.input_content.text
  if not input or input == "" then
    noticeManager:ShowMsgBox(1430012)
  elseif not self:_CheckInputAvild(input) then
    noticeManager:ShowMsgBox(1430013)
  else
    Service.roomService:SendEnterRoom({
      ZoneId = 1,
      Identity = tonumber(input)
    })
  end
end

function ARkitJoinPage:_ClickCancel()
  XR:SetActive(false)
  self:_Close()
end

function ARkitJoinPage:_Close()
  UIHelper.ClosePage("ARkitJoinPage")
end

function ARkitJoinPage:_CheckInputAvild(input)
  local n = tonumber(input)
  if n then
    return true
  end
  return false
end

return ARkitJoinPage
