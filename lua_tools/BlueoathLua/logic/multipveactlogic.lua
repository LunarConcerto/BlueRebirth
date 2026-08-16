local MultiPveActLogic = class("logic.MultiPveActLogic")
local Multi_Pve_Act_Id = 83002

function MultiPveActLogic:initialize()
  self:ResetData()
end

function MultiPveActLogic:ResetData()
end

function MultiPveActLogic:GetActConfig()
  local actConfig = configManager.GetDataById("config_activity", Multi_Pve_Act_Id)
  return actConfig
end

function MultiPveActLogic:GetActTime()
  local actConfig = Logic.multiPveActLogic:GetActConfig()
  local periodInfo = configManager.GetDataById("config_period", actConfig.period)
  local _, endTime = PeriodManager:GetPeriodTime(actConfig.period, actConfig.period_area)
  local now = time.getSvrTime()
  return endTime - now
end

function MultiPveActLogic:GetRankReward(dropTab)
  for _, dropId in ipairs(dropTab) do
    local dropInfo = configManager.GetDataById("config_drop_info", dropId)
    local itemInfo = Logic.bagLogic:GetItemByTempateId(singleDrop[1], singleDrop[2])
  end
end

function MultiPveActLogic:CheckShowTips()
  if PlayerPrefsKey.MultiPveAct then
    local setok = PlayerPrefs.GetBool(PlayerPrefsKey.MultiPveAct, false)
    local settime = PlayerPrefs.GetInt(PlayerPrefsKey.MultiPveAct .. "Time", 0)
    if setok then
      return not time.isSameDay(settime, time.getSvrTime())
    end
  end
  return true
end

return MultiPveActLogic
