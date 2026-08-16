local item2d9 = class("game2d.item2d9", Item2d)

function item2d9:Pick()
  if self.state == Item2dState.UnActive then
    return
  end
  self:SetActive(Item2dState.UnActive)
  GameManager2d:Pick(self.itemId)
  GameManager2d:PlayEffect("effects/prefabs/ui/eff3d_mini_game_getitem", self:GetPos())
end

return item2d9
