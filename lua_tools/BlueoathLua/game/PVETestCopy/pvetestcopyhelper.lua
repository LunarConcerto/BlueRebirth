local PVETestCopyHelper = class("game.PVETestCopy.PVETestCopyHelper")

function PVETestCopyHelper:StartCopy(nChapterId, nCopyId)
  self.nChapterId = nChapterId
  self.nCopyId = nCopyId
  local nCurType = stageMgr:GetCurStageType()
  if nCurType == EStageType.eStageSimpleBattle then
    stageMgr:Shutdown()
  end
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  self.timer = FrameTimer.New(function()
    self:_enterBattle()
  end, 5, 1)
  self.timer:Start()
end

function PVETestCopyHelper:_enterBattle()
  self.timer:Stop()
  npcAssistFleetMgr:Clear()
  local assistShipIds = npcAssistFleetMgr:CreateNpcShips4UI(self.nCopyId)
  self.hasNpcAssist = npcAssistFleetMgr:CheckNpcAssist(self.nCopyId)
  if self.hasNpcAssist then
    npcAssistFleetMgr:SetNpcAssist(true)
    local m_tabFleetData = clone(Data.fleetData:GetFleetData())
    m_tabFleetData[1].heroInfo = npcAssistFleetMgr:ReplaceFirstFleet(m_tabFleetData[1].heroInfo, assistShipIds, self.nCopyId)
    npcAssistFleetMgr:SetUIShipIds(m_tabFleetData[1].heroInfo)
    prepareBattleMgr:StartBattle(1, self.nChapterId, self.nCopyId, false, CopyType.COMMONCOPY, function(ret, param)
      self:_SetDefaultParam(ret, param, m_tabFleetData)
    end)
  else
    local m_tabFleetData = Data.fleetData:GetFleetData()
    npcAssistFleetMgr:SetUIShipIds(m_tabFleetData[1].heroInfo)
    prepareBattleMgr:StartBattle(1, self.nChapterId, self.nCopyId, false, CopyType.COMMONCOPY, function(ret, param)
      self:_SetDefaultParam(ret, param, m_tabFleetData)
    end)
  end
end

function PVETestCopyHelper:_SetDefaultParam(ret, param, m_tabFleetData)
  param.ShipEquipGridInfo = self:_GetOpenEquipGridNum()
  local strategyId = m_tabFleetData[1].strategyId
  ret.BattlePlayer.BattlePlayerList[1].FleetInfo.strategyId = strategyId
  param.SetConditions = {}
  param.SetQucikConditions = {}
  param.isStrat = false
  param.SafeLv = 0
  local tblShips = param.BattlePlayer.BattlePlayerList[1].FleetInfo.Ships
  for k, v in pairs(tblShips) do
    v.PSkill = {}
  end
end

function PVETestCopyHelper:_GetOpenEquipGridNum()
  local tabTemp = {}
  local fleetData = Data.fleetData:GetFleetData()
  local curAttackFleet = fleetData[1].heroInfo
  for k, v in ipairs(curAttackFleet) do
    local shipInfo = Data.heroData:GetHeroById(v)
    local openNum = Logic.shipLogic:GetShipOpenEquipNum(shipInfo)
    table.insert(tabTemp, {HeroId = v, EquipGridNum = openNum})
  end
  return tabTemp
end

return PVETestCopyHelper
