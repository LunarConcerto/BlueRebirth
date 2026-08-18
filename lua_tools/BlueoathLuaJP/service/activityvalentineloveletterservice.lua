local ActivityValentineLoveLetterService = class("service.ActivityValentineLoveLetterService", Service.BaseService)

function ActivityValentineLoveLetterService:initialize()
  self:_InitHandlers()
end

function ActivityValentineLoveLetterService:_InitHandlers()
  self:BindEvent("activityvalentineloveletter.GetRewardBySecretary", self._ReceiveGetRewardSecretary, self)
  self:BindEvent("activityvalentineloveletter.GetReward", self._ReceiveGetReward, self)
  self:BindEvent("activityvalentineloveletter.UpdateActivityValentineLoveLetterInfo", self._ReceiveUpdateActivityValentineLoveLetterInfo, self)
end

function ActivityValentineLoveLetterService:checkErr(name, err, errmsg, callback)
  logDebug("on ", name, err, errmsg)
  if err ~= 0 then
    if 0 < err then
      local str = UIHelper.GetString(err)
      noticeManager:ShowTip(str)
    end
    if err < 0 then
      logError(name .. " error", tostring(errmsg))
      return true
    end
    if callback ~= nil then
      callback()
    end
    return true
  end
  return false
end

function ActivityValentineLoveLetterService:SendGetReward(arg)
  local data = {}
  data.Index = arg.Index
  local msg = dataChangeManager:LuaToPb(data, activityvalentineloveletter_pb.TACTIVITYVALENTINELOVELETTERGETREWARDARG)
  self:SendNetEvent("activityvalentineloveletter.GetReward", msg, arg)
end

function ActivityValentineLoveLetterService:_ReceiveGetReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetReward", err, errmsg) then
    return
  end
  self:SendLuaEvent(LuaEvent.ActivityValentineLoveLetter_GetGift, state)
end

function ActivityValentineLoveLetterService:SendGetRewardSecretary(arg)
  self:SendNetEvent("activityvalentineloveletter.GetRewardBySecretary", nil, arg)
end

function ActivityValentineLoveLetterService:_ReceiveGetRewardSecretary(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetReward", err, errmsg) then
    return
  end
  self:SendLuaEvent(LuaEvent.ActivityValentineLoveLetter_GetGift_Secretary, state)
end

function ActivityValentineLoveLetterService:_ReceiveUpdateActivityValentineLoveLetterInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateActivityValentineLoveLetterInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, activityvalentineloveletter_pb.TACTIVITYVALENTINELOVELETTERINFORET)
  Data.activityvalentineloveletterData:UpdateData(data)
  self:SendLuaEvent(LuaEvent.ActivityValentineLoveLetter_RefreshData)
end

return ActivityValentineLoveLetterService
