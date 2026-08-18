local SetFlagShipBehaviour = class("game.Guide.guidebehaviours.SetFlagShipBehaviour", GR.requires.BehaviourBase)

function SetFlagShipBehaviour:doBehaviour()
  self:_set()
end

function SetFlagShipBehaviour:_set()
  local nShipInfoId = self.objParam
  local tblFleetData = Data.fleetData:GetFleetData()
  local tblFirstFleetData = tblFleetData[1]
  local bTargetShipOnBattle = false
  tblFleetData = Logic.fleetLogic:InitFleetInfo(tblFleetData)
  local tblHeroInfos = tblFirstFleetData.heroInfo
  local nCount = #tblHeroInfos
  for i = 1, nCount do
    local nHeroId = tblHeroInfos[i]
    local tblHeroData = Data.heroData:GetHeroById(nHeroId)
    local nHeroShipInfoId = configManager.GetDataById("config_ship_main", tblHeroData.TemplateId).ship_info_id
    if nHeroShipInfoId == nShipInfoId then
      if i == 1 then
        self:onDone()
        return
      else
        bTargetShipOnBattle = true
        local nFirstHeroId = tblHeroInfos[1]
        tblHeroInfos[1] = nHeroId
        tblHeroInfos[i] = nFirstHeroId
      end
    end
  end
  local nTargetHeroId
  if not bTargetShipOnBattle then
    local tblAllHeroData = Data.heroData:GetHeroData()
    for nHeroId, tblHero in pairs(tblAllHeroData) do
      local nHeroShipInfoId = configManager.GetDataById("config_ship_main", tblHero.TemplateId).ship_info_id
      if nHeroShipInfoId == nShipInfoId then
        nTargetHeroId = tblHero.HeroId
        break
      end
    end
    if nTargetHeroId == nil then
      logError("no such ship")
      self:onDone()
      return
    else
      local bOnCursade = Logic.shipLogic:IsInCrusade(nTargetHeroId)
      if bOnCursade then
        logError("bOnCursade")
        return
      end
      tblHeroInfos[1] = nTargetHeroId
    end
  end
  eventManager:RegisterEvent(LuaEvent.SetFleetMsg, self._onSetOk, self)
  local tacticsTab = {tactics = tblFleetData}
  Service.fleetService:SendSetFleet(tacticsTab)
end

function SetFlagShipBehaviour:_onSetOk()
  eventManager:UnregisterEvent(LuaEvent.SetFleetMsg, self._onSetOk)
  self:onDone()
end

return SetFlagShipBehaviour
