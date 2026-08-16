local DailyCopyService = class("servic.DailyCopyService", Service.BaseService)

function DailyCopyService:initialize()
  self:_InitHandlers()
end

function DailyCopyService:_InitHandlers()
  self:BindEvent("dailycopy.UpdateDailyCopyData", self._UpdateDailyCopyData, self)
  self:BindEvent("dailycopy.GetData", self._GetDailyData, self)
end

function DailyCopyService:_UpdateDailyCopyData(ret, state, err, errmsg)
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, dailycopy_pb.TUSERDAILYCOPYINFO)
    Data.dailyCopyData:SetData(info)
    self:SendLuaEvent(LuaEvent.UpdateDailyCopy)
  end
end

function DailyCopyService:_CopyEnterCallBack(ret, state, err, errmsg)
  if err ~= 0 then
    logError("DailyCopyEnter Failed:" .. errmsg)
  elseif ret ~= nil then
    local StartBaseRet = dataChangeManager:PbToLua(ret, dailycopy_pb.TDAILYCOPYENTERRET)
    self:SendLuaEvent(LuaEvent.DailyCopyEnter, StartBaseRet)
  end
end

function DailyCopyService:_CopyPassBase(ret, state, err, errmsg)
  if err ~= 0 then
    logError(errmsg)
  elseif ret ~= nil then
    local PassBaseRet = dataChangeManager:PbToLua(ret, dailycopy_pb.TDAILYCOPYPASSBASERET) or {}
    local param = {
      Reward = PassBaseRet.Reward,
      ExtraReward = PassBaseRet.ExtraReward,
      FirstPass = PassBaseRet.FirstPass
    }
    self:SendLuaEvent("CopyPassBase", param or {})
  end
end

function DailyCopyService:SendCopyEnter(chapterId, copyId, fleetId, cacheId, dailyGroupId)
  local args = {
    ChapterId = chapterId,
    CopyId = copyId,
    TacticId = fleetId,
    CacheId = cacheId,
    DailyGroupId = dailyGroupId
  }
  args = dataChangeManager:LuaToPb(args, dailycopy_pb.TDAILYCOPYENTERARG)
  self:SendNetEvent("dailycopy.CopyEnter", args)
end

function DailyCopyService:SendGetData(arg)
  args = dataChangeManager:LuaToPb(args, module_pb.TEMPTYARG)
  self:SendNetEvent("dailycopy.GetData", args)
end

function DailyCopyService:_GetDailyData(ret, state, err, errmsg)
end

return DailyCopyService
