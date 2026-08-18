local FriendService = class("servic.FriendService", Service.BaseService)

function FriendService:initialize()
  self:_InitHandlers()
end

function FriendService:_InitHandlers()
  self:BindEvent("friend.GetFriendMainData", self._GetFriendInfoRet, self)
  self:BindEvent("friend.GetRecommendList", self._GetRecommendRet, self)
  self:BindEvent("friend.Apply", self._ApplyRet, self)
  self:BindEvent("friend.Accept", self._AcceptRet, self)
  self:BindEvent("friend.Refuse", self._RefuseRet, self)
  self:BindEvent("friend.DeleteFriend", self._DeleteFriendRet, self)
  self:BindEvent("friend.SetBlack", self._SetBlackRet, self)
  self:BindEvent("friend.DeleteBlack", self._DeleteBlackRet, self)
  self:BindEvent("friend.SearchUser", self._SearchUserRet, self)
  self:BindEvent("friend.GetFriendList", self._ReceiveGetFriendList, self)
  self:BindEvent("friend.UpdateUserState", self._UpdateUserState, self)
end

function FriendService:checkErr(name, err, errmsg, callback)
  logDebug("on ", name, err, errmsg)
  if err ~= 0 then
    if 0 < err then
      local str = UIHelper.GetString(err)
      noticeManager:ShowTip(str)
    end
    if err < 0 then
      logError(name .. " error", tostring(errmsg))
      return true
    end
    if callback ~= nil then
      callback()
    end
    return true
  end
  return false
end

function FriendService:_GetFriendMainData()
  self:SendNetEvent("friend.GetFriendMainData")
end

function FriendService:_GetFriendInfoRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Get Friend Info failed " .. err .. "" .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, friend_pb.TFRIENDMAININFORET)
    Data.friendData:SetData(info)
    self:SendLuaEvent(LuaEvent.GetFriendsInfo)
  end
end

function FriendService:SendGetRecommend()
  self:SendNetEvent("friend.GetRecommendList", nil)
end

function FriendService:_GetRecommendRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Get Recommend failed " .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, friend_pb.TCOMMONFRIENDGETLISTRET)
    self:SendLuaEvent(LuaEvent.GetRecommendInfo, info.List)
  end
end

function FriendService:SendApply(param)
  local arg = {Uid = param}
  arg = dataChangeManager:LuaToPb(arg, friend_pb.TAPPLYARG)
  self:SendNetEvent("friend.Apply", arg)
end

function FriendService:_ApplyRet(ret, state, err, errmsg)
  self:SendLuaEvent(LuaEvent.ApplyFriend, err)
end

function FriendService:SendAccept(param)
  local arg = {Uid = param}
  arg = dataChangeManager:LuaToPb(arg, friend_pb.TFRIENDCOMMONARG)
  self:SendNetEvent("friend.Accept", arg)
end

function FriendService:_AcceptRet(ret, state, err, errmsg)
  self:SendLuaEvent(LuaEvent.AddFriendSucceed, err)
end

function FriendService:SendRefuse(param)
  local arg = {Uid = param}
  arg = dataChangeManager:LuaToPb(arg, friend_pb.TFRIENDCOMMONARG)
  self:SendNetEvent("friend.Refuse", arg)
end

function FriendService:_RefuseRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError(errmsg)
  end
end

function FriendService:SendDeleteFriend(param)
  local arg = {Uid = param}
  arg = dataChangeManager:LuaToPb(arg, friend_pb.TFRIENDCOMMONARG)
  self:SendNetEvent("friend.DeleteFriend", arg)
end

function FriendService:_DeleteFriendRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError(errmsg)
  end
end

function FriendService:SendSetBlack(param)
  local arg = {Uid = param}
  arg = dataChangeManager:LuaToPb(arg, friend_pb.TFRIENDCOMMONARG)
  self:SendNetEvent("friend.SetBlack", arg)
end

function FriendService:_SetBlackRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:SendLuaEvent(LuaEvent.SetFriendBlackFail, err)
  else
    self:SendLuaEvent(LuaEvent.SetFriendBlackSuccess)
  end
end

function FriendService:SendDeleteBlack(param)
  local arg = {Uid = param}
  arg = dataChangeManager:LuaToPb(arg, friend_pb.TFRIENDCOMMONARG)
  self:SendNetEvent("friend.DeleteBlack", arg)
end

function FriendService:_DeleteBlackRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError(errmsg)
  else
    self:SendLuaEvent("SucessDeleteUserFromBlack")
  end
end

function FriendService:SendSearchUser(param)
  local arg = dataChangeManager:LuaToPb(param, friend_pb.TSEARCHARG)
  self:SendNetEvent("friend.SearchUser", arg)
end

function FriendService:_SearchUserRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:SendLuaEvent(LuaEvent.FriendSearchUser, err)
  else
    local info = dataChangeManager:PbToLua(ret, friend_pb.TCOMMONFRIENDGETLISTRET)
    self:SendLuaEvent(LuaEvent.FriendSearchUser, info)
  end
end

function FriendService:SendGetFriendList(arg)
  self:SendNetEvent("friend.GetFriendList", nil, arg)
end

function FriendService:_ReceiveGetFriendList(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetFriendList", err, errmsg) then
    return
  end
  logDebug("ReceiveGetFriendList ", traceTable(ret))
  local data = dataChangeManager:PbToLua(ret, friend_pb.TCOMMONFRIENDGETLISTRET)
  self:SendLuaEvent(LuaEvent.Friend_GetFriendList, data)
end

function FriendService:_UpdateUserState(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Friend Service update user state failed: " .. err)
  else
    local info = dataChangeManager:PbToLua(ret, friend_pb.TUSERSTATERET)
    Data.friendData:SetFriendStatus(info.Type, info.Uid)
    self:SendLuaEvent(LuaEvent.UpdateUserOnLineState, info)
  end
end

return FriendService
