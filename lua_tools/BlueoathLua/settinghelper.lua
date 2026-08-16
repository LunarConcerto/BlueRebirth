SettingHelper = {}
local cacheData = {}
local changeData = {
  otherData = {}
}
local SaveFunc = {
  volumeData = function()
    SettingHelper._SaveVolume()
  end,
  qualityData = function()
    SettingHelper._SaveQuality()
  end,
  operateData = function()
    SettingHelper._SaveOperate()
  end,
  otherData = function()
    SettingHelper._SaveOther()
  end,
  speedData = function()
    SettingHelper._SaveSpeed()
  end,
  controlScale = function()
    SettingHelper._SaveControlScale()
  end,
  noticeData = function()
    SettingHelper._SaveNotice()
  end
}

function SettingHelper.GetAllSetting()
  local data = {}
  local qualityData = SettingHelper.GetQualitySetting()
  data.globalQuality = qualityData.globalQuality
  data.qualityDataMap = qualityData.qualityDataMap
  data.three = qualityData.three
  data.fenbianlv = qualityData.fenbianlv
  data.switch = qualityData.switch
  data.four = qualityData.four
  data.volumeData = SettingHelper.GetVolumeFromPlayerPrefs()
  data.operateData = SettingHelper.GetOperateFromPlayerPrefs()
  data.speedData = SettingHelper.GetSpeedFromPlayerPrefs()
  data.otherData = SettingHelper.GetOtherFromPlayerPrefs()
  data.controlScale = SettingHelper.GetControlScale()
  data.noticeData = SettingHelper.GetNoticeFromPlayerPrefs()
  cacheData = data
  return data
end

function SettingHelper.GetQualitySetting()
  local data = {}
  data.globalQuality = GR.qualityManager:getGlobalQuality()
  local qualityDataMap = {}
  local three = {}
  local switch = {}
  local fenbianlv = {}
  local four = {}
  data.qualityDataMap = qualityDataMap
  data.three = three
  data.fenbianlv = fenbianlv
  data.switch = switch
  data.four = four
  qualityDataMap.resolution = {
    name = "\229\136\134\232\190\168\231\142\135",
    curLv = GR.qualityManager:getQualityLvByType(QualityType.ResolutionQuality),
    count = 2,
    type = QualityType.ResolutionQuality,
    select = {
      ResolutionQuality.Low,
      ResolutionQuality.Middle
    }
  }
  qualityDataMap.shadow = {
    name = "\233\152\180\229\189\177",
    curLv = GR.qualityManager:getQualityLvByType(QualityType.ShadowQuality),
    count = 3,
    type = QualityType.ShadowQuality,
    select = {
      ShadowQuality.Disable,
      ShadowQuality.HardOnly,
      ShadowQuality.All
    }
  }
  qualityDataMap.postProcess = {
    name = "\229\144\142\229\164\132\231\144\134",
    curLv = GR.qualityManager:getQualityLvByType(QualityType.PostProcessQuality),
    count = 1,
    type = QualityType.PostProcessQuality,
    select = {
      PostProcessQuality.Close,
      PostProcessQuality.Open
    }
  }
  qualityDataMap.battleRole = {
    name = "\232\167\146\232\137\178\230\143\143\232\190\185",
    curLv = GR.qualityManager:getQualityLvByType(QualityType.OutlineQuality),
    count = 1,
    type = QualityType.OutlineQuality,
    select = {
      OutlineQuality.Close,
      OutlineQuality.Open
    }
  }
  qualityDataMap.shader = {
    name = "\230\184\178\230\159\147\232\180\168\233\135\143",
    curLv = GR.qualityManager:getQualityLvByType(QualityType.ShaderQuality),
    count = 3,
    type = QualityType.ShaderQuality,
    select = {
      ShaderQuality.Low,
      ShaderQuality.Middle,
      ShaderQuality.High
    }
  }
  qualityDataMap.bones = {
    name = "\229\138\168\228\189\156\232\180\168\233\135\143",
    curLv = GR.qualityManager:getQualityLvByType(QualityType.ActionQuality),
    count = 3,
    type = QualityType.ActionQuality,
    select = {
      BlendWeights.OneBone,
      BlendWeights.TwoBones,
      BlendWeights.FourBones
    }
  }
  qualityDataMap.antiAliasing = {
    name = "\230\138\151\233\148\175\233\189\191",
    curLv = GR.qualityManager:getQualityLvByType(QualityType.AntiAliasingQuality),
    count = 3,
    type = QualityType.AntiAliasingQuality,
    select = {
      AntiAliasingQuality.Low,
      AntiAliasingQuality.Middle,
      AntiAliasingQuality.High
    }
  }
  local highFps = GR.qualityManager:getHighFps()
  local lowName = 0 < highFps and "60FPS" or "30FPS"
  local highName = 0 < highFps and "120FPS" or "60FPS"
  qualityDataMap.fps = {
    name = "\229\184\167\230\149\176\233\153\144\229\136\182",
    curLv = GR.qualityManager:getQualityLvByType(QualityType.FpsQuality),
    count = 2,
    type = QualityType.FpsQuality,
    select = {
      FpsQuality.Low,
      FpsQuality.High
    },
    lowName = lowName,
    highName = highName
  }
  table.insert(three, qualityDataMap.shader)
  table.insert(three, qualityDataMap.bones)
  table.insert(three, qualityDataMap.shadow)
  table.insert(three, qualityDataMap.antiAliasing)
  table.insert(fenbianlv, qualityDataMap.fps)
  table.insert(fenbianlv, qualityDataMap.resolution)
  table.insert(switch, qualityDataMap.postProcess)
  table.insert(switch, qualityDataMap.battleRole)
  return data
end

function SettingHelper.GetVolumeFromPlayerPrefs()
  return SoundHelper.GetSoundData()
end

function SettingHelper.GetOperateFromPlayerPrefs()
  local data = {}
  data.operateMode = CacheUtil.GetBattleRotationOpe()
  data.showAnim = CacheUtil.GetShowOperationWhenAnim()
  data.torpedoMode = CacheUtil.GetReleaseTorpedoModeValue()
  return data
end

function SettingHelper.GetSpeedFromPlayerPrefs()
  local data = {}
  data.speedMode = CacheUtil.GetBattleRightAreaOpe()
  return data
end

function SettingHelper.GetControlScale()
  return CacheUtil.GetOpeRatationAddRadio()
end

function SettingHelper.GetOtherFromPlayerPrefs()
  local data = {
    otherData = {}
  }
  data.otherData.player = CacheUtil.GetIsSkipSkillAnimIndex(true)
  data.otherData.enemy = CacheUtil.GetIsSkipSkillAnimIndex(false)
  data.otherData.animSpeed = CacheUtil.GetBattleGameSpeedIndex()
  data.otherData.enemyTorpedo = CacheUtil.GetSkipEnemyTorpedoPlayAnim()
  data.otherData.nearBullet = CacheUtil.GetSkipZhiJingDanBuffAnim()
  data.otherData.hitmiss = CacheUtil.GetSkipSkillAnimResult()
  data.otherData.autoAttak = CacheUtil.GetBattleResultAutoContinueSearch()
  data.otherData.hitCameraZoom = CacheUtil.GetSkipHitCameraZoom()
  local bathroom = Logic.setLogic:GetBathAnimOption()
  data.otherData.bathroom = bathroom == 1
  data.otherData.animMode = CacheUtil.GetUseSimpleAnim()
  return data
end

function SettingHelper.GetNoticeFromPlayerPrefs()
  return NoticeHelper.GetNoticeData()
end

function SettingHelper.SetQuality(value)
  GR.qualityManager:setGlobalQuality(value)
  changeData.qualityData = 1
end

function SettingHelper.SetBGMVolume(value)
  cacheData.volumeData.bgm = value
  changeData.volumeData = 1
end

function SettingHelper.SetAudioVolume(value)
  cacheData.volumeData.audio = value
  changeData.volumeData = 1
end

function SettingHelper.SetCVVolume(value)
  cacheData.volumeData.cv = value
  changeData.volumeData = 1
end

function SettingHelper.SetControlScale(value)
  cacheData.controlScale = value
  changeData.controlScale = 1
end

function SettingHelper.SetSkillAnimSpeed(value)
  cacheData.otherData.otherData.animSpeed = value
  changeData.otherData.animSpeed = 1
end

function SettingHelper.SetNearBulletAnim(value)
  cacheData.otherData.otherData.nearBullet = value
  changeData.otherData.nearBullet = 1
end

function SettingHelper.SetEnemyTorpedoAnim(value)
  cacheData.otherData.otherData.enemyTorpedo = value
  changeData.otherData.enemyTorpedo = 1
end

function SettingHelper.SetEnemySkipSkillAnim(value)
  cacheData.otherData.otherData.enemy = value
  changeData.otherData.enemy = 1
end

function SettingHelper.SetPlayerSkipSkillAnim(value)
  cacheData.otherData.otherData.player = value
  changeData.otherData.player = 1
end

function SettingHelper.SetSpeedMode(value)
  cacheData.speedData.speedMode = value
  changeData.speedData = 1
end

function SettingHelper.SetOperateMode(value)
  cacheData.operateData.operateMode = value
  changeData.operateData = 1
end

function SettingHelper.SetShowOperationWhenAnim(value)
  cacheData.operateData.showAnim = value
  changeData.operateData = 1
end

function SettingHelper.SetTorpedoMode(value)
  cacheData.operateData.torpedoMode = value
  changeData.operateData = 1
end

function SettingHelper.SetSkipSkillAnimResul(value)
  cacheData.otherData.otherData.hitmiss = value
  changeData.otherData.hitmiss = 1
end

function SettingHelper.SetBattleResultAutoContinueSearch(value)
  cacheData.otherData.otherData.autoAttak = value
  changeData.otherData.autoAttak = 1
end

function SettingHelper.SetSkipHitCameraZoom(value)
  cacheData.otherData.otherData.hitCameraZoom = value
  changeData.otherData.hitCameraZoom = 1
end

function SettingHelper.SetBathroomAnim(value)
  cacheData.otherData.otherData.bathroom = value
  changeData.otherData.bathroom = 1
end

function SettingHelper.SetAnimMode(value)
  cacheData.otherData.otherData.animMode = value
  changeData.otherData.animMode = 1
end

function SettingHelper.SetSupplyNotice(value)
  cacheData.noticeData.supplyInTwelve = value
  cacheData.noticeData.supplyInEighteen = value
  changeData.noticeData = 1
end

function SettingHelper.SetWishWallNotice(value)
  cacheData.noticeData.wishWall = value
  changeData.noticeData = 1
end

function SettingHelper.SetSupportFleetNotice(value)
  cacheData.noticeData.supportFleet = value
  changeData.noticeData = 1
end

function SettingHelper.SetBuildNotice(value)
  cacheData.noticeData.build = value
  changeData.noticeData = 1
end

function SettingHelper.SetBathNotice(value)
  cacheData.noticeData.bath = value
  changeData.noticeData = 1
end

function SettingHelper.SetMoodNotice(value)
  cacheData.noticeData.mood = value
  changeData.noticeData = 1
end

function SettingHelper.SetProduceNotice(value)
  cacheData.noticeData.produce = value
  changeData.noticeData = 1
end

function SettingHelper.SetOilNotice(value)
  cacheData.noticeData.oil = value
  changeData.noticeData = 1
end

function SettingHelper.SetGoldNotice(value)
  cacheData.noticeData.gold = value
  changeData.noticeData = 1
end

function SettingHelper.SetFreeBuildShipNotice(value)
  cacheData.noticeData.freeBuildShip = value
  changeData.noticeData = 1
end

function SettingHelper.SaveAllSetting()
  local noticeSetting = cacheData.noticeData
  for k, v in pairs(changeData) do
    SaveFunc[k]()
  end
  if changeData.noticeData == 1 then
    eventManager:SendEvent(LuaEvent.NoticeSetingHasChanged, noticeSetting)
    eventManager:SendEvent(LuaEvent.PushAllNotice)
  end
  changeData = {
    otherData = {}
  }
  PlayerPrefs.Save()
  Data.prefsData:SaveAll()
end

function SettingHelper._SaveVolume()
  SoundHelper.SetSoundData(cacheData.volumeData)
end

function SettingHelper._SaveQuality()
  GR.qualityManager:saveAll()
end

function SettingHelper._SaveOperate()
  CacheUtil.SetBattleRotationOpe(cacheData.operateData.operateMode)
  CacheUtil.SetShowOperationWhenAnim(cacheData.operateData.showAnim)
  CacheUtil.SetReleaseTorpedoMode(cacheData.operateData.torpedoMode)
end

function SettingHelper._SaveOther()
  if changeData.otherData.bathroom then
    Logic.setLogic:SetBathAnimOption(cacheData.otherData.otherData.bathroom)
  end
  if changeData.otherData.autoAttak then
    CacheUtil.SetBattleResultAutoContinueSearch(cacheData.otherData.otherData.autoAttak)
  end
  if changeData.otherData.hitmiss then
    CacheUtil.SetSkipSkillAnimResul(cacheData.otherData.otherData.hitmiss)
  end
  if changeData.otherData.nearBullet then
    CacheUtil.SetSkipZhiJingDanBuffAnim(cacheData.otherData.otherData.nearBullet)
  end
  if changeData.otherData.enemyTorpedo then
    CacheUtil.SetSkipEnemyTorpedoPlayAnim(cacheData.otherData.otherData.enemyTorpedo)
  end
  if changeData.otherData.animSpeed then
    CacheUtil.SetBattleGameSpeedIndex(cacheData.otherData.otherData.animSpeed)
  end
  if changeData.otherData.enemy then
    CacheUtil.SetSkipIsSkillAnimIndex(false, cacheData.otherData.otherData.enemy)
  end
  if changeData.otherData.player then
    CacheUtil.SetSkipIsSkillAnimIndex(true, cacheData.otherData.otherData.player)
  end
  if changeData.otherData.hitCameraZoom then
    CacheUtil.SetSkipHitCameraZoom(cacheData.otherData.otherData.hitCameraZoom)
  end
  if changeData.otherData.animMode then
    CacheUtil.SetUseSimpleAnim(cacheData.otherData.otherData.animMode)
  end
end

function SettingHelper._SaveSpeed()
  CacheUtil.SetBattleRightAreaOpe(cacheData.speedData.speedMode)
end

function SettingHelper._SaveControlScale()
  CacheUtil.SetOpeRatationAddRadio(cacheData.controlScale)
end

function SettingHelper._SaveNotice()
  NoticeHelper.SetNoticeData(cacheData.noticeData)
end
