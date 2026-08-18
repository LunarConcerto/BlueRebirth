local QueueManager = class("util.QueueManager")
local Socket_net = require("socket_net")

function QueueManager:initialize()
  eventManager:RegisterEvent(LuaEvent.StartQueue, self._StartQueue, self)
  eventManager:RegisterEvent(LuaEvent.LoginOk, self._LoginOk, self)
end

function QueueManager:_LoginOk(ret)
  self.loginOk = true
end

function QueueManager:_StartQueue(ret)
  if ret.SelfPos == 0 then
    return
  end
  local nStageType = stageMgr:GetCurStageType()
  if not self.loginOk then
    UIHelper.OpenPage("QueuePage", ret, UILayer.NETWORK)
  else
    Logic.loginLogic:SetOptOff(true)
    Socket_net.Disconnect()
    local tabParams = {
      callback = function(bool)
        self:_ReturnLogin()
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(920000309), tabParams, UILayer.NETWORK)
  end
end

function QueueManager:_ReturnLogin()
  stageMgr:Goto(EStageType.eStageLaunch, nil, true)
end

function QueueManager:CloseQueuePage()
  UIHelper.ClosePage("QueuePage")
end

return QueueManager
