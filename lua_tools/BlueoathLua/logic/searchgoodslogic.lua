local SearchGoodsLogic = class("logic.SearchGoodsLogic")
local scale_pinch = configManager.GetDataById("config_parameter", 384).arrValue
local scale_drag = configManager.GetDataById("config_parameter", 385).arrValue

function SearchGoodsLogic:initialize()
  self:ResetData()
end

function SearchGoodsLogic:ResetData()
  self.devia_x = 0
  self.devia_y = 0
  self.scale_x = 0
end

function SearchGoodsLogic:GirlPinch2D(delta, imTran, obj, tran)
  if IsNil(imTran) then
    return
  end
  local scaleFactor = delta / 500
  local localScale = imTran.localScale
  local scale = {}
  if localScale.x > 0 then
    scale = Vector3.New(localScale.x + scaleFactor, localScale.y + scaleFactor, localScale.z + scaleFactor)
  else
    scale = Vector3.New(localScale.x - scaleFactor, localScale.y + scaleFactor, localScale.z + scaleFactor)
  end
  if scale.y >= scale_pinch[1] and scale.y <= scale_pinch[2] and self:CheckScale(scale.y, scale.y, obj, tran) then
    imTran.localScale = Vector3.New(scale.x, scale.y, scale.z)
  end
end

function SearchGoodsLogic:CheckScale(scale_x, scale_y, targetTran, tran)
  local subwidth = tran.rect.width
  local subheight = tran.rect.height
  local subwidth1 = subwidth * scale_x
  local subheight1 = subheight * scale_y
  local curPosition = targetTran.transform.localPosition
  local oriPosition = self.oriPosition
  local deltaX = curPosition.x - oriPosition.x
  if deltaX < 0 then
    deltaX = -deltaX
  end
  local deltaY = curPosition.y - oriPosition.y
  if deltaY < 0 then
    deltaY = -deltaY
  end
  local deviceWidth = UIManager:GetUIWidth()
  local deviceHeight = UIManager:GetUIHeight()
  if deltaX > subwidth1 / 2 or deltaY > subheight1 / 2 then
    return false
  end
  if subwidth1 / 2 - deltaX < deviceWidth / 2 then
    return false
  end
  if subheight1 / 2 - deltaY < deviceHeight / 2 then
    return false
  end
  return true
end

function SearchGoodsLogic:CheckMove(delta_x, delta_y, targetTran, tran)
  local subwidth = tran.rect.width
  local subheight = tran.rect.height
  local subwidth1 = subwidth * targetTran.transform.localScale.x
  local subheight1 = subheight * targetTran.transform.localScale.y
  local curPosition = targetTran.transform.localPosition
  local oriPosition = self.oriPosition
  local deltaX = math.abs(curPosition.x - oriPosition.x + delta_x)
  local deltaY = math.abs(curPosition.y - oriPosition.y + delta_y)
  local deviceWidth = UIManager:GetUIWidth()
  local deviceHeight = UIManager:GetUIHeight()
  if deltaX > subwidth1 / 2 or deltaY > subheight1 / 2 then
    return false
  end
  if subwidth1 / 2 - deltaX < deviceWidth / 2 then
    return false
  end
  if subheight1 / 2 - deltaY < deviceHeight / 2 then
    return false
  end
  return true
end

function SearchGoodsLogic:GirlDrag2D(go, eventData, imTran, obj, tran)
  local delta = eventData.delta
  if not IsNil(imTran) then
    if not self:CheckMove(delta.x, delta.y, obj, tran) then
      return
    end
    local deviceWidth = UIManager:GetUIWidth()
    local deviceHeight = UIManager:GetUIHeight()
    local targetPos = imTran.localPosition
    local x = targetPos.x + delta.x
    targetPos.x = self:GetNumberBetween(x, deviceWidth * scale_drag[2], deviceWidth * scale_drag[1])
    local y = targetPos.y + delta.y
    targetPos.y = self:GetNumberBetween(y, deviceHeight * scale_drag[4], deviceHeight * scale_drag[3])
    imTran.localPosition = Vector3.New(targetPos.x, targetPos.y, 0)
  end
end

function SearchGoodsLogic:GetNumberBetween(value, min, max)
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

function SearchGoodsLogic:SetDeviation(targetTran, tran)
  local deviceWidth = UIManager:GetUIWidth()
  local deviceHeight = UIManager:GetUIHeight()
  local subwidth = tran.rect.width
  local subheight = tran.rect.height
  local subwidth1 = subwidth * targetTran.transform.localScale.x
  local subheight1 = subheight * targetTran.transform.localScale.y
  local m_Width = subwidth
  local m_Hight = subheight
  local devia_x = (subwidth1 - deviceWidth) / 2
  local devia_y = (subheight1 - deviceHeight) / 2
  if deviceWidth > subwidth1 then
    logWarning("\229\155\190\231\137\135\229\175\172\229\186\166\229\176\143\228\186\142\229\177\143\229\185\149\229\175\172\229\186\166")
    devia_x = 0
  end
  if deviceHeight > subheight1 then
    logWarning("\229\155\190\231\137\135\233\171\152\229\186\166\229\176\143\228\186\142\229\177\143\229\185\149\233\171\152\229\186\166")
    devia_y = 0
  end
  self.devia_x = devia_x
  self.devia_y = devia_y
  self.oriWidth = tran.rect.width
  self.oriHeight = tran.rect.height
  if not self.oriPosition then
    self.oriPosition = targetTran.transform.localPosition
  else
    targetTran.transform.localPosition = self.oriPosition
  end
end

function SearchGoodsLogic:CheckAndSetScale(targetTran, tran)
  local deviceWidth = UIManager:GetUIWidth()
  local deviceHeight = UIManager:GetUIHeight()
  local subwidth = tran.rect.width
  local subheight = tran.rect.height
  local ds = 1
  if deviceWidth > subwidth then
    ds = deviceWidth / subwidth + 0.01
    subwidth = subwidth * ds
    subheight = subheight * ds
  end
  local dss = 1
  if deviceHeight > subheight then
    dss = deviceHeight / subheight + 0.01
    subwidth = subwidth * dss
    subheight = subheight * dss
  end
  if deviceWidth > subwidth or deviceHeight > subheight then
    logError(" calculation error ", ds, dss)
    return
  end
  local scale = ds * dss
  if not self.scale then
    self.scale = Vector3.New(scale, scale, 1)
    targetTran.transform.localScale = self.scale
  else
    targetTran.transform.localScale = self.scale
  end
end

function SearchGoodsLogic:ChangeDeviation(scale_x, scale_y)
  self.devia_x = self.devia_x * scale_x
  self.devia_y = self.devia_y * scale_y
  return self.devia_x, self.devia_y
end

return SearchGoodsLogic
