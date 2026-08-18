local TowerLockWarnPage = class("UI.Tower.TowerLockWarnPage", LuaUIPage)

function TowerLockWarnPage:DoInit()
  self.chapter = 30007
  self.startTime = 0
  self.times = 0
  self.themeIndex = 1
end

function TowerLockWarnPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local fleetType = self.param.fleetType or FleetType.Tower
  local fleetData = Data.fleetData:GetShipByFleet(1, fleetType)
  local battleTimeDefault = Logic.towerLogic:GetShipBattleTimes(fleetType)
  local chapterTowerConfig = Logic.towerLogic:GetTowerConfigByFleetType(fleetType)
  local battle_point_default = chapterTowerConfig.battle_point_default
  UIHelper.SetLocText(widgets.tx_times, 1700037, chapterTowerConfig.battle_point_cost)
  UIHelper.SetLocText(widgets.tx_tips, 1700058, chapterTowerConfig.battle_point_min)
  UIHelper.CreateSubPart(widgets.item, widgets.content, #fleetData, function(index, tabPart)
    local heroId = fleetData[index]
    local heroInfo = Data.heroData:GetHeroById(heroId)
    ShipCardItem:LoadVerticalCard(heroId, tabPart.childpart, VerCardType.FleetBottom, nil, fleetType)
    local heroAttr = Logic.attrLogic:GetHeroFianlAttrById(heroId, fleetType)
    local curHp = Logic.shipLogic:GetHeroHp(heroId, fleetType)
    local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroAttr[AttrType.HP])
    UIHelper.SetImage(tabPart.imgHp, NewHpStatusImg[hpStatus + 1])
    tabPart.slider.value = curHp / heroAttr[AttrType.HP]
    local hurtPer = Logic.towerLogic:CalTowerHurtPer(heroInfo.TemplateId, fleetType)
    local shipBattleCount = Logic.towerLogic:GetShipBattleCount(heroInfo.TemplateId, fleetType)
    local userPoint = battleTimeDefault - shipBattleCount
    tabPart.tx_num.text = userPoint .. "/" .. battle_point_default
    tabPart.tx_num_red.text = userPoint .. "/" .. battle_point_default
    tabPart.tx_times.text = hurtPer .. "%"
    tabPart.tx_times_red.text = hurtPer .. "%"
    tabPart.times:SetActive(0 < hurtPer)
    tabPart.times_red:SetActive(hurtPer <= 0)
    tabPart.Reducenum:SetActive(0 < hurtPer)
    tabPart.Reducenum_red:SetActive(hurtPer <= 0)
  end)
end

function TowerLockWarnPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self.btn_confirm, self)
end

function TowerLockWarnPage:btn_close(go, content)
  UIHelper.ClosePage("TowerLockWarnPage")
end

function TowerLockWarnPage:btn_confirm(go, content)
  UIHelper.ClosePage("TowerLockWarnPage")
  local params = self:GetParam() or {}
  if params.callback then
    params.callback()
  end
end

return TowerLockWarnPage
