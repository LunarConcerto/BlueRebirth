local FleetTowerPage = class("UI.Fleet.FleetTowerPage")

function FleetTowerPage:Init(owner)
  self.page = owner
  self.sendRepaire = false
end

function FleetTowerPage:DoOnOpen()
  self.autoRepair = Logic.copyLogic:GetAutoRepaireInfo()
  self.page.m_tabWidgets.obj_battleMask:SetActive(true)
  self.page:OpenTopPage(nil, 1, nil, self, nil, nil, {
    {5, 2},
    {5, 1},
    {5, 5},
    {5, 22}
  })
  self.page.m_tabWidgets.obj_top:SetActive(true)
end

function FleetTowerPage:RegisterAllEvent()
  self.page:RegisterEvent(LuaEvent.SetFleetMsg, function()
    self:_UpdateSetFleet()
  end)
  UGUIEventListener.AddButtonOnClick(self.page.m_tabWidgets.btnStrategy, self._ClickStrategy, self)
  UGUIEventListener.AddButtonOnClick(self.page.m_tabWidgets.btn_attack, function()
    self:_ClickAttack()
  end, self)
end

function FleetTowerPage:_InitFleet()
  local data = Data.fleetData:GetFleetData(self.page.fleetType)
  self.page.m_tabFleetData = clone(data)
  if self.page.m_tabFleetData[1].tacticName == "" then
    self.page.m_tabFleetData[1].tacticName = UIHelper.GetString(1700034)
  end
  self.page.m_onFleetShip = Logic.fleetLogic:GetFleetHeroId(self.page.fleetType)
  self.page.m_onFleetTid = Logic.fleetLogic:GetFleetTemplateId(self.page.fleetType)
  local tabHaveHero = Logic.fleetLogic:ChangeHeroTable()
  if not UIPageManager:IsExistPage("CommonHeroPage") then
    local useLastPos = self.page.fleetToGirlInfo
    self.page.fleetToGirlInfo = false
    local fleetId = self.page.m_lastTogIndex
    local recommendTbl = Logic.strategyLogic:GetRecommendByFleet(fleetId, self.page.fleetType)
    UIHelper.OpenPage("CommonHeroPage", {
      self.page,
      CommonHeroItem.TowerFleet,
      tabHaveHero,
      self.page.m_tabFleetData,
      useLastPos = useLastPos,
      nil,
      recommendTbl,
      notSaveSort = true,
      chapterId = self.page.chapterId
    }, nil, false)
  end
  local togItem = self.page.togPart[self.page.m_lastTogIndex]
  togItem.fleetName.text = self.page.m_tabFleetData[self.page.m_lastTogIndex].tacticName
end

function FleetTowerPage:_GetRepaireNum()
  local curToggleShip = {}
  local heroInfo = self.page.m_tabFleetData[self.page.m_lastTogIndex].heroInfo
  for k, v in pairs(heroInfo) do
    table.insert(curToggleShip, Data.heroData:GetHeroById(v))
  end
  local needRepairShip = Logic.repaireLogic:GetRepairShip(curToggleShip)
  local needGold = Logic.repaireLogic:CalculateNeedAllGold(needRepairShip)
  return needRepairShip, needGold
end

function FleetTowerPage:_DoRepair()
  local userGoldData = Data.userData:GetCurrency(1)
  if userGoldData >= self.repairCost then
    local heroIds = {}
    for k, v in pairs(self.repairShips) do
      table.insert(heroIds, v.HeroId)
    end
    self.sendRepaire = true
    Service.repaireService:SendGetRepair(heroIds)
  else
    noticeManager:ShowMsgBox(110002)
  end
end

function FleetTowerPage:_UpdateRepair()
  self.repairShips, self.repairCost = self:_GetRepaireNum()
  UIHelper.SetText(self.page.m_tabWidgets.repairTxt, math.floor(self.repairCost))
end

function FleetTowerPage:_AutoRepairCallback()
  if not self.sendRepaire then
    return
  end
  self:_UpdateRepair()
  self:_CreateToggle()
  self.page:_RecordInfoLoadFleet()
  self.page:PerformDelay(0.2, function()
    self:_StartBattle()
  end)
end

function FleetTowerPage:_InitToggle()
  self.page.m_lastTogIndex = 1
end

function FleetTowerPage:_CreateToggle()
  local maxTogNum = Logic.fleetLogic:GetFleetNum(self.page.fleetType)
  UIHelper.CreateSubPart(self.page.m_tabWidgets.obj_tog, self.page.m_tabWidgets.trans_togGroup, maxTogNum, function(nIndex, tabPart)
    tabPart.fleetIndex.text = nIndex
    UGUIEventListener.AddButtonOnClick(tabPart.btnSelect, function()
      self.page:_SwitchTogs(nIndex)
      self:_UpdateRepair()
    end, self.page)
    table.insert(self.page.togPart, tabPart)
  end)
end

function FleetTowerPage:_ClickStrategy()
  if self.page.m_bNeedSave then
    self:_SetFleet()
  end
  moduleManager:JumpToFunc(FunctionID.Strategy, {
    subType = FleetSubType.Tower,
    fleetType = self.page.fleetType,
    FleetDatas = self.page.m_tabFleetData
  })
end

function FleetTowerPage:_ClickAttack(battleModel)
  self.page.m_battleMode = battleModel ~= nil and battleModel or BattleMode.Normal
  self.page.m_isClickAttack = true
  if self.page.m_bNeedSave then
    self:_SetFleet()
  else
    self:_UpdateSetFleet()
  end
end

function FleetTowerPage:_SetFleet()
  if self.page.m_bNeedSave then
    eventManager:SendEvent(LuaEvent.SaveFleet)
    Logic.fleetLogic:PlatformDotSaveFleet(self.page.m_tabFleetData, self.page.m_recordModelId, self.page.fleetType)
    local tacticsTab = {
      tactics = self.page.m_tabFleetData
    }
    Service.fleetService:SendSetFleet(tacticsTab)
    self.page.m_bNeedSave = false
  end
end

function FleetTowerPage:OnFleetChanged()
  self:_UpdateRepair()
end

function FleetTowerPage:_UpdateSetFleet()
  if self.page.m_isClickAttack then
    local isHasFleet = Logic.fleetLogic:IsHasFleet(self.page.fleetType)
    if isHasFleet then
      eventManager:SendEvent(LuaEvent.FleetToBattle, self.page.m_battleMode)
    else
      noticeManager:OpenTipPage(self.page, 110007)
    end
    self.page.m_isClickAttack = false
  else
    self:_InitFleet()
    self.page:_ChangeShipEnd()
  end
end

function FleetTowerPage:_OpenGirlInfo(param, m_heroData)
  eventManager:SendEvent("SaveSort")
  UIHelper.ClosePage("CommonHeroPage")
  self.page.m_heroData = Logic.fleetLogic:GetCommonHeroData()
  self.page.m_tabHero = m_heroData
  self.page.fleetToGirlInfo = true
  if self.page.m_heroData ~= nil then
    local heros = {}
    for k, v in ipairs(self.page.m_heroData) do
      table.insert(heros, v.HeroId)
    end
    UIHelper.OpenPage("GirlInfo", {
      param,
      heros,
      AnimojiEnter.NoCanEnter,
      fleetType = self.page.fleetType
    })
  else
    self.page.m_tabHero = {}
    UIHelper.OpenPage("GirlInfo", {
      param,
      m_heroData,
      AnimojiEnter.NoCanEnter,
      fleetType = self.page.fleetType
    })
  end
end

function FleetTowerPage:_OnGoBattle()
  if self.autoRepair and #self.repairShips > 0 then
    self:_DoRepair()
  else
    self:_StartBattle()
  end
end

function FleetTowerPage:_StartBattle()
  if Logic.forbiddenHeroLogic:CheckForbiddenHeroInTab(self.page.m_tabFleetData[self.page.m_lastTogIndex].heroInfo, ForbiddenType.Battle) then
    return
  end
  local do_start = function()
    UIHelper.ClosePage("CommonHeroPage")
    prepareBattleMgr:StartBattle(self.page.m_lastTogIndex, self.page.chapterId, self.page.copyId, false, CopyType.COMMONCOPY, function(ret, param)
      param.ShipEquipGridInfo = self:GetOpenEquipGridNum()
      param.RandomFactors = self.randFactor and self.randFactor.Factors or {}
    end, nil, nil, self.page.m_battleMode)
  end
  Logic.fleetLogic:SetBattleFleetId(self.page.m_lastTogIndex, self.page.fleetType)
  local heroInfo = self.page.m_tabFleetData[self.page.m_lastTogIndex].heroInfo
  Logic.fleetLogic:CheckFleetAttackConditions(heroInfo, function()
    do_start()
  end, self.page.fleetType, self.page.copyInfo)
end

function FleetTowerPage:GetOpenEquipGridNum()
  local tabTemp = {}
  local fleetData = Data.fleetData:GetFleetData()
  local curAttackFleet = fleetData[self.page.m_lastTogIndex].heroInfo
  for k, v in ipairs(curAttackFleet) do
    local shipInfo = Data.heroData:GetHeroById(v)
    local openNum = Logic.shipLogic:GetShipOpenEquipNum(shipInfo)
    table.insert(tabTemp, {HeroId = v, EquipGridNum = openNum})
  end
  return tabTemp
end

function FleetTowerPage:DoOnHide()
  self:_SetFleet()
end

function FleetTowerPage:DoOnClose()
  self.page = nil
end

function FleetTowerPage:_ClosePage()
  self:_SetFleet()
end

return FleetTowerPage
