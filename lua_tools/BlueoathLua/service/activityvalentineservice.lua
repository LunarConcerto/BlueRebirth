local ActivityValentineService = class("service.ActivityValentineService", Service.BaseService)

function ActivityValentineService:initialize()
  self:_InitHandlers()
end

function ActivityValentineService:_InitHandlers()
  self:BindEvent("activityvalentine.ActivityValentineInfo", self._ActivityValentineInfo, self)
  self:BindEvent("activityvalentine.ActVanlenReward", self._ActVanlenReward, self)
end

function ActivityValentineService:_ActivityValentineInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("activityValentineInfo data errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, activityValentine_pb.TACTIVITYVALENTINEINFO)
    Data.activityValentineData:SetValentineData(info)
  end
end

function ActivityValentineService:SendActVanlenReward(index)
  local arg = dataChangeManager:LuaToPb({Index = index}, activityValentine_pb.TACTIVITYVALENTINEARG)
  self:SendNetEvent("activityvalentine.ActVanlenReward", arg)
end

function ActivityValentineService:_ActVanlenReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("sign fininsh errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, activityValentine_pb.TACTIVITYVALENTINERET)
    self:SendLuaEvent(LuaEvent.ActivityValentineReward, info.Reward)
  end
end

return ActivityValentineService
