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
    noticeManager:ShowMsgBox("\228\186\178\231\136\177\231\154\132\230\140\135\230\140\165\229\174\152\239\188\140\229\189\147\229\137\141\230\156\141\229\138\161\229\153\168\230\173\163\229\156\168\230\142\146\233\152\159\239\188\140\232\175\183\232\191\148\229\155\158\231\153\187\229\189\149\231\149\140\233\157\162\233\135\141\230\150\176\231\153\187\229\189\149~~", tabParams, UILayer.NETWORK)
  end
end

function QueueManager:_ReturnLogin()
  stageMgr:Goto(EStageType.eStageLaunch, nil, true)
end

function QueueManager:CloseQueuePage()
  UIHelper.ClosePage("QueuePage")
end

return QueueManager
