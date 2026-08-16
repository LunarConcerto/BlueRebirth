local npcManager2d = class("game2d.npcManager2d")

function npcManager2d:InitData(scene_root)
  self.npcMap = {}
  self.deathMap = {}
  local npc_root = scene_root:Find("NPC")
  for i = 0, npc_root.childCount - 1 do
    local child = npc_root:GetChild(i)
    local id = tonumber(child.name)
    local npc = require("game2d.npc2d"):new(id, child)
    AiManager2d:SetAi(npc, id)
    self.npcMap[id] = npc
  end
end

function npcManager2d:Reset()
  for i, v in pairs(self.npcMap) do
    v:Reset()
  end
end

function npcManager2d:GetPlayerNearest()
  local npc
  for id, v in pairs(self.npcMap) do
    local state = self:GetStateById(id)
    if state ~= State2d.death and state ~= State2d.attacked then
      if not npc then
        npc = v
      else
        local dis_item = npc:GetDisFromPlayer()
        local dis_v = v:GetDisFromPlayer()
        if dis_item > dis_v then
          npc = v
        end
      end
    end
  end
  return npc
end

function npcManager2d:CheckPlayerCollision()
  for id, v in pairs(self.npcMap) do
    local isCollision = self:CheckPlayerCollisionById(id)
    if isCollision then
      local state = self:GetStateById(id)
      if state == State2d.attacked then
        self:SetStateById(id, State2d.death)
      else
        return true
      end
    end
  end
  return false
end

function npcManager2d:CheckPlayerCollisionById(id)
  local playerRect = PlayerManager2d:GetPlayerRect()
  local itemRect = self:GetRectById(id)
  return Logic2d:IsCollision(playerRect, itemRect)
end

function npcManager2d:GetRectById(id)
  local npcInfo = self.npcMap[id]
  local npc = npcInfo.npc
  local pos = npc.localPosition
  local width = npcInfo.width
  local height = npcInfo.height
  return Logic2d:SetRect(pos.x - width / 2, pos.x + width / 2, pos.y, pos.y + height)
end

function npcManager2d:GetNpcMap()
  return self.npcMap
end

function npcManager2d:SetDeathMapById(id)
  self.deathMap[id] = true
end

function npcManager2d:GetDeathNum()
  local sum = 0
  for i, v in pairs(self.deathMap) do
    if v then
      sum = sum + 1
    end
  end
  return sum
end

function npcManager2d:SetStateById(id, state, custom)
  local npc = self.npcMap[id]
  npc:SetState(state, custom)
end

function npcManager2d:SetTimeByBuffId(id, buffId)
  local npc = self.npcMap[id]
  npc:SetTimeByBuffId(buffId)
end

function npcManager2d:KillLife(id)
  local npc = self.npcMap[id]
  npc:KillLife()
end

function npcManager2d:GetStateById(id)
  local npc = self.npcMap[id]
  return npc:GetState()
end

function npcManager2d:GetPos(id)
  local npc = self.npcMap[id]
  return npc:GetPos()
end

function npcManager2d:SetBuffIdAll(buffId)
  for id, v in pairs(self.npcMap) do
    v:SetTimeByBuffId(buffId)
  end
end

function npcManager2d:Destroy()
  for i, v in pairs(self.npcMap) do
    v:Destroy()
  end
  self.npcMap = {}
  self.deathMap = {}
end

return npcManager2d
