local ActivityService = class("service.ActivityService", Service.BaseService)

function ActivityService:initialize()
  self:_InitHandlers()
end

function ActivityService:_InitHandlers()
  self:BindEvent("activity.UpdateActivityInfo", self._UpdateActivityInfo, self)
  self:BindEvent("sign.SignInfo", self._SaveSignData, self)
  self:BindEvent("sign.Sign", self._FinishSign, self)
  self:BindEvent("activityfashion.PushActivityFashionInfo", self._GetActivityFashionInfo, self)
  self:BindEvent("activityfashion.Reward", self._GetActivityReward, self)
  self:BindEvent("activityfashion.Buy", self._GetActivityBuy, self)
  self:BindEvent("statcount.GetStatCount", self._GetStatCountRet, self)
end

function ActivityService:_UpdateActivityInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_UpdateActivityInfo errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, activity_pb.TRETACTIVITYINFO)
    Data.activityData:UpdateActivityInfo(info)
    self:SendLuaEvent(LuaEvent.UpdateActivity)
  end
end

function ActivityService:SendSign()
  self:SendNetEvent("sign.Sign", nil)
end

function ActivityService:_FinishSign(ret, state, err, errmsg)
  if err ~= 0 then
    logError("sign fininsh errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, sign_pb.TSIGNINFO)
    Data.activityData:SetSignData(info)
    self:SendLuaEvent(LuaEvent.SignFinished, info.Reward)
  end
end

function ActivityService:_SaveSignData(ret, state, err, errmsg)
  if err ~= 0 then
    logError("save sign data errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, sign_pb.TSIGNINFO)
    Data.activityData:SetSignData(info)
    self:SendLuaEvent(LuaEvent.UpdateSignInfo)
  end
end

function ActivityService:SendActivityFashionBuy(args)
  local args = {Count = args}
  args = dataChangeManager:LuaToPb(args, activityfashion_pb.TACTIVITYFASHIONBUYARG)
  self:SendNetEvent("activityfashion.Buy", args)
end

function ActivityService:_GetActivityFashionInfo(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, activityfashion_pb.TACTIVITYFASHIONINFORET)
      Data.activityData:SetActFashionData(info)
      self:SendLuaEvent(LuaEvent.GetActivityfashion, info)
    end
  else
    logError("activityfashion err" .. errmsg)
  end
end

function ActivityService:SendActivityFashionReward(arg)
  local args = {Index = arg}
  args = dataChangeManager:LuaToPb(args, activityfashion_pb.TACTIVITYFASHIONREWARDARG)
  self:SendNetEvent("activityfashion.Reward", args)
end

function ActivityService:_GetActivityBuy(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, commonreward_pb.TCOMMONARRREWARD)
      self:SendLuaEvent(LuaEvent.BuyActFashionSuc, info)
    end
  else
    self:SendLuaEvent(LuaEvent.ActFashionSucError, err)
    logError("_GetActivityBuy err" .. err)
  end
end

function ActivityService:_GetActivityReward(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, commonreward_pb.TCOMMONARRREWARD)
      self:SendLuaEvent(LuaEvent.RewardActFashionSuc, info)
    end
  else
    self:SendLuaEvent(LuaEvent.ActFashionSucError, err)
    logError("_GetActivityBuy err" .. err)
  end
end

function ActivityService:SendGetStateCount()
  self:SendNetEvent("statcount.GetStatCount")
end

function ActivityService:_GetStatCountRet(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, statcount_pb.TSTATCOUNTINFO)
      self:SendLuaEvent(LuaEvent.GetStatCountRet, info)
    end
  else
    logError("_GetStatCountRet err" .. err)
  end
end

return ActivityService
