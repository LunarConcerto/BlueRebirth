local TowerService = class("service.TowerService", Service.BaseService)
local Socket_net = require("socket_net")

function TowerService:initialize()
  self:_InitHandlers()
end

function TowerService:_InitHandlers()
  self:BindEvent("tower.TowerInfo", self._TowerInfo, self)
  self:BindEvent("tower.Receive", self._Receive, self)
  self:BindEvent("tower.Replacement", self._Replacement, self)
  self:BindEvent("tower.ReceiveBuff", self._ReceiveBuff, self)
end

function TowerService:SendTowerInfo(arg)
  logDebug("Tower SendTowerInfo arg:", arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("tower.GetTowerInfo", arg)
end

function TowerService:_TowerInfo(ret, state, err, errmsg)
  logDebug("Tower TowerInfo ret:", ret)
  if err ~= 0 then
    logError("TowerService _TowerInfo failed " .. errmsg)
  else
    ret = dataChangeManager:PbToLua(ret, tower_pb.TTOWERINFORET)
    Data.towerData:SetData(ret)
    self:SendLuaEvent(LuaEvent.UpdateTowerInfo)
  end
end

function TowerService:SendReceive(arg)
  logDebug("Tower SendReceive arg:", arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("tower.Receive", arg)
end

function TowerService:_Receive(ret, state, err, errmsg)
  logDebug("Tower _Receive ret:", ret)
  if err ~= 0 then
    logError("TowerService _Receive failed " .. errmsg)
  else
    ret = dataChangeManager:PbToLua(ret, tower_pb.TTOWERREWARD)
    self:SendLuaEvent(LuaEvent.TowerFetchReward, ret)
  end
end

function TowerService:SendReplacement(arg)
  logDebug("Tower SendReplacement arg:", arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("tower.Replacement", arg)
end

function TowerService:_Replacement(ret, state, err, errmsg)
  logDebug("Tower _Replacement ret:", ret)
  if err ~= 0 then
    logError("TowerService _Replacement failed " .. errmsg)
  else
  end
end

function TowerService:ResetChangeHeroIdList(arg)
  logDebug("Tower SendResetChangeHeroIdList arg:", arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("tower.ResetChangeHeroIdList", arg)
end

function TowerService:SendReset(arg)
  logDebug("Tower SendReset arg:", arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("tower.Reset", arg)
end

function TowerService:SendUpgrade(arg)
  logDebug("Tower SendUpgrade arg:", arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("tower.SendUpgrade", arg)
end

function TowerService:SendReceiveBuff(arg)
  arg = dataChangeManager:LuaToPb(arg, tower_pb.TTOWERRECEIVEBUFFARG)
  self:SendNetEvent("tower.ReceiveBuff", arg)
end

function TowerService:_ReceiveBuff(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TowerService OnReceiveBuff failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.TowerReceiveBuff, ret)
  end
end

return TowerService
