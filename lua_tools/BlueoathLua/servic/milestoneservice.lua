local MilestoneService = class("servic.MilestoneService", Service.BaseService)

function MilestoneService:initialize()
  self:_InitHandlers()
end

function MilestoneService:_InitHandlers()
  self:BindEvent("milestone.GetMilestone", self._GetMilestone, self)
  self:BindEvent("milestone.FetchReward", self._FetchReward, self)
end

function MilestoneService:SendMilestoneFetchReward(arg)
  arg = dataChangeManager:LuaToPb(arg, milestone_pb.TMILESTONEARG)
  self:SendNetEvent("milestone.FetchReward", arg, arg)
end

function MilestoneService:_GetMilestone(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetMilestone failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, milestone_pb.TMILESTONE)
    Data.milestoneData:SetData(info)
    self:SendLuaEvent(LuaEvent.GetMilestoneMsg)
  end
end

function MilestoneService:_FetchReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_FetchReward failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.MilestoneFetchReward, state)
  end
end

return MilestoneService
