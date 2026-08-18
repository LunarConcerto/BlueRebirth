local FleetService = class("servic.FleetService", Service.BaseService)

function FleetService:initialize()
  self:_InitHandlers()
end

function FleetService:_InitHandlers()
  self:BindEvent("tactic.SetHerosTactic", self._SetHerosTactic, self)
  self:BindEvent("tactic.GetHerosTactic", self._GetHerosTactic, self)
end

function FleetService:SendSetFleet(arg)
  arg = dataChangeManager:LuaToPb(arg, tactic_pb.TSELFTACTIS)
  self:SendNetEvent("tactic.SetHerosTactic", arg)
end

function FleetService:_SetHerosTactic(ret, state, err, errmsg)
  if err ~= 0 then
    logError("SetHeroTatic failed " .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, tactic_pb.TSELFTACTIS)
    Data.fleetData:SetData(info)
    self:SendLuaEvent(LuaEvent.SetFleetMsg)
  end
end

function FleetService:SendGetFleet()
  self:SendNetEvent("tactic.GetHerosTactic", nil)
end

function FleetService:_GetHerosTactic(ret, state, err, errmsg)
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, tactic_pb.TSELFTACTIS)
    Data.fleetData:SetData(info)
    self:SendLuaEvent(LuaEvent.GetFleetMsg)
  end
end

return FleetService
