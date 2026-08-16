local TaskService = class("service.TaskService", Service.BaseService)

function TaskService:initialize()
  self:BindEvent("task.TaskInfo", self._TaskInfo, self)
  self:BindEvent("task.TaskReward", self._TaskReward, self)
  self:BindEvent("task.TaskTrigger", self._TaskTrigger, self)
  self:BindEvent("task.TaskRewardByDaysActivity", self._RewardByDaysActivity, self)
  self:BindEvent("task.TaskAllReward", self._TaskAllReward, self)
  self:BindEvent("task.GetPtReward", self._OnGetPtReward, self)
  self:BindEvent("task.GetTeachingTask", self._OnGetTeachingTask, self)
  self:BindEvent("task.TaskRewardByReturnActivity", self._RewardByReturnActivity, self)
end

function TaskService:SendTaskInfo(args)
  args = dataChangeManager:LuaToPb(args, module_pb.TEMPTYARG)
  self:SendNetEvent("task.TaskInfo", args)
end

function TaskService:_TaskInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get task info err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, task_pb.TTASKINFORET)
    Data.taskData:SetTaskData(args)
    self:SendLuaEvent(LuaEvent.UpdataTaskList, nil)
  end
end

function TaskService:SendTaskReward(taskId, taskType)
  local args = {TaskId = taskId, TaskType = taskType}
  args = dataChangeManager:LuaToPb(args, task_pb.TTASKREWARDARG)
  self:SendNetEvent("task.TaskReward", args, args)
end

function TaskService:_TaskReward(ret, state, err, errmsg)
  if err ~= 0 then
    if err == ErrorCode.ErrHeroBagExpandMax then
      noticeManager:OpenTipPage(self, "\232\136\185\229\157\158\229\183\178\230\137\169\229\177\149\229\136\176\230\156\128\229\164\167\229\174\185\233\135\143")
      return
    end
    if err == ErrorCode.ErrTaskNotComplete then
      noticeManager:OpenTipPage(self, "\228\187\187\229\138\161\230\156\170\229\174\140\230\136\144")
      return
    end
    logError("get task reward err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, task_pb.TTASKREWARDRET)
    local params = {
      TaskId = state.TaskId,
      TaskType = state.TaskType,
      Rewards = args.Reward
    }
    self:SendLuaEvent(LuaEvent.GetTaskReward, params)
    eventManager:SendEvent(LuaEvent.FetchRewardBox)
  end
end

function TaskService:SendTaskTrigger(eventId)
  local args = {EventId = eventId}
  args = dataChangeManager:LuaToPb(args, task_pb.TTASKTRIGGERARG)
  self:SendNetEvent("task.TaskTrigger", args, nil, false)
end

function TaskService:_TaskTrigger(ret, state, err, errmsg)
  if err ~= 0 then
    logError("task trigger err:" .. errmsg)
    return
  else
    self:SendLuaEvent(LuaEvent.TaskTriggerRet)
  end
end

function TaskService:SendTaskRewardDay(arg)
  local args = {
    TaskId = arg.TaskId,
    TaskType = arg.TaskType,
    Day = arg.Day
  }
  args = dataChangeManager:LuaToPb(args, task_pb.TTASKREWARDDAYARG)
  self:SendNetEvent("task.TaskRewardByDaysActivity", args, args, false)
end

function TaskService:_RewardByDaysActivity(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get task reward err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, task_pb.TTASKREWARDRET)
    self:SendLuaEvent(LuaEvent.GetNewPlayerReward, args)
  end
end

function TaskService:SendTaskRewardReturn(arg)
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.ReturnPlayer)
  if not actId then
    noticeManager:OpenTipPage(self, UIHelper.GetString(4200001))
    return
  end
  local args = {
    TaskId = arg.TaskId,
    TaskType = arg.TaskType,
    Day = arg.Day
  }
  args = dataChangeManager:LuaToPb(args, task_pb.TTASKREWARDDAYARG)
  self:SendNetEvent("task.TaskRewardByReturnActivity", args, args, false)
end

function TaskService:_RewardByReturnActivity(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get task reward err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, task_pb.TTASKREWARDRET)
    self:SendLuaEvent(LuaEvent.GetReturnPlayerReward, args)
  end
end

function TaskService:SendTaskAllReward(getType)
  local args = {GetType = getType}
  args = dataChangeManager:LuaToPb(args, task_pb.TTASKALLREWARDARG)
  self:SendNetEvent("task.TaskAllReward", args)
end

function TaskService:_TaskAllReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get task reward err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, task_pb.TTASKALLREWARDRET)
    self:SendLuaEvent(LuaEvent.GetAllTaskReward, args)
  end
end

function TaskService:SendGetPtReward(id)
  local args = {Id = id}
  args = dataChangeManager:LuaToPb(args, task_pb.TTASKPTREWARDARG)
  self:SendNetEvent("task.GetPtReward", args)
end

function TaskService:_OnGetPtReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("teaching.getptreward err:" .. err .. " errmsg:" .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, task_pb.TTASKPTREWARDRET)
    self:SendLuaEvent(LuaEvent.TEACHING_GetPtReward, info.Reward)
  end
end

function TaskService:SendGetTeachingTask(uid)
  local args = {targetUId = uid}
  args = dataChangeManager:LuaToPb(args, task_pb.TTASKTEACHINGARG)
  self:SendNetEvent("task.GetTeachingTask", args)
end

function TaskService:_OnGetTeachingTask(ret, state, err, errmsg)
  if err ~= 0 then
    logError("task.getteachingtask err:" .. err .. " errmsg:" .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, task_pb.TTASKTEACHINGRET)
    Data.taskData:SetSTeachData(info)
    self:SendLuaEvent(LuaEvent.TASK_GetSTeachingTask)
  end
end

return TaskService
