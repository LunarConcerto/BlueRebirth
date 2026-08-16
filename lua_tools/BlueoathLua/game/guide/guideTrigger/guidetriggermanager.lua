local GuideTriggerManager = class("game.guide.guidetrigger.guidetriggermanager")
local requiredLevel = require("game.guide.guideTrigger.HeroLevelTrigger")
local requiredFlashipLevel = require("game.guide.guideTrigger.FlagShipLevelTrigger")
local requiredEnterCopy = require("game.guide.guideTrigger.EnterCopyTrigger")
local requiredPageOpen = require("game.guide.guideTrigger.PageOpen")
local requiredShipDamage = require("game.guide.guideTrigger.ShipDamageTrigger")
local requiredEquipAmend = require("game.guide.guideTrigger.EquipAmendTrigger")
local requiredCopyBoss = require("game.guide.guideTrigger.CopyBossTrigger")
local requiredBathRoom = require("game.guide.guideTrigger.BathRoomInitTrigger")
local requiredBathShip = require("game.guide.guideTrigger.BathShipTrigger")
local requiredBathFinish = require("game.guide.guideTrigger.BathFinishTrigger")
local requiredModelClick = require("game.guide.guideTrigger.HomeGirlClickTrigger")
local requiredGirlAnimEnd = require("game.guide.guideTrigger.GirlAnimEndTrigger")
local requiredHomeDragEnd = require("game.guide.guideTrigger.HomeDragEndTrigger")

function GuideTriggerManager:initialize()
  self.tblAllTrigger = {}
  self.tblTickTrigger = {}
  self.tblDel = {}
  self:init()
  self.objEmptyTrigger = require("game.guide.guidetrigger.emptytrigger"):new()
end

function GuideTriggerManager:init()
  LateUpdateBeat:Add(self.tick, self)
  self:InitAllTriggers()
end

function GuideTriggerManager:InitAllTriggers()
  self.tblAllTrigger[TRIGGER_TYPE.HERO_LEVEL_5] = requiredLevel:new(TRIGGER_TYPE.HERO_LEVEL_5, 5)
  self.tblAllTrigger[TRIGGER_TYPE.HERO_LEVEL_20] = requiredLevel:new(TRIGGER_TYPE.HERO_LEVEL_20, 20)
  self.tblAllTrigger[TRIGGER_TYPE.MAIN_SHIP_LEVEL_5] = requiredFlashipLevel:new(TRIGGER_TYPE.MAIN_SHIP_LEVEL_5, 5)
  self.tblAllTrigger[TRIGGER_TYPE.FLEET_DAMAGE_SMALL] = requiredShipDamage:new(TRIGGER_TYPE.FLEET_DAMAGE_SMALL, DamageLevel.SmallDamage)
  self.tblAllTrigger[TRIGGER_TYPE.FLEET_DAMAGE_MIDDLE] = requiredShipDamage:new(TRIGGER_TYPE.FLEET_DAMAGE_MIDDLE, DamageLevel.MiddleDamage)
  self.tblAllTrigger[TRIGGER_TYPE.FLEET_DAMAGE_BIG] = requiredShipDamage:new(TRIGGER_TYPE.FLEET_DAMAGE_BIG, DamageLevel.BigDamage)
  self.tblAllTrigger[TRIGGER_TYPE.EQUIP_AMEND] = requiredEquipAmend:new(TRIGGER_TYPE.EQUIP_AMEND, {
    "HomePage",
    "EquipIntensifyPage"
  })
  self.tblAllTrigger[TRIGGER_TYPE.COPY_BOSS] = requiredCopyBoss:new(TRIGGER_TYPE.COPY_BOSS, "CopyPage")
  self.tblAllTrigger[TRIGGER_TYPE.YUSHI_UI] = requiredBathRoom:new(TRIGGER_TYPE.YUSHI_UI)
  self.tblAllTrigger[TRIGGER_TYPE.SHIP_IN_BATH] = requiredBathShip:new(TRIGGER_TYPE.SHIP_IN_BATH)
  self.tblAllTrigger[TRIGGER_TYPE.BATH_FINISH] = requiredBathFinish:new(TRIGGER_TYPE.BATH_FINISH)
  self.tblAllTrigger[TRIGGER_TYPE.CLICK_GIRL] = requiredModelClick:new(TRIGGER_TYPE.CLICK_GIRL)
  self.tblAllTrigger[TRIGGER_TYPE.MAINUI_APPEAR] = requiredGirlAnimEnd:new(TRIGGER_TYPE.MAINUI_APPEAR)
  self.tblAllTrigger[TRIGGER_TYPE.TURN_GIRL] = requiredHomeDragEnd:new(TRIGGER_TYPE.TURN_GIRL)
  self.tblAllTrigger[TRIGGER_TYPE.PlotEnd] = require("game.guide.guideTrigger.PlotEndTrigger"):new(TRIGGER_TYPE.PlotEnd)
  self.tblAllTrigger[TRIGGER_TYPE.GIRL_IN_BATTLE] = require("game.guide.guideTrigger.ShipInBattleCheck"):new(TRIGGER_TYPE.GIRL_IN_BATTLE, FleetType.Normal)
  self.tblAllTrigger[TRIGGER_TYPE.PlotTrigger] = require("game.guide.guideTrigger.PlotTrigger"):new(TRIGGER_TYPE.PlotTrigger)
  self.tblAllTrigger[TRIGGER_TYPE.HomePageTweenReturn] = require("game.guide.guideTrigger.HomePageTweenEnd"):new(TRIGGER_TYPE.HomePageTweenReturn)
  self.tblAllTrigger[TRIGGER_TYPE.BathPageOpen] = requiredPageOpen:new(TRIGGER_TYPE.BathPageOpen, "BathRoomPage")
  self.tblAllTrigger[TRIGGER_TYPE.WishPageOpen] = requiredPageOpen:new(TRIGGER_TYPE.WishPageOpen, "WishPage")
  self.tblAllTrigger[TRIGGER_TYPE.TeachPageOpen] = requiredPageOpen:new(TRIGGER_TYPE.TeachPageOpen, "StudyPage")
  self.tblAllTrigger[TRIGGER_TYPE.AssistPageOpen] = requiredPageOpen:new(TRIGGER_TYPE.AssistPageOpen, "AssistNewPage")
  self.tblAllTrigger[TRIGGER_TYPE.EnterCopy_20101] = requiredEnterCopy:new(TRIGGER_TYPE.EnterCopy_20101, 201010)
  self.tblAllTrigger[TRIGGER_TYPE.EnterCopy_20201] = requiredEnterCopy:new(TRIGGER_TYPE.EnterCopy_20201, 202010)
  self.tblAllTrigger[TRIGGER_TYPE.EnterCopy_20301] = requiredEnterCopy:new(TRIGGER_TYPE.EnterCopy_20301, 203010)
  self.tblAllTrigger[TRIGGER_TYPE.EnterCopy_20401] = requiredEnterCopy:new(TRIGGER_TYPE.EnterCopy_20401, 204010)
  self.tblAllTrigger[TRIGGER_TYPE.PassCopyTrigger] = require("game.guide.guideTrigger.PassCopyTrigger"):new(TRIGGER_TYPE.PassCopyTrigger)
  self.tblAllTrigger[TRIGGER_TYPE.OnPageHide] = require("game.guide.guideTrigger.OnPageHide"):new(TRIGGER_TYPE.OnPageHide)
  self.tblAllTrigger[TRIGGER_TYPE.StrategyPageOpen] = requiredPageOpen:new(TRIGGER_TYPE.StrategyPageOpen, "SuperStrategyPage")
  self.tblAllTrigger[TRIGGER_TYPE.BattleFail] = require("game.guide.guideTrigger.BattleFail"):new(TRIGGER_TYPE.BattleFail)
  self.tblAllTrigger[TRIGGER_TYPE.EquipCanRise] = require("game.guide.guideTrigger.EquipCanRiseTrigger"):new(TRIGGER_TYPE.EquipCanRise)
  self.tblAllTrigger[TRIGGER_TYPE.HaveEquipRised] = require("game.guide.guideTrigger.EquipRiseSuccessTrigger"):new(TRIGGER_TYPE.HaveEquipRised)
  self.tblAllTrigger[TRIGGER_TYPE.ExitBattleManual] = require("game.guide.guideTrigger.ExitBattleManual"):new(TRIGGER_TYPE.ExitBattleManual)
  self.tblAllTrigger[TRIGGER_TYPE.MarryBookPageOpen] = requiredPageOpen:new(TRIGGER_TYPE.MarryBookPageOpen, "MarryBookPage")
  self.tblAllTrigger[TRIGGER_TYPE.CopyDetailPage_1_1] = require("game.guide.guideTrigger.CopyDetailPage_1_1"):new(TRIGGER_TYPE.CopyDetailPage_1_1)
  self.tblAllTrigger[TRIGGER_TYPE.StrategyEndDrag] = require("game.guide.guideTrigger.StrategyEndDrag"):new(TRIGGER_TYPE.StrategyEndDrag)
  self.tblAllTrigger[TRIGGER_TYPE.BuildTenShipReturn] = require("game.guide.guideTrigger.BuildTenShipReturn"):new(TRIGGER_TYPE.BuildTenShipReturn)
  self.tblAllTrigger[TRIGGER_TYPE.GirlInfoDetail] = require("game.guide.guideTrigger.GirlInfoDetail"):new(TRIGGER_TYPE.GirlInfoDetail)
  self.tblAllTrigger[TRIGGER_TYPE.GoodsCopyOpenTipClose] = require("game.guide.guideTrigger.GoodsCopyOpenTipClose"):new(TRIGGER_TYPE.GoodsCopyOpenTipClose)
  self.tblAllTrigger[TRIGGER_TYPE.BathRoomOpen] = require("game.guide.guideTrigger.BathRoomOpenTrigger"):new(TRIGGER_TYPE.BathRoomOpen)
  self.tblAllTrigger[TRIGGER_TYPE.SupportFleetOpen] = require("game.guide.guideTrigger.SupportFleetOpenTrigger"):new(TRIGGER_TYPE.SupportFleetOpen)
  self.tblAllTrigger[TRIGGER_TYPE.CrusadeOpen] = require("game.guide.guideTrigger.CrusadeOpenTrigger"):new(TRIGGER_TYPE.CrusadeOpen)
  self.tblAllTrigger[TRIGGER_TYPE.StrategyOpen] = require("game.guide.guideTrigger.StrategyOpenTrigger"):new(TRIGGER_TYPE.StrategyOpen)
  self.tblAllTrigger[TRIGGER_TYPE.DailyCopyOpen] = require("game.guide.guideTrigger.DailyCopyOpenTrigger"):new(TRIGGER_TYPE.DailyCopyOpen)
  self.tblAllTrigger[TRIGGER_TYPE.CanOpenRewardBox] = require("game.guide.guideTrigger.CanOpenRewardBox"):new(TRIGGER_TYPE.CanOpenRewardBox)
  self.tblAllTrigger[TRIGGER_TYPE.ShipLV5] = require("game.guide.guideTrigger.ShipLV5"):new(TRIGGER_TYPE.ShipLV5)
  self.tblAllTrigger[TRIGGER_TYPE.IsPageOpen] = require("game.guide.guideTrigger.IsPageOpen"):new(TRIGGER_TYPE.IsPageOpen)
  self.tblAllTrigger[TRIGGER_TYPE.EquipEnhaceLv] = require("game.guide.guideTrigger.EquipEnhaceLv"):new(TRIGGER_TYPE.EquipEnhaceLv)
  self.tblAllTrigger[TRIGGER_TYPE.EnterCopyPage] = require("game.guide.guideTrigger.EnterCopyPage"):new(TRIGGER_TYPE.EnterCopyPage)
  self.tblAllTrigger[TRIGGER_TYPE.TowerOpen] = require("game.guide.guideTrigger.TowerOpen"):new(TRIGGER_TYPE.TowerOpen)
  self.tblAllTrigger[TRIGGER_TYPE.BuildOpen] = require("game.guide.guideTrigger.BuildOpen"):new(TRIGGER_TYPE.BuildOpen)
  self.tblAllTrigger[TRIGGER_TYPE.BuildElectricFactoryEnd] = require("game.guide.guideTrigger.BuildingHaveDone"):new(TRIGGER_TYPE.BuildElectricFactoryEnd, 2)
  self.tblAllTrigger[TRIGGER_TYPE.BuildFoodFactoryEnd] = require("game.guide.guideTrigger.BuildingHaveDone"):new(TRIGGER_TYPE.BuildFoodFactoryEnd, 6)
  self.tblAllTrigger[TRIGGER_TYPE.BuildOilFactoryEnd] = require("game.guide.guideTrigger.BuildingHaveDone"):new(TRIGGER_TYPE.BuildOilFactoryEnd, 3)
  self.tblAllTrigger[TRIGGER_TYPE.BuildResourcesFactoryEnd] = require("game.guide.guideTrigger.BuildingHaveDone"):new(TRIGGER_TYPE.BuildResourcesFactoryEnd, 4)
  self.tblAllTrigger[TRIGGER_TYPE.BuildDormRoomEnd] = require("game.guide.guideTrigger.BuildDormRoomEnd"):new(TRIGGER_TYPE.BuildDormRoomEnd, 5)
  self.tblAllTrigger[TRIGGER_TYPE.BuildItemFactoryEnd] = require("game.guide.guideTrigger.BuildItemFactoryEnd"):new(TRIGGER_TYPE.BuildItemFactoryEnd, 7)
  self.tblAllTrigger[TRIGGER_TYPE.TowerGirlInBattle] = require("game.guide.guideTrigger.ShipInBattleCheck"):new(TRIGGER_TYPE.TowerGirlInBattle, FleetType.Tower)
  self.tblAllTrigger[TRIGGER_TYPE.EnterCopy_20405] = requiredEnterCopy:new(TRIGGER_TYPE.EnterCopy_20405, 20405)
  self.tblAllTrigger[TRIGGER_TYPE.AbleToAttackCopy] = require("game.guide.guideTrigger.AbleToAttackCopy"):new(TRIGGER_TYPE.AbleToAttackCopy)
  self.tblAllTrigger[TRIGGER_TYPE.EnterCopy_5011] = requiredEnterCopy:new(TRIGGER_TYPE.EnterCopy_5011, 5011)
  self.tblAllTrigger[TRIGGER_TYPE.FleetAttrNotEnough] = require("game.guide.guideTrigger.FleetAttrNotEnough"):new(TRIGGER_TYPE.FleetAttrNotEnough)
  self.tblAllTrigger[TRIGGER_TYPE.CanAttackDailyEx] = require("game.guide.guideTrigger.CanAttackDailyEx"):new(TRIGGER_TYPE.CanAttackDailyEx)
end

function GuideTriggerManager:AddTriggerKey(nKey, param)
  local objOldTrigger = self.tblTickTrigger[nKey]
  if objOldTrigger ~= nil and objOldTrigger ~= self.objEmptyTrigger then
    logError("have Same trigger")
    return
  end
  local objTrigger = self.tblAllTrigger[nKey]
  if objTrigger ~= nil then
    self.tblTickTrigger[nKey] = objTrigger
    objTrigger:startTrigger(param)
  end
end

function GuideTriggerManager:RemoveTriggerKey(nKey)
  local objTrigger = self.tblTickTrigger[nKey]
  if objTrigger ~= nil then
    objTrigger:endTrigger()
  end
  self.tblTickTrigger[nKey] = self.objEmptyTrigger
end

function GuideTriggerManager:tick()
  for k, v in pairs(self.tblTickTrigger) do
    if v ~= nil then
      v:tick()
    end
  end
end

function GuideTriggerManager:_DelImp(nKey)
  for k, v in pairs(self.tblTickTrigger) do
    if k == nKey then
      self.tblTickTrigger[k] = nil
    end
  end
end

function GuideTriggerManager:Clear()
  self.guideTriggermananger = {}
end

return GuideTriggerManager
