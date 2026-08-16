FSM = require("FSM.fsm")
Ai2dbase = require("game2d.ai2d.ai2dbase")
AiManager2d = require("game2d.ai2d.aiManager2d")
GameManager2d = require("game2d.gameManager2d")
NpcManager2d = require("game2d.npcManager2d")
Item2d = require("game2d.item2d.item2d")
ItemManager2d = require("game2d.item2d.itemManager2d")
PlayerManager2d = require("game2d.playerManager2d")
Logic2d = require("game2d.logic2d"):new()
SkillManager2d = require("game2d.skillManager2d")
BombManager2d = require("game2d.bombManager2d")
CameraManager2d = require("game2d.cameraManager2d")
Area2d = require("game2d.area2d")
AreaManager2d = require("game2d.areaManager2d")
SPEED_2D_NPC = 0.2
Dir2d = {
  Left = 0,
  Right = 1,
  Up = 2,
  Down = 3
}
Item2dType = {Common = 1, Unique = 2}
Skill2d = {Bomb = 1, Invisible = 2}
BombSize = {width = 1, height = 1}
State2d = {
  idle = 0,
  walk = 1,
  run = 2,
  jump = 3,
  swim = 4,
  attacked = 10,
  death = 11
}
RoleItemState2d = {empty = 1, item = 2}
AnimatorState2d = {
  [RoleItemState2d.empty] = {
    [State2d.idle] = 0,
    [State2d.walk] = 1,
    [State2d.run] = 2,
    [State2d.jump] = 3,
    [State2d.swim] = 4,
    [State2d.attacked] = 10,
    [State2d.death] = 11
  },
  [RoleItemState2d.item] = {
    [State2d.idle] = 5,
    [State2d.walk] = 6,
    [State2d.run] = 7,
    [State2d.jump] = 8,
    [State2d.swim] = 9,
    [State2d.attacked] = 10,
    [State2d.death] = 11
  }
}
Game2dType = {
  Bomb = 1,
  Pick = 2,
  Photo = 3
}
Item2dState = {Active = 1, UnActive = 2}
AiState = {
  patrol = 1,
  closer = 2,
  far = 3,
  cheese = 4
}
Item2dId = {Camera = 10002, Cheese = 10003}
Buff2dId = {
  Invincible = 106,
  NpcAttacked = 107,
  Far = 108,
  HeroAttacked = 1001,
  HeroDead = 1002,
  Photoed = 1003
}
Buff2dType = {
  Invincible = 1,
  Accelerate = 2,
  Confusion = 3,
  Attack = 4,
  Invisible = 5,
  Far = 7,
  Attacked = 101,
  Death = 102,
  Photoed = 103,
  OnIce = 2000,
  OnRollBand = 2001
}
GameState2d = {Start = 1, Stop = 2}
TimeConfig2d = {
  Success = 1,
  Fail = 1,
  Rule = 1
}
Game2dPlayType = {Limit = 1, UnLimit = 2}
GlobalGameState2d = GameState2d.Stop

function SetGlobalGameMini2DStart()
  GlobalGameState2d = GameState2d.Start
  Time.timeScale = 1
end

function SetGlobalGameMini2DStop()
  GlobalGameState2d = GameState2d.Stop
end
