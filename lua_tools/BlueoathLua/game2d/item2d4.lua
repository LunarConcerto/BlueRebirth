local item2d4 = class("game2d.item2d4", Item2d)

function item2d4:Pick()
  if self.state == Item2dState.UnActive then
    return
  end
  self:SetActive(Item2dState.UnActive)
  local config = configManager.GetDataById("config_minigame_item", self.itemId)
  PlayerManager2d:SetTimeByBuffId(config.buff_id[1])
end

function item2d4:Use()
end

return item2d4
