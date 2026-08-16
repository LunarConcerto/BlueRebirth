local BattleStage = class("stage.BattleStage", BaseStage)

function BattleStage:initialize()
  self.enterParam = nil
end

function BattleStage:StageEnter(nLastStage, param)
  memoryUtil.LuaMemory("\232\191\155\229\133\165\230\136\152\230\150\151\231\138\182\230\128\129")
  self:RegisterEvent(LuaCSharpEvent.BattleNetDisconnect, excMgr._OpenLogin)
  self:RegisterEvent(LuaCSharpEvent.LoadingBattleKick, excMgr._UserKick)
  self:RegisterEvent(LuaEvent.UserKick, excMgr._UserKick)
  eventManager:SendEvent(LuaEvent.BattleStageEnter, nil)
  DropRewardsHelper.RecordsHasGirl()
  vivoSDKInterface:sendChangeScene(vivoSDKInterface.sceneNames.GAME_SCENE)
end

function BattleStage:StageLeave()
  CS.UITweener.audioSwitch = false
  eventManager:SendEvent(LuaEvent.BattleStageLeave, nil)
  eventManager:UnregisterEventByHandler(self)
  self:UnregisterAllEvent()
  Logic.copyLogic:SetUserEnterBattle(false)
  Logic.setLogic:_UnregisterBattle()
  memoryUtil.LuaMemory("\231\166\187\229\188\128\230\136\152\230\150\151\231\138\182\230\128\129")
end

return BattleStage
