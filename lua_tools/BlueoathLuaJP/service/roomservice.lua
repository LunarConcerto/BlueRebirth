local RoomService = class("servic.RoomService", Service.BaseService)

function RoomService:initialize()
  self:_InitHandlers()
end

function RoomService:_InitHandlers()
  self:BindEvent("room.UpdateRoom", self.onUpdateRoom, self)
  self:BindEvent("matchsvr.CreateRoom", self.onSendCreateRoom, self)
  self:BindEvent("matchsvr.EnterRoom", self.onSendEnterRoom, self)
  self:BindEvent("matchsvr.ExitRoom", self.onSendExitRoom, self)
  self:BindEvent("room.Ready", self.OnReady, self)
  self:BindEvent("room.Cancel", self.OnCancel, self)
  self:BindEvent("room.SetAutoReady", self.OnSetAutoReady, self)
  self:BindEvent("room.CancelAutoReady", self.OnCancelAutoReady, self)
  self:BindEvent("room.Tactic", self.onTactic, self)
  self:BindEvent("room.Deliver", self.onDeliver, self)
  self:BindEvent("room.SetPassword", self.onSetPassword, self)
  self:BindEvent("room.Kick", self.onKick, self)
  self:BindEvent("room.Kicked", self.onKicked, self)
  self:BindEvent("room.GetChapterInfo", self.onGetChapterInfo, self)
  self:BindEvent("room.CancelFocus", self.onCancelFocus, self)
  self:BindEvent("room.Leave", self.onLeave, self)
  self:BindEvent("room.Invite", self.onInvite, self)
  self:BindEvent("room.Invited", self.onInvited, self)
  self:BindEvent("room.RefuseInvite", self.onRefuseInvite, self)
  self:BindEvent("room.AcceptInvite", self.onAcceptInvite, self)
  self:BindEvent("room.RoomInviteInfo", self.onRoomInviteInfo, self)
  self:BindEvent("room.ChangeChapter", self.onChangeChapter, self)
  self:BindEvent("room.Remind", self.onRemind, self)
  self:BindEvent("room.BeRemind", self.onBeRemind, self)
  self:BindEvent("room.StartMatch", self.onStartMatch, self)
  self:BindEvent("room.StopMatch", self.onStopMatch, self)
  self:BindEvent("room.MatchSuccess", self.onMatchSuccess, self)
end

function RoomService:onUpdateRoom(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onUpdateRoom failed " .. errmsg)
  else
    Data.roomData:SetData(msg)
  end
end

function RoomService:SendCreateRoom(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".CreateRoom", arg)
end

function RoomService:onSendCreateRoom(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onSendCreateRoom failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.CreateRoom)
  end
end

function RoomService:SendEnterRoom(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".EnterRoom", arg)
end

function RoomService:onSendEnterRoom(msg, state, err, errmsg)
  if err ~= 0 then
    if err == 1430014 then
      noticeManager:ShowTipById(1430014)
    end
    logError("onSendEnterRoom failed " .. errmsg)
  else
  end
end

function RoomService:SendExitRoom(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".ExitRoom", arg)
end

function RoomService:onSendExitRoom(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onSendExitRoom failed " .. errmsg)
  else
  end
end

function RoomService:SendTactic(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".Tactic", arg)
end

function RoomService:onTactic(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onSendTactic failed " .. errmsg)
  else
  end
end

function RoomService:SendDeliver(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".Deliver", arg)
end

function RoomService:onSendDeliver(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onSendDeliver failed " .. errmsg)
  else
  end
end

function RoomService:SendSetPassWord(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".SendSetPassWord", arg)
end

function RoomService:onSetPassWord(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onSetPassWord failed " .. errmsg)
  else
  end
end

function RoomService:SendKick(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".Kick", arg)
end

function RoomService:onKick(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onKick failed " .. errmsg)
  else
  end
end

function RoomService:onKicked(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onKicked failed " .. errmsg)
  else
  end
end

function RoomService:SendGetChapterInfo(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".GetChapterInfo", arg)
end

function RoomService:onGetChapterInfo(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onGetChapterInfo failed " .. errmsg)
  else
  end
end

function RoomService:SendCancelFocus(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".CancelFocus", arg)
end

function RoomService:onCancelFocus(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onCancelFocus failed " .. errmsg)
  else
  end
end

function RoomService:SendLeave(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".Leave", arg)
end

function RoomService:onLeave(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onLeave failed " .. errmsg)
  else
  end
end

function RoomService:SendInvite(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TINVITEARG)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".Invite", arg)
end

function RoomService:onInvite(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onInvite failed " .. errmsg)
  else
  end
end

function RoomService:onInvited(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onInvited failed " .. errmsg)
  else
  end
end

function RoomService:SendRefuseInvite(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TINVITEARG)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".RefuseInvite", arg)
end

function RoomService:onRefuseInvite(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onRefuseInvite failed " .. errmsg)
  else
  end
end

function RoomService:SendAcceptInvite(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TINVITEARG)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".AcceptInvite", arg)
end

function RoomService:onAcceptInvite(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onAcceptInvite failed " .. errmsg)
  else
  end
end

function RoomService:onRoomInviteInfo(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onRoomInviteInfo failed " .. errmsg)
  else
  end
end

function RoomService:SendChangeChapter(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".ChangeChapter", arg)
end

function RoomService:onChangeChapter(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onChangeChapter failed " .. errmsg)
  else
  end
end

function RoomService:SendRemind(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".Remind", arg)
end

function RoomService:onRemind(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onRemind failed " .. errmsg)
  else
  end
end

function RoomService:onBeRemind(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onBeRemind failed " .. errmsg)
  else
  end
end

function RoomService:SendStartMatch(arg)
  arg = dataChangeManager:LuaToPb(arg, room_pb.TMATCH)
  self:SendNetEvent("room.StartMatch", arg)
end

function RoomService:onStartMatch(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onStartMatch failed " .. errmsg)
  else
  end
end

function RoomService:SendStopMatch(arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("room.StopMatch", arg)
end

function RoomService:onStopMatch(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onStopMatch failed " .. errmsg)
  else
  end
end

function RoomService:onMatchSuccess(msg, state, err, errmsg)
  if err ~= 0 then
    logError("onMatchSuccess failed " .. errmsg)
  else
  end
end

function RoomService:SendReady(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".Ready", arg)
end

function RoomService:OnReady(msg, state, err, errmsg)
  if err ~= 0 then
    logError("OnReady failed " .. errmsg)
  else
  end
end

function RoomService:SendCancel(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".Cancel", arg)
end

function RoomService:OnCancel(msg, state, err, errmsg)
  if err ~= 0 then
    logError("OnCancel failed " .. errmsg)
  else
  end
end

function RoomService:SetAutoReady(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".SetAutoReady", arg)
end

function RoomService:OnSetAutoReady(msg, state, err, errmsg)
  if err ~= 0 then
    logError("OnSetAutoReady failed " .. errmsg)
  else
  end
end

function RoomService:CancelAutoReady(arg)
  local zoneId = arg.ZoneId
  arg = dataChangeManager:LuaToPb(arg, room_pb.TROOMINFO)
  self:SendNetEvent("matchsvr_" .. zoneId .. ".CancelAutoReady", arg)
end

function RoomService:OnCancelAutoReady(msg, state, err, errmsg)
  if err ~= 0 then
    logError("OnCancelAutoReady failed " .. errmsg)
  else
  end
end

return RoomService
