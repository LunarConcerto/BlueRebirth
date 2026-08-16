local IllustrateData = class("data.IllustrateData", Data.BaseData)

function IllustrateData:initialize()
  self:_InitHandlers()
end

function IllustrateData:_InitHandlers()
  self:ResetData()
end

function IllustrateData:ResetData()
  self.illustrate = {}
  self.haveNew = false
  self.haveNewEquip = false
  self.m_vowHero = 0
  self.m_preHeroList = {}
  self.m_chargeTime = 0
  self.m_vowCount = 0
  self.currId = {}
  self.oldCurrId = {}
  self.SkipVcr = {}
  self.VowItemUseInfo = {}
  self.closeIllustrate = {}
  self.memoryMap = {}
  self.m_cache = {}
  self.m_activetime = {}
  self.m_wish_activetime = {}
  self:_HandleConfig()
  self.heroMemoryList = {}
  self.equipIllustrate = {}
  self.equipHaveIllustrate = {}
  self.haveCount = 0
  self.allCount = 0
end

function IllustrateData:SetMemoryData(data)
  logDebug("SetMemoryData", data)
  if data and data.MemoryList then
    for index, info in pairs(data.MemoryList) do
      self.memoryMap[info.ChapterId] = info.Index
    end
  end
end

function IllustrateData:GetMemoryIndexByChapterId(chapterId)
  return self.memoryMap[chapterId] or 0
end

function IllustrateData:SetIllustrateData(datas)
  if self.currId ~= {} then
    self.oldCurrId = clone(self.currId)
  end
  if datas.VowCoolHero ~= nil then
    self:SetVowHero(datas.VowCoolHero)
  end
  if datas.VowHeroList ~= nil then
    self:SetPreHeroList(datas.VowHeroList)
  end
  if datas.VowCoolTime ~= nil then
    self:SetChargeTime(datas.VowCoolTime)
  end
  if datas.VowCount ~= nil then
    self:SetVowCount(datas.VowCount)
  end
  if datas.SkipVcr ~= nil then
    for _, info in ipairs(datas.SkipVcr) do
      self.SkipVcr[info.ShipInfoId] = {
        shipInfoId = info.ShipInfoId,
        skipEnterBattleAnim = info.StartVcr,
        skipDeadAnim = info.EndVcr
      }
    end
  end
  if datas.UseInfo ~= nil then
    if #datas.UseInfo == 0 then
      self.VowItemUseInfo = {}
    else
      for _, info in ipairs(datas.UseInfo) do
        self.VowItemUseInfo[info.ItemTid] = info.ItemNum
      end
    end
  end
  if datas.IllustrateList then
    self.m_cache = datas.IllustrateList
  end
  self:UpdateHero(datas.IllustrateList, true)
  self:UpdateEquip(datas.IllustrateEquipList)
  if self.oldCurrId == {} then
    self.oldCurrId = clone(self.currId)
  end
  if datas.HeroMemoryList then
    self:SetHeroMemorysDirty(true)
    self.heroMemoryList = self.heroMemoryList or {}
    for i, memory in ipairs(datas.HeroMemoryList) do
      self.heroMemoryList[memory.HeroId] = self.heroMemoryList[memory.HeroId] or {}
      self.heroMemoryList[memory.HeroId][memory.PlotId] = true
    end
  end
end

function IllustrateData:LocalUpdateHero()
  self:UpdateHero(self.m_cache, false)
end

function IllustrateData:UpdateHero(datas, server)
  local tabConfig = configManager.GetData("config_ship_handbook")
  local checkClose = function(s, t)
    return s == IllustrateShow.NOOPEN or s == IllustrateShow.TIMEAFTER and t >= time.getSvrTime()
  end
  local svrActive = function(id)
    if self.m_activetime[id] then
      self.m_activetime[id].Pass = true
    end
  end
  for index, info in ipairs(datas) do
    local config = tabConfig[info.IllustrateId]
    if config then
      local item = {}
      item = info
      item.IllustrateState = IllustrateState.UNLOCK
      local id = Mathf.ToInt(item.IllustrateId)
      local shipInfoConfig = Logic.shipLogic:GetShipInfoBySiId(id)
      item.IllustrateId = id
      item.Name = shipInfoConfig.ship_name
      item.quality = shipInfoConfig.quality
      item.shipCountry = shipInfoConfig.ship_country
      item.type = shipInfoConfig.ship_type
      item.ship_order = config.ship_order
      item.show_tag = config.show_tag
      if checkClose(config.show_state, config.activatetime) then
        self.closeIllustrate[id] = item
      else
        self.illustrate[id] = item
        svrActive(id)
      end
      self.currId[id] = true
    end
    if server and info.NewHero then
      self.haveNew = true
    end
  end
  for id, config in pairs(tabConfig) do
    if self.illustrate[id] == nil then
      local item = {}
      item.IllustrateId = id
      item.TemplateId = config.TemplateId
      item.GetTime = 0
      item.LikeTime = 0
      item.NewHero = false
      if IllustrateShow.OPEN == config.show_state then
        item.IllustrateState = IllustrateState.LOCK
      elseif IllustrateShow.CLOSE == config.show_state then
        item.IllustrateState = IllustrateState.CLOSE
      elseif IllustrateShow.TIMEAFTER == config.show_state then
        item.IllustrateState = checkClose(config.show_state, config.activatetime) and IllustrateState.CLOSE or IllustrateState.LOCK
      end
      item.BehaviourList = {}
      item.MarryCount = 0
      local shipInfoConfig = Logic.shipLogic:GetShipInfoBySiId(id)
      item.Name = shipInfoConfig.ship_name
      item.quality = shipInfoConfig.quality
      item.shipCountry = shipInfoConfig.ship_country
      item.type = shipInfoConfig.ship_type
      item.ship_order = config.ship_order
      item.show_tag = config.show_tag
      if checkClose(config.show_state, config.activatetime) then
        self.closeIllustrate[id] = item
      else
        self.illustrate[id] = item
        svrActive(id)
      end
    end
  end
end

function IllustrateData:UpdataIllustrateData(data)
  if self.illustrate == nil then
    return
  end
  for id, info in pairs(self.illustrate) do
    if id == data.IllustrateId then
      if info.IllustrateState ~= IllustrateState.UNLOCK then
        info.IllustrateState = IllustrateState.UNLOCK
        self.haveNew = true
      end
      info.GetTime = data.GetTime
      info.NewHero = data.NewHero
      info.LikeTime = data.LikeTime
      info.BehaviourList = data.BehaviourList
      return
    end
  end
end

function IllustrateData:GetIllustrateById(illstrateId)
  if self.illustrate[illstrateId] == nil then
    if self.closeIllustrate[illstrateId] ~= nil then
      return self.closeIllustrate[illstrateId]
    else
      logError("IllustrateData:can't find" .. illstrateId .. "'s illustrate info,Please check ship_handbook config")
    end
    return nil
  end
  return self.illustrate[illstrateId]
end

function IllustrateData:HaveIllustrate(illstrateId)
  return self.illustrate[illstrateId] ~= nil or self.closeIllustrate[illstrateId] ~= nil
end

function IllustrateData:GetAllIllustrate()
  self:CheckRefreshHero()
  return SetReadOnlyMeta(self.illustrate)
end

function IllustrateData:GetIllustrateArray()
  self:CheckRefreshHero()
  local tabTemp = {}
  for k, v in pairs(self.illustrate) do
    tabTemp[#tabTemp + 1] = v
  end
  return tabTemp
end

function IllustrateData:GetOpenShipNum()
  local count = 0
  for k, v in pairs(self.illustrate) do
    if v.IllustrateState == IllustrateState.UNLOCK or v.IllustrateState == IllustrateState.LOCK then
      count = count + 1
    end
  end
  return count
end

function IllustrateData:GetHaveShipNum()
  local count = 0
  for k, v in pairs(self.illustrate) do
    if v.IllustrateState == IllustrateState.UNLOCK then
      count = count + 1
    end
  end
  return count
end

function IllustrateData:GetHaveShipNumByCamp(nCountryList)
  local count = 0
  local marryCount = 0
  for i, nCountry in pairs(nCountryList) do
    for k, v in pairs(self.illustrate) do
      if v.IllustrateState == IllustrateState.UNLOCK and v.shipCountry == nCountry then
        count = count + 1
        if 0 < v.MarryCount then
          marryCount = marryCount + 1
        end
      end
    end
  end
  return count, marryCount
end

function IllustrateData:GetAllMarryNum()
  local marryCount = 0
  for k, v in pairs(self.illustrate) do
    if v.IllustrateState == IllustrateState.UNLOCK and 0 < v.MarryCount then
      marryCount = marryCount + 1
    end
  end
  return marryCount
end

function IllustrateData:GetShipNumByCamp(nCountryList)
  local count = 0
  for i, nCountry in pairs(nCountryList) do
    for k, v in pairs(self.illustrate) do
      if v.shipCountry == nCountry and v.show_tag == ShipPictureType.Normal then
        count = count + 1
      end
    end
  end
  return count
end

function IllustrateData:GetCollectionRate()
  local total = 0
  local unlock = 0
  for k, v in pairs(self.illustrate) do
    if v.IllustrateState == IllustrateState.UNLOCK or v.IllustrateState == IllustrateState.LOCK then
      total = total + 1
      if v.IllustrateState == IllustrateState.UNLOCK then
        unlock = unlock + 1
      end
    end
  end
  return unlock / total
end

function IllustrateData:ResetHaveNew()
  self.haveNew = false
end

function IllustrateData:GetHaveNewIllustrate()
  return self.haveNew
end

function IllustrateData:GetChargeTime()
  return self.m_chargeTime
end

function IllustrateData:SetChargeTime(tim)
  self.m_chargeTime = tim
end

function IllustrateData:GetVowHero()
  return self.m_vowHero
end

function IllustrateData:SetVowHero(hero)
  self.m_vowHero = hero
end

function IllustrateData:GetPreHeroList()
  return self.m_preHeroList
end

function IllustrateData:SetPreHeroList(herolist)
  self.m_preHeroList = herolist
end

function IllustrateData:IsFirstGetHero(shipInfoId)
  return self.oldCurrId[shipInfoId] == nil
end

function IllustrateData:UpdateOldIllustrateData()
  if self.currId ~= {} then
    self.oldCurrId = clone(self.currId)
  end
end

function IllustrateData:SetVowCount(count)
  self.m_vowCount = count
end

function IllustrateData:GetVowCount()
  return self.m_vowCount
end

function IllustrateData:GetSkipVcr()
  local arrSkipVcr = {}
  for _, v in pairs(self.SkipVcr) do
    table.insert(arrSkipVcr, v)
  end
  return arrSkipVcr
end

function IllustrateData:GetWishItemNum(id)
  return self.VowItemUseInfo[id] or 0
end

function IllustrateData:GetHeroMemorys()
  return self.heroMemoryList
end

function IllustrateData:SetHeroMemorysDirty(dirty)
  self.heroMemroyDirty = dirty
end

function IllustrateData:IsHeroMemorysDirty()
  return self.heroMemroyDirty
end

function IllustrateData:_HandleConfig()
  self:_HandleShipHandbookConfig()
end

function IllustrateData:_HandleShipHandbookConfig()
  local configs = configManager.GetData("config_ship_handbook")
  for id, config in pairs(configs) do
    if config.activatetime > 0 then
      self.m_activetime[id] = {
        Stamp = config.activatetime,
        Pass = false
      }
    end
    if 0 < config.wish_activatetime then
      self.m_wish_activetime[id] = {
        Stamp = config.wish_activatetime,
        Pass = false
      }
    end
  end
end

function IllustrateData:GetWishActiveTime()
  return self.m_wish_activetime
end

function IllustrateData:CheckRefreshHero()
  local stamps = self.m_activetime
  local ids = {}
  for id, value in pairs(stamps) do
    if value.Stamp <= time.getSvrTime() and not value.Pass then
      table.insert(ids, id)
    end
  end
  if 0 < #ids then
    self:LocalUpdateHero()
  end
end

function IllustrateData:UpdateEquip(datas)
  self.allCount = 0
  self.haveCount = 0
  local allEquip = configManager.GetData("config_equip")
  local tabConfig = {}
  for k, v in pairs(allEquip) do
    if v.picture_show == 1 then
      self.allCount = self.allCount + 1
      tabConfig[v.e_id] = v
    end
  end
  for index, info in ipairs(datas) do
    local config = tabConfig[info.EquipTemplateId]
    if config and self.equipHaveIllustrate[info.EquipTemplateId] == nil then
      local item = {}
      item = info
      item.IllustrateState = IllustrateState.UNLOCK
      local id = Mathf.ToInt(item.EquipTemplateId)
      local equipData = configManager.GetDataById("config_equip", id)
      item.EquipId = id
      item.name = equipData.name
      item.quality = equipData.quality
      item.icon = equipData.icon
      item.newEquip = info.NewEquip
      item.equip_ship = equipData.equip_ship
      item.ewt_id = equipData.ewt_id
      item.equip_type_id = equipData.equip_type_id
      if self.haveNewEquip == false and info.NewEquip then
        self.haveNewEquip = true
      end
      self.haveCount = self.haveCount + 1
      self.equipIllustrate[id] = item
      self.equipHaveIllustrate[id] = item
    end
  end
  for id, config in pairs(tabConfig) do
    if self.equipIllustrate[id] == nil then
      local item = {}
      item.newEquip = false
      item.IllustrateState = IllustrateState.LOCK
      item.EquipId = config.e_id
      item.name = config.name
      item.quality = config.quality
      item.icon = config.icon
      item.equip_ship = config.equip_ship
      item.ewt_id = config.ewt_id
      item.equip_type_id = config.equip_type_id
      self.equipIllustrate[id] = item
    end
  end
end

function IllustrateData:UpdataIllustrateEquipData(data)
  if self.equipIllustrate == nil then
    return
  end
  for id, info in pairs(self.equipIllustrate) do
    if id == data.EquipTemplateId then
      if info.IllustrateState ~= IllustrateState.UNLOCK then
        info.IllustrateState = IllustrateState.UNLOCK
      end
      info.GetTime = data.GetTime
      info.newEquip = data.newEquip
      if self.haveNewEquip == false and data.newEquip then
        self.haveNewEquip = true
      end
      return
    end
  end
end

function IllustrateData:GetEquipData(...)
  local equipData = {}
  for k, v in pairs(self.equipIllustrate) do
    table.insert(equipData, v)
  end
  return equipData
end

function IllustrateData:GetIllustrateEquipById(equipID)
  return self.equipIllustrate[equipID]
end

function IllustrateData:GetEquipCount()
  local equip = {}
  for id, info in pairs(self.equipIllustrate) do
    if info.IllustrateState == IllustrateState.UNLOCK then
      table.insert(equip, id)
    end
  end
  local count = #equip
  return count, self.allCount
end

function IllustrateData:IsHaveNewEquip(...)
  return self.haveNewEquip
end

return IllustrateData
