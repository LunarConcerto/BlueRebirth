HeroSortHelper = {}
local SortNameType = {
  [HeroSortType.Rarity] = 1,
  [HeroSortType.Lvl] = 2,
  [HeroSortType.Property] = 3,
  [HeroSortType.CreateTime] = 4,
  [HeroSortType.AttackGrade] = 5,
  [HeroSortType.Mood] = 6,
  [HeroSortType.BuildingEffect] = 7,
  [HeroSortType.Status] = 8,
  [HeroSortType.BuildingCharacter] = 9,
  [HeroSortType.BathFleet] = 10
}

function HeroSortHelper.FilterAndSort(tab_heros, tab_filterRule, sortRule, descend, recommendTbl, fleetType)
  local tabTemp = HeroSortHelper._Filter(tab_heros, tab_filterRule, recommendTbl)
  local sortOrder = {
    HeroSortType.Rarity,
    HeroSortType.TemplateId,
    HeroSortType.Lvl,
    HeroSortType.Property,
    HeroSortType.CreateTime,
    "SortDefault"
  }
  for k, v in pairs(sortOrder) do
    if v == sortRule then
      table.remove(sortOrder, k)
      break
    end
  end
  table.insert(sortOrder, 1, sortRule)
  local custom = {Ships = recommendTbl, FleetType = fleetType}
  return HeroSortHelper._Sort(tabTemp, sortOrder, descend, custom)
end

function HeroSortHelper.FilterAndSortBuilding(tab_heros, tab_filterRule, sortRule, descend, buildingId)
  local tabTemp = HeroSortHelper._Filter(tab_heros, tab_filterRule, recommendTbl, buildingId)
  local sortOrder = {
    HeroSortType.Rarity,
    HeroSortType.TemplateId,
    HeroSortType.Lvl,
    HeroSortType.Property,
    HeroSortType.CreateTime,
    "SortDefault"
  }
  for k, v in pairs(sortOrder) do
    if v == sortRule then
      table.remove(sortOrder, k)
      break
    end
  end
  local buildingCfg, buildingData
  if buildingId then
    buildingData = Data.buildingData:GetBuildingById(buildingId)
    buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  end
  if sortRule == HeroSortType.Mood and buildingCfg and buildingCfg.type ~= MBuildingType.DormRoom then
    sortRule = HeroSortType.BuildingHeroMood
  end
  table.insert(sortOrder, 1, sortRule)
  local buildingType = Logic.buildingLogic:GetBuildingTypeById(buildingId)
  local custom = {Type = buildingType}
  if buildingId then
    if buildingCfg.type == MBuildingType.ItemFactory and buildingData.RecipeId > 0 then
      custom.RecipeId = buildingData.RecipeId
      table.insert(sortOrder, 1, HeroSortType.RecipeType)
    end
    if buildingCfg.type == MBuildingType.DormRoom then
      table.insert(sortOrder, 1, HeroSortType.BuildingDorm)
    end
  end
  table.insert(sortOrder, 1, HeroSortType.BuildingSelect)
  return HeroSortHelper._Sort(tabTemp, sortOrder, descend, custom)
end

function HeroSortHelper.FilterAndSort1(tab_heros, tab_filterRule, sortRule, descend)
  local tabTemp = HeroSortHelper._Filter(tab_heros, tab_filterRule)
  local sortOrder = {
    HeroSortType.Rarity,
    HeroSortType.TemplateId,
    HeroSortType.Lvl,
    HeroSortType.Property,
    HeroSortType.CreateTime,
    HeroSortType.AttackGrade
  }
  for k, v in pairs(sortOrder) do
    if v == sortRule then
      table.remove(sortOrder, k)
      break
    end
  end
  table.insert(sortOrder, 1, sortRule)
  local fleets, others = HeroSortHelper.findFleets(tabTemp)
  HeroSortHelper._Sort(fleets, sortOrder, descend)
  HeroSortHelper._Sort(others, sortOrder, descend)
  if 0 < #fleets then
    table.insertto(fleets, others)
    return fleets
  else
    return others
  end
end

function HeroSortHelper.PictureFilterAndSort(tab_heros, tab_filterRule, descend)
  local tabTemp = HeroSortHelper._Filter(tab_heros, tab_filterRule)
  local sortOrder = {
    HeroSortType.Lock
  }
  return HeroSortHelper._Sort(tabTemp, sortOrder, descend)
end

function HeroSortHelper.PictureEquipFilterAndSort(tab_heros, tab_filterRule, descend)
  local tabTemp = HeroSortHelper._Filter(tab_heros, tab_filterRule)
  local sortOrder = {
    HeroSortType.IllustrateEquip
  }
  return HeroSortHelper._Sort(tabTemp, sortOrder, descend)
end

function HeroSortHelper.AssistFilterAndSort(tab_heros, tab_filterRule, sortRule, descend, custom)
  local tabTemp = HeroSortHelper._Filter(tab_heros, tab_filterRule)
  local sortOrder = {
    HeroSortType.SpecialShip,
    HeroSortType.SpecialShipType,
    HeroSortType.Rarity,
    HeroSortType.TemplateId,
    HeroSortType.Lvl,
    HeroSortType.Property,
    HeroSortType.CreateTime,
    HeroSortType.AttackGrade
  }
  for k, v in pairs(sortOrder) do
    if v == sortRule then
      table.remove(sortOrder, k)
      break
    end
  end
  table.insert(sortOrder, 3, sortRule)
  local fleets, others = HeroSortHelper.findFleets(tabTemp)
  HeroSortHelper._Sort(fleets, sortOrder, descend, custom)
  HeroSortHelper._Sort(others, sortOrder, descend, custom)
  if 0 < #fleets then
    table.insertto(fleets, others)
    return fleets
  else
    return others
  end
end

function HeroSortHelper.AutoEquipSortAndFilter(heros, option, max, descend, custom)
  local sortOrder = {
    HeroSortType.Property,
    HeroSortType.Lvl,
    HeroSortType.AttackGrade,
    HeroSortType.Rarity,
    HeroSortType.CreateTime,
    "SortDefault"
  }
  local index
  for k, v in pairs(sortOrder) do
    if v == option then
      table.remove(sortOrder, k)
      index = k
      break
    end
  end
  if index then
    table.insert(sortOrder, 1, option)
  end
  HeroSortHelper._Sort(heros, sortOrder, descend, custom)
  local res = {}
  if max < #heros then
    for i = 1, #heros do
      if max >= i then
        res[i] = heros[i].HeroId
      end
    end
  else
    for i, v in ipairs(heros) do
      res[i] = v.HeroId
    end
  end
  return res
end

function HeroSortHelper.ShopFashionFiler(goods, tab_filterRule)
  return HeroSortHelper._Filter(goods, tab_filterRule)
end

function HeroSortHelper.ShopFashionSortAndFiler(goods, tab_filterRule)
  local tabTemp = HeroSortHelper._Filter(goods, tab_filterRule)
  local sortOrder = {
    HeroSortType.FASHION_Own
  }
  return HeroSortHelper._Sort(tabTemp, sortOrder, false)
end

function HeroSortHelper.CustomSortHero(heros, custom, index)
  table.sort(heros, function(data1, data2)
    local i = 1
    while i <= #custom do
      local state = HeroSortHelper.SortFuncs[custom[i][1]](data1, data2, custom[i][2] == 0)
      if state == 0 then
        i = i + 1
      else
        return state == 2
      end
    end
  end)
end

function HeroSortHelper.BuildingSortHero(heros, buildType)
  local char
  table.sort(heros, function(data1, data2)
    local max1, max2
    char, max1 = Logic.buildingLogic:GetBestChar(buildType, data1.TemplateId)
    char, max2 = Logic.buildingLogic:GetBestChar(buildType, data2.TemplateId)
    return max1 > max2
  end)
  return heros
end

function HeroSortHelper.GetSortName(sortType)
  local tabSortInfo = {}
  local tabTemp = configManager.GetData("config_shiplist_sequence")
  local nCount = GetTableLength(tabTemp)
  for i = 1, nCount do
    if tabTemp[i].belong == 1 then
      table.insert(tabSortInfo, tabTemp[i])
    end
  end
  local num = SortNameType[sortType]
  return tabSortInfo[num].name
end

function HeroSortHelper.findFleets(heros)
  local fleets, others = {}, {}
  local infleet = false
  for k, hero in pairs(heros) do
    infleet = Logic.shipLogic:IsInFleet(hero.HeroId)
    if infleet then
      table.insert(fleets, hero)
    else
      table.insert(others, hero)
    end
  end
  return fleets, others
end

function HeroSortHelper._Filter(tab_heros, tab_filterRule, recommendTbl, buildingId)
  local tabTemp = {}
  for k, v in pairs(tab_heros) do
    tabTemp[#tabTemp + 1] = v
  end
  for i = 1, HeroFilterType.Count do
    if nil ~= tab_filterRule[i] then
      tabTemp = HeroSortHelper.FilterFuc[i](tabTemp, tab_filterRule[i], recommendTbl, buildingId)
    end
  end
  return tabTemp
end

function HeroSortHelper.FilterHeroByBuilding(tab_heros, tab_indexRules, recommendTbl, buildingId)
  local tabTemp = {}
  local uniqueMap = {}
  local tabInBuildingHero = {}
  local tabBuildingHero = Logic.buildingLogic:GetSaveBuildingHero()
  for i = 1, #tab_heros do
    local hero = tab_heros[i]
    for k, v in pairs(tabBuildingHero) do
      if hero.HeroId == v then
        table.insert(tabInBuildingHero, hero)
      end
    end
    if nil ~= hero then
      for j = 1, #tab_indexRules do
        local filter = tab_indexRules[j]
        if HeroBuildingIndexType.NotSet == filter then
          local inBuilding = Logic.buildingLogic:IsBuildingHero(hero.HeroId)
          local inBath = Logic.buildingLogic:IsBathHero(hero.HeroId)
          if not inBath and not inBuilding then
            table.insert(tabTemp, hero)
          end
        elseif filter >= HeroBuildingIndexType.Office and filter <= HeroBuildingIndexType.FoodFactory then
          local buildingType = filter - 1
          if not uniqueMap[hero.HeroId] and Logic.buildingLogic:CheckHeroBuilding(hero.TemplateId, buildingType) then
            table.insert(tabTemp, hero)
            uniqueMap[hero.HeroId] = true
          end
        elseif not uniqueMap[hero.HeroId] and filter >= HeroBuildingIndexType.ModifyMat and filter <= HeroBuildingIndexType.SkillBook then
          local recipeType = filter - (HeroBuildingIndexType.ModifyMat - 1)
          if Logic.buildingLogic:CheckHeroRecipe(hero.TemplateId, recipeType) then
            table.insert(tabTemp, hero)
            uniqueMap[hero.HeroId] = true
          end
        end
      end
    else
    end
  end
  local mapTemp = {}
  for k, v in pairs(tabInBuildingHero) do
    mapTemp[v.HeroId] = v
  end
  for k, v in pairs(tabTemp) do
    if mapTemp[v.HeroId] then
      mapTemp[v.HeroId] = nil
    end
  end
  for key, value in pairs(mapTemp) do
    table.insert(tabTemp, value)
  end
  return tabTemp
end

function HeroSortHelper.FilterHeroByIndex(tab_heros, tab_indexRules)
  local tabTemp = {}
  local typeMap = {}
  for _, type in ipairs(tab_indexRules) do
    typeMap[type] = true
  end
  for i = 1, #tab_heros do
    local hero = tab_heros[i]
    if hero and typeMap[hero.type] then
      tabTemp[#tabTemp + 1] = hero
    end
  end
  return tabTemp
end

function HeroSortHelper.FilterHeroByCamp(tab_heros, tab_campRules)
  local tabTemp = {}
  local campMap = {}
  for _, camp in ipairs(tab_campRules) do
    campMap[camp] = true
  end
  for i = 1, #tab_heros do
    local hero = tab_heros[i]
    if hero and campMap[hero.shipCountry] then
      tabTemp[#tabTemp + 1] = hero
    end
  end
  return tabTemp
end

function HeroSortHelper.FilterHeroByRarity(tab_heros, tab_rarityRules)
  local tabTemp = {}
  local rarityMap = {}
  for _, rarity in ipairs(tab_rarityRules) do
    rarityMap[rarity] = true
  end
  for i = 1, #tab_heros do
    local hero = tab_heros[i]
    if hero and rarityMap[hero.quality] then
      tabTemp[#tabTemp + 1] = hero
    end
  end
  return tabTemp
end

function HeroSortHelper.FilterHeroByLock(tab_heros, tab_lockRules)
  local tabTemp = {}
  for i = 1, #tab_heros do
    local hero = tab_heros[i]
    if nil ~= hero then
      for j = 1, #tab_lockRules do
        if hero.IllustrateState == tab_lockRules[j] then
          tabTemp[#tabTemp + 1] = hero
          break
        end
      end
    end
  end
  return tabTemp
end

function HeroSortHelper.FilterHeroByRecommend(tab_heros, tab_Rules, recommendTbl)
  local tabTemp = {}
  for i = 1, #tab_heros do
    local hero = tab_heros[i]
    if nil ~= hero then
      local shipInfoId = Logic.shipLogic:GetShipInfoId(hero.TemplateId)
      if recommendTbl[shipInfoId] then
        table.insert(tabTemp, hero)
      end
    end
  end
  return tabTemp
end

function HeroSortHelper.FilterEquipByIndex(tab_equip, tab_indexRules)
  local tabTemp = {}
  local typeMap = {}
  for _, type in ipairs(tab_indexRules) do
    typeMap[type] = true
  end
  for i = 1, #tab_equip do
    local equip = tab_equip[i]
    for k, v in pairs(equip.equip_ship) do
      if typeMap[v] then
        tabTemp[#tabTemp + 1] = equip
      end
    end
  end
  return tabTemp
end

function HeroSortHelper.FilterEquipByType(tab_equip, tab_indexRules)
  local tabTemp = {}
  local typeMap = {}
  for _, type in ipairs(tab_indexRules) do
    typeMap[type] = true
  end
  for i = 1, #tab_equip do
    local equip = tab_equip[i]
    for k, v in pairs(equip.ewt_id) do
      local equipFashionType = configManager.GetDataById("config_equip_fashion_type", v).equippicture_type
      if typeMap[equipFashionType] then
        tabTemp[#tabTemp + 1] = equip
      end
    end
  end
  return tabTemp
end

HeroSortHelper.FilterFuc = {
  HeroSortHelper.FilterHeroByIndex,
  HeroSortHelper.FilterHeroByCamp,
  HeroSortHelper.FilterHeroByRarity,
  HeroSortHelper.FilterHeroByLock,
  HeroSortHelper.FilterHeroByRecommend,
  HeroSortHelper.FilterHeroByBuilding,
  HeroSortHelper.FilterEquipByType,
  HeroSortHelper.FilterEquipByIndex
}

function HeroSortHelper._Sort(tab_heros, sortOrder, descend, custom)
  table.sort(tab_heros, function(data1, data2)
    local i = 1
    while i <= #sortOrder do
      local state = HeroSortHelper.SortFuncs[sortOrder[i]](data1, data2, descend, custom)
      if state == 0 then
        i = i + 1
      else
        return state == SortResult.Greater
      end
    end
  end)
  return tab_heros
end

function HeroSortHelper.SortHeroByRarity(data1, data2, descend)
  return HeroSortHelper._SortImp(data1.quality, data2.quality, descend)
end

function HeroSortHelper.SortHeroByLvl(data1, data2, descend)
  return HeroSortHelper._SortImp(data1.Lvl, data2.Lvl, descend)
end

function HeroSortHelper.SortHeroByProperty(data1, data2, descend, custom)
  if data1.HeroId ~= 0 and data2.HeroId ~= 0 then
    local fleetType
    if custom and custom.FleetType then
      fleetType = custom.FleetType
    end
    local attr1 = Logic.attrLogic:GetBattlePower(data1.HeroId, fleetType)
    local attr2 = Logic.attrLogic:GetBattlePower(data2.HeroId, fleetType)
    return HeroSortHelper._SortImp(attr1, attr2, descend)
  else
    return HeroSortHelper._SortImp(data1.HeroId, data2.HeroId, descend)
  end
end

function HeroSortHelper.SortHeroByCreateTime(data1, data2, descend)
  return HeroSortHelper._SortImp(data1.CreateTime, data2.CreateTime, descend)
end

function HeroSortHelper.SortHeroByLock(data1, data2, descend)
  return HeroSortHelper._SortImp(data1.ship_order, data2.ship_order, descend)
end

function HeroSortHelper.SortHeroBySpecialShip(data1, data2, descend, custom)
  local si_id1 = Logic.shipLogic:GetShipInfoIdByTid(data1.TemplateId)
  local si_id2 = Logic.shipLogic:GetShipInfoIdByTid(data2.TemplateId)
  local index1 = table.keyof(custom.Ships, si_id1) or 0
  local index2 = table.keyof(custom.Ships, si_id2) or 0
  if index1 < index2 then
    return SortResult.Less
  elseif index1 > index2 then
    return SortResult.Greater
  else
    return SortResult.Equal
  end
end

function HeroSortHelper.SortHeroByTemplateId(data1, data2, descend)
  return HeroSortHelper._SortImp(data1.TemplateId, data2.TemplateId, descend)
end

function HeroSortHelper.SortHeroByFleet(data1, data2, descend)
  local fleet1 = Logic.shipLogic:GetHeroFleet(data1.HeroId)
  local fleet2 = Logic.shipLogic:GetHeroFleet(data2.HeroId)
  return HeroSortHelper._SortImp(fleet1, fleet2, true)
end

function HeroSortHelper.SortHeroByAdvance(data1, data2, descend)
  return HeroSortHelper._SortImp(data1.Advance, data2.Advance, descend)
end

function HeroSortHelper.SortHeroByRecommend(data1, data2, descend, custom)
  local recommendTbl = custom.Ships
  local shipInfoId1 = Logic.shipLogic:GetShipInfoId(data1.TemplateId)
  local shipInfoId2 = Logic.shipLogic:GetShipInfoId(data2.TemplateId)
  if recommendTbl[shipInfoId1] == recommendTbl[shipInfoId2] then
    return SortResult.Equal
  elseif recommendTbl[shipInfoId1] == true then
    return SortResult.Greater
  else
    return SortResult.Less
  end
end

function HeroSortHelper.SortHeroBySpecialShipType(data1, data2, descend, custom)
  local index1 = table.keyof(custom.Types, data1.type) or 0
  local index2 = table.keyof(custom.Types, data2.type) or 0
  if index1 < index2 then
    return SortResult.Less
  elseif index1 > index2 then
    return SortResult.Greater
  else
    return SortResult.Equal
  end
end

function HeroSortHelper.SortHeroByHeroId(data1, data2, descend)
  return HeroSortHelper._SortImp(data1.HeroId, data2.HeroId, descend)
end

function HeroSortHelper.SortHeroByAttackGrade(data1, data2, descend, custom)
  local fleetType
  if custom and custom.FleetType then
    fleetType = custom.FleetType
  end
  local attr1 = Logic.attrLogic:GetAttackGrade(data1.HeroId, fleetType)
  local attr2 = Logic.attrLogic:GetAttackGrade(data2.HeroId, fleetType)
  if Logic.towerLogic:IsTowerType(fleetType) then
    attr1 = Logic.fleetLogic:GetAttackAddition(data1, attr1, fleetType)
    attr2 = Logic.fleetLogic:GetAttackAddition(data2, attr2, fleetType)
  end
  return HeroSortHelper._SortImp(attr1, attr2, descend)
end

function HeroSortHelper.SortHeroByMood(data1, data2, descend)
  local mood1 = Logic.marryLogic:GetMoodNum(data1, data1.HeroId)
  local mood2 = Logic.marryLogic:GetMoodNum(data2, data2.HeroId)
  return HeroSortHelper._SortImp(mood1, mood2, descend)
end

function HeroSortHelper.SortHeroByBuildingEffect(data1, data2, descend)
  local effect1 = Logic.buildingLogic:GetHeroBuildingEffect(data1)
  local effect2 = Logic.buildingLogic:GetHeroBuildingEffect(data2)
  return HeroSortHelper._SortImp(effect1, effect2, descend)
end

function HeroSortHelper.SortHeroByBuildingSelect(data1, data2, descend)
  local front = descend and 1 or 0
  local back = descend and 0 or 1
  local match1 = Logic.buildingLogic:IsBuildingHeroSort(data1.HeroId) and front or back
  local match2 = Logic.buildingLogic:IsBuildingHeroSort(data2.HeroId) and front or back
  return HeroSortHelper._SortImp(match1, match2, descend)
end

function HeroSortHelper.SortHeroByCharacter(data1, data2, descend, custom)
  local match1, match2 = Logic.buildingLogic:GetBuildingCharacterSortLevel(data1, data2, custom.Type, descend)
  return HeroSortHelper._SortImp(match1, match2, descend)
end

function HeroSortHelper.SortHeroByBuildingHeroMood(data1, data2, descend, custom)
  local match1, match2 = Logic.buildingLogic:GetBuildingCharacterSortMood(data1, data2, custom.Type, descend)
  return HeroSortHelper._SortImp(match1, match2, descend)
end

function HeroSortHelper.SortHeroByRecipeType(data1, data2, descend, custom)
  local match1 = Logic.buildingLogic:GetHeroRecipeType(data1, custom.RecipeId)
  local match2 = Logic.buildingLogic:GetHeroRecipeType(data2, custom.RecipeId)
  return HeroSortHelper._SortImp(match1, match2, descend)
end

function HeroSortHelper.SortHeroByStatus(data1, data2, descend)
  local status1 = Logic.buildingLogic:GetHeroStatus(data1)
  local status2 = Logic.buildingLogic:GetHeroStatus(data2)
  return HeroSortHelper._SortImp(status1, status2, descend)
end

function HeroSortHelper.SortHeroByDorm(data1, data2, descend)
  local front = descend and 1 or 0
  local back = descend and 0 or 1
  local inDorm1 = Logic.buildingLogic:IsHeroInDormOrBath(data1.HeroId) and back or front
  local inDorm2 = Logic.buildingLogic:IsHeroInDormOrBath(data2.HeroId) and back or front
  return HeroSortHelper._SortImp(inDorm1, inDorm2, descend)
end

function HeroSortHelper.SortHeroByEquipId(data1, data2, descend)
  return HeroSortHelper._SortImp(data1.equip_type_id, data2.equip_type_id, descend)
end

function HeroSortHelper.SortHeroByEquipId(data1, data2, descend)
  if data1.equip_type_id ~= data2.equip_type_id then
    return HeroSortHelper._SortImp(data1.equip_type_id, data2.equip_type_id, descend)
  else
    return HeroSortHelper._SortImp(data1.EquipId, data2.EquipId, descend)
  end
end

function HeroSortHelper.SortFashionByOwn(data1, data2, descend)
  local own1 = Logic.fashionLogic:CheckFashionOwn(data1.fashionId) and 1 or 0
  local own2 = Logic.fashionLogic:CheckFashionOwn(data2.fashionId) and 1 or 0
  return HeroSortHelper._SortImp(own1, own2, descend)
end

function HeroSortHelper._SortImp(data1, data2, descend)
  if descend then
    if data2 < data1 then
      return SortResult.Greater
    elseif data1 < data2 then
      return SortResult.Less
    else
      return SortResult.Equal
    end
  elseif data1 < data2 then
    return SortResult.Greater
  elseif data2 < data1 then
    return SortResult.Less
  else
    return SortResult.Equal
  end
end

HeroSortHelper.SortFuncs = {
  [HeroSortType.Rarity] = HeroSortHelper.SortHeroByRarity,
  [HeroSortType.Lvl] = HeroSortHelper.SortHeroByLvl,
  [HeroSortType.Property] = HeroSortHelper.SortHeroByProperty,
  [HeroSortType.CreateTime] = HeroSortHelper.SortHeroByCreateTime,
  [HeroSortType.Lock] = HeroSortHelper.SortHeroByLock,
  [HeroSortType.SpecialShip] = HeroSortHelper.SortHeroBySpecialShip,
  [HeroSortType.TemplateId] = HeroSortHelper.SortHeroByTemplateId,
  [HeroSortType.Fleet] = HeroSortHelper.SortHeroByFleet,
  [HeroSortType.Advance] = HeroSortHelper.SortHeroByAdvance,
  [HeroSortType.Recommend] = HeroSortHelper.SortHeroByRecommend,
  [HeroSortType.SpecialShipType] = HeroSortHelper.SortHeroBySpecialShipType,
  SortDefault = HeroSortHelper.SortHeroByHeroId,
  [HeroSortType.AttackGrade] = HeroSortHelper.SortHeroByAttackGrade,
  [HeroSortType.Mood] = HeroSortHelper.SortHeroByMood,
  [HeroSortType.BuildingEffect] = HeroSortHelper.SortHeroByBuildingEffect,
  [HeroSortType.Status] = HeroSortHelper.SortHeroByStatus,
  [HeroSortType.BuildingSelect] = HeroSortHelper.SortHeroByBuildingSelect,
  [HeroSortType.BuildingCharacter] = HeroSortHelper.SortHeroByCharacter,
  [HeroSortType.RecipeType] = HeroSortHelper.SortHeroByRecipeType,
  [HeroSortType.BuildingDorm] = HeroSortHelper.SortHeroByDorm,
  [HeroSortType.BuildingHeroMood] = HeroSortHelper.SortHeroByBuildingHeroMood,
  [HeroSortType.IllustrateEquip] = HeroSortHelper.SortHeroByEquipId,
  [HeroSortType.FASHION_Own] = HeroSortHelper.SortFashionByOwn
}
