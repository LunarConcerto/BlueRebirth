local ExchangeService = class("servic.ExchangeService", Service.BaseService)

function ExchangeService:initialize()
  self:_InitHandlers()
end

function ExchangeService:_InitHandlers()
  self:BindEvent("exchange.Exchange", self._Exchange, self)
  self:BindEvent("exchange.GetExchange", self._GetExchange, self)
end

function ExchangeService:GetExchangeInfo(arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("exchange.GetExchangeInfo", arg)
end

function ExchangeService:SendExchange(arg)
  arg = dataChangeManager:LuaToPb(arg, exchange_pb.TEXCHANGEARG)
  self:SendNetEvent("exchange.Exchange", arg, arg)
end

function ExchangeService:_Exchange(ret, state, err, errmsg)
  if err ~= 0 then
    logError("ExchangeService _Exchange failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.Exchange, state)
  end
end

function ExchangeService:_GetExchange(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetExchange failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, exchange_pb.TEXCHANGE)
    Data.exchangeData:SetData(info)
    self:SendLuaEvent(LuaEvent.GetExchangeMsg)
  end
end

return ExchangeService
