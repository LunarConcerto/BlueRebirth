local GuildService = class("service.GuildService", Service.BaseService)
local SearchType = {NormalSearch = 1, SubNameSearch = 2}
VerifyType = {ApplyReject = 1, ApplyAccept = 2}

function GuildService:initialize()
  self:_InitHandlers()
end

function GuildService:_InitHandlers()
  self:BindEvent("guild.Create", self._ReceiveCreate, self)
  self:BindEvent("guild.Search", self._ReceiveSearch, self)
  self:BindEvent("guild.GetList", self._ReceiveGetList, self)
  self:BindEvent("guild.Apply", self._ReceiveApply, self)
  self:BindEvent("guild.CancelApply", self._ReceiveCancelApply, self)
  self:BindEvent("guild.Verify", self._ReceiveVerify, self)
  self:BindEvent("guild.Dismiss", self._ReceiveDismiss, self)
  self:BindEvent("guild.Modify", self._ReceiveModify, self)
  self:BindEvent("guild.Appoint", self._ReceiveAppoint, self)
  self:BindEvent("guild.Remove", self._ReceiveRemove, self)
  self:BindEvent("guild.Transfer", self._ReceiveTransfer, self)
  self:BindEvent("guild.Upgrade", self._ReceiveUpgrade, self)
  self:BindEvent("guild.Quit", self._ReceiveQuit, self)
  self:BindEvent("guild.GetApplyList", self._ReceiveGetApplyList, self)
  self:BindEvent("guild.GetMemberList", self._ReceiveGetMemberList, self)
  self:BindEvent("guild.RejectAll", self._ReceiveRejectAll, self)
  self:BindEvent("guild.AcceptAll", self._ReceiveAcceptAll, self)
  self:BindEvent("guild.Publicity", self._ReceivePublicity, self)
  self:BindEvent("guild.SetGuildLevelOfShow", self._ReceiveSetGuildLevelOfShow, self)
  self:BindEvent("guild.Impeach", self._ReceiveImpeach, self)
  self:BindEvent("guild.AcceptAllMsg", self._ReceiveAcceptAllMsg, self)
  self:BindEvent("guild.UpdateOurGuildData", self._ReceiveUpdateOurGuildData, self)
  self:BindEvent("guild.UpdateMyGuildData", self._ReceiveUpdateMyGuildData, self)
  eventManager:RegisterEvent(LuaEvent.GUILD_ENTER_CHECK, self.onGuildBtnInMainMotoClick, self)
end

function GuildService:checkErr(name, err, errmsg, callback)
  logDebug("on ", name, err, errmsg)
  if err ~= 0 then
    if 0 < err then
      local str = UIHelper.GetString(err)
      noticeManager:ShowTip(str)
    else
      noticeManager:ShowTip(err .. " : " .. tostring(errmsg))
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

function GuildService:SendCreate(arg)
  local data = {}
  data.Name = arg.name
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGCREATEGUILD)
  self:SendNetEvent("guild.Create", msg)
end

function GuildService:_ReceiveCreate(ret, state, err, errmsg)
  if self:checkErr("_ReceiveCreate", err, errmsg) then
    return
  end
  self:SendLuaEvent(LuaEvent.MOTO_GUILD_CREATE_SUCCESS)
  noticeManager:ShowTipById(710001)
end

function GuildService:SendSearch(arg)
  local data = {}
  data.GuildId = arg.sGuildId or 0
  data.Name = arg.sName
  data.Type = SearchType.SubNameSearch
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGSEARCHGUILD)
  self:SendNetEvent("guild.Search", msg)
end

function GuildService:_ReceiveSearch(ret, state, err, errmsg)
  if self:checkErr("_ReceiveSearch", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guild_pb.TRETSEARCHGUILD)
  self:SendLuaEvent(LuaEvent.MOTO_SEARCH_RESULT, data)
end

function GuildService:SendGetList(arg)
  local data = {}
  data.FromRank = arg.fromRank
  data.Num = arg.num or 0
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGGETGUILDLIST)
  self:SendNetEvent("guild.GetList", msg)
end

function GuildService:_ReceiveGetList(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetList", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guild_pb.TRETGETGUILDLIST)
  self:SendLuaEvent(LuaEvent.MOTO_GUILD_LIST, data)
end

function GuildService:SendApply(arg)
  local data = {}
  data.GuildId = arg.GuildId
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGAPPLYGUILD)
  self:SendNetEvent("guild.Apply", msg)
end

function GuildService:_ReceiveApply(ret, state, err, errmsg)
  if self:checkErr("_ReceiveApply", err, errmsg) then
    self:SendLuaEvent(LuaEvent.MOTO_BUILD_MOTO_UPDATE)
    return
  end
  self:SendLuaEvent(LuaEvent.GUILD_ApplyOk)
end

function GuildService:SendCancelApply(arg)
  local data = {}
  data.GuildId = arg.GuildId
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGCANCELAPPLY)
  self:SendNetEvent("guild.CancelApply", msg)
end

function GuildService:_ReceiveCancelApply(ret, state, err, errmsg)
  if self:checkErr("_ReceiveCancelApply", err, errmsg) then
    self:SendLuaEvent(LuaEvent.MOTO_BUILD_MOTO_UPDATE)
    return
  end
end

function GuildService:SendVerify(arg)
  local data = {}
  data.Uid = arg.uid
  data.Mode = arg.mode
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGVERIFYGUILD)
  self:SendNetEvent("guild.Verify", msg)
end

function GuildService:_ReceiveVerify(ret, state, err, errmsg)
  if self:checkErr("_ReceiveVerify", err, errmsg) then
    return
  end
  self:SendGetApplyList()
end

function GuildService:SendDismiss(arg)
  self:SendNetEvent("guild.Dismiss", nil)
end

function GuildService:_ReceiveDismiss(ret, state, err, errmsg)
  if self:checkErr("_ReceiveDismiss", err, errmsg) then
    return
  end
  Data.guildData:clearOurGuildInfo()
end

function GuildService:SendModify(arg)
  local data = {}
  data.Name = arg.Name
  data.Emblem = arg.Emblem
  data.Enounce = arg.Enounce
  data.Notice = arg.Notice
  data.Limit = arg.Limit
  data.Frame = arg.Frame
  data.ChatRoom = arg.ChatRoom
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGMODIGUILDINFO)
  self:SendNetEvent("guild.Modify", msg, arg)
end

function GuildService:_ReceiveModify(ret, state, err, errmsg)
  if self:checkErr("_ReceiveModify", err, errmsg) then
    return
  end
  if state.succ_callbackfunc ~= nil then
    state.succ_callbackfunc()
  end
  self:SendLuaEvent(LuaEvent.MOTO_GUILD_MODIFY, state)
end

function GuildService:SendAppoint(arg)
  local data = {}
  data.Uid = arg.Uid
  data.Post = arg.Post
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGAPPOINT)
  self:SendNetEvent("guild.Appoint", msg, arg)
end

function GuildService:_ReceiveAppoint(ret, state, err, errmsg)
  if self:checkErr("_ReceiveAppoint", err, errmsg) then
    return
  end
  if state.Post == Post.Deputy then
    noticeManager:ShowTipById(710052, state.Uname)
  elseif state.Post == Post.Member then
    noticeManager:ShowTipById(710053, state.Uname)
  else
    logError("Undefined Post ", state.Post)
  end
end

function GuildService:SendRemove(arg)
  local data = {}
  data.Uid = arg.Uid
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGREMOVE)
  self:SendNetEvent("guild.Remove", msg)
end

function GuildService:_ReceiveRemove(ret, state, err, errmsg)
  if self:checkErr("_ReceiveRemove", err, errmsg) then
    return
  end
end

function GuildService:SendTransfer(arg)
  local data = {}
  data.Uid = arg.Uid
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGTRANSFER)
  self:SendNetEvent("guild.Transfer", msg)
end

function GuildService:_ReceiveTransfer(ret, state, err, errmsg)
  if self:checkErr("_ReceiveTransfer", err, errmsg) then
    return
  end
end

function GuildService:SendUpgrade(arg)
  self:SendNetEvent("guild.Upgrade", nil)
end

function GuildService:_ReceiveUpgrade(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpgrade", err, errmsg) then
    return
  end
end

function GuildService:SendQuit(arg)
  local ourGuild = Data.guildData:getOurGuildInfo()
  self:SendNetEvent("guild.Quit", nil, {
    GuildName = ourGuild:getName()
  })
end

function GuildService:_ReceiveQuit(ret, state, err, errmsg)
  if self:checkErr("_ReceiveQuit", err, errmsg) then
    return
  end
  noticeManager:ShowTip(string.format("\230\130\168\229\183\178\230\136\144\229\138\159\233\128\128\229\135\186\229\164\167\232\136\176\233\152\159%s\239\188\140\232\175\183\229\191\171\229\142\187\229\175\187\230\137\190\230\150\176\231\154\132\229\164\167\229\174\182\229\186\173\229\144\167~", state.GuildName))
end

function GuildService:SendGetApplyList(arg)
  self:SendNetEvent("guild.GetApplyList", nil)
end

function GuildService:_ReceiveGetApplyList(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetApplyList", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guild_pb.TRETGETGUILDAPPLYINFO)
  self:SendLuaEvent(LuaEvent.MOTO_APPLY_LIST, data)
end

function GuildService:SendGetMemberList(arg)
  self:SendNetEvent("guild.GetMemberList", nil)
end

function GuildService:_ReceiveGetMemberList(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetMemberList", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guild_pb.TRETGETMEMBERINFO)
  self:SendLuaEvent(LuaEvent.MOTO_MEMBER_LIST, data)
end

function GuildService:SendRejectAll(arg)
  self:SendNetEvent("guild.RejectAll", nil)
end

function GuildService:_ReceiveRejectAll(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetMemberList", err, errmsg) then
    return
  end
  self:SendGetApplyList()
end

function GuildService:SendAcceptAll(arg)
  self:SendNetEvent("guild.AcceptAll", nil, arg)
end

function GuildService:_ReceiveAcceptAll(ret, state, err, errmsg)
  if self:checkErr("_ReceiveAcceptAll", err, errmsg) then
    return
  end
end

function GuildService:SendPublicity(arg)
  self:SendNetEvent("guild.Publicity", nil, arg)
end

function GuildService:_ReceivePublicity(ret, state, err, errmsg)
  if self:checkErr("_ReceivePublicity", err, errmsg) then
    return
  end
  noticeManager:ShowTipById(710065)
end

function GuildService:_ReceiveAcceptAllMsg(ret, state, err, errmsg)
  if self:checkErr("_ReceiveAcceptAllMsg", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guild_pb.TGUILDACCEPTALLRET)
  noticeManager:ShowTipById(710059, data.SuccNum)
end

function GuildService:SendSetGuildLevelOfShow(arg)
  local data = {}
  data.Level = arg.Level
  local msg = dataChangeManager:LuaToPb(data, guild_pb.TARGSETGUILDLEVELOFSHOW)
  self:SendNetEvent("guild.SetGuildLevelOfShow", msg, arg)
end

function GuildService:_ReceiveSetGuildLevelOfShow(ret, state, err, errmsg)
  if self:checkErr("_ReceiveSetGuildLevelOfShow", err, errmsg) then
    return
  end
end

function GuildService:SendImpeach(arg)
  self:SendNetEvent("guild.Impeach", nil, arg)
end

function GuildService:_ReceiveImpeach(ret, state, err, errmsg)
  if self:checkErr("_ReceiveImpeach", err, errmsg) then
    return
  end
end

function GuildService:_ReceiveUpdateOurGuildData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateOurGuildData", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guild_pb.TRETGETGUILDINFO)
  Data.guildData:updateOurGuildInfo(data)
end

function GuildService:_ReceiveUpdateMyGuildData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateMyGuildData", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guild_pb.TRETGUILDUSERINFO)
  Data.guildData:updateMyGuildInfo(data)
end

function GuildService:onGuildBtnInMainMotoClick()
  if Data.guildData:inGuild() then
    UIHelper.OpenPage("GuildPage")
  else
    UIHelper.OpenPage("GuildMainPage")
  end
end

return GuildService
