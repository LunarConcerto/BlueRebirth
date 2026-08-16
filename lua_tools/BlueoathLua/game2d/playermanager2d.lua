local playerManager2d = class("game2d.playerManager2d")
local socket = require("socket")

function playerManager2d:initialize()
end

function playerManager2d:InitData(scene)
  local player_root = scene.transform:Find("Player")
  self.player_root = player_root
  self.player = player_root:GetChild(0)
  local player = self.player
  self.init_pos = player.localPosition
  self.templateId = tonumber(player.name)
  local config = configManager.GetDataById("config_minigame_npc_info", self.templateId)
  self.animator = self.player.gameObject:GetComponent(UnityEngine_Animator.GetClassType())
  self.width = config.size[1]
  self.height = config.size[2]
  self.velocity = config.velocity[1]
  self.dirTbl = {
    [Dir2d.Left] = 0,
    [Dir2d.Right] = 0,
    [Dir2d.Up] = 0,
    [Dir2d.Down] = 0
  }
  self.dir = Dir2d.Right
  self.speed = Vector3.zero
  self.buffMap = {}
  self.buffTypeMap = {}
  self.skillId = GameManager2d:GetSkillId()
  self.itemId = 0
  self.bombTime = 0
  self.deathTime = 0
  self.state = State2d.idle
  self.focusFlag = false
  self.item_tran = nil
  eventManager:RegisterEvent(LuaCSharpEvent.LoseFocus, self.onGameFocus, self)
  LateUpdateBeat:Add(self.__tick, self)
end

function playerManager2d:Reset()
  self.player.localPosition = self.init_pos
end

function playerManager2d:SetItemId(id)
  if self.itemId ~= id then
    if self.itemId > 0 then
      ItemManager2d:DropById(self.itemId)
      self.itemId = 0
    end
    if 0 < id then
      ItemManager2d:PickById(id)
      self.itemId = id
    end
    self:SetItemImage()
    eventManager:SendEvent(LuaEvent.UpdateItemSingle2d)
  end
end

function playerManager2d:SetItemImage()
  if self.item_tran then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.item_tran)
    self.item_tran = nil
  end
  if self.itemId > 0 then
    local item_root = self.player:Find("Item")
    local itemId = ItemManager2d:GetItemIdById(self.itemId)
    local config = configManager.GetDataById("config_minigame_item", itemId)
    self.item_tran = GR.objectPoolManager:LuaGetGameObject(config.respath, item_root)
    local pos = config.position
    self.item_tran.transform.localPosition = Vector3.New(pos[1], pos[2], 0)
  end
end

function playerManager2d:GetItemId()
  return self.itemId
end

function playerManager2d:UseItem()
  if self.itemId > 0 then
    ItemManager2d:UseById(self.itemId)
  else
    logError("\230\178\161\230\156\137\229\143\175\228\189\191\231\148\168\231\154\132\231\137\169\229\147\129")
  end
end

function playerManager2d:Pick()
  local itemMap = ItemManager2d:GetItemMap()
  local item
  for i, v in pairs(itemMap) do
    local isCollision = v:CheckPlayerCollision()
    if isCollision then
      local templateId = v:GetItemId()
      local config = configManager.GetDataById("config_minigame_item", templateId)
      if config.type == Item2dType.Unique then
        if not item then
          item = v
        else
          local dis_item = item:GetDisFromPlayer()
          local dis_v = v:GetDisFromPlayer()
          if dis_item > dis_v then
            item = v
          end
        end
      end
      GameManager2d:PlayEffect("effects/prefabs/ui/eff3d_mini_game_getitem", item:GetPos())
    end
  end
  if item then
    self:SetItemId(item:GetId())
  else
    self:UseItem()
  end
end

function playerManager2d:CheckCollision()
  local npcMap = NpcManager2d:GetNpcMap()
  for id, v in pairs(npcMap) do
    local isCollision = v:CheckPlayerCollision()
    if isCollision then
      local isInvincible = self:HasBuffByIdType(Buff2dType.Invincible)
      local isAttack = self:HasBuffByIdType(Buff2dType.Attack)
      if isAttack then
        v:SetState(State2d.death)
      elseif isInvincible then
      else
        GameManager2d:DelLife(1)
      end
    end
  end
  local itemMap = ItemManager2d:GetItemMap()
  for i, v in pairs(itemMap) do
    local isCollision = v:CheckPlayerCollision()
    local templateId = v:GetItemId()
    local config = configManager.GetDataById("config_minigame_item", templateId)
    if isCollision then
      if config.type == Item2dType.Common then
        v:Pick()
        GameManager2d:PickCommonItem(templateId)
      elseif config.type == Item2dType.Unique then
        v:SetTips(true)
      end
    elseif config.type == Item2dType.Unique then
      v:SetTips(false)
    end
  end
end

function playerManager2d:GetPlayerPos()
  return self.player.localPosition
end

function playerManager2d:SetPlayerPos(pos)
  self.player.localPosition = pos
end

function playerManager2d:GetPlayerRect()
  local pos = self.player.localPosition
  local width = self.width
  local height = self.height
  return Logic2d:SetRect(pos.x - width / 2, pos.x + width / 2, pos.y, pos.y + height)
end

function playerManager2d:Skill()
  if self.skillId <= 0 then
    logError("\230\178\161\230\156\137\230\138\128\232\131\189")
    return
  end
  SkillManager2d:Skill(self.skillId)
end

function playerManager2d:SetDir(dir, value)
  self.dirTbl[dir] = value
end

function playerManager2d:SetDirNow()
  local isConfusion = self:HasBuffByIdType(Buff2dType.Confusion) and -1 or 1
  if self.dirTbl[Dir2d.Right] ~= self.dirTbl[Dir2d.Left] then
    self.dir = isConfusion * (self.dirTbl[Dir2d.Right] - self.dirTbl[Dir2d.Left]) > 0 and Dir2d.Right or Dir2d.Left
  elseif self.dirTbl[Dir2d.Up] ~= self.dirTbl[Dir2d.Down] then
    self.dir = 0 < isConfusion * (self.dirTbl[Dir2d.Up] - self.dirTbl[Dir2d.Down]) and Dir2d.Up or Dir2d.Down
  end
end

function playerManager2d:__tick()
  if self.focusFlag then
    self.focusFlag = false
    return
  end
  if GlobalGameState2d == GameState2d.Stop then
    self:PlayStateAnimator(State2d.idle)
    return
  end
  self:RefreshBuff()
  local isAttacked = self:HasBuffByIdType(Buff2dType.Attacked)
  if isAttacked then
    self:SetState(State2d.attacked)
    self.animator.enabled = true
    self.speed = Vector3.zero
    return
  end
  if GameManager2d:GetLife() <= 0 then
    PlayerManager2d:SetTimeByBuffId(Buff2dId.HeroDead)
    self:SetState(State2d.death)
    self.animator.enabled = true
    return
  end
  local speed = Vector3.New(self.dirTbl[Dir2d.Right] - self.dirTbl[Dir2d.Left], self.dirTbl[Dir2d.Up] - self.dirTbl[Dir2d.Down], 0)
  speed = speed.normalized
  local isAccelerate, speedRateParam = self:HasBuffByIdType(Buff2dType.Accelerate)
  local speed_rate = isAccelerate and speedRateParam[1] or 1
  local isOnIce, onIceParam = self:HasBuffByIdType(Buff2dType.OnIce)
  local isOnRollBand, OnRollBandParam = self:HasBuffByIdType(Buff2dType.OnRollBand)
  if speed == Vector3.zero then
    self:SetState(State2d.idle)
  else
    self:SetState(State2d.walk)
  end
  if isOnIce then
    if speed == Vector3.zero then
      self.animator.enabled = false
    else
      self.speed = speed
      self.animator.enabled = true
    end
    speed_rate = speed_rate * onIceParam[1]
  else
    self.animator.enabled = true
    if isOnRollBand then
      self.speed = speed + Vector3.New(OnRollBandParam[1], OnRollBandParam[2], 0)
    else
      self.speed = speed
    end
    self.animator.enabled = true
  end
  local pos = self.player.localPosition
  local isConfusion = self:HasBuffByIdType(Buff2dType.Confusion) and -1 or 1
  local x_delta = self.velocity * Time.deltaTime * self.speed.x * isConfusion
  local y_delta = self.velocity * Time.deltaTime * self.speed.y * isConfusion
  local x = pos.x + x_delta * speed_rate
  local y = pos.y + y_delta * speed_rate
  local des = Vector3.New(x, y, y)
  local pointOnNavmesh = Logic.pathfinder:PointOnNavmesh(des)
  if not pointOnNavmesh then
    if isOnIce then
      local testXPoint = Vector3.New(des.x, pos.y, pos.y)
      local testYPoint = Vector3.New(pos.x, des.y, des.y)
      local testX = Logic.pathfinder:PointOnNavmesh(testXPoint)
      local testY = Logic.pathfinder:PointOnNavmesh(testYPoint)
      self.speed.x = testX and self.speed.x or -self.speed.x
      self.speed.y = testY and self.speed.y or -self.speed.y
    end
    return
  end
  self.player.localPosition = Vector3.New(x, y, y)
  AreaManager2d:RefreshPlayerBuff()
  CameraManager2d:Update()
  self:SetDirNow()
  self.animator:SetInteger("Dir", self.dir)
end

function playerManager2d:GetAngleDir()
  local to = Vector2.New(self.dirTbl[Dir2d.Right] - self.dirTbl[Dir2d.Left], self.dirTbl[Dir2d.Up] - self.dirTbl[Dir2d.Down])
  if self.dirTbl[Dir2d.Up] - self.dirTbl[Dir2d.Down] > 0 then
    return -Vector2.Angle(Vector2.right, to)
  else
    return Vector2.Angle(Vector2.right, to)
  end
end

function playerManager2d:Destroy()
  eventManager:UnregisterEvent(LuaCSharpEvent.LoseFocus, self.onGameFocus, self)
  LateUpdateBeat:Remove(self.__tick, self)
  self.player = nil
  self.animator = nil
  if not IsNil(self.item_tran) then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.item_tran)
  end
  self.item_tran = nil
  for i, v in pairs(self.buffTypeMap) do
    GR.objectPoolManager:LuaUnspawnAndDestory(v)
  end
  self.buffTypeMap = {}
end

function playerManager2d:SetState(state, custom)
  self.state = state
  self:PlayStateAnimator(state)
end

function playerManager2d:GetDir()
  return self.dir
end

function playerManager2d:GetRoleItemState()
  return self.itemId > 0 and RoleItemState2d.item or RoleItemState2d.empty
end

function playerManager2d:PlayStateAnimator(state)
  local itemSate = self:GetRoleItemState()
  local ani = AnimatorState2d[itemSate][state]
  self.animator:SetInteger("State", ani)
end

function playerManager2d:SetTimeByBuffId(id)
  local config = configManager.GetDataById("config_minigame_buff", id)
  self.buffMap[id] = GameManager2d:GetTime() + config.time
  local buff_type = config.type
  local buff_trans = self.buffTypeMap[buff_type]
  local type_config = configManager.GetDataById("config_minigame_buff_type", buff_type)
  if type_config.effect_path then
    if not buff_trans then
      local buff_root = self.player:Find("Buff")
      buff_trans = GR.objectPoolManager:LuaGetGameObject(type_config.effect_path, buff_root)
      self.buffTypeMap[buff_type] = buff_trans
    end
    if buff_trans then
      buff_trans:SetActive(false)
      buff_trans:SetActive(true)
    end
  end
end

function playerManager2d:AddBuffWithoutEff(id)
  self.buffMap[id] = GameManager2d:GetTime() + 9999
end

function playerManager2d:DelBuffWithoutEff(id)
  self.buffMap[id] = GameManager2d:GetTime() - 1
end

function playerManager2d:RefreshBuff()
  for buff_type, buff_trans in pairs(self.buffTypeMap) do
    local type_config = configManager.GetDataById("config_minigame_buff_type", buff_type)
    if type_config.effect_path then
      local isActive = self:HasBuffByIdType(buff_type)
      if isActive and buff_type == Buff2dType.Accelerate then
        local angle = 0 - PlayerManager2d:GetAngleDir()
        buff_trans.transform.localEulerAngles = Vector3.New(0, 0, angle)
        local isOnIce = self:HasBuffByIdType(Buff2dType.OnIce)
        if isOnIce and self.state == State2d.idle then
          buff_trans.transform.localScale = Vector3.New(0, 0, 0)
        else
          buff_trans.transform.localScale = Vector3.New(1, 1, 1)
        end
        local angle = 0 - PlayerManager2d:GetAngleDir()
        buff_trans.transform.localEulerAngles = Vector3.New(0, 0, angle)
      end
      buff_trans:SetActive(isActive)
    end
  end
end

function playerManager2d:HasBuffByIdType(buffType)
  for i, v in pairs(self.buffMap) do
    local config = configManager.GetDataById("config_minigame_buff", i)
    local _time = v or 0
    if config.type == buffType and _time >= GameManager2d:GetTime() then
      return true, config.parameter
    end
  end
  return false
end

function playerManager2d:onGameFocus()
  self.focusFlag = true
end

return playerManager2d
