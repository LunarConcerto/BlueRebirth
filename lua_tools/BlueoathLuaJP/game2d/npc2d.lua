local npc2d = class("game2d.npc2d")
local socket = require("socket")

function npc2d:initialize(id, npc)
  self.id = id
  local config = configManager.GetDataById("config_minigame_npc_info", id)
  self.width = config.size[1]
  self.height = config.size[2]
  self.velocity = config.velocity[1]
  self.npc = npc
  self.init_pos = npc.localPosition
  self.animator = self.npc.gameObject:GetComponent(UnityEngine_Animator.GetClassType())
  self.dirTbl = {
    [Dir2d.Left] = 0,
    [Dir2d.Right] = 0,
    [Dir2d.Up] = 0,
    [Dir2d.Down] = 0
  }
  self.dir = Dir2d.Right
  self.state = State2d.idle
  self.animator:SetInteger("Dir", self.dir)
  self.bombTime = 0
  self.deathTime = 0
  self.cheeseId = 0
  self.life = 1
  self.buffMap = {}
  self.buffTypeMap = {}
  LateUpdateBeat:Add(self.__tick, self)
end

function npc2d:Reset()
  self.npc.localPosition = self.init_pos
end

function npc2d:SetDirNow(delta)
  if delta.x ~= 0 and delta.y ~= 0 then
    if math.abs(delta.x) >= math.abs(delta.y) then
      self.dir = delta.x > 0 and Dir2d.Right or Dir2d.Left
    else
      self.dir = 0 < delta.y and Dir2d.Up or Dir2d.Down
    end
  end
  self.animator:SetInteger("Dir", self.dir)
end

function npc2d:SetDir(dir, value)
  self.dirTbl[dir] = value
end

function npc2d:InitData()
end

function npc2d:__tick()
  if GlobalGameState2d == GameState2d.Stop then
    if self.state ~= State2d.death then
      self:SetState(State2d.idle)
    end
    return
  end
  local isAttacked = self:HasBuffByIdType(Buff2dType.Attacked)
  if isAttacked then
    self:SetState(State2d.attacked)
    return
  end
  if self.life <= 0 then
    self:SetState(State2d.death)
    self.npc.gameObject:SetActive(false)
    NpcManager2d:SetDeathMapById(self.id)
    GameManager2d:CheckGameOver()
  end
end

function npc2d:SetState(state, custom)
  self.state = state
  self.animator:SetInteger("State", state)
end

function npc2d:GetDisFromPlayer()
  local pos = self.npc.transform.localPosition
  local player_pos = PlayerManager2d:GetPlayerPos()
  local vec2 = Vector2.New(pos.x - player_pos.x, pos.y - player_pos.y)
  return vec2.magnitude
end

function npc2d:GetPos()
  return self.npc.transform.localPosition
end

function npc2d:GetState()
  return self.state
end

function npc2d:SetDeath()
  self:SetState(State2d.death)
end

function npc2d:GetId()
  return self.id
end

function npc2d:GetVelocity()
  return self.velocity
end

function npc2d:Destroy()
  LateUpdateBeat:Remove(self.__tick, self)
  self.npc = nil
  self.animator = nil
  for i, v in pairs(self.buffTypeMap) do
    GR.objectPoolManager:LuaUnspawnAndDestory(v)
  end
  self.buffTypeMap = {}
end

function npc2d:HaveCheese()
  return self.cheeseId > 0
end

function npc2d:SetCheeseId(id)
  self.cheeseId = id
end

function npc2d:ResetCheeseId()
  ItemManager2d:SetActiveById(self.cheeseId, Item2dState.UnActive)
  self.cheeseId = 0
end

function npc2d:GetCheesePos()
  return ItemManager2d:GetPosById(self.cheeseId)
end

function npc2d:CheckPlayerCollision()
  if self.state == State2d.death then
    return false
  end
  local playerRect = PlayerManager2d:GetPlayerRect()
  local itemRect = self:GetRect()
  return Logic2d:IsCollision(playerRect, itemRect)
end

function npc2d:GetRect()
  local npc = self.npc
  local pos = npc.localPosition
  local width = self.width
  local height = self.height
  return Logic2d:SetRect(pos.x - width / 2, pos.x + width / 2, pos.y, pos.y + height)
end

function npc2d:SetTimeByBuffId(id)
  local config = configManager.GetDataById("config_minigame_buff", id)
  self.buffMap[id] = GameManager2d:GetTime() + config.time
  local buff_type = config.type
  if config.type == Buff2dType.Photoed then
    local buff_trans = self.buffTypeMap[buff_type]
    local type_config = configManager.GetDataById("config_minigame_buff_type", buff_type)
    if type_config.effect_path then
      if not buff_trans then
        local buff_root = self.npc.transform:Find("Buff")
        buff_trans = GR.objectPoolManager:LuaGetGameObject(type_config.effect_path, buff_root)
        self.buffTypeMap[buff_type] = buff_trans
      end
      if buff_trans then
        buff_trans:SetActive(true)
      end
    end
  end
end

function npc2d:KillLife()
  self.life = self.life - 1
end

function npc2d:HasBuffByIdType(buffType)
  for i, v in pairs(self.buffMap) do
    local config = configManager.GetDataById("config_minigame_buff", i)
    local _time = v or 0
    if config.type == buffType and _time >= GameManager2d:GetTime() then
      return true, config.parameter
    end
  end
  return false
end

return npc2d
