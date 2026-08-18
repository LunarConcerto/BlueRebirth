local ActivityVideoService = class("servic.ActivityVideoService", Service.BaseService)

function ActivityVideoService:initialize()
  self:_InitHandlers()
end

function ActivityVideoService:_InitHandlers()
  self:BindEvent("activityVideo.GetActivityVideo", self._GetActivityVideo, self)
  self:BindEvent("activityVideo.SetActivityVideo", self._SetActivityVideoRet, self)
end

function ActivityVideoService:_GetActivityVideo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetActivityVideo failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, activityVideo_pb.TACTIVITYVIDEO)
    Data.activityVideoData:SetData(info)
    self:SendLuaEvent(LuaEvent.GetActivityVideoMsg)
  end
end

function ActivityVideoService:SetActivityVideo(arg, state)
  arg = dataChangeManager:LuaToPb(arg, activityVideo_pb.TAVIDEOWATCHARG)
  self:SendNetEvent("activityVideo.SetActivityVideo", arg, state)
end

function ActivityVideoService:_SetActivityVideoRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_SetActivityVideoRet failed " .. errmsg)
  elseif ret ~= nil then
    local data = dataChangeManager:PbToLua(ret, activityVideo_pb.TAVIDEOWATCHRET)
    UIHelper.OpenPage("GetRewardsPage", {
      Rewards = data.BaseReward,
      DontMerge = false
    })
  end
end

return ActivityVideoService
