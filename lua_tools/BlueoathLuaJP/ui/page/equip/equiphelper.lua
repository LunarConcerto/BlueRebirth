EquipHelper = {}

local function EquipFiler(equips, condition)
  local res = {}
  for _, equip in pairs(equips) do
    if condition(equip) then
      table.insert(res, equip)
    end
  end
  return res
end

EquipHelper.EquipFiler = EquipFiler
EquipHelper.TypeMatchOutput = TypeMatchOutput
return EquipHelper
