local DevelopLogic = class("logic.DevelopLogic")
local reward = Logic.rewardLogic

function DevelopLogic:initialize()
  self:ConstantAndEnum()
  self:ResetData()
end

function DevelopLogic:ConstantAndEnum()
  self.E_HeroLvState = {
    LEVELUP = 0,
    FURTHER = 1,
    FULL = 4
  }
end

function DevelopLogic:ResetData()
  self.m_bselect = {}
  self.m_bhero = 0
end

function DevelopLogic:SetBSelect(selects, hero)
  local res = {}
  for _, id in ipairs(selects) do
    if Data.heroData:VerifyHero(id) then
      table.insert(res, id)
    end
  end
  self.m_bselect = res
  self.m_bhero = hero
end

function DevelopLogic:GetBSelect(hero)
  if hero == self.m_bhero then
    local res = {}
    for _, id in ipairs(self.m_bselect) do
      if Data.heroData:VerifyHero(id) then
        table.insert(res, id)
      end
    end
    self.m_bselect = res
    return res
  else
    return {}
  end
end

function DevelopLogic:ResetBSelect(force, heroId)
  if force or heroId ~= self.m_bhero then
    self.m_bhero = 0
    self.m_bselect = {}
    return true
  end
  return false
end

function DevelopLogic:GetHeroMaxLv()
  return configManager.GetDataById("config_parameter", 70).value
end

function DevelopLogic:GetHeroBaseMaxLv()
  return self:GetLHeroFurtherConfig(1).initial_level
end

function DevelopLogic:GetLFurtherCost(tid, cid)
  local config = self:_GetShipMainConfigById(tid)
  if config and config.unlock_item and config.unlock_item[cid] then
    return config.unlock_item[cid]
  else
    logError("get hero further cost err!!! please check shipmain config,id:" .. tid)
    return {}
  end
end

function DevelopLogic:GetLFurtherMax(cid)
  local config = self:GetLHeroFurtherConfig(cid)
  return config and config.max_level or self:GetHeroBaseMaxLv()
end

function DevelopLogic:GetLHeroState(heroId)
  local state = self.E_HeroLvState
  local ok, data = Data.heroData:VerifyHero(heroId)
  if ok then
    local cid = Data.heroData:GetHeroLFurtherId(heroId)
    local max = self:GetHeroMaxLv()
    local min = self:GetHeroBaseMaxLv()
    local lv = data.Lvl
    local configs = configManager.GetData("config_ship_advance")
    if max <= lv then
      return state.FULL
    elseif min > lv then
      return state.LEVELUP
    else
      local minlv, maxlv
      for id, config in pairs(configs) do
        minlv, maxlv = config.initial_level, config.max_level
        if lv >= minlv and lv <= maxlv then
          if lv >= minlv and id > cid or maxlv == lv and id == cid then
            return state.FURTHER, id
          end
          if id == cid then
            return state.LEVELUP
          end
        end
      end
      logError("hero lv further stage config no match, this is fatal err!!! hero data:" .. printTable(data))
      return state.LEVELUP
    end
  else
    logError("invalid heroId:" .. heroId)
    return state.LEVELUP
  end
end

function DevelopLogic:GetLHeroFurtherConfig(cid)
  return configManager.GetDataById("config_ship_advance", cid)
end

function DevelopLogic:CanLFurther(heroId)
  local state, cid = self:GetLHeroState(heroId)
  local ok, hero = Data.heroData:VerifyHero(heroId)
  if not ok then
    return false
  end
  return state == self.E_HeroLvState.FURTHER and self:_CheckCosts(hero.TemplateId, cid)
end

function DevelopLogic:CheckLFurther(heroId, cid)
  local ok, hero = Data.heroData:VerifyHero(heroId)
  if not ok then
    return false, UIHelper.GetString(911008)
  end
  if not self:GetLHeroFurtherConfig(cid) then
    return false, UIHelper.GetString(911009)
  end
  local state = self:GetLHeroState(heroId)
  if state ~= self.E_HeroLvState.FURTHER then
    return false, UIHelper.GetString(911010)
  end
  return self:_CheckCosts(hero.TemplateId, cid)
end

function DevelopLogic:FormatLFurtherCost(cost)
  local res = {}
  res.Type = cost[1]
  res.ConfigId = cost[2]
  local cur = reward:GetPossessNum(cost[1], cost[2])
  res.Num = cur .. "/" .. cost[3]
  return res, cur >= cost[3]
end

function DevelopLogic:_GetShipMainConfigById(tid)
  return configManager.GetDataById("config_ship_main", tid)
end

function DevelopLogic:_CheckCosts(tid, cid)
  local costs = self:GetLFurtherCost(tid, cid)
  local cur = 0
  for _, cost in pairs(costs) do
    cur = reward:GetPossessNum(cost[1], cost[2])
    if cur < cost[3] then
      if cost[1] == GoodsType.CURRENCY and cost[2] == CurrencyType.GOLD then
        return false, UIHelper.GetString(180004)
      else
        return false, cost
      end
    end
  end
  return true, ""
end

function DevelopLogic:TEST_GetLHeroState(lv, cid)
  local state = self.E_HeroLvState
  local max = self:GetHeroMaxLv()
  local min = self:GetHeroBaseMaxLv()
  local configs = configManager.GetData("config_ship_advance")
  if lv >= max then
    return state.FULL
  elseif lv < min then
    return state.LEVELUP
  else
    local minlv, maxlv
    for id, config in pairs(configs) do
      minlv, maxlv = config.initial_level, config.max_level
      if lv >= minlv and lv <= maxlv then
        logError(min .. " " .. max .. " " .. lv .. " " .. cid)
        if minlv == lv and cid < id or maxlv == lv and id == cid then
          return state.FURTHER, id
        end
        if id == cid then
          return state.LEVELUP
        end
      end
    end
    logError("hero lv further stage config no match, this is fatal err!!! hero data:" .. printTable(data))
    return state.LEVELUP
  end
end

return DevelopLogic
