EnumGuildTaskType = {Donate = 1, Task = 2}
EnumGuildTaskDonateType = {
  DonateTaskType_Num_Id_Item = 1,
  DonateTaskType_Num_Qual_Item = 2,
  DonateTaskType_Num_Qual_Equip = 6
}
EnumUpdateGuildTaskInfoEvent = {TodayFinishTaskCount = 1}
GUILDTASK_REQUIRE_STEP_COUNT = 10
local GuildTaskData = class("data.GuildTaskData")

function GuildTaskData:initialize()
  self.mCurrentTaskMap = {}
  self.mTodayTaskInfo = {}
end

function GuildTaskData:UpdateData(TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  logDebug("GuildTaskData UpdateData ", TRet)
  if TRet.TodayAcceptTaskCount ~= nil then
    self.mTodayAcceptTaskCount = TRet.TodayAcceptTaskCount
  end
  if TRet.TodayFinishTaskCount ~= nil then
    self.mTodayFinishTaskCount = TRet.TodayFinishTaskCount
    eventManager:SendEvent(LuaEvent.UPDATE_GUILDTASK_INFO_EVENT, EnumUpdateGuildTaskInfoEvent.TodayFinishTaskCount)
  end
  if TRet.CurrentTaskEmptyFlag ~= nil and TRet.CurrentTaskEmptyFlag > 0 then
    self.mCurrentTaskMap = {}
  end
  if TRet.CurrentTasks ~= nil and 0 < #TRet.CurrentTasks then
    for _, taskinfo in ipairs(TRet.CurrentTasks) do
      if 0 < taskinfo.TaskId then
        self.mCurrentTaskMap[taskinfo.TaskIndex] = taskinfo
      end
    end
  end
  if TRet.TodayTaskInfoEmptyFlag ~= nil and 0 < TRet.TodayTaskInfoEmptyFlag then
    self.mTodayTaskInfo = {}
  end
  if TRet.TodayTaskInfo ~= nil and 0 < #TRet.TodayTaskInfo then
    for _, todayTaskInfo in ipairs(TRet.TodayTaskInfo) do
      self.mTodayTaskInfo[todayTaskInfo.TaskId] = todayTaskInfo
    end
  end
  if TRet.TodayRandomRewardInfo ~= nil and 0 < #TRet.TodayRandomRewardInfo then
    self.mTodayRandomRewardInfo = {}
    for _, data in ipairs(TRet.TodayRandomRewardInfo) do
      table.insert(self.mTodayRandomRewardInfo, data)
    end
    table.sort(self.mTodayRandomRewardInfo, function(a, b)
      if a.EnterNum ~= b.EnterNum then
        return a.EnterNum < b.EnterNum
      end
      if a.RewardId ~= b.RewardId then
        return a.RewardId < b.RewardId
      end
      return false
    end)
  end
  if TRet.ConstantRewardPool ~= nil and 0 < #TRet.ConstantRewardPool then
    self.mConstantRewardPool = {}
    for _, data in ipairs(TRet.ConstantRewardPool) do
      if data.RewardId ~= nil and 0 < data.RewardId then
        table.insert(self.mConstantRewardPool, data)
      end
    end
  end
  if TRet.ConstantItemPool ~= nil and 0 < #TRet.ConstantItemPool then
    self.mConstantItemPool = {}
    for _, data in ipairs(TRet.ConstantItemPool) do
      if data.ItemId ~= nil and 0 < data.ItemId then
        table.insert(self.mConstantItemPool, data)
      end
    end
  end
  if TRet.RandomRewardPool ~= nil and 0 < #TRet.RandomRewardPool then
    self.mRandomRewardPool = {}
    for _, data in ipairs(TRet.RandomRewardPool) do
      if data.ItemId ~= nil and 0 < data.ItemId then
        table.insert(self.mRandomRewardPool, data)
      end
    end
  end
  if TRet.TodayMemberContribute ~= nil and 0 < #TRet.TodayMemberContribute then
    self.mTodayMemberContribute = {}
    for _, data in ipairs(TRet.TodayMemberContribute) do
      if data.Uid ~= nil and 0 < data.Uid then
        self.mTodayMemberContribute[data.Uid] = data.Contri
      end
    end
  end
  if TRet.MemberContribute ~= nil and 0 < #TRet.MemberContribute then
    self.mMemberContribute = {}
    for _, data in ipairs(TRet.MemberContribute) do
      if data.Uid ~= nil and 0 < data.Uid then
        self.mMemberContribute[data.Uid] = data.Contri
      end
    end
  end
  if TRet.MemberGetConstantReward ~= nil and 0 < #TRet.MemberGetConstantReward then
    self.mMemberGetConstantReward = {}
    for _, data in ipairs(TRet.MemberGetConstantReward) do
      if data.Uid ~= nil and 0 < data.Uid then
        self.mMemberGetConstantReward[data.Uid] = data
      end
    end
  end
  if TRet.MemberGetRandomReward ~= nil and 0 < #TRet.MemberGetRandomReward then
    self.mMemberGetRandomReward = {}
    for _, data in ipairs(TRet.MemberGetRandomReward) do
      if data.Uid ~= nil and 0 < data.Uid then
        self.mMemberGetRandomReward[data.Uid] = data
      end
    end
  end
  if TRet.MemberFinishStepCount ~= nil and 0 < #TRet.MemberFinishStepCount then
    self.mRewardInfo_MemberFinishStepCount = {}
    for _, data in ipairs(TRet.MemberFinishStepCount) do
      if data.Uid ~= nil and 0 < data.Uid then
        self.mRewardInfo_MemberFinishStepCount[data.Uid] = data.Count
      end
    end
  end
  eventManager:SendEvent(LuaEvent.UPDATE_GUILDTASK_INFO)
end

function GuildTaskData:UpdateUserData(TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  logDebug("GuildTaskData UpdateUserData ", TRet)
  if TRet.ContributeValue ~= nil then
    self.mUserContributeValue = TRet.ContributeValue
  end
  if TRet.TodayAcceptTaskCount ~= nil then
    self.mUserTodayAcceptTaskCount = TRet.TodayAcceptTaskCount
  end
  if TRet.TodayFinishTaskStepCount ~= nil then
    self.mUserTodayFinishTaskStepCount = TRet.TodayFinishTaskStepCount
  end
  if TRet.CurrentGuildTaskInfo ~= nil and TRet.CurrentGuildTaskInfo.TaskIndex ~= nil then
    self.mCurrentGuildTaskInfo = nil
    if TRet.CurrentGuildTaskInfo.TaskIndex >= 0 then
      self.mCurrentGuildTaskInfo = TRet.CurrentGuildTaskInfo
    end
  end
  if TRet.CurrentCanAcceptTaskList ~= nil and 0 < #TRet.CurrentCanAcceptTaskList then
    self.mCurrentCanAcceptTaskList = {}
    for _, taskId in ipairs(TRet.CurrentCanAcceptTaskList) do
      if 0 < taskId then
        table.insert(self.mCurrentCanAcceptTaskList, taskId)
      end
    end
  end
  eventManager:SendEvent(LuaEvent.UPDATE_GUILDTASK_USER_INFO)
end

function GuildTaskData:GetUserContributeValue()
  return self.mUserContributeValue or 0
end

function GuildTaskData:GetUserTodayAcceptTaskCount()
  return self.mUserTodayAcceptTaskCount or 0
end

function GuildTaskData:GetUserTodayFinishTaskStepCount()
  return self.mUserTodayFinishTaskStepCount or 0
end

function GuildTaskData:GetUserCurrentGuildTaskInfo()
  return self.mCurrentGuildTaskInfo
end

function GuildTaskData:GetUserCurrentCanAcceptTaskList()
  return self.mCurrentCanAcceptTaskList or {}
end

function GuildTaskData:GetTodayFinishTaskCount()
  return self.mTodayFinishTaskCount or 0
end

function GuildTaskData:GetCurrentTasks()
  return self.mCurrentTaskMap or {}
end

function GuildTaskData:GetTodayTaskInfo()
  return self.mTodayTaskInfo or {}
end

function GuildTaskData:GetTodayRandomRewardInfo()
  return self.mTodayRandomRewardInfo or {}
end

function GuildTaskData:GetConstantRewardPool()
  return self.mConstantRewardPool or {}
end

function GuildTaskData:GetConstantItemPool()
  return self.mConstantItemPool or {}
end

function GuildTaskData:GetRandomRewardPool()
  return self.mRandomRewardPool or {}
end

function GuildTaskData:GetTodayMemberContribute()
  return self.mTodayMemberContribute or {}
end

function GuildTaskData:GetMemberContribute()
  return self.mMemberContribute or {}
end

function GuildTaskData:GetMemberGetConstantReward()
  return self.mMemberGetConstantReward or {}
end

function GuildTaskData:GetMemberGetRandomReward()
  return self.mMemberGetRandomReward or {}
end

function GuildTaskData:GetMemberFinishStepCount()
  return self.mRewardInfo_MemberFinishStepCount or {}
end

function GuildTaskData:GetMyMemberFinishStepCount()
  local myUid = Data.userData:GetUserUid()
  local memberFinishStepCount = self:GetMemberFinishStepCount()
  local count = memberFinishStepCount[myUid] or 0
  return count
end

function GuildTaskData:GetMyTodayMemberContribute()
  local myUid = Data.userData:GetUserUid()
  local todaymembercontri = self:GetTodayMemberContribute()
  local contri = todaymembercontri[myUid] or 0
  return contri
end

function GuildTaskData:GetTotalTodayMemberContribute()
  local todaymembercontri = self:GetTodayMemberContribute()
  local total = 0
  for _, contri in pairs(todaymembercontri) do
    total = total + contri
  end
  return total
end

function GuildTaskData:GetGetConstantRewardByUid(uid)
  local memContri = self:GetMemberContribute()
  local contri = memContri[uid] or 0
  if contri <= 0 then
    return nil
  end
  local totalContri = 0
  for _, contri in pairs(memContri) do
    totalContri = totalContri + contri
  end
  local constItemPool = self:GetConstantItemPool()
  local mConstItemReward = {}
  for _, itemdata in ipairs(constItemPool) do
    local data = {}
    data.Type = itemdata.ItemType
    data.ConfigId = itemdata.ItemId
    data.Num = math.floor(itemdata.ItemNum * contri / totalContri)
    table.insert(mConstItemReward, data)
  end
  return mConstItemReward
end

function GuildTaskData:GetMyGetConstantReward()
  local myUid = Data.userData:GetUserUid()
  local memGetConstInfo = self:GetMemberGetConstantReward()
  local memGetConst = memGetConstInfo[myUid] or {}
  local get = memGetConst.Get or 0
  if 0 < get then
    return nil
  end
  local myConstItemReward = self:GetGetConstantRewardByUid(myUid)
  return myConstItemReward
end

function GuildTaskData:GetMyGetRandomRewardGet()
  local myUid = Data.userData:GetUserUid()
  local memGetRandInfo = self:GetMemberGetRandomReward()
  local memGetRand = memGetRandInfo[myUid] or {}
  local get = memGetRand.Get or 0
  return get
end

function GuildTaskData:GetUserTodayCanAcceptTaskCount()
  if not Data.guildData:inGuild() then
    return 0
  end
  local cfg = Logic.guildLogic:GetUserPostConfig()
  local userTodayApplyTaskCount = Data.guildtaskData:GetUserTodayAcceptTaskCount()
  local userTodayCanApplyTaskCount = cfg.apply_task_num - userTodayApplyTaskCount
  if userTodayCanApplyTaskCount < 0 then
    userTodayCanApplyTaskCount = 0
  end
  return userTodayCanApplyTaskCount
end

function GuildTaskData:CanDrawRandomReward()
  if not Data.guildData:inGuild() then
    return false
  end
  local randomrewardlist = Logic.guildtaskLogic:GetRandomRewardList()
  if #randomrewardlist <= 0 then
    return false
  end
  local count = Data.guildtaskData:GetMyMemberFinishStepCount()
  if count < GUILDTASK_REQUIRE_STEP_COUNT then
    return false
  end
  local get = Data.guildtaskData:GetMyGetRandomRewardGet()
  if 0 < get then
    return false
  end
  return true
end

return GuildTaskData
