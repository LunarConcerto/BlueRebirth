local MatchService = class("service.MatchService", Service.BaseService)

function MatchService:initialize()
  self:_InitHandlers()
end

function MatchService:_InitHandlers()
  self:BindEvent("battle.CreateRoom", self._ReceiveCreateRoom, self)
  self:BindEvent("battle.JoinRoom", self._ReceiveJoinRoom, self)
  self:BindEvent("battle.MatchJoin", self._ReceiveMatchJoin, self)
  self:BindEvent("battle.MatchLeave", self._ReceiveMatchLeave, self)
  self:BindEvent("battle.createBattleInfo", self._ReceiveCreateBattleInfo, self)
  self:BindEvent("battle.CreateMutiBattle", self._ReceiveMutiBattle, self)
end

function MatchService:SendMatchJoin(arg)
  arg = dataChangeManager:LuaToPb(arg, battle_pb.TBATTLEMATCHARG)
  self:SendNetEvent("battle.MatchJoin", arg)
end

function MatchService:SendMatchLeave(arg)
  arg = dataChangeManager:LuaToPb(arg, battle_pb.TBATTLEQUITARG)
  self:SendNetEvent("battle.MatchLeave", arg)
end

function MatchService:_ReceiveMatchJoin(ret, state, err, errmsg)
  if err == 0 then
    local matchData = dataChangeManager:PbToLua(ret, battle_pb.TBATTLEMATCHRET)
    self:SendLuaEvent("matchJoinMsg", battleInfo)
    if matchData.MatchRet == 1 then
      self:SendLuaEvent(LuaEvent.MatchPreSuccess)
    elseif matchData.MatchRet == 2 then
      logError("faild")
      self:SendLuaEvent(LuaEvent.MatchPreFail)
    end
  else
  end
end

function MatchService:_ReceiveMutiBattle(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.HidePveRoomPage)
    local battleInfo = dataChangeManager:PbToLua(ret, battle_pb.TBATTLECREATEMUTIRET)
    Data.copyData:SetMatchPlayerTempData(battleInfo.Arg.BattlePlayerList)
  end
end

function MatchService:_ReceiveCreateBattleInfo(ret, state, err, errmsg)
  if err == 0 then
    local battleInfo = dataChangeManager:PbToLua(ret, match_pb.TBATTLEPUSHMESSAGE, true)
    self:SendLuaEvent("createBattleMsg", battleInfo)
  else
  end
end

function MatchService:_ReceiveMatchLeave(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent("matchLeaveMsg", ret)
  else
  end
end

function MatchService:SendCreateRoom()
  self:SendNetEvent("battle.CreateRoom")
end

function MatchService:SendJoinRoom(roomId)
  local arg = {RoomId = roomId, PassWord = 1}
  arg = dataChangeManager:LuaToPb(arg, battle_pb.TJOINROOMARG)
  self:SendNetEvent("battle.JoinRoom", arg)
end

function MatchService:SendLeaveRoom()
  self:SendNetEvent("battle.LeaveRoom")
end

function MatchService:_ReceiveCreateRoom(ret, state, err, errmsg)
  logError(printTable(ret))
  if err == 0 then
    self:SendLuaEvent(LuaEvent.CreateRoom, ret.RoomId)
  end
end

function MatchService:_ReceiveJoinRoom(ret, state, err, errmsg)
  self:SendLuaEvent(LuaEvent.JoinRoom, err)
end

return MatchService
