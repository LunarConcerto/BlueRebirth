local gameManager2d = class("game2d.gameManager2d")

function gameManager2d:initialize()
end

function gameManager2d:InitGameId(gameId)
  self.gameId = gameId
  Service.miniGameService:StartMiniGame({Id = gameId})
end

function gameManager2d:Restart()
  NpcManager2d:Reset()
  PlayerManager2d:Reset()
  ItemManager2d:Reset()
  self.pickItem = {}
  self.photoMap = {}
  self.time = 0
  self.pausetime = 0
  self.pickCommonItem = {}
end

function gameManager2d:InitData()
  local gameId = self.gameId
  local config = configManager.GetDataById("config_minigame_copy", gameId)
  SoundManager.Instance:PlayMusic(config.bgm)
  self.config = config
  self.life = config.player_life
  self.pickItem = {}
  self.photoMap = {}
  self.time = 0
  self.pausetime = 0
  self.EffectMap = {}
  local successId = config.victory_condition
  self.successConfig = configManager.GetDataById("config_minigame_victory_condition", successId)
  self.gameType = self.successConfig.type
  self.attacked = 0
  self.pickCommonItem = {}
  self.scene = homeEnvManager:ChangeScene(SceneType.MiniGame, true, gameId)
  self.camera = GR.cameraManager:showCamera(GameCameraType.MiniGameSceneCamera)
  self.camera_real = self.camera:GetCam()
  self.camera_real.orthographic = true
  self.camera_real.orthographicSize = config.camera_size
  Logic.pathfinder:LoadMap(gameId)
  AiManager2d:InitData()
  PlayerManager2d:InitData(self.scene.transform)
  NpcManager2d:InitData(self.scene.transform)
  ItemManager2d:InitData(self.scene.transform, config.item_random)
  SkillManager2d:InitData(self.scene.transform)
  BombManager2d:InitData(self.scene.transform)
  LateUpdateBeat:Add(self.__tick, self)
  AreaManager2d:InitData()
  CameraManager2d:InitData(self.camera_real)
  self.__startGame = false
end

function gameManager2d:__tick()
  if GlobalGameState2d == GameState2d.Stop then
    if self.__startGame == true then
      self.pausetime = self.pausetime + Time.unscaledDeltaTime
    end
    return
  end
  if self.__startGame == false then
    self.__startGame = true
    self.pausetime = 0
  end
  self.time = self.time + Time.deltaTime
  PlayerManager2d:CheckCollision()
end

function gameManager2d:GetTime()
  return self.time
end

function gameManager2d:GetPauseTime()
  return self.pausetime
end

function gameManager2d:GetCameraLimit()
  return self.config.camera_info
end

function gameManager2d:GetSkillId()
  return self.config.skill_id
end

function gameManager2d:GetConfig()
  return self.config
end

function gameManager2d:Pick(templateId)
  local num = self.pickItem[templateId] or 0
  self.pickItem[templateId] = num + 1
  eventManager:SendEvent(LuaEvent.UpdateItem2d)
  self:CheckGameOver()
end

function gameManager2d:GetPickNum(itemId)
  return self.pickItem[itemId] or 0
end

function gameManager2d:GetPickNumByTid(templateId)
  local sum = 0
  for itemId, num in pairs(self.pickItem) do
    local config = configManager.GetDataById("config_minigame_item", itemId)
    if config.template == templateId then
      sum = sum + num
    end
  end
  return sum
end

function gameManager2d:PickCommonItem(itemId)
  local num = self.pickCommonItem[itemId] or 0
  self.pickCommonItem[itemId] = num + 1
end

function gameManager2d:GetPickCommonItemMap()
  local tmp = {}
  for i, v in pairs(self.pickCommonItem) do
    local sub = {}
    sub.ItemId = i
    sub.Num = v
    table.insert(tmp, sub)
  end
  return tmp
end

function gameManager2d:CheckGameOver()
  local param = self.successConfig.parameter
  if self.gameType == Game2dType.Bomb or self.gameType == Game2dType.Pick then
    local sum = GameManager2d:GetPickNumByTid(param[1])
    if sum >= param[2] then
      eventManager:SendEvent(LuaEvent.Success2d)
    end
  elseif self.gameType == Game2dType.Photo and self:GetPhotoNum() >= param[1] then
    eventManager:SendEvent(LuaEvent.Success2d)
  end
end

function gameManager2d:DelLife(custom)
  if self:GetLife() <= 0 then
    return
  end
  self.attacked = self.attacked + 1
  self.life = self.life - 1
  eventManager:SendEvent(LuaEvent.UpdateLife2d)
  if 0 >= self.life then
    PlayerManager2d:SetState(State2d.death, custom)
    local timer = Timer.New(function()
      self:Fail()
    end, 1, 1, false)
    timer:Start()
  else
    PlayerManager2d:SetState(State2d.attacked, custom)
    PlayerManager2d:SetTimeByBuffId(Buff2dId.Invincible)
    PlayerManager2d:SetTimeByBuffId(Buff2dId.HeroAttacked)
    NpcManager2d:SetBuffIdAll(Buff2dId.Far)
  end
end

function gameManager2d:AddLife(custom)
  self.life = self.life + 1
  eventManager:SendEvent(LuaEvent.UpdateLife2d)
end

function gameManager2d:GetLife()
  return self.life
end

function gameManager2d:GetAttackedCount()
  return self.attacked
end

function gameManager2d:Fail()
  eventManager:SendEvent(LuaEvent.GameOver2d)
end

function gameManager2d:SetPhoto(id)
  self.photoMap[id] = true
  self:CheckGameOver()
end

function gameManager2d:GetPhotoNum()
  local sum = 0
  for i, v in pairs(self.photoMap) do
    sum = sum + 1
  end
  return sum
end

function gameManager2d:Destroy()
  for i, v in pairs(self.EffectMap) do
    GR.objectPoolManager:LuaUnspawnAndDestory(v)
  end
  self.EffectMap = {}
  LateUpdateBeat:Remove(self.__tick, self)
  SkillManager2d:Destroy()
  ItemManager2d:Destroy()
  NpcManager2d:Destroy()
  BombManager2d:Destroy()
  AiManager2d:Destroy()
  PlayerManager2d:Destroy()
  CameraManager2d:Destroy()
  Logic.pathfinder:UnLoad()
  self.config = nil
  self.successConfig = nil
  self.camera = nil
  self.scene = nil
  Time.timeScale = 1
end

function gameManager2d:GetScoreSum()
  local score_sum = 0
  local paramConf = configManager.GetDataById("config_parameter", 369).arrValue
  local conditionConf = paramConf[1]
  local valueConf = paramConf[2]
  local time_num = math.floor(GameManager2d:GetTime())
  local score_time
  for i = #conditionConf, 1, -1 do
    if time_num >= conditionConf[i] then
      score_time = valueConf[i]
    end
  end
  score_sum = score_sum + score_time
  local life = GameManager2d:GetLife()
  local life_rate = configManager.GetDataById("config_parameter", 370).value
  score_sum = score_sum + life * life_rate
  if self.gameType == Game2dType.Photo then
    local photo_num = GameManager2d:GetPhotoNum()
    local photo_rate = configManager.GetDataById("config_parameter", 371).value
    score_sum = score_sum + photo_num * photo_rate
  end
  if self.gameType == Game2dType.Bomb or self.gameType == Game2dType.Pick then
    local param = self.successConfig.parameter
    local templateId = param[1]
    local num = GameManager2d:GetPickNumByTid(templateId)
    local bomb_rate = configManager.GetDataById("config_parameter", 372).value
    score_sum = score_sum + num * bomb_rate
  end
  return score_sum
end

function gameManager2d:PlayEffect(effect, pos)
  local effect_trans = self.EffectMap[effect]
  if not effect_trans then
    local effect_root = self.scene.transform:Find("Effect")
    effect_trans = GR.objectPoolManager:LuaGetGameObject(effect, effect_root)
    self.EffectMap[effect] = effect_trans
  end
  if effect_trans then
    effect_trans.transform.localPosition = pos
    effect_trans:SetActive(false)
    effect_trans:SetActive(true)
  end
end

return gameManager2d
