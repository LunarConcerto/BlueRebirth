local ActivityExtractURService = class("servic.ActivityExtractURService", Service.BaseService)

function ActivityExtractURService:initialize()
  self:_InitHandlers()
end

function ActivityExtractURService:_InitHandlers()
  self:BindEvent("activityextractur.Get", self._GetRefresh, self)
  self:BindEvent("activityextractur.Update", self._GetRefresh, self)
  self:BindEvent("activityextractur.Draw", self._Draw, self)
  self:BindEvent("activityextractur.SwitchDraw", self._SwitchDraw, self)
end

function ActivityExtractURService:SendGetActExtractURInfo()
  self:SendNetEvent("activityextractur.Get")
end

function ActivityExtractURService:SendActExtractURDraw(drawId, num)
  local arg = {DrawId = drawId, Num = num}
  local state = 0
  arg = dataChangeManager:LuaToPb(arg, activityextractur_pb.TACTIVITYEXTRACTURDRAWARG)
  self:SendNetEvent("activityextractur.Draw", arg, state)
end

function ActivityExtractURService:SendActExtractURSwitchDraw(param)
  self:SendNetEvent("activityextractur.SwitchDraw")
end

function ActivityExtractURService:_GetRefresh(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, activityextractur_pb.TACTIVITYEXTRACTURINFO)
      Data.activityExtractURData:SetData(info)
    end
  else
    self:SendLuaEvent(LuaEvent.ErrActExtractURRet, err)
  end
end

function ActivityExtractURService:_Draw(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, activityextractur_pb.TACTIVITYEXTRACTURDRAWRET)
      local param = info
      self:SendLuaEvent(LuaEvent.ActExtractURReward, param)
    end
  else
    logError("ActivityExtractURService _Draw err !!", err, errmsg)
    self:SendLuaEvent(LuaEvent.ErrActExtractURRet, err)
  end
end

function ActivityExtractURService:_SwitchDraw(ret, state, err, errmsg)
  if err == 0 then
  else
    logError("ActivityExtractURService _SwitchDraw err !!", err, errmsg)
    self:SendLuaEvent(LuaEvent.ErrActExtractURRet, err)
  end
end

return ActivityExtractURService
