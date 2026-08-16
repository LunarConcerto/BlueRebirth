local UserService = class("service.UserService", Service.BaseService)
local Socket_net = require("socket_net")

function UserService:initialize()
  self:_InitHandlers()
  self.firstLogin = true
end

function UserService:_InitHandlers()
  self:BindEvent("player.Login", self._ReceiveLogin, self)
  self:BindEvent("player.GetUserList", self._ReceiveUserList, self)
  self:BindEvent("player.CreateUser", self._ReceiveCreateUserFunc, self)
  self:BindEvent("user.UserLogin", self._ReceiveUserLogin, self)
  self:BindEvent("user.GetUserInfo", self._ReceiveUserGetUserInfoFunc, self)
  self:BindEvent("user.UpdateUserInfo", self._UpdateUserInfo, self)
  self:BindEvent("user.UpdateSvrTime", self._UpdateSvrTime, self)
  self:BindEvent("user.SetUserSecretary", self._SetUserSecretary, self)
  self:BindEvent("user.SetUserOrderRecord", self._SetUserOrderRecord, self)
  self:BindEvent("usersvr.GetOtherInfo", self._GetOtherInfo, self)
  self:BindEvent("user.BuyGold", self._BuyResourceRet, self)
  self:BindEvent("user.BuySupply", self._BuyResourceRet, self)
  self:BindEvent("user.Logoff", self._LogOff, self)
  self:BindEvent("user.SetMessage", self._SetMessage, self)
  self:BindEvent("user.KickInfo", self._KickRet, self)
  self:BindEvent("user.GetSupply", self._GetSupply, self)
  self:BindEvent("user.ChangeName", self._GetChangeName, self)
  self:BindEvent("user.SetPlayerHeadFrame", self._SetPlayerHeadFrameRet, self)
  self:BindEvent("user.InitQueueInfo", self._InitQueueInfo, self)
  self:BindEvent("user.UpdateQueueInfo", self._UpdateQueueInfo, self)
  self:BindEvent("user.UpdateLoginTime", self._UpdateLoginTime, self)
  self:BindEvent("user.Refresh", self._RefreshCallBack, self)
  self:BindEvent("user.GetMiniGameScoreRank", self._GetMiniGameScoreRank, self)
  self:BindEvent("user.GetMiniGameScore", self._GetMiniGameScore, self)
  self:BindEvent("user.SetMiniGameScore", self._SetMiniGameScore, self)
  self:BindEvent("user.MedalReplaceReward", self._MedalReplaceReward, self)
end

function UserService:SendLogin(param)
  local state = excMgr.ConnectCount
  self:SendNetEvent("player.Login", param, state)
end

function UserService:SendLogoff()
  self:SendNetEvent("user.Logoff", nil)
end

function UserService:CreateUser(param)
  local state = excMgr.ConnectCount
  self:SendNetEvent("player.CreateUser", param, state)
end

function UserService:UserLogin(param)
  local state = excMgr.ConnectCount
  self:SendNetEvent("user.UserLogin", param, state)
end

function UserService:SendSecretary(param)
  local arg = {SecretaryId = param}
  arg = dataChangeManager:LuaToPb(arg, user_pb.TSETUSERSECRETARYARG)
  self:SendNetEvent("user.SetUserSecretary", arg)
end

function UserService:SendOrderRecord(param)
  param = dataChangeManager:LuaToPb(param, user_pb.TUSERORDERRECORDARG)
  self:SendNetEvent("user.SetUserOrderRecord", param, nil, false)
end

function UserService:SendSetMessage(param)
  local arg = {Message = param}
  arg = dataChangeManager:LuaToPb(arg, user_pb.TSETUSERMSGARG)
  self:SendNetEvent("user.SetMessage", arg)
end

function UserService:SendChangeName(strNewName)
  local arg = {Name = strNewName}
  arg = dataChangeManager:LuaToPb(arg, user_pb.TUSERCHANGENAMEARG)
  self:SendNetEvent("user.ChangeName", arg)
end

function UserService:SetPlayerHeadFrame(arg, state)
  arg = dataChangeManager:LuaToPb(arg, user_pb.TUSERSETPLAYERHEADFRAMEARG)
  self:SendNetEvent("user.SetPlayerHeadFrame", arg)
end

function UserService:_ReceiveLogin(msg, state, err, errmsg)
  if state ~= excMgr.ConnectCount then
    return
  end
  if err == 0 and msg.Ret == "ok" then
    if msg.ErrCode == 0 then
      local currState = excMgr.ConnectCount
      self:SendNetEvent("player.GetUserList", nil, currState)
      self:SendLuaEvent(LuaEvent.PlayerLogin)
    else
      Logic.loginLogic:SetUserKick(msg.ErrCode)
    end
  else
    Socket_net.Disconnect()
    self:SendLuaEvent(LuaEvent.LoginError)
    logError("logicserver exit")
  end
end

function UserService:_ReceiveUserList(msg, state, err, errmsg)
  if state ~= excMgr.ConnectCount then
    return
  end
  if err == 0 then
    self:SendLuaEvent(LuaEvent.GetUserList, msg)
  else
    Socket_net.Disconnect()
    logError("player.GetUserList Fail" .. err)
    self:SendLuaEvent(LuaEvent.LoginError)
  end
end

function UserService:_ReceiveCreateUserFunc(msg, state, err, errmsg)
  if state ~= excMgr.ConnectCount then
    return
  end
  if err == 0 then
    self:SendLuaEvent(LuaEvent.CreaterCharacterSuccess, msg)
  else
    self:SendLuaEvent(LuaEvent.LoginError)
    if err == 1011 then
      noticeManager:ShowTip(UIHelper.GetString(250003))
    elseif err == 1005 then
      noticeManager:ShowTip(UIHelper.GetString(250004))
    elseif err == 1010 then
      noticeManager:ShowTip(UIHelper.GetString(250002))
    end
  end
end

function UserService:_SetMessage(msg, state, err, errmsg)
  if err == -1012 then
    noticeManager:ShowTip(UIHelper.GetString(290001))
  end
end

function UserService:_ReceiveUserLogin(msg, state, err, errmsg)
  if state ~= excMgr.ConnectCount then
    return
  end
  if err == 0 and msg.Ret == "ok" then
    local currState = excMgr.ConnectCount
    self:SendNetEvent("user.GetUserInfo", nil, currState)
  elseif msg.Ret == "ban" then
    local info = dataChangeManager:PbToLua(msg, user_pb.TUSERLOGINRET)
    Socket_net.Disconnect()
    self:SendLuaEvent(LuaEvent.UserBan, info)
    self:SendLuaEvent(LuaEvent.LoginError)
  else
    Socket_net.Disconnect()
    self:SendLuaEvent(LuaEvent.LoginError)
    logError("UserLogin err" .. err)
  end
end

function UserService:_ReceiveUserGetUserInfoFunc(msg, state, err, errmsg)
  if state ~= excMgr.ConnectCount then
    return
  end
  if err == 0 then
    self:SendLuaEvent(LuaEvent.LoginOk, msg)
    eventManager:FireEventToCSharp(LuaCSharpEvent.LoginOk)
  else
    Socket_net.Disconnect()
    self:SendLuaEvent(LuaEvent.LoginError)
    logError("err " .. err .. " " .. "errmsg" .. errmsg)
  end
end

function UserService:_UpdateUserInfo(ret, state, err, errmsg)
  if err == 0 then
    local userInfo = dataChangeManager:PbToLua(ret, user_pb.TGETUSERINFORET)
    if userInfo.Uid == nil and self.firstLogin then
      return
    end
    self.firstLogin = false
    Data.userData:SetData(userInfo)
    self:SendLuaEvent(LuaEvent.UpdataUserInfo)
    if userInfo.Level ~= nil and 0 < userInfo.Level then
      self:SendLuaEvent(LuaEvent.UserLevelUp)
      self:SendLuaEvent(LuaEvent.ShopLevelGift)
      self:SendLuaEvent(LuaEvent.GoodsCopyBattle)
    end
  else
    logError("UpdateUserInfo err" .. err)
  end
end

function UserService:_UpdateSvrTime(ret, state, err, errmsg)
  if err == 0 then
    local timeInfo = dataChangeManager:PbToLua(ret, user_pb.TGETSVRTIMERET)
    if timeInfo == nil or timeInfo.SvrStartTime == nil then
      logError("timeInfo is", timeInfo)
      return
    end
    time.setSvrStartTime(timeInfo.SvrStartTime)
  else
    logError("UpdateSvrTime err" .. err)
  end
end

function UserService:_SetUserSecretary(msg, state, err, errmsg)
  if err ~= 0 then
    logError("SetUserSecretary error" .. err)
  else
    self:SendLuaEvent(LuaEvent.SetSecretaryFinish)
  end
end

function UserService:_SetUserOrderRecord(msg, state, err, errmsg)
  if err ~= 0 then
    logError("Set User Order Record Error" .. err)
  end
end

function UserService:SendGetOtherInfo(param)
  local arg = {Uid = param}
  arg = dataChangeManager:LuaToPb(arg, user_pb.TGETOTHERINFOARG)
  self:SendNetEvent("usersvr.GetOtherInfo", arg)
end

function UserService:_GetOtherInfo(msg, state, err, errmsg)
  if err ~= 0 then
    logError("Get Other Info Error" .. err .. "  " .. errmsg)
  else
    local otherUserInfo = dataChangeManager:PbToLua(msg, user_pb.TGETOTHERUSERINFORET)
    self:SendLuaEvent(LuaEvent.GetOtherUserInfoByUid, otherUserInfo)
  end
end

function UserService:_SendBuyGold()
  self:SendNetEvent("user.BuyGold")
end

function UserService:_SendBuySupply()
  self:SendNetEvent("user.BuySupply")
end

function UserService:_BuyResourceRet(msg, state, err, errmsg)
  if err ~= 0 then
    logError("Buy Aupply File:" .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.UpdataBuyResource)
  end
end

function UserService:_LogOff(msg, state, err, errmsg)
  if err ~= 0 then
    logError("log off err:" .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.LogoffOk)
  end
end

function UserService:_KickRet(msg, state, err, errmsg)
  Logic.loginLogic:SetUserKick(err)
end

function UserService:SendGetSupply(param)
  local arg = {Id = param}
  arg = dataChangeManager:LuaToPb(arg, user_pb.TUSERGETSUPPLYARG)
  self:SendNetEvent("user.GetSupply", arg)
end

function UserService:_GetSupply(msg, state, err, errmsg)
  if err ~= 0 then
    logError(err .. printTable(errmsg))
  end
end

function UserService:_GetChangeName(msg, state, err, errmsg)
  if err ~= 0 then
    logError(err .. printTable(errmsg))
  elseif msg.Ret == "mask" then
    noticeManager:ShowTip(UIHelper.GetString(250004))
  elseif msg.Ret == "dup" then
    noticeManager:ShowTip(UIHelper.GetString(250003))
  elseif msg.Ret == "length" then
    noticeManager:ShowTip(UIHelper.GetString(250002))
  else
    self:SendLuaEvent(LuaEvent.ChangeNameOk)
  end
end

function UserService:_SetPlayerHeadFrameRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError(" _Set _SetPlayerHeadFrame Ret err " .. errmsg)
    return
  end
end

function UserService:_InitQueueInfo(msg, state, err, errmsg)
  if err ~= 0 then
    logError(err .. printTable(errmsg))
  else
    local queueInfo = dataChangeManager:PbToLua(msg, user_pb.TINITQUEUEINFORET)
    self:SendLuaEvent(LuaEvent.StartQueue, queueInfo)
  end
end

function UserService:_UpdateQueueInfo(msg, state, err, errmsg)
  if err ~= 0 then
    logError(err .. printTable(errmsg))
  else
    local queueInfo = dataChangeManager:PbToLua(msg, user_pb.TQUEUEINFORET)
    self:SendLuaEvent(LuaEvent.UpdateQueue, queueInfo)
  end
end

function UserService:SendRefresh(fleetArr)
  local maxpoweridx, minpoweridx = Logic.fleetLogic:GetMaxPower()
  local arg = {MaxPowerIndex = maxpoweridx, MinPowerIndex = minpoweridx}
  arg = dataChangeManager:LuaToPb(arg, user_pb.TREFRESHARG)
  self:SendNetEvent("user.Refresh", arg)
end

function UserService:_RefreshCallBack(msg, state, err, errmsg)
  if err ~= 0 then
    logError("Refresh err:" .. err .. ", errmsg: " .. printTable(errmsg))
  else
    self:SendLuaEvent(LuaEvent.UpdateSignInfo)
  end
end

function UserService:_UpdateLoginTime(msg, state, err, errmsg)
  if err ~= 0 then
    logError(err .. printTable(errmsg))
  else
    Data.userData:SetLoginTime(msg)
    self:SendLuaEvent(LuaEvent.UpdateLoginTime)
  end
end

function UserService:SetMiniGameScore(args)
  args = dataChangeManager:LuaToPb(args, user_pb.TSETMINIGAMESCOREARG)
  self:SendNetEvent("user.SetMiniGameScore", args, args)
end

function UserService:_SetMiniGameScore(ret, state, err, errmsg)
  if err == 0 then
    local tabRet = dataChangeManager:PbToLua(ret, user_pb.TMINIGAMESCORERET) or {}
    Data.miniGameData:SetScore(state.ChapterId, tabRet.Score)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function UserService:GetMiniGameScore(args)
  args = dataChangeManager:LuaToPb(args, user_pb.TGETMINIGAMESCOREARG)
  self:SendNetEvent("user.GetMiniGameScore", args, args)
end

function UserService:_GetMiniGameScore(ret, state, err, errmsg)
  if err == 0 then
    local tabRet = dataChangeManager:PbToLua(ret, user_pb.TMINIGAMESCORERET) or {}
    Data.miniGameData:SetScore(state.ChapterId, tabRet.Score)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function UserService:GetMiniGameScoreRank(args)
  args = dataChangeManager:LuaToPb(args, user_pb.TGETMINIGAMERANKARG)
  self:SendNetEvent("user.GetMiniGameScoreRank", args)
end

function UserService:_GetMiniGameScoreRank(ret, state, err, errmsg)
  if err == 0 then
    local tabRet = dataChangeManager:PbToLua(ret, user_pb.TGETMINIGAMERANKLISTRET) or {}
    self:SendLuaEvent(LuaEvent.GetRank2d, tabRet)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function UserService:_MedalReplaceReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Medal replace failed err:" .. err .. errmsg)
  else
    local medalReplaceInfo = dataChangeManager:PbToLua(ret, user_pb.TMEDALREPLACEREWARD)
    Data.userData:SetMedalReplaceReward(medalReplaceInfo)
  end
end

return UserService
