local ShipSkillLogic = class("logic.ShipSkillLogic")

function ShipSkillLogic:CheckMaterials(heroId, skillId, isNoti)
  local isMax = Logic.shipLogic:CheckHeroPSkillReachMax(heroId, skillId)
  if isMax then
    return false
  end
  local level = Logic.shipLogic:GetHeroPSkillLv(heroId, skillId)
  local sortMaterial = self:SortSkillMaterial(level, skillId)
  for _, material in ipairs(sortMaterial) do
    local typ = material[1]
    local id = material[2]
    local num = material[3]
    local numHave = Logic.bagLogic:GetBagItemNum(id)
    if num > numHave then
      if isNoti then
        local name = Logic.goodsLogic:GetName(id, typ)
        noticeManager:ShowTipById(440002, name)
        globalNoitceManager:ShowItemInfoPage(typ, id)
      end
      return false
    end
  end
  return true
end

function ShipSkillLogic:SortSkillMaterial(level, skillId)
  local materials, materialsmub = Logic.shipLogic:GetPSkillMaterials(skillId)
  local levelShow = math.min(level, #materials)
  local material = materials[levelShow]
  local tmp = {}
  if material == nil then
    logError("yl hero skill level:%s skillId:%d error", level, skillId)
    return tmp
  end
  table.insert(tmp, material)
  if #materialsmub ~= 0 and #materialsmub[levelShow] ~= 0 then
    for _, v in ipairs(materialsmub[levelShow]) do
      table.insert(tmp, v)
    end
  end
  return tmp
end

return ShipSkillLogic
