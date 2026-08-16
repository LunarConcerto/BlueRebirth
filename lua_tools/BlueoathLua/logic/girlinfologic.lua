local GirlInfoLogic = class("logic.GirlInfoLogic")
local scale_pinch = configManager.GetDataById("config_parameter", 87).arrValue
local scale_drag = configManager.GetDataById("config_parameter", 88).arrValue

function GirlInfoLogic:initialize()
  self:ResetData()
end

function GirlInfoLogic:ResetData()
  self.equipOpen = false
  self.is3D = false
  self.lastTogIndex = 1
  self.mapHero = {}
end

function GirlInfoLogic:SetLastTogIndex(lastTogIndex)
  self.lastTogIndex = lastTogIndex
end

function GirlInfoLogic:GetLastTogIndex()
  return self.lastTogIndex
end

function GirlInfoLogic:SetIs3D(is3D)
  self.is3D = is3D
end

function GirlInfoLogic:GetIs3D()
  return self.is3D
end

function GirlInfoLogic:SetEquipPageState(val)
  self.equipOpen = val
end

function GirlInfoLogic:GetEquipPageState()
  return self.equipOpen
end

function GirlInfoLogic:GirlPinch2D(delta, trans, heroId)
  if IsNil(trans) then
    return
  end
  local scaleSize = configManager.GetDataById("config_ship_position", heroId).ship_scale3 / 10000
  local scaleFactor = delta / 500
  local localScale = trans.localScale
  local scale = {}
  if localScale.x > 0 then
    scale = Vector3.New(localScale.x + scaleFactor, localScale.y + scaleFactor, localScale.z + scaleFactor)
  else
    scale = Vector3.New(localScale.x - scaleFactor, localScale.y + scaleFactor, localScale.z + scaleFactor)
  end
  if scale.y >= scale_pinch[1] and scale.y <= scale_pinch[2] then
    trans.localScale = Vector3.New(scale.x, scale.y, scale.z)
  end
end

function GirlInfoLogic:GirlDrag2D(go, eventData, targetTran)
  local delta = eventData.delta
  if not IsNil(targetTran) then
    local deviceWidth = UIManager:GetUIWidth()
    local deviceHeight = UIManager:GetUIHeight()
    local targetPos = targetTran.localPosition
    local x = targetPos.x + delta.x
    targetPos.x = self:GetNumberBetween(x, deviceWidth * scale_drag[2], deviceWidth * scale_drag[1])
    local y = targetPos.y + delta.y
    targetPos.y = self:GetNumberBetween(y, deviceHeight * scale_drag[4], deviceHeight * scale_drag[3])
    targetTran.localPosition = Vector3.New(targetPos.x, targetPos.y, 0)
  end
end

function GirlInfoLogic:GetNumberBetween(value, min, max)
  if max <= min then
    logError("max less then min")
    return value
  end
  if max < value then
    return max
  elseif value < min then
    return min
  else
    return value
  end
end

function GirlInfoLogic:SetMapHeroByMood(mapHero)
  self.mapHero = mapHero
end

function GirlInfoLogic:GetMapHeroByMood()
  return self.mapHero
end

function GirlInfoLogic:CheckStrengthenLock(heroId)
  local shipInfo = Data.heroData:GetHeroById(heroId)
  local sf_id = Logic.shipLogic:GetHeroSFIdByTemplateId(shipInfo.TemplateId)
  local sf_config = configManager.GetDataById("config_ship_fleet", sf_id)
  return sf_config.power_type == 1
end

return GirlInfoLogic
