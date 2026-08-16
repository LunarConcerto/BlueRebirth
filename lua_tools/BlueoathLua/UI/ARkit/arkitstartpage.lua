local ARkitStartPage = class("UI.ARkit.ARkitStartPage", LuaUIPage)

function ARkitStartPage:DoInit()
end

function ARkitStartPage:DoOnOpen()
end

function ARkitStartPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_join, self._ClickJoin, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_create, self._ClickCreate, self)
  self:RegisterEvent(LuaEvent.CreateRoom, self._CreateRoomSuccess, self)
end

function ARkitStartPage:_CreateRoomSuccess(num)
  self:_Close()
  num = Data.roomData:GetIdentity()
  UIHelper.OpenPage("ARkitCreatePage", math.tointeger(num))
end

function ARkitStartPage:_ClickJoin()
  self:_Close()
  UIHelper.OpenPage("ARkitJoinPage")
end

function ARkitStartPage:_ClickCreate()
  Service.roomService:SendCreateRoom({ZoneId = 1, ChapterId = 1})
end

function ARkitStartPage:_ClickClose()
  self:_Close()
end

function ARkitStartPage:_Close()
  UIHelper.ClosePage("ARkitStartPage")
end

return ARkitStartPage
