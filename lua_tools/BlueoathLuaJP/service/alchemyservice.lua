local AlchemyService = class("servic.AlchemyService", Service.BaseService)

function AlchemyService:initialize()
  self:_InitHandlers()
end

function AlchemyService:_InitHandlers()
  self:BindEvent("alchemy.UpdateAlchemyData", self._UpdateAlchemyDataRet, self)
  self:BindEvent("alchemy.StartAlchemy", self._SendStartAlchemyRet, self)
end

function AlchemyService:_UpdateAlchemyDataRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("alchemy.UpdateAlchemyData err:", err, "errMsg:", errmsg, "ret,", ret)
  else
    local info = dataChangeManager:PbToLua(ret, alchemy_pb.TALCHEMYINFORET)
    Data.alchemyData:SetData(info)
  end
end

function AlchemyService:SendStartAlchemy(id, equipIdTab)
  local args = {formulaId = id, equipId = equipIdTab}
  args = dataChangeManager:LuaToPb(args, alchemy_pb.TALCHEMYBYFORMULAARG)
  self:SendNetEvent("alchemy.StartAlchemy", args)
end

function AlchemyService:_SendStartAlchemyRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("alchemy.SendStartAlchemy err:", err, "errMsg:", errmsg, "ret,", ret)
  else
    self:SendLuaEvent(LuaEvent.AlchemySuccess)
  end
end

return AlchemyService
