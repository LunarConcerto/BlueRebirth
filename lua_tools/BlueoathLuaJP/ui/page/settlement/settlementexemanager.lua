local SettlementExeManager = class("UI.Settlement.SettlementExeManager")

function SettlementExeManager:initialize()
  self.m_executerList = {}
  self.m_timer = nil
  self.m_isAuto = false
  self.m_inBattle = false
  self.m_taskFinish = false
  self:RegisterEvent()
end

function SettlementExeManager:RegisterEvent()
end

function SettlementExeManager:SetTaskFinish(bool)
  self.m_taskFinish = bool
end

function SettlementExeManager:GetTaskFinish()
  return self.m_taskFinish
end

function SettlementExeManager:SetInBattle(bool)
  self.m_inBattle = bool
end

function SettlementExeManager:GetInBattle()
  return self.m_inBattle
end

function SettlementExeManager:SetIsAuto(isAuto)
  self.m_isAuto = isAuto
end

function SettlementExeManager:IsAutoExe()
  return self.m_isAuto
end

function SettlementExeManager:GetAutoExeTime()
  return tonumber(configManager.GetDataById("config_battle_config", 238).data)
end

function SettlementExeManager:RegisterExecuter(executer)
  for _, exe in ipairs(self.m_executerList) do
    if exe.flow == executer.flow then
      logError("repeat register settlement executer,type:" .. executer.flow)
      return
    end
  end
  table.insert(self.m_executerList, executer)
end

function SettlementExeManager:UnregisterExecuter(flow)
  for index, exe in ipairs(self.m_executerList) do
    if exe.flow == flow then
      table.remove(self.m_executerList, index)
      return
    end
  end
end

function SettlementExeManager:HaveExecuted(flow)
  for _, exe in ipairs(self.m_executerList) do
    if exe.flow == flow then
      return exe.exed
    end
  end
  return true
end

function SettlementExeManager:AutoExecute()
  if #self.m_executerList < 1 then
    return
  end
  if self.m_timer ~= nil then
    self.m_timer:Stop()
  end
  local duration = self:GetAutoExeTime()
  local loop = #self.m_executerList
  local executer
  local index = 0
  self.m_timer = Timer.New(function()
    for i = 1, #self.m_executerList do
      executer = self.m_executerList[i]
      if executer and not executer.exed then
        index = i
        break
      end
    end
    if executer and not executer.exed then
      executer.func(executer.param)
      executer.exed = true
      table.remove(self.m_executerList, index)
      executer = nil
    end
    if i == #self.m_executerList then
      self.m_timer:Stop()
    end
  end, duration, loop, false)
  self.m_timer:Start()
end

function SettlementExeManager:PauseAutoExe()
  if self.m_timer then
    self.m_timer:Pause()
    return true
  end
  return false
end

function SettlementExeManager:ResumeAutoExe()
  if self.m_timer then
    self.m_timer:Resume()
    return true
  end
  return false
end

function SettlementExeManager:StopAutoExe()
end

function SettlementExeManager:StopExeAndClear()
  self:Dispose()
end

function SettlementExeManager:Execute(flow)
  local cache = 0
  for index, exe in ipairs(self.m_executerList) do
    if exe.flow == flow then
      exe.func(exe.param)
      exe.exed = true
      cache = index
    end
  end
  if self.m_executerList[cache] then
    table.remove(self.m_executerList, cache)
  end
end

function SettlementExeManager:GenExecuter(flow, func, param, auto)
  local executer = {
    flow = flow,
    param = param,
    func = func,
    exed = auto
  }
  return type(func) == "function" and type(flow) == "number", executer
end

function SettlementExeManager:Dispose()
  if self.m_timer ~= nil then
    self.m_timer:Stop()
  end
  self.m_timer = nil
  self.m_executerList = {}
  self.m_inBattle = false
end

return SettlementExeManager
