local area2d = class("game2d.area2d")

function area2d:initialize(id)
  self.id = id
  local config = configManager.GetDataById("config_minigame_special_area", id)
  self.buff_id = config.buff_id
  self.lbx = config.area[1][1]
  self.lby = config.area[2][1]
  self.rtx = config.area[1][2]
  self.rty = config.area[2][2]
end

function area2d:IsPointInside(px, py)
  return Logic2d:IsInsideRect(px, py, self.lbx, self.lby, self.rtx, self.rty)
end

return area2d
