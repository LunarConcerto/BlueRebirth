local ExceptionManager = class("util.ExceptionManager")
local Socket_net = require("socket_net")
ExceptionManager.ConnectCount = 0

function ExceptionManager:initialize()
  eventManager:RegisterEvent(LuaCSharpEvent.WaitOverBackLogin, self._SendNetMsgOvertime, self)
  eventManager:RegisterEvent(LuaEvent.CheckHotUpdate, self._HotUpdate, self, param)
  eventManager:RegisterEvent(LuaEvent.UserBan, self._OpenBanHint, self)
  eventManager:RegisterEvent(LuaEvent.ReconnectNetworkExc, self._OpenLogin)
end

function ExceptionManager:_OpenLogin()
  UIHelper.SetUILock(false)
  addictionManager:StopAddiction()
  if not Logic.loginLogic:GetOptOff() then
    log("open reconnect page")
    eventManager:FireEventToCSharp(LuaCSharpEvent.OnWaitEnd)
    queueManager:CloseQueuePage()
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          excMgr:_ClickTrue()
        else
          excMgr:_ClickClose()
        end
      end,
      nameOk = UIHelper.GetString(420004),
      nameCancel = UIHelper.GetString(420005)
    }
    noticeManager:ShowMsgBox(110015, tabParams, UILayer.NETWORK)
  end
end

function ExceptionManager:_BackLogin()
  Logic.loginLogic:SetOptOff(true)
  UIHelper.SetUILock(false)
  local param = {
    callback = function(bool)
      excMgr:_ClickClose()
    end
  }
  noticeManager:ShowMsgBox(420003, param, UILayer.NETWORK)
end

function ExceptionManager:_UserKick()
  addictionManager:StopAddiction()
  Logic.loginLogic:SetOptOff(true)
  UIHelper.SetUILock(false)
  local kickType = Logic.loginLogic:GetUserKickType()
  local str = ""
  if kickType == KickType.ErrorKickByWeb then
    str = UIHelper.GetString(420002)
  elseif kickType == KickType.ErrorRegMax then
    str = UIHelper.GetString(420015)
  else
    str = UIHelper.GetString(420001)
  end
  local param = {
    callback = function(bool)
      excMgr:_ClickClose()
    end
  }
  noticeManager:ShowMsgBox(str, param, UILayer.NETWORK)
end

function ExceptionManager:_OpenBanHint(msg)
  Logic.loginLogic:SetOptOff(true)
  UIHelper.SetUILock(false)
  local endTime = time.formatTimeToYMDHMS(msg.BanTime)
  local param = {
    callback = function(bool)
      excMgr:_ClickClose()
    end
  }
  local message = string.format(UIHelper.GetString(920000306), endTime)
  if msg.BanMsg == nil or msg.BanMsg == "" or tonumber(msg.BanMsg) == nil then
  else
    message = string.format(UIHelper.GetString(920000621), UIHelper.GetString(420019), endTime)
  end
  noticeManager:ShowMsgBox(message, param)
end

function ExceptionManager:_SendNetMsgOvertime()
  local curStage = stageMgr:GetCurStageType()
  if curStage == EStageType.eStageSimpleBattle or curStage == EStageType.eStagePvpBattle then
  else
    self:_BackLogin()
  end
end

function ExceptionManager:_ClickClose()
  stageMgr:Goto(EStageType.eStageLaunch, nil, true)
end

function ExceptionManager:_ClickTrue()
  UIHelper.SetUILock(true)
  ExceptionManager.ConnectCount = ExceptionManager.ConnectCount + 1
  Logic.loginLogic:_Reconnect()
  GR.guideHub:exceptionCheck()
end

return ExceptionManager
