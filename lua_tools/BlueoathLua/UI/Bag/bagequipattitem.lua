local BagEquipAttItem = class("UI.Bag.BagEquipAttItem")
local TEXT_COUNT_LIMIT = 3

function BagEquipAttItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.equipInfo = nil
  self.index = 0
end

function BagEquipAttItem:Init(obj, tabPart, data, index)
  self.page = obj
  self.tabPart = tabPart
  self.equipInfo = data
  self.index = index
  local equipId = self.equipInfo.EquipId
  local fleetType = FleetType.Normal
  if self.page._GetFleetType then
    fleetType = self.page:_GetFleetType()
  end
  local hero = Data.equipData:GetEquipHero(equipId, fleetType)
  self.tabPart.obj_girl:SetActive(0 < hero)
  self.tabPart.obj_equip:SetActive(hero <= 0)
  if 0 < hero then
    local heroData = Data.heroData:GetHeroById(hero)
    if heroData then
      local heroConfig = Logic.shipLogic:GetShipShowByHeroId(hero)
      local heroInfo = Logic.shipLogic:GetShipInfoByHeroId(hero)
      UIHelper.SetImage(self.tabPart.img_girl, tostring(heroConfig.ship_icon5))
      UIHelper.SetImage(self.tabPart.img_girlbg, SmallGirlQuality[heroInfo.quality])
      local fleetMap = Logic.fleetLogic:GetHeroFleetMap()
      if Logic.shipLogic:IsInFleet(hero) then
        local fleetInfo = Data.fleetData:GetFleetData()
        local fleetName = fleetInfo[fleetMap[hero]].tacticName
        self.tabPart.txt_girlName.text = string.format(heroInfo.ship_name .. "(" .. fleetName .. ")")
      else
        self.tabPart.txt_girlName.text = heroInfo.ship_name
      end
    else
      logError("get hero data failure,heroId:" .. hero)
    end
  else
    UIHelper.SetText(self.tabPart.txt_girlName, "")
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
  self.tabPart.txt_equipName.text = self.equipInfo.name
  UIHelper.SetImage(self.tabPart.img_equip, tostring(self.equipInfo.icon))
  UIHelper.SetImage(self.tabPart.img_quality, QualityIcon[self.equipInfo.quality])
  if self.equipInfo.EnhanceLv == 0 then
    self.tabPart.txt_lvl.gameObject:SetActive(false)
  else
    self.tabPart.txt_lvl.gameObject:SetActive(true)
    self.tabPart.txt_lvl.text = "+" .. math.tointeger(self.equipInfo.EnhanceLv)
  end
  UIHelper.SetStar(self.tabPart.obj_star, self.tabPart.trans_star, self.equipInfo.Star)
  local property = Logic.equipLogic:GetCurEquipFinaAttr(self.equipInfo.EquipId)
  local attrTab = {}
  for k, v in pairs(property) do
    table.insert(attrTab, v)
  end
  self:AttrItem(attrTab)
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_equip, function()
    self.page:ClickEquipDetail(self.equipInfo.EquipId)
  end)
end

function BagEquipAttItem:AttrItem(attr)
  UIHelper.CreateSubPart(self.tabPart.obj_attr, self.tabPart.trans_attr, 6, function(nIndex, tabPart)
    local attrInfo = attr[nIndex]
    local showAttr = attrInfo ~= nil
    tabPart.txt_name.gameObject:SetActive(showAttr)
    tabPart.txt_value.gameObject:SetActive(showAttr)
    tabPart.img_attr.gameObject:SetActive(showAttr)
    if showAttr then
      local _, count = string.gsub(attrInfo.name, "[^\128-\193]", "")
      if count < TEXT_COUNT_LIMIT then
        tabPart.txt_name.fontSize = 18
      else
        tabPart.txt_name.fontSize = 15
      end
      tabPart.txt_name.text = attrInfo.name
      local value
      if Logic.equipLogic:IsShowIntAttr(attrInfo.attr) then
        value = math.tointeger(attrInfo.value)
      else
        value = attrInfo.value
      end
      local attrValueShow = Logic.attrLogic:GetAttrShow(attrInfo.id, attrInfo.value)
      tabPart.txt_value.text = attrValueShow
      local tabTemp = configManager.GetDataById("config_attribute", attrInfo.id)
      UIHelper.SetImage(tabPart.img_attr, tabTemp.attr_icon)
    end
  end)
end

return BagEquipAttItem
