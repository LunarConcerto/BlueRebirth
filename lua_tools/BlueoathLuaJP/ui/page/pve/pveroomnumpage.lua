local PveRoomNumPage = class("UI.Pve.PveRoomNumPage", LuaUIPage)

function PveRoomNumPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_roomNumber = -1
end

function PveRoomNumPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, function()
    UIHelper.ClosePage("PveRoomNumPage")
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_enter, self.EnterBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_bg, function()
    UIHelper.ClosePage("PveRoomNumPage")
  end, self)
  self:RegisterEvent(LuaEvent.RefreshRoomInfo, self.BackEnterRoomInfo, self)
end

function PveRoomNumPage:DoOnOpen()
  self:InitInputText()
end

function PveRoomNumPage:InitInputText()
  self.m_tabWidgets.input_roomNum.onValueChanged:AddListener(function(number)
    self.m_roomNumber = number
    if number == "-" then
      UIHelper.SetText(self.m_tabWidgets.input_roomNum, "")
    end
  end)
end

function PveRoomNumPage:EnterBtnClick()
  self.m_roomNumber = self.m_roomNumber == "" and -1 or self.m_roomNumber
  if tonumber(self.m_roomNumber) <= 9999 then
    self:ShowMsgByLanguageId(6100049)
  else
    if not Logic.pveRoomLogic:CheckCanJoinRoom() then
      return
    end
    Service.pveRoomService:SendEnterRoom(tonumber(self.m_roomNumber))
  end
end

function PveRoomNumPage:BackEnterRoomInfo(errcode)
  if errcode == nil or errcode == 0 then
    UIHelper.OpenPage("PVERoomPage")
    UIHelper.ClosePage("PveRoomNumPage")
  else
    self:ShowMsgByLanguageId(6100032)
  end
end

function PveRoomNumPage:ShowMsgByLanguageId(id)
  noticeManager:OpenTipPage(self, UIHelper.GetString(id))
end

return PveRoomNumPage
