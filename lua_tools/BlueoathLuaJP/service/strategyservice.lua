local StrategyService = class("servic.StrategyService", Service.BaseService)

function StrategyService:initialize()
  self:_InitHandlers()
end

function StrategyService:_InitHandlers()
  self:BindEvent("strategy.Learn", self._Learn, self)
  self:BindEvent("strategy.Upgrade", self._Upgrade, self)
  self:BindEvent("strategy.Reset", self._Reset, self)
  self:BindEvent("strategy.Apply", self._Apply, self)
  self:BindEvent("strategy.GetStrategy", self._GetStrategy, self)
end

function StrategyService:SendLearn(arg)
  arg = dataChangeManager:LuaToPb(arg, strategy_pb.TSTRATEGYARG)
  self:SendNetEvent("strategy.Learn", arg)
end

function StrategyService:_Learn(ret, state, err, errmsg)
  if err ~= 0 then
    logError("StrategyService _Learn failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.LearnStrategy)
  end
end

function StrategyService:SendUpgrade(arg)
  arg = dataChangeManager:LuaToPb(arg, strategy_pb.TSTRATEGYARG)
  self:SendNetEvent("strategy.Upgrade", arg)
end

function StrategyService:_Upgrade(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Upgrade failed " .. errmsg)
  else
  end
end

function StrategyService:SendReset(arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("strategy.Reset", arg)
end

function StrategyService:_Reset(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Reset failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.ResetStrategy)
  end
end

function StrategyService:SendApply(arg)
  arg = dataChangeManager:LuaToPb(arg, strategy_pb.TSTRATEGYARG)
  self:SendNetEvent("strategy.Apply", arg)
end

function StrategyService:_Apply(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Apply failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.ApplyStrategy)
  end
end

function StrategyService:_GetStrategy(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetStrategy failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, strategy_pb.TSTRATEGY)
    Data.strategyData:SetData(info)
    self:SendLuaEvent(LuaEvent.GetStrategyMsg)
  end
end

return StrategyService
