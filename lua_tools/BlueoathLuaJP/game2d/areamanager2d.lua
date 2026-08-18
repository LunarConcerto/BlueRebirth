local areaManager2d = class("game2d.areaManager2d")

function areaManager2d:InitData()
  self.areas = {}
  local gameConfig = GameManager2d:GetConfig()
  self.area_ids = gameConfig.special_area
  for i, v in ipairs(self.area_ids) do
    self.areas[i] = require("game2d.area2d"):new(v)
  end
end

function areaManager2d:CheckBuffByPosition(px, py)
  local buff_by_in_area = {}
  local buff_by_outside_area = {}
  for i, v in ipairs(self.areas) do
    if v:IsPointInside(px, py) then
      table.insert(buff_by_in_area, v.buff_id)
    else
      table.insert(buff_by_outside_area, v.buff_id)
    end
  end
  return buff_by_in_area, buff_by_outside_area
end

function areaManager2d:RefreshPlayerBuff()
  local pos = PlayerManager2d.player.localPosition
  local buff_by_in_area, buff_by_outside_area = self:CheckBuffByPosition(pos.x, pos.y)
  for i, v in ipairs(buff_by_outside_area) do
    PlayerManager2d:DelBuffWithoutEff(v)
  end
  for i, v in ipairs(buff_by_in_area) do
    PlayerManager2d:AddBuffWithoutEff(v)
  end
end

return areaManager2d
