local json = require("cjson")
local PrefsData = class("data.PrefsData")

function PrefsData:initialize()
  self.mPrefsDataStr = "{}"
  self.mSyncTime = nil
end

function PrefsData:UpdateData(TPrefsRet)
  if TPrefsRet == nil then
    logError("TPrefsRet is nil !")
    return
  end
  local prefsDataStr = TPrefsRet.PrefsDataStr
  local syncTime = TPrefsRet.SyncTime
  if prefsDataStr ~= nil then
    self.mPrefsDataStr = prefsDataStr
  end
  if syncTime ~= nil then
    self.mSyncTime = syncTime
  end
end

function PrefsData:SaveAll()
  local prefsmap = {}
  local mapSettingAfter = Logic.setLogic:GetSettingAfter()
  prefsmap.OperateMode = CacheUtil.GetBattleRotationOpe()
  prefsmap.SpeedMode = CacheUtil.GetBattleRightAreaOpe()
  prefsmap.AnimSpeed = CacheUtil.GetBattleGameSpeedIndex()
  if mapSettingAfter == nil or mapSettingAfter[SettingDict.SkipEnemyTorpedoAnim] == nil then
    prefsmap.SkipEnemyTorpedoPlayAnim = CacheUtil.GetSkipEnemyTorpedoPlayAnim()
  end
  prefsmap.SkipSkipZhiJingDanBuffAnim = CacheUtil.GetSkipZhiJingDanBuffAnim()
  prefsmap.BattleResultAutoContinueSearch = CacheUtil.GetBattleResultAutoContinueSearch()
  if mapSettingAfter == nil or mapSettingAfter[SettingDict.SkipMySkillAnim] == nil then
    prefsmap.SkipPlayerSkillAnim = CacheUtil.GetIsSkipSkillAnimIndex(true)
  end
  if mapSettingAfter == nil or mapSettingAfter[SettingDict.SkipEnemySkillAnim] == nil then
    prefsmap.SkipEnemySkillAnim = CacheUtil.GetIsSkipSkillAnimIndex(false)
  end
  if mapSettingAfter == nil or mapSettingAfter[SettingDict.SkipOtherAnim] == nil then
    prefsmap.SkipSkillAnimResult = CacheUtil.GetSkipSkillAnimResult()
  end
  prefsmap.UseSimpleAnim = CacheUtil.GetUseSimpleAnim()
  prefsmap.ConfigTorpedoMode = CacheUtil.GetReleaseTorpedoModeValue()
  logDebug("Prefs save ", prefsmap)
  local prefsstr = json.encode(prefsmap)
  Service.prefsService:SendSavePrefs({PrefsDataStr = prefsstr})
end

function PrefsData:InitSetting()
  if self.mSyncTime == nil or self.mSyncTime <= 0 then
    return
  end
  local prefsDataStr = self.mPrefsDataStr or "{}"
  local prefsmap = json.decode(prefsDataStr)
  logDebug("Prefs Init Setting ", prefsmap)
  if prefsmap == nil then
    prefsmap = {}
  end
  if prefsmap.OperateMode ~= nil then
    CacheUtil.SetBattleRotationOpe(prefsmap.OperateMode)
  end
  if prefsmap.SpeedMode ~= nil then
    CacheUtil.SetBattleRightAreaOpe(prefsmap.SpeedMode)
  end
  if prefsmap.AnimSpeed ~= nil then
    CacheUtil.SetBattleGameSpeedIndex(prefsmap.AnimSpeed)
  end
  if prefsmap.SkipEnemyTorpedoPlayAnim ~= nil then
    CacheUtil.SetSkipEnemyTorpedoPlayAnim(prefsmap.SkipEnemyTorpedoPlayAnim)
  end
  if prefsmap.SkipSkipZhiJingDanBuffAnim ~= nil then
    CacheUtil.SetSkipZhiJingDanBuffAnim(prefsmap.SkipSkipZhiJingDanBuffAnim)
  end
  if prefsmap.BattleResultAutoContinueSearch ~= nil then
    CacheUtil.SetBattleResultAutoContinueSearch(prefsmap.BattleResultAutoContinueSearch)
  end
  if prefsmap.SkipPlayerSkillAnim ~= nil then
    CacheUtil.SetSkipIsSkillAnimIndex(true, prefsmap.SkipPlayerSkillAnim)
  end
  if prefsmap.SkipEnemySkillAnim ~= nil then
    CacheUtil.SetSkipIsSkillAnimIndex(false, prefsmap.SkipEnemySkillAnim)
  end
  if prefsmap.SkipSkillAnimResult ~= nil then
    CacheUtil.SetSkipSkillAnimResul(prefsmap.SkipSkillAnimResult)
  end
  if prefsmap.UseSimpleAnim ~= nil then
    CacheUtil.SetUseSimpleAnim(prefsmap.UseSimpleAnim)
  end
  if prefsmap.ConfigTorpedoMode ~= nil then
    CacheUtil.SetReleaseTorpedoMode(prefsmap.ConfigTorpedoMode)
  end
end

return PrefsData
