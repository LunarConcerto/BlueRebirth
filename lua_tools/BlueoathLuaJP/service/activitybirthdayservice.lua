local ActivityBirthdayService = class("servic.ActivityBirthdayService", Service.BaseService)

function ActivityBirthdayService:initialize()
  self:_InitHandlers()
end

function ActivityBirthdayService:_InitHandlers()
  self:BindEvent("activitybirthday.UpdateBirthdayInfo", self._UpdateBirthdayInfo, self)
  self:BindEvent("activitybirthday.MakeBirthdayCake", self._MakeCake, self)
  self:BindEvent("activitybirthday.FeedBirthdayCake", self._FeedCake, self)
  self:BindEvent("activitybirthday.GetCakeAffairReward", self._GetReward, self)
  self:BindEvent("activitybirthday.BirthdayRefresh", self._GetOpenRefresh, self)
end

function ActivityBirthdayService:MakeBirthdayCake(arg, state)
  arg = dataChangeManager:LuaToPb(arg, activitybirthday_pb.TABMAKECAKEARG)
  self:SendNetEvent("activitybirthday.MakeBirthdayCake", arg, state)
end

function ActivityBirthdayService:_MakeCake(ret, state, err, errmsg)
  if err ~= 0 then
    logError("activitybirthday _MakeCake failed " .. errmsg)
  else
    Logic.activityBirthdayLogic:GetMakeReward(state)
    self:SendLuaEvent(LuaEvent.UpdateBirthdayInfo)
  end
end

function ActivityBirthdayService:FeedBirthdayCake(arg, state)
  arg = dataChangeManager:LuaToPb(arg, activitybirthday_pb.TABFEEDGIRLARG)
  self:SendNetEvent("activitybirthday.FeedBirthdayCake", arg, state)
end

function ActivityBirthdayService:_FeedCake(ret, state, err, errmsg)
  if err ~= 0 then
    logError("activitybirthday _FeedCake failed " .. errmsg)
  else
    Logic.activityBirthdayLogic:GetFeedReward(state)
    self:SendLuaEvent(LuaEvent.UpdateBirthdayInfo)
    self:SendLuaEvent(LuaEvent.GetFeedReward, state)
  end
end

function ActivityBirthdayService:GetBirthdayAffairReward(arg, state)
  arg = dataChangeManager:LuaToPb(arg, activitybirthday_pb.TABRECEIVEAFFAIRREWARDARG)
  self:SendNetEvent("activitybirthday.GetCakeAffairReward", arg, state)
end

function ActivityBirthdayService:_GetReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("activitybirthday _GetReward failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.UpdateBirthdayInfo)
    local tab = {Reward = state}
    eventManager:SendEvent(LuaEvent.FetchRewardBox, tab)
  end
end

function ActivityBirthdayService:GetBirthdayRefresh(arg, state)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("activitybirthday.BirthdayRefresh", arg, state)
end

function ActivityBirthdayService:_GetOpenRefresh(ret, state, err, errmsg)
  if err ~= 0 then
    logError("activitybirthday  _GetOpenRefresh failed " .. errmsg)
  else
  end
end

function ActivityBirthdayService:_UpdateBirthdayInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("activitybirthday  _UpdateBirthdayInfo failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, activitybirthday_pb.TACTIVITYBIRTHDAYINFORET)
    Data.activityBirthdayData:SetData(info)
    self:SendLuaEvent(LuaEvent.UpdateBirthdayInfo)
  end
end

return ActivityBirthdayService
