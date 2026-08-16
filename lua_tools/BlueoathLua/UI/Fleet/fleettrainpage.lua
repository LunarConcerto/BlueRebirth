local FleetTrainBase = require("ui.page.Fleet.FleetTrainBase")
local FleetTrainPage = class("UI.Fleet.FleetTrainPage", FleetTrainBase)

function FleetTrainPage:Init(owner)
  zelf = owner
  FleetTrainBase.Init(self, owner)
end

function FleetTrainPage:DoOnOpen()
  local copyId = zelf.param.copyId
  self.copyId = zelf.param.copyId
  self.chapterId = zelf.param.chapterId
  zelf.tab_Widgets.bgTrain:SetActive(true)
  zelf.tab_Widgets.txtTrain:SetActive(true)
  zelf.tab_Widgets.trainTips:SetActive(true)
  local copyDisplay = configManager.GetDataById("config_copy_display", self.copyId)
  local strategyList = copyDisplay.training_strategy
  if #strategyList <= 1 then
    zelf.tab_Widgets.objLock:SetActive(true)
  end
  FleetTrainBase.DoOnOpen(self)
end

function FleetTrainPage:RegisterAllEvent()
  FleetTrainBase.RegisterAllEvent(self)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btn_attack, self._ClickAttack, self)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btnStrategy, self._ClickStrategy, self)
end

function FleetTrainPage:_InitFleet()
  if zelf.fleetToGirlInfo then
    self:_ShowCommonHeroPage()
    return
  end
  local copyDisplay = configManager.GetDataById("config_copy_display", self.copyId)
  local lock = copyDisplay.assist_fleet_lock
  npcAssistFleetMgr:SetNpcAssist(true)
  local assistShipIds = npcAssistFleetMgr:CreateNpcShips4UI(self.copyId)
  zelf.lockShipIds = {}
  zelf.m_tabFleetData = {}
  zelf.m_onFleetShip = {}
  zelf.m_onFleetTid = {}
  local fleetData = {}
  fleetData.modeId = 1
  fleetData.strategyId = 0
  fleetData.tacticName = UIHelper.GetString(1000003)
  fleetData.heroInfo = {}
  fleetData.lockedHeroMap = {}
  fleetData.lockedName = UIHelper.GetString(1000012)
  fleetData.totalCount = copyDisplay.assist_fleet_num
  local strategyList = copyDisplay.training_strategy
  local count = #strategyList
  if count == 1 then
    fleetData.strategyId = strategyList[1][1]
  end
  fleetData.noStrategyRedDot = count <= 1
  local onFleetIdMap = {}
  local onFleetTidMap = {}
  for i = 1, lock do
    local shipId = assistShipIds[i]
    table.insert(fleetData.heroInfo, shipId)
    onFleetIdMap[shipId] = 1
    local ship = npcAssistFleetMgr:GetNpcShipById(shipId)
    onFleetTidMap[ship.TemplateId] = shipId
    table.insert(zelf.lockShipIds, shipId)
    fleetData.lockedHeroMap[shipId] = true
  end
  table.insert(zelf.m_tabFleetData, fleetData)
  table.insert(zelf.m_onFleetShip, onFleetIdMap)
  table.insert(zelf.m_onFleetTid, onFleetTidMap)
  npcAssistFleetMgr:SetNpcFleetData(zelf.m_tabFleetData)
  self:_InitToggle()
  self:_ShowCommonHeroPage()
  self:OnFleetChanged()
end

function FleetTrainPage:_InitToggle()
  zelf.m_lastTogIndex = 1
end

function FleetTrainPage:OnFleetChanged()
  local copyDisplay = configManager.GetDataById("config_copy_display", self.copyId)
  local lockNum = copyDisplay.assist_fleet_lock
  local totalNum = copyDisplay.assist_fleet_num
  local currNum = #zelf.m_tabFleetData[1].heroInfo
  UIHelper.SetText(zelf.tab_Widgets.txtTrainNum, string.format("%s<color=#677690>/%s </color>", currNum, totalNum))
end

function FleetTrainPage:CanAddCard(isReplace)
  local copyDisplay = configManager.GetDataById("config_copy_display", self.copyId)
  local totalNum = copyDisplay.assist_fleet_num
  local currNum = #zelf.m_tabFleetData[1].heroInfo
  if totalNum <= currNum and not isReplace then
    noticeManager:ShowTip(UIHelper.GetString(1000010))
  end
  return totalNum > currNum
end

function FleetTrainPage:CanRemoveCard(heroId)
  local locked = table.containV(zelf.lockShipIds, heroId)
  if locked then
    noticeManager:ShowTip(UIHelper.GetString(1000005))
  end
  return not locked
end

function FleetTrainPage:_ShowCommonHeroPage()
  if not UIPageManager:IsExistPage("CommonHeroPage") then
    local tabHaveHero = npcAssistFleetMgr:GetTrainAllShips()
    local useLastPos = zelf.fleetToGirlInfo
    zelf.fleetToGirlInfo = false
    UIHelper.OpenPage("CommonHeroPage", {
      zelf,
      CommonHeroItem.Fleet,
      tabHaveHero,
      zelf.m_tabFleetData,
      useLastPos = useLastPos,
      notSaveSort = true
    })
  end
end

function FleetTrainPage:_CreateToggle()
  UIHelper.CreateSubPart(zelf.m_tabWidgets.obj_tog, zelf.m_tabWidgets.trans_togGroup, 1, function(nIndex, tabPart)
    tabPart.fleetIndex.text = nIndex
    UGUIEventListener.AddButtonOnClick(tabPart.btnSelect, function()
      zelf:_SwitchTogs(nIndex)
    end, zelf)
    table.insert(zelf.togPart, tabPart)
  end)
end

function FleetTrainPage:_OpenGirlInfo(param, heroData)
  eventManager:SendEvent("SaveSort")
  UIHelper.ClosePage("CommonHeroPage")
  zelf.m_heroData = Logic.fleetLogic:GetCommonHeroData()
  zelf.m_tabHero = heroData
  if zelf.m_heroData ~= nil then
    local heros = {}
    for k, v in ipairs(zelf.m_heroData) do
      table.insert(heros, v.HeroId)
    end
    local p = {
      param,
      heros,
      AnimojiEnter.NoCanEnter
    }
    p.toggleIndices = {1, 5}
    p.isNpc = true
    UIHelper.OpenPage("GirlInfo", p)
  else
    local p = {
      param,
      zelf.m_tabHero,
      AnimojiEnter.NoCanEnter
    }
    p.toggleIndices = {1, 5}
    p.isNpc = true
    UIHelper.OpenPage("GirlInfo", p)
    zelf.m_tabHero = {}
  end
  zelf.fleetToGirlInfo = true
end

function FleetTrainPage:_ClickStrategy()
  local copyDisplay = configManager.GetDataById("config_copy_display", self.copyId)
  local strategyList = copyDisplay.training_strategy
  if #strategyList <= 1 then
    noticeManager:ShowTip(UIHelper.GetString(1000011))
    return
  end
  zelf.fleetToGirlInfo = true
  local stategyIds = Logic.copyLogic:GetTrainStrategyIds(self.copyId)
  moduleManager:JumpToFunc(FunctionID.Strategy, {
    subType = FleetSubType.Train,
    StrategyIds = stategyIds,
    FleetDatas = zelf.m_tabFleetData
  })
end

function FleetTrainPage:_ClickAttack()
  if self:_CheckConditions() then
    npcAssistFleetMgr:SetUIShipIds(zelf.m_tabFleetData[1].heroInfo)
    local strategyId = zelf.m_tabFleetData[1].strategyId or 0
    prepareBattleMgr:StartBattle(1, self.chapterId, self.copyId, false, CopyType.COMMONCOPY, function(ret, param)
      param.ShipEquipGridInfo = self:GetOpenEquipGridNum()
      param.RandomFactors = self.randFactor and self.randFactor.Factors or {}
    end, strategyId)
  end
end

function FleetTrainPage:GetOpenEquipGridNum()
  local tabTemp = {}
  local curAttackFleet = zelf.m_tabFleetData[zelf.m_lastTogIndex].heroInfo
  for k, v in ipairs(curAttackFleet) do
    local shipInfo = Data.heroData:GetHeroById(v)
    local openNum = Logic.shipLogic:GetShipOpenEquipNum(shipInfo)
    table.insert(tabTemp, {HeroId = v, EquipGridNum = openNum})
  end
  return tabTemp
end

function FleetTrainPage:_CheckConditions()
  local heroInfo = zelf.m_tabFleetData[1].heroInfo
  if Logic.forbiddenHeroLogic:CheckForbiddenHeroInTab(heroInfo, ForbiddenType.Battle) then
    return
  end
  local count = #heroInfo
  local copyDisplay = configManager.GetDataById("config_copy_display", self.copyId)
  local totalNum = copyDisplay.assist_fleet_num
  if count ~= totalNum then
    noticeManager:ShowTip(UIHelper.GetString(1000013))
    return false
  end
  if Logic.copyLogic:CheckDockFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(toRetire)
        if toRetire then
          UIHelper.OpenPage("HeroRetirePage")
        end
      end
    }
    noticeManager:ShowMsgBox(110012, tabParams)
    return false
  end
  if Logic.copyLogic:CheckEquipBagFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(toEquip)
        if toEquip then
          UIHelper.ClosePage("NoticePage")
          UIHelper.OpenPage("DismantlePage")
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(1000014), tabParams)
    return false
  end
  return true
end

function FleetTrainPage:DoOnHide()
  FleetTrainBase.DoOnHide(self)
end

function FleetTrainPage:DoOnClose()
  zelf = nil
  FleetTrainBase.DoOnClose(self)
end

return FleetTrainPage
