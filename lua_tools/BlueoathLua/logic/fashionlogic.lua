local FashionLogic = class("logic.FashionLogic")

function FashionLogic:initialize()
  self:ResetData()
end

function FashionLogic:ResetData()
end

function FashionLogic:GetFashionDataById(id)
  local fashionData = Data.fashionData:GetFashionData()
  return fashionData[id]
end

function FashionLogic:GetFashionConfig(id)
  return configManager.GetDataById("config_fashion", id)
end

function FashionLogic:GetCurFashionData(heroId)
  local ship_fashion = Logic.shipLogic:GetShipFashioning(heroId)
  local f_config = configManager.GetDataById("config_fashion", ship_fashion)
  return f_config
end

function FashionLogic:GetDefaultFashionData(sf_id)
  local f_config = configManager.GetMultiDataByKey("config_fashion", "belong_to_ship", sf_id)
  if f_config then
    for k, v in pairs(f_config) do
      if v.is_default == 1 then
        return v
      end
    end
  end
  return nil
end

function FashionLogic:GetOwnFashion(sf_id)
  local s_data = self:GetFashionDataById(sf_id)
  local map_result = s_data and s_data.FashionTid
  map_result = map_result or {}
  local f_config = configManager.GetMultiDataByKey("config_fashion", "belong_to_ship", sf_id)
  if f_config then
    for k, v in pairs(f_config) do
      if v.is_default == 1 or v.get_type == 0 then
        map_result[v.id] = 1
      end
    end
  end
  return map_result
end

function FashionLogic:GetOwnFashionByHeroId(sf_id, heroId)
  local map_result = {}
  local s_data = self:GetFashionDataById(sf_id)
  if s_data ~= nil then
    for fashionId, v in pairs(s_data.FashionTid) do
      local fConfig = configManager.GetDataById("config_fashion", fashionId)
      if fConfig.get_id == FunctionID.Remould then
        local ownFashion = Logic.remouldLogic:CheckOwnRemouldFashion(heroId, fConfig.id)
        if ownFashion then
          map_result[fConfig.id] = 1
        end
      else
        map_result[fConfig.id] = 1
      end
    end
  end
  local f_config = configManager.GetMultiDataByKey("config_fashion", "belong_to_ship", sf_id)
  if f_config then
    for k, v in pairs(f_config) do
      if v.is_default == 1 or v.get_type == 0 then
        map_result[v.id] = 1
      end
    end
  end
  return map_result
end

function FashionLogic:CheckFashionOwn(fashion_id)
  local f_config = configManager.GetDataById("config_fashion", fashion_id)
  local sf_id = f_config.belong_to_ship
  local own_map = self:GetOwnFashion(sf_id)
  if own_map[fashion_id] then
    return true
  else
    return false
  end
end

function FashionLogic:CheckFashionOwnByHero(fashion_id, heroId)
  local f_config = configManager.GetDataById("config_fashion", fashion_id)
  local sf_id = f_config.belong_to_ship
  local own_map = self:GetOwnFashionByHeroId(sf_id, heroId)
  if own_map[fashion_id] then
    return true
  else
    return false
  end
end

function FashionLogic:GetFashionConfigData(sf_id)
  local c_data = configManager.GetMultiDataByKey("config_fashion", "belong_to_ship", sf_id)
  local result = {}
  for k, v in pairs(c_data) do
    if v.is_appear == 1 then
      table.insert(result, v)
    end
  end
  table.sort(result, function(data1, data2)
    return data1.order < data2.order
  end)
  return result
end

function FashionLogic:GetHeroByFashionId(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  local sfId = fashionCfg.belong_to_ship
  local previewHero = Data.heroData:GetHeroBySfId(sfId)
  return previewHero
end

function FashionLogic:ftos(fashionId)
  return configManager.GetDataById("config_fashion", fashionId).belong_to_ship
end

function FashionLogic:GetFashionShipName(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  local shipShow = configManager.GetDataById("config_ship_show", fashionCfg.ship_show_id)
  return shipShow and shipShow.ship_name or "FashionName"
end

function FashionLogic:GetFashionShipNameBySsId(shipShwoId)
  local shipShow = configManager.GetDataById("config_ship_show", shipShwoId)
  return shipShow and shipShow.ship_name or "FashionName"
end

function FashionLogic:GetIcon(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  return fashionCfg.icon_small
end

function FashionLogic:GetQuality(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  return fashionCfg.quality_show
end

function FashionLogic:GetName(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  return fashionCfg.name
end

function FashionLogic:GetDesc(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  return fashionCfg.description
end

function FashionLogic:GetSmallIcon(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  return fashionCfg.icon_small
end

function FashionLogic:GetFrame(fashionId)
  return "", ""
end

function FashionLogic:GetTexIcon(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  return fashionCfg.icon
end

function FashionLogic:GetFashionDraw(fashionId)
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  local shipShow = configManager.GetDataById("config_ship_show", fashionCfg.ship_show_id)
  return shipShow.ship_draw
end

function FashionLogic:GetFashionSellTip(id)
  return self:GetFashionConfig(id).fashion_showicon or ""
end

function FashionLogic:GetRemouldFashionData(sf_id, remouldLvl)
  local f_config = configManager.GetMultiDataByKey("config_fashion", "belong_to_ship", sf_id)
  if f_config then
    for _, v in pairs(f_config) do
      if v.type == remouldLvl then
        return v
      end
    end
  end
  return nil
end

return FashionLogic
