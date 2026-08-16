local SelectHeroItem = class("UI.Common.SelectHeroItem")

function SelectHeroItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.heroInfo = {}
  self.index = nil
  self.type = nil
end

function SelectHeroItem:Init(obj, tabPart, data, index, type)
  self.page = obj
  self.tabPart = tabPart
  self.heroInfo = data
  self.index = index
  self.type = type
  self:_SetHeroInfo()
end

function SelectHeroItem:_SetHeroInfo()
  ShipCardItem:LoadVerticalCard(self.heroInfo.HeroId, self.tabPart.cardPart)
  self.tabPart.tx_lv.text = Mathf.ToInt(self.heroInfo.Lvl)
  UIHelper.SetStar(self.tabPart.obj_stars, self.tabPart.trans_stars, self.heroInfo.Advance)
  self.tabPart.Obj_prop:SetActive(false)
  table.insert(self.page.m_tabTog, self.tabPart.tog_select)
  if self.page.m_tabSelectShip and #self.page.m_tabSelectShip > 0 then
    for _, v in pairs(self.page.m_tabSelectShip) do
      if v == self.heroInfo.HeroId then
        self.tabPart.tog_select.isOn = true
        self.page.m_beforeSelectTog = self.tabPart.tog_select
      end
    end
  end
  if self.page.m_isShowProp then
    self.tabPart.Obj_propbg:SetActive(true)
    self.page:_LoadProp(self.heroInfo, self.tabPart.Obj_prop, self.tabPart.trans_propbg)
  else
    self.tabPart.Obj_propbg:SetActive(false)
  end
  if self.type == CommonHeroItem.Study or self.type == CommonHeroItem.Assist then
    self.tabPart.im_lock.gameObject:SetActive(self.heroInfo.Lock)
    local fleet = Logic.shipLogic:GetHeroFleet(self.heroInfo.HeroId)
    local showTip = Logic.shipLogic:IsInFleet(self.heroInfo.HeroId)
    self.tabPart.fleet:SetActive(showTip)
    if Logic.shipLogic:IsInFleet(self.heroInfo.HeroId) then
      local fleetName = Logic.fleetLogic:GetHeroFleetName(self.heroInfo.HeroId)
      UIHelper.SetText(self.tabPart.tx_fleet, fleetName)
    end
    self.tabPart.obj_support:SetActive(Logic.shipLogic:IsInCrusade(self.heroInfo.HeroId))
  end
  if self.type == CommonHeroItem.Break or self.type == CommonHeroItem.Strengthen then
    local bLock = Logic.shipLogic:IsLock(self.heroInfo.HeroId)
    local bInFleet = Logic.shipLogic:IsInFleet(self.heroInfo.HeroId)
    local bInCrusade = Logic.shipLogic:IsInCrusade(self.heroInfo.HeroId)
    local bInStudy = Logic.studyLogic:CheckHeroAlreadyStudy(self.heroInfo.HeroId)
    local bInBath = Logic.bathroomLogic:CheckInBath(self.heroInfo.HeroId)
    local bInOutpost = Logic.mubarOutpostLogic:CheckHeroIsInOutpost(self.heroInfo.HeroId)
    local tips = bInFleet or bInCrusade or bInStudy or bInBath or bInOutpost
    self.tabPart.fleet:SetActive(tips)
    self.tabPart.im_lock.gameObject:SetActive(bLock)
    if bInFleet then
      local fleetName = Logic.fleetLogic:GetHeroFleetName(self.heroInfo.HeroId)
      UIHelper.SetText(self.tabPart.tx_fleet, fleetName)
    end
    self.tabPart.obj_support:SetActive(bInCrusade)
    if bInStudy then
      UIHelper.SetText(self.tabPart.tx_fleet, UIHelper.GetString(180021))
    end
    if bInBath then
      UIHelper.SetText(self.tabPart.tx_fleet, UIHelper.GetString(180022))
    end
    if bInOutpost then
      UIHelper.SetText(self.tabPart.tx_fleet, UIHelper.GetString(4600029))
    end
  end
  local tog = self.tabPart.tog_select.isOn
  if self.type == CommonHeroItem.Assist then
    local si_id = Logic.shipLogic:GetShipInfoIdByTid(self.heroInfo.TemplateId)
    local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    local selected = self.page.m_selectFids and self.page.m_selectFids[sf_id] ~= nil
    self.tabPart.obj_mask.gameObject:SetActive(selected)
    self.tabPart.obj_mask.color = Color.New(1, 1, 1, 0.5)
    self.tabPart.tween_select.enabled = tog
    local showRmd = self:_IsShowRmd(sf_id, self.heroInfo.type)
    self.tabPart.obj_recommand:SetActive(showRmd)
  elseif self.type == CommonHeroItem.PresetFleet then
    local si_id = Logic.shipLogic:GetShipInfoIdByTid(self.heroInfo.TemplateId)
    local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    local selected = self.page.m_selectFids and self.page.m_selectFids[sf_id] ~= nil
    self.tabPart.obj_mask.gameObject:SetActive(selected)
    self.tabPart.obj_mask.color = Color.New(1, 1, 1, 0.5)
    self.tabPart.tween_select.enabled = tog
  elseif self.type == CommonHeroItem.Building then
    local bathCache = self.page:_GetCacheBathInfo()
    local buildingCache = self.page:_GetCacheBuildingInfo()
    local outpostCache = self.page:_GetCacheOutpostInfo()
    local bInOutPost = Logic.mubarOutpostLogic:CheckHeroIsInOutpost(self.heroInfo.HeroId)
    local si_id = Logic.shipLogic:GetShipInfoIdByTid(self.heroInfo.TemplateId)
    local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    local bInBath = bathCache[sf_id] ~= nil
    local bInBuilding = buildingCache[sf_id] ~= nil
    local bInOutPosting = outpostCache[sf_id] ~= nil
    local tips = bInBuilding or bInBath or bInOutPosting
    self.tabPart.fleet:SetActive(tips)
    if bInOutPosting then
      UIHelper.SetText(self.tabPart.tx_fleet, UIHelper.GetString(4600029))
    end
    if bInBath then
      UIHelper.SetText(self.tabPart.tx_fleet, UIHelper.GetString(180022))
    end
    if bInBuilding then
      local buildingType = buildingCache[sf_id]
      if buildingType and buildingType == MBuildingType.DormRoom then
        UIHelper.SetText(self.tabPart.tx_fleet, "\229\183\178\229\156\168\229\174\191\232\136\141\228\184\173")
      else
        UIHelper.SetText(self.tabPart.tx_fleet, "\229\183\178\229\156\168\229\183\165\228\189\156\228\184\173")
      end
    end
    local selected = self.page.m_selectFids and self.page.m_selectFids[sf_id] ~= nil or bInBath or bInBuilding or bInOutPosting
    self.tabPart.obj_mask.gameObject:SetActive(selected)
    self.tabPart.obj_mask.color = Color.New(1, 1, 1, 0.5)
    self.tabPart.tween_select.enabled = tog
    local tid = self.page:GetBuildingTid()
    local buildType = 0
    if tid then
      buildType = Logic.buildingLogic:GetBuildType(self.page:GetBuildingTid())
    end
    local charIds, charLevels = Logic.buildingLogic:GetHeroBuildingCharacter(buildType, self.heroInfo.TemplateId)
    self.tabPart.obj_character.gameObject:SetActive(0 < #charIds)
    local charNameStr = ""
    local charLevelStr = ""
    for i, id in ipairs(charIds) do
      local charName = Logic.shipLogic:GetCharacterName(id)
      local charLevel = charLevels[i]
      charNameStr = charNameStr .. charName
      charLevelStr = charLevelStr .. charLevel
      charNameStr = charNameStr .. "lv" .. charLevelStr .. "\n"
      if i < #charIds then
        charNameStr = charNameStr .. "\n"
      end
    end
    UIHelper.SetText(self.tabPart.txt_character, charNameStr)
  else
    self.tabPart.obj_mask.gameObject:SetActive(tog)
  end
  local moodLimit = configManager.GetDataById("config_parameter", 142).arrValue
  local moodInfo, curMood = Logic.marryLogic:GetLoveInfo(self.heroInfo.HeroId, MarryType.Mood)
  if moodInfo then
    UIHelper.SetImage(self.tabPart.im_girlMood, moodInfo.mood_icon)
  end
  if self.tabPart.girlMood_Slider then
    local percent = curMood / moodLimit[2]
    self.tabPart.girlMood_Slider.value = percent
  end
  if self.tabPart.obj_badMood then
    self.tabPart.obj_badMood:SetActive(curMood == 0)
  end
  local isShipTaskOver = false
  if self.tabPart.objImgTestShip then
    self.tabPart.objImgTestShip:SetActive(false)
  end
  if self.tabPart.objTestShipRewardInfo then
    self.tabPart.objTestShipRewardInfo:SetActive(false)
  end
  if self.type == CommonHeroItem.ShipTask then
    local heroTid = self.heroInfo.TemplateId
    local cfg = configManager.GetDataById("config_ship_main", heroTid)
    local siCfg = configManager.GetDataById("config_ship_info", cfg.ship_info_id)
    local shipTid = siCfg.sf_id
    isShipTaskOver = Logic.shiptaskLogic:IsShipTaskFinishOver(shipTid)
    if isShipTaskOver then
      self.tabPart.objImgTestShip:SetActive(true)
    else
      self.tabPart.objTestShipRewardInfo:SetActive(true)
      UIHelper.SetText(self.tabPart.textTestShipRewardInfo, Logic.shiptaskLogic:GetShipTaskFinishProcess(shipTid))
    end
  end
  self.tabPart.tog_select.enabled = not isShipTaskOver
  UGUIEventListener.AddButtonToggleChanged(self.tabPart.tog_select, self.page.Selected, self.page, {
    heroId = self.heroInfo.HeroId,
    tog = self.tabPart.tog_select
  })
end

function SelectHeroItem:_IsShowRmd(sf_id, type)
  return table.containV(self.page.tabParams.m_tids, sf_id) or table.containV(self.page.tabParams.m_type, type)
end

return SelectHeroItem
