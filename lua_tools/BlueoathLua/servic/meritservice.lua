local MeritService = class("servic.MeritService", Service.BaseService)

function MeritService:initialize()
  self:_InitHandlers()
end

function MeritService:_InitHandlers()
  self:BindEvent("bigactivity.GetBigActivityInfo", self._GetBigActivity, self)
  self:BindEvent("bigactivity.GetBigActivityRank", self._GetBigActivityRankList, self)
  self:BindEvent("bigactivity.GetBigActivityRankEx", self._GetExRankList, self)
end

function MeritService:SendBigActivity()
  self:SendNetEvent("bigactivity.GetBigActivityInfo")
end

function MeritService:_GetBigActivity(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, bigactivity_pb.TBIGACTIVITYRET)
      Data.meritData:SetData(info)
      self:SendLuaEvent(LuaEvent.UpdateMeritInfo)
    end
  else
    logError("BigActivity err" .. err)
  end
end

function MeritService:_GetBigActivityRankList(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, bigactivity_pb.TBIGACTIVITYRANKLISTRET)
      self:SendLuaEvent(LuaEvent.UpdateMeritRank, info)
    end
  else
    logError("BigActivityRankList err" .. err)
  end
end

function MeritService:SendMeritRankInfo(arg)
  local args = {
    Start = arg.Start,
    End = arg.End
  }
  args = dataChangeManager:LuaToPb(args, bigactivity_pb.TBIGACTIVITYRANKARG)
  self:SendNetEvent("bigactivity.GetBigActivityRank", args)
end

function MeritService:_GetExRankList(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, bigactivity_pb.TBIGACTIVITYRANKLISTRET)
      self:SendLuaEvent(LuaEvent.UpdateExRank, info)
    end
  else
    logError("_GetExRankList err" .. err)
  end
end

function MeritService:SendMeritRankExInfo(args)
  args = dataChangeManager:LuaToPb(args, bigactivity_pb.TBIGACTIVITYRANKARG)
  self:SendNetEvent("bigactivity.GetBigActivityRankEx", args)
end

return MeritService
