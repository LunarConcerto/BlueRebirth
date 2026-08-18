local FlagShipLevelTrigger = class("game.guide.guideTrigger.FlagShipLevelTrigger", GR.requires.GuideTriggerBase)

function FlagShipLevelTrigger:initialize(nType, nFlagShipLevel)
  self.type = nType
  self.param = nFlagShipLevel
end

function FlagShipLevelTrigger:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageMain then
    return
  end
  local fleetData = Data.fleetData
  if fleetData == nil then
    return
  end
  local tblFleetData = fleetData:GetFleetData()
  if tblFleetData == nil then
    return
  end
  local tblOneFleetData = tblFleetData[1]
  local tblHeroInfo = tblOneFleetData.heroInfo
  if #tblHeroInfo == 0 then
    return
  end
  local nFirstHeroId = tblHeroInfo[1]
  local heroInfo = Data.heroData:GetHeroById(nFirstHeroId)
  local nHeroLevel = heroInfo.Lvl
  if nHeroLevel >= self.param then
    self:sendTrigger()
  end
end

return FlagShipLevelTrigger
