local FleetCardItem = class("UI.Fleet.FleetCardItem")
FAULT_SHIP_TYPE = 6
local back = false

function FleetCardItem:initialize(...)
  self.page = nil
  self.nIndex = nil
  self.heroId = nil
  self.tabPart = nil
  self.toggeIndex = nil
  self.newCardPos = nil
  self.m_firstEmptyPos = false
  self.heroInfo = {}
  self.shipInfo = {}
  self.heroTab = {}
  self.showBack = false
  self.chapterId = 0
  self.submarine = false
end

function FleetCardItem:Init(obj, nIndex, heroId, tabPart, toggeIndex, firstEmptyPos, newCardPos, showBack, heroTab, isLocked, chapterId, copyDisplayId, submarine)
  self.page = obj
  self.nIndex = nIndex
  self.heroId = heroId
  self.tabPart = tabPart
  self.toggeIndex = toggeIndex
  self.m_firstEmptyPos = firstEmptyPos
  self.newCardPos = newCardPos
  self.showBack = showBack
  self.heroTab = heroTab
  self.isLocked = isLocked
  self.chapterId = chapterId
  self.copyDisplayId = copyDisplayId
  self.submarine = submarine
  self:_SetShipInfo()
end

function FleetCardItem:_SetShipInfo()
  self.tabPart.locked:SetActive(self.isLocked)
  if self.isLocked then
    self.tabPart.objHero:SetActive(false)
    self.tabPart.txt_hint.gameObject:SetActive(false)
  elseif self.heroId == nil then
    self.tabPart.objHero:SetActive(false)
    self.tabPart.txt_hint.gameObject:SetActive(true)
    self.tabPart.txt_hint.enabled = self.m_firstEmptyPos
  elseif self.nIndex == self.newCardPos then
    UIHelper.SetUILock(true)
    self:_ReverseTween()
  else
    self:_ShowCard()
  end
  if self.nIndex == 1 then
    UIHelper.SetImage(self.tabPart.img_typeBg, "uipic_ui_newfleetpage_bg_qijiandiban")
    UIHelper.SetImage(self.tabPart.img_backType, "uipic_ui_newfleetpage_bg_qijiandiban")
  end
  self:_CloseSelect()
  self.tabPart.obj_lock:SetActive(false)
  if self.submarine and self.nIndex > 3 then
    self.tabPart.obj_lock:SetActive(true)
  end
end

function FleetCardItem:_ReverseTween()
  self:_ShowCard()
  self:_HideTween()
end

function FleetCardItem:_ShowCard()
  self.tabPart.obj_front:SetActive(not self.showBack)
  self.tabPart.obj_back:SetActive(self.showBack)
  self.tabPart.obj_tween.transform.localEulerAngles = self.showBack and Vector3.New(0, 180, 0) or Vector3.zero
  self.tabPart.txt_hint.gameObject:SetActive(false)
  self.tabPart.objHero:SetActive(true)
  self.heroInfo = Data.heroData:GetHeroById(self.heroId)
  self.shipInfo = Logic.shipLogic:GetShipInfoByHeroId(self.heroInfo.HeroId)
  self:_SetBaseInfo()
  self:_SetTypeDisplay()
  self:_SetAttr()
  self:_SetAdvance()
  self:_SetUpSign()
  self:_SetEquip()
  self:_SetDrag()
  self:_SetClick()
  self:_SetExpUp()
end

function FleetCardItem:_HideTween()
  UIHelper.SetUILock(false)
  local tblHeros = self.page.m_tabFleetData[1].heroInfo
  eventManager:SendEvent(LuaEvent.ShipInBattle, {
    self.page.fleetType,
    tblHeros
  })
end

function FleetCardItem:_SetUpSign()
  self.page:RegisterRedDot(self.tabPart.redDot, self.heroId, self.page.fleetType)
end

function FleetCardItem:_SetAttr()
  local heroAttr = Logic.attrLogic:GetHeroFinalShowAttrById(self.heroId, self.page.fleetType)
  if self.heroInfo.type == FAULT_SHIP_TYPE then
    UIHelper.SetImage(self.tabPart.imgIcon1, "uipic_ui_attribute_im_jianbao")
    UIHelper.SetImage(self.tabPart.imgIcon2, "uipic_ui_attribute_im_jianzhan")
    UIHelper.SetImage(self.tabPart.backAttr1, "uipic_ui_attribute_im_jianbao")
    UIHelper.SetImage(self.tabPart.backAttr2, "uipic_ui_attribute_im_jianzhan")
    self.tabPart.text1.text = math.tointeger(heroAttr[AttrType.SHIP_BOMB_ATTACK])
    self.tabPart.text2.text = math.tointeger(heroAttr[AttrType.SHIP_AIR_CONTROL])
    self.tabPart.backAttack.text = math.tointeger(heroAttr[AttrType.SHIP_BOMB_ATTACK])
    self.tabPart.backPorpedo.text = math.tointeger(heroAttr[AttrType.SHIP_AIR_CONTROL])
  else
    UIHelper.SetImage(self.tabPart.imgIcon1, "uipic_ui_attribute_im_paoji")
    UIHelper.SetImage(self.tabPart.imgIcon2, "uipic_ui_attribute_im_leiji")
    UIHelper.SetImage(self.tabPart.backAttr1, "uipic_ui_attribute_im_paoji")
    UIHelper.SetImage(self.tabPart.backAttr2, "uipic_ui_attribute_im_leiji")
    self.tabPart.text1.text = math.tointeger(heroAttr[AttrType.ATTACK])
    self.tabPart.text2.text = math.tointeger(heroAttr[AttrType.TORPEDO_ATTACK])
    self.tabPart.backAttack.text = math.tointeger(heroAttr[AttrType.ATTACK])
    self.tabPart.backPorpedo.text = math.tointeger(heroAttr[AttrType.TORPEDO_ATTACK])
  end
  UIHelper.SetImage(self.tabPart.img_attr3, "uipic_ui_attribute_im_huoli")
  self.tabPart.attr3.text = math.tointeger(heroAttr[AttrType.ATTACK_GRADE])
  UIHelper.SetImage(self.tabPart.img_backAttr3, "uipic_ui_attribute_im_huoli")
  self.tabPart.backAttr3.text = math.tointeger(heroAttr[AttrType.ATTACK_GRADE])
  local ship = configManager.GetDataById("config_ship_main", self.heroInfo.TemplateId)
  self.tabPart.text3.text = ship.supple_cost
  self.tabPart.backCost.text = ship.supple_cost
  local curHp = Logic.shipLogic:GetHeroHp(self.heroId, self.page.fleetType)
  local hpValue = curHp / heroAttr[AttrType.HP]
  self.tabPart.sliderHp.value = hpValue
  local shipIcon, shipBackIcon
  local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroAttr[AttrType.HP])
  if hpStatus >= DamageLevel.SmallDamage then
    self.tabPart.imageState.gameObject:SetActive(true)
    local showConfig = Logic.shipLogic:GetShipShowByHeroId(self.heroInfo.HeroId)
    local ship_battle_hp_state = showConfig.ship_battle_hp_state
    UIHelper.SetImage(self.tabPart.imageState, ship_battle_hp_state[hpStatus])
  else
    self.tabPart.imageState.gameObject:SetActive(false)
  end
  UIHelper.SetImage(self.tabPart.imgHp, NewHpStatusImg[hpStatus + 1])
  UIHelper.SetImage(self.tabPart.backHpImg, NewCardHpStatus[hpStatus + 1])
  local jumpFunc
  local combineData = Logic.shipCombinationLogic:GetCombineData(self.heroInfo.HeroId)
  if combineData.Combine and combineData.Combine > 0 then
    local combineHeroId = combineData.Combine
    local combineHeroInfo = Data.heroData:GetHeroById(combineHeroId)
    local fleetId = combineHeroInfo.fleetId
    local icon = Logic.shipLogic:GetIcon(fleetId)
    local quality = combineHeroInfo.quality
    self.tabPart.im_combineShip.gameObject:SetActive(true)
    self.tabPart.im_combineQuality.gameObject:SetActive(true)
    self.tabPart.obj_combineNone:SetActive(false)
    UIHelper.SetImage(self.tabPart.im_combineShip, icon)
    UIHelper.SetImage(self.tabPart.im_combineQuality, QualityIcon[quality])
    
    function jumpFunc()
      local heros = {}
      for k, v in pairs(Data.heroData:GetHeroData()) do
        table.insert(heros, v.HeroId)
      end
      UIHelper.OpenPage("GirlInfo", {
        combineHeroId,
        heros,
        jumpToggle = 6
      })
    end
  else
    self.tabPart.im_combineShip.gameObject:SetActive(false)
    self.tabPart.im_combineQuality.gameObject:SetActive(false)
    self.tabPart.obj_combineNone:SetActive(true)
    
    function jumpFunc()
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            local heros = {}
            for k, v in pairs(Data.heroData:GetHeroData()) do
              table.insert(heros, v.HeroId)
            end
            UIHelper.OpenPage("GirlInfo", {
              self.heroInfo.HeroId,
              heros,
              jumpToggle = 5
            })
          end
        end
      }
      noticeManager:ShowMsgBox(UIHelper.GetString(4900023), tabParams)
    end
  end
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_combine, jumpFunc)
  ShipCardItem:LoadVerticalCard(self.heroId, self.tabPart.childpart, VerCardType.Fleet, nil, self.page.fleetType)
  ShipCardItem:LoadVerticalCard(self.heroId, self.tabPart.backChildPart, VerCardType.FleetSmall, nil, self.page.fleetType)
end

function FleetCardItem:_SetAdvance()
  local starTab = {
    self.tabPart.obj_star1,
    self.tabPart.obj_star2,
    self.tabPart.obj_star3,
    self.tabPart.obj_star4,
    self.tabPart.obj_star5,
    self.tabPart.obj_star6
  }
  local backStarTab = {
    self.tabPart.obj_backStar1,
    self.tabPart.obj_backStar2,
    self.tabPart.obj_backStar3,
    self.tabPart.obj_backStar4,
    self.tabPart.obj_backStar5,
    self.tabPart.obj_backStar6
  }
  local line, starNum = Logic.shipLogic:ShowShipStarInfo(self.heroInfo.Advance)
  for i, v in ipairs(starTab) do
    if i <= starNum then
      local image = starTab[i].gameObject:GetComponent(UIImage.GetClassType())
      if 0 < line then
        UIHelper.SetImage(image, ShipStarImgMubo[2])
      else
        UIHelper.SetImage(image, ShipStarImgMubo[1])
      end
      starTab[i]:SetActive(true)
      backStarTab[i]:SetActive(true)
    else
      starTab[i]:SetActive(false)
      backStarTab[i]:SetActive(false)
    end
  end
end

function FleetCardItem:_SetBaseInfo()
  local girlInfo = Data.heroData:GetHeroById(self.heroId)
  if not npcAssistFleetMgr:IsNpcHeroId(self.heroId) then
    if girlInfo.Name ~= "" then
      self.tabPart.textName.text = girlInfo.Name
      self.tabPart.backName.text = girlInfo.Name
    else
      self.tabPart.textName.text = self.shipInfo.ship_name
      self.tabPart.backName.text = self.shipInfo.ship_name
    end
  else
    self.tabPart.textName.text = self.shipInfo.ship_name
    self.tabPart.backName.text = self.shipInfo.ship_name
  end
  self.tabPart.textLv.text = math.tointeger(self.heroInfo.Lvl)
  self.tabPart.txt_backLv.text = math.tointeger(self.heroInfo.Lvl)
  local moodBound = configManager.GetDataById("config_parameter", 142).arrValue
  local girlData = Data.heroData:GetHeroById(self.heroInfo.HeroId)
  local currMoodNum = Logic.marryLogic:GetMoodNum(girlData, self.heroInfo.HeroId)
  self.tabPart.backExpSlider.value = currMoodNum / moodBound[2]
  local moodInfo = Logic.marryLogic:GetLoveInfo(self.heroInfo.HeroId, MarryType.Mood)
  UIHelper.SetImage(self.tabPart.im_mood, moodInfo.mood_icon_xiao, true)
end

function FleetCardItem:_CloseSelect()
  self.tabPart.objGolden:SetActive(false)
  self.tabPart.objMask:SetActive(false)
  self.tabPart.obj_white:SetActive(false)
end

function FleetCardItem:_SetEquip()
  local shipEquips = Data.heroData:GetEquipsByType(self.heroId, self.page.fleetType)
  local haveEquip = {}
  for k, v in pairs(shipEquips) do
    if v.EquipsId ~= 0 then
      table.insert(haveEquip, v.EquipsId)
    end
  end
  local isAEquip, isLLEquip
  UIHelper.CreateSubPart(self.tabPart.obj_equip, self.tabPart.trans_equip, #haveEquip, function(index, equipPart)
    local equipInfo = Logic.equipLogic:GetEquipById(haveEquip[index])
    local shipEquipInfo = configManager.GetDataById("config_equip", equipInfo.TemplateId)
    UIHelper.SetImage(equipPart.img_equip, tostring(shipEquipInfo.icon_small))
    UIHelper.SetImage(equipPart.img_equipQuality, EquipQualityIcon[shipEquipInfo.quality])
    isAEquip = Logic.equipLogic:IsAEquip(equipInfo.TemplateId)
    equipPart.obj_activity:SetActive(isAEquip)
    isLLEquip = Logic.equipLogic:IsLLEquip(equipInfo.TemplateId)
    equipPart.obj_limit:SetActive(isLLEquip)
  end)
end

function FleetCardItem:_SetDrag()
  UGUIEventListener.AddButtonOnPointDown(self.tabPart.objHero, function()
    self.page:OnDragCard(self.tabPart, self.heroInfo, self.nIndex, nil, FleetCardType.FleetCard)
  end)
  UGUIEventListener.AddButtonOnPointUp(self.tabPart.objHero, function()
    if self.page.m_popObj ~= nil then
      self.page.m_tabWidgets.obj_float:SetActive(false)
      self:_CloseSelect()
      GameObject.Destroy(self.page.m_popObj)
      self.page.m_popObj = nil
      self.page:OnClickCard(self.tabPart, self.heroInfo.HeroId, nil, self.heroTab)
    end
  end)
end

function FleetCardItem:_SetClick()
  UGUIEventListener.AddButtonOnClick(self.tabPart.objHero, function()
    self.page:OnClickCard(self.tabPart, self.heroInfo.HeroId, nil, self.heroTab)
  end)
end

function FleetCardItem:TurnCard(curBack)
  local tweenRotation = UIHelper.AddTween(self.tabPart.obj_tween, ETweenType.ETT_ROTATION)
  tweenRotation.from = curBack and Vector3.New(0, 180, 0) or Vector3.zero
  tweenRotation.to = Vector3.New(0, 85, 0)
  tweenRotation.duration = 0.25
  tweenRotation:SetOnFinished(function()
    UIHelper.RemoveTween(tweenRotation)
    local nextRotation = UIHelper.AddTween(self.tabPart.obj_tween, ETweenType.ETT_ROTATION)
    nextRotation.from = Vector3.New(0, 85, 0)
    nextRotation.to = curBack and Vector3.zero or Vector3.New(0, 180, 0)
    nextRotation.duration = 0.45
    self.tabPart.obj_front:SetActive(curBack)
    self.tabPart.obj_back:SetActive(not curBack)
    nextRotation:SetOnFinished(function()
      UIHelper.RemoveTween(nextRotation)
    end)
    nextRotation:Play()
  end)
  tweenRotation:Play()
end

function FleetCardItem:_SetTypeDisplay()
  if self.chapterId == 0 then
    return
  end
  local chapterInfo = Logic.copyLogic:GetChaperConfById(self.chapterId)
  if Logic.towerLogic:IsTowerType(chapterInfo.tactic_type) then
    local surplus, countText = Logic.towerLogic:GetShipBattleInfo(self.heroInfo.TemplateId, chapterInfo.tactic_type)
    self.tabPart.im_towertimes1:SetActive(0 < surplus)
    self.tabPart.im_towertimes2:SetActive(surplus <= 0)
    self.tabPart.tx_towertimes1.text = countText
    self.tabPart.tx_towertimes2.text = countText
    local hurtPer = Logic.towerLogic:CalTowerHurtPer(self.heroInfo.TemplateId, chapterInfo.tactic_type)
    self.tabPart.img_hurt.gameObject:SetActive(true)
    local imgBg = 0 < hurtPer and "uipic_ui_challenge_bg_cishu_02" or "uipic_ui_challenge_bg_cishu_01"
    UIHelper.SetImage(self.tabPart.img_hurt, imgBg)
    self.tabPart.tx_hurtNum.text = hurtPer .. "%"
    self.tabPart.im_backTowertimes1:SetActive(0 < surplus)
    self.tabPart.im_backTowertimes2:SetActive(surplus <= 0)
    self.tabPart.tx_backTimes1.text = countText
    self.tabPart.tx_backTimes2.text = countText
    self.tabPart.im_backHurt.gameObject:SetActive(true)
    UIHelper.SetImage(self.tabPart.im_backHurt, imgBg)
    self.tabPart.tx_backhurtNum.text = hurtPer .. "%"
  elseif Logic.copyLogic:IsGuildWarCopy(chapterInfo) then
    local hadGuildWar = Logic.fleetLogic:CheckHeroHadGuildWar(self.heroInfo.HeroId)
    self.tabPart.obj_attacklimit:SetActive(hadGuildWar)
    self.tabPart.obj_attacklimit_back:SetActive(hadGuildWar)
  end
end

function FleetCardItem:_SetExpUp()
  if self.copyDisplayId == nil or self.copyDisplayId == 0 then
    return
  end
  local exp_up = Logic.fleetOrderLogic:GetExpUpMap(self.copyDisplayId)
  self.tabPart.exp_up1:SetActive(exp_up[self.heroId] == true)
  self.tabPart.exp_up2:SetActive(exp_up[self.heroId] == true)
end

return FleetCardItem
