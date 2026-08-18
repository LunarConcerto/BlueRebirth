local item2d7 = class("game2d.item2d7", Item2d)

function item2d7:Pick()
  if self.state == Item2dState.UnActive then
    return
  end
  self:SetActive(Item2dState.UnActive)
  local config = configManager.GetDataById("config_minigame_item", self.itemId)
  local index = math.random(1, #config.buff_id)
  PlayerManager2d:SetTimeByBuffId(config.buff_id[index])
end

function item2d7:Use()
end

return item2d7
