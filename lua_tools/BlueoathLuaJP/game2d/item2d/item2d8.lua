local item2d8 = class("game2d.item2d8", Item2d)

function item2d8:Pick()
  local config = configManager.GetDataById("config_minigame_item", self.itemId)
  local pos = config.p1
  PlayerManager2d:SetPlayerPos(Vector3.New(pos[1], pos[2], pos[2]))
end

return item2d8
