local ai2d1 = class("game2d.ai2d.ai2d1", Ai2d)

function ai2d1:initialize(npc)
  self.npc = npc
  local npcId = npc:GetId()
  local npcConfig = configManager.GetDataById("config_minigame_npc_info", npcId)
  local aiList = npcConfig.ai
  self.id = 0
  self.aiList = aiList
  self.randomMap = {}
  LateUpdateBeat:Add(self.__tick, self)
end

function ai2d1:GetState()
  if self.npc:HaveCheese() then
    return AiState.cheese
  end
  local dis = self.npc:GetDisFromPlayer()
  if self.id > 0 then
    local aiConfig = configManager.GetDataById("config_minigame_ai", self.id)
    if dis >= aiConfig.area[1] and dis <= aiConfig.area[2] then
      self.velocity_rate = aiConfig.velocity_rate
      return aiConfig.type
    else
      self.id = 0
    end
  end
  if self.id == 0 then
    for i, v in ipairs(self.aiList) do
      local aiConfig = configManager.GetDataById("config_minigame_ai", v)
      if dis >= aiConfig.area[1] and dis <= aiConfig.area[2] then
        self.id = i
        self.velocity_rate = aiConfig.velocity_rate
        return aiConfig.type
      end
    end
  end
  self.id = 0
  self.velocity_rate = 1
  return AiState.patrol
end

function ai2d1:__tick()
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

function ai2d1:Far()
  local isInvisible = PlayerManager2d:HasBuffByIdType(Buff2dType.Invisible)
  if isInvisible then
    return
  end
  local pos = PlayerManager2d:GetPlayerPos()
  local posNow = self.npc.npc.transform.localPosition
  local pathList = Logic.pathfinder:FindPath(posNow, pos)
  if #pathList <= 1 then
    return
  end
  local to = pathList[2]
  local velocity = self.npc:GetVelocity() * self.velocity_rate
  local vec2 = Vector2.New(posNow.x - to.x, posNow.y - to.y)
  local move_dis = velocity * Time.deltaTime
  local vec2_Normalize = vec2:SetNormalize()
  local delta = vec2_Normalize * move_dis
  self.npc:SetState(State2d.walk)
  self.npc:SetDirNow(delta)
  local x = posNow.x + delta.x
  local y = posNow.y + delta.y
  local des = Vector3.New(x, y, y)
  local pointOnNavmesh = Logic.pathfinder:PointOnNavmesh(des)
  if not pointOnNavmesh then
    return
  end
  self.npc.npc.transform.localPosition = des
end

function ai2d1:Closer()
  local isInvisible = PlayerManager2d:HasBuffByIdType(Buff2dType.Invisible)
  if isInvisible then
    return
  end
  local pos = PlayerManager2d:GetPlayerPos()
  local posNow = self.npc.npc.transform.localPosition
  local vec2Tmp = Vector2.New(pos.x - posNow.x, pos.y - posNow.y)
  if vec2Tmp.magnitude <= 0.01 then
    self.npc:SetState(State2d.idle)
    return
  end
  local pathList = Logic.pathfinder:FindPath(posNow, pos)
  if #pathList <= 1 then
    return
  end
  local targetIndex = 2
  for i = 1, #pathList - 1 do
    local offset = pathList[i + 1] - pathList[i]
    if offset.magnitude < 1.0E-4 then
      targetIndex = targetIndex + 1
    else
      break
    end
  end
  if targetIndex > #pathList then
    return
  end
  local to = pathList[targetIndex]
  local velocity = self.npc:GetVelocity() * self.velocity_rate
  local vec2 = Vector2.New(to.x - posNow.x, to.y - posNow.y)
  local vec2_dis = vec2.magnitude
  local move_dis = vec2_dis < velocity * Time.deltaTime and vec2_dis or velocity * Time.deltaTime
  local vec2_Normalize = vec2:SetNormalize()
  local delta = vec2_Normalize * move_dis
  self.npc:SetState(State2d.run)
  self.npc:SetDirNow(delta)
  local x = posNow.x + delta.x
  local y = posNow.y + delta.y
  self.npc.npc.transform.localPosition = Vector3.New(x, y, y)
end

function ai2d1:PATROL()
  local posNow = self.npc.npc.transform.localPosition
  local velocity = self.npc:GetVelocity()
  local _time = time.getSvrTime()
  local _deg = self.randomMap[_time] or math.random(0, 4)
  self.randomMap[_time] = _deg
  local vec2 = Vector2.New(math.sin(math.rad(_deg * 90)), math.cos(math.rad(_deg * 90)))
  local move_dis = velocity * Time.deltaTime
  local vec2_Normalize = vec2:SetNormalize()
  local delta = vec2_Normalize * move_dis
  self.npc:SetState(State2d.walk)
  self.npc:SetDirNow(delta)
  local x = posNow.x + delta.x
  local y = posNow.y + delta.y
  local des = Vector3.New(x, y, y)
  local pointOnNavmesh = Logic.pathfinder:PointOnNavmesh(des)
  if not pointOnNavmesh then
    local _deg = math.random(0, 4)
    self.randomMap[_time] = _deg
    return
  end
  self.npc.npc.transform.localPosition = des
end

function ai2d1:Cheese()
  local pos = self.npc:GetCheesePos()
  local posNow = self.npc:GetPos()
  local vec2Tmp = Vector2.New(pos.x - posNow.x, pos.y - posNow.y)
  if vec2Tmp.magnitude <= 0.01 then
    self.npc:ResetCheeseId()
    return
  end
  local pathList = Logic.pathfinder:FindPath(posNow, pos)
  if #pathList <= 1 then
    return
  end
  local to = pathList[2]
  local velocity = self.npc:GetVelocity()
  local vec2 = Vector2.New(to.x - posNow.x, to.y - posNow.y)
  local vec2_dis = vec2.magnitude
  local move_dis = vec2_dis < velocity * Time.deltaTime and vec2_dis or velocity * Time.deltaTime
  local vec2_Normalize = vec2:SetNormalize()
  local delta = vec2_Normalize * move_dis
  self.npc:SetState(State2d.run)
  self.npc:SetDirNow(delta)
  local x = posNow.x + delta.x
  local y = posNow.y + delta.y
  self.npc.npc.transform.localPosition = Vector3.New(x, y, y)
end

function ai2d1:Destroy()
  LateUpdateBeat:Remove(self.__tick, self)
  self.npc = nil
end

return ai2d1
