local ActivityRollsService = class("servic.ActivityRollsService", Service.BaseService)

function ActivityRollsService:initialize()
  self:_InitHandlers()
end

function ActivityRollsService:_InitHandlers()
  self:BindEvent("activitySSRrolls.UpdateActivityRollsInfo", self._UpdateActivityRollsInfo, self)
  self:BindEvent("activitySSRrolls.ActivityRollsSelect", self._GetSelectShips, self)
  self:BindEvent("activitySSRrolls.ActivityRollsRand", self._GetRandShips, self)
end

function ActivityRollsService:SendUpdateActRollsInfo()
  self:SendNetEvent("activitySSRrolls.UpdateActivityRollsInfoRPC")
end

function ActivityRollsService:_UpdateActivityRollsInfo(ret, state, err, errmsg)
  if err ~= 0 then
    self:SendLuaEvent(LuaEvent.ErrorRollsData, err)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, activitySSRrolls_pb.TACTIVITYSSRROLLSINFORET)
    Data.activityRollsData:SetData(info)
    self:SendLuaEvent(LuaEvent.UpdateActivityRolls, err)
  end
end

function ActivityRollsService:SendSecletShips(param)
  local arg = {SelectTeamId = param}
  arg = dataChangeManager:LuaToPb(arg, activitySSRrolls_pb.TSSRROLLSSELECTARG)
  self:SendNetEvent("activitySSRrolls.ActivityRollsSelect", arg)
end

function ActivityRollsService:_GetSelectShips(ret, state, err, errmsg)
  if err ~= 0 then
    self:SendLuaEvent(LuaEvent.ErrorRollsData, err)
    logError("_GetSelectShips err" .. err)
  else
    self:SendLuaEvent(LuaEvent.ActivityRollsSelect)
  end
end

function ActivityRollsService:SendRandShips()
  self:SendNetEvent("activitySSRrolls.ActivityRollsRand")
end

function ActivityRollsService:_GetRandShips(ret, state, err, errmsg)
  if err ~= 0 then
    self:SendLuaEvent(LuaEvent.ErrorRollsData, err)
    logError("_GetRandShips err" .. err)
  else
    self:SendLuaEvent(LuaEvent.ActivityRollsRand)
  end
end

return ActivityRollsService
