QueuePage = class("UI.Queue.QueuePage", LuaUIPage)
local Socket_net = require("socket_net")

function QueuePage:DoInit()
end

function QueuePage:DoOnOpen()
  UIHelper.SetUILock(false)
  self.m_tabParam = self:GetParam()
  self.m_selfPos = self.m_tabParam.SelfPos
  self:_UpdateInfoImp(self.m_tabParam.QueuePos, self.m_tabParam.OnlineMax)
end

function QueuePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateQueue, self._UpdateInfo, self)
  self:RegisterEvent(LuaEvent.PlayerLogin, self._PlayerLogin, self)
  self:RegisterEvent(LuaEvent.DisconnectServer, self._Disconnect, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancle, function()
    self:_CancelQueue()
  end)
end

function QueuePage:_PlayerLogin()
  UIHelper.ClosePage("QueuePage")
end

function QueuePage:_UpdateInfo(ret)
  self:_UpdateInfoImp(ret.QueuePos, ret.OnlineMax)
end

function QueuePage:_UpdateInfoImp(queuePos, isOnlineMax)
  local num = self.m_selfPos - queuePos
  num = math.tointeger(num)
  local numstr = tostring(num)
  if 1000 <= num then
    numstr = ">1000"
  elseif 500 <= num then
    numstr = ">500"
  elseif 100 <= num then
    numstr = ">100"
  end
  local t = 0
  if not isOnlineMax then
    t = math.floor(num / 100 / 60)
  else
    t = math.floor(num / 10 / 60)
  end
  if t < 1 then
    t = 1
  end
  if 60 <= t then
    t = ">60"
  else
    t = tostring(t)
  end
  local s = UIHelper.GetString(5200001)
  self.tab_Widgets.txt_content.text = string.format(s, numstr, t)
end

function QueuePage:_CancelQueue()
  Logic.loginLogic:SetOptOff(true)
  Socket_net.Disconnect()
end

function QueuePage:_Disconnect()
  UIHelper.ClosePage("QueuePage")
  Logic.loginLogic:SetOptOff(false)
end

function QueuePage:DoOnHide()
end

function QueuePage:DoOnClose()
end

return QueuePage
