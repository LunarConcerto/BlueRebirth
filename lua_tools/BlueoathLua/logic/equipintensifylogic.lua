local EquipIntensifyLogic = class("logic.EquipIntensifyLogic")

function EquipIntensifyLogic:initialize()
  self:ResetData()
end

function EquipIntensifyLogic:ResetData()
end

function EquipIntensifyLogic:GetExpItemIdByEquipId(equipId)
  local equip = Logic.equipLogic:GetEquipById(equipId)
  local level = equip.EnhanceLv
  local configAllNew = configManager.GetData("config_equip_enhance_item")
  for i, v in pairs(configAllNew) do
    if level >= v.enhance_level_limit[1] and level <= v.enhance_level_limit[2] then
      return v.id
    end
  end
  logError("\232\175\165\230\173\166\229\153\168\231\173\137\231\186\167\230\137\190\228\184\141\229\136\176\229\143\175\228\187\165\228\189\191\231\148\168\231\154\132\231\187\143\233\170\140\228\185\166", level)
  return
end

function EquipIntensifyLogic:GetExpItemTable(level)
  local configAllNew = configManager.GetData("config_equip_enhance_item")
  local configAll = {}
  for i, v in pairs(configAllNew) do
    if level then
      if level >= v.enhance_level_limit[1] and level <= v.enhance_level_limit[2] then
        table.insert(configAll, v)
      end
    else
      table.insert(configAll, v)
    end
  end
  table.sort(configAll, function(a, b)
    return a.exp < b.exp
  end)
  return configAll
end

function EquipIntensifyLogic:GetExpInfoByEquipId(equipId)
  local equip = Logic.equipLogic:GetEquipById(equipId)
  if equip == nil then
    logError("GetExpInfoByEquipId equip is nil. equipId:", equipId)
    return 0, 0, 0
  end
  local level = equip.EnhanceLv
  local exp = equip.EnhanceExp
  local equipMaxLv = Logic.equipLogic:GetEquipMaxLv(equip.TemplateId)
  if lock then
    equipMaxLv = Logic.equipLogic:GetLockedEquipMaxLv()
  end
  local allExp, curExp, needExp = 0, 0, 0
  if level == equipMaxLv then
    for i = 1, level - 1 do
      local tempExp = configManager.GetDataById("config_equip_enhance_level_exp", i).exp
      allExp = allExp + tempExp
    end
    if exp == nil then
      logError("GetExpInfoByEquipId equip is nil. equipId:", equipId)
      logError("GetExpInfoByEquipId equip is nil. equip:", equip)
    end
    curExp = exp - allExp
    needExp = configManager.GetDataById("config_equip_enhance_level_exp", level).exp
  elseif level < equipMaxLv then
    for i = 1, level do
      local tempExp = configManager.GetDataById("config_equip_enhance_level_exp", i).exp
      allExp = allExp + tempExp
    end
    curExp = exp - allExp
    needExp = configManager.GetDataById("config_equip_enhance_level_exp", level + 1).exp
  elseif level > equipMaxLv then
  end
  return allExp, curExp, needExp
end

function EquipIntensifyLogic:GetExpItemTableByEquipId(equipId)
  local equip = Logic.equipLogic:GetEquipById(equipId)
  local level = equip.EnhanceLv
  local allExp, curExp, expLevelUp = self:GetExpInfoByEquipId(equipId)
  local configAll = self:GetExpItemTable(level)
  return self:GetExpItemTableByExp(configAll, expLevelUp)
end

function EquipIntensifyLogic:GetExpItemTableByExp(configAll, expLevelUp)
  local result = {}
  for i = 1, #configAll do
    local config = configAll[i]
    local exp = config.exp
    local num = Logic.bagLogic:GetBagItemNum(config.id)
    local resultSub = {}
    resultSub.Id = config.id
    if 0 < num then
      if expLevelUp <= exp * num then
        resultSub.Num = math.ceil(expLevelUp / exp)
        table.insert(result, resultSub)
        return result, true
      else
        resultSub.Num = num
        table.insert(result, resultSub)
      end
    end
  end
  return result, false
end

function EquipIntensifyLogic:CheckLevelMax(equipId)
  local isMaxLevel = false
  local equip = Logic.equipLogic:GetEquipById(equipId)
  local equipInfo = configManager.GetDataById("config_equip", equip.TemplateId)
  local equipMaxStar = Logic.equipLogic:GetEquipMaxStar(equip.TemplateId)
  local curLv = equip.EnhanceLv
  local renovate
  if equipMaxStar > equip.Star then
    renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
  else
    renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star)
  end
  if curLv >= renovate.need_enhance_level and equipMaxStar > equip.Star or curLv >= equipInfo.enhance_level_max then
    isMaxLevel = true
  end
  return isMaxLevel
end

function EquipIntensifyLogic:GetBindIntensifyItems()
  local consums = {}
  local equipBreakLvConf = configManager.GetDataById("config_equip_levelbreak_item", 1)
  for _, item in ipairs(equipBreakLvConf.item_cost) do
    local consum = {}
    local type = item[1]
    local tid = item[2]
    local num = item[3]
    if type == GoodsType.CURRENCY then
      local curConf = configManager.GetDataById("config_currency", tid)
      consum.icon = curConf.icon
    elseif type == GoodsType.ITEM then
      local itemConf = configManager.GetDataById("config_item_info", tid)
      consum.icon = itemConf.icon_small
    elseif type == GoodsType.EQUIP_ENHANCE_ITEM then
      local itemConf = configManager.GetDataById("config_equip_enhance_item", tid)
      consum.icon = itemConf.icon
    end
    consum.id = tid
    consum.num = num
    consum.type = type
    table.insert(consums, consum)
  end
  return consums
end

return EquipIntensifyLogic
