local TowerLockedPage = class("UI.Tower.TowerLockedPage", LuaUIPage)

function TowerLockedPage:DoInit()
  self.chapter = 30007
  self.startTime = 0
  self.times = 0
  self.themeIndex = 1
end

function TowerLockedPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local fleetType = self.param.fleetType or FleetType.Tower
  local fleetData = Logic.towerLogic:GetHeroIdList(fleetType)
  UIHelper.CreateSubPart(widgets.ship, widgets.ship_content, #fleetData, function(index, tabPart)
    local heroId = fleetData[index]
    local heroInfo = Data.heroData:GetHeroById(heroId)
    local heroAttr = Logic.attrLogic:GetHeroFinalShowAttrById(heroId, fleetType)
    if heroInfo.type == HeroIndexType.HeavyAircraftCarrier then
      UIHelper.SetImage(tabPart.backAttr1, "uipic_ui_attribute_im_jianbao")
      UIHelper.SetImage(tabPart.backAttr2, "uipic_ui_attribute_im_jianzhan")
      tabPart.backAttack.text = heroAttr[AttrType.SHIP_BOMB_ATTACK]
      tabPart.backPorpedo.text = heroAttr[AttrType.SHIP_AIR_CONTROL]
    else
      UIHelper.SetImage(tabPart.backAttr1, "uipic_ui_attribute_im_paoji")
      UIHelper.SetImage(tabPart.backAttr2, "uipic_ui_attribute_im_leiji")
      tabPart.backAttack.text = heroAttr[AttrType.ATTACK]
      tabPart.backPorpedo.text = heroAttr[AttrType.TORPEDO_ATTACK]
    end
    ShipCardItem:LoadVerticalCard(heroId, tabPart.backChildPart, VerCardType.FleetSmall, nil, fleetType)
    local shipEquips = Data.heroData:GetEquipsByType(heroId, fleetType)
    local haveEquip = {}
    for k, v in pairs(shipEquips) do
      if v.EquipsId ~= 0 then
        table.insert(haveEquip, v.EquipsId)
      end
    end
    local isAEquip
    UIHelper.CreateSubPart(tabPart.obj_equip, tabPart.trans_equip, #haveEquip, function(indexSub, equipPart)
      local equipInfo = Logic.equipLogic:GetEquipById(haveEquip[indexSub])
      local shipEquipInfo = configManager.GetDataById("config_equip", equipInfo.TemplateId)
      UIHelper.SetImage(equipPart.img_equip, tostring(shipEquipInfo.icon_small))
      UIHelper.SetImage(equipPart.img_equipQuality, EquipQualityIcon[shipEquipInfo.quality])
      isAEquip = Logic.equipLogic:IsAEquip(equipInfo.TemplateId)
      equipPart.obj_activity:SetActive(isAEquip)
    end)
  end)
end

function TowerLockedPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self.btn_close, self)
end

function TowerLockedPage:btn_close(go, content)
  UIHelper.ClosePage("TowerLockedPage")
end

return TowerLockedPage
