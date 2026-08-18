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
  self:BindEvent("guildwar.GetGuildwarInfo", self._ReceiveGuildWarInfo, self)
  self:BindEvent("guildwar.GetRankList", self._ReceiveGuildWarRankInfo, self)
  self:BindEvent("guildwar.GetBaseInfo", self._ReceiveBaseInfo, self)
  self:BindEvent("guildwar.GetHeroLockInfo", self._ReceiveHeroLockInfo, self)
  self:BindEvent("guildwar.GetBattleReport", self.ReceiveGuildWarReport, self)
  self:BindEvent("guildwar.BattleReport", self.ReceiveGuildWarOneReport, self)
  self:BindEvent("guildwar.GetGuildReward", self.ReceiveGuildWarBossReward, self)
  self:BindEvent("guildwar.GetRankUserList", self.ReceiveGuildWarPersonRank, self)
  self:BindEvent("guildwar.GetHaveScores", self.ReceiveGetHaveScores, self)
  self:BindEvent("guildwar.GetHaveGuildReward", self.ReceiveHaveGuildWarReward, self)
  self:BindEvent("guildwar.GetGuildGradeId", self.ReceiveGetGuildWarGradeId, self)
  self:BindEvent("guildwar.UpdateBaseInfo", self.ReceiveUpdateGuildWarBaseInfo, self)
  eventManager:RegisterEvent(LuaEvent.GUILD_ENTER_CHECK, self.onGuildBtnInMainMotoClick, self)
  self:BindEvent("guildOffer.GetGuildOffer", self.BackGuildOffer, self)
  self:BindEvent("guildOfferUser.GetGuildOfferUser", self.BackGuildOfferUserInfo, self)
  self:BindEvent("guildOffer.GuildOffer", self.BackGuildOfferRes, self)
  self:BindEvent("guildOffer.GuildOfferUser", self.BackGuildOfferRes, self)
  self:BindEvent("guildOffer.AddOffer", self.BackGuildOfferTaskInfo, self)
  self:BindEvent("guildOffer.AbandonOffer", self.BackGuildOfferTaskInfo, self)
  self:BindEvent("guildOffer.ReceiveOfferRewardPerson", self.ReceivePointsRewardData, self)
  self:BindEvent("guildOffer.ReceiveOfferRewardGuild", self.ReceivePointsRewardData, self)
  self:BindEvent("guildOffer.ReceiveOfferRewardAll", self.ReceivePointsRewardData, self)
  self:BindEvent("guildOffer.BuyOfferCount", self.BackBuyOfferCountRes, self)
  self:BindEvent("guildOffer.GetRankList", self.ReceiveGuildOfferRankListRet, self)
  self:BindEvent("guildofferrank.GetGuildRankList", self.ReceiveGuildOfferGuildRankListRet, self)
  self:BindEvent("guildbox.GuildData", self.ReceiveGuildBoxGuildData, self)
  self:BindEvent("guildbox.UserData", self.ReceiveGuildBoxUserData, self)
  self:BindEvent("guildbox.UserAllList", self.ReceiveGuildBoxUserAllList, self)
  self:BindEvent("guildbox.BoxShareAdd", self.ReceiveGuildBoxShareAdd, self)
  self:BindEvent("guildbox.BoxTaskAdd", self.ReceiveGuildBoxTaskAdd, self)
  self:BindEvent("guildbox.PickShareBox", self.ReceivePicGuildBoxRes, self)
  self:BindEvent("guildbox.PickTaskBox", self.ReceivePicGuildBoxRes, self)
  self:BindEvent("guildbox.PickPointsBox", self.ReceivePicPointsGuildBoxRes, self)
  self:BindEvent("guildbox.PushMessage", self.ReceiveGuildBoxPushMessage, self)
  self:BindEvent("guildbox.PickAllTaskBox", self.ReceivePickAllTaskBoxRes, self)
  self:BindEvent("guildbigactivity.UserData", self.ReceiveBigActivityUserData, self)
  self:BindEvent("guildbigactivity.GuildRateData", self.ReceiveBigActivityGuildRateData, self)
  self:BindEvent("guildbigactivityrank.GetGuildRankList", self.ReceiveBigActivityGuildRankList, self)
end

function GuildService:checkErr(name, err, errmsg, callback)
  logDebug("on ", name, err, errmsg)
  if err ~= 0 then
    if 0 < err then
      local str = UIHelper.GetString(err)
      if str ~= "" then
        noticeManager:ShowTip(str)
      end
    else
      noticeManager:ShowTip(err .. " : " .. tostring(errmsg))
    end
    if err < 0 then
      logError(name .. " error", tostring(errmsg))
      if err == -1900024 then
        noticeManager:ShowTip(UIHelper.GetString(4200001))
      elseif err == -1000106 then
        noticeManager:ShowTip("\231\142\169\229\174\182\230\180\187\229\138\168\229\188\128\229\144\175\229\144\142\229\138\160\229\133\165\229\133\172\228\188\154\239\188\140\230\151\160\230\179\149\229\143\130\229\138\160\230\180\187\229\138\168\239\188\129")
      end
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
  noticeManager:ShowTip(string.format(UIHelper.GetString(920000081), state.GuildName))
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
  Data.guildData:updateGuildMemberData(data)
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

function GuildService:SendGuildWarInfo()
  self:SendNetEvent("guildwar.GetGuildwarInfo")
end

function GuildService:SendGetGuildWarBaseInfo(baseId)
  local args = {BaseId = baseId}
  local pbArgs = dataChangeManager:LuaToPb(args, guildwar_pb.TGUILDBASEINFOARG)
  self:SendNetEvent("guildwar.GetBaseInfo", pbArgs)
end

function GuildService:SendGetGuildWarHeroLockInfo()
  self:SendNetEvent("guildwar.GetHeroLockInfo")
end

function GuildService:_ReceiveGuildWarInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGuildWarInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TGUILDWARINFORET)
  Data.guildData:updateGuildWarInfo(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildWarInfo)
end

function GuildService:SendGuildWarRankInfo(fromIndex, toIndex)
  local args = {FromRankNo = fromIndex, ToRankNo = toIndex}
  local pbArgs = dataChangeManager:LuaToPb(args, guildwar_pb.TGUILDWARRANKLISTARG)
  self:SendNetEvent("guildwar.GetRankList", pbArgs)
end

function GuildService:_ReceiveGuildWarRankInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGuildWarRankInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TGUILDWARRANKLISTRET)
  Data.guildData:updateRankData(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildWarRank, true)
end

function GuildService:SendGuildWarReport()
  self:SendNetEvent("guildwar.GetBattleReport")
end

function GuildService:ReceiveGuildWarReport(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildWarReport", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TBATTLEREPORTRET)
  Data.guildData:updateGuildWarReportList(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildWarReport, true)
end

function GuildService:ReceiveGuildWarOneReport(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildWarOneReport", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TBATTLEREPORTINFO)
  Data.guildData:updateGuildWarReportOne(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildWarReport, true)
end

function GuildService:SendGuildWarBossReward()
  self:SendNetEvent("guildwar.GetGuildReward")
end

function GuildService:ReceiveGuildWarBossReward(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildWarBossReward", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TGUILDWARREWARDLISTRET)
  if data and data.list and #data.list > 0 then
    self:SendLuaEvent(LuaEvent.ShowGuildWarBossReward, data.list)
  end
end

function GuildService:SendGuildWarPersonRank()
  self:SendNetEvent("guildwar.GetRankUserList")
end

function GuildService:ReceiveGuildWarPersonRank(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildWarPersonRank", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TGUILDWARUSERRANKLISTRET)
  Data.guildData:updatePersonRankData(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildWarRank, false)
end

function GuildService:SendGetHaveScores(uid)
  local arg = {DestUid = uid}
  local msg = dataChangeManager:LuaToPb(arg, guildwar_pb.TGUILDWARHAVESCORESARG)
  self:SendNetEvent("guildwar.GetHaveScores", msg)
end

function GuildService:ReceiveGetHaveScores(ret, state, err, errmsg)
  if self:checkErr("ReceiveGetHaveScores", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TGUILDWARHAVESCORESRET)
  self:SendLuaEvent(LuaEvent.SetGuildWarHaveScore, data)
end

function GuildService:SendHaveGuildWarReward()
  self:SendNetEvent("guildwar.GetHaveGuildReward")
end

function GuildService:ReceiveHaveGuildWarReward(ret, state, err, errmsg)
  if self:checkErr("ReceiveHaveGuildWarReward", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TGUILDWARHAVEREWARDRET)
  Data.guildData:updateHaveGuildWarReward(data)
  self:SendLuaEvent(LuaEvent.CheckHaveGuildWarReward)
end

function GuildService:ReceiveGetGuildWarGradeId(ret, state, err, errmsg)
  if self:checkErr("ReceiveGetGuildWarGradeId", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TGUILDWARGRADEIDRET)
  Data.guildData:updateGuildWarGradeId(data)
end

function GuildService:ReceiveUpdateGuildWarBaseInfo(ret, state, err, errmsg)
  if self:checkErr("UpdateGuildWarBaseInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TGUILDWARBASEINFORET)
  Data.guildData:updateGuildWarBaseInfo(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildWarBaseInfo, data.BaseId)
end

function GuildService:_ReceiveBaseInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGuildWarRankInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.TGUILDBASEINFORET)
  self:SendLuaEvent(LuaEvent.GetGuildWarBaseInfo, data)
end

function GuildService:_ReceiveHeroLockInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGuildWarRankInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildwar_pb.THEROLOCKINFORET)
  if data then
    Data.fleetData:SaveGuildWarLockData(data.HeroList)
    self:SendLuaEvent(LuaEvent.UpdateTowerInfo)
  end
end

function GuildService:onGuildBtnInMainMotoClick()
  if Data.guildData:inGuild() then
    UIHelper.OpenPage("GuildPage")
  else
    UIHelper.OpenPage("GuildMainPage")
  end
end

function GuildService:SendGuildOfferInfo()
  self:SendNetEvent("guildOffer.GuildOffer")
end

function GuildService:SendGuildOfferUserInfo()
  self:SendNetEvent("guildOffer.GuildOfferUser")
end

function GuildService:SendGuildAddOffer(index, id)
  local args = {TaskIndex = index, TaskId = id}
  args = dataChangeManager:LuaToPb(args, guildOffer_pb.TADDNEWOFFERARG)
  self:SendNetEvent("guildOffer.AddOffer", args)
end

function GuildService:SendGuildAbandonOffer(id)
  local args = {TaskId = id}
  args = dataChangeManager:LuaToPb(args, guildOffer_pb.TABANDONNEWOFFERARG)
  self:SendNetEvent("guildOffer.AbandonOffer", args)
end

function GuildService:SendReceiveOfferRewardPerson(levelId)
  local args = {LevelId = levelId}
  args = dataChangeManager:LuaToPb(args, guildOffer_pb.TRECEIVELEVELREWARD)
  self:SendNetEvent("guildOffer.ReceiveOfferRewardPerson", args)
end

function GuildService:SendReceiveOfferRewardGuild(levelId)
  local args = {LevelId = levelId}
  args = dataChangeManager:LuaToPb(args, guildOffer_pb.TRECEIVELEVELREWARD)
  self:SendNetEvent("guildOffer.ReceiveOfferRewardGuild", args)
end

function GuildService:SendReceiveAllGOReward()
  self:SendNetEvent("guildOffer.ReceiveOfferRewardAll")
end

function GuildService:SendBuyOffer(num)
  local args = {Num = num}
  args = dataChangeManager:LuaToPb(args, guildOffer_pb.TBUYOFFERCOUNT)
  self:SendNetEvent("guildOffer.BuyOfferCount", args)
end

function GuildService:ReceivePointsRewardData(ret, state, err, errmsg)
  if self:checkErr("ReceivePointsRewardData", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, commonreward_pb.TCOMMONARRREWARD)
  self:SendLuaEvent(LuaEvent.ReceiveRewardBack, data)
end

function GuildService:BackGuildOffer(ret, state, err, errmsg)
  if self:checkErr("BackGuildOffer", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildOffer_pb.TGUILDOFFER)
  Data.guildOfferData:SetOfferData(data)
  self:SendLuaEvent(LuaEvent.UpdateUserPoint)
end

function GuildService:BackGuildOfferUserInfo(ret, state, err, errmsg)
  if self:checkErr("BackGuildOfferUserInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildOffer_pb.TGUILDOFFERUSER)
  Data.guildOfferData:SetOfferData(data)
  self:SendLuaEvent(LuaEvent.UpdateUserPoint)
end

function GuildService:BackGuildOfferCommonInfo(ret, state, err, errmsg)
  if self:checkErr("BackGuildOfferCommonInfo", err, errmsg) then
    return
  end
end

function GuildService:BackGuildOfferTaskInfo(ret, state, err, errmsg)
  if self:checkErr("BackGuildOfferTaskInfo", err, errmsg) then
    return
  end
  self:SendLuaEvent(LuaEvent.UpdateUserGOTaskInfo)
end

function GuildService:BackGuildOfferRes(ret, state, err, errmsg)
  if self:checkErr("BackGuildOfferRes", err, errmsg) then
    return
  end
end

function GuildService:BackBuyOfferCountRes(ret, state, err, errmsg)
  if self:checkErr("BackBuyOfferCountRes", err, errmsg) then
    return
  end
  self:SendLuaEvent(LuaEvent.UpdateUserGOTaskCount)
end

function GuildService:SendGuildOfferRankList(fidx, tidx)
  local arg = {FromRankNo = fidx, ToRankNo = tidx}
  local msg = dataChangeManager:LuaToPb(arg, guildOffer_pb.TGUILDOFFERRANKLISTARG)
  self:SendNetEvent("guildOffer.GetRankList", msg)
end

function GuildService:ReceiveGuildOfferRankListRet(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildOfferRankListRet", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildOffer_pb.TGUILDOFFERRANKLISTRET)
  if data == nil then
    return
  end
  Data.guildData:updateGuildWarOfferRankList(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildWarOfferRankList)
end

function GuildService:SendGuildOfferGuildRankList(fidx, tidx)
  local arg = {FromRankNo = fidx, ToRankNo = tidx}
  local msg = dataChangeManager:LuaToPb(arg, guildOffer_pb.TGUILDOFFERGUILDRANKLISTARG)
  self:SendNetEvent("guildofferrank.GetGuildRankList", msg)
end

function GuildService:ReceiveGuildOfferGuildRankListRet(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildOfferGuildRankListRet", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildOffer_pb.TGUILDOFFERGUILDRANKLISTRET)
  if data == nil then
    return
  end
  Data.guildData:updateGuildWarOfferGuildRankList(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildWarOfferGuildRankList)
end

function GuildService:ReceiveGuildBoxGuildData(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildBoxGuildData", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbox_pb.TGUILDBOXGUILDDATA)
  if data == nil then
    return
  end
  Data.guildData:updateGuildBoxScoreData(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildBoxScoreData)
end

function GuildService:ReceiveGuildBoxUserData(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildBoxUserData", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbox_pb.TGUILDBOXUSERDATA)
  if data == nil then
    return
  end
  Data.guildData:updateGuildBoxUserData(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildBoxUserData)
end

function GuildService:ReceiveGuildBoxUserAllList(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildBoxUserAllList", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbox_pb.TGUILDBOXUSERALLLIST)
  if data == nil then
    return
  end
  Data.guildData:updateGuildBoxUserAllList(data)
end

function GuildService:ReceiveGuildBoxShareAdd(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildBoxShareAdd", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbox_pb.TGUILDBOXSHAREADD)
  if data == nil then
    return
  end
  Data.guildData:updateGuildBoxShareAdd(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildBoxShareAdd)
end

function GuildService:ReceiveGuildBoxTaskAdd(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildBoxTaskAdd", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbox_pb.TGUILDBOXTASKADD)
  if data == nil then
    return
  end
  Data.guildData:updateGuildBoxTaskAdd(data)
  self:SendLuaEvent(LuaEvent.UpdateGuildBoxTaskAdd)
end

function GuildService:ReceivePicGuildBoxRes(ret, state, err, errmsg)
  if self:checkErr("ReceivePicGuildBoxRes", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbox_pb.TGUILDBOXREWARDLISTRET)
  if data == nil then
    return
  end
  Data.guildData:updateGuildBoxState(data)
  Data.guildData:ShowGuildBoxRewardList(data)
end

function GuildService:ReceivePickAllTaskBoxRes(ret, state, err, errmsg)
  if self:checkErr("ReceivePicGuildBoxRes", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbox_pb.TGUILDBOXREWARDLISTRET)
  if data == nil then
    return
  end
  Data.guildData:updateGuildTaskBBoxState(data)
  Data.guildData:ShowGuildBoxRewardList(data)
end

function GuildService:ReceivePicPointsGuildBoxRes(ret, state, err, errmsg)
  if self:checkErr("ReceivePicPointsGuildBoxRes", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbox_pb.TGUILDBOXREWARDLISTRET)
  if data == nil then
    return
  end
  Data.guildData:updatePointsGuildBoxState(data)
  Data.guildData:ShowGuildBoxRewardList(data)
end

function GuildService:ReceiveGuildBoxPushMessage(ret, state, err, errmsg)
  if self:checkErr("ReceiveGuildBoxTaskAdd", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbox_pb.TGUILDBOXPUSHMESSAGERET)
  if data == nil then
    return
  end
  noticeManager:ShowTipById(3701003)
end

function GuildService:SendGuildBoxAnonymous(state)
  local arg = {Anonymous = state}
  local msg = dataChangeManager:LuaToPb(arg, guildbox_pb.TGUILDBOXANONYMOUSARG)
  self:SendNetEvent("guildbox.SetAnonymous", msg)
end

function GuildService:SendGuildBoxPickShare(id)
  local arg = {BoxId = id}
  local msg = dataChangeManager:LuaToPb(arg, guildbox_pb.TGUILDBOXPICKSHAREARG)
  self:SendNetEvent("guildbox.PickShareBox", msg)
end

function GuildService:SendGuildBoxPickTask(id)
  local arg = {BoxId = id}
  local msg = dataChangeManager:LuaToPb(arg, guildbox_pb.TGUILDBOXPICKTASKARG)
  self:SendNetEvent("guildbox.PickTaskBox", msg)
end

function GuildService:SendGuildBoxPickPoints()
  self:SendNetEvent("guildbox.PickPointsBox", nil)
end

function GuildService:SendGuildBoxPickAllTaskBox()
  self:SendNetEvent("guildbox.PickAllTaskBox", nil)
end

function GuildService:ReceiveBigActivityUserData(ret, state, err, errmsg)
  if self:checkErr("ReceiveBigActivityUserData", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbigactivity_pb.TGUILDBIGACTUSERDATA)
  if data == nil then
    return
  end
  Data.guildData:updateGuildBigActivityUserData(data)
end

function GuildService:ReceiveBigActivityGuildRateData(ret, state, err, errmsg)
  if self:checkErr("ReceiveBigActivityGuildRateData", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbigactivity_pb.TGUILDBIGACTGUILDRATEDATA)
  if data == nil then
    return
  end
  Data.guildData:updateGuildBigActivityGuildRateData(data)
end

function GuildService:SendGuildBigActivityPresentItem()
  self:SendNetEvent("guildbigactivity.PresentItem", nil)
end

function GuildService:SendBigActivityGuildRankList(fIdx, tIdx)
  local arg = {FromRankNo = fIdx, ToRankNo = tIdx}
  local msg = dataChangeManager:LuaToPb(arg, guildbigactivity_pb.TGUILDBIGACTRANKLISTARG)
  self:SendNetEvent("guildbigactivityrank.GetGuildRankList", msg)
end

function GuildService:ReceiveBigActivityGuildRankList(ret, state, err, errmsg)
  if self:checkErr("ReceiveBigActivityGuildRankList", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildbigactivity_pb.TGUILDBIGACTRANKLISTRET)
  if data == nil then
    return
  end
  Data.guildData:updateGuildBigActivityGuildRankList(data)
end

return GuildService
