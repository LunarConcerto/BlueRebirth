local LevelFleetItem = class("UI.Copy.LevelFleetItem")

function LevelFleetItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.index = nil
  self.heroInfo = {}
end

function LevelFleetItem:Init(obj, heroId, nIndex, tabPart, chapterInfo)
  self.page = obj
  self.tabPart = tabPart
  self.index = nIndex
  if heroId ~= 0 then
    tabPart.btnDrag.gameObject:SetActive(true)
    tabPart.btn_openFleet.gameObject:SetActive(false)
    self:SetFleetBasicInfoNew(heroId, nIndex, tabPart)
    self:SetTypeDisplay(chapterInfo)
    self:_SetClick()
    self:_SetDrag()
  else
    tabPart.btnDrag.gameObject:SetActive(false)
    tabPart.btn_openFleet.gameObject:SetActive(true)
    self:_SetClick()
  end
end

function LevelFleetItem:InitItemClickDrag(obj, heroId, nIndex, tabPart, chapterInfo, click, drag)
  self.page = obj
  self.tabPart = tabPart
  self.index = nIndex
  if heroId ~= 0 then
    tabPart.btnDrag.gameObject:SetActive(true)
    tabPart.btn_openFleet.gameObject:SetActive(false)
    self:SetFleetBasicInfoNew(heroId, nIndex, tabPart)
    self:SetTypeDisplay(chapterInfo)
    if click then
      self:_SetClick()
    end
    if drag then
      self:_SetDrag()
    else
      self:_SetSweepingDrag()
    end
  else
    tabPart.btnDrag.gameObject:SetActive(false)
    tabPart.btn_openFleet.gameObject:SetActive(true)
    self:_SetClick()
  end
end

function LevelFleetItem:SetFleetBasicInfoNew(heroId, nIndex, tabPart)
  self.heroInfo = Data.heroData:GetHeroById(heroId)
  local totalHp = Logic.shipLogic:GetHeroMaxHp(heroId, self.page.m_fleetType)
  local curHp = Logic.shipLogic:GetHeroHp(heroId, self.page.m_fleetType)
  local isAssist = npcAssistFleetMgr:IsNpcHeroId(heroId)
  tabPart.assist_tag:SetActive(isAssist)
  local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, totalHp)
  UIHelper.SetImage(tabPart.imgHp, NewHpStatusImg[hpStatus + 1])
  UIHelper.CreateSubPart(tabPart.obj_star, tabPart.trans_star, self.heroInfo.Advance, function(index, part)
  end)
  ShipCardItem:LoadVerticalCard(heroId, tabPart.childpart, VerCardType.LevelDetails, nil, self.page.m_fleetType)
  tabPart.slider.value = curHp / totalHp
  local shipInfo = Data.heroData:GetHeroById(heroId)
  tabPart.textLv.text = Mathf.ToInt(shipInfo.Lvl)
  UGUIEventListener.ClearButtonEventListener(tabPart.obj_hero)
  UGUIEventListener.ClearButtonEventListener(tabPart.btn_openFleet.gameObject)
end

function LevelFleetItem:_SetDrag()
  UGUIEventListener.AddButtonOnPointDown(self.tabPart.obj_hero, function()
    self.page:OnDragCard(self.tabPart, self.heroInfo, self.index)
  end)
  UGUIEventListener.AddButtonOnPointUp(self.tabPart.obj_hero, function()
    if self.page.m_popObj ~= nil then
      self.page.m_tabWidgets.obj_float:SetActive(false)
      self.page:DragButtonUp()
    end
  end)
end

function LevelFleetItem:_SetSweepingDrag()
  UGUIEventListener.AddOnDrag(self.tabPart.obj_hero, function()
    self.page:OnDragCard(self.tabPart, self.heroInfo, self.index)
  end)
  UGUIEventListener.AddOnEndDrag(self.tabPart.obj_hero, function()
    if self.page.m_popObj ~= nil then
      self.page.m_tabWidgets.obj_float:SetActive(false)
      self.page:DragButtonUp()
    end
  end)
end

function LevelFleetItem:_SetClick()
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_openFleet, function()
    self.page:ClickFleetCard()
  end)
  UGUIEventListener.AddButtonOnClick(self.tabPart.obj_btn, function()
    self.page:ClickFleetCard()
  end)
end

function LevelFleetItem:SetTypeDisplay(chapterInfo)
  if Logic.towerLogic:IsTowerType(chapterInfo.tactic_type) then
    local hurtPer = Logic.towerLogic:CalTowerHurtPer(self.heroInfo.TemplateId, chapterInfo.tactic_type)
    self.tabPart.img_hurt.gameObject:SetActive(true)
    local imgBg = 0 < hurtPer and "uipic_ui_challenge_bg_cishu_02" or "uipic_ui_challenge_bg_cishu_01"
    UIHelper.SetImage(self.tabPart.img_hurt, imgBg)
    self.tabPart.tx_hurtNum.text = hurtPer .. "%"
  end
end

return LevelFleetItem
