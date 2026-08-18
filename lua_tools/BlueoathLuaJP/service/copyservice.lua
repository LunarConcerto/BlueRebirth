local CopyService = class("servic.CopyService", Service.BaseService)

function CopyService:initialize()
  self:_InitHandlers()
end

function CopyService:_InitHandlers()
  self:BindEvent("copy.GetCopy", self._GetCopyService, self)
  self:BindEvent("copy.StartBase", self._CopyStartBase, self)
  self:BindEvent("copy.PassBase", self._CopyPassBase, self)
  self:BindEvent("copy.QuitBase", self._QuitBattleCallBack, self)
  self:BindEvent("copy.StarReward", self._StarRewardCallback, self)
  self:BindEvent("copy.GetRandomFactors", self._GetRandomFactorCallback, self)
  self:BindEvent("copyinfo.GetCopyInfo", self._GetCopyInfoRet, self)
  self:BindEvent("copyinfo.DotBase", self._DotBaseRet, self)
  self:BindEvent("copy.FetchRewardBox", self._FetchRewardBox, self)
  self:BindEvent("copy.DeleteRecord", self._DeleteRecord, self)
  self:BindEvent("copy.GetRecord", self._GetRecord, self)
  self:BindEvent("copy.TacticOn", self._TacticOn, self)
  self:BindEvent("copy.UnLockCopy", self._UnLockCopy, self)
  self:BindEvent("archiveCopy.ArchiveCopyData", self._ArchiveCopyData, self)
  self:BindEvent("copy.ChooseSfLv", self._ChooseSfLvRet, self)
  self:BindEvent("boss.GetBossData", self._GetBossCopyDataRet, self)
  self:BindEvent("boss.UpdateBossData", self._GetBossCopyDataRet, self)
  self:BindEvent("boss.GetBossUserDamageRankList", self._GetBossSingleRank, self)
  self:BindEvent("boss.GetBossGuildDamageRankList", self._GetBossTeamRank, self)
  self:BindEvent("mopUp.GetMopUpData", self.BackSweepCopyInfo, self)
  self:BindEvent("mopUp.CheckSweep", self.GetServerMaxSweepTeam, self)
  self:BindEvent("copy.PvpStartBase", self._CopyStartBase, self)
  self:BindEvent("battle.pvpMatchReadyTimeout", self._BackMatchTimeout, self)
  self:BindEvent("copyextra.AddCopyRewardCount", self._AddCopyRewardCountRet, self)
  self:BindEvent("copyextra.UpdateCopyExtraInfo", self._UpdateCopyExtraInfoRet, self)
  self:BindEvent("battle.pvpMatchReady", self._BackMatchSucess, self)
end

function CopyService:_BackMatchTimeout(ret, state, err, errmsg)
  if err ~= 0 then
    logError("errCode:", err, "msg:", errmsg, "ret,", ret)
  else
    local arg = {
      uid = Data.userData:GetUserData().Uid
    }
    Service.matchService:SendMatchLeave(arg)
    self:SendLuaEvent(LuaEvent.MatchPreFail)
  end
end

function CopyService:_BackMatchSucess(ret, state, err, errmsg)
  if err ~= 0 then
    logError("errCode:", err, "msg:", errmsg, "ret,", ret)
  else
    local info = dataChangeManager:PbToLua(ret, match_pb.TPVPMATCHREADYRET)
    if info ~= nil then
      self:SendLuaEvent(LuaEvent.MatchSuccess, info.RoomId)
    end
  end
end

function CopyService:GetSweepCopyInfo()
  self:SendNetEvent("mopUp.GetMopUpData")
end

function CopyService:StartSweepCopy(args)
  self:SendNetEvent("mopUp.StartSweep", args)
end

function CopyService:GetSweepMaxFleetNum()
  self:SendNetEvent("mopUp.CheckSweep")
end

function CopyService:StopSweepCopy(config)
  config = dataChangeManager:LuaToPb(config, mopUp_pb.TMOPUPARG)
  self:SendNetEvent("mopUp.StopSweep", config)
end

function CopyService:GetServerMaxSweepTeam(ret, state, err, errmsg)
  if err ~= 0 then
    logError("errCode:", err, "msg:", errmsg, "ret,", ret)
  else
    local info = dataChangeManager:PbToLua(ret, mopUp_pb.TMOPUPRET)
    if info ~= nil and info.sweepFleetsNum ~= nil then
      Data.copyData:SetMaxFleetNum(info.sweepFleetsNum)
      self:SendLuaEvent(LuaEvent.UpdateSweepFleetMaxNum)
    end
  end
end

function CopyService:BackSweepCopyInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("ErrCode is :", err)
  else
    local info = dataChangeManager:PbToLua(ret, mopUp_pb.TMOPUPRET)
    Data.copyData:SetSweepCopyInfo(info)
    local RewardInfo = {}
    local ExtraReward = {}
    local allReward = {}
    if info ~= nil and info.passRets ~= nil and #info.passRets >= 1 then
      for i = 1, #info.passRets do
        if info.passRets[i] ~= nil and info.passRets[i].Reward ~= nil then
          for j = 1, #info.passRets[i].Reward do
            local rewardNormal = info.passRets[i].Reward[j]
            table.insert(RewardInfo, rewardNormal)
          end
        end
      end
      for i = 1, #info.passRets do
        if info.passRets[i] ~= nil and info.passRets[i].ExtraReward ~= nil then
          for j = 1, #info.passRets[i].ExtraReward do
            local rewardExtra = info.passRets[i].ExtraReward[j]
            table.insert(ExtraReward, rewardExtra)
          end
        end
      end
      local chapterId = Logic.copyLogic:GetChapterIdByCopyId(info.passRets[1].CopyId)
      local configInfo, copyType = Logic.copyLogic:GetCopyTypeByChapterId(chapterId)
      local isMerage = true
      if copyType == Logic.copyLogic.SelectCopyType.DailyCopy then
        isMerage = false
      end
      if isMerage then
        if RewardInfo ~= nil and 0 < #RewardInfo then
          for i = 1, #RewardInfo do
            table.insert(allReward, RewardInfo[i])
          end
        end
        if ExtraReward ~= nil and 0 < #ExtraReward then
          for i = 1, #ExtraReward do
            table.insert(allReward, ExtraReward[i])
          end
        end
        if allReward ~= nil and 0 < #allReward then
          UIHelper.OpenPage("GetRewardsPage", {Rewards = allReward, DontMerge = false})
        end
      elseif RewardInfo ~= nil and 0 < #RewardInfo then
        local param = {}
        if ExtraReward ~= nil and 0 < #ExtraReward then
          param = {
            Rewards = RewardInfo,
            DontMerge = false,
            ExtraRewards = ExtraReward
          }
        else
          param = {Rewards = RewardInfo, DontMerge = false}
        end
        UIHelper.OpenPage("GetRewardsPage", param)
      end
    end
    self:SendLuaEvent(LuaEvent.UpdateSweepInfo)
    self:SendLuaEvent(LuaEvent.UpdateFleetSweepInfo)
  end
end

function CopyService:SendQuitBattle(copyId, isRunningFight, isPass, heroInfo)
  local args = {
    CopyId = copyId,
    IsRunningFight = isRunningFight,
    IsPass = isPass,
    HeroInfo = heroInfo
  }
  Service.cacheDataService:ClearLocalCacheId()
  args = dataChangeManager:LuaToPb(args, copy_pb.TQUITBASEARG)
  self:SendNetEvent("copy.QuitBase", args)
end

function CopyService:_QuitBattleCallBack(ret, state, err, errmsg)
  Service.cacheDataService:ClearLocalCacheId()
  if err ~= 0 then
    logError("QuitBase" .. errmsg)
    return
  end
  self:SendLuaEvent(LuaEvent.QuitCopy)
end

function CopyService:UnLockCopy(copyId)
  local arg = {CopyId = copyId}
  arg = dataChangeManager:LuaToPb(arg, copy_pb.TUNLOCKEDCOPYARG)
  self:SendNetEvent("copy.UnLockCopy", arg)
end

function CopyService:_UnLockCopy(ret, state, err, errmsg)
  if err ~= 0 then
    logError("errCode:" .. err .. ",msg:" .. errmsg)
  else
    self:_RefreshLockCopy(ret, state, err, errmsg)
  end
end

function CopyService:_RefreshLockCopy(ret, state, err, errmsg)
  self:SendLuaEvent(LuaEvent.RefreshLockCopy)
end

function CopyService:JoinBattleFleetList(strategyId, fleetId, chapterId, copyId, isRunningFight, fleetType, fleets, isLimit)
  local fleetList = {}
  local copyID = copyId
  local chapterID = chapterId
  local copyDisplayConf = {}
  if not isRunningFight then
    copyDisplayConf = Logic.copyLogic:GetCopyDesConfig(copyID)
  else
    copyID = Logic.copyLogic:GetCopyChaseInfo(chapterId, copyId)
    copyDisplayConf = Logic.copyLogic:GetCopyDesConfig(copyID)
  end
  if copyDisplayConf.max_fleet > 0 and fleets ~= nil and 0 < #fleets then
    local fleetIDs = {}
    for _, v in pairs(fleets) do
      table.insert(fleetIDs, v.modeId)
    end
    local myFleetId
    local posIndex = 0
    for f = 1, #fleetIDs do
      local fleet = {}
      myFleetId = fleetIDs[f]
      fleet.Index = posIndex
      fleet.HeroIdList = {}
      fleet.StrategyId = Data.fleetData:GetStrategyDataById(myFleetId)
      local myShips = Data.fleetData:GetShipByFleet(myFleetId)
      for i = 1, #myShips do
        table.insert(fleet.HeroIdList, myShips[i])
      end
      table.insert(fleetList, fleet)
      posIndex = posIndex + 1
    end
    return fleetList
  end
  local hasNpcAssist = npcAssistFleetMgr:CheckNpcAssist(copyID)
  if hasNpcAssist then
    local fleet = {}
    fleet.Index = 0
    fleet.HeroIdList = npcAssistFleetMgr:CreateStartBaseHeroList()
    fleet.StrategyId = strategyId
    table.insert(fleetList, fleet)
  else
    local myFleetId = fleetId or 1
    local posIndex = 0
    local strategyId = Data.fleetData:GetStrategyDataById(myFleetId, fleetType)
    local battleHeroIdList = Data.fleetData:GetShipByFleet(myFleetId, fleetType)
    local teamTab = copyDisplayConf.split_team
    for index = 1, #teamTab do
      local fleet = {}
      fleet.Index = posIndex
      fleet.StrategyId = strategyId
      fleet.HeroIdList = {}
      local heroIndexsConf = teamTab[index]
      for _, heroIndex in ipairs(heroIndexsConf) do
        if 0 < #fleetList and battleHeroIdList[heroIndex] then
          for _, f in ipairs(fleetList) do
            if table.containV(f.HeroIdList, battleHeroIdList[heroIndex]) then
              logError("\233\133\141\231\189\174\232\161\168\233\135\140\233\133\141\231\189\174\228\186\134\233\135\141\229\164\141\231\154\132\232\139\177\233\155\132id")
            end
          end
        end
        if table.containKey(battleHeroIdList, heroIndex) then
          table.insert(fleet.HeroIdList, battleHeroIdList[heroIndex])
        end
      end
      if 0 < #fleet.HeroIdList then
        table.insert(fleetList, fleet)
        posIndex = posIndex + 1
      end
    end
    if not isLimit then
      local battleExHeroIdList = Data.fleetData:GetExShipByFleet(myFleetId, fleetType)
      if 0 < #battleExHeroIdList and 0 < #fleetList then
        local fleet = {}
        fleet.Index = #fleetList
        fleet.StrategyId = 0
        fleet.HeroIdList = {}
        for i = 1, #battleExHeroIdList do
          table.insert(fleet.HeroIdList, battleExHeroIdList[i])
        end
        table.insert(fleetList, fleet)
      end
    end
    if 0 < #fleetList then
      for index, fleet in ipairs(fleetList) do
        if index <= #teamTab then
          fleet.HeroIdList = Logic.fleetLogic:CheckFleetHeroNum(copyID, fleet.HeroIdList, false)
        else
          fleet.HeroIdList = Logic.fleetLogic:CheckFleetHeroNum(copyID, fleet.HeroIdList, true)
        end
      end
    end
  end
  return fleetList
end

function CopyService:SendStartBase(chapterId, baseId, isRunningFight, tacticId, cacheId, strategyId, dailyGroupId, battleMode, exBuff, roomId, isPvePtMode)
  strategyId = strategyId or -1
  local fleetType = Logic.copyLogic:GetFleetTypeById(chapterId)
  local power = Logic.fleetLogic:GetFleetPower(tacticId, fleetType)
  local curFleetId = Logic.fleetLogic:GetBattleFleetId(fleetType)
  local curNvNFleets = Logic.fleetLogic:GetBattleNvNFleets(fleetType)
  local copyCfg = configManager.GetDataById("config_copy_display", baseId)
  local isLimit = copyCfg.attached_fleet == nil or copyCfg.attached_fleet == 0
  local heroList = self:JoinBattleFleetList(strategyId, curFleetId, chapterId, baseId, isRunningFight, fleetType, curNvNFleets, isLimit)
  local animMode = CacheUtil.GetConfigBattleAnimMode()
  local matchRoomId = 0
  if roomId then
    matchRoomId = roomId
  end
  local args = {
    ChapterId = chapterId,
    CopyId = baseId,
    IsRunningFight = isRunningFight,
    TacticId = tacticId,
    CacheId = cacheId,
    HeroList = heroList,
    StrategyId = strategyId,
    DailyGroupId = dailyGroupId,
    BattleMode = battleMode,
    AnimMode = animMode,
    Power = power,
    ExBuff = exBuff,
    RoomId = matchRoomId,
    IsSpeedUpMode = false,
    IsPvePtMode = isPvePtMode or false
  }
  args = dataChangeManager:LuaToPb(args, copy_pb.TSTARTBASEARG)
  self:SendNetEvent("copy.StartBase", args)
end

function CopyService:SendStartBasePve(chapterId, baseId, isRunningFight, tacticId, cacheId, strategyId, dailyGroupId, battleMode, exBuff, roomId, matchType)
  strategyId = strategyId or -1
  matchType = matchType or 0
  local fleetType = Logic.copyLogic:GetFleetTypeById(chapterId)
  local power = Logic.fleetLogic:GetFleetPower(tacticId, fleetType)
  local curFleetId = Logic.fleetLogic:GetBattleFleetId(fleetType)
  local copyCfg = configManager.GetDataById("config_copy_display", baseId)
  local isLimit = copyCfg.attached_fleet == nil or copyCfg.attached_fleet == 0
  local heroList = self:JoinBattleFleetList(strategyId, curFleetId, chapterId, baseId, isRunningFight, fleetType, nil, isLimit)
  local animMode = CacheUtil.GetConfigBattleAnimMode()
  local matchRoomId = 0
  if roomId then
    matchRoomId = roomId
  end
  local args = {
    ChapterId = chapterId,
    CopyId = baseId,
    IsRunningFight = isRunningFight,
    TacticId = tacticId,
    CacheId = cacheId,
    HeroList = heroList,
    StrategyId = strategyId,
    DailyGroupId = dailyGroupId,
    BattleMode = battleMode,
    AnimMode = animMode,
    Power = power,
    ExBuff = exBuff,
    RoomId = matchRoomId,
    MatchType = matchType
  }
  args = dataChangeManager:LuaToPb(args, copy_pb.TSTARTBASEARG)
  self:SendNetEvent("copy.PvpStartBase", args)
end

function CopyService:SendStartBaseTeamPve(arg)
  arg.strategyId = arg.strategyId or -1
  arg.matchType = arg.matchType or 0
  local fleetType = Logic.copyLogic:GetFleetTypeById(arg.chapterId)
  local curFleetId = Logic.fleetLogic:GetBattleFleetId(fleetType)
  local heroList = arg.heroList
  local animMode = CacheUtil.GetConfigBattleAnimMode()
  local matchRoomId = 0
  if arg.roomId then
    matchRoomId = arg.roomId
  end
  local power = 0
  for _, v in ipairs(heroList) do
    local heroId = v
    local heroPower = Logic.attrLogic:_RecalBattlePower(heroId, fleetType, arg.baseId)
    power = power + heroPower
  end
  local exHeroList = arg.exHeroList
  if exHeroList and next(exHeroList) ~= nil then
    for _, v in ipairs(exHeroList) do
      local heroId = v
      local heroPower = Logic.attrLogic:_RecalBattlePower(heroId, fleetType, arg.baseId)
      power = power + heroPower
    end
  end
  local pbHeroList = {}
  pbHeroList[1] = {
    Index = 0,
    StrategyId = arg.strategyId,
    HeroIdList = heroList
  }
  if exHeroList and next(exHeroList) ~= nil then
    pbHeroList[2] = {
      Index = 1,
      StrategyId = 0,
      HeroIdList = exHeroList
    }
  end
  local args = {
    ChapterId = arg.chapterId,
    CopyId = arg.baseId,
    IsRunningFight = arg.isRunningFight,
    TacticId = arg.tacticId,
    CacheId = arg.cacheId,
    HeroList = pbHeroList,
    StrategyId = arg.strategyId,
    DailyGroupId = arg.dailyGroupId,
    BattleMode = arg.battleMode,
    AnimMode = animMode,
    Power = power,
    ExBuff = nil,
    RoomId = matchRoomId,
    MatchType = arg.matchType,
    IsSpeedUpMode = arg.isSpeedUpMode or false,
    IsPvePtMode = arg.isPvePtMode or false
  }
  logWarning("CopyService:SendStartBaseTeamPve args:", args)
  args = dataChangeManager:LuaToPb(args, copy_pb.TSTARTBASEARG)
  self:SendNetEvent("copy.PvpStartBase", args)
end

function CopyService:_GetCopyService(ret, state, err, errmsg)
  if err == 0 then
    local copy = dataChangeManager:PbToLua(ret, copy_pb.TUSERCOPYINFO)
    Data.copyData:SetData(copy)
    self:SendLuaEvent(LuaEvent.GetCopyData)
    if Data.copyData:IsPassNewCopy() then
      self:SendLuaEvent(LuaEvent.PassNewCopy)
    end
    if Data.copyData:GetPassNewDaily() then
      self:SendLuaEvent(LuaEvent.PassNewDailyCopy, copy)
    end
  end
end

function CopyService:_CopyStartBase(ret, state, err, errmsg)
  if err == 0 then
    local StartBaseRet = dataChangeManager:PbToLua(ret, copy_pb.TSTARTBASERET)
    self:SendLuaEvent(LuaEvent.StartTeamPve)
    self:SendLuaEvent(LuaEvent.CopyStartBase, StartBaseRet)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:SendPassBase()
  local pbCopyEnd = copy_pb.TPassBaseArg()
  pbCopyEnd.BaseId = 1
  pbCopyEnd.EnemyId = 1
  pbCopyEnd.IsPass = true
  pbCopyEnd.StarLevel = 1
  pbCopyEnd.BossId = 1
  pbCopyEnd.IsRunningFight = false
  pbCopyEnd.BattleString = ""
  self:SendNetEvent("copy.PassBase", pbCopyEnd)
end

function CopyService:_CopyPassBase(ret, state, err, errmsg)
  if err == 0 then
    local tabRet = dataChangeManager:PbToLua(ret, copy_pb.TPASSBASERET) or {}
    Logic.dailyCopyLogic:SetBuildShipInfo(tabRet)
    eventManager:SendEvent("CopyPassBase", tabRet or {})
    Service.cacheDataService:ClearLocalCacheId()
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:SendStarReward(chapterId, level)
  local args = {ChapterId = chapterId, Index = level}
  args = dataChangeManager:LuaToPb(args, copy_pb.TSTARREWARDARG)
  self:SendNetEvent("copy.StarReward", args, args)
end

function CopyService:_StarRewardCallback(ret, state, err, errmsg)
  if err == 0 then
    local starRewardRet = dataChangeManager:PbToLua(ret, copy_pb.TSTARREWARDRET)
    self:SendLuaEvent(LuaEvent.StarReward, state)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:SendGetRandomFactors(copyId)
  local args = {CopyId = copyId}
  args = dataChangeManager:LuaToPb(args, copy_pb.TGETRANDOMFACTORARG)
  self:SendNetEvent("copy.GetRandomFactors", args)
end

function CopyService:_GetRandomFactorCallback(ret, state, err, errmsg)
  if err == 0 then
    local factorRet = dataChangeManager:PbToLua(ret, copy_pb.TGETRANDOMFACTORRET)
    eventManager:SendEvent(LuaEvent.GetRandFactor, factorRet)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:SendGetCopyInfo(copyId, star)
  local args = {CopyId = copyId, ExStar = star}
  args = dataChangeManager:LuaToPb(args, copyinfo_pb.TCOPYINFOARG)
  self:SendNetEvent("copyinfo.GetCopyInfo", args)
end

function CopyService:_GetCopyInfoRet(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, copyinfo_pb.TCOPYINFORET)
    eventManager:SendEvent(LuaEvent.GetCopyInfo, info)
  else
    logError("GetCopyInfo err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:SendDotBase(copyId)
  local args = {CopyId = copyId}
  args = dataChangeManager:LuaToPb(args, copy_pb.TDOTBASEARG)
  self:SendNetEvent("copy.DotBase", args)
end

function CopyService:_DotBaseRet(ret, state, err, errmsg)
  if err == 0 then
  else
    logError("Copy.DotBase err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:FetchRewardBox(args)
  args = dataChangeManager:LuaToPb(args, copy_pb.TSTARREWARDARG)
  self:SendNetEvent("copy.FetchRewardBox", args)
end

function CopyService:_FetchRewardBox(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, copy_pb.TSTARREWARDRET)
    eventManager:SendEvent(LuaEvent.FetchRewardBox, info)
  else
    logError("Copy._FetchRewardBox err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:DeleteRecord(args)
  args = dataChangeManager:LuaToPb(args, copy_pb.TCOPYRECORD)
  self:SendNetEvent("copy.DeleteRecord", args)
end

function CopyService:_DeleteRecord(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, copyinfo_pb.TCOPYRECORDLIST)
    eventManager:SendEvent(LuaEvent.DeleteRecord, info)
  else
    logError("Copy.DeleteRecord", err, errmsg)
  end
end

function CopyService:GetRecord(args)
  args = dataChangeManager:LuaToPb(args, copy_pb.TCOPYRECORD)
  self:SendNetEvent("copy.GetRecord", args)
end

function CopyService:_GetRecord(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, copyinfo_pb.TCOPYRECORDLIST)
    eventManager:SendEvent(LuaEvent.GetRecord, info)
  else
    logError("Copy.GetRecord", err, errmsg)
  end
end

function CopyService:TacticOn(args)
  args = dataChangeManager:LuaToPb(args, copy_pb.TCOPYRECORD)
  self:SendNetEvent("copy.TacticOn", args)
end

function CopyService:_TacticOn(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, tactic_pb.TSELFTACTIS)
    Data.fleetData:SetData(info)
    self:SendLuaEvent(LuaEvent.SetFleetMsg)
    self:SendLuaEvent(LuaEvent.TacticOn, info)
  else
    logError("Copy.TacticOn", err, errmsg)
  end
end

function CopyService:_ArchiveCopyData(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, archiveCopy_pb.TARCHIVECOPYDATA)
    self:SendLuaEvent(LuaEvent.GetArchiveCopyData, info)
  else
    logError("archiveCopy.ArchiveCopyData", err, errmsg)
  end
end

function CopyService:SendChooseSafeLv(copyId, lv)
  local args = {CopyId = copyId, SafeLv = lv}
  args = dataChangeManager:LuaToPb(args, copy_pb.TCOPYCHOOSESFLVARG)
  self:SendNetEvent("copy.ChooseSfLv", args)
end

function CopyService:_ChooseSfLvRet(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.ChooseSafeLvOk)
  else
    logError("copy.ChooseSfLv err: ", err, errmsg)
  end
end

function CopyService:SendPassMiniGame(args)
  args = dataChangeManager:LuaToPb(args, copy_pb.TPASSBASEARG)
  self:SendNetEvent("copy.PassMiniGame", args)
end

function CopyService:_SendPassMiniGame(ret, state, err, errmsg)
  if err == 0 then
    local tabRet = dataChangeManager:PbToLua(ret, copy_pb.TPASSBASERET) or {}
    self:SendLuaEvent(LuaEvent.MiniGameRet, tabRet)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:SendGetBossData()
  self:SendNetEvent("boss.GetBossData")
end

function CopyService:_GetBossCopyDataRet(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, boss_pb.TBOSSRET)
    Data.copyData:SetBossInfo(info)
    self:SendLuaEvent(LuaEvent.BossInfoRet)
  else
    logError("boss.GetBossData err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:SendGetBossSingleRank()
  self:SendNetEvent("boss.GetBossUserDamageRankList")
end

function CopyService:_GetBossSingleRank(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, boss_pb.TBOSSUSERDAMAGERANKLISTRET)
    self:SendLuaEvent(LuaEvent.UpdateBossSingeRank, info)
  else
    logError("boss.GetBossUserDamageRankList err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:SendGetBossTeamleRank()
  self:SendNetEvent("boss.GetBossGuildDamageRankList")
end

function CopyService:_GetBossTeamRank(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, boss_pb.TBOSSGUILDDAMAGERANKLISTRET)
    self:SendLuaEvent(LuaEvent.UpdateBossTeamRank, info)
  else
    logError("boss.GetBossGuildDamageRankList err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function CopyService:SendAddCopyRewardCount(chapterId, num)
  local arg = {Chapter = chapterId, RewardTime = num}
  local msg = dataChangeManager:LuaToPb(arg, copyextra_pb.TCOPYREWARDTIMES)
  self:SendNetEvent("copyextra.AddCopyRewardCount", msg)
end

function CopyService:_AddCopyRewardCountRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("copyextra.AddCopyRewardCount failed " .. errmsg .. ", err:" .. err)
  else
    self:SendLuaEvent(LuaEvent.UpdateCopyRewardCount)
  end
end

function CopyService:_UpdateCopyExtraInfoRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("UpdateActMultiPveInfo failed " .. errmsg .. ", err:" .. err)
  else
    local info = dataChangeManager:PbToLua(ret, copyextra_pb.TCOPYEXTRAINFORET)
    Data.copyData:SetCopyExtraInfo(info)
    self:SendLuaEvent(LuaEvent.UpdateCopyExtraInfo)
  end
end

return CopyService
