local ActivityExtractService = class("servic.ActivityExtractService", Service.BaseService)

function ActivityExtractService:initialize()
  self:_InitHandlers()
end

function ActivityExtractService:_InitHandlers()
  self:BindEvent("activityextract.Get", self._GetRefresh, self)
  self:BindEvent("activityextract.Update", self._GetRefresh, self)
  self:BindEvent("activityextract.Draw", self._Draw, self)
  self:BindEvent("activityextract.SwitchDraw", self._SwitchDraw, self)
end

function ActivityExtractService:SendGetActExtractInfo()
  self:SendNetEvent("activityextract.Get")
end

function ActivityExtractService:SendActExtractDraw(drawId, num)
  local arg = {DrawId = drawId, Num = num}
  local state = 0
  arg = dataChangeManager:LuaToPb(arg, activityextract_pb.TACTIVITYEXTRACTDRAWARG)
  self:SendNetEvent("activityextract.Draw", arg, state)
end

function ActivityExtractService:SendActExtractSwitchDraw(param)
  self:SendNetEvent("activityextract.SwitchDraw")
end

function ActivityExtractService:_GetRefresh(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, activityextract_pb.TACTIVITYEXTRACTINFO)
      Data.activityExtractData:SetData(info)
    end
  else
    self:SendLuaEvent(LuaEvent.ErrActExtraRet, err)
  end
end

function ActivityExtractService:_Draw(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, activityextract_pb.TACTIVITYEXTRACTDRAWRET)
      local jackpot = false
      local param = {Ret = info, Jackpot = jackpot}
      self:SendLuaEvent(LuaEvent.ActExtraReward, param)
    end
  else
    logError("ActivityExtractService _Draw err !!", err, errmsg)
    self:SendLuaEvent(LuaEvent.ErrActExtraRet, err)
  end
end

function ActivityExtractService:_SwitchDraw(ret, state, err, errmsg)
  if err == 0 then
  else
    logError("ActivityExtractService _SwitchDraw err !!", err, errmsg)
    self:SendLuaEvent(LuaEvent.ErrActExtraRet, err)
  end
end

return ActivityExtractService
