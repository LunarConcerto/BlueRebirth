local PrepareBattleMgr = class("util.PrepareBattleMgr")

function PrepareBattleMgr:initialize()
  self:ResetData()
end

function PrepareBattleMgr:ResetData()
  self.fleetId = 0
  self.chapterId = 0
  self.copyId = 0
  self.isRunningFight = false
  self.copyType = 1
  
  function self.handleParamsCB(param)
  end
  
  self.dailyGroupId = nil
end

function PrepareBattleMgr:StartBattle(fleetId, chapterId, copyId, isRunningFight, copyType, handleParamsCB, strategyId, restart, battleMode, dailyGroupId)
  self.fleetId = fleetId
  self.chapterId = chapterId
  self.copyId = copyId
  self.copyType = copyType
  self.isRunningFight = isRunningFight
  self.handleParamsCB = handleParamsCB
  self.strategyId = strategyId
  self.restart = not not restart
  self.BattleMode = battleMode
  self.dailyGroupId = dailyGroupId
  eventManager:RegisterEvent(LuaEvent.CopyStartBase, self._CopyEnter, self)
  eventManager:RegisterEvent(LuaEvent.CacheDataRet, self._CacheDataRet, self)
  Service.cacheDataService:SendCacheData("copy.StartBase", "PrepareBattleMgr")
end

function PrepareBattleMgr:RestartBattle()
  if self.chapterId and self.copyId and self.fleetId then
    self:StartBattle(self.fleetId, self.chapterId, self.copyId, self.isRunningFight, self.copyType, function(ret, param)
      if self.cachedParam then
        for k, v in pairs(self.cachedParam) do
          if param[k] == nil or k == "RandomFactors" or k == "ShipEquipGridInfo" then
            param[k] = v
          end
        end
      end
    end, self.strategyId, true)
  end
end

function PrepareBattleMgr:_CacheDataRet(cacheId)
  Service.copyService:SendStartBase(self.chapterId, self.copyId, self.isRunningFight, self.fleetId, cacheId, self.strategyId, self.dailyGroupId, self.BattleMode)
end

function PrepareBattleMgr:_CopyEnter(ret)
  if ret.Rid == nil then
    noticeManager:ShowMsgBox(UIHelper.GetString(920000185))
    return
  end
  local param = self:CreateDefaultBattleParam(self.copyId, self.copyType, ret)
  param.CopyPass = Logic.copyLogic:IsCopyPassById(self.copyId)
  self.handleParamsCB(ret, param)
  self.cachedParam = param
  local safeLv, safePoint = Logic.copyLogic:GetCopySafeInfo(self.copyId)
  Logic.copyLogic:SetAttackCopyInfo(self.copyId, param.IsRunningFight, safeLv, safePoint)
  homeEnvManager:EnterBattle()
  Logic.copyLogic:SetUserEnterBattle(true)
  Logic.copyLogic:SetEnterLevelInfo(false)
  eventManager:UnregisterEvent(LuaEvent.CopyStartBase, self._CopyEnter, self)
  eventManager:UnregisterEvent(LuaEvent.CacheDataRet, self._CacheDataRet, self)
end

function PrepareBattleMgr:CreateDefaultBattleParam(copyId, copyType, ret)
  local param = {}
  param.RandomSeed = ret.RandomSeed
  param.BattlePlayer = ret.BattlePlayer
  param.CopyDictId = ret.Rid
  param.arrRes = ret.arrRes
  param.CopyId = copyId
  param.BossId = 0
  param.CopyPass = false
  param.PlayerUid = Data.userData:GetUserData().Uid
  param.BossProgress = 0
  param.ShipEquipGridInfo = {}
  param.IsPVETest = false
  param.CopyType = copyType
  param.IsRunningFight = false
  param.SuportEffect = {}
  param.SupportHeros = {}
  param.RandomFactors = {}
  param.EnemyFleet = ret.EnemyFleet
  param.SkipVcr = Data.illustrateData:GetSkipVcr()
  return param
end

return PrepareBattleMgr
