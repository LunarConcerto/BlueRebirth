PlayerPrefs = class("util.PlayerPrefs")

function PlayerPrefs.SetInt(key, value)
  PlayerPrefsBase.SetInt(key, value)
end

function PlayerPrefs.GetInt(key, value)
  return PlayerPrefsBase.GetInt(key, value)
end

function PlayerPrefs.SetFloat(key, value)
  PlayerPrefsBase.SetFloat(key, value)
end

function PlayerPrefs.GetFloat(key, value)
  return PlayerPrefsBase.GetFloat(key, value)
end

function PlayerPrefs.SetString(key, value)
  PlayerPrefsBase.SetString(key, value)
end

function PlayerPrefs.GetString(key, value)
  return PlayerPrefsBase.GetString(key, value)
end

function PlayerPrefs.SetBool(key, value)
  key = PlayerPrefs.FormatKey(key)
  value = value and 1 or 0
  PlayerPrefsBase.SetInt(key, value)
end

function PlayerPrefs.GetBool(key, value)
  key = PlayerPrefs.FormatKey(key)
  value = value and 1 or 0
  local result = PlayerPrefsBase.GetInt(key, value)
  return result == 1 and true or false
end

function PlayerPrefs.FormatKey(key)
  local uid = Data.userData:GetUserUid()
  if uid then
    key = key .. uid
  end
  return key
end

function PlayerPrefs.DeleteKey(key)
  return PlayerPrefsBase.DeleteKey(key)
end

function PlayerPrefs.Save()
  PlayerPrefsBase.Save()
end

PlayerPrefsKey = {
  StrategyApply = "StrategyApply",
  StrategyUnlock = "StrategyUnlock",
  Strategy = "Strategy",
  StudyGoOn = "CLSY_STUDYMODULE_StudyGoOn",
  WishMaxShip = "CLSY_WISHMODULE_WishMaxShip",
  ActivityLookPrefix = "ActivityLook_",
  FleetAutoAddTip = "CLSY_FLEETMODULE_FleetAutoAddTip",
  OpenValentineSale = "OpenValentineSale",
  NewStrategy = "NewStrategy",
  ActivityBoss = "ActivityBoss",
  ActBossEnter = "ActBossEnter",
  MultiPveAct = "MultiPveAct"
}
return PlayerPrefs
