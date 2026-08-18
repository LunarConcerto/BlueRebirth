SettleRewardScheduler = {}
local container = {}

function SettleRewardScheduler.Register(func, handler, ...)
  local action = {
    func,
    handler,
    ...
  }
  table.insert(container, action)
end

function SettleRewardScheduler.Can()
  return 0 < #container
end

function SettleRewardScheduler.Next()
  if SettleRewardScheduler.Can() then
    local action = container[1]
    table.remove(container, 1)
    action[1](action[2], action[3])
  else
    logError("next failure!!!")
  end
end

function SettleRewardScheduler.Dispose()
  container = {}
end

return SettleRewardScheduler
