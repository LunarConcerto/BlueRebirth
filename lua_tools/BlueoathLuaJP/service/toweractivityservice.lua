local TowerActivityService = class("service.TowerActivityService", Service.BaseService)
local Socket_net = require("socket_net")

function TowerActivityService:initialize()
  self:_InitHandlers()
end

function TowerActivityService:_InitHandlers()
  self:BindEvent("activityTower.GetActivityTower", self._TowerInfo, self)
  self:BindEvent("activityTower.ReceiveBuff", self._ReceiveBuff, self)
  self:BindEvent("activityTower.QuickPass", self._QuickPass, self)
end

function TowerActivityService:SendTowerInfo(arg)
  logDebug("Tower SendTowerInfo arg:", arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("activityTower.ActivityTower", arg)
end

function TowerActivityService:_TowerInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TowerActivityService _TowerInfo failed " .. errmsg)
  else
    ret = dataChangeManager:PbToLua(ret, activitytower_pb.TACTIVITYTOWER)
    Data.towerActivityData:SetData(ret)
    self:SendLuaEvent(LuaEvent.TowerActivityReceiveBuff)
  end
end

function TowerActivityService:SendReset(arg)
  logDebug("Tower SendReset arg:", arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("activityTower.Reset", arg)
end

function TowerActivityService:SendReceiveBuff(arg)
  arg = dataChangeManager:LuaToPb(arg, tower_pb.TTOWERRECEIVEBUFFARG)
  self:SendNetEvent("activityTower.ReceiveBuff", arg)
end

function TowerActivityService:_ReceiveBuff(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TowerActivityService OnReceiveBuff failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.TowerActivityReceiveBuff, ret)
  end
end

function TowerActivityService:SendQuickPass(arg)
  arg = dataChangeManager:LuaToPb(arg, activitytower_pb.TACTIVITYTOWERQUICKPASSARG)
  self:SendNetEvent("activityTower.QuickPass", arg)
end

function TowerActivityService:_QuickPass(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TowerActivityService OnReceiveBuff failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.TowerActivityQuickPass, ret)
  end
end

return TowerActivityService
