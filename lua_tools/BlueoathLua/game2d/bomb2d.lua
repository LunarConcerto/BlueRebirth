local bomb2d = class("game2d.bomb2d")
local socket = require("socket")

function bomb2d:initialize(bomb_root, id)
  self.id = id
  local config = configManager.GetDataById("config_minigame_item", 10001)
  local bomb = GR.objectPoolManager:LuaGetGameObject(config.effect_path, bomb_root)
  self.bomb = bomb
  self.width = BombSize.width
  self.height = BombSize.height
  self:InitData(bomb_root, id)
  self.skillId = Skill2d.Bomb
  local config = configManager.GetDataById("config_minigame_skill", self.skillId)
  self.config = config
end

function bomb2d:InitData()
  local playerPos = PlayerManager2d:GetPlayerPos()
  self.bomb.transform.localPosition = Vector3.New(playerPos.x, playerPos.y, playerPos.z)
  self.timeStamp = socket.gettime()
  LateUpdateBeat:Add(self.__tick, self)
end

function bomb2d:__tick()
  if GlobalGameState2d == GameState2d.Stop then
    return
  end
  if self.timeStamp > 0 and socket.gettime() - self.timeStamp > self.config.skill_delay_time then
    local npcMap = NpcManager2d:GetNpcMap()
    for id, v in pairs(npcMap) do
      local isCollision = self:CheckNpcCollisionById(id)
      if isCollision then
        NpcManager2d:SetTimeByBuffId(id, Buff2dId.NpcAttacked)
        local config = configManager.GetDataById("config_minigame_npc_info", id)
        local pos = NpcManager2d:GetPos(id)
        ItemManager2d:DropItem(config.drop_item[1], pos)
        NpcManager2d:KillLife(id)
      end
    end
    local isCollision = self:CheckPlayerCollisionById()
    if isCollision then
      GameManager2d:DelLife(self.config.skill_delay_time)
    end
    self:Bomb()
    self.timeStamp = 0
  end
end

function bomb2d:CheckPlayerCollisionById()
  local playerRect = PlayerManager2d:GetPlayerRect()
  local itemRect = self:GetRectById()
  return Logic2d:IsCollision(playerRect, itemRect)
end

function bomb2d:CheckNpcCollisionById(id)
  local npcRect = NpcManager2d:GetRectById(id)
  local itemRect = self:GetRectById()
  return Logic2d:IsCollision(npcRect, itemRect)
end

function bomb2d:GetRectById()
  local pos = self.bomb.transform.localPosition
  local recInfo = self.config.skill_area
  return Logic2d:SetRect(pos.x + recInfo[1][1], pos.x + recInfo[1][2], pos.y + recInfo[2][1], pos.y + recInfo[2][2])
end

function bomb2d:Bomb()
  self.bomb:SetActive(false)
  BombManager2d:DestroyBomb(self.id)
end

function bomb2d:Destroy()
  LateUpdateBeat:Remove(self.__tick, self)
  GR.objectPoolManager:LuaUnspawnAndDestory(self.bomb)
  self.bomb = nil
end

return bomb2d
