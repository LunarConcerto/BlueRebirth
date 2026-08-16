local HeroData = class("data.HeroData", Data.BaseData)

function HeroData:initialize()
  self:_InitHandlers()
end

function HeroData:_InitHandlers()
  self:ResetData()
end

function HeroData:ResetData()
  self.tabHero = {}
  self.tabHeroTid = {}
  self.newHero = {}
  self.HeroBagSize = 0
  self.heroNum = {}
  self.m_isSetData = false
  self.mapHero = {}
  self.equipRetireRewards = {}
end

function HeroData:IsSetData()
  return self.m_isSetData
end

function HeroData:SetData(param)
  self.mapHero = Logic.girlInfoLogic:GetMapHeroByMood()
  local curTime = time.getSvrTime()
  self.m_isSetData = true
  local isRecord = next(self.tabHero) ~= nil
  for k, v in pairs(param.HeroInfo) do
    if v.TemplateId == 0 then
      if self.tabHero[v.HeroId] ~= nil then
        self.tabHero[v.HeroId] = nil
      end
      if self.tabHeroTid[v.TemplateId] ~= nil then
        self.tabHeroTid[v.TemplateId] = self.tabHeroTid[v.TemplateId] - 1
      end
    else
      if isRecord and self.tabHero[v.HeroId] == nil then
        table.insert(self.newHero, v.HeroId)
      end
      if self.tabHeroTid[v.TemplateId] ~= nil then
        self.tabHeroTid[v.TemplateId] = self.tabHeroTid[v.TemplateId] + 1
      else
        self.tabHeroTid[v.TemplateId] = 1
      end
      self.tabHero[v.HeroId] = self:_SetExtraInfo(v)
      self.mapHero[v.HeroId] = curTime
      eventManager:SendEvent(LuaEvent.HERO_TryUpdateHeroExData, v.HeroId)
    end
    if self.tabHeroTid[v.TemplateId] ~= nil and 0 >= self.tabHeroTid[v.TemplateId] then
      self.tabHeroTid[v.TemplateId] = nil
    end
  end
  if param.HeroBagSize ~= nil then
    self.HeroBagSize = param.HeroBagSize
  end
  if param.HeroNum ~= nil and 0 < #param.HeroNum then
    for i, v in ipairs(param.HeroNum) do
      self.heroNum[v.TemplateId] = Mathf.ToInt(v.Num)
    end
  end
  Logic.girlInfoLogic:SetMapHeroByMood(self.mapHero)
end

function HeroData:GetHeroGetNum(id)
  return self.heroNum[id] or 0
end

function HeroData:SetRecordNewHero(param)
  if next(self.tabHero) == nil then
    self.newHero = {}
  else
    for i, v in ipairs(param.HeroInfo) do
      if self.tabHero[v.HeroId] == nil then
        table.insert(self.newHero, v.HeroId)
      end
    end
  end
end

function HeroData:IsNew(heroId)
  for i, v in ipairs(self.newHero) do
    if v == heroId then
      return true
    end
  end
  return false
end

function HeroData:ClearRecord()
  self.newHero = {}
end

function HeroData:GetRecordNewHero()
  return SetReadOnlyMeta(self.newHero)
end

function HeroData:GetHeroData()
  return SetReadOnlyMeta(self.tabHero)
end

function HeroData:GetHeroById(id)
  if npcAssistFleetMgr:GetNpcShipById(id) ~= nil then
    return SetReadOnlyMeta(npcAssistFleetMgr:GetNpcShipById(id))
  end
  if self.tabHero[id] == nil then
    log("not Exist hero id:" .. tostring(id))
    return
  end
  return SetReadOnlyMeta(self.tabHero[id])
end

function HeroData:ModifyHeroData()
  local fleetData = Data.fleetData
end

function HeroData:_SetExtraInfo(heroInfo)
  local shipConfig = configManager.GetDataById("config_ship_main", heroInfo.TemplateId)
  local shipId = shipConfig.ship_info_id
  local ship = Logic.shipLogic:GetShipShowByFashionId(heroInfo.Fashioning)
  if not ship then
    return
  end
  local shipInfo = configManager.GetDataById("config_ship_info", shipId)
  heroInfo.Advance = shipConfig.break_level
  heroInfo.type = shipInfo.ship_type
  heroInfo.quality = shipInfo.quality
  heroInfo.shipCountry = shipInfo.ship_country
  heroInfo.fleetId = shipInfo.sf_id
  heroInfo.PSKillMap = {}
  for _, v in ipairs(heroInfo.PSkill) do
    heroInfo.PSKillMap[v.PSkillId] = v.PSkillExp
  end
  heroInfo.PSKillLevelMap = {}
  for _, v in ipairs(heroInfo.PSkill) do
    heroInfo.PSKillLevelMap[v.PSkillId] = v.Level
  end
  heroInfo.Attr = {}
  heroInfo.Power = {}
  local equips = {}
  for _, info in ipairs(heroInfo.Equips) do
    equips[info.type] = info.Equip
  end
  heroInfo.Equips = equips
  return heroInfo
end

function HeroData:GetHeroStatus(heroId)
  return self:GetHeroById(heroId).Status
end

function HeroData:HeroIsInStatus(heroId, status)
  local statusValue = self:GetHeroById(heroId).Status
  return string.sub(statusValue, status, 1) == "1"
end

function HeroData:GetCurrAllHeroTid()
  return self.tabHeroTid
end

function HeroData:GetHeroCountByTemplateId(nTemplateId)
  local nCount = self.tabHeroTid[nTemplateId]
  if nCount == nil then
    return 0
  else
    return nCount
  end
end

function HeroData:GetHeroBagSize()
  return self.HeroBagSize
end

function HeroData:GetHeroBySfId(sfId)
  local heroInfos = {}
  for heroId, heroInfo in pairs(self.tabHero) do
    local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId)
    if shipInfo and shipInfo.sf_id == sfId then
      table.insert(heroInfos, heroInfo)
    end
  end
  table.sort(heroInfos, function(l, r)
    if l.Lvl == r.Lvl then
      return l.Advance < r.Advance
    else
      return l.Lvl < r.Lvl
    end
  end)
  return heroInfos[1]
end

function HeroData:VerifyHero(heroId)
  local hero = self:GetHeroById(heroId)
  return hero ~= nil, hero
end

function HeroData:GetHeroLFurtherId(heroId)
  return self:GetHeroById(heroId).AdvLv or 0
end

function HeroData:GetEquipsByType(heroId, type)
  type = type or FleetType.Normal
  local data = self:GetHeroById(heroId)
  if data and data.Equips[type] then
    return data.Equips[type] or self:_getDefaultEquipInfo()
  end
  return self:_getDefaultEquipInfo()
end

function HeroData:_getDefaultEquipInfo()
  return {
    {EquipsId = 0, state = 0},
    {EquipsId = 0, state = 0},
    {EquipsId = 0, state = 0},
    {EquipsId = 0, state = 0},
    {EquipsId = 0, state = 0},
    {EquipsId = 0, state = 0}
  }
end

function HeroData:SetEquipRetireReward(rewards)
  self.equipRetireRewards = rewards
end

function HeroData:GetEquipRetireReward()
  return self.equipRetireRewards
end

return HeroData
