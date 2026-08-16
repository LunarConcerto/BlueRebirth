local PresetFleetCardItem = class("UI.PresetFleet.PresetFleetCardItem")

function PresetFleetCardItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.index = nil
  self.heroInfo = {}
end

function PresetFleetCardItem:Init(obj, heroId, nIndex, tabPart, float, fleetIndex)
  self.page = obj
  self.tabPart = tabPart
  self.index = nIndex
  self.fleetIndex = fleetIndex
  if heroId ~= 0 then
    tabPart.im_AddHero:SetActive(false)
    tabPart.btnDrag.gameObject:SetActive(true)
    tabPart.btn_openFleet.gameObject:SetActive(false)
    self:SetFleetBasicInfoNew(heroId, nIndex, tabPart)
    self:_SetDrag()
  else
    tabPart.im_AddHero:SetActive(true)
    tabPart.btnDrag.gameObject:SetActive(false)
    tabPart.btn_openFleet.gameObject:SetActive(true)
    self:_SetClick()
  end
end

function PresetFleetCardItem:SetFleetBasicInfoNew(heroId, nIndex, tabPart)
  self.heroInfo = Data.heroData:GetHeroById(heroId)
  local totalHp = Logic.shipLogic:GetHeroMaxHp(heroId, self.page.m_fleetType)
  local curHp = Logic.shipLogic:GetHeroHp(heroId, self.page.m_fleetType)
  local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, totalHp)
  UIHelper.SetImage(tabPart.imgHp, NewHpStatusImg[hpStatus + 1])
  UIHelper.CreateSubPart(tabPart.obj_star, tabPart.trans_star, self.heroInfo.Advance, function(index, part)
  end)
  ShipCardItem:LoadVerticalCard(heroId, tabPart.childpart, VerCardType.LevelDetails, nil, self.page.m_fleetType)
  tabPart.slider.value = curHp / totalHp
  local shipInfo = Data.heroData:GetHeroById(heroId)
  tabPart.textLv.text = Mathf.ToInt(shipInfo.Lvl)
  local shipInfoConfig = Logic.shipLogic:GetShipInfoById(self.heroInfo.TemplateId)
  UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipInfoConfig.ship_type])
end

function PresetFleetCardItem:_SetDrag()
  local objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  if IsNil(objEvent) then
    local obj = UIHelper.CreateGameObject(self.page.pageWidgets.obj_sourceEvent, self.tabPart.objSelf.transform)
    obj.name = "obj_event"
    objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  end
  UGUIEventListener.AddButtonOnPointDown(objEvent, function()
    self.page:OnDragCard(self.tabPart, self.heroInfo, self.index, objEvent)
  end)
  UGUIEventListener.AddButtonOnPointUp(objEvent, function()
    if self.page.m_popObj ~= nil then
      self.page.m_widgets.obj_float:SetActive(false)
      GameObject.Destroy(self.page.m_popObj)
      self.page.m_popObj = nil
      self.page:ClickFleetCard()
    end
  end)
  UGUIEventListener.AddButtonOnClick(objEvent, function()
  end)
end

function PresetFleetCardItem:_SetClick()
  local objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  if IsNil(objEvent) then
    local obj = UIHelper.CreateGameObject(self.page.pageWidgets.obj_sourceEvent, self.tabPart.objSelf.transform)
    obj.name = "obj_event"
    objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  end
  UGUIEventListener.AddButtonOnPointDown(objEvent, function()
  end)
  UGUIEventListener.AddButtonOnPointUp(objEvent, function()
  end)
  UGUIEventListener.AddButtonOnClick(objEvent, function()
    self.page.isClickCard = true
    self.page:ClickFleetCard()
  end)
end

return PresetFleetCardItem
