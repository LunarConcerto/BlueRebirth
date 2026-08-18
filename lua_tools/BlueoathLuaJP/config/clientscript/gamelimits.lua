function ScriptExample(user, params, ProgramParam)
  logError("ScriptExample")
end

function PlayerCurrency(user, params)
  local PlayerCurrency = user:GetCurrency(params[1])
  if PlayerCurrency >= params[2] and PlayerCurrency <= params[3] then
    return true
  else
    return false
  end
end

function PlayerDailyCurrencyCost(user, params)
  local PlayerDailyCurrencyCost = user:DailyCurrencyCost(params[1])
  if PlayerDailyCurrencyCost >= params[2] and PlayerDailyCurrencyCost <= params[3] then
    return true
  else
    return false
  end
end

function TeamRequireQualityTypeCount(user, params, fleetId, typ)
  local lenParams = #params
  if lenParams == 0 then
    return false
  end
  local fleet = user:GetShipTableByFleet(fleetId, typ)
  local ret = 0
  for _, heroId in pairs(fleet) do
    if 0 < heroId then
      local tmp = user:GetQualityByHeroId(heroId)
      local type1 = user:GetTypeByHeroId(heroId)
      if tmp >= params[1] then
        for i = 3, #params do
          if type1 == params[i] then
            ret = ret + 1
            break
          end
        end
      end
    end
  end
  return valueCompare(3, ret, params[2])
end

function TacticsRequire(user, params, fleetId, typ)
  local lenParams = #params
  local fleet = user:GetShipTableByFleet(fleetId, typ)
  local nCount = 0
  if lenParams < 2 then
    logError("\233\133\141\232\161\168\231\188\186\229\176\145\229\143\130\230\149\176")
    return false
  elseif lenParams == 2 then
    for k, heroId in pairs(fleet) do
      if 0 < heroId then
        nCount = nCount + 1
      end
    end
    return valueCompare(params[1], nCount, params[2])
  else
    for k, heroId in pairs(fleet) do
      if 0 < heroId then
        local tmp = user:GetTypeByHeroId(heroId)
        for i = 3, #params do
          if tmp == params[i] then
            nCount = nCount + 1
            break
          end
        end
      end
    end
    return valueCompare(params[1], nCount, params[2])
  end
end

function CopyThrough(user, params)
  if #params ~= 2 then
    return false, nil, 0
  elseif user:IsPassLBCopy(params[1], params[2]) == true then
    return true, nil, 1
  else
    return false, nil, 0
  end
end

function PlayerLevel(user, params)
  local playerLevel = user:GetLevel()
  if playerLevel >= params[1] and playerLevel <= params[2] then
    return true
  else
    return false
  end
end

function TeamRequireTypeCombination(user, params, fleetId, typ)
  local lenParams = #params
  if lenParams == 0 then
    return true
  end
  local fleet = user:GetShipTableByFleet(fleetId, typ)
  local fleetType = {}
  for _, heroId in pairs(fleet) do
    if 0 < heroId then
      local tmp = user:GetTypeByHeroId(heroId)
      fleetType[tmp] = tmp
    end
  end
  return tableInclude(params, fleetType)
end

function TeamRequireShipInfoCombination(user, params, fleetId, typ)
  local lenParams = #params
  if lenParams == 0 then
    return true
  end
  local fleet = user:GetShipTableByFleet(fleetId, typ)
  local fleetInfoType = {}
  for _, heroId in pairs(fleet) do
    if 0 < heroId then
      local tmp = user:GetInfoIdByHeroId(heroId)
      fleetInfoType[tmp] = tmp
    end
  end
  return tableInclude(params, fleetInfoType)
end

function TeamRequireBreakLevelCount(user, params, fleetId, typ)
  local lenParams = #params
  if lenParams == 0 then
    return true
  end
  local fleet = user:GetShipTableByFleet(fleetId, typ)
  local ret = 0
  for _, heroId in pairs(fleet) do
    if 0 < heroId then
      local tmp = user:GetAdvanceByHeroId(heroId)
      if tmp >= params[1] then
        ret = ret + 1
      end
    end
  end
  if ret >= params[2] then
    return true
  else
    return false
  end
end

function TeamRequireQualityCount(user, params, fleetId, typ)
  local lenParams = #params
  if lenParams == 0 then
    return true
  end
  local fleet = user:GetShipTableByFleet(fleetId, typ)
  local ret = 0
  for _, heroId in pairs(fleet) do
    if 0 < heroId then
      local tmp = user:GetQualityByHeroId(heroId)
      if tmp >= params[1] then
        ret = ret + 1
      end
    end
  end
  if ret >= params[2] then
    return true
  else
    return false
  end
end

function TeamRequireBreakLevelQualityCount(user, params, fleetId, typ)
  local lenParams = #params
  if lenParams == 0 then
    return true
  end
  local fleet = user:GetShipTableByFleet(fleetId, typ)
  local ret = 0
  for _, heroId in pairs(fleet) do
    if 0 < heroId then
      local tmp = user:GetQualityByHeroId(heroId)
      local tmp1 = user:GetAdvanceByHeroId(heroId)
      if tmp >= params[1] and tmp1 > params[2] then
        ret = ret + 1
      end
    end
  end
  if ret >= params[3] then
    return true
  else
    return false
  end
end

function UseTactics(user, params)
  local lenParams = #params
  local tmp = user:GetStrategyIdInBattle()
  if lenParams == 0 then
    return false
  elseif lenParams == 1 then
    if tmp == params[1] then
      return true
    else
      return false
    end
  else
    for _, v in pairs(params) do
      if v == tmp then
        return true
      end
    end
    return false
  end
end

function CumulativeRecharge(user, params)
  local tmp = user:GetAccRechargeRmb()
  return tmp >= params[1]
end

function ShopGoodsNeedDailyCopyThrough(user, params)
  return user:GetCopyPassLock(params[1])
end

function TowerThroughLevel(user, params)
  local level = user:GetTowerLevel()
  return level > params[1]
end

function tableInclude(t1, t2)
  local set = {}
  for _, v in pairs(t1) do
    set[v] = false
  end
  for k, v in pairs(set) do
    for _, ret in pairs(t2) do
      if ret == k then
        set[v] = true
      end
    end
  end
  for _, v in pairs(set) do
    if v == false then
      return false
    end
  end
  return true
end

function CheckGoodsBuyNumLimit(user, params)
  local goodId = params[1]
  local limitNum = params[2]
  local ownNum = user:GetBagItemsNumById(goodId)
  return limitNum > ownNum
end

function valueCompare(operator, leftValue, rightValue)
  if operator == 0 then
    if leftValue == rightValue then
      return true
    else
      return false
    end
  elseif operator == 1 then
    if rightValue < leftValue then
      return true
    else
      return false
    end
  elseif operator == 2 then
    if leftValue < rightValue then
      return true
    else
      return false
    end
  elseif operator == 3 then
    if rightValue <= leftValue then
      return true
    else
      return false
    end
  elseif operator == 4 then
    if leftValue <= rightValue then
      return true
    else
      return false
    end
  elseif operator == 5 then
    if leftValue ~= rightValue then
      return true
    else
      return false
    end
  else
    logError("\232\191\144\231\174\151\231\172\166\231\177\187\229\158\139\230\156\170\229\174\154\228\185\137")
    return false
  end
end
