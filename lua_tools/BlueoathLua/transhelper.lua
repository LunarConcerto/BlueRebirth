TransHelper = {}

function TransHelper.GetLoadTexIndex()
  local configs = configManager.GetData("config_loading")
  local wrap, count, total = {}, 0, 0
  for id, config in pairs(configs) do
    total = total + config.weight
    count = 0 < config.weight and total or 0
    table.insert(wrap, {ID = id, UP = count})
  end
  local seek = Mathf.Random(1, total)
  if seek <= wrap[1].UP then
    return wrap[1].ID
  end
  for i = 2, #wrap do
    if seek >= wrap[i - 1].UP and seek <= wrap[i].UP then
      return wrap[i].ID
    end
  end
end

function TransHelper.GetLoadingTip()
  local lv, ok = Data.userData:GetLevel()
  local str, strId
  strId = TransHelper.GetTipImpl(lv)
  if strId == -1 then
    return ""
  end
  str = configManager.GetDataById("config_loading_tips", strId).tips
  return str or ""
end

function TransHelper._getLoadingTipConfig()
  local pl = platformManager:CheckZyxSDK() and 1 or 0
  return TransitionManager.GetLoadingTipConfig(pl)
end

function TransHelper.GetTipImpl(lv)
  lv = lv or -1
  local data = TransHelper._getLoadingTipConfig()
  local wrap, count = {}, 0
  for id, info in pairs(data) do
    if lv >= info.level[1] and lv <= info.level[2] then
      count = count + info.weight
      table.insert(wrap, {ID = id, UP = count})
    end
  end
  if #wrap <= 0 then
    for id, info in pairs(data) do
      if -1 >= info.level[1] and -1 <= info.level[2] then
        count = count + info.weight
        table.insert(wrap, {ID = id, UP = count})
      end
    end
  end
  if #wrap <= 0 then
    return -1
  end
  local seek = Mathf.Random(1, count)
  if seek <= wrap[1].UP then
    return wrap[1].ID
  end
  for i = 2, #wrap do
    if seek >= wrap[i - 1].UP and seek <= wrap[i].UP then
      return wrap[i].ID
    end
  end
  return wrap[#wrap].ID
end

function TransHelper.GetBuildLeast()
  return 1
end

return TransHelper
