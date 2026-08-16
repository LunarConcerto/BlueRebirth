local BagEquipItem = class("UI.Bag.BagEquipItem")

function BagEquipItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.equipInfo = nil
  self.type = nil
  self.index = 0
end

function BagEquipItem:Init(obj, tabPart, data, type, index)
  self.page = obj
  self.tabPart = tabPart
  self.equipInfo = data
  self.type = type
  self.index = index
  local equipId = self.equipInfo.EquipId
  local fleetType = FleetType.Normal
  if self.page._GetFleetType then
    fleetType = self.page:_GetFleetType()
  end
  local hero = Data.equipData:GetEquipHero(equipId, fleetType)
  self.tabPart.obj_girl:SetActive(0 < hero)
  if 0 < hero then
    local heroData = Data.heroData:GetHeroById(hero)
    if heroData then
      local heroConfig = Logic.shipLogic:GetShipShowByHeroId(hero)
      local heroInfo = Logic.shipLogic:GetShipInfoByHeroId(hero)
      self.tabPart.img_girlName.text = Logic.shipLogic:GetRealName(hero)
      UIHelper.SetImage(self.tabPart.img_girl, tostring(heroConfig.ship_icon5))
      UIHelper.SetImage(self.tabPart.img_girlbg, SmallGirlQuality[heroInfo.quality])
    else
      logError("get hero data failure,heroId:" .. hero)
    end
  end
  if tabPart.obj_towerlock then
    local towerLockStatus = Logic.equipLogic:GetTowerLockStatus(equipId, fleetType)
    tabPart.obj_towerlock:SetActive(towerLockStatus ~= 0)
    if towerLockStatus == 1 then
      tabPart.tx_locked.text = UIHelper.GetString(1700049)
    elseif towerLockStatus == 2 then
      tabPart.tx_locked.text = UIHelper.GetString(1700048)
    end
  end
  local isAEquip = Logic.equipLogic:IsAEquip(self.equipInfo.TemplateId)
  self.tabPart.obj_activity:SetActive(isAEquip)
  if type == EquipToBagSign.CHANGE_EQUIP or type == EquipToBagSign.AddEquip then
    isAEquip = Logic.equipLogic:CanChange(hero, index, equipId, fleetType)
    self.tabPart.obj_nochange:SetActive(not isAEquip)
  elseif type == EquipToBagSign.DISMANTLE_EQUIP then
    isAEquip = Logic.equipLogic:CanDelect(self.equipInfo.TemplateId)
    self.tabPart.obj_nodel:SetActive(not isAEquip)
  end
  local isLLEquip = Logic.equipLogic:IsLLEquip(self.equipInfo.TemplateId)
  self.tabPart.obj_limit:SetActive(isLLEquip)
  self.tabPart.img_select.enabled = false
  self.tabPart.txt_equipName.text = self.equipInfo.name
  UIHelper.SetImage(self.tabPart.img_goods, tostring(self.equipInfo.icon))
  UIHelper.SetImage(self.tabPart.img_quality, QualityIcon[self.equipInfo.quality])
  if self.equipInfo.Num == nil then
    self.tabPart.txt_num.text = "x" .. "1"
  else
    self.tabPart.txt_num.text = "x" .. self.equipInfo.Num
  end
  if self.equipInfo.EnhanceLv == 0 then
    self.tabPart.txt_lv.gameObject:SetActive(false)
  else
    self.tabPart.txt_lv.gameObject:SetActive(true)
    self.tabPart.txt_lv.text = "+" .. math.tointeger(self.equipInfo.EnhanceLv)
  end
  UIHelper.SetStar(self.tabPart.obj_star, self.tabPart.trans_star, self.equipInfo.Star)
  if self.type == EquipToBagSign.RISE_STAR then
    self:SetRiseClick()
  elseif self.type == EquipToBagSign.DISMANTLE_EQUIP then
    self:SetDismantleClick()
  else
    self:SetNormalClick()
  end
  local new = Logic.equipLogic:IsNewEquip(self.equipInfo.EquipId)
  self.tabPart.obj_newSign:SetActive(new)
  if tabPart.obj_fashion ~= nil then
    local isHave = Logic.equipLogic:EquipIsHaveEffect(self.equipInfo.TemplateId)
    tabPart.obj_fashion:SetActive(isHave)
  end
end

function BagEquipItem:SetRiseClick()
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_equip, function()
    self.page:ClickSelectEquip(not self.tabPart.img_select.enabled, self.index, self.equipInfo)
  end)
end

function BagEquipItem:SetNormalClick()
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_equip, function()
    self.page:ClickEquipDetail(self.equipInfo.EquipId)
  end)
end

function BagEquipItem:SetDismantleClick()
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_equip, function()
    self.page:_ClickEquipDismantle(self.equipInfo, self.tabPart)
  end)
  UGUIEventListener.AddButtonOnClick(self.tabPart.obj_selectTag, function()
    self.page:_ClickSubEquip(self.equipInfo, self.tabPart)
  end)
end

return BagEquipItem
