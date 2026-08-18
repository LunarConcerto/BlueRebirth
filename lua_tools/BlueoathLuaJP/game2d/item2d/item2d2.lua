local item2d2 = class("game2d.item2d2", Item2d)

function item2d2:Use()
  local config = configManager.GetDataById("config_minigame_item", self.itemId)
  local playerPos = PlayerManager2d:GetPlayerPos()
  local pos = Vector2.New(playerPos.x, playerPos.y)
  local dir = PlayerManager2d:GetDir()
  local p2 = config.p2
  if dir == Dir2d.Left then
    pos = Vector2.New(playerPos.x + p2[1], playerPos.y)
  elseif dir == Dir2d.Right then
    pos = Vector2.New(playerPos.x + p2[2], playerPos.y)
  elseif dir == Dir2d.Down then
    pos = Vector2.New(playerPos.x, playerPos.y + p2[3])
  elseif dir == Dir2d.Up then
    pos = Vector2.New(playerPos.x, playerPos.y + p2[4])
  end
  local p1 = config.p1
  local rect = Logic2d:SetRect(pos.x + p1[1][1], pos.x + p1[1][2], pos.y + p1[2][1], pos.y + p1[2][2])
  local npcMap = NpcManager2d:GetNpcMap()
  for id, v in pairs(npcMap) do
    local isCollision = self:CheckNpcCollisionById(id, rect)
    if isCollision then
      GameManager2d:SetPhoto(id)
      NpcManager2d:SetTimeByBuffId(id, Buff2dId.NpcAttacked)
      NpcManager2d:SetTimeByBuffId(id, Buff2dId.Photoed)
    end
  end
  GameManager2d:PlayEffect(config.effect_path, PlayerManager2d:GetPlayerPos())
end

return item2d2
