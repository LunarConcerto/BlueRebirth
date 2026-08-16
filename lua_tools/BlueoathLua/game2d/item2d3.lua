local item2d3 = class("game2d.item2d3", Item2d)

function item2d3:Use()
  PlayerManager2d:SetItemId(0)
  local npc = NpcManager2d:GetPlayerNearest()
  if npc then
    npc:SetCheeseId(self.id)
  else
    logError("find no npc to cheese")
  end
end

return item2d3
