local GuildOfferData = class("GuildOfferData", Data.BaseData)

function GuildOfferData:initialize()
  self:ResetData()
end

function GuildOfferData:ResetData()
  self.GuildPoints = 0
  self.userId = Data.userData:GetUserUid()
  self.OfferList = {}
  self.UserOfferInfo = {}
  self:GetScoreCfgData()
end

function GuildOfferData:SetUserOfferInfo(data)
  self.UserOfferInfo = data
  eventManager:SendEvent(LuaEvent.UpdateGuildOfferUserInfo)
end

function GuildOfferData:GetUserOfferInfo()
  return self.UserOfferInfo
end

function GuildOfferData:SetGuildPoints(count)
  self.GuildPoints = count
end

function GuildOfferData:GetGuildPoints()
  return self.GuildPoints
end

function GuildOfferData:SetOfferList(list)
  self.OfferList = list
  eventManager:SendEvent(LuaEvent.UpdateGuildOfferTaskInfo)
end

function GuildOfferData:GetOfferList()
  return self.OfferList
end

function GuildOfferData:SetOfferData(data)
  if data == nil then
    self:SetUserOfferInfo(data)
    self:SetGuildPoints(0)
    self:SetOfferList(data)
    return
  end
  if data.GuildPoints then
    self:SetGuildPoints(data.GuildPoints)
  end
  if data.UserOfferInfo then
    self:SetUserOfferInfo(data.UserOfferInfo)
  end
  if data.OfferList then
    self:SetOfferList(data.OfferList)
  end
end

function GuildOfferData:LoadTaskInfoByCfgIndex(index)
  return configManager.GetDataById("config_task_guildoffer", index)
end

function GuildOfferData:ParaseGuildOfferTaskData(data)
  local taskList = {}
  local selfTaskList = {}
  for k, v in pairs(data) do
    local quality = v
    for index, taskInfo in pairs(quality.OfferList) do
      local paraseTask = taskInfo
      local config = Data.guildOfferData:LoadTaskInfoByCfgIndex(paraseTask.TaskId)
      paraseTask.Quality = quality.Quality
      paraseTask.config = config
      if paraseTask.AcceptInfo ~= nil and #paraseTask.AcceptInfo > 0 then
        for indexUser, userInfo in pairs(paraseTask.AcceptInfo) do
          if userInfo.Uid == Data.userData:GetUserUid() then
            table.insert(selfTaskList, paraseTask)
          end
        end
      end
      table.insert(taskList, paraseTask)
    end
  end
  table.sort(taskList, function(l, r)
    if l.IsTaskOver ~= r.IsTaskOver then
      return l.IsTaskOver < r.IsTaskOver
    end
    if l.Quality ~= r.Quality then
      return l.Quality < r.Quality
    end
    if l.config.order ~= r.config.order then
      return l.config.order < r.config.order
    end
    return l.config.id < r.config.id
  end)
  self.taskList = taskList
  self.selfTaskList = selfTaskList
  return taskList, selfTaskList
end

function GuildOfferData:GetReceiveTaskMaxCount()
  local isMonthPri = Logic.userLogic:CheckMonthCardPrivilege()
  if isMonthPri then
    return 1
  end
  return 1
end

function GuildOfferData:GetReceiveTaskCount()
  if next(self.serverTask) == nil then
    return 0
  end
  return #self.serverTask, self:GetReceiveTaskMaxCount()
end

function GuildOfferData:SetReceiveTaskCount(data)
  self.serverTask = data
end

function GuildOfferData:GetTaskCount()
  return self:GetUserOfferInfo().AllOfferCount or configManager.GetData("config_guildoffer_info")[1].apply_max_num, self:GetUserOfferInfo().UseOfferCount or 0
end

function GuildOfferData:GetScoreCfgData()
  self.personRewardCfg = configManager.GetData("config_guildoffer_perscorereward")
  self.guildRewardCfg = configManager.GetData("config_guildoffer_scorereward")
end

function GuildOfferData:GetPerAndGdScoreCfg()
  if self.personRewardCfg == nil or self.guildRewardCfg == nil then
    self:GetScoreCfgData()
  end
  return self.personRewardCfg, self.guildRewardCfg
end

return GuildOfferData
