local item2d10 = class("game2d.item2d10", Item2d)

function item2d10:Pick()
  if self.state == Item2dState.UnActive then
    return
  end
  self:SetActive(Item2dState.UnActive)
  GameManager2d:AddLife()
  GameManager2d:PlayEffect("effects/prefabs/ui/eff3d_mini_game_getitem", self:GetPos())
end

return item2d10
