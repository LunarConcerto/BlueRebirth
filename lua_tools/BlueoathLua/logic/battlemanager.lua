local BattleManager = class("logic.BattleManager")

function BattleManager:initialize()
  self:_RegisterAllEvent()
  self.evenHandle = {
    matchJoinMsg = {},
    createBattleMsg = {},
    matchLeaveMsg = {}
  }
end

function BattleManager:_RegisterAllEvent()
  eventManager:RegisterEvent("matchJoinMsg", self._ReceiveMatchJoin, self)
  eventManager:RegisterEvent("createBattleMsg", self._ReceiveCreateBattle, self)
  eventManager:RegisterEvent("matchLeaveMsg", self._OnReceiveMatchLeave, self)
end

function BattleManager:_UnRegisterAllEvent()
end

function BattleManager:RegisterBattleEvent(event, handle, handleName)
  if self.evenHandle[event] then
    self.evenHandle[event][handleName] = handle
  end
end

function BattleManager:UnRegisterBattleEvent(event, handelName)
  if self.evenHandle[event] then
    self.evenHandle[event][handelName] = nil
  end
end

function BattleManager:LeaveMatch()
  if self.nPvpMatchType == -1 then
    return
  end
  local arg = {
    BattleType = self.nPvpMatchType
  }
  Service.matchService:SendMatchLeave(arg)
end

function BattleManager:_ReceiveMatchJoin(ret)
  for k, v in pairs(self.evenHandle.matchJoinMsg) do
    v:_ReceiveMatchJoin(ret)
  end
end

function BattleManager:_OnReceiveMatchLeave()
  for k, v in pairs(self.evenHandle.matchLeaveMsg) do
    v:_OnReceiveMatchLeave()
  end
end

function BattleManager:_ReceiveCreateBattle(ret)
  ret.selfUid = Data.userData:GetUserData().Uid
  stageMgr:Goto(EStageType.eStagePvpBattle, ret)
  for k, v in pairs(self.evenHandle.createBattleMsg) do
    v:_ReceiveCreateBattle(ret)
  end
end

function BattleManager:JoinArPcp()
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if isHasFleet then
    moduleManager:JumpToFunc(FunctionID.ARKit)
  else
    noticeManager:ShowMsgBox(1430033)
  end
end

function BattleManager:MatchJoin1V1()
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if isHasFleet then
    local arg = {MatchType = 1}
    Service.matchService:SendMatchJoin(arg)
    self.nPvpMatchType = 1
  else
    noticeManager:ShowMsgBox(1430033)
  end
end

function BattleManager:MatchJoin2V2()
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if isHasFleet then
    local arg = {MatchType = 2}
    self.nPvpMatchType = 2
    Service.matchService:SendMatchJoin(arg)
  else
    noticeManager:ShowMsgBox(1430033)
  end
end

function BattleManager:MatchJoin3V3()
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if isHasFleet then
    local arg = {MatchType = 3}
    self.nPvpMatchType = 3
    Service.matchService:SendMatchJoin(arg)
  else
    lnoticeManager:ShowMsgBox(1430033)
  end
end

function BattleManager:MatchJoin5V5()
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if isHasFleet then
    local arg = {MatchType = 4}
    self.nPvpMatchType = 4
    Service.matchService:SendMatchJoin(arg)
  else
    noticeManager:ShowMsgBox(1430033)
  end
end

return BattleManager
