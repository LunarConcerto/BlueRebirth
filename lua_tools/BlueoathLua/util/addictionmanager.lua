local AddictionManager = class("util.AddictionManager")
local Socket_net = require("socket_net")
local AddictionType = {
  Play = 0,
  Normal = 1,
  Replay = 2,
  Force = 3,
  FastUserForce = 4
}
local addictionImpl = {
  [AddictionType.Play] = function(self, ret)
    self:_Play(ret)
  end,
  [AddictionType.Normal] = function(self, ret)
    self:_NormalNotice(ret)
  end,
  [AddictionType.Replay] = function(self, ret)
    self:_ReplayNotice(ret)
  end,
  [AddictionType.Force] = function(self, ret)
    self:_ForceLogout(ret)
  end,
  [AddictionType.FastUserForce] = function(self, ret)
    self:_FastUserForceLogout(ret)
  end
}

function AddictionManager:initialize()
  self.limitTime = nil
  self.noticeTimer = nil
  self.addictionTimer = nil
  self.replayDuration = nil
  self.replayMessage = nil
  self.msgOpen = false
  self.loginOk = false
  eventManager:RegisterEvent(LuaEvent.LoginOk, self._LoginOk, self)
end

function AddictionManager:InitData()
  self.isInit = false
end

function AddictionManager:_Reset()
  self.limitTime = nil
  self.msgOpen = false
  self:_StopTimer()
end

function AddictionManager:_LoginOk()
  if not self.loginOk then
    self.loginOk = true
  else
    self:Addiction()
  end
end

function AddictionManager:_StopTimer()
  if self.noticeTimer ~= nil then
    self.noticeTimer:Stop()
    self.noticeTimer = nil
  end
  if self.addictionTimer ~= nil then
    self.addictionTimer:Stop()
    self.addictionTimer = nil
  end
end

function AddictionManager:Addiction()
  if not self.isInit then
    self.isInit = true
    if platformManager:useSDK() then
      self:_Reset()
      self:_AddictionImp()
    end
  end
end

function AddictionManager:_AddictionImp()
  local time = self.limitTime or 0
  platformManager:Addiction(time, function(ret)
    self:_CallBack(ret)
  end)
end

function AddictionManager:_CallBack(ret)
  if ret then
    if ret.errornu == "1" then
      self:_Reset()
    elseif ret.errornu == "0" then
      self.limitTime = ret.limit_time
      addictionImpl[ret.type](self, ret)
      self:_PlayAddictionTimer()
    end
  end
end

function AddictionManager:_PlayAddictionTimer()
  if self.addictionTimer ~= nil then
    self.addictionTimer:Stop()
  end
  if self.limitTime and self.limitTime > 0 then
    self.addictionTimer = Timer.New(function()
      self:_AddictionImp()
    end, self.limitTime, 1, true)
    self.addictionTimer:Start()
  end
end

function AddictionManager:_OpenMsgBox(msg, callback)
  if self.msgOpen then
    noticeManager:ForceCloseBox()
    self.msgOpen = false
  end
  local tabParams = {}
  
  function tabParams.callback()
    self.msgOpen = false
    if callback ~= nil then
      callback()
    end
  end
  
  self.msgOpen = true
  noticeManager:ShowMsgBox(msg, tabParams, UILayer.NETWORK)
end

function AddictionManager:_OpenFastUserMsgBox(msg)
  if self.msgOpen then
    noticeManager:ForceCloseBox()
    self.msgOpen = false
  end
  local tabParams = {}
  tabParams.msgType = NoticeType.TwoButton
  tabParams.nameCancel = "\232\180\166\230\136\183\229\141\135\231\186\167"
  
  function tabParams.callback(bool)
    self.msgOpen = false
    if bool then
      platformManager:getRealNameState(function(ret)
        if ret and ret.data then
          if platformManager:CheckFastUser() then
            self:_StopTimer()
            Logic.loginLogic:SetOptOff(true)
            Socket_net.Disconnect()
            stageMgr:Goto(EStageType.eStageLaunch, nil, true)
          else
            self:_AddictionImp()
          end
        end
      end)
    else
      self:_OpenFastUserMsgBox(msg)
      platformManager:enterUserCenter()
    end
  end
  
  self.msgOpen = true
  noticeManager:ShowMsgBox(msg, tabParams, UILayer.NETWORK)
end

function AddictionManager:_Play(ret)
end

function AddictionManager:_NormalNotice(ret)
  self:_OpenMsgBox(ret.message)
end

function AddictionManager:_ReplayNotice(ret)
  self.replayDuration = ret.replay_time
  self.replayMessage = ret.message
  self:_ReplayNoticeImp()
end

function AddictionManager:_ReplayNoticeImp()
  self:_OpenMsgBox(self.replayMessage)
  if self.noticeTimer ~= nil then
    self.noticeTimer:Stop()
  end
  self.noticeTimer = Timer.New(function()
    self:_ReplayNoticeImp()
  end, self.replayDuration, 1, true)
end

function AddictionManager:_ForceLogout(ret)
  self:_StopTimer()
  Logic.loginLogic:SetOptOff(true)
  Socket_net.Disconnect()
  self:_OpenMsgBox(ret.message, function()
    stageMgr:Goto(EStageType.eStageLaunch, nil, true)
  end)
end

function AddictionManager:_FastUserForceLogout(ret)
  platformManager:getRealNameState(function(realRet)
    if realRet and realRet.data and platformManager:CheckFastUser() then
      self:_OpenFastUserMsgBox(ret.message)
    end
  end)
end

function AddictionManager:StopAddiction()
  self.isInit = false
  self:_Reset()
end

return AddictionManager
