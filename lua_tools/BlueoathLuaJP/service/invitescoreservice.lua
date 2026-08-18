local InviteScoreService = class("servic.InviteScoreService", Service.BaseService)

function InviteScoreService:initialize()
  self:_InitHandlers()
end

function InviteScoreService:_InitHandlers()
  self:BindEvent("invitescore.SetInviteStateByType", self._SetInviteStateByTypeRet, self)
  self:BindEvent("invitescore.CheckAndResetInviteState", self._CheckAndResetInviteStateRet, self)
  self:BindEvent("invitescore.RefreshInviteScore", self._RefreshInviteScore, self)
end

function InviteScoreService:SetInviteStateByType(arg, state)
  arg = dataChangeManager:LuaToPb(arg, invitescore_pb.TINVITESCOREARG)
  self:SendNetEvent("invitescore.SetInviteStateByType", arg)
end

function InviteScoreService:_SetInviteStateByTypeRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError(" _Set InviteStateByTypeRet Ret err " .. errmsg)
    return
  end
end

function InviteScoreService:CheckAndResetInviteState(arg, state)
  log("send reset inviteScore msg :", arg)
  arg = dataChangeManager:LuaToPb(arg, invitescore_pb.TINVITESCOREVERSIONARG)
  self:SendNetEvent("invitescore.CheckAndResetInviteState", arg)
end

function InviteScoreService:_CheckAndResetInviteStateRet(ret, state, err, errmsg)
  log("_CheckAndResetInviteStateRet!!!!!!!!!!!!!!!")
  if err ~= 0 then
    logError(" _Set _CheckAndResetInviteStateRet Ret err " .. errmsg)
    return
  end
end

function InviteScoreService:_RefreshInviteScore(ret, state, err, errmsg)
  if err ~= 0 then
    logError(" _Refresh InviteScore err : " .. errmsg)
    return
  end
  local info = dataChangeManager:PbToLua(ret, invitescore_pb.TINVITESCORERET)
  Data.inviteScoreData:SetData(info)
end

return InviteScoreService
