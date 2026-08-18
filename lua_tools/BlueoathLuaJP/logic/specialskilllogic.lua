local SpSkillLogic = class("logic.SpecialSkillLogic")

function SpSkillLogic:initialize()
end

function SpSkillLogic:CheckSpecialSkill(heroId, pskillId)
  local tid = Data.heroData:GetHeroById(heroId).TemplateId
  local spSkills = Logic.shipLogic:GetSpSkill(tid)
  if #spSkills <= 0 then
    return false
  end
  for _, id in ipairs(spSkills) do
    if id == pskillId then
      return true
    end
  end
  return false
end

function SpSkillLogic:SpAddHerosExp(heros, param)
  local checkHero = {}
  local medium = {}
  local temps = {}
  for i, v in ipairs(heros) do
    medium[v.heroId] = v
  end
  for index, info in ipairs(heros) do
    local check = self:CheckSpecialSkill(info.heroId, SpSkillType.ADDOTHEREXP)
    check = check and Data.heroData:GetHeroById(info.heroId).type == param
    if check then
      table.insert(checkHero, info.heroId)
    end
  end
  if 0 < #checkHero then
    for _, heroId in ipairs(checkHero) do
      local temp = self:addHerosExp(heros, heroId)
      if temp then
        table.insert(temps, temp)
      end
    end
    for _, temp in ipairs(temps) do
      for heroId, addExp in pairs(temp) do
        medium[heroId].addExp = medium[heroId].addExp + addExp
      end
    end
    for heroId, info in ipairs(medium) do
      info.addExp = math.ceil(info.addExp)
    end
    for i, v in ipairs(heros) do
      if medium[v.heroId] ~= nil then
        heros[i] = medium[v.heroId]
      end
    end
  end
end

function SpSkillLogic:addHerosExp(heros, heroId)
  local res = {}
  local lowShips = self:getSameTypeLowShips(heroId, heros)
  local highShips = self:getSameTypeHighShips(heroId, heros)
  local factor = self:getSpAddOtherExpFactor(heroId)
  local exist, item = self:checkInHeros(heros, heroId)
  if not exist then
    return nil
  end
  local addExp = item.addExp * factor
  local res = self:addOtherExp(lowShips, addExp)
  if 0 < #highShips then
    res[heroId] = #highShips * addExp
  end
  return res
end

function SpSkillLogic:addOtherExp(heros, addExp)
  local temp = {}
  for _, v in pairs(heros) do
    temp[v.heroId] = addExp
  end
  return temp
end

function SpSkillLogic:checkInHeros(heros, hero)
  for i, v in ipairs(heros) do
    if v.heroId == hero then
      return true, v
    end
  end
  return false, nil
end

function SpSkillLogic:getSameTypeLowShips(heroId, heros)
  local info = Data.heroData:GetHeroById(heroId)
  local typ = info.type
  local lv = info.Lvl
  local res = {}
  for i, v in ipairs(heros) do
    if v.heroId ~= heroId then
      local heroInfo = Data.heroData:GetHeroById(v.heroId)
      if heroInfo.type == typ and lv > heroInfo.Lvl then
        table.insert(res, v)
      end
    end
  end
  return res
end

function SpSkillLogic:getSameTypeHighShips(heroId, heros)
  local info = Data.heroData:GetHeroById(heroId)
  local typ = info.type
  local lv = info.Lvl
  local res = {}
  for i, v in ipairs(heros) do
    if v.heroId ~= heroId then
      local heroInfo = Data.heroData:GetHeroById(v.heroId)
      if heroInfo.type == typ and lv <= heroInfo.Lvl then
        table.insert(res, v)
      end
    end
  end
  return res
end

function SpSkillLogic:getSpAddOtherExpFactor(heroId)
  local lv = Logic.shipLogic:GetHeroPSkillLv(heroId, SpSkillType.ADDOTHEREXP)
  local config = configManager.GetDataById("config_pskill_sp_talent", 2)
  return (config.val_init + (lv - 1) * config.val_add) / 10000
end

return SpSkillLogic
