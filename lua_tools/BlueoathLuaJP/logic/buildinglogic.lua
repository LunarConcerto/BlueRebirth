local BuildingLogic = class("logic.BuildingLogic")
local BuildingStatusStr = {
  [BuildingStatus.Idle] = 3001004,
  [BuildingStatus.Adding] = 3001005,
  [BuildingStatus.Working] = 3001006,
  [BuildingStatus.Upgrading] = 3001007,
  [BuildingStatus.Receiving] = 3001008,
  [BuildingStatus.Waiting] = 3001009
}
local BuildingTypeNameMap = {
  [MBuildingType.Office] = 3002004,
  [MBuildingType.ElectricFactory] = 3002005,
  [MBuildingType.OilFactory] = 3002006,
  [MBuildingType.ResourceFactory] = 3002007,
  [MBuildingType.DormRoom] = 3002008,
  [MBuildingType.FoodFactory] = 3002009,
  [MBuildingType.ItemFactory] = 3002010,
  [MBuildingType.BathRoom] = 3002011
}
local LevelEffectKey = {
  [LevelEffect.ProduceSpeed] = 3002034,
  [LevelEffect.ProductMax] = 3002035,
  [LevelEffect.ElectricCost] = 3002036,
  [LevelEffect.Level] = 3002037,
  [LevelEffect.HeroCount] = 3002038,
  [LevelEffect.WorkerRecover] = 3002039,
  [LevelEffect.MoodRecover] = 3002040,
  [LevelEffect.ProduceReduceTime] = 3002041,
  [LevelEffect.MaxStrength] = 3002042
}
local BuildingRecipes = {
  [1] = "recipe",
  [2] = "recipe_compose"
}
local CharacterBuildingAddtionStrMap = {
  3100005,
  3100001,
  3100003,
  3100000,
  3100002,
  3100004
}
local CharacterItemAddtionStrMap = {
  3100006,
  3100007,
  3100008,
  3100009,
  3100010,
  3100011
}
local TypeEffectMap = {
  [MBuildingType.Office] = {
    HeroEffects = {
      HeroEffect.FoodCost,
      HeroEffect.MoodCost,
      HeroEffect.ItemProduceSpeedAdd,
      HeroEffect.CoinProduceSpeedAdd
    },
    BuildingEffects = {
      BuildingEffect.ElectricCost,
      BuildingEffect.MaxStrengthAdd
    },
    LevelEffects = {
      LevelEffect.Level,
      LevelEffect.MaxStrength,
      LevelEffect.HeroCount,
      LevelEffect.ElectricCost
    }
  },
  [MBuildingType.ElectricFactory] = {
    HeroEffects = {
      HeroEffect.FoodCost,
      HeroEffect.MoodCost,
      HeroEffect.Productivity
    },
    BuildingEffects = {
      BuildingEffect.WorkerRecover,
      BuildingEffect.MaxAdd,
      BuildingEffect.ElectricCost
    },
    LevelEffects = {
      LevelEffect.WorkerRecover,
      LevelEffect.ProductMax,
      LevelEffect.HeroCount
    }
  },
  [MBuildingType.OilFactory] = {
    HeroEffects = {
      HeroEffect.FoodCost,
      HeroEffect.MoodCost,
      HeroEffect.Productivity
    },
    BuildingEffects = {
      BuildingEffect.ProduceSpeed,
      BuildingEffect.ProductCount,
      BuildingEffect.ElectricCost
    },
    LevelEffects = {
      LevelEffect.ProduceSpeed,
      LevelEffect.ProductMax,
      LevelEffect.HeroCount,
      LevelEffect.ElectricCost
    }
  },
  [MBuildingType.ResourceFactory] = {
    HeroEffects = {
      HeroEffect.FoodCost,
      HeroEffect.MoodCost,
      HeroEffect.Productivity
    },
    BuildingEffects = {
      BuildingEffect.ProduceSpeed,
      BuildingEffect.ProductCount,
      BuildingEffect.ElectricCost,
      BuildingEffect.MoodCostRate
    },
    LevelEffects = {
      LevelEffect.ProduceSpeed,
      LevelEffect.ProductMax,
      LevelEffect.HeroCount,
      LevelEffect.ElectricCost
    }
  },
  [MBuildingType.DormRoom] = {
    HeroEffects = {
      HeroEffect.FoodCost,
      HeroEffect.Productivity
    },
    BuildingEffects = {
      BuildingEffect.MoodRecover,
      BuildingEffect.ElectricCost
    },
    LevelEffects = {
      LevelEffect.MoodRecover,
      LevelEffect.HeroCount,
      LevelEffect.ElectricCost
    }
  },
  [MBuildingType.FoodFactory] = {
    HeroEffects = {
      HeroEffect.FoodCost,
      HeroEffect.MoodCost,
      HeroEffect.Productivity
    },
    BuildingEffects = {
      BuildingEffect.MaxAdd,
      BuildingEffect.ElectricCost
    },
    LevelEffects = {
      LevelEffect.ProductMax,
      LevelEffect.HeroCount,
      LevelEffect.ElectricCost
    }
  },
  [MBuildingType.ItemFactory] = {
    HeroEffects = {
      HeroEffect.FoodCost,
      HeroEffect.MoodCost,
      HeroEffect.Productivity
    },
    BuildingEffects = {
      BuildingEffect.ElectricCost
    },
    LevelEffects = {
      LevelEffect.ProduceReduceTime,
      LevelEffect.HeroCount,
      LevelEffect.ElectricCost
    }
  }
}
local Building3DAttrs = {
  [MBuildingType.Office] = {
    HeroEffects = {
      HeroEffect.ItemProduceSpeedAdd,
      HeroEffect.CoinProduceSpeedAdd
    },
    BuildingEffects = {
      BuildingEffect.MaxStrengthAdd
    }
  },
  [MBuildingType.ElectricFactory] = {
    HeroEffects = {},
    BuildingEffects = {
      BuildingEffect.WorkerRecover,
      BuildingEffect.MaxAdd
    }
  },
  [MBuildingType.OilFactory] = {
    HeroEffects = {},
    BuildingEffects = {
      BuildingEffect.ProduceSpeed,
      BuildingEffect.ProductCount
    }
  },
  [MBuildingType.ResourceFactory] = {
    HeroEffects = {},
    BuildingEffects = {
      BuildingEffect.ProduceSpeed,
      BuildingEffect.ProductCount
    }
  },
  [MBuildingType.FoodFactory] = {
    HeroEffects = {},
    BuildingEffects = {
      BuildingEffect.MaxAdd
    }
  }
}
local BGM = {
  [MBuildingType.Office] = "System|Infrastructure_AdmiralRoom",
  [MBuildingType.ElectricFactory] = "System|Infrastructure_Refinery",
  [MBuildingType.OilFactory] = "System|Infrastructure_Refinery",
  [MBuildingType.ResourceFactory] = "System|Infrastructure_Izakaya",
  [MBuildingType.DormRoom] = "System|Infrastructure_DormRoom",
  [MBuildingType.FoodFactory] = "System|Infrastructure_Restaurant",
  [MBuildingType.ItemFactory] = "System|Infrastructure_Refinery"
}
local BuildInitLv = 1

function BuildingLogic:initialize()
  self:ResetData()
  pushNoticeManager:_BindNotice("building", function()
    return self:GetPushNoticeParams(Data.buildingData:GetBuildingData())
  end)
end

function BuildingLogic:ResetData()
  self.groupLv2Tid = {}
  self.typeLv2Tid = {}
  self.typeLv2LvupTid = {}
  self.recipeType2Tid = {}
  self.recipeTypes = {}
  self.m_buildHeroSfIds = {}
  self.tabSelectShip = {}
  self.shipFleetPlotMap = {}
  self:_HandleBuildingConfig()
  self.buildingMode = BuildingMode._3D
end

function BuildingLogic:RefreshBuildingHeroSfId()
  local res = {}
  local allHeroId = Data.buildingData:GetBuildingHero()
  for i, heroId in pairs(allHeroId) do
    local sf_id = Logic.shipLogic:GetShipUniqueIdById(heroId)
    if sf_id then
      res[sf_id] = heroId
    end
  end
  self.m_buildHeroSfIds = res
end

function BuildingLogic:GetBuildingTypeName(btype)
  return UIHelper.GetString(BuildingTypeNameMap[btype + 1])
end

function BuildingLogic:GetBuildingBgm(btype)
  return BGM[btype]
end

function BuildingLogic:_HandleBuildingConfig()
  self.m_group2BuildInfo = {}
  local buildingCfg = configManager.GetData("config_buildinginfo")
  local groupLv2Tid = self.groupLv2Tid
  local typeLv2Tid = self.typeLv2Tid
  for tid, cfg in pairs(buildingCfg) do
    groupLv2Tid[cfg.group_id] = groupLv2Tid[cfg.group_id] or {}
    groupLv2Tid[cfg.group_id][cfg.level] = tid
    typeLv2Tid[cfg.type] = typeLv2Tid[cfg.type] or {}
    typeLv2Tid[cfg.type][cfg.level] = tid
  end
  local lvupCfg = configManager.GetData("config_buildinglevelup")
  local typeLv2LvupTid = self.typeLv2LvupTid
  for tid, cfg in pairs(lvupCfg) do
    typeLv2LvupTid[cfg.type] = typeLv2LvupTid[cfg.type] or {}
    typeLv2LvupTid[cfg.type][cfg.level] = tid
  end
  local recipeCfg = configManager.GetData("config_recipe")
  local recipeType2Tid = self.recipeType2Tid
  for tid, cfg in pairs(recipeCfg) do
    if not recipeType2Tid[cfg.type] then
      table.insert(self.recipeTypes, {
        rtype = cfg.type,
        typename = cfg.typename
      })
    end
    recipeType2Tid[cfg.type] = recipeType2Tid[cfg.type] or {}
    recipeType2Tid[cfg.type].type = cfg.type
    recipeType2Tid[cfg.type].name = cfg.typename
    recipeType2Tid[cfg.type].tids = recipeType2Tid[cfg.type].tids or {}
    table.insert(recipeType2Tid[cfg.type].tids, tid)
  end
  local plotCfg = configManager.GetData("config_building_character_story")
  for id, cfg in pairs(plotCfg) do
    self.shipFleetPlotMap[cfg.ship_fleet_id] = self.shipFleetPlotMap[cfg.ship_fleet_id] or {}
    table.insert(self.shipFleetPlotMap[cfg.ship_fleet_id], cfg)
  end
end

function BuildingLogic:GetHeroPlotCfgs(shipFleetId)
  return self.shipFleetPlotMap[shipFleetId]
end

function BuildingLogic:GetTidByTypeLevel(btype, level)
  return self.typeLv2Tid[btype][level]
end

function BuildingLogic:GetTidByGroupLevel(groupId, level)
  return self.groupLv2Tid[groupId][level]
end

function BuildingLogic:GetLvupTidByTypeLevel(btype, level)
  return self.typeLv2LvupTid[btype][level]
end

function BuildingLogic:GetMaxLevel(btype)
  return table.nums(self.typeLv2Tid[btype])
end

function BuildingLogic:GetRecipeTypes()
  return self.recipeTypes
end

function BuildingLogic:GetRecipeTypeCfg(type)
  return self.recipeType2Tid[type]
end

function BuildingLogic:GetRecipesByType(recipeType)
  local recipeType = self.recipeType2Tid[recipeType]
  local tids = recipeType.tids
  local cfgs = {}
  for i, tid in ipairs(tids) do
    local cfg = configManager.GetDataById("config_recipe", tid)
    table.insert(cfgs, cfg)
  end
  return cfgs
end

function BuildingLogic:GetBuildingRecipes()
  local itemFactory = {}
  for i = 1, #BuildingRecipes do
    local configName = "config_" .. BuildingRecipes[i]
    local tabRecipe = configManager.GetData(configName)
    local recipeMap = {}
    for i, value in ipairs(tabRecipe) do
      local typename = value.typename
      if value.hide == nil or value.hide and value.hide == 0 then
        recipeMap[typename] = recipeMap[typename] or {}
        table.insert(recipeMap[typename], value.id)
      end
    end
    local recipes = {}
    for typename, recipeIds in pairs(recipeMap) do
      table.insert(recipes, {typename = typename, recipeIds = recipeIds})
    end
    table.sort(recipes, function(l, r)
      local lcfg = configManager.GetDataById(configName, l.recipeIds[1])
      local rcfg = configManager.GetDataById(configName, r.recipeIds[1])
      local orders = configManager.GetDataById("config_parameter", 217).arrValue
      return orders[lcfg.type] < orders[rcfg.type]
    end)
    itemFactory[BuildingRecipes[i]] = recipes
  end
  return itemFactory
end

function BuildingLogic:GetStatusStr(status, buildingType, buildingData)
  local statusId = BuildingStatusStr[status]
  if buildingType ~= MBuildingType.DormRoom then
    return UIHelper.GetString(statusId)
  end
  if status == BuildingStatus.Working then
    return UIHelper.GetString(3200008)
  end
  if #buildingData.HeroList == 0 then
    return UIHelper.GetString(3200007)
  end
  return UIHelper.GetString(3200009)
end

function BuildingLogic:GetRecipeItemByType(type)
  return self.m_tag2Item[type] or {}
end

function BuildingLogic:GetBuildingEffects(type)
  return TypeEffectMap[type]
end

function BuildingLogic:GetBuilding3DAttrs(type, buildingData)
  local attrs = clone(Building3DAttrs[type])
  local heroEffects = {}
  for i, effectFunc in ipairs(attrs.HeroEffects) do
    if effectFunc == HeroEffect.ItemProduceSpeedAdd or effectFunc == HeroEffect.CoinProduceSpeedAdd then
      local key, valueStr, value = Logic.buildingLogic[effectFunc](Logic.buildingLogic, buildingData)
      if 0 < value then
        table.insert(heroEffects, effectFunc)
      end
    else
      table.insert(heroEffects, effectFunc)
    end
  end
  attrs.HeroEffects = heroEffects
  return attrs
end

function BuildingLogic:GetFoodCostStr(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local heroCount = #buildingData.HeroList
  local foodCost = heroCount * buildingCfg.foodcost
  return UIHelper.GetString(3000014), foodCost
end

function BuildingLogic:GetMoodCostStr(buildingData)
  local timeUnit = configManager.GetDataById("config_parameter", 207).value
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local drinkData = Data.buildingData:GetBuildingsByType(4)
  local rate = 1
  if drinkData and drinkData[1] then
    local drinkCfg = configManager.GetDataById("config_buildinginfo", drinkData[1].Tid)
    rate = 1 - drinkCfg.reducecost / 10000
  end
  local moodCost = buildingCfg.moodcost * BuildingBase.Float * rate
  moodCost = self:KeepFloat2(moodCost)
  return UIHelper.GetString(3000015), string.format("%s/%ds", moodCost, timeUnit)
end

function BuildingLogic:GetMoodProductivity(buildingData)
  local addition = self:GetTotalHeroAddition(buildingData.Tid, buildingData.HeroList)
  return addition
end

function BuildingLogic:GetProductivityStr(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local productivity = 0
  if buildingCfg.type == MBuildingType.ItemFactory then
    productivity = self:GetItemProductivity(buildingData)
  elseif buildingCfg.type == MBuildingType.DormRoom then
    productivity = self:GetMoodProductivity(buildingData)
  else
    productivity = 0 < buildingData.Productivity and buildingData.Productivity * BuildingBase.Float or 1
  end
  local btype = buildingCfg.type
  local productivityMsg = ""
  if btype == MBuildingType.ElectricFactory then
    productivityMsg = UIHelper.GetString(3000016)
  elseif btype == MBuildingType.FoodFactory then
    productivityMsg = UIHelper.GetString(3000021)
  elseif btype == MBuildingType.DormRoom then
    productivityMsg = UIHelper.GetString(3000047)
  else
    productivityMsg = UIHelper.GetString(3000032)
  end
  local value = productivity * 100
  value = self:KeepFloat2(value)
  return productivityMsg, string.format("%s%%", value)
end

function BuildingLogic:GetCharacterStr(buildingData)
  local recipeId = buildingData.RecipeId
  local recipeType = 0
  if 0 < recipeId then
    local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
    recipeType = recipeCfg.type
  end
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local characters = buildingCfg.showcharacters
  local characterStr = ""
  for i, cid in ipairs(characters) do
    local characterCfg = configManager.GetDataById("config_character", cid)
    if recipeType == 0 or 0 < recipeType and characterCfg.recipeaddition[recipeType] and 0 < characterCfg.recipeaddition[recipeType] then
      characterStr = characterStr .. characterCfg.name .. " "
    end
  end
  characterStr = string.sub(characterStr, 1, -2)
  return UIHelper.GetString(3001003), characterStr
end

function BuildingLogic:GetMoodCostRateStr(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local moodReduceRate = buildingCfg.reducecost / 100
  local msg = string.format("%d", moodReduceRate) .. "%"
  return UIHelper.GetString(3000056), msg
end

function BuildingLogic:GetProduceSpeedStr(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local btype = buildingCfg.type
  local speed = buildingData.ProduceSpeed * BuildingBase.Float
  local timeUnit = configManager.GetDataById("config_parameter", 210).value
  local produceSpeedMsg = ""
  if btype == MBuildingType.OilFactory then
    produceSpeedMsg = UIHelper.GetString(3000033)
    speed = string.format("%d/%ds", math.floor(speed), timeUnit)
  elseif btype == MBuildingType.ResourceFactory then
    produceSpeedMsg = UIHelper.GetString(3000027)
    speed = string.format("%d/%ds", math.floor(speed), timeUnit)
  elseif btype == MBuildingType.DormRoom then
    produceSpeedMsg = UIHelper.GetString(3000047)
    speed = self:KeepFloat2(speed)
  end
  return produceSpeedMsg, speed
end

function BuildingLogic:GetMaxAddStr(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  if buildingCfg.productid[2] == CurrencyType.FOOD then
    local maxAdd = self:GetMaxFoodByHero(buildingData.Tid, buildingData.HeroList)
    return UIHelper.GetString(3000022), string.format("%d", math.ceil(maxAdd))
  elseif buildingCfg.productid[2] == CurrencyType.ELECTRIC then
    return UIHelper.GetString(3000018), string.format("%d", buildingCfg.productmax)
  end
  return "", ""
end

function BuildingLogic:GetProductCountStr(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local curCount = self:Produce(buildingData)
  return UIHelper.GetString(3000028), string.format("%d/%d", curCount, buildingCfg.productmax)
end

function BuildingLogic:GetElectricCostStr(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  return UIHelper.GetString(3000023), buildingCfg.powercost
end

function BuildingLogic:GetWorkerRecoverStr(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  if buildingCfg.type == MBuildingType.ElectricFactory then
    local timeUnit = configManager.GetDataById("config_parameter", 205).value
    local speed = buildingData.ProduceSpeed * BuildingBase.Float
    speed = self:KeepFloat2(speed)
    return UIHelper.GetString(3000017), string.format("%s/%ds", speed, timeUnit)
  end
  return "", ""
end

function BuildingLogic:GetMoodRecoverStr(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  if buildingCfg.type == MBuildingType.DormRoom then
    local timeUnit = configManager.GetDataById("config_parameter", 207).value
    local speed = self:GetMoodRecoverSpeed(buildingData)
    speed = speed * BuildingBase.Float
    speed = self:KeepFloat2(speed)
    return UIHelper.GetString(3000048), string.format("%s/%ds", speed, timeUnit)
  end
  return "", ""
end

function BuildingLogic:GetMoodRecoverSpeed(buildingData)
  local addition = self:GetTotalHeroAddition(buildingData.Tid, buildingData.HeroList)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local speed = math.floor(buildingCfg.addmood * addition)
  return speed
end

function BuildingLogic:GetItemProduceSpeedAddStr()
  local office = Data.buildingData:GetOffice()
  local addition = office.Productivity * BuildingBase.Float - 1
  addition = addition * 100
  addition = self:KeepFloat2(addition)
  return UIHelper.GetString(3000052), string.format("%s%%", addition), tonumber(addition)
end

function BuildingLogic:GetCoinProduceSpeedAddStr()
  local office = Data.buildingData:GetOffice()
  local addition = office.Productivity * BuildingBase.Float - 1
  addition = addition * 100
  addition = self:KeepFloat2(addition)
  return UIHelper.GetString(3000053), string.format("%s%%", addition), tonumber(addition)
end

function BuildingLogic:GetMaxStrengthAddStr()
  local office = Data.buildingData:GetOffice()
  local workerCfg = configManager.GetDataById("config_worker", 1)
  local addition = 0
  if 1 <= office.Level then
    for i = 1, office.Level do
      addition = addition + workerCfg.workerhplevelup[i]
    end
  end
  return UIHelper.GetString(3000055), string.format("+%d", addition)
end

function BuildingLogic:KeepFloat(nNum, n)
  if type(nNum) ~= "number" then
    return nNum
  end
  n = n or 0
  n = math.floor(n)
  if n < 0 then
    n = 0
  end
  if n == 0 then
    return math.floor(nNum)
  end
  local nDecimal = 10 ^ n
  local nTemp = math.modf(nNum * nDecimal)
  local nRet = nTemp / nDecimal
  return nRet
end

function BuildingLogic:KeepFloat1(value)
  if value - math.floor(value) >= 0.09999999 then
    return string.format("%s", self:KeepFloat(value, 1))
  end
  return string.format("%s", self:KeepFloat(value, 0))
end

function BuildingLogic:KeepFloat2(value)
  local temp = value * 10
  if temp - math.floor(temp) >= 0.09999999 then
    return string.format("%s", self:KeepFloat(value, 2))
  end
  return self:KeepFloat1(value)
end

function BuildingLogic:GetLevelEffectStr(tid, newTid, propertyName)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", tid)
  local buildingCfgNew = configManager.GetDataById("config_buildinginfo", newTid)
  local curValue = buildingCfg[propertyName]
  local newValue = buildingCfgNew[propertyName]
  if propertyName == LevelEffect.ProduceSpeed then
    curValue = curValue * BuildingBase.Float
    newValue = newValue * BuildingBase.Float
  end
  local productId = buildingCfg.productid[2]
  local keyNameNum = LevelEffectKey[propertyName]
  local keyName = UIHelper.GetString(keyNameNum)
  return keyName, curValue, newValue
end

function BuildingLogic:GetUpgradeCountDown(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local toLevel = 0
  if buildingData.Status == BuildingStatus.Adding then
    toLevel = 1
  elseif buildingData.Status == BuildingStatus.Upgrading then
    toLevel = buildingData.Level + 1
  end
  local lvupTid = Logic.buildingLogic:GetLvupTidByTypeLevel(buildingCfg.type, toLevel)
  local lvupCfg = configManager.GetDataById("config_buildinglevelup", lvupTid)
  local buildingCd = lvupCfg.leveluptime
  if 0 < buildingCd then
    buildingCd = buildingCd + 1
  end
  local nowTime = time.getSvrTime()
  local delta = buildingData.LastBuildUpdateTime + buildingCd - nowTime
  return delta
end

function BuildingLogic:GetEffectDuration(effectTime, startTime, endTime)
  if startTime < effectTime[1] then
    startTime = effectTime[1]
  end
  if effectTime == -1 then
    return endTime - startTime
  end
  if endTime > effectTime[2] then
    endTime = effectTime[2]
  end
  return endTime - startTime
end

function BuildingLogic:Produce(buildingData)
  local timeUnit = BuildingTimeUnit
  local buildingRec = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  if buildingRec.type ~= MBuildingType.OilFactory and buildingRec.type ~= MBuildingType.ResourceFactory then
    return 0
  end
  if buildingData.Status ~= BuildingStatus.Working then
    return buildingData.ProductCount
  end
  local productMax = buildingRec.productmax
  local productId = buildingRec.productid[2]
  local ratio = 1
  if productId == CurrencyType.SUPPLY then
    ratio = timeUnit / configManager.GetDataById("config_parameter", 209).value
  elseif productId == CurrencyType.GOLD then
    ratio = timeUnit / configManager.GetDataById("config_parameter", 210).value
  end
  self.checkoutResourceTime = self.checkoutResourceTime or buildingData.LastUpdateTime
  local nowTime = time.getSvrTime()
  local delta = nowTime - buildingData.LastUpdateTime - 1
  local totalCount = 0
  local checkoutDelta = nowTime - self.checkoutResourceTime
  if timeUnit <= delta then
    self.checkoutResourceTime = nowTime
    local baseSpeed = buildingRec.productivity * BuildingBase.Float * ratio
    totalCount = delta / timeUnit * baseSpeed
    for heroId, effectTime in pairs(buildingData.HeroEffectTime) do
      local duration = self:GetEffectDuration(effectTime, buildingData.LastUpdateTime, buildingData.LastUpdateTime + delta)
      if 0 < duration then
        local heroAddition = self:GetSingleHeroAddition(buildingData.Tid, heroId)
        local extraSpeed = baseSpeed * (heroAddition - 1)
        local extraCount = duration / timeUnit * extraSpeed
        totalCount = totalCount + extraCount
      end
    end
    if productId == CurrencyType.GOLD then
      local office = Data.buildingData:GetOffice()
      for heroId, effectTime in pairs(office.HeroEffectTime) do
        local duration = self:GetEffectDuration(effectTime, office.LastUpdateTime, office.LastUpdateTime + delta)
        if 0 < duration then
          local heroAddition = self:GetSingleHeroAddition(office.Tid, heroId)
          local extraSpeed = baseSpeed * (heroAddition - 1)
          local extraCount = duration / timeUnit * extraSpeed
          totalCount = totalCount + extraCount
        end
      end
    end
  end
  local count = buildingData.ProductCount + math.floor(totalCount)
  if productMax <= count then
    count = productMax
    buildingData.Status = BuildingStatus.Idle
    buildingData.ProductCount = count
    buildingData.LastUpdateTime = nowTime
  end
  return count
end

function BuildingLogic:PrintTime(name, timeseconds)
  logError("=========" .. name .. "=======" .. printTable(time.formatTimeToYMDHMS(timeseconds)))
end

function BuildingLogic:GetProduceItemTime(buildingData, recipeId, count)
  local productivity = buildingData.ProduceSpeed * BuildingBase.Float
  local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
  local addition = self:GetTotalRecipeAddition(buildingData.Tid, buildingData.HeroList, recipeId)
  local costTime = recipeCfg.time / addition
  return math.floor(costTime * count)
end

function BuildingLogic:ProduceItem(buildingData)
  buildingData = Data.buildingData:GetBuildingById(buildingData.Id)
  if buildingData.RecipeId == 0 then
    return 0, 0, 0
  end
  if buildingData.Status ~= BuildingStatus.Working and 0 < buildingData.ItemCount then
    return 0, buildingData.ProductCount, buildingData.ItemCount
  end
  local timeReduce = self:GetTotalRecipeAddition(buildingData.Tid, buildingData.HeroList, buildingData.RecipeId)
  local recipeCfg = configManager.GetDataById("config_recipe", buildingData.RecipeId)
  local oneTime = recipeCfg.time / timeReduce
  local nowTime = time.getSvrTime()
  local delta = nowTime - buildingData.LastUpdateTime
  local floatCount = buildingData.FloatCount * BuildingBase.Float
  local totalTime = (buildingData.ItemCount - floatCount) * oneTime
  local totalCount = floatCount
  if 0 < delta then
    totalCount = totalCount + delta / recipeCfg.time
    for heroId, effectTime in pairs(buildingData.HeroEffectTime) do
      local duration = self:GetEffectDuration(effectTime, buildingData.LastUpdateTime, buildingData.LastUpdateTime + delta)
      if 0 < duration then
        local addition = self:GetSingleRecipeAddition(buildingData.Tid, heroId, buildingData.RecipeId)
        local extraCount = (addition - 1) * duration / recipeCfg.time
        totalCount = totalCount + extraCount
      end
    end
    local officeData = Data.buildingData:GetOffice()
    for heroId, effectTime in pairs(officeData.HeroEffectTime) do
      local duration = self:GetEffectDuration(effectTime, officeData.LastUpdateTime, officeData.LastUpdateTime + delta)
      if 0 < duration then
        local addition = self:GetSingleHeroAddition(officeData.Tid, heroId)
        local extraCount = (addition - 1) * duration / recipeCfg.time
        totalCount = totalCount + extraCount
      end
    end
  end
  local remainTime = math.floor(buildingData.LastUpdateTime + totalTime - nowTime)
  local count = math.floor(totalCount)
  local remainCount = 0
  local realRemainCount = 0
  if count >= buildingData.ItemCount or remainTime <= 0 then
    buildingData.Status = BuildingStatus.Idle
    buildingData.LastUpdateTime = nowTime
    buildingData.ProductCount = buildingData.ProductCount + buildingData.ItemCount
    count = buildingData.ProductCount
    buildingData.ItemCount = 0
    remainTime = 0
  else
    remainCount = buildingData.ItemCount - count
    count = buildingData.ProductCount + count
    realRemainCount = buildingData.ItemCount - totalCount
  end
  return remainTime, count, remainCount, realRemainCount
end

function BuildingLogic:ProduceNow(buildingData, delta)
  buildingData = Data.buildingData:GetBuildingById(buildingData.Id)
  if buildingData.RecipeId == 0 then
    return 0, 0, 0
  end
  if buildingData.Status ~= BuildingStatus.Working and 0 < buildingData.ItemCount then
    return 0, buildingData.ProductCount, buildingData.ItemCount
  end
  local recipeCfg = configManager.GetDataById("config_recipe", buildingData.RecipeId)
  local nowTime = time.getSvrTime()
  local totalCount = 0
  if 0 < delta then
    totalCount = totalCount + delta / recipeCfg.time
    for heroId, effectTime in pairs(buildingData.HeroEffectTime) do
      if nowTime >= effectTime[1] and nowTime <= effectTime[2] then
        local duration = delta
        if 0 < duration then
          local addition = self:GetSingleRecipeAddition(buildingData.Tid, heroId, buildingData.RecipeId)
          local extraCount = (addition - 1) * duration / recipeCfg.time
          totalCount = totalCount + extraCount
        end
      end
    end
    local officeData = Data.buildingData:GetOffice()
    for heroId, effectTime in pairs(officeData.HeroEffectTime) do
      if nowTime >= effectTime[1] and nowTime <= effectTime[2] then
        local duration = delta
        if 0 < duration then
          local addition = self:GetSingleHeroAddition(officeData.Tid, heroId)
          local extraCount = (addition - 1) * duration / recipeCfg.time
          totalCount = totalCount + extraCount
        end
      end
    end
  end
  return totalCount
end

function BuildingLogic:GetCurStrengthReal()
  local curStrength = Data.buildingData:GetWorkerStrength()
  local maxStrength = Data.buildingData:GetMaxWorkerStrength()
  local maxIntBase = maxStrength * BuildingBase.Int
  if curStrength >= maxIntBase then
    return curStrength
  end
  local lastUpdateTime = Data.buildingData:GetWorkerUpdateTime()
  local nowTime = time.getSvrTime()
  local delta = nowTime - lastUpdateTime
  local unitTime = BuildingTimeUnit
  local ratio = unitTime / configManager.GetDataById("config_parameter", 205).value
  if delta <= 0 then
    return curStrength
  end
  local workerCfg = configManager.GetDataById("config_worker", 1)
  local baseSpeed = workerCfg.addworkerhp * ratio
  local totalCount = delta / unitTime * baseSpeed
  local buildingDatas = Data.buildingData:GetBuildingData()
  for k, data in pairs(buildingDatas) do
    local buildingCfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    if buildingCfg.type == MBuildingType.ElectricFactory then
      local buildingSpeed = buildingCfg.addworkerhp
      totalCount = totalCount + delta / unitTime * buildingSpeed
      for heroId, effectTime in pairs(data.HeroEffectTime) do
        local duration = self:GetEffectDuration(effectTime, lastUpdateTime, lastUpdateTime + delta)
        if 0 < duration then
          local addition = self:GetSingleHeroAddition(data.Tid, heroId)
          local extraSpeed = buildingSpeed * (addition - 1)
          local extraCount = duration / unitTime * extraSpeed
          totalCount = totalCount + extraCount
        end
      end
    end
  end
  local points = math.floor(totalCount)
  if maxIntBase < curStrength + points then
    curStrength = maxIntBase
  else
    curStrength = curStrength + points
  end
  return curStrength
end

function BuildingLogic:RecoverStrength()
  local curStrength = self:GetCurStrengthReal()
  local maxStrength = Data.buildingData:GetMaxWorkerStrength()
  local maxIntBase = maxStrength * BuildingBase.Int
  if curStrength >= maxIntBase then
    return math.floor(curStrength * BuildingBase.Float), maxStrength, 1
  end
  local ratio = curStrength / maxIntBase
  curStrength = math.floor(curStrength * BuildingBase.Float)
  return curStrength, maxStrength, ratio
end

function BuildingLogic:CheckoutHeroMoodChange(heroId)
  local buildingData = Data.buildingData:GetHeroBuilding(heroId)
  local buildingType = Data.buildingData:GetHeroBuildingType(heroId)
  if buildingType then
    local heroList = buildingData.HeroList
    for i, hid in ipairs(heroList) do
      if hid == heroId then
        local now = time.getSvrTime()
        if buildingType == MBuildingType.DormRoom then
          do
            local delta = now - buildingData.LastUpdateTime
            local timeUnit = BuildingTimeUnit
            local ratio = timeUnit / configManager.GetDataById("config_parameter", 206).value
            local addSpeed = buildingData.ProduceSpeed * ratio
            local addCount = delta / timeUnit * addSpeed
            return addCount
          end
          break
        end
        do
          local lastTime = 0
          if buildingType == MBuildingType.ElectricFactory then
            lastTime = Data.buildingData:GetWorkerUpdateTime()
          else
            lastTime = buildingData.LastUpdateTime
          end
          local delta = now - lastTime
          local bcfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
          local timeUnit = BuildingTimeUnit
          local ratio = timeUnit / configManager.GetDataById("config_parameter", 207).value
          local costSpeed = bcfg.moodcost * ratio
          local subCount = delta / timeUnit * costSpeed
          return -subCount
        end
        break
      end
    end
  end
  return 0
end

function BuildingLogic:UpdateBuildings(force)
  local now = time.getSvrTime()
  local lastTime = self.lastCheckTime or 0
  if now - lastTime < 60 and not force then
    return
  end
  self.lastCheckTime = now
  local buildingIdList = {}
  local buildingDatas = Data.buildingData:GetBuildingData()
  for bId, bData in pairs(buildingDatas) do
    table.insert(buildingIdList, bId)
  end
  if 0 < #buildingIdList then
    Service.buildingService:UpdateHeroAddition(buildingIdList)
  end
end

function BuildingLogic:ResetUpdateTime()
  local now = time.getSvrTime()
  self.lastCheckTime = now
end

function BuildingLogic:GetCharacterAdditionStr(characterId, level)
  local descStrIds = {}
  local characterCfg = configManager.GetDataById("config_character", characterId)
  if #characterCfg.characteraddition > 0 then
    local bases = characterCfg.characteraddition
    local levelups = characterCfg.levelupaddition
    for i, addition in ipairs(characterCfg.characteraddition) do
      if 0 < addition then
        local num = (level - 1) * levelups[i] + bases[i]
        num = num * 0.01
        num = self:KeepFloat2(num)
        table.insert(descStrIds, {
          strId = CharacterBuildingAddtionStrMap[i],
          value = num
        })
      end
    end
  else
    local addAll = 0 < #characterCfg.recipeaddition
    for i, v in ipairs(characterCfg.recipeaddition) do
      if v == 0 then
        addAll = false
        break
      end
    end
    if not addAll then
      for i, addition in ipairs(characterCfg.recipeaddition) do
        local bases = characterCfg.recipeaddition
        local levelups = characterCfg.leveluprecipeaddition
        if 0 < addition then
          local num = (level - 1) * levelups[i] + bases[i]
          num = num * 0.01
          num = self:KeepFloat2(num)
          table.insert(descStrIds, {
            strId = CharacterItemAddtionStrMap[i],
            value = num
          })
        end
      end
    else
      local bases = characterCfg.recipeaddition
      local levelups = characterCfg.leveluprecipeaddition
      local num = (level - 1) * levelups[1] + bases[1]
      num = num * 0.01
      num = self:KeepFloat2(num)
      table.insert(descStrIds, {
        strId = CharacterItemAddtionStrMap[#CharacterItemAddtionStrMap],
        value = num
      })
    end
  end
  return descStrIds
end

function BuildingLogic:IsProduceBuilding(tid)
  local cfg = configManager.GetDataById("config_buildinginfo", tid)
  local productId = cfg.productid[2]
  if productId == CurrencyType.GOLD or productId == CurrencyType.SUPPLY then
    return true
  end
  return false
end

function BuildingLogic:CheckResourceLimit(currencyId)
  local curCount = Data.userData:GetCurrency(currencyId)
  local maxCount = Data.userData:GetCurrencyMax(currencyId)
  if curCount < maxCount then
    return true, nil
  end
  return false, UIHelper.GetString(3002043)
end

function BuildingLogic:CheckReceiveResource(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  if buildingCfg.type == MBuildingType.OilFactory or buildingCfg.type == MBuildingType.ResourceFactory then
    return self:CheckResourceLimit(buildingCfg.productid[2])
  end
  return false, UIHelper.GetString(3002044)
end

function BuildingLogic:CheckLandUnlock(landIndex)
  local landCfg = configManager.GetDataById("config_building", landIndex)
  local level = landCfg.officelevel
  local officeData = Data.buildingData:GetOffice()
  if level > officeData.Level then
    return false, string.format(UIHelper.GetString(3002023), level)
  end
  return true, nil
end

function BuildingLogic:CheckUpgradeLevel(buildingData)
  local status = buildingData.Status
  if status == BuildingStatus.Upgrading then
    return 0, UIHelper.GetString(3002045)
  end
  local cfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local curLevel = buildingData.Level
  local maxLevel = Logic.buildingLogic:GetMaxLevel(cfg.type)
  local targetLevel = curLevel
  if curLevel >= maxLevel then
    return 0, UIHelper.GetString(3002047)
  end
  return curLevel + 1, nil
end

function BuildingLogic:CheckUpgradeCost(buildingTid, level)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local newTid = self:GetTidByTypeLevel(buildingCfg.type, level)
  local newBuildingCfg = configManager.GetDataById("config_buildinginfo", newTid)
  local levelupTid = self:GetLvupTidByTypeLevel(buildingCfg.type, level)
  local levelupCfg = configManager.GetDataById("config_buildinglevelup", levelupTid)
  local curStrength = self:GetCurStrengthReal()
  local costStrength = levelupCfg.costwork * BuildingBase.Int
  local curElectric = Data.buildingData:GetCurElectric()
  local maxElectric = Data.buildingData:GetElectricMax()
  local officeData = Data.buildingData:GetOffice()
  if buildingCfg.type ~= MBuildingType.Office and level > officeData.Level then
    return UIHelper.GetString(3002048)
  end
  if curStrength < costStrength then
    return UIHelper.GetString(3002049)
  end
  if level == 1 then
    if buildingCfg.type ~= MBuildingType.ElectricFactory and maxElectric < curElectric + buildingCfg.powercost then
      return UIHelper.GetString(3002025)
    end
  elseif buildingCfg.type ~= MBuildingType.ElectricFactory and maxElectric < curElectric + newBuildingCfg.powercost - buildingCfg.powercost then
    return UIHelper.GetString(3002025)
  end
  local curGold = Data.userData:GetCurrency(CurrencyType.GOLD)
  if curGold < levelupCfg.costmoney then
    return UIHelper.GetString(3002050)
  end
  for i = 1, 3 do
    local item = levelupCfg["rawmaterial" .. i]
    if 0 < #item then
      local curMat = Data.bagData:GetItemNum(item[2])
      if curMat < item[3] then
        local itemCfg = Logic.bagLogic:GetConfig(item[1], item[2])
        return itemCfg.name .. UIHelper.GetString(3002051)
      end
    end
  end
  return nil
end

function BuildingLogic:CheckProduceItemCost(recipeId, count, configName)
  if not recipeId or recipeId == 0 then
    return UIHelper.GetString(3002052)
  end
  local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
  if configName then
    recipeCfg = configManager.GetDataById(configName, recipeId)
  end
  for i = 1, 3 do
    local item = recipeCfg["rawmaterial" .. i]
    if 0 < #item then
      local curMat = Logic.bagLogic:GetConsumeCurrNum(item[1], item[2])
      if curMat < item[3] * count then
        local itemCfg = Logic.bagLogic:GetConfig(item[1], item[2])
        return itemCfg.name .. UIHelper.GetString(3002051)
      end
    end
  end
  return nil
end

function BuildingLogic:CheckDegradeLevel(buildingData)
  local status = buildingData.Status
  if status == BuildingStatus.Upgrading then
    return 0, UIHelper.GetString(3002054)
  end
  local cfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  if cfg.type == MBuildingType.ItemFactory and status == BuildingStatus.Working then
    return 0, UIHelper.GetString(3002055)
  end
  local curLevel = buildingData.Level
  if curLevel <= 1 then
    return 0, UIHelper.GetString(3002056)
  end
  return curLevel - 1, nil
end

function BuildingLogic:CheckDegradeCost(buildingTid, level)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local newTid = self:GetTidByTypeLevel(buildingCfg.type, level)
  local newBuildingCfg = configManager.GetDataById("config_buildinginfo", newTid)
  local levelupTid = Logic.buildingLogic:GetLvupTidByTypeLevel(buildingCfg.type, level)
  local levelupCfg = configManager.GetDataById("config_buildinglevelup", levelupTid)
  local curStrength = Data.buildingData:GetWorkerStrength()
  local costStrength = levelupCfg.costwork
  local curElectric = Data.buildingData:GetCurElectric()
  local maxElectric = Data.buildingData:GetElectricMax()
  curElectric = curElectric - buildingCfg.powercost + newBuildingCfg.powercost
  if buildingCfg.type == MBuildingType.ElectricFactory or buildingCfg.type == MBuildingType.Office then
    maxElectric = maxElectric - buildingCfg.productmax + newBuildingCfg.productmax
  end
  if curElectric > maxElectric then
    return UIHelper.GetString(3002028)
  end
  return nil
end

function BuildingLogic:ShowBuildingFinish(buildingId)
  local buildingData = Data.buildingData:GetBuildingById(buildingId)
  if buildingData.Status == BuildingStatus.Adding or buildingData.Status == BuildingStatus.Upgrading then
    return
  end
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local isAdding = buildingData.Level == 1
  local content = ""
  if isAdding then
    content = string.format(UIHelper.GetString(3002063), buildingCfg.name)
  else
    content = string.format(UIHelper.GetString(3002064), buildingCfg.name)
  end
  UIHelper.OpenPage("BuildingOpenPage", {
    Type = RewardType.TEXT,
    open_show_name = content,
    isAdding = isAdding
  })
end

function BuildingLogic:GetBuild3DScaleThreshold()
  return 0.1
end

function BuildingLogic:GetOneBuildingHeroMax(tid)
  return configManager.GetDataById("config_buildinginfo", tid).heronumber
end

function BuildingLogic:GetBuldingCostItem(type, lv)
  local id = self:GetLvupTidByTypeLevel(type, lv)
  local config = configManager.GetDataById("config_buildinglevelup", id)
  local res = {}
  
  local function filer(args)
    return {
      Type = args[1],
      ConfigId = args[2],
      Num = args[3]
    }
  end
  
  if config.costwork > 0 then
    table.insert(res, filer({
      GoodsType.CURRENCY,
      CurrencyType.STRENGTH,
      config.costwork
    }))
  end
  if config.rawmaterial1 and 0 < #config.rawmaterial1 then
    table.insert(res, filer(config.rawmaterial1))
  end
  if config.rawmaterial2 and 0 < #config.rawmaterial2 then
    table.insert(res, filer(config.rawmaterial2))
  end
  if config.rawmaterial3 and 0 < #config.rawmaterial3 then
    table.insert(res, filer(config.rawmaterial3))
  end
  return res
end

function BuildingLogic:SlotIndex2Id(index)
  return index
end

function BuildingLogic:GetCurBuildingsInfo()
  local res = {}
  local data = Data.buildingData:GetBuildingData()
  for id, info in pairs(data) do
    local cfg = configManager.GetDataById("config_buildinginfo", info.Tid)
    info.order = cfg.order
    table.insert(res, info)
  end
  table.sort(res, function(l, r)
    return l.order < r.order
  end)
  return res
end

function BuildingLogic:AutoRmdHero(orginHero, buildId)
  local data = Data.buildingData:GetBuildingById(buildId)
  if data == nil then
    logError("\229\143\150\228\184\141\229\136\176\230\149\176\230\141\174\228\186\134,Id:" .. buildId)
    return {}
  end
  local max = Logic.buildingLogic:GetOneBuildingHeroMax(data.Tid)
  local num = max - #data.HeroList
  if num <= 0 then
    return {}
  end
  local heros = self:_removeLockHero(orginHero)
  if #heros <= 0 then
    return {}
  end
  return self:_getMatchHero(heros, buildId, num)
end

function BuildingLogic:_removeLockHero(orginHero)
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  local cachBathFids = self:GetHeroUniqueTids(bathHero)
  local cachBuildingFids = self:GetBuildingHeroSfIds()
  local res = {}
  for index, info in ipairs(orginHero) do
    local curUniqueId = Logic.shipLogic:GetShipUniqueIdById(info.HeroId)
    local bInBath = cachBathFids[curUniqueId]
    local bInBuilding = cachBuildingFids[curUniqueId]
    if not bInBath and not bInBuilding then
      res[#res + 1] = info
    end
  end
  return res
end

function BuildingLogic:IsBuildingHero(heroId)
  local cachBuildingFids = self:GetBuildingHeroSfIds()
  local si_id, sf_id
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    si_id = Logic.shipLogic:GetShipInfoIdByTid(heroData.TemplateId)
    sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    return cachBuildingFids[sf_id] ~= nil
  else
    return false
  end
end

function BuildingLogic:IsBuildingSameCharacterHero(heroId)
  local cachBuildingFids = self:GetBuildingHeroSfIds()
  local si_id, sf_id
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    si_id = Logic.shipLogic:GetShipInfoIdByTid(heroData.TemplateId)
    sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    for cachesf_id, _ in pairs(cachBuildingFids) do
      local isSameShip = Logic.shipLogic:CheckSameShipCharacterBySfid(sf_id, cachesf_id)
      if isSameShip then
        return true, sf_id, cachesf_id
      end
    end
    return false, 0, 0
  else
    return false, 0, 0
  end
end

function BuildingLogic:IsBathHero(heroId)
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  local cachBathFids = self:GetHeroUniqueTids(bathHero)
  local si_id, sf_id
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    si_id = Logic.shipLogic:GetShipInfoIdByTid(heroData.TemplateId)
    sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    return cachBathFids[sf_id] ~= nil
  else
    return false
  end
end

function BuildingLogic:GetBuildingHeroSfIds()
  if next(self.m_buildHeroSfIds) == nil then
    local res = {}
    local allHeroId = Data.buildingData:GetBuildingHero()
    for i, heroId in pairs(allHeroId) do
      local sf_id = Logic.shipLogic:GetShipUniqueIdById(heroId)
      if sf_id then
        res[sf_id] = heroId
      end
    end
    self.m_buildHeroSfIds = res
  end
  return self.m_buildHeroSfIds
end

function BuildingLogic:GetHeroUniqueTids(herolist)
  local res = {}
  local data, tid, si_id
  for k, heroId in pairs(herolist) do
    local sf_id = Logic.shipLogic:GetShipUniqueIdById(heroId)
    if sf_id then
      res[sf_id] = heroId
    end
  end
  return res
end

function BuildingLogic:_getMatchHero(heros, buildId, num)
  local data = Data.buildingData:GetBuildingById(buildId)
  if data == nil then
    logError("\229\143\150\228\184\141\229\136\176\230\149\176\230\141\174\228\186\134,Id:" .. buildId)
    return {}
  end
  local targetChar = self:_getRmdCharacter(data.Tid)
  local char = 0
  local res, temp = {}, {}
  for _, hero in pairs(heros) do
    chars = Logic.shipLogic:GetHeroCharcater(hero.TemplateId)
    for _, char in pairs(chars) do
      if table.containV(targetChar, char) then
        table.insert(temp, hero)
      end
    end
  end
  local buildType = Logic.buildingLogic:GetBuildType(data.Tid)
  temp = HeroSortHelper.BuildingSortHero(temp, buildType)
  for _, hero in pairs(temp) do
    table.insert(res, hero.HeroId)
    if #res == num then
      return res
    end
  end
  return res
end

function BuildingLogic:_getRmdCharacter(buildTid)
  return configManager.GetDataById("config_buildinginfo", buildTid).characters
end

function BuildingLogic:Is3DBuild(tid)
  return self.buildingMode == BuildingMode._3D
end

function BuildingLogic:GetBuildListByIndex(index)
  local res = {}
  local officeData = Data.buildingData:GetOffice()
  local officeCfg = configManager.GetDataById("config_buildinginfo", officeData.Tid)
  local landCfg = configManager.GetDataById("config_building", index)
  local buildable = {}
  for i, btype in ipairs(landCfg.buildinggroup_id) do
    buildable[btype] = true
  end
  local buildingTypes = configManager.GetDataById("config_parameter", 218).arrValue
  for order, btype in ipairs(buildingTypes) do
    local tid = self.typeLv2Tid[btype][BuildInitLv]
    if 0 < tid then
      local buildingCfg = configManager.GetDataById("config_buildinginfo", tid)
      local buildingTypeCfg = configManager.GetDataById("config_buildingtype", buildingCfg.type)
      local curCount = Data.buildingData:GetBuildingCountByType(buildingCfg.type)
      local maxCount = officeCfg.buildquantity[buildingCfg.type - 1]
      local canBuild = buildable[buildingCfg.type]
      local available = curCount < maxCount and 1 or 0
      table.insert(res, {
        tid = tid,
        available = available,
        curCount = curCount,
        maxCount = maxCount,
        order = order,
        canBuild = canBuild
      })
    end
  end
  table.sort(res, function(l, r)
    if l.available == r.available then
      return l.order < r.order
    end
    return l.available > r.available
  end)
  return res
end

function BuildingLogic:GetWorkerStreProgress()
  local cur = Data.buildingData:GetWorkerStrength()
  local max = Data.buildingData:GetMaxWorkerStrength()
  return cur, max, Mathf.Clamp01(cur / max)
end

function BuildingLogic:GetBuildInfoProgress()
  local cur = Data.buildingData:GetCurBuildingCount() + 1
  local buildingData = configManager.GetData("config_buildingtype")
  local max = 0
  for k, v in pairs(buildingData) do
    max = max + v.buildnumber
  end
  return cur, max, Mathf.Clamp01(cur / max)
end

function BuildingLogic:GetBuildHeroProgress()
  local cur, max = Data.buildingData:GetBuildingHeroCount()
  return cur, max, Mathf.Clamp01(cur / max)
end

function BuildingLogic:GetBuildElectricProgress()
  local cur = Data.buildingData:GetCurElectric()
  local max = Data.buildingData:GetElectricMax()
  local available = max - cur
  return available, max, Mathf.Clamp01(available / max)
end

function BuildingLogic:GetBuildFoodProgress()
  local cur = Data.buildingData:GetCurFood()
  local buildingDatas = Data.buildingData:GetBuildingData()
  local max = 0
  for bId, bData in pairs(buildingDatas) do
    local maxAdd = self:GetMaxFoodByHero(bData.Tid, bData.HeroList)
    max = max + maxAdd
  end
  local available = max - cur
  return available, max, Mathf.Clamp01(available / max)
end

function BuildingLogic:GetResourceCount(resourceId)
  local count = 0
  local idling = true
  local buildingDatas = Data.buildingData:GetBuildingData()
  for k, data in pairs(buildingDatas) do
    if data.Status == BuildingStatus.Working then
      idling = false
    end
    local cfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    if cfg.productid[2] == resourceId then
      count = count + self:Produce(data)
    end
  end
  return count, idling
end

function BuildingLogic:GetMakeOil(id)
  local num = self:_getItemNum(id)
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.SUPPLY,
    Num = num
  }
end

function BuildingLogic:GetMakeResource(id)
  local num = self:_getItemNum(id)
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.GOLD,
    Num = num
  }
end

function BuildingLogic:GetMakeElectric(id)
  local num = self:_getItemNum(id)
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.ELECTRIC,
    Num = num
  }
end

function BuildingLogic:GetMakeFood(id)
  local num = self:_getItemNum(id)
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.FOOD,
    Num = num
  }
end

function BuildingLogic:_getItemNum(id)
  local data = Data.buildingData:GetBuildingById(id)
  local num = 0
  if data ~= nil then
    num = self:Produce(data)
  end
  return num
end

function BuildingLogic:GetMaxMakeOil(tid)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", tid)
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.SUPPLY,
    Num = buildingCfg.productmax
  }
end

function BuildingLogic:GetMaxMakeResource(tid)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", tid)
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.GOLD,
    Num = buildingCfg.productmax
  }
end

function BuildingLogic:GetMaxMakeElectric(tid)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", tid)
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.ELECTRIC,
    Num = buildingCfg.productmax
  }
end

function BuildingLogic:GetMaxMakeFood(tid)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", tid)
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.FOOG,
    Num = buildingCfg.productmax
  }
end

local BUILDING_RewardDispatcher = {
  [MBuildingType.OilFactory] = BuildingLogic.GetMakeOil,
  [MBuildingType.ResourceFactory] = BuildingLogic.GetMakeResource,
  [MBuildingType.ElectricFactory] = BuildingLogic.GetMakeElectric,
  [MBuildingType.FoodFactory] = BuildingLogic.GetMakeFood
}
local BUILDING_MaxRewardDispatcher = {
  [MBuildingType.OilFactory] = BuildingLogic.GetMaxMakeOil,
  [MBuildingType.ResourceFactory] = BuildingLogic.GetMaxMakeResource,
  [MBuildingType.ElectricFactory] = BuildingLogic.GetMaxMakeElectric,
  [MBuildingType.FoodFactory] = BuildingLogic.GetMaxMakeFood
}

function BuildingLogic:GetRewardById(id)
  local data = Data.buildingData:GetBuildingById(id)
  if data == nil then
    return nil
  end
  local cfg = configManager.GetDataById("config_buildinginfo", data.Tid)
  if BUILDING_RewardDispatcher[cfg.type] then
    return BUILDING_RewardDispatcher[cfg.type](self, id)
  else
    return nil
  end
end

function BuildingLogic:GetRewardMaxByTid(tid)
  local cfg = configManager.GetDataById("config_buildinginfo", tid)
  if BUILDING_RewardDispatcher[cfg.type] then
    return BUILDING_MaxRewardDispatcher[cfg.type](self, tid)
  else
    return nil
  end
end

function BuildingLogic:GetUniqueHeroListExcept(buildingId)
  local uniqueHeroMap = {}
  local buildingDatas = Data.buildingData:GetBuildingData()
  for bid, buildingData in pairs(buildingDatas) do
    if bid ~= buildingId then
      for k, heroId in pairs(buildingData.HeroList) do
        local uniqueId = Logic.shipLogic:GetShipUniqueIdById(heroId)
        uniqueHeroMap[uniqueId] = heroId
      end
    end
  end
  return uniqueHeroMap
end

function BuildingLogic:_getInitBuildByGroupId(groupId)
  if self.m_group2BuildInfo[groupId] then
    local datas = self.m_group2BuildInfo[groupId]
    for _, data in ipairs(datas) do
      if data.level == BuildInitLv then
        return data.id
      end
    end
    return 0
  else
    return 0
  end
end

function BuildingLogic:GetBuildType(tid)
  if tid == nil then
    return nil
  end
  return configManager.GetDataById("config_buildinginfo", tid).type
end

function BuildingLogic:GetBuildName(tid)
  return configManager.GetDataById("config_buildinginfo", tid).name
end

function BuildingLogic:GetBuildEngName(tid)
  return configManager.GetDataById("config_buildinginfo", tid).englishname
end

function BuildingLogic:GetBuildDesc(tid)
  return configManager.GetDataById("config_buildinginfo", tid).desc
end

function BuildingLogic:GetBuildIcon(tid)
  return configManager.GetDataById("config_buildinginfo", tid).typeicon
end

function BuildingLogic:BathHeroWrap()
  local hero = Data.bathroomData:GetBathHero()
  local res = {}
  for _, v in ipairs(hero) do
    if next(v) ~= nil then
      table.insert(res, v.HeroId)
    end
  end
  return res
end

function BuildingLogic:CheckBuildHero(heroIdList, data, otherList, otherData)
  data = Data.buildingData:GetBuildingById(data.Id)
  if data == nil then
    return -1, UIHelper.GetString(3002065)
  end
  local tid = data.Tid
  local cost = configManager.GetDataById("config_buildinginfo", tid).foodcost
  local cur = Data.buildingData:GetCurFood()
  local old = cur
  local max = Data.buildingData:GetFoodMax()
  if otherData then
    local otherCost = configManager.GetDataById("config_buildinginfo", otherData.Tid).foodcost
    cur = cur - otherCost * #otherData.HeroList
    cur = cur + otherCost * #otherList
  end
  cur = cur - cost * #data.HeroList
  cur = cur + cost * #heroIdList
  if 0 < cost and max < cur and old <= cur then
    return -1, UIHelper.GetString(3002024)
  end
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  local cachBathFids = self:GetHeroUniqueTids(bathHero)
  local cachBuildingFids = self:GetUniqueHeroListExcept(data.Id)
  local sortedHeroIds = clone(heroIdList)
  table.sort(sortedHeroIds, function(l, r)
    local lu = Logic.shipLogic:GetShipUniqueIdById(l)
    local ru = Logic.shipLogic:GetShipUniqueIdById(r)
    local lbath = cachBathFids[lu]
    local rbath = cachBathFids[ru]
    local lvalue = lbath and 1 or 0
    local rvalue = rbath and 1 or 0
    return lvalue > rvalue
  end)
  local exchangeShip = false
  for index, heroId in ipairs(sortedHeroIds) do
    local curUniqueId = Logic.shipLogic:GetShipUniqueIdById(heroId)
    local bInBath = cachBathFids[curUniqueId]
    local isTypeInBuilding = cachBuildingFids[curUniqueId]
    if bInBath then
      return 100, nil
    end
    if isTypeInBuilding then
      exchangeShip = true
      local isHeroIdInBuilding = Data.buildingData:IsInBuilding(heroId)
      if not isHeroIdInBuilding then
        return -1, UIHelper.GetString(3002033)
      end
    end
    local outpost = Logic.mubarOutpostLogic:CheckHeroIsInOutpost(heroId)
    if outpost then
      return -5, UIHelper.GetString(4600020)
    end
  end
  if exchangeShip then
    return 200, nil
  end
  return 0, nil
end

function BuildingLogic:CheckAndSendBuildHero(heroIdList, data, okCB)
  local result, errmsg = self:CheckBuildHero(heroIdList, data)
  if result == -1 then
    return false, errmsg
  end
  if result == -5 then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool and okCB then
          okCB()
        end
      end
    }
    noticeManager:ShowMsgBox(errmsg, tabParams)
    return true, nil
  end
  if result == 100 then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          moduleManager:JumpToFunc(FunctionID.BathRoom)
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(3002031), tabParams)
    return true, nil
  end
  if result == 200 then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool and okCB then
          okCB()
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(3002032), tabParams)
    return true, nil
  end
  local result_sc, msg = self:CheckBuildingSameCharacher(heroIdList, data)
  if result_sc ~= 0 then
    if result_sc == SameCharacterIn.Bath then
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            moduleManager:JumpToFunc(FunctionID.BathRoom)
          end
        end
      }
      noticeManager:ShowMsgBox(msg, tabParams)
      return true, nil
    end
    if result_sc == SameCharacterIn.Building then
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool and okCB then
            okCB()
          end
        end
      }
      noticeManager:ShowMsgBox(msg, tabParams)
      return true, nil
    end
    if result_sc == SameCharacterIn.Outpost then
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool and okCB then
            okCB()
          end
        end
      }
      noticeManager:ShowMsgBox(msg, tabParams)
      return true, nil
    end
  end
  if okCB then
    okCB()
  end
  return true, nil
end

function BuildingLogic:CheckBuildingSameCharacher(heroIdList, data)
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  local cachBathFids = self:GetHeroUniqueTids(bathHero)
  local cachBuildingFids = self:GetUniqueHeroListExcept(data.Id)
  local outpostHero = Data.mubarOutpostData:GetOutPostHeroData()
  local cachOutpostFids = Logic.buildingLogic:GetHeroUniqueTids(outpostHero)
  local sortedHeroIds = clone(heroIdList)
  for _, heroId in ipairs(sortedHeroIds) do
    local sf_id = Logic.shipLogic:GetShipUniqueIdById(heroId)
    local sf_config = configManager.GetDataById("config_ship_fleet", sf_id)
    local bInBath = cachBathFids[sf_id]
    local isTypeInBuilding = cachBuildingFids[sf_id]
    local isTypeInOutpost = cachOutpostFids[sf_id]
    if not isTypeInBuilding and not bInBath and not isTypeInOutpost and #sf_config.same_character > 0 then
      for _, asid in pairs(sf_config.same_character) do
        local bInBath_SC = cachBathFids[asid]
        local isTypeInBuilding_SC = cachBuildingFids[asid]
        local isTypeInOutpost_SC = cachOutpostFids[asid]
        local newShipName = Logic.shipLogic:GetRealName(heroId)
        if bInBath_SC then
          return SameCharacterIn.Bath, string.format(UIHelper.GetString(4700008), Logic.shipLogic:GetRealName(bInBath_SC), newShipName)
        elseif isTypeInBuilding_SC then
          return SameCharacterIn.Building, string.format(UIHelper.GetString(4700008), Logic.shipLogic:GetRealName(isTypeInBuilding_SC), newShipName)
        elseif isTypeInOutpost_SC then
          return SameCharacterIn.Outpost, string.format(UIHelper.GetString(4700008), Logic.shipLogic:GetRealName(bInBath_SC), newShipName)
        else
          return 0, nil
        end
      end
    else
      return 0, nil
    end
  end
  return 0, nil
end

function BuildingLogic:CheckBuildingListHero(heroIdList, data, otherList, otherData, callback)
  local result, errmsg = self:CheckBuildHero(heroIdList, data, otherList, otherData)
  if result == -1 then
    return false, errmsg
  end
  if result == 200 then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool and callback then
          callback()
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(3002032), tabParams)
    return false, nil
  end
  return true, nil
end

function BuildingLogic:GetHeroMoodCost(id, heroId)
  local data = Data.buildingData:GetBuildingById(id)
  if data == nil then
    return 0, 0, 0
  end
  local unit = configManager.GetDataById("config_buildinginfo", data.Tid).moodcost
  local mood, cur, rate
  _, mood = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
  local timeUnit = configManager.GetDataById("config_parameter", 207).value
  cur = mood - (time.getSvrTime() - data.LastUpdateTime) / timeUnit * unit
  rate = 0
  if 0 < cur and 0 < mood then
    rate = cur / mood
    Mathf.Clamp01(rate)
  end
  return cur, mood, rate
end

local charSort = {
  [MBuildingType.Office] = 1,
  [MBuildingType.ElectricFactory] = 2,
  [MBuildingType.OilFactory] = 3,
  [MBuildingType.ResourceFactory] = 4,
  [MBuildingType.DormRoom] = 5,
  [MBuildingType.FoodFactory] = 6
}

function BuildingLogic:GetHeroBuildingCharacter(buildType, heroTid)
  local shipMainCfg = configManager.GetDataById("config_ship_main", heroTid)
  local max, char, additions = 0, 0, {}
  if buildType == MBuildingType.ItemFactory then
    for i, cid in ipairs(shipMainCfg.character) do
      local level = shipMainCfg.characterlevel[i]
      local character = configManager.GetDataById("config_character", cid)
      if 0 < #character.recipeadd then
        return {cid}, {level}
      end
    end
    return {}, {}
  end
  local characterIds = {}
  local chacterLevels = {}
  for i, charId in ipairs(shipMainCfg.character) do
    local level = shipMainCfg.characterlevel[i]
    local characterCfg = configManager.GetDataById("config_character", charId)
    local addtion = characterCfg.characteraddition[buildType]
    if addtion and 0 < addtion then
      table.insert(characterIds, charId)
      table.insert(chacterLevels, level)
    end
  end
  return characterIds, chacterLevels
end

function BuildingLogic:CheckHeroRecipe(heroTid, recipeType)
  local shipMainCfg = configManager.GetDataById("config_ship_main", heroTid)
  local characters = shipMainCfg.character
  for i, characterId in ipairs(characters) do
    local characterCfg = configManager.GetDataById("config_character", characterId)
    if characterCfg.recipeaddition[recipeType] and characterCfg.recipeaddition[recipeType] > 0 then
      return true
    end
  end
  return false
end

function BuildingLogic:CheckHeroBuilding(heroTid, buildingType)
  local shipMainCfg = configManager.GetDataById("config_ship_main", heroTid)
  local characters = shipMainCfg.character
  for i, characterId in ipairs(characters) do
    local characterCfg = configManager.GetDataById("config_character", characterId)
    if characterCfg.characteraddition[buildingType] and characterCfg.characteraddition[buildingType] > 0 then
      return true
    end
  end
  return false
end

function BuildingLogic:CheckHeroInBuilding(heroId, buildingId)
  local buildingData = Data.buildingData:GetBuildingById(buildingId)
  local heroList = buildingData.HeroList
  for i, hid in ipairs(heroList) do
    if hid == heroId then
      return true
    end
  end
  return false
end

function BuildingLogic:SetSortBuildingType(btype)
  self.SortBuildingType = btype
end

function BuildingLogic:GetHeroBuildingEffect(heroData)
  local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
  local characters = shipMainCfg.character
  local levels = shipMainCfg.characterlevel
  local maxEffect = 0
  for i, characterId in ipairs(characters) do
    local effect = 0
    local level = levels[i]
    local characterCfg = configManager.GetDataById("config_character", characterId)
    if 0 < #characterCfg.characteraddition then
      local base = characterCfg.characteraddition[self.SortBuildingType]
      local lvup = characterCfg.levelupaddition[self.SortBuildingType]
      effect = level * lvup + base
    else
      local base = characterCfg.recipeaddition[self.SortBuildingType]
      local lvup = characterCfg.leveluprecipeaddition[self.SortBuildingType]
      for i, b in ipairs(base) do
        if 0 < b then
          effect = level * lvup + base
          break
        end
      end
    end
    if maxEffect < effect then
      maxEffect = effect
    end
  end
  return maxEffect
end

function BuildingLogic:GetHeroStatus(heroData)
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  local cachBathFids = self:GetHeroUniqueTids(bathHero)
  local buildingHero = Data.buildingData:GetBuildingHero()
  local cachBuildingFids = self:GetHeroUniqueTids(buildingHero)
  local curUniqueId = Logic.shipLogic:GetShipUniqueIdById(heroData.HeroId)
  local inBuilding = cachBuildingFids[curUniqueId]
  if inBuilding then
    return 3
  end
  local inBath = cachBathFids[curUniqueId]
  if inBath then
    return 1
  end
  return 2
end

function BuildingLogic:CheckBuildingCanLvUp(id)
  local data = Data.buildingData:GetBuildingById(id)
  if data == nil then
    return false
  end
  local nextLv = Logic.buildingLogic:CheckUpgradeLevel(data)
  if nextLv <= 0 then
    return false
  end
  local errMsg = Logic.buildingLogic:CheckUpgradeCost(data.Tid, nextLv)
  return errMsg == nil
end

function BuildingLogic:CheckBuildingsCanLvUp()
  local datas = Data.buildingData:GetBuildingData()
  for id, _ in pairs(datas) do
    if Logic.buildingLogic:CheckBuildingCanLvUp(id) then
      return true
    end
  end
  return false
end

function BuildingLogic:CheckBuildingsCanGet()
  local oil, gold, item = 0, 0, 0
  local datas = Data.buildingData:GetBuildingData()
  for _, data in pairs(datas) do
    local type = Logic.buildingLogic:GetBuildType(data.Tid)
    if type == MBuildingType.OilFactory then
      oil = oil + Logic.buildingLogic:Produce(data)
    elseif type == MBuildingType.ResourceFactory then
      gold = gold + Logic.buildingLogic:Produce(data)
    elseif type == MBuildingType.ItemFactory then
      local _, itemCount = Logic.buildingLogic:ProduceItem(data)
      item = item + itemCount
    end
  end
  return 0 < oil, 0 < gold, 0 < item
end

function BuildingLogic:SetDetailTabIndex(index)
  self.detailTabIndex = index
end

function BuildingLogic:GetDetailTabIndex()
  local index = self.detailTabIndex
  self.detailTabIndex = nil
  return index
end

function BuildingLogic:GetEffectHeroCount(heroList)
  local count = 0
  for i, heroId in ipairs(heroList) do
    local heroInfo = Data.heroData:GetHeroById(heroId)
    local moodNum = Logic.marryLogic:GetMoodNum(heroInfo, heroId)
    if 0 < moodNum then
      count = count + 1
    end
  end
  return count
end

function BuildingLogic:GetProduceRecipeProductivity(buildingData, recipeId)
  local office = Data.buildingData:GetOffice()
  local officeAddition = self:GetTotalHeroAddition(office.Tid, office.HeroList)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local heroAdd = buildingCfg.heroaddition * BuildingBase.Float
  local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
  local recipeType = recipeCfg.type
  local characterAddition = 0
  for i, heroId in ipairs(buildingData.HeroList) do
    local heroData = Data.heroData:GetHeroById(heroId)
    if heroData then
      local moodNum = Logic.marryLogic:GetMoodNum(heroData, heroId)
      if 0 < moodNum then
        local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
        local characters = shipMainCfg.character
        local characterLevels = shipMainCfg.characterlevel
        local addition = 0
        for i, characterId in ipairs(characters) do
          local level = characterLevels[i]
          local characterCfg = configManager.GetDataById("config_character", characterId)
          local base = characterCfg.recipeaddition[recipeType] or 0
          local levelup = characterCfg.leveluprecipeaddition[recipeType] or 0
          if 0 < base then
            addition = addition + (base + levelup * (level - 1)) * BuildingBase.Float
          end
        end
        characterAddition = characterAddition + (addition + 1) * (1 + heroAdd) - 1
      end
    end
  end
  local totalAddition = officeAddition + characterAddition
  return totalAddition * BuildingBase.Int
end

function BuildingLogic:GetItemProductivity(buildingData)
  local office = Data.buildingData:GetOffice()
  local officeAddition = self:GetTotalHeroAddition(office.Tid, office.HeroList)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local heroAdd = buildingCfg.heroaddition
  local characterAddition = 0
  for i, heroId in ipairs(buildingData.HeroList) do
    local heroData = Data.heroData:GetHeroById(heroId)
    if heroData then
      local moodNum = Logic.marryLogic:GetMoodNum(heroData, heroId)
      if 0 < moodNum then
        local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
        local characters = shipMainCfg.character
        local characterLevels = shipMainCfg.characterlevel
        local addition = 0
        for i, characterId in ipairs(characters) do
          local level = characterLevels[i]
          local characterCfg = configManager.GetDataById("config_character", characterId)
          local addAll = 0 < #characterCfg.recipeaddition
          for i, add in ipairs(characterCfg.recipeaddition) do
            if add == 0 then
              addAll = false
              break
            end
          end
          if addAll then
            addition = addition + (characterCfg.recipeaddition[1] + characterCfg.leveluprecipeaddition[1] * (level - 1))
          end
        end
        addition = (addition + 10000) * (heroAdd + 10000) / 10000 - 10000
        characterAddition = characterAddition + addition
      end
    end
  end
  local total = officeAddition + characterAddition / 10000
  return total
end

function BuildingLogic:GetItemRecipeAdd(buildingData)
  local office = Data.buildingData:GetOffice()
  local officeAddition = self:GetTotalHeroAddition(office.Tid, office.HeroList)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local characterAdditions = {}
  local showRecipeType = {}
  local heroAdd = buildingCfg.heroaddition
  for i, heroId in ipairs(buildingData.HeroList) do
    local heroData = Data.heroData:GetHeroById(heroId)
    if heroData then
      local moodNum = Logic.marryLogic:GetMoodNum(heroData, heroId)
      if 0 < moodNum then
        local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
        local characters = shipMainCfg.character
        local characterLevels = shipMainCfg.characterlevel
        for i, characterId in ipairs(characters) do
          local level = characterLevels[i]
          local characterCfg = configManager.GetDataById("config_character", characterId)
          local addAll = 0 < #characterCfg.recipeaddition
          for i, addition in ipairs(characterCfg.recipeaddition) do
            if addition == 0 then
              addAll = false
              break
            end
          end
          if not addAll then
            for i, recipeType in ipairs(characterCfg.recipeadd) do
              if 0 < recipeType then
                showRecipeType[recipeType] = true
              end
            end
          end
          local addition = 0
          for i, recipeType in ipairs(characterCfg.recipeadd) do
            if 0 < recipeType then
              addition = characterCfg.recipeaddition[recipeType] + characterCfg.leveluprecipeaddition[recipeType] * (level - 1)
              addition = (addition + 10000) * (heroAdd + 10000) / 10000 - 10000
              characterAdditions[recipeType] = characterAdditions[recipeType] or 0
              characterAdditions[recipeType] = characterAdditions[recipeType] + addition
            end
          end
        end
      end
    end
  end
  local result = {}
  for recipeType, addition in pairs(characterAdditions) do
    if showRecipeType[recipeType] then
      addition = addition / 10000 + officeAddition
      table.insert(result, {recipeType = recipeType, add = addition})
    end
  end
  local recipeId = buildingData.RecipeId
  if 0 < recipeId and 0 < buildingData.ItemCount then
    local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
    local addition = characterAdditions[recipeCfg.type] or 0
    addition = addition / 10000 + officeAddition
    if not showRecipeType[recipeCfg.type] then
      table.insert(result, {
        recipeType = recipeCfg.type,
        add = addition
      })
    end
  end
  return result
end

function BuildingLogic:GetOfficeAddition()
  local officeData = Data.buildingData:GetOffice()
  local officeHeroCountAddition = self:GetBuildingCharacterCountAddition(officeData.Tid, officeData.HeroList)
  local officeCharacterAddition = self:GetBuildingCharacterAddition(officeData.Tid, officeData.HeroList)
  return officeHeroCountAddition, officeCharacterAddition
end

function BuildingLogic:GetBuildingCharacterCountAddition(buildingTid, heroList)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local heroCount = self:GetEffectHeroCount(heroList)
  local addition = heroCount * buildingCfg.heroaddition
  return addition
end

function BuildingLogic:GetBuildingCharacterAddition(buildingTid, heroList)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local heroAdd = buildingCfg.heroaddition * BuildingBase.Float
  local totalAddition = 0
  local buildingType = buildingCfg.type
  for i, heroId in ipairs(heroList) do
    local heroData = Data.heroData:GetHeroById(heroId)
    if heroData then
      local moodNum = Logic.marryLogic:GetMoodNum(heroData, heroId)
      if 0 < moodNum then
        local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
        local characters = shipMainCfg.character
        local characterLevels = shipMainCfg.characterlevel
        local addition = 0
        for i, characterId in ipairs(characters) do
          local level = characterLevels[i]
          local characterCfg = configManager.GetDataById("config_character", characterId)
          local base = characterCfg.characteraddition[buildingType] or 0
          local levelup = characterCfg.levelupaddition[buildingType] or 0
          if 0 < base then
            addition = addition + (base + levelup * (level - 1))
          end
        end
        totalAddition = (addition * BuildingBase.Float + 1) * (heroAdd + 1) - 1
      end
    end
  end
  totalAddition = totalAddition + 1
  return totalAddition
end

function BuildingLogic:GetMaxFoodByHero(buildingTid, heroIds)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  if buildingCfg.type == MBuildingType.FoodFactory then
    local addition = self:GetTotalHeroAddition(buildingTid, heroIds)
    local maxFood = buildingCfg.productmax * addition
    maxFood = math.ceil(maxFood)
    return maxFood
  end
  return 0
end

function BuildingLogic:GetSingleHeroAddition(buildingTid, heroId)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local heroAdd = buildingCfg.heroaddition * BuildingBase.Float
  local totalAddition = 0
  local buildingType = buildingCfg.type
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
    local characters = shipMainCfg.character
    local characterLevels = shipMainCfg.characterlevel
    local addition = 0
    for i, characterId in ipairs(characters) do
      local level = characterLevels[i]
      local characterCfg = configManager.GetDataById("config_character", characterId)
      local base = characterCfg.characteraddition[buildingType] or 0
      local levelup = characterCfg.levelupaddition[buildingType] or 0
      if 0 < base then
        addition = addition + base + levelup * (level - 1)
      end
    end
    totalAddition = totalAddition + (heroAdd + 1) * (1 + addition * BuildingBase.Float) - 1
  end
  totalAddition = totalAddition + 1
  return totalAddition
end

function BuildingLogic:GetSingleRecipeAddition(buildingTid, heroId, recipeId)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local heroAdd = buildingCfg.heroaddition * BuildingBase.Float
  local totalAddition = 0
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
    local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
    local characters = shipMainCfg.character
    local characterLevels = shipMainCfg.characterlevel
    local addition = 0
    for i, characterId in ipairs(characters) do
      local level = characterLevels[i]
      local characterCfg = configManager.GetDataById("config_character", characterId)
      local base = characterCfg.recipeaddition[recipeCfg.type] or 0
      local levelup = characterCfg.leveluprecipeaddition[recipeCfg.type] or 0
      if 0 < base then
        addition = addition + base + levelup * (level - 1)
      end
    end
    totalAddition = totalAddition + (heroAdd + 1) * (1 + addition * BuildingBase.Float) - 1
  end
  totalAddition = totalAddition + 1
  return totalAddition
end

function BuildingLogic:GetTotalHeroAddition(buildingTid, heroList)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local heroAdd = buildingCfg.heroaddition
  local totalAddition = 0
  local buildingType = buildingCfg.type
  for i, heroId in ipairs(heroList) do
    local heroData = Data.heroData:GetHeroById(heroId)
    if heroData then
      local moodNum = Logic.marryLogic:GetMoodNum(heroData, heroId)
      if 0 < moodNum then
        local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
        local characters = shipMainCfg.character
        local characterLevels = shipMainCfg.characterlevel
        local addition = 0
        for i, characterId in ipairs(characters) do
          local level = characterLevels[i]
          local characterCfg = configManager.GetDataById("config_character", characterId)
          local base = characterCfg.characteraddition[buildingType] or 0
          local levelup = characterCfg.levelupaddition[buildingType] or 0
          if 0 < base then
            addition = addition + base + levelup * (level - 1)
          end
        end
        totalAddition = totalAddition + (heroAdd + 10000) * (10000 + addition) / 10000 - 10000
      end
    end
  end
  totalAddition = (totalAddition + 10000) / 10000
  return totalAddition
end

function BuildingLogic:GetTotalRecipeAddition(buildingTid, heroList, recipeId)
  local office = Data.buildingData:GetOffice()
  local officeAddition = self:GetTotalHeroAddition(office.Tid, office.HeroList)
  local recipeAddition = 0
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local heroAdd = buildingCfg.heroaddition * BuildingBase.Float
  local totalAddition = 0
  for i, heroId in ipairs(heroList) do
    local heroData = Data.heroData:GetHeroById(heroId)
    if heroData then
      local moodNum = Logic.marryLogic:GetMoodNum(heroData, heroId)
      if 0 < moodNum then
        local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
        local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
        local characters = shipMainCfg.character
        local characterLevels = shipMainCfg.characterlevel
        local addition = 0
        for i, characterId in ipairs(characters) do
          local level = characterLevels[i]
          local characterCfg = configManager.GetDataById("config_character", characterId)
          local base = characterCfg.recipeaddition[recipeCfg.type] or 0
          local levelup = characterCfg.leveluprecipeaddition[recipeCfg.type] or 0
          if 0 < base then
            addition = addition + base + levelup * (level - 1)
          end
        end
        totalAddition = totalAddition + (heroAdd + 1) * (1 + addition * BuildingBase.Float) - 1
      end
    end
  end
  totalAddition = totalAddition + officeAddition
  return totalAddition
end

function BuildingLogic:GetUnlockDatas(tid, newTid)
  self.newUpRecipe = {}
  self.newDownRecipe = {}
  local curRecipeId = {}
  local newRecipeId = {}
  local curCfg = configManager.GetDataById("config_buildinginfo", tid)
  for k, v in pairs(curCfg.recipeid) do
    table.insert(curRecipeId, v)
  end
  local newCfg = configManager.GetDataById("config_buildinginfo", newTid)
  for k, v in pairs(newCfg.recipeid) do
    table.insert(newRecipeId, v)
  end
  if curCfg.type == MBuildingType.ItemFactory then
    local recipes = {}
    if curCfg.level < newCfg.level then
      self:HaveNewUpRecipe(curRecipeId, newRecipeId)
      if self.newUpRecipe then
        for k, v in pairs(self.newUpRecipe) do
          local recipe = configManager.GetDataById("config_recipe", v)
          local itemCfg = Logic.bagLogic:GetConfig(recipe.item[1], recipe.item[2])
          local recipe = {}
          recipe.key = UIHelper.GetString(3002001)
          recipe.value = UIHelper.GetLocString(3002012, itemCfg.name)
          table.insert(recipes, recipe)
        end
      end
    else
      self:HaveNewDownRecipe(curRecipeId, newRecipeId)
      if self.newDownRecipe then
        for k, v in pairs(self.newDownRecipe) do
          local recipe = configManager.GetDataById("config_recipe", v)
          local itemCfg = Logic.bagLogic:GetConfig(recipe.item[1], recipe.item[2])
          local recipe = {}
          recipe.key = UIHelper.GetString(3002013)
          recipe.value = UIHelper.GetLocString(3002014, itemCfg.name)
          table.insert(recipes, recipe)
        end
      end
    end
    return recipes
  elseif curCfg.type == MBuildingType.Office then
    local addBuildings = {}
    for btype, bcount in ipairs(newCfg.buildquantity) do
      local delta = bcount - curCfg.buildquantity[btype]
      if 0 < delta then
        local building = {}
        building.key = UIHelper.GetString(3002003)
        building.value = string.format("%sx%s", self:GetBuildingTypeName(btype), delta)
        table.insert(addBuildings, building)
      end
    end
    local landCount = newCfg.unlockbuilding - curCfg.unlockbuilding
    if 0 < landCount then
      local building = {}
      building.key = UIHelper.GetString(3002002)
      building.value = landCount
      table.insert(addBuildings, building)
    end
    return addBuildings
  end
  return {}
end

function BuildingLogic:GetBuildingUnlockLevel(buildingTid, curCount)
  if not self.buildingCountMap then
    local buildingCountMap = {}
    local maxLevel = Logic.buildingLogic:GetMaxLevel(MBuildingType.Office)
    for level = 1, maxLevel do
      local officeTid = self:GetTidByTypeLevel(MBuildingType.Office, level)
      local officeRec = configManager.GetDataById("config_buildinginfo", officeTid)
      for btype, bcount in ipairs(officeRec.buildquantity) do
        buildingCountMap[btype] = buildingCountMap[btype] or {}
        local countLvMap = buildingCountMap[btype]
        countLvMap[bcount] = officeRec.level
      end
    end
    self.buildingCountMap = buildingCountMap
  end
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local countLvMap = self.buildingCountMap[buildingCfg.type - 1]
  for count, officeLevel in ipairs(countLvMap) do
    if curCount < count then
      return officeLevel
    end
  end
  return 0
end

function BuildingLogic:GetBuildingListData()
  local heroInfoList = {}
  local buildingHeroSfIds = self:GetBuildingHeroSfIds()
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  local bathFids = self:GetHeroUniqueTids(bathHero)
  local heroInfos = Data.heroData:GetHeroData()
  for heroId, heroInfo in pairs(heroInfos) do
    local sfId = Logic.shipLogic:GetShipUniqueIdById(heroId)
    if not buildingHeroSfIds[sfId] and not bathFids[sfId] then
      table.insert(heroInfoList, heroInfo)
    end
  end
  table.sort(heroInfoList, function(l, r)
    local lq = Logic.shipLogic:GetQualityByHeroId(l.HeroId)
    local rq = Logic.shipLogic:GetQualityByHeroId(r.HeroId)
    return lq > rq
  end)
  return heroInfoList
end

function BuildingLogic:HaveNewUpRecipe(curCfg, newCfg)
  local isTure = false
  for k, v in pairs(newCfg) do
    for key, value in pairs(curCfg) do
      if v == value then
        isTure = true
        table.remove(newCfg, k)
      end
    end
  end
  if isTure then
    isTure = false
    self:HaveNewUpRecipe(curCfg, newCfg)
  else
    self.newUpRecipe = newCfg
  end
end

function BuildingLogic:HaveNewDownRecipe(curCfg, newCfg)
  local isTure = false
  for k, v in pairs(curCfg) do
    for key, value in pairs(newCfg) do
      if v == value then
        isTure = true
        table.remove(curCfg, k)
      end
    end
  end
  if isTure then
    isTure = false
    self:HaveNewDownRecipe(curCfg, newCfg)
  else
    self.newDownRecipe = curCfg
  end
end

function BuildingLogic:SetSaveBuildingHero(tabSelectShip)
  self.tabSelectShip = tabSelectShip
end

function BuildingLogic:GetSaveBuildingHero()
  return self.tabSelectShip
end

function BuildingLogic:IsBuildingHeroSort(heroId)
  if self.tabSelectShip == nil then
    return false
  end
  for k, v in pairs(self.tabSelectShip) do
    if heroId == v then
      return true
    end
  end
  return false
end

function BuildingLogic:GetBuildingTypeById(buildingId)
  if buildingId ~= nil then
    local buildingData = Data.buildingData:GetBuildingById(buildingId)
    local buildingType = configManager.GetDataById("config_buildinginfo", buildingData.Tid).type
    return buildingType
  else
    return nil
  end
end

function BuildingLogic:GetMaxCharacterLevel(levelData)
  local levelNum = 0
  local index = 0
  for k, v in pairs(levelData) do
    if v >= levelNum then
      levelNum = v
      index = k
    end
  end
  return levelNum, index
end

function BuildingLogic:GetBuildingHeroMatch(data1, data2, type)
  local sm_id1 = Data.heroData:GetHeroById(data1.HeroId).TemplateId
  local sm_id2 = Data.heroData:GetHeroById(data2.HeroId).TemplateId
  local charIds1, Level1 = self:GetHeroBuildingCharacter(type, sm_id1)
  local charIds2, Level2 = self:GetHeroBuildingCharacter(type, sm_id2)
  local maxLevel1, index1, maxLevel2, index2
  local shipMainCfg1 = configManager.GetDataById("config_ship_main", sm_id1)
  local shipMainCfg2 = configManager.GetDataById("config_ship_main", sm_id2)
  local match1 = next(charIds1) ~= nil and 1 or 0
  local match2 = next(charIds2) ~= nil and 1 or 0
  return match1, match2
end

function BuildingLogic:GetBuildingCharacterSortLevel(data1, data2, type, descend)
  local sm_id1 = Data.heroData:GetHeroById(data1.HeroId).TemplateId
  local sm_id2 = Data.heroData:GetHeroById(data2.HeroId).TemplateId
  local charIds1, levels1 = self:GetHeroBuildingCharacter(type, sm_id1)
  local charIds2, levels2 = self:GetHeroBuildingCharacter(type, sm_id2)
  local shipMainCfg1 = configManager.GetDataById("config_ship_main", sm_id1)
  local shipMainCfg2 = configManager.GetDataById("config_ship_main", sm_id2)
  local match1 = next(charIds1) ~= nil and 1 or 0
  local match2 = next(charIds2) ~= nil and 1 or 0
  if match1 ~= match2 then
    if not descend then
      match1, match2 = match2, match1
    end
    return match1, match2
  end
  local maxLevel1 = 0
  local maxLevel2 = 0
  if match1 == 1 then
    maxLevel1 = Logic.buildingLogic:GetMaxCharacterLevel(levels1)
    maxLevel2 = Logic.buildingLogic:GetMaxCharacterLevel(levels2)
  else
    maxLevel1 = Logic.buildingLogic:GetMaxCharacterLevel(shipMainCfg1.characterlevel)
    maxLevel2 = Logic.buildingLogic:GetMaxCharacterLevel(shipMainCfg2.characterlevel)
  end
  return maxLevel1, maxLevel2
end

function BuildingLogic:GetBuildingCharacterSortMood(data1, data2, type, descend)
  local sm_id1 = Data.heroData:GetHeroById(data1.HeroId).TemplateId
  local sm_id2 = Data.heroData:GetHeroById(data2.HeroId).TemplateId
  local charIds1, levels1 = self:GetHeroBuildingCharacter(type, sm_id1)
  local charIds2, levels2 = self:GetHeroBuildingCharacter(type, sm_id2)
  local shipMainCfg1 = configManager.GetDataById("config_ship_main", sm_id1)
  local shipMainCfg2 = configManager.GetDataById("config_ship_main", sm_id2)
  local match1 = next(charIds1) ~= nil and 1 or 0
  local match2 = next(charIds2) ~= nil and 1 or 0
  if match1 ~= match2 then
    if not descend then
      match1, match2 = match2, match1
    end
    return match1, match2
  end
  local _, curMood1 = Logic.marryLogic:GetLoveInfo(data1.HeroId, MarryType.Mood)
  local _, curMood2 = Logic.marryLogic:GetLoveInfo(data2.HeroId, MarryType.Mood)
  return curMood1, curMood2
end

function BuildingLogic:IsHeroInDormOrBath(heroId)
  local sf_id = Logic.shipLogic:GetShipUniqueIdById(heroId)
  local buildingHeros = self:GetBuildingHeroSfIds()
  local inDormOrBath = false
  if buildingHeros[sf_id] then
    local relativeHeroId = buildingHeros[sf_id]
    local buildingData = Data.buildingData:GetHeroBuilding(relativeHeroId)
    if buildingData then
      local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
      inDormOrBath = buildingCfg.type == MBuildingType.DormRoom
    end
  end
  inDormOrBath = inDormOrBath or self:IsBathHero(heroId)
  return inDormOrBath
end

function BuildingLogic:GetHeroRecipeType(data, recipeId)
  local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
  local shipMainCfg = configManager.GetDataById("config_ship_main", data.TemplateId)
  for i, cid in ipairs(shipMainCfg.character) do
    local characterCfg = configManager.GetDataById("config_character", cid)
    if characterCfg.recipeaddition[recipeCfg.type] and characterCfg.recipeaddition[recipeCfg.type] > 0 then
      return 1
    end
  end
  return 0
end

function BuildingLogic:GetSortResult(maxLevel1, maxLevel2, sm_id1, sm_id2, charIdData1, charIdData2)
  local math1 = false
  local math2 = false
  local sf_id1 = Logic.shipLogic:GetSfidBySmid(sm_id1)
  local sf_id2 = Logic.shipLogic:GetSfidBySmid(sm_id2)
  local ship_order1 = configManager.GetDataById("config_ship_handbook", sf_id1).ship_order
  local ship_order2 = configManager.GetDataById("config_ship_handbook", sf_id2).ship_order
  if maxLevel1 ~= maxLevel2 then
    match1 = maxLevel2 < maxLevel1
    match2 = maxLevel1 < maxLevel2
  elseif charIdData1 ~= charIdData2 then
    match1 = charIdData2 < charIdData1
    match2 = charIdData1 < charIdData2
  elseif maxLevel1 == maxLevel2 and charIdData1 == charIdData2 then
    match1 = ship_order1 > ship_order2
    match2 = ship_order1 < ship_order2
  end
  return match1, match2
end

function BuildingLogic:BuildingIsHaveItem()
  local buildingDatas = Data.buildingData:GetBuildingData()
  local buildingCfg = {}
  local remainTime, count, remainCount
  for i, data in ipairs(buildingDatas) do
    buildingCfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    if buildingCfg.type == MBuildingType.ItemFactory then
      remainTime, count, remainCount = self:ProduceItem(data)
      if remainCount == 0 then
        return true
      end
    end
  end
  return false
end

function BuildingLogic:IsHaveHeroInBuilding()
  local buildingHero = Data.buildingData:GetBuildingHero()
  local buildingType = 0
  if buildingHero then
    for k, v in pairs(buildingHero) do
      buildingType = Data.buildingData:GetHeroBuildingType(v)
      local moodInfo, num = Logic.marryLogic:GetLoveInfo(v, MarryType.Mood)
      if num == 0 and buildingType ~= MBuildingType.DormRoom then
        return true
      end
    end
  end
  return false
end

function BuildingLogic:IsHaveHeroInSingleBuilding(heroData)
  for key, value in pairs(heroData) do
    local moodInfo, num = Logic.marryLogic:GetLoveInfo(value, MarryType.Mood)
    if num == 0 then
      return true
    end
  end
  return false
end

function BuildingLogic:StartSliderAnim(from, to, callback)
  self.animTimers = self.animTimers or {}
  local animTime = 0
  local loop = 10
  local delta = 0.03
  local totalTime = delta * loop
  local sliderTimer = Timer.New(function()
    animTime = animTime + delta
    local percent = animTime / totalTime
    local curValue = from + (to - from) * percent
    callback(curValue)
  end, delta, loop)
  sliderTimer:Start()
  table.insert(self.animTimers, sliderTimer)
  return sliderTimer
end

function BuildingLogic:StopSliderAnim()
  if self.animTimers then
    for i, timer in ipairs(self.animTimers) do
      timer:Stop()
    end
    self.animTimers = {}
  end
end

function BuildingLogic:GetShowStatus(buildingData, buildingCfg)
  if buildingCfg.type ~= MBuildingType.DormRoom then
    return buildingData.Status
  end
  local heroList = buildingData.HeroList
  if #heroList == 0 then
    return BuildingStatus.Idle
  end
  local status = BuildingStatus.Idle
  local moodLimit = configManager.GetDataById("config_parameter", 142).arrValue
  local max = moodLimit[2]
  for i, heroId in ipairs(heroList) do
    local moodInfo, curMood = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
    if max > curMood then
      status = BuildingStatus.Working
      break
    end
  end
  return status
end

function BuildingLogic:GetHeroBuildingFoodCost(heroId)
  local buildingData = Data.buildingData:GetHeroBuilding(heroId)
  if buildingData then
    local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
    return buildingCfg.foodcost
  end
  return 0
end

function BuildingLogic:GetBuildingEndTime(buildingData)
  local buildingRec = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local addtionTable = {}
  local lastUpdateTime = buildingData.LastUpdateTime
  local baseSpeed = buildingRec.productivity * BuildingBase.Float
  local productMax = buildingRec.productmax
  local productCount = buildingData.ProductCount
  table.sort(buildingData.HeroEffectTimeList, function(a, b)
    return a.EffectTime[2] < b.EffectTime[2]
  end)
  for key, value in ipairs(buildingData.HeroEffectTimeList) do
    local thisHeroAddtion = self:GetSingleHeroAddition(buildingData.Tid, value.HeroId)
    if addtionTable[value.EffectTime[2]] == nil then
      addtionTable[value.EffectTime[2]] = thisHeroAddtion
    else
      addtionTable[value.EffectTime[2]] = addtionTable[value.EffectTime[2]] + thisHeroAddtion - 1
    end
    for k, v in pairs(addtionTable) do
      if k < value.EffectTime[2] then
        addtionTable[k] = addtionTable[k] + thisHeroAddtion - 1
      end
    end
  end
  local itemCount = productMax - productCount
  local hasProduct = 0
  local lastEffectTime = lastUpdateTime
  table.sort(addtionTable, function(a, b)
    return a < b
  end)
  for timing, addtion in pairs(addtionTable) do
    if itemCount < addtion * baseSpeed * (timing - lastEffectTime) / 600 + hasProduct then
      return math.floor(lastEffectTime + (itemCount - hasProduct) * 600 / (baseSpeed * addtion))
    else
      hasProduct = hasProduct + addtion * baseSpeed * (timing - lastEffectTime) / 600
      lastEffectTime = timing
    end
  end
  return math.floor(lastEffectTime + (itemCount - hasProduct) / baseSpeed * 600)
end

function BuildingLogic:GetProductEndTime(buildingData)
  local buildingRec = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local addtionTable = {}
  local lastUpdateTime = buildingData.LastUpdateTime
  if buildingData.RecipeId == 0 then
    return 0
  end
  local baseSpeed = configManager.GetDataById("config_recipe", buildingData.RecipeId).time
  local itemCount = buildingData.ItemCount
  table.sort(buildingData.HeroEffectTimeList, function(a, b)
    return a.EffectTime[2] < b.EffectTime[2]
  end)
  for key, value in ipairs(buildingData.HeroEffectTimeList) do
    local thisHeroAddtion = self:GetSingleRecipeAddition(buildingData.Tid, value.HeroId, buildingData.RecipeId)
    if addtionTable[value.EffectTime[2]] == nil then
      addtionTable[value.EffectTime[2]] = thisHeroAddtion
    else
      addtionTable[value.EffectTime[2]] = addtionTable[value.EffectTime[2]] + thisHeroAddtion - 1
    end
    for k, v in pairs(addtionTable) do
      if k < value.EffectTime[2] then
        addtionTable[k] = addtionTable[k] + thisHeroAddtion - 1
      end
    end
  end
  table.sort(addtionTable, function(a, b)
    return a < b
  end)
  local hasProduct = 0
  local lastEffectTime = lastUpdateTime
  for timing, addtion in pairs(addtionTable) do
    if itemCount < addtion * (timing - lastEffectTime) / baseSpeed + hasProduct then
      return math.floor(lastEffectTime + (itemCount - hasProduct) * (baseSpeed / addtion))
    else
      hasProduct = hasProduct + addtion * (timing - lastEffectTime) / baseSpeed
      lastEffectTime = timing
    end
  end
  return math.floor(lastEffectTime + (itemCount - hasProduct) * baseSpeed)
end

function BuildingLogic:GetPushNoticeParams(args)
  local paramList = {}
  local noticeParam = {}
  local moodFirstEndTime = 9999999999
  local produceFirstEndTime = 9999999999
  if #args == 0 then
    return paramList
  end
  for k, buildingData in pairs(args) do
    local buildingRec = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
    for key, value in pairs(buildingData.HeroEffectTimeList) do
      if value.EffectTime[2] > time.getSvrTime() then
        moodFirstEndTime = math.min(value.EffectTime[2], moodFirstEndTime)
      end
    end
    if buildingData.Status == BuildingStatus.Working then
      if buildingRec.type == 3 then
        noticeParam = {}
        noticeParam.key = "oil"
        noticeParam.text = configManager.GetDataById("config_pushnotice", 9).text
        noticeParam.time = self:GetBuildingEndTime(buildingData)
        noticeParam.repeatTime = LocalNotificationInterval.NoRepeat
        paramList.oil = noticeParam
      elseif buildingRec.type == 4 then
        noticeParam = {}
        noticeParam.key = "gold"
        noticeParam.text = configManager.GetDataById("config_pushnotice", 10).text
        noticeParam.time = self:GetBuildingEndTime(buildingData)
        noticeParam.repeatTime = LocalNotificationInterval.NoRepeat
        paramList.gold = noticeParam
      elseif buildingRec.type == 7 then
        local produceEndTime = Logic.buildingLogic:GetProductEndTime(buildingData)
        if produceEndTime > time.getSvrTime() then
          produceFirstEndTime = math.min(produceFirstEndTime, produceEndTime)
        end
      end
    end
  end
  noticeParam = {}
  noticeParam.key = "mood"
  noticeParam.text = configManager.GetDataById("config_pushnotice", 7).text
  noticeParam.time = moodFirstEndTime
  noticeParam.repeatTime = LocalNotificationInterval.NoRepeat
  paramList.mood = noticeParam
  noticeParam = {}
  noticeParam.key = "produce"
  noticeParam.text = configManager.GetDataById("config_pushnotice", 8).text
  noticeParam.time = produceFirstEndTime
  noticeParam.repeatTime = LocalNotificationInterval.NoRepeat
  paramList.produce = noticeParam
  return paramList
end

function BuildingLogic:SetMode(mode)
  if mode < BuildingMode._2D or mode > BuildingMode._3D then
    return
  end
  self.buildingMode = mode
end

function BuildingLogic:GetMode()
  return self.buildingMode
end

function BuildingLogic:GetCharacterPlots(heroId)
  local plots = {}
  for i = 1, 3 do
    local plot = configManager.GetDataById("config_building_character_story", i)
    local data = {
      sfId = plot.ship_fleet_id,
      plotId = plot.plot_trigger_id,
      plotType = plot.plot_trigger_type
    }
    table.insert(plots, data)
  end
  return plots
end

function BuildingLogic:GetExtraPlotModel(heroId)
  local plots = {}
  for i = 1, 3 do
    local plot = configManager.GetDataById("config_building_character_story", i)
    local data = {
      sfId = plot.ship_fleet_id,
      plotId = plot.plot_trigger_id,
      plotType = plot.plot_trigger_type
    }
    table.insert(plots, data)
  end
  local extraModel = {
    name = "e_bc_hood_sd",
    heroId = heroId,
    plots = plots
  }
  return extraModel
end

function BuildingLogic:GetBuildingPlots(buildingId)
  local modelDatas = {}
  local buildingData = Data.buildingData:GetBuildingById(buildingId)
  local normalPlots = Data.buildingData:GetNormalPlots()
  local specialPlost = Data.buildingData:GetSpecialPlots()
  local addedHero = {}
  for _, heroId in ipairs(buildingData.HeroList) do
    local data = {}
    local heroData = Data.heroData:GetHeroById(heroId)
    if heroData then
      local shipShow = Logic.shipLogic:GetShipShowByHeroId(heroData.HeroId)
      if shipShow then
        data.name = shipShow.building_model
        data.heroId = heroId
        data.buildingId = buildingId
        data.shipShowId = shipShow.ss_id
        data.plots = {}
        addedHero[heroId] = true
        local plotIds = {}
        if specialPlost and next(specialPlost) ~= nil then
          local curPlots = specialPlost[buildingId]
          if curPlots and curPlots[heroId] then
            table.insert(plotIds, curPlots[heroId])
          end
        end
        if normalPlots and next(normalPlots) ~= nil then
          local curPlots = normalPlots[buildingId]
          if curPlots and curPlots[heroId] then
            table.insert(plotIds, curPlots[heroId])
          end
        end
        for i, plotId in ipairs(plotIds) do
          local plotCfg = configManager.GetDataById("config_building_character_story", plotId)
          if plotCfg then
            local plotData = {
              buildingId = buildingId,
              heroId = heroId,
              storyId = plotId,
              sfId = plotCfg.ship_fleet_id,
              plotId = plotCfg.plot_trigger_id,
              plotType = plotCfg.plot_trigger_type
            }
            table.insert(data.plots, plotData)
          end
        end
      end
    end
    table.insert(modelDatas, data)
  end
  local specials = specialPlost[buildingId]
  if specials and next(specials) ~= nil then
    for heroId, plotId in pairs(specials) do
      if not addedHero[heroId] then
        local data = {}
        local heroData = Data.heroData:GetHeroById(heroId)
        if heroData then
          local shipShow = Logic.shipLogic:GetShipShowByHeroId(heroData.HeroId)
          if shipShow then
            data.name = shipShow.building_model
            data.shipShowId = shipShow.ss_id
            data.heroId = heroId
            data.buildingId = buildingId
            data.plots = {}
            addedHero[heroId] = true
            local plotCfg = configManager.GetDataById("config_building_character_story", plotId)
            if plotCfg then
              local plotData = {
                buildingId = buildingId,
                heroId = heroId,
                storyId = plotId,
                sfId = plotCfg.ship_fleet_id,
                plotId = plotCfg.plot_trigger_id,
                plotType = plotCfg.plot_trigger_type
              }
              table.insert(data.plots, plotData)
              table.insert(modelDatas, data)
            end
          end
        end
      end
    end
  end
  return modelDatas
end

function BuildingLogic:SetHeroAffection(heroId, addAffection, plotId)
  self.heroAffection = {
    heroId = heroId,
    affection = addAffection,
    plotId = plotId
  }
end

function BuildingLogic:GetHeroAffection()
  local heroAffection = self.heroAffection
  self.heroAffection = nil
  return heroAffection
end

function BuildingLogic:GetPresetData()
  local presetDatas = {}
  local buildingDatas = Data.buildingData:GetBuildingData()
  for bId, bData in pairs(buildingDatas) do
    presetDatas[bId] = clone(bData.TacticList)
  end
  return presetDatas
end

function BuildingLogic:RandomVideo(playingPath, key)
  local randomPaths = {}
  local randomWeights = {}
  local videoCfg = configManager.GetData("config_building_tv_res")
  for id, v in pairs(videoCfg) do
    if v.tv_res ~= playingPath and v.tv_key == key then
      table.insert(randomPaths, v.tv_res)
      table.insert(randomWeights, v.play_weight)
    end
  end
  local idx = self:RandomWeight(randomWeights)
  return randomPaths[idx]
end

function BuildingLogic:RandomWeight(weights)
  local total = 0
  for i, w in ipairs(weights) do
    total = total + w
  end
  local v = math.random(0, total - 1)
  for i, w in ipairs(weights) do
    if w > v then
      return i
    end
    v = v - w
  end
  return 1
end

function BuildingLogic:GetBuildMaxLevel(type)
  local datas = Data.buildingData:GetBuildingsByType(type)
  local max = 0
  for _, data in pairs(datas) do
    if max < data.Level then
      max = data.Level
    end
  end
  return max
end

function BuildingLogic:ClearBehaviorTreeCache()
  xlua.private_accessible(CS.BehaviorTreeCache)
  local queue = CS.BehaviorTreeCache.GetInstance().mActorCache
  for i = 1, queue.Count do
    local go = queue:Dequeue()
    GameObject.Destroy(go)
  end
  queue:Clear()
  CS.BehaviorTreeCache.GetInstance().mPrefabAsset = nil
end

function BuildingLogic:ShowOnlyLockedHero(heroList)
  local count = #heroList
  for i = count, 1, -1 do
    local heroInfo = heroList[i]
    if not heroInfo.Lock then
      table.remove(heroList, i)
    end
  end
end

return BuildingLogic
