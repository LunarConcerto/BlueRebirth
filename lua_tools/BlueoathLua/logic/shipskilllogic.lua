local ShipSkillLogic = class("logic.ShipSkillLogic")

function ShipSkillLogic:CheckMaterials(heroId, skillId, isNoti)
  local isMax = Logic.shipLogic:CheckHeroPSkillReachMax(heroId, skillId)
  if isMax then
    return false
  end
  local level = Logic.shipLogic:GetHeroPSkillLv(heroId, skillId)
  local materials = Logic.shipLogic:GetPSkillMaterials(skillId)
  local material = materials[level]
  if material == nil then
    logError("yl hero skill level:%s error", level)
    return false
  end
  local typ = material[1]
  local id = material[2]
  local num = material[3]
  local numHave = Logic.bagLogic:GetBagItemNum(id)
  if num > numHave and isNoti then
    local name = Logic.goodsLogic:GetName(id, typ)
    noticeManager:ShowTipById(440002, name)
    globalNoitceManager:ShowItemInfoPage(typ, id)
  end
  return num <= numHave
end

return ShipSkillLogic
