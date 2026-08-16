local ActivitySSRService = class("servic.ActivitySSRService", Service.BaseService)

function ActivitySSRService:initialize()
  self:_InitHandlers()
end

function ActivitySSRService:_InitHandlers()
  self:BindEvent("activitySSR.GetActivitySSRInfo", self._GetActivitySSRInfo, self)
  self:BindEvent("activitySSR.ActivitySSRSelect", self._GetSelectShip, self)
  self:BindEvent("activitySSR.ActivitySSRRand", self._GetActivitySSRRand, self)
  self:BindEvent("activitySSR.ActivitySSRShare", self._GetActivitySSRShare, self)
end

function ActivitySSRService:SendActSSRGirlInfo()
  self:SendNetEvent("activitySSR.GetActivitySSRInfo")
end

function ActivitySSRService:_GetActivitySSRInfo(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, activitySSR_pb.TACTIVITYSSRINFORET)
      Data.activitySSRData:SetData(info)
      self:SendLuaEvent(LuaEvent.UpadateActData, err)
    end
  else
    self:SendLuaEvent(LuaEvent.ErrorActData, err)
  end
end

function ActivitySSRService:SendSecletShipId(param)
  local arg = {SelectShipId = param}
  arg = dataChangeManager:LuaToPb(arg, activitySSR_pb.TSELECTARG)
  self:SendNetEvent("activitySSR.ActivitySSRSelect", arg)
end

function ActivitySSRService:_GetSelectShip(ret, state, err, errmsg)
  if err ~= 0 then
    self:SendLuaEvent(LuaEvent.ErrorActData, err)
    logError("ActivitySSRSelect err" .. err)
  else
    self:SendLuaEvent(LuaEvent.ActivitySSRSelect)
  end
end

function ActivitySSRService:SendActivitySSRRand()
  self:SendNetEvent("activitySSR.ActivitySSRRand")
end

function ActivitySSRService:_GetActivitySSRRand(ret, state, err, errmsg)
  if err ~= 0 then
    self:SendLuaEvent(LuaEvent.ErrorActData, err)
    logError("ActivitySSRRand err" .. err)
  else
    self:SendLuaEvent(LuaEvent.ActivitySSRRand)
  end
end

function ActivitySSRService:SendActivitySSRShare()
  self:SendNetEvent("activitySSR.ActivitySSRShare")
end

function ActivitySSRService:_GetActivitySSRShare(ret, state, err, errmsg)
  if err ~= 0 then
    self:SendLuaEvent(LuaEvent.ErrorActData, err)
    logError("ActivitySSRShare err" .. err)
  else
    self:SendLuaEvent(LuaEvent.ActivitySSRShare)
  end
end

return ActivitySSRService
