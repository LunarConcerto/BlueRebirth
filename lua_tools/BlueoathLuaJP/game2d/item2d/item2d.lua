local item2d = class("game2d.item2d")

function item2d:initialize(id, itemId, item, state)
  self.id = id
  self.itemId = itemId
  local config = configManager.GetDataById("config_minigame_item", itemId)
  self.templateId = config.template
  self.width = config.size[1]
  self.height = config.size[2]
  self.item = item
  self.init_pos = item.localPosition
  self.state = state
  self.item.gameObject:SetActive(state == Item2dState.Active)
end

function item2d:Reset()
  self.item.localPosition = self.init_pos
end

function item2d:GetRect()
  local pos = self.item.transform.localPosition
  local width = self.width
  local height = self.height
  return Logic2d:SetRect(pos.x - width / 2, pos.x + width / 2, pos.y, pos.y + height)
end

function item2d:GetDisFromPlayer()
  local pos = self.item.transform.localPosition
  local player_pos = PlayerManager2d:GetPlayerPos()
  local vec2 = Vector2.New(pos.x - player_pos.x, pos.y - player_pos.y)
  return vec2.magnitude
end

function item2d:GetPos()
  return self.item.transform.localPosition
end

function item2d:CheckPlayerCollision()
  if self.state == Item2dState.UnActive then
    return false
  end
  local playerRect = PlayerManager2d:GetPlayerRect()
  local itemRect = self:GetRect()
  return Logic2d:IsCollision(playerRect, itemRect)
end

function item2d:Pick()
  if self.state == Item2dState.UnActive then
    return
  end
  self:SetActive(Item2dState.UnActive)
end

function item2d:GetItemId()
  return self.itemId
end

function item2d:GetTemplateId()
  return self.templateId
end

function item2d:GetId()
  return self.id
end

function item2d:Use()
end

function item2d:Destroy()
  self.item = nil
end

function item2d:SetTips(_bool)
  self.item:GetChild(0).gameObject:SetActive(_bool)
end

function item2d:Drop()
  self.item.localPosition = PlayerManager2d:GetPlayerPos()
  self:SetActive(Item2dState.Active)
end

function item2d:SetActive(state)
  self.state = state
  self.item.gameObject:SetActive(state == Item2dState.Active)
end

function item2d:GetPos()
  return self.item.localPosition
end

function item2d:CheckNpcCollisionById(id, rect)
  local npcRect = NpcManager2d:GetRectById(id)
  return Logic2d:IsCollision(npcRect, rect)
end

return item2d
