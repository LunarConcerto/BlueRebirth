local BuildShipService = class("servic.BuildShipService", Service.BaseService)

function BuildShipService:initialize()
  self:_InitHandlers()
end

function BuildShipService:_InitHandlers()
  self:BindEvent("buildship.BuildShip", self._BuildShipRet, self)
  self:BindEvent("buildship.BuildShipInfo", self._BuildShipInfo, self)
  self:BindEvent("buildship.BuildShipBox", self._BuildShipBox, self)
  self:BindEvent("buildship.BuildShipReward", self._BuildShipReward, self)
end

function BuildShipService:SendBuildShipReq(arg)
  arg = dataChangeManager:LuaToPb(arg, buildship_pb.TBUILDSHIPARG)
  self:SendNetEvent("buildship.BuildShip", arg)
end

function BuildShipService:SendBuildShipBoxReward(arg)
  arg = dataChangeManager:LuaToPb(arg, buildship_pb.TBUILDSHIPARG)
  self:SendNetEvent("buildship.BuildShipBox", arg)
end

function BuildShipService:SendBuildShipReward(arg)
  arg = dataChangeManager:LuaToPb(arg, buildship_pb.TBUILDSHIPARG)
  self:SendNetEvent("buildship.BuildShipReward", arg)
end

function BuildShipService:_BuildShipRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("BuildShip failed err:" .. err .. errmsg)
    UIHelper.SetUILock(false)
    self:SendLuaEvent(LuaEvent.BuildShipFailed, err)
  else
    local info = dataChangeManager:PbToLua(ret, buildship_pb.TBUILDSHIPRET)
    self:SendLuaEvent(LuaEvent.BuildFinish, info)
  end
end

function BuildShipService:_BuildShipInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("BuildShipInfo failed err:" .. err .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, buildship_pb.TBUILDSHIPINFO)
    Data.buildShipData:SetData(info)
  end
end

function BuildShipService:_BuildShipBox(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_BuildShipBox failed err:" .. err .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, buildship_pb.TBUILDSHIPRET)
    self:SendLuaEvent(LuaEvent.BuildShipBox, info)
  end
end

function BuildShipService:_BuildShipReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_BuildShipReward failed err:" .. err .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, buildship_pb.TBUILDSHIPRET)
    self:SendLuaEvent(LuaEvent.BuildShipReward, info)
  end
end

return BuildShipService
