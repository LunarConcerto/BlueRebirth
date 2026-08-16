local UpdateService = class("servic.UpdateService", Service.BaseService)

function UpdateService:initialize()
  self:_InitHandlers()
end

function UpdateService:_InitHandlers()
  self:BindEvent("update.UpdateGameAdvList", self._UpdateGameAdv, self)
  self:BindEvent("update.UpdateWebActivity", self._UpdateWebActivity, self)
  self:BindEvent("update.UpdateGMAnswer", self._UpdateGMAnswer, self)
end

function UpdateService:_UpdateGameAdv(ret, state, err, errmsg)
  if err ~= 0 then
    logError("updateGameAdv Error :" .. err)
  else
    local advInfo = dataChangeManager:PbToLua(ret, update_pb.TUPDATEADVLIST)
    self:SendLuaEvent(LuaEvent.UpdateGameAdv, advInfo)
  end
end

function UpdateService:_UpdateWebActivity(ret, state, err, errmsg)
  if err ~= 0 then
    logError("UpdateWebActivity Error :" .. err)
  else
    local activityInfo = dataChangeManager:PbToLua(ret, update_pb.TUPDATEWEBACTIVITY)
    self:SendLuaEvent(LuaEvent.UpdateWebActivity, activityInfo)
  end
end

function UpdateService:_UpdateGMAnswer(ret, state, err, errmsg)
  if err ~= 0 then
    logError("UpdateGMAnswer Error :" .. err)
  else
    self:SendLuaEvent(LuaEvent.UpdateGMAnswer, true)
  end
end

return UpdateService
