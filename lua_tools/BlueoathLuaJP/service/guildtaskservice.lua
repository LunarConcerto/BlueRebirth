local GuildTaskService = class("service.GuildTaskService", Service.BaseService)

function GuildTaskService:initialize()
  self:_InitHandlers()
end

function GuildTaskService:_InitHandlers()
  self:BindEvent("guildtask.AcceptTask", self._ReceiveAcceptTask, self)
  self:BindEvent("guildtask.GuildTaskAccept", self._ReceiveGuildTaskAccept, self)
  self:BindEvent("guildtask.GuildTaskFinish", self._ReceiveGuildTaskFinish, self)
  self:BindEvent("guildtask.ConstantRewardPoolGetReward", self._ReceiveConstantRewardPoolGetReward, self)
  self:BindEvent("guildtask.DrawTaskReward", self._ReceiveDrawTaskReward, self)
  self:BindEvent("guildtask.Donate", self._ReceiveDonate, self)
  self:BindEvent("guildtask.UpdateGuildTaskData", self._ReceiveUpdateGuildTaskData, self)
  self:BindEvent("guildtask.UpdateGuildTaskUserData", self._ReceiveUpdateGuildTaskUserData, self)
end

function GuildTaskService:checkErr(name, err, errmsg, callback)
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

function GuildTaskService:SendAcceptTask(arg)
  local data = {}
  data.TaskId = arg.TaskId
  local msg = dataChangeManager:LuaToPb(data, guildtask_pb.TGUILDTASKTASKIDARG)
  self:SendNetEvent("guildtask.AcceptTask", msg, arg)
end

function GuildTaskService:_ReceiveAcceptTask(ret, state, err, errmsg)
  if self:checkErr("_ReceiveAcceptTask", err, errmsg) then
    return
  end
  self:SendLuaEvent(LuaEvent.PAGE_GUILDTASK_ACCEPT)
  noticeManager:ShowTip(UIHelper.GetString(920000530))
end

function GuildTaskService:SendGuildTaskAccept(arg)
  local data = {}
  data.TaskIndex = arg.TaskIndex
  data.TaskId = arg.TaskId
  local msg = dataChangeManager:LuaToPb(data, guildtask_pb.TGUILDTASKTASKARG)
  self:SendNetEvent("guildtask.GuildTaskAccept", msg, arg)
end

function GuildTaskService:_ReceiveGuildTaskAccept(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGuildTaskAccept", err, errmsg) then
    return
  end
end

function GuildTaskService:SendGuildTaskFinish(arg)
  local data = {}
  data.TaskIndex = arg.TaskIndex
  data.TaskId = arg.TaskId
  local msg = dataChangeManager:LuaToPb(data, guildtask_pb.TGUILDTASKTASKARG)
  self:SendNetEvent("guildtask.GuildTaskFinish", msg, arg)
end

function GuildTaskService:_ReceiveGuildTaskFinish(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGuildTaskFinish", err, errmsg) then
    return
  end
  Logic.guildtaskLogic:ShowGuildTaskFinishReward(state.TaskId, state.TaskIndex, 1, state.IsExtra)
end

function GuildTaskService:SendConstantRewardPoolGetReward(arg)
  self:SendNetEvent("guildtask.ConstantRewardPoolGetReward", nil, arg)
end

function GuildTaskService:_ReceiveConstantRewardPoolGetReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveConstantRewardPoolGetReward", err, errmsg) then
    return
  end
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = state.ConstReward,
    Page = "GuildPage",
    DontMerge = true
  })
end

function GuildTaskService:SendDrawTaskReward(arg)
  self:SendNetEvent("guildtask.DrawTaskReward", nil, arg)
end

function GuildTaskService:_ReceiveDrawTaskReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveDrawTaskReward", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildtask_pb.TRANDOMREWARDDATA)
  self:SendLuaEvent(LuaEvent.GET_DRAWREWARD, data)
end

function GuildTaskService:SendDonate(arg)
  local data = {}
  data.TaskIndex = arg.TaskIndex
  data.TaskId = arg.TaskId
  data.Items = arg.Items
  data.TaskNum = arg.TaskNum
  local msg = dataChangeManager:LuaToPb(data, guildtask_pb.TGUILDTASKDONATEARG)
  self:SendNetEvent("guildtask.Donate", msg, arg)
end

function GuildTaskService:_ReceiveDonate(ret, state, err, errmsg)
  if self:checkErr("_ReceiveDonate", err, errmsg) then
    return
  end
  Logic.guildtaskLogic:ShowGuildTaskFinishReward(state.TaskId, state.TaskIndex, state.TaskNum, false)
end

function GuildTaskService:_ReceiveUpdateGuildTaskData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateGuildTaskData", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildtask_pb.TGUILDTASKINFORET)
  Data.guildtaskData:UpdateData(data)
end

function GuildTaskService:_ReceiveUpdateGuildTaskUserData(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateGuildTaskUserData", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, guildtask_pb.TGUILDTASKUSERINFORET)
  Data.guildtaskData:UpdateUserData(data)
end

return GuildTaskService
