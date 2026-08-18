local SportMeetService = class("service.SportMeetService", Service.BaseService)
local SportMeet = {
  AttackBee = 1,
  Track = 2,
  Steeplechase = 3
}
local SportMeetLua = {
  [SportMeet.AttackBee] = sportsmeet_pb.TSPORTSRANKGETATTACKBEEARG,
  [SportMeet.Track] = sportsmeet_pb.TSPORTSRANKGETTRACKARG,
  [SportMeet.Steeplechase] = sportsmeet_pb.TSPORTSRANKGETSTEEPLECHASEARG
}
local SportMeetNet = {
  [SportMeet.AttackBee] = "sportsmeetrank.GetAttackBeeRank",
  [SportMeet.Track] = "sportsmeetrank.GetTrackRank",
  [SportMeet.Steeplechase] = "sportsmeetrank.GetSteeplechaseRank"
}
local SportMeetRet = {
  [SportMeet.AttackBee] = sportsmeet_pb.TSPORTSRANKGETATTACKBEERET,
  [SportMeet.Track] = sportsmeet_pb.TSPORTSRANKGETTRACKRET,
  [SportMeet.Steeplechase] = sportsmeet_pb.TSPORTSRANKGETSTEEPLECHASERET
}

function SportMeetService:initialize()
  self:_InitHandlers()
end

function SportMeetService:_InitHandlers()
  self:BindEvent("sportsmeetrank.GetOwnerRankData", self.ReceiveRankData, self)
  self:BindEvent("sportsmeetrank.GetAttackBeeRank", self.ReceiveAttackBeeData, self)
  self:BindEvent("sportsmeetrank.GetTrackRank", self.ReceiveTrackData, self)
  self:BindEvent("sportsmeetrank.GetSteeplechaseRank", self.ReceiveSteeplechaseData, self)
  self:BindEvent("sportsmeet.GetSportsTickCount", self.ReceiveUserTickData, self)
  self:BindEvent("sportsmeet.GetPointsRewardDetail", self.ReceivePointsRewardDetailData, self)
  self:BindEvent("sportsmeet.ReceivePointsReward", self.ReceivePointsRewardData, self)
  self:BindEvent("sportsmeet.ReceiveAllPointsReward", self.ReceivePointsRewardData, self)
end

function SportMeetService:checkErr(name, err, errmsg, callback)
  if err ~= 0 then
    if 0 < err then
      local str = UIHelper.GetString(err)
      noticeManager:ShowTip(str)
    else
      noticeManager:ShowTip(err .. " : " .. tostring(errmsg))
    end
    if err < 0 then
      if err == -1900041 then
        noticeManager:ShowTip(UIHelper.GetString(920000821))
      elseif err == -1900042 then
        noticeManager:ShowTip(UIHelper.GetString(270022))
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

function SportMeetService:GetUserRankData()
  self:SendNetEvent("sportsmeetrank.GetOwnerRankData")
end

function SportMeetService:GetUserSportTickData()
  self:SendNetEvent("sportsmeet.GetSportsTickCount")
end

function SportMeetService:ReceiveUserTickData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveCreate", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, sportsmeet_pb.TSPORTSTICKCOUNTRET)
  Data.sportMeetData:SetSportTickCount(data)
  self:SendLuaEvent(LuaEvent.UpdateSportTickInfo, data)
end

function SportMeetService:GetPointsRewardDetailData()
  self:SendNetEvent("sportsmeet.GetPointsRewardDetail")
end

function SportMeetService:ReceivePointsRewardDetailData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveCreate", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, sportsmeet_pb.TSPORTSGETPOINTSREWARDDETAILRET)
  Data.sportMeetData:SetSportMeetPonits(data)
  self:SendLuaEvent(LuaEvent.GetSportRewardRecInfo, data)
end

function SportMeetService:GetPointsReward(point)
  local arg = {PointsReward = point}
  arg = dataChangeManager:LuaToPb(arg, sportsmeet_pb.TSPORTSRECEIVEREWARDARG)
  self:SendNetEvent("sportsmeet.ReceivePointsReward", arg)
end

function SportMeetService:GetAllPointsReward()
  self:SendNetEvent("sportsmeet.ReceiveAllPointsReward")
end

function SportMeetService:ReceivePointsRewardData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveCreate", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, commonreward_pb.TCOMMONARRREWARD)
  self:SendLuaEvent(LuaEvent.ReceiveRewardBack, data)
end

function SportMeetService:GetSportRankData(args)
  local pbArg = {
    FromRankNo = args.FromRankNo,
    ToRankNo = args.ToRankNo
  }
  pbArg = dataChangeManager:LuaToPb(pbArg, SportMeetLua[args.type])
  self:SendNetEvent(SportMeetNet[args.type], pbArg)
end

function SportMeetService:ReceiveRankData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveCreate", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, sportsmeet_pb.TSPORTSOWNERRANKDATARET)
  Data.sportMeetData:SetMySportRankData(data)
  self:SendLuaEvent(LuaEvent.UpdateSportInfo, data)
end

function SportMeetService:ReceiveAttackBeeData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveCreate", err, errmsg) then
    return
  end
  self:DealSportMeetData(ret, state, err, errmsg, SportMeet.AttackBee)
end

function SportMeetService:ReceiveTrackData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveCreate", err, errmsg) then
    return
  end
  self:DealSportMeetData(ret, state, err, errmsg, SportMeet.Track)
end

function SportMeetService:ReceiveSteeplechaseData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveCreate", err, errmsg) then
    return
  end
  self:DealSportMeetData(ret, state, err, errmsg, SportMeet.Steeplechase)
end

function SportMeetService:DealSportMeetData(ret, state, err, errmsg, type)
  local data = dataChangeManager:PbToLua(ret, SportMeetRet[type])
  local param = {Data = data, Type = type}
  Data.sportMeetData:SetData(param)
end

return SportMeetService
