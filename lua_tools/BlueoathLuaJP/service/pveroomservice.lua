local PveRoomService = class("service.PveRoomService", Service.BaseService)

function PveRoomService:initialize()
  self:_InitHandlers()
  self.m_errcodes = nil
end

function PveRoomService:_InitHandlers()
  self:BindEvent("matchsvr.CreateRoom", self._CreateRoomRet, self)
  self:BindEvent("matchsvr.EnterRoom", self._EnterRoomRet, self)
  self:BindEvent("matchsvr.ExitRoom", self._ExitRoomRet, self)
  self:BindEvent("matchsvr.DismissRoom", self._DismissRoomRet, self)
  self:BindEvent("matchsvr.Ready", self._ReadyRet, self)
  self:BindEvent("matchsvr.Cancel", self._CancelRet, self)
  self:BindEvent("matchsvr.Kick", self._KickRet, self)
  self:BindEvent("match.UpdateRoomInfo", self._UpdateMatchRoom, self)
  self:BindEvent("matchsvr.UploadTactic", self._UploadTacticRet, self)
  self:BindEvent("matchsvr.GetRoomList", self._GetRoomListRet, self)
  self:BindEvent("matchsvr.SwitchRoomPublicState", self._SwitchRoomStateRet, self)
  self:BindEvent("matchsvr.Start", self._StartRet, self)
  self:BindEvent("match.pveMatchRoomTimeout", self._PveMatchRoomTimeoutRet, self)
end

function PveRoomService:SendCreateRoom(copyId)
  Logic.pveRoomLogic:SetPveTacticNum(copyId)
  local heroInfo = Logic.presetFleetLogic:SendMatchTactic()
  local arg = {CopyId = copyId, HeroList = heroInfo}
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.CreateRoom", arg)
end

function PveRoomService:_CreateRoomRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("CreateRoom err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
  end
  self:SendLuaEvent(LuaEvent.CreatePveRoom, err)
end

function PveRoomService:SendEnterRoom(roomId)
  local heroInfo = Logic.presetFleetLogic:SendMatchTactic()
  local arg = {RoomId = roomId, HeroList = heroInfo}
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.EnterRoom", arg)
end

function PveRoomService:_EnterRoomRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("EnterRoom err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
    self:SendLuaEvent(LuaEvent.RefreshRoomInfo)
  end
  self:SendLuaEvent(LuaEvent.PveRoomEnterRoom, err)
end

function PveRoomService:SendExitRoom(roomId)
  local arg = {RoomId = roomId}
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.ExitRoom", arg)
end

function PveRoomService:_ExitRoomRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("ExitRoom err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
  end
end

function PveRoomService:SendDismissRoom(roomId)
  local arg = {RoomId = roomId}
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.DismissRoom", arg)
end

function PveRoomService:_DismissRoomRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("DismissRoom err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
  end
end

function PveRoomService:SendReady(roomId)
  local arg = {RoomId = roomId}
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.Ready", arg)
end

function PveRoomService:_ReadyRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Ready err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
    self:SendLuaEvent(LuaEvent.PVERoomReady)
  end
end

function PveRoomService:SendCancel(roomId)
  local arg = {RoomId = roomId}
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.Cancel", arg)
end

function PveRoomService:_CancelRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Cancel err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
  end
end

function PveRoomService:SendKick(roomId, kickedUid)
  local arg = {RoomId = roomId, KickedUid = kickedUid}
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.Kick", arg)
end

function PveRoomService:_KickRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Kick err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
  end
end

function PveRoomService:_UpdateMatchRoom(ret, state, err, errmsg)
  if err ~= 0 then
    logError("UpdateMatchRoom err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
    local matchRoomInfo = dataChangeManager:PbToLua(ret, match_pb.TPVEROOMINFORET)
    Data.pveRoomData:SetData(matchRoomInfo)
    self:SendLuaEvent(LuaEvent.UpdatePveRoomInfo)
  end
end

function PveRoomService:SendUploadTactic(heroInfo)
  local arg = {HeroList = heroInfo}
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.UploadTactic", arg)
end

function PveRoomService:_UploadTacticRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("UploadTactic err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
  end
end

function PveRoomService:SendGetRoomList(copyId, state)
  local arg = {CopyId = copyId}
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.GetRoomList", arg, state)
end

function PveRoomService:_GetRoomListRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("GetRoomList err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
    local roomList = dataChangeManager:PbToLua(ret, match_pb.TPVEROOMLIST)
    Data.pveRoomData:SetRoomListData(roomList, state)
  end
end

function PveRoomService:SendSwitchRoomState()
  self:SendNetEvent("matchsvr.SwitchRoomPublicState")
end

function PveRoomService:_SwitchRoomStateRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("SwitchRoomPublicState err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
  end
end

function PveRoomService:SendStart(arg)
  arg = dataChangeManager:LuaToPb(arg, match_pb.TPVEROOMINFOARG)
  self:SendNetEvent("matchsvr.Start", arg)
end

function PveRoomService:_StartRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Start err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
  end
end

function PveRoomService:_PveMatchRoomTimeoutRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Start err " .. err .. "errmsg" .. errmsg)
    self:_PveRoomErrHandler(err)
  else
    self:SendLuaEvent(LuaEvent.PveRoomTimeOut)
  end
end

function PveRoomService:GetCacheId(isMultiple)
  Service.cacheDataService:SendCacheData("copy.StartBase", "PVERoomPage", isMultiple)
end

local PveServiceErrCode = {
  ErrRoomIsNil = 210101,
  ErrRoomAlreadyFull = 210102,
  ErrUserNotInRoom = 210103,
  ErrNoEnoughRoom = 210104,
  ErrRoomId = 210105,
  ErrAlreadyInRoom = 210106,
  ErrAlreadyExistRoom = 210107,
  ErrUserNotAllReady = 210110,
  ErrNoEnoughPvePt = 210112,
  ErrCopyLock = 210113,
  ErrRoomIsFighting = 210114
}

function PveRoomService:_PveRoomErrHandler(err)
  if self.m_errcodes == nil then
    self.m_errcodes = {
      [PveServiceErrCode.ErrRoomIsNil] = 6100049,
      [PveServiceErrCode.ErrRoomAlreadyFull] = 6100050,
      [PveServiceErrCode.ErrUserNotInRoom] = 6100051,
      [PveServiceErrCode.ErrNoEnoughRoom] = 6100052,
      [PveServiceErrCode.ErrRoomId] = 6100053,
      [PveServiceErrCode.ErrAlreadyInRoom] = 6100054,
      [PveServiceErrCode.ErrAlreadyExistRoom] = 6100055,
      [PveServiceErrCode.ErrUserNotAllReady] = 6100057,
      [PveServiceErrCode.ErrNoEnoughPvePt] = 6100058,
      [PveServiceErrCode.ErrCopyLock] = 6100063,
      [PveServiceErrCode.ErrRoomIsFighting] = 6100050
    }
  end
  if self.m_errcodes[err] then
    noticeManager:ShowTip(UIHelper.GetString(self.m_errcodes[err]))
  else
    logError("\228\184\141\233\156\128\232\166\129\230\152\190\231\164\186\230\138\165\233\148\153\228\191\161\230\129\175\231\154\132\233\148\153\232\175\175\231\160\129err:", err)
  end
  if err == PveServiceErrCode.ErrRoomIsNil or err == PveServiceErrCode.ErrAlreadyExistRoom then
    UIHelper.ClosePage("PVERoomPage")
  end
end

return PveRoomService
