local ActivitysecretcopyService = class("service.ActivitysecretcopyService", Service.BaseService)

function ActivitysecretcopyService:initialize()
  self:_InitHandlers()
end

function ActivitysecretcopyService:_InitHandlers()
  self:BindEvent("activitysecretcopy.GetReward", self._ReceiveGetReward, self)
  self:BindEvent("activitysecretcopy.UpdateActivitySecretCopyInfo", self._ReceiveUpdateActivitySecretCopyInfo, self)
end

function ActivitysecretcopyService:checkErr(name, err, errmsg, callback)
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

function ActivitysecretcopyService:SendGetReward(arg)
  local data = {}
  data.RateIndex = arg.RateIndex
  local msg = dataChangeManager:LuaToPb(data, activitysecretcopy_pb.TACTIVITYSECRETCOPYGETREWARDARG)
  self:SendNetEvent("activitysecretcopy.GetReward", msg, arg)
end

function ActivitysecretcopyService:_ReceiveGetReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetReward", err, errmsg) then
    return
  end
  local rewards = Logic.rewardLogic:FormatRewards({
    state.RewardId
  })
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = rewards,
    Page = "ActivitySecretCopy",
    DontMerge = true
  })
end

function ActivitysecretcopyService:_ReceiveUpdateActivitySecretCopyInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateActivitySecretCopyInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, activitysecretcopy_pb.TACTIVITYSECRETCOPYINFO)
  Data.activitysecretcopyData:UpdateData(data)
  self:SendLuaEvent(LuaEvent.ActivitySecretCopy_RefreshData)
end

return ActivitysecretcopyService
