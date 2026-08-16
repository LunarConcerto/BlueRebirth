local FleetHomePage = class("UI.Fleet.FleetHomePage")
local zelf

function FleetHomePage:Init(owner)
  zelf = owner
  self.isImmeAttack = false
  self.sendRepaire = false
end

function FleetHomePage:DoOnOpen(isLevelOpen)
  if not isLevelOpen then
    eventManager:SendEvent(LuaEvent.HomePlayTween, true)
    eventManager:SendEvent(LuaEvent.HomePageOtherPageOpen, LeftOpenInde.Fleet)
  else
    zelf:OpenTopPage(nil, 1, nil, self, nil, nil, {
      {5, 2},
      {5, 1},
      {5, 5},
      {5, 22}
    })
  end
  self:_CheckIsMatchCopy()
  zelf.m_tabWidgets.obj_battleMask:SetActive(isLevelOpen)
  zelf.m_tabWidgets.obj_top:SetActive(isLevelOpen)
  self.autoRepair = Logic.copyLogic:GetAutoRepaireInfo()
end

function FleetHomePage:RegisterAllEvent()
  zelf:RegisterEvent(LuaEvent.SetFleetMsg, function()
    self:_UpdateSetFleet()
  end)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btnStrategy, self._ClickStrategy, self)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btn_attack, function()
    self:_ClickAttack()
  end, self)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btn_match, function()
    self:_MatchBtnClick()
  end, self)
  zelf:RegisterEvent(LuaEvent.Preset_2_Fleet, self._SetFleet, self)
  zelf:RegisterEvent(LuaEvent.MatchPreSuccess, self._JoinMatchRoomSuc, self)
  zelf:RegisterEvent(LuaEvent.MatchPreFail, self._JoinMatchRoomFai, self)
end

function FleetHomePage:_InitFleet()
  local data = Data.fleetData:GetFleetData()
  zelf.m_tabFleetData = clone(data)
  for i, v in ipairs(zelf.m_tabFleetData) do
    if v.tacticName == "" then
      zelf.m_tabFleetData = Logic.fleetLogic:InitFleetInfo(zelf.m_tabFleetData)
      break
    end
  end
  zelf.m_onFleetShip = Logic.fleetLogic:GetFleetHeroId()
  zelf.m_onFleetTid = Logic.fleetLogic:GetFleetTemplateId()
  local tabHaveHero = Logic.fleetLogic:ChangeHeroTable()
  if not UIHelper.IsPageOpen("CommonHeroPage") then
    local useLastPos = zelf.fleetToGirlInfo
    zelf.fleetToGirlInfo = false
    local fleetId = zelf.m_lastTogIndex
    local recommendTbl = Logic.strategyLogic:GetRecommendByFleet(fleetId, zelf.fleetType)
    UIHelper.OpenPage("CommonHeroPage", {
      zelf,
      CommonHeroItem.Fleet,
      tabHaveHero,
      zelf.m_tabFleetData,
      useLastPos = useLastPos,
      nil,
      recommendTbl
    }, nil, false)
  end
end

function FleetHomePage:_CreateToggle()
  local maxTogNum = Logic.fleetLogic:GetFleetNum(zelf.fleetType)
  UIHelper.CreateSubPart(zelf.m_tabWidgets.obj_tog, zelf.m_tabWidgets.trans_togGroup, maxTogNum, function(nIndex, tabPart)
    tabPart.fleetIndex.text = nIndex
    UGUIEventListener.AddButtonOnClick(tabPart.btnSelect, function()
      self:_UpdateRepair()
      zelf:_SwitchTogs(nIndex)
    end, zelf)
    table.insert(zelf.togPart, tabPart)
  end)
end

function FleetHomePage:_CheckIsMatchCopy()
  self.isMatch = false
  local param = zelf:GetParam()
  if param == nil then
    self.isMatch = false
  else
    local copyInfo = configManager.GetDataById("config_copy_display", param.copyInfo.copyId)
    if copyInfo and copyInfo.is_match == 1 then
      self.isMatch = true
    end
  end
  self:SetMatchStateBtn()
end

function FleetHomePage:SetMatchStateBtn()
  zelf.m_tabWidgets.obj_match:SetActive(self.isMatch)
  if self.isMatch then
    zelf.m_tabWidgets.obj_attack:SetActive(false)
    zelf.m_tabWidgets.obj_exercises:SetActive(false)
  end
end

function FleetHomePage:_MatchBtnClick()
  if self.isMatch then
    self:_JoinMatchRoomSuc()
  end
end

function FleetHomePage:_JoinMatchRoomSuc()
  eventManager:SendEvent(LuaEvent.CloseLeftPage)
  Data.copyData:SetMatchingState(true)
  eventManager:SendEvent(LuaEvent.RefreshMatchState)
end

function FleetHomePage:_JoinMatchRoomFai()
  noticeManager:OpenTipPage(self, "\229\138\160\229\133\165\230\136\191\233\151\180\229\164\177\232\180\165\239\188\140\232\175\183\233\135\141\230\150\176\229\140\185\233\133\141!")
end

function FleetHomePage:_ClickStrategy()
  if zelf.m_bNeedSave then
    self:_SetFleet()
  end
  moduleManager:JumpToFunc(FunctionID.Strategy, {
    fleetId = zelf.m_lastTogIndex
  })
end

function FleetHomePage:_ClickAttack(battleModel)
  zelf.m_battleMode = battleModel ~= nil and battleModel or BattleMode.Normal
  zelf.m_isClickAttack = true
  if zelf.m_bNeedSave then
    self:_SetFleet()
  else
    self:_UpdateSetFleet()
  end
end

function FleetHomePage:_SetFleet()
  if zelf.m_bNeedSave then
    eventManager:SendEvent(LuaEvent.SaveFleet)
    Logic.fleetLogic:PlatformDotSaveFleet(zelf.m_tabFleetData, zelf.m_recordModelId, zelf.fleetType)
    local tacticsTab = {
      tactics = zelf.m_tabFleetData
    }
    Service.fleetService:SendSetFleet(tacticsTab)
    zelf.m_bNeedSave = false
  end
end

function FleetHomePage:_UpdateSetFleet()
  if zelf.m_isClickAttack then
    local isHasFleet = Logic.fleetLogic:IsHasFleet()
    if isHasFleet then
      if not zelf.isLevelOpen then
        UIHelper.ClosePage("CommonHeroPage")
        UIHelper.OpenPage("CopyPage")
      else
        eventManager:SendEvent(LuaEvent.FleetToBattle, zelf.m_battleMode)
      end
    else
      noticeManager:OpenTipPage(zelf, 110007)
    end
    zelf.m_isClickAttack = false
  else
    self:_InitFleet()
    zelf:_ChangeShipEnd()
  end
end

function FleetHomePage:_OpenGirlInfo(param, m_heroData)
  eventManager:SendEvent("SaveSort")
  UIHelper.ClosePage("CommonHeroPage")
  zelf.m_heroData = Logic.fleetLogic:GetCommonHeroData()
  zelf.m_tabHero = m_heroData
  zelf.fleetToGirlInfo = true
  if zelf.m_heroData ~= nil then
    local heros = {}
    for k, v in ipairs(zelf.m_heroData) do
      table.insert(heros, v.HeroId)
    end
    UIHelper.OpenPage("GirlInfo", {
      param,
      heros,
      AnimojiEnter.CanEnter
    })
    zelf.m_heroData = {}
    Logic.fleetLogic:SetCommonHeroData(nil)
  else
    zelf.m_tabHero = {}
    UIHelper.OpenPage("GirlInfo", {
      param,
      m_heroData,
      AnimojiEnter.CanEnter
    })
  end
end

function FleetHomePage:RemoveCard(fleetInfo)
  local heroInFleet = {}
  for _, v in ipairs(fleetInfo) do
    for k, _ in pairs(v) do
      table.insert(heroInFleet, k)
    end
  end
  if #heroInFleet == 1 then
    return false
  end
  return true
end

function FleetHomePage:DoOnHide()
  self:_SetFleet()
end

function FleetHomePage:_ClosePage()
  self:_SetFleet()
end

function FleetHomePage:_ImmeAttack()
  self:_UpdateRepair()
  if zelf.m_isClickAttack then
    local isHasFleet = Logic.fleetLogic:IsHasFleet(zelf.fleetType)
    if isHasFleet then
      self:_OnGoBattle()
    else
      noticeManager:OpenTipPage(zelf, 110007)
    end
  else
    self:_InitFleet()
    zelf:_ChangeShipEnd()
  end
end

function FleetHomePage:_AutoRepairCallback()
  if not self.sendRepaire or not zelf.isLevelOpen then
    return
  end
  self:_UpdateRepair()
  self:_CreateToggle()
  zelf:_RecordInfoLoadFleet()
  zelf:PerformDelay(0.2, function()
    self:_StartBattle()
  end)
end

function FleetHomePage:_UpdateRepair()
  self.repairShips, self.repairCost = self:_GetRepaireNum()
end

function FleetHomePage:_GetRepaireNum()
  local curToggleShip = {}
  local heroInfo = zelf.m_tabFleetData[zelf.m_lastTogIndex].heroInfo
  for k, v in pairs(heroInfo) do
    table.insert(curToggleShip, Data.heroData:GetHeroById(v))
  end
  local needRepairShip = Logic.repaireLogic:GetRepairShip(curToggleShip)
  local needGold = Logic.repaireLogic:CalculateNeedAllGold(needRepairShip)
  return needRepairShip, needGold
end

function FleetHomePage:OnFleetChanged()
  self:_UpdateRepair()
end

function FleetHomePage:_StartBattle()
  if Logic.forbiddenHeroLogic:CheckForbiddenHeroInTab(zelf.m_tabFleetData[zelf.m_lastTogIndex].heroInfo, ForbiddenType.Battle) then
    return
  end
  local chapterConfig = configManager.GetDataById("config_chapter", zelf.chapterId)
  local do_start = function()
    local isRunningFight = false
    local copyType = CopyType.COMMONCOPY
    local dailyGroupId
    if chapterConfig.class_type == ChapterType.DailyCopy then
      copyType = CopyType.DAILYCOPY
      _, dailyGroupId = Logic.dailyCopyLogic:GetDCBattleInfo()
    else
      local chaseTab = Logic.copyLogic:GetChase()
      if next(chaseTab) ~= nil then
        isRunningFight = chaseTab[zelf.copyId] ~= nil and chaseTab[zelf.copyId] or false
      end
    end
    prepareBattleMgr:StartBattle(zelf.m_lastTogIndex, zelf.chapterId, zelf.copyId, isRunningFight, copyType, function(ret, param)
      param.ShipEquipGridInfo = self:GetOpenEquipGridNum()
      param.RandomFactors = self.randFactor and self.randFactor.Factors or {}
    end, nil, nil, zelf.m_battleMode, dailyGroupId)
  end
  Logic.fleetLogic:SetBattleFleetId(zelf.m_lastTogIndex, zelf.fleetType)
  local heroInfo = zelf.m_tabFleetData[zelf.m_lastTogIndex].heroInfo
  Logic.fleetLogic:CheckFleetAttackConditions(heroInfo, function()
    do_start()
  end, zelf.fleetType, zelf.copyInfo)
end

function FleetHomePage:GetOpenEquipGridNum()
  local tabTemp = {}
  local fleetData = Data.fleetData:GetFleetData()
  local curAttackFleet = fleetData[zelf.m_lastTogIndex].heroInfo
  for k, v in ipairs(curAttackFleet) do
    local shipInfo = Data.heroData:GetHeroById(v)
    local openNum = Logic.shipLogic:GetShipOpenEquipNum(shipInfo)
    table.insert(tabTemp, {HeroId = v, EquipGridNum = openNum})
  end
  return tabTemp
end

function FleetHomePage:_OnGoBattle()
  if self.autoRepair and #self.repairShips > 0 then
    self:_DoRepair()
  else
    self:_StartBattle()
  end
end

function FleetHomePage:_DoRepair()
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

return FleetHomePage
