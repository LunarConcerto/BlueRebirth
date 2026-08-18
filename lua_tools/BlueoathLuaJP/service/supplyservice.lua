local SupplyService = class("servic.SupplyService", Service.BaseService)

function SupplyService:initialize()
  self:_InitHandlers()
end

function SupplyService:_InitHandlers()
  self:BindEvent("supply.SupplySwitch", self._SupplySwitch, self)
end

function SupplyService:SendSupplySwitch(arg)
  arg = dataChangeManager:LuaToPb(arg, supply_pb.TSUPPLYSWITCHARG)
  self:SendNetEvent("supply.SupplySwitch", arg)
end

function SupplyService:_SupplySwitch(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Supply Error :" .. err)
  end
end

return SupplyService
