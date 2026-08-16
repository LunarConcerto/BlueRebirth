local ai2d = class("game2d.ai2d.ai2d", Ai2dbase)

function ai2d:initialize(npc)
  self.npc = npc
  local npcId = npc:GetId()
  local npcConfig = configManager.GetDataById("config_minigame_npc_info", npcId)
  local aiList = npcConfig.ai
  self.aiList = aiList
  self.randomMap = {}
  LateUpdateBeat:Add(self.__tick, self)
end

function ai2d:GetState()
  if self.npc:HaveCheese() then
    return AiState.cheese
  end
  local isInvisible = PlayerManager2d:HasBuffByIdType(Buff2dType.Invisible)
  if isInvisible then
    return AiState.patrol
  end
  local isFar = self.npc:HasBuffByIdType(Buff2dType.Far)
  if isFar then
    return AiState.far
  end
  local dis = self.npc:GetDisFromPlayer()
  for i, v in pairs(self.aiList) do
    local aiConfig = configManager.GetDataById("config_minigame_ai", v)
    if dis >= aiConfig.area[1] and dis <= aiConfig.area[2] then
      self.velocity_rate = aiConfig.velocity_rate
      return aiConfig.type
    end
  end
  self.velocity_rate = 1
  return AiState.patrol
end

function ai2d:__tick()
  if GlobalGameState2d == GameState2d.Stop then
    return
  end
  local state = self.npc:GetState()
  if state == State2d.attacked then
    return
  elseif state == State2d.death then
    return
  end
  local fsm_state = self:GetState()
  if fsm_state == AiState.far then
    self:Far()
  elseif fsm_state == AiState.closer then
    self:Closer()
  elseif fsm_state == AiState.patrol then
    self:PATROL()
  elseif fsm_state == AiState.cheese then
    self:Cheese()
  end
end

function ai2d:Destroy()
  LateUpdateBeat:Remove(self.__tick, self)
  self.npc = nil
end

return ai2d
