local PrefsLogic = class("logic.PrefsLogic")

function PrefsLogic:initialize()
  self:RegisterAllEvent()
end

function PrefsLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaCSharpEvent.InitLocalChat, self._initsetting, self)
  eventManager:RegisterEvent(LuaEvent.OpenNewModule, self._OpenNewModule, self)
end

function PrefsLogic:_initsetting()
  Data.prefsData:InitSetting()
end

function PrefsLogic:_OpenNewModule(conflist)
  local ismodi = false
  for _, conf in ipairs(conflist) do
    if conf.fi_id == "26" then
      CacheUtil.SetBattleGameSpeedIndex(BattleGameSpeedIndex.THR)
      ismodi = true
    elseif conf.fi_id == "56" then
      CacheUtil.SetSkipEnemyTorpedoPlayAnim(true)
      ismodi = true
    end
  end
  if ismodi then
    PlayerPrefs.Save()
    Data.prefsData:SaveAll()
  end
end

return PrefsLogic
