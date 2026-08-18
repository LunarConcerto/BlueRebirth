local ChangeRoomPage = class("UI.Chat.ChangeRoomPage", LuaUIPage)

function ChangeRoomPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function ChangeRoomPage:DoOnOpen()
  local params = self:GetParam()
  local nowRoom = Mathf.ToInt(Data.chatData:GetRoomNum())
  UIHelper.SetText(self.m_tabWidgets.tx_now, "ROOM " .. nowRoom)
  self.m_tabWidgets.input_room.onValueChanged:AddListener(function(msg)
    local res, ischarUp = Logic.chatLogic:MsgCut(msg, 2)
    if ischarUp then
      noticeManager:ShowTip(UIHelper.GetString(920000135))
    end
    self.m_tabWidgets.input_room.text = res
  end)
end

function ChangeRoomPage:RegisterAllEvent()
  local widgets = self.m_tabWidgets
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, function()
    UIHelper.ClosePage("ChangeRoomPage")
  end)
  UGUIEventListener.AddButtonOnClick(widgets.obj_bg, function()
    UIHelper.ClosePage("ChangeRoomPage")
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, function()
    UIHelper.ClosePage("ChangeRoomPage")
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._ChangeRoom, self)
end

function ChangeRoomPage:_ChangeRoom()
  local roomNum = tonumber(self.m_tabWidgets.input_room.text)
  self.m_tabWidgets.input_room.text = ""
  if roomNum == nil then
    noticeManager:ShowTip(UIHelper.GetString(920000135))
    return
  end
  if not (roomNum < 100) or not (0 < roomNum) then
    noticeManager:ShowTip(UIHelper.GetString(220004))
    return
  end
  if roomNum == Data.chatData:GetRoomNum() then
    noticeManager:ShowTip(UIHelper.GetString(920000136))
    return
  end
  Service.chatService:SendChangeWorldChannel(Mathf.ToInt(roomNum + ChatChannel.WorldBase))
  Data.chatData:SetRoomNum(roomNum)
  UIHelper.ClosePage("ChangeRoomPage")
end

function ChangeRoomPage:DoOnHide()
  self.m_tabWidgets.input_room.onValueChanged:RemoveAllListeners()
end

function ChangeRoomPage:DoOnClose()
  self.m_tabWidgets.input_room.onValueChanged:RemoveAllListeners()
end

return ChangeRoomPage
