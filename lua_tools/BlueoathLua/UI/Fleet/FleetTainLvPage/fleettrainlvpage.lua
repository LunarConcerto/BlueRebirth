local FleetTrainBase = require("ui.page.Fleet.FleetTrainBase")
local FleetTainLvPage = class("UI.Fleet.FleetTainLvPage", FleetTrainBase)
local zelf
local MAX_TAG_NUM = 4

function FleetTainLvPage:Init(owner)
  zelf = owner
  FleetTrainBase.Init(self, owner)
end

function FleetTainLvPage:DoOnOpen()
  self.copyId = zelf.param.copyId
  self.chapterId = zelf.param.chapterId
  self.autoRepair = true
  zelf.tab_Widgets.bgTrain:SetActive(true)
  zelf.tab_Widgets.trainTips:SetActive(true)
  FleetTrainBase.DoOnOpen(self)
end

function FleetTainLvPage:RegisterAllEvent()
  FleetTrainBase.RegisterAllEvent(self)
  zelf:RegisterEvent(LuaEvent.SetFleetMsg, function()
    self:_UpdateSetFleet()
  end)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btnStrategy, self._ClickStrategy, self)
  UGUIEventListener.AddButtonOnClick(zelf.m_tabWidgets.btn_attack, self._ClickAttack, self)
  zelf:RegisterEvent(LuaEvent.UpdateHeroData, function()
    self:_AutoRepairCallback()
  end)
end

function FleetTainLvPage:_InitFleet()
  local data = Data.fleetData:GetFleetData()
  zelf.m_tabFleetData = clone(data)
  if zelf.m_tabFleetData[1].tacticName == "" then
    zelf.m_tabFleetData = Logic.fleetLogic:InitFleetInfo(zelf.m_tabFleetData)
  end
  zelf.m_onFleetShip = Logic.fleetLogic:GetFleetHeroId()
  zelf.m_onFleetTid = Logic.fleetLogic:GetFleetTemplateId()
  local tabHaveHero = Logic.fleetLogic:ChangeHeroTable()
  if not UIPageManager:IsExistPage("CommonHeroPage") then
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
      recommendTbl,
      notSaveSort = true
    })
  end
  self:InitRepairToggle()
end

function FleetTainLvPage:InitRepairToggle()
  local widgets = zelf.m_tabWidgets
  widgets.repairBtnObj:SetActive(true)
  widgets.repairCostObj:SetActive(true)
  local ships, cost = self:_GetRepaireNum()
  self.repairShips = ships
  self.repairCost = cost
  UIHelper.SetText(widgets.repairTxt, math.floor(cost))
  UIHelper.AddToggleGroupChangeValueEvent(widgets.repairGroup, self, "", self.OnRepairToggle)
  widgets.repairGroup:RegisterToggle(widgets.repairOn)
  widgets.repairGroup:RegisterToggle(widgets.repairOff)
  widgets.repairGroup:SetActiveToggleIndex(1)
end

function FleetTainLvPage:OnRepairToggle(index)
  self.autoRepair = index == 1
  zelf.m_tabWidgets.repairOn.gameObject:SetActive(index == 1)
  zelf.m_tabWidgets.repairOff.gameObject:SetActive(index == 0)
end

function FleetTainLvPage:_GetRepaireNum()
  local curToggleShip = {}
  local heroInfo = zelf.m_tabFleetData[zelf.m_lastTogIndex].heroInfo
  for k, v in pairs(heroInfo) do
    table.insert(curToggleShip, Data.heroData:GetHeroById(v))
  end
  local needRepairShip = Logic.repaireLogic:GetRepairShip(curToggleShip)
  local needGold = Logic.repaireLogic:CalculateNeedAllGold(needRepairShip)
  return needRepairShip, needGold
end

function FleetTainLvPage:_DoRepair()
  local userGoldData = Data.userData:GetCurrency(1)
  if userGoldData >= self.repairCost then
    local heroIds = {}
    for k, v in pairs(self.repairShips) do
      table.insert(heroIds, v.HeroId)
    end
    Service.repaireService:SendGetRepair(heroIds)
  else
    noticeManager:ShowMsgBox(110002)
  end
end

function FleetTainLvPage:_UpdateRepair()
  self.repairShips, self.repairCost = self:_GetRepaireNum()
  UIHelper.SetText(zelf.m_tabWidgets.repairTxt, math.floor(self.repairCost))
end

function FleetTainLvPage:_AutoRepairCallback()
  self:_UpdateRepair()
  self:_CreateToggle()
  zelf:_RecordInfoLoadFleet()
  zelf:PerformDelay(0.2, function()
    self:_StartBattle()
  end)
end

function FleetTainLvPage:_InitToggle()
  zelf.m_lastTogIndex = 1
end

function FleetTainLvPage:_CreateToggle()
  UIHelper.CreateSubPart(zelf.m_tabWidgets.obj_tog, zelf.m_tabWidgets.trans_togGroup, MAX_TAG_NUM, function(nIndex, tabPart)
    tabPart.fleetIndex.text = nIndex
    UGUIEventListener.AddButtonOnClick(tabPart.btnSelect, function()
      zelf:_SwitchTogs(nIndex)
      self:_UpdateRepair()
    end, zelf)
    table.insert(zelf.togPart, tabPart)
  end)
end

function FleetTainLvPage:_ClickStrategy()
  if zelf.m_bNeedSave then
    self:_SetFleet()
  end
  moduleManager:JumpToFunc(FunctionID.Strategy, {})
end

function FleetTainLvPage:_ClickAttack()
  zelf.m_isClickAttack = true
  if zelf.m_bNeedSave then
    self:_SetFleet()
  else
    self:_UpdateSetFleet()
  end
end

function FleetTainLvPage:_SetFleet()
  if zelf.m_bNeedSave then
    Logic.fleetLogic:PlatformDotSaveFleet(zelf.m_tabFleetData, zelf.m_recordModelId)
    local tacticsTab = {
      tactics = zelf.m_tabFleetData
    }
    Service.fleetService:SendSetFleet(tacticsTab)
    zelf.m_bNeedSave = false
  end
end

function FleetTainLvPage:OnFleetChanged()
  self:_UpdateRepair()
end

function FleetTainLvPage:_UpdateSetFleet()
  if zelf.m_isClickAttack then
    local isHasFleet = Logic.fleetLogic:IsHasFleet()
    if isHasFleet then
      self:_OnGoBattle()
    else
      noticeManager:OpenTipPage(zelf, 110007)
    end
    zelf.m_isClickAttack = false
  end
end

function FleetTainLvPage:_OpenGirlInfo(param, m_heroData)
  eventManager:SendEvent("SaveSort")
  UIHelper.ClosePage("CommonHeroPage")
  zelf.m_heroData = Logic.fleetLogic:GetCommonHeroData()
  zelf.m_tabHero = m_heroData
  if zelf.m_heroData ~= nil then
    local heros = {}
    for k, v in ipairs(zelf.m_heroData) do
      table.insert(heros, v.HeroId)
    end
    UIHelper.OpenPage("GirlInfo", {
      param,
      heros,
      AnimojiEnter.NoCanEnter
    })
  else
    UIHelper.OpenPage("GirlInfo", {
      param,
      zelf.m_tabHero,
      AnimojiEnter.NoCanEnter
    })
    zelf.m_tabHero = {}
  end
  zelf.fleetToGirlInfo = true
end

function FleetTainLvPage:_OnGoBattle()
  if self.autoRepair and #self.repairShips > 0 then
    self:_DoRepair()
  else
    self:_StartBattle()
  end
end

function FleetTainLvPage:_StartBattle()
  if Logic.forbiddenHeroLogic:CheckForbiddenHeroInTab(zelf.m_tabFleetData[zelf.m_lastTogIndex].heroInfo, ForbiddenType.Battle) then
    return
  end
  local do_start = function()
    UIHelper.ClosePage("CommonHeroPage")
    prepareBattleMgr:StartBattle(zelf.m_lastTogIndex, self.chapterId, self.copyId, false, CopyType.COMMONCOPY, function(ret, param)
      param.ShipEquipGridInfo = self:GetOpenEquipGridNum()
      param.RandomFactors = self.randFactor and self.randFactor.Factors or {}
    end)
  end
  Logic.fleetLogic:SetBattleFleetId(zelf.m_lastTogIndex)
  local heroInfo = zelf.m_tabFleetData[zelf.m_lastTogIndex].heroInfo
  if self:_CheckConditions(heroInfo, function()
    do_start()
  end) then
    do_start()
  end
end

function FleetTainLvPage:GetOpenEquipGridNum()
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

function FleetTainLvPage:_CheckConditions(heroInfo, continueCallback)
  if #heroInfo <= 0 then
    noticeManager:OpenTipPage(self, 110007)
    return false
  end
  if Logic.copyLogic:CheckFlagShipDamage(heroInfo) then
    noticeManager:ShowMsgBox(110011)
    return false
  end
  if Logic.copyLogic:CheckDockFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(toRetire)
        if toRetire then
          UIHelper.ClosePage("NoticePage")
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
  if Logic.copyLogic:CheckShipSink(heroInfo) then
    noticeManager:ShowMsgBox(UIHelper.GetString(1000015))
    return false
  end
  local anyDamage = Logic.copyLogic:CheckAnyShipDamage(heroInfo)
  if anyDamage then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(goBattle)
        if goBattle then
          continueCallback()
        end
      end
    }
    noticeManager:ShowMsgBox(110013, tabParams)
    return false
  end
  return true
end

function FleetTainLvPage:DoOnHide()
  self:_SetFleet()
  FleetTrainBase.DoOnHide(self)
end

function FleetTainLvPage:DoOnClose()
  zelf = nil
  FleetTrainBase.DoOnClose(self)
end

function FleetTainLvPage:_ClosePage()
  self:_SetFleet()
end

return FleetTainLvPage
