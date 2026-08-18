local ShipCombinationLogic = class("logic.ShipCombinationLogic")
local MAXCOMBINELV = 100
local MAXHeroADVANCE = 6

function ShipCombinationLogic:initialize()
end

function ShipCombinationLogic:ResetData()
end

function ShipCombinationLogic:GetCombineData(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    local allHero = Data.heroData:GetHeroData()
    logError("\230\156\170\230\137\190\229\136\176\232\136\176\229\168\152\239\188\140\232\136\176\229\168\152id:", heroId, allHero)
    return
  end
  if table.nums(heroInfo.CombinationInfo) == 0 then
    heroInfo.CombinationInfo = {
      ComLv = 0,
      ComGrade = 0,
      Combine = 0,
      BeCombined = 0
    }
  end
  return heroInfo.CombinationInfo
end

function ShipCombinationLogic:GetCombineConf(heroId, combineLv)
  local nowCombConf, nextCombConf
  if combineLv <= 0 or combineLv > MAXCOMBINELV then
    logError("\228\188\160\229\133\165\231\154\132\229\133\177\233\184\163\231\173\137\231\186\167\228\184\141\229\175\185,heroId:%d,combineLv:%d", heroId, combineLv)
    return nil
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local shipFleetId = heroInfo.fleetId
  if Logic.shipLogic:CheckShipCanCombine(heroId) then
    local confId = shipFleetId * 100 + (combineLv - 1) / 10
    confId = math.floor(confId)
    nowCombConf = configManager.GetDataById("config_combination_ship", confId)
    if nowCombConf and 0 < nowCombConf.next_id then
      nextCombConf = configManager.GetDataById("config_combination_ship", nowCombConf.next_id)
    end
  end
  if nowCombConf == nil then
    logError("\229\133\177\233\184\163\233\133\141\231\189\174\230\156\170\232\142\183\229\143\150\229\136\176\239\188\140\230\163\128\230\181\139\232\175\165\232\139\177\233\155\132\230\152\175\229\144\166\232\131\189\229\164\159\229\188\128\229\144\175\229\133\177\233\184\163\239\188\140shipFleetId:%d", shipFleetId)
  end
  return clone(nowCombConf), clone(nextCombConf)
end

function ShipCombinationLogic:GetCombineConfBySs_id(ss_id)
  local shipShowConf = Logic.shipLogic:GetShipShowConfig(ss_id)
  local shipFleetId = shipShowConf.sf_id
  local advanceLv = MAXHeroADVANCE
  local shipCombineLv = MAXCOMBINELV
  local canCombine = configManager.GetDataById("config_ship_fleet", shipFleetId).combination_open == 1
  if not canCombine then
    logError("\233\133\141\231\189\174\232\142\183\229\143\150\229\164\177\232\180\165\239\188\140\230\163\128\230\159\165\232\175\165\232\136\176\229\168\152\230\152\175\229\144\166\232\131\189\229\164\159\229\188\128\229\144\175\229\133\177\233\184\163\239\188\140fleetId:%d", shipFleetId)
    return nil
  end
  local confId = shipFleetId * 100 + (MAXCOMBINELV - 1) / 10
  confId = math.floor(confId)
  local combConf = configManager.GetDataById("config_combination_ship", confId)
  return clone(combConf)
end

function ShipCombinationLogic:CheckIsOpenCombine(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  local combinationTab = heroInfo.CombinationInfo
  return combinationTab.ComLv > 0
end

function ShipCombinationLogic:IfBreakUp(heroId, combineLv)
  local combConf, nextConf = self:GetCombineConf(heroId, combineLv)
  if combConf == nil or nextConf == nil then
    return false
  end
  local combinationTab = self:GetCombineData(heroId)
  local breakLevel = combinationTab.ComGrade
  return breakLevel ~= combConf.star and nextConf and breakLevel == nextConf.star
end

function ShipCombinationLogic:GetCombAttrTab(heroId, combineLv)
  local shipCombineLv = combineLv
  local combConf, nextConf = self:GetCombineConf(heroId, combineLv)
  if combConf == nil then
    return {}, {}
  end
  local propBaseTab = combConf.break_prop_up
  local propUpTab = combConf.prop_up
  local propBasePercentTab = combConf.break_prop_up_percent
  local propUpPercentTab = combConf.prop_up_percent
  local curStage = combConf.star
  local sameKindConf = configManager.GetMultiDataByKey("config_combination_ship", "sf_id", combConf.sf_id)
  for _, conf in pairs(sameKindConf) do
    if conf.sf_id == combConf.sf_id and curStage > conf.star then
      for _, propBaseInfo in pairs(propBaseTab) do
        for _, upInfo in pairs(conf.break_prop_up) do
          if propBaseInfo[1] == upInfo[1] then
            propBaseInfo[2] = propBaseInfo[2] + upInfo[2]
          end
        end
        for _, upInfo in pairs(conf.prop_up) do
          if propBaseInfo[1] == upInfo[1] then
            propBaseInfo[2] = propBaseInfo[2] + upInfo[2] * 10
          end
        end
      end
      for _, propBasePercentInfo in pairs(propBasePercentTab) do
        for _, upInfo in pairs(conf.break_prop_up_percent) do
          if propBasePercentInfo[1] == upInfo[1] then
            propBasePercentInfo[2] = propBasePercentInfo[2] + upInfo[2]
          end
        end
        for _, upInfo in pairs(conf.prop_up_percent) do
          if propBasePercentInfo[1] == upInfo[1] then
            propBasePercentInfo[2] = propBasePercentInfo[2] + upInfo[2] * 10
          end
        end
      end
    end
  end
  local stageLv = shipCombineLv % 10 == 0 and 10 or shipCombineLv % 10
  for _, propBaseInfo in pairs(propBaseTab) do
    for _, propUpInfo in pairs(propUpTab) do
      if propBaseInfo[1] == propUpInfo[1] then
        propBaseInfo[2] = propBaseInfo[2] + propUpInfo[2] * stageLv
        break
      end
    end
  end
  for _, propBasePercentInfo in pairs(propBasePercentTab) do
    for _, propUpInfo in pairs(propUpPercentTab) do
      if propBasePercentInfo[1] == propUpInfo[1] then
        propBasePercentInfo[2] = propBasePercentInfo[2] + propUpInfo[2] * stageLv
        break
      end
    end
  end
  if self:IfBreakUp(heroId, combineLv) then
    for _, propBaseInfo in pairs(propBaseTab) do
      for _, v in pairs(nextConf.break_prop_up) do
        if propBaseInfo[1] == v[1] then
          propBaseInfo[2] = propBaseInfo[2] + v[2]
        end
      end
    end
    for _, propBasePercentInfo in pairs(propBasePercentTab) do
      for _, v in pairs(nextConf.break_prop_up_percent) do
        if propBasePercentInfo[1] == v[1] then
          propBasePercentInfo[2] = propBasePercentInfo[2] + v[2]
        end
      end
    end
  end
  return propBaseTab, propBasePercentTab
end

function ShipCombinationLogic.GetCombineAttrBuff(heroId)
  local ret = {}
  local buffInfo = {}
  if heroId then
    local combineData = Logic.shipCombinationLogic:GetCombineData(heroId)
    if combineData.Combine == nil or combineData.Combine <= 0 then
      return {}
    end
    local combHero = Data.heroData:GetHeroById(combineData.Combine)
    if combHero == nil then
      return {}
    end
    local otherCombineDate = Logic.shipCombinationLogic:GetCombineData(combineData.Combine)
    local _, percentTab = Logic.shipCombinationLogic:GetCombAttrTab(combineData.Combine, otherCombineDate.ComLv)
    for _, info in pairs(percentTab) do
      buffInfo = configManager.GetDataById("config_value_effect", info[1])
      table.insert(ret, {
        power = info[2],
        values = buffInfo.values
      })
    end
  end
  return ret
end

function ShipCombinationLogic:GetCombAttrTabBySs_id(ss_Id)
  local shipCombineLv = MAXCOMBINELV
  local combConf = self:GetCombineConfBySs_id(ss_Id)
  if combConf == nil then
    return {}, {}
  end
  local propBaseTab = combConf.break_prop_up
  local propUpTab = combConf.prop_up
  local propBasePercentTab = combConf.break_prop_up_percent
  local propUpPercentTab = combConf.prop_up_percent
  local curStage = combConf.star
  local sameKindConf = configManager.GetMultiDataByKey("config_combination_ship", "sf_id", combConf.sf_id)
  for _, conf in pairs(sameKindConf) do
    if conf.sf_id == combConf.sf_id and curStage > conf.star then
      for _, propBaseInfo in pairs(propBaseTab) do
        for _, upInfo in pairs(conf.break_prop_up) do
          if propBaseInfo[1] == upInfo[1] then
            propBaseInfo[2] = propBaseInfo[2] + upInfo[2]
          end
        end
        for _, upInfo in pairs(conf.prop_up) do
          if propBaseInfo[1] == upInfo[1] then
            propBaseInfo[2] = propBaseInfo[2] + upInfo[2] * 10
          end
        end
      end
      for _, propBasePercentInfo in pairs(propBasePercentTab) do
        for _, upInfo in pairs(conf.break_prop_up_percent) do
          if propBasePercentInfo[1] == upInfo[1] then
            propBasePercentInfo[2] = propBasePercentInfo[2] + upInfo[2]
          end
        end
        for _, upInfo in pairs(conf.prop_up_percent) do
          if propBasePercentInfo[1] == upInfo[1] then
            propBasePercentInfo[2] = propBasePercentInfo[2] + upInfo[2] * 10
          end
        end
      end
    end
  end
  local stageLv = 10
  for _, propBaseInfo in pairs(propBaseTab) do
    for _, propUpInfo in pairs(propUpTab) do
      if propBaseInfo[1] == propUpInfo[1] then
        propBaseInfo[2] = propBaseInfo[2] + propUpInfo[2] * stageLv
        break
      end
    end
  end
  for _, propBasePercentInfo in pairs(propBasePercentTab) do
    for _, propUpInfo in pairs(propUpPercentTab) do
      if propBasePercentInfo[1] == propUpInfo[1] then
        propBasePercentInfo[2] = propBasePercentInfo[2] + propUpInfo[2] * stageLv
        break
      end
    end
  end
  return propBaseTab, propBasePercentTab
end

function ShipCombinationLogic:GetNextAddAttrTab(heroId, combineLv)
  local combConf, nextConf = self:GetCombineConf(heroId, combineLv)
  local nextAddPropTab = {}
  local nextAddPropPercentTab = {}
  if self:IfBreakUp(heroId, combineLv) then
    if nextConf then
      nextAddPropTab = nextConf.prop_up
      nextAddPropPercentTab = nextConf.prop_up_percent
    end
  else
    local stageLv = combineLv % 10 == 0 and 10 or combineLv % 10
    if combineLv < MAXCOMBINELV then
      if stageLv < 10 then
        nextAddPropTab = combConf.prop_up
        nextAddPropPercentTab = combConf.prop_up_percent
      elseif nextConf then
        nextAddPropTab = nextConf.break_prop_up
        nextAddPropPercentTab = nextConf.break_prop_up_percent
      end
    end
  end
  return nextAddPropTab, nextAddPropPercentTab
end

function ShipCombinationLogic:IfCombining(heroId)
  local combineData = self:GetCombineData(heroId)
  return combineData.BeCombined > 0
end

return ShipCombinationLogic
