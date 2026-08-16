local FleetHeroItem = class("UI.Fleet.FleetHeroItem")

function FleetHeroItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.index = nil
  self.heroInfo = {}
  self.fleetData = {}
  self.heroData = {}
  self.chapterId = 0
end

function FleetHeroItem:Init(obj, tabPart, data, index, fleetData, heroData, chapterId, tblParts)
  self.page = obj
  self.tabPart = tabPart
  self.index = index
  self.heroInfo = data
  self.fleetData = fleetData
  self.heroData = heroData
  self.chapterId = chapterId
  self.page:onRectRefresh(tblParts)
  self:_SetHeroInfo()
end

function FleetHeroItem:_SetHeroInfo()
  local recommendTbl = {}
  local fleetId = self.page.m_lastTogIndex
  if fleetId and 0 < fleetId then
    recommendTbl = Logic.strategyLogic:GetRecommendByFleet(fleetId, self.page.fleetType)
  end
  local shipInfoId = Logic.shipLogic:GetShipInfoIdByTid(self.heroInfo.TemplateId)
  self.tabPart.recommend:SetActive(recommendTbl[shipInfoId] == true)
  self.shipInfo = Logic.shipLogic:GetShipInfoById(self.heroInfo.TemplateId)
  self.tabPart.textLv.text = math.tointeger(self.heroInfo.Lvl)
  self.tabPart.obj_onFleet:SetActive(false)
  self.tabPart.im_lock.gameObject:SetActive(self.heroInfo.Lock)
  local onFleet, fleetIndex = Logic.fleetLogic:CheckOnFleet(self.page.m_onFleetShip, self.heroInfo.HeroId)
  if onFleet then
    self.tabPart.objState:SetActive(true)
    local fleetName, heroInFleetIndex = Logic.fleetLogic:GetCurFleetName(self.page.m_tabFleetData, self.heroInfo.HeroId)
    local isLocked = Logic.fleetLogic:IsShipLocked(self.page.m_tabFleetData[1], self.heroInfo.HeroId)
    if isLocked then
      fleetName = self.page.m_tabFleetData[1].lockedName
    end
    UIHelper.SetText(self.tabPart.tx_status, fleetName)
  else
    self.tabPart.objState:SetActive(false)
    local onFleetSameTId = Logic.fleetLogic:CheckOnFleetSameFId(self.fleetData, self.heroInfo.TemplateId)
    if onFleetSameTId then
      self.tabPart.obj_onFleet:SetActive(true)
    end
  end
  self:_SetDrag()
  self:_SetTypeDisplay()
  self:_SetClick()
  self:_CloseSelect()
  self:_SetHp()
  self:_SetAdvance()
end

function FleetHeroItem:_SetAdvance()
  self.tabPart.obj_star:SetActive(true)
  local starTab = {
    self.tabPart.obj_star1,
    self.tabPart.obj_star2,
    self.tabPart.obj_star3,
    self.tabPart.obj_star4,
    self.tabPart.obj_star5,
    self.tabPart.obj_star6
  }
  local startNum = self.heroInfo.Advance
  for i, v in ipairs(starTab) do
    if i <= startNum then
      starTab[i]:SetActive(true)
    else
      starTab[i]:SetActive(false)
    end
  end
end

function FleetHeroItem:_SetHp()
  local heroAttr = Logic.attrLogic:GetHeroFinalShowAttrById(self.heroInfo.HeroId, self.page.fleetType)
  local curHp = Logic.shipLogic:GetHeroHp(self.heroInfo.HeroId, self.page.fleetType)
  local hpValue = curHp / heroAttr[AttrType.HP]
  self.tabPart.slider.value = hpValue
  local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroAttr[AttrType.HP])
  UIHelper.SetImage(self.tabPart.imgHp, NewCardHpStatus[hpStatus + 1])
  ShipCardItem:LoadVerticalCard(self.heroInfo.HeroId, self.tabPart.childpart, VerCardType.FleetBottom, self.page.fleetType)
end

function FleetHeroItem:_CloseSelect()
  self.tabPart.objGolden:SetActive(false)
  self.tabPart.objMask:SetActive(false)
end

function FleetHeroItem:_SetDrag()
  local objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  if IsNil(objEvent) then
    local obj = UIHelper.CreateGameObject(self.page.m_tabWidgets.obj_sourceEvent, self.tabPart.objSelf.transform)
    obj.name = "obj_event"
    objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  end
  UGUIEventListener.AddButtonOnPointDown(objEvent, function()
    self.page:OnDragCard(self.tabPart, self.heroInfo, self.index, objEvent, FleetCardType.FleetHeroCard)
  end)
  UGUIEventListener.AddButtonOnPointUp(objEvent, function()
    if self.page.m_popObj ~= nil then
      self.page.m_tabWidgets.obj_float:SetActive(false)
      self:_CloseSelect()
      GameObject.Destroy(self.page.m_popObj)
      self.page.m_popObj = nil
      Logic.fleetLogic:SetCommonHeroData(self.heroData)
      self.page:OnClickCard(self.tabPart, self.heroInfo.HeroId, nil, self.heroData)
    end
  end)
end

function FleetHeroItem:_SetClick()
  local objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  if IsNil(objEvent) then
    local obj = UIHelper.CreateGameObject(self.page.m_tabWidgets.obj_sourceEvent, self.tabPart.objSelf.transform)
    obj.name = "obj_event"
    objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  end
  UGUIEventListener.AddButtonOnClick(objEvent, function()
    Logic.fleetLogic:SetCommonHeroData(self.heroData)
    self.page:OnClickCard(self.tabPart, self.heroInfo.HeroId, self.index)
  end)
end

function FleetHeroItem:_SetTypeDisplay()
  if self.chapterId == 0 then
    return
  end
  local chapterInfo = Logic.copyLogic:GetChaperConfById(self.chapterId)
  if Logic.towerLogic:IsTowerType(chapterInfo.tactic_type) then
    local surplus, countText = Logic.towerLogic:GetShipBattleInfo(self.heroInfo.TemplateId, self.page.fleetType)
    self.tabPart.im_towertimes1:SetActive(0 < surplus)
    self.tabPart.im_towertimes2:SetActive(surplus <= 0)
    self.tabPart.tx_towertimes1.text = countText
    self.tabPart.tx_towertimes2.text = countText
  end
end

return FleetHeroItem
