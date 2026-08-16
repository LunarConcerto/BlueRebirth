local StageManager = class("util.StageManager")
local mainStage = require("stage.MainStage"):new()
local loginStage = require("stage.LoginStage"):new()
local battleStage = require("stage.BattleStage"):new()
local lastStage
local StageType = {
  [EStageType.eStageLogin] = loginStage,
  [EStageType.eStageMain] = mainStage,
  [EStageType.eStageSimpleBattle] = battleStage,
  [EStageType.eStageReplayBattle] = battleStage,
  [EStageType.eStageResumeBattle] = battleStage,
  [EStageType.eStagePvpBattle] = battleStage
}

function StageManager:initialize()
  eventManager:RegisterEvent(LuaCSharpEvent.StageEnter, function(self, param)
    self:_StageEnter(param)
  end, self)
  eventManager:RegisterEvent(LuaCSharpEvent.LeaveStage, self._StageLeave, self)
end

function StageManager:_StageEnter(param)
  local curStage = param[1]
  local enterParam = param[2]
  if StageType[curStage] ~= nil then
    StageType[curStage]:StageEnter(lastStage, enterParam)
    eventManager:SendEvent(LuaEvent.StageEnter, curStage)
  end
  lastStage = curStage
end

function StageManager:_StageLeave()
  GR.cameraManager:releaseAll()
  if StageType[lastStage] ~= nil then
    StageType[lastStage]:StageLeave()
    eventManager:SendEvent(LuaEvent.StageLeave, lastStage)
  end
end

function StageManager:GetCurStageType()
  return lastStage
end

function StageManager:GetCurStageObj()
  return StageType[lastStage]
end

function StageManager:Goto(nStageId, objParam, bRestart)
  self:__OnGotoStage(nStageId, objParam, bRestart)
  if bRestart ~= nil then
    CSharpStageMgr:Goto(nStageId, objParam, bRestart)
  else
    CSharpStageMgr:Goto(nStageId, objParam)
  end
end

function StageManager:__OnGotoStage(nStageId, objParam)
  if nStageId == EStageType.eStageSimpleBattle then
    self:__SetGuideInfo(nStageId, objParam)
    self:__SetNpcAssistInfo(nStageId, objParam)
  elseif nStageId == EStageType.eStageLaunch then
    SoundHelper.UnloadSFX()
  end
end

function StageManager:__SetGuideInfo(nStageId, objParam)
  local bInGuide = GR.guideHub:isInGuide()
  objParam.IsInGuide = bInGuide
end

function StageManager:__SetNpcAssistInfo(nStageId, objParam)
  local tblShips = objParam.BattlePlayer.FleetInfo.Ships
  for k, ship in pairs(tblShips) do
    local bAssistNpc = npcAssistFleetMgr:IsNpcHeroId(ship.HeroId)
    ship.bAssistNpc = bAssistNpc
  end
end

function StageManager:Shuntdown()
  CSharpStageMgr:Shuntdown()
end

function StageManager:IsLoading()
  return CSharpStageMgr:IsLoading()
end

function StageManager:GetCurStage()
  return CSharpStageMgr:GetCurStage()
end

function StageManager:GetLoadProgress()
  return CSharpStageMgr:GetLoadProgress()
end

function StageManager:GetStageObj(nType)
  return StageType[nType]
end

return StageManager
