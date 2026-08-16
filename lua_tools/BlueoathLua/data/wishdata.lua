local WishData = class("data.WishData", Data.BaseData)

function WishData:initialize()
  self:ResetData()
end

function WishData:ResetData()
  self.m_selectData = {}
  self.m_banData = {}
  self.m_allData = {}
  self.m_noData = {}
  self.m_srcount, self.m_ssrcount = 0, 0
end

function WishData:GetWishItem()
  local res = {}
  local itemTab = Data.bagData:GetItemData()
  local config = configManager.GetData("config_vow_item")
  for id, _ in pairs(config) do
    for i, info in pairs(itemTab) do
      if id == i then
        table.insert(res, info)
      end
    end
  end
  return res
end

function WishData:UpdateWishHeroOrgainData()
  local heroData = Data.heroData:GetHeroData()
  local srcount, ssrcount = 0, 0
  local counter = function(quality)
    if quality == HeroRarityType.SR then
      srcount = srcount + 1
    end
    if quality == HeroRarityType.SSR then
      ssrcount = ssrcount + 1
    end
  end
  local activetime = Data.illustrateData:GetWishActiveTime()
  local svrActive = function(id)
    if activetime[id] then
      activetime[id].Pass = true
    end
  end
  local res, nohero = {}, {}
  local canwish = false
  local id = 0
  for heroId, data in pairs(heroData) do
    id = Logic.shipLogic:GetShipInfoIdByTid(data.TemplateId)
    canwish = Logic.wishLogic:CheckCanWish(id)
    if WishData.BaseCondition(data.quality) then
      local temp = {}
      temp.CreateTime = data.CreateTime
      temp.HeroId = heroId
      temp.TemplateId = data.TemplateId
      temp.shipCountry = data.shipCountry
      temp.quality = data.quality
      temp.type = data.type
      local ad, lv = Logic.wishLogic:GetHeroMaxLvByillId(id, data)
      temp.Advance = ad
      temp.Lvl = lv
      temp.IllustrateId = id
      local compare = res[id]
      if canwish then
        if compare ~= nil then
          if compare.Advance < temp.Advance then
            res[id] = temp
          end
        else
          res[id] = temp
          counter(data.quality)
          svrActive(id)
        end
      elseif compare ~= nil then
        if compare.Advance < temp.Advance then
          nohero[id] = temp
        end
      else
        nohero[id] = temp
      end
    end
  end
  local illustrateData = Data.illustrateData:GetAllIllustrate()
  for id, data in pairs(illustrateData) do
    canwish = Logic.wishLogic:CheckCanWish(id)
    if data.GetTime ~= 0 and WishData.BaseCondition(data.quality) then
      local temp = {}
      temp.CreateTime = data.GetTime
      temp.HeroId = 0
      local ad, lv = Logic.wishLogic:GetHeroMaxLvByillId(id)
      temp.Advance = ad
      temp.Lvl = lv
      temp.TemplateId = Logic.illustrateLogic:GetIllustrateTid(id)
      temp.shipCountry = data.shipCountry
      temp.quality = data.quality
      temp.type = data.type
      temp.IllustrateId = id
      if canwish then
        if res[id] == nil then
          res[id] = temp
          counter(data.quality)
          svrActive(id)
        end
      elseif nohero[id] == nil then
        nohero[id] = temp
      end
    end
  end
  self.m_allData = res
  self.m_noData = nohero
  self.m_srcount, self.m_ssrcount = srcount, ssrcount
  return res
end

function WishData:GetNoShipById(tid)
  if self.m_noData[tid] then
    return self.m_noData[tid]
  else
    return self:GenWishTemplate(tid)
  end
end

function WishData:GenWishTemplate(tid)
  local res = {}
  res.CreateTime = 0
  res.HeroId = 0
  res.Advance = 1
  local config = Logic.illustrateLogic:GetIllustrateConfigById(tid)
  if config then
    res.shipCountry = config.ship_country
    res.quality = config.quality
    res.type = config.type
    res.TemplateId = Logic.illustrateLogic:GetIllustrateTid(tid)
    res.Lvl = 1
    res.IllustrateId = tid
    return res
  else
    return nil
  end
end

function WishData.BaseCondition(quality)
  return quality == HeroRarityType.SR or quality == HeroRarityType.SSR
end

function WishData:UpdateWishHero()
  local heroData = Data.heroData:GetHeroData()
  local illustrateData = Data.illustrateData:GetAllIllustrate()
  if table.empty(heroData) or table.empty(illustrateData) then
    return
  end
  local preHeroList = Data.illustrateData:GetPreHeroList()
  if #preHeroList ~= 0 then
    preHeroList = Logic.wishLogic:FilterCanWish(preHeroList)
    self.m_selectData, self.m_banData = self:_dealWishHeroByPreHeros(preHeroList)
  else
    self.m_selectData = self:_getDefaultSelectHero()
    self.m_banData = self:_getDefaultBanHero()
  end
end

function WishData:_dealWishHeroByPreHeros(preHeroList)
  local selectHeros, banHeros = {}, {}
  local datas = self:UpdateWishHeroOrgainData()
  for index, id in ipairs(preHeroList) do
    if datas[id] ~= nil then
      table.insert(selectHeros, clone(datas[id]))
    else
      logError("\228\184\138\230\172\161\232\174\184\230\132\191\231\154\132\232\139\177\233\155\132\230\149\176\230\141\174\228\184\141\229\156\168\232\139\177\233\155\132\229\142\159\229\167\139\230\149\176\230\141\174\228\184\173,id:" .. id)
    end
  end
  for id, info in pairs(datas) do
    if self:_findKey(selectHeros, id) == 0 then
      table.insert(banHeros, clone(info))
    end
  end
  return selectHeros, banHeros
end

function WishData:_getDefaultBanHero()
  local res = {}
  local illustrate = self:UpdateWishHeroOrgainData()
  for id, info in pairs(illustrate) do
    table.insert(res, clone(info))
  end
  return res
end

function WishData:_getDefaultSelectHero()
  return {}
end

function WishData:GetSelectHeroList()
  return self.m_selectData
end

function WishData:GetBanHeroList()
  return self.m_banData
end

function WishData:AddSelectHero(id, index)
  index = Mathf.Clamp(index, 1, #self.m_selectData + 1)
  if self.m_allData[id] and self:_findKey(self.m_selectData, id) == 0 then
    table.insert(self.m_selectData, index, clone(self.m_allData[id]))
    self:_syncWishHero()
  end
  self:_removeBanHero(id)
end

function WishData:InsertSelectHero(id, index)
  local temp = {}
  index = index or #self.m_selectData
  local oldIndex = self:_findKey(self.m_selectData, id)
  if 0 < oldIndex and index ~= oldIndex then
    local temp = clone(self.m_selectData[oldIndex])
    table.remove(self.m_selectData, oldIndex)
    index = Mathf.Clamp(index, 1, #self.m_selectData + 1)
    table.insert(self.m_selectData, index, temp)
  end
end

function WishData:AddBanHero(id, index)
  index = index or #self.m_banData + 1
  index = Mathf.Clamp(index, 1, #self.m_banData + 1)
  if self.m_allData[id] and self:_findKey(self.m_banData, id) == 0 then
    table.insert(self.m_banData, index, clone(self.m_allData[id]))
  end
  self:_removeSelectHero(id)
end

function WishData:_findKey(data, id)
  for index, info in ipairs(data) do
    if info.IllustrateId == id then
      return index
    end
  end
  return 0
end

function WishData:_removeSelectHero(id)
  local index = self:_findKey(self.m_selectData, id)
  if 0 < index then
    table.remove(self.m_selectData, index)
    self:_syncWishHero()
  end
end

function WishData:_removeBanHero(id)
  local index = self:_findKey(self.m_banData, id)
  if 0 < index then
    table.remove(self.m_banData, index)
  end
end

function WishData:AllSelect(sortData)
  local sorter = self.m_banData
  if sortData then
    local sortParam = sortData[1]
    local filterParam = sortData[2]
    sorter = HeroSortHelper.FilterAndSort(self.m_banData, filterParam[1], filterParam[2], sortParam, nil)
  end
  sorter, self.m_banData = self:_selectFilter(sorter)
  self.m_selectData = table.append(self.m_selectData, sorter)
  self:_syncWishHero()
end

function WishData:_selectFilter(selects)
  local ok, err = {}, {}
  for _, hero in pairs(selects) do
    if hero.Advance < Logic.shipLogic:GetBreakMaxByShipMainId(hero.TemplateId) then
      table.insert(ok, hero)
    else
      table.insert(err, hero)
    end
  end
  return ok, err
end

function WishData:AllBan()
  self.m_banData = table.append(self.m_banData, self.m_selectData)
  self.m_selectData = {}
  self:_syncWishHero()
end

function WishData:_syncWishHero()
  local res = self:_formatWishHeroToRPC(self.m_selectData)
  Service.illustrateService:SendModiVowHero(res)
end

function WishData:_formatWishHeroToRPC(herolist)
  local res = {}
  for index, info in ipairs(herolist) do
    res[index] = info.IllustrateId
  end
  return res
end

function WishData:GetAllWishNum()
  return self.m_srcount + self.m_ssrcount, self.m_srcount, self.m_ssrcount
end

function WishData:GetSelectWishNum()
  return #self.m_selectData
end

function WishData:CheckRefreshHero()
  local stamps = Data.illustrateData:GetWishActiveTime()
  local ids = {}
  for id, value in pairs(stamps) do
    if value.Stamp <= time.getSvrTime() and not value.Pass then
      table.insert(ids, id)
    end
  end
  if 0 < #ids then
    self:UpdateWishHeroOrgainData()
  end
end

return WishData
