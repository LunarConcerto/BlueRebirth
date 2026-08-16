local SettlementLogic = class("logic.SettlementLogic")
require("ui.page.Settlement.SettlementHelper")

function SettlementLogic:initialize(...)
  self:_RegisterAllEvent()
  self:ResetData()
  SettlementLogic._InitBattleGrade()
end

function SettlementLogic:ResetData()
  self.m_curState = SettlementLogic.State.Blood
  self.m_bInSettle = false
  self.m_param = nil
  self:_ResetTimer()
end

function SettlementLogic:_ResetTimer()
  if self.m_rdelayTimer then
    self.m_rdelayTimer:Stop()
  end
  self.m_rdelayTimer = nil
end

function SettlementLogic._InitBattleGrade()
  local config = configManager.GetData("config_copy_grade_type")
  EvaGradeType = {}
  for id, info in pairs(config) do
    EvaGradeType[info.name] = id
  end
end

function SettlementLogic:GetBattleGradeConfig(grade)
  return configManager.GetDataById("config_copy_grade_type", grade)
end

function SettlementLogic:SetParam(param)
  self.m_param = param
end

function SettlementLogic:GetParam()
  return self.m_param
end

local WarningYellowId = 4
local WarningRedId = 5
SettlementLogic.WarningType = {
  Safe = 0,
  Normal = 1,
  Emergency = 2
}
SettlementLogic.State = {
  Blood = 1,
  Exp = 3,
  Damage = 4,
  Reward = 5,
  ShowGirl = 6,
  ShowBeforePlot = 7,
  ShowAfterPlot = 8,
  ExtraReward = 9,
  TaskReward = 10
}
SettlementLogic.Input = {
  Next = 1,
  Init = 2,
  Change = 3
}
local m_changing = false

function SettlementLogic:_RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.BattleStageEnter, self._RegisterBattle, self)
  eventManager:RegisterEvent(LuaEvent.BattleStageLeave, self._UnregisterBattle, self)
  eventManager:RegisterEvent(LuaCSharpEvent.TryPlaySettlementPSkillAnim, self._OnTryPlaySettlementPSkillAnim, self)
  eventManager:RegisterEvent(LuaCSharpEvent.SettlementTryAutoExe, self._OnTryAutoExe, self)
  eventManager:RegisterEvent(LuaEvent.ShareStart, self._OnShareStart, self)
  eventManager:RegisterEvent(LuaEvent.ShareOver, self._OnShareOver, self)
end

function SettlementLogic:_OnTryAutoExe()
  local isAuto = settlementExeManager:IsAutoExe()
  if isAuto then
    settlementExeManager:AutoExecute()
  end
end

function SettlementLogic:_UnRegisterAllEvent()
  eventManager:UnregisterEvent(LuaEvent.BattleStageEnter, self._RegisterBattle)
  eventManager:UnregisterEvent(LuaEvent.BattleStageLeave, self._UnregisterBattle)
end

function SettlementLogic:_RegisterBattle()
  eventManager:RegisterEvent(LuaCSharpEvent.SettlementDataChangeBefore, self.OnDataChangeBefore, self)
  eventManager:RegisterEvent(LuaCSharpEvent.SettlementChangeEnd, self.OnChangeEnd, self)
end

function SettlementLogic:OnDataChangeBefore(notification)
  memoryUtil.LuaMemory("\229\135\134\229\164\135\231\187\147\231\174\151")
  self:HandleDataBefore(notification)
  self.preHerodata = Logic.shipLogic:GetAllHeroSfId()
  eventManager:RegisterEvent("CopyPassBase", self._OnCopyPassBase, self)
end

function SettlementLogic:OnChangeEnd()
  m_changing = false
end

function SettlementLogic:_OnTryPlaySettlementPSkillAnim()
  if settlementSkillItemManager:HaveMyAnim() then
    settlementSkillItemManager:PlayMyAnim(SettlementPSkillPlayType.SAMETIME)
  elseif settlementSkillItemManager:HaveEnemyAnim() then
    settlementSkillItemManager:PlayEnemyAnim(SettlementPSkillPlayType.SAMETIME)
  else
    local duration = self:_getWaitToEvaluationDuration()
    local timer = Timer.New(function()
      eventManager:SendEvent(LuaEvent.SettlementEvaluation)
    end, duration, 1, false)
    timer:Start()
  end
end

function SettlementLogic:_getWaitToEvaluationDuration()
  return 2
end

function SettlementLogic:_UnregisterBattle()
  eventManager:UnregisterEvent(LuaCSharpEvent.SettlementDataChangeBefore, self.OnDataChangeBefore)
  eventManager:UnregisterEvent(LuaCSharpEvent.SettlementChangeEnd, self.OnChangeEnd)
  eventManager:UnregisterEvent("CopyPassBase", self._OnCopyPassBase)
  self:UnregisterNormalProcess()
  self:_TryCleanUpData()
end

function SettlementLogic:_OnShowGirlEnd()
  self.m_flowCtrl(SettlementLogic.Input.Next)
end

function SettlementLogic:_OnDropRewardEnd()
  self.m_flowCtrl(SettlementLogic.Input.Next)
end

function SettlementLogic:_OnEvaluationEnd()
  self.m_flowCtrl(SettlementLogic.Input.Next)
end

function SettlementLogic:_OnPlotEnd(plotType)
  if plotType == PlotTriggerType.fleetbattle_before_count then
    self.m_flowCtrl(SettlementLogic.Input.Init)
  elseif plotType == PlotTriggerType.fleetbattle_after_count then
    self.m_flowCtrl(SettlementLogic.Input.Next)
  end
end

function SettlementLogic:_OnCopyPassBase(param)
  eventManager:RegisterEvent(LuaEvent.EvaluationEnd, self._OnEvaluationEnd, self)
  eventManager:RegisterEvent(LuaEvent.ShowGirlEnd, self._OnShowGirlEnd, self)
  eventManager:RegisterEvent(LuaEvent.ShowRewardEnd, self._OnDropRewardEnd, self)
  self.bNeedResend = false
  if param == nil then
    param = self:GetDefaultParam()
    self:SetParam(param)
  else
    self:HandleDataAfter(param)
  end
  self.m_flowCtrl = self:InitFlowCtrl()
  self.m_flowCtrl(self.Input.Init)
  eventManager:UnregisterEvent("CopyPassBase", self._OnCopyPassBase)
  eventManager:RegisterEvent(LuaEvent.PlotTriggerEnd, self._OnPlotEnd, self)
  self:_dotRewards(self:GetParam())
end

function SettlementLogic:_dotRewards(param)
  local copyType = Logic.copyLogic:GetChapterTypeByCopyId(param.copyInfo.id)
  local type2str = {
    [ChapterType.SeaCopy] = "seacopy_get",
    [ChapterType.DailyCopy] = "dailycopy_get"
  }
  if type2str[copyType] == nil then
    return
  end
  self:_dotBaseRewards(type2str[copyType], param)
end

function SettlementLogic:_dotBaseRewards(str, param)
  for _, reward in ipairs(param.rewards) do
    if reward.Type == GoodsType.EQUIP then
      Logic.equipLogic:DotGetEquip(str, reward.ConfigId)
    end
  end
  if param.extraReward then
    for _, reward in ipairs(param.extraReward) do
      if reward.Type == GoodsType.EQUIP then
        Logic.equipLogic:DotGetEquip(str, reward.ConfigId)
      end
    end
  end
end

function SettlementLogic:UnregisterNormalProcess()
  eventManager:UnregisterEvent(LuaEvent.EvaluationEnd, self._OnEvaluationEnd)
  eventManager:UnregisterEvent(LuaEvent.ShowGirlEnd, self._OnShowGirlEnd)
  eventManager:UnregisterEvent(LuaEvent.ShowRewardEnd, self._OnDropRewardEnd)
  eventManager:UnregisterEvent(LuaEvent.PlotTriggerEnd, self._OnPlotEnd)
end

function SettlementLogic:InitFlowCtrl()
  local curState = SettlementLogic.State.Blood
  local State = SettlementLogic.State
  local Input = SettlementLogic.Input
  local param = self:GetParam()
  local DoEnd = function()
    settlementExeManager:StopExeAndClear()
    self:UnregisterNormalProcess()
    if not IsNil(param.exitFunc) then
      param.exitFunc()
      param.exitFunc = nil
    end
    DropRewardsHelper.RecordsHasGirl()
    memoryUtil.LuaMemory("\231\187\147\230\157\159\231\187\147\231\174\151,\233\135\141\232\191\148\230\136\152\230\150\151")
  end
  local haveRes = not settlementExeManager:GetTaskFinish()
  if haveRes then
    local ok, executer = settlementExeManager:GenExecuter(State.Exp, function()
      curState = State.Exp
      eventManager:SendEvent("SETTLEMENT_ShowExp", nil)
      eventManager:SendEvent("PlayMVPAnim", nil)
    end, nil, true)
    if ok then
      settlementExeManager:RegisterExecuter(executer)
    end
  end
  local rewardType = RewardType.COMMON
  if param.firstPass == true then
    rewardType = RewardType.FIRSTPASS
  end
  local showRewards = function(args)
    return #args.rewards > 0 or args.extraReward and 0 < #args.extraReward or args.taskReward and #args.taskReward
  end
  local rewards = param.rewards
  local copyId = param.copyInfo.id
  local chapter = Logic.copyLogic:GetCopyChapter(copyId)
  local isGoodsCopy = chapter and chapter.class_type == ChapterType.GoodsCopy or false
  local rewardArgs = {
    Rewards = rewards,
    Page = "SettlementLogic",
    ExtraRewards = param.extraReward,
    RewardType = rewardType,
    IsGoodsCopy = isGoodsCopy,
    TaskRewards = param.taskReward,
    UsrAddExp = param.userAddExp
  }
  local ok, executer = settlementExeManager:GenExecuter(State.Reward, function(args)
    if showRewards(param) and not args.IsGoodsCopy then
      memoryUtil.LuaMemory("\230\152\190\231\164\186\231\187\147\231\174\151\229\165\150\229\138\177")
      curState = State.Reward
      UIHelper.OpenPage("GetRewardsPage", args)
      eventManager:SendEvent(LuaEvent.FinishSettlementHeroTween)
    else
      UIHelper.ClosePage("SettlementPage")
      curState = nil
      DoEnd()
    end
  end, rewardArgs, false)
  if ok then
    settlementExeManager:RegisterExecuter(executer)
  end
  local showTaskRewards = function(args)
    return args.taskReward and #args.taskReward > 0
  end
  if showTaskRewards(param) then
    local ok, executer = settlementExeManager:GenExecuter(State.TaskReward, function()
      eventManager:SendEvent(LuaEvent.REWARD_TaskRewardSkip)
    end, nil, false)
    if ok then
      settlementExeManager:RegisterExecuter(executer)
    end
  end
  local showOtherRewards = function(args)
    return #args.rewards > 0 and args.extraReward and 0 < #args.extraReward
  end
  if showOtherRewards(param) then
    local ok, executer = settlementExeManager:GenExecuter(State.ExtraReward, function()
      eventManager:SendEvent(LuaEvent.RewardsPageSkip)
    end, nil, false)
    if ok then
      settlementExeManager:RegisterExecuter(executer)
    end
  end
  local sm_id, heroId = Logic.settlementLogic.GetNeedShowGirl(rewards)
  if param.extraReward and sm_id == nil then
    sm_id, heroId = Logic.settlementLogic.GetNeedShowGirl(param.extraReward)
  end
  if param.taskReward and sm_id == nil then
    sm_id, heroId = Logic.settlementLogic.GetNeedShowGirl(param.taskReward)
  end
  local si_id
  if sm_id ~= nil then
    si_id = Logic.shipLogic:GetShipInfoId(sm_id)
  end
  local ok, executer = settlementExeManager:GenExecuter(State.ShowGirl, function(args)
    eventManager:SendEvent("AnimNext", nil)
    UIHelper.ClosePage("SettlementPage")
    UIHelper.ClosePage("GetRewardsPage")
    if sm_id and not self:CheckHasShip(sm_id) then
      memoryUtil.LuaMemory("\229\177\149\231\164\186\231\187\147\231\174\151\232\142\183\229\143\150\231\154\132\232\139\177\233\155\132")
      eventManager:FireEventToCSharp(LuaCSharpEvent.SettlementTurnOnOffCamera, false)
      args.battleOpen = true
      UIHelper.OpenPage("ShowGirlPage", args)
      curState = State.ShowGirl
    else
      curState = nil
      DoEnd()
    end
  end, {
    girlId = si_id,
    HeroId = heroId,
    getWay = GetGirlWay.battle,
    callback = function()
      eventManager:FireEventToCSharp(LuaCSharpEvent.SettlementTurnOnOffCamera, true)
    end
  }, false)
  if ok then
    settlementExeManager:RegisterExecuter(executer)
  end
  return function(input)
    self.m_curState = curState
    if input == Input.Init then
      if UIHelper.GetCurMainPageName() == "PlotPage" then
        return
      end
      memoryUtil.LuaMemory("\230\152\190\231\164\186\231\187\147\231\174\151")
      local haveRes = not settlementExeManager:GetTaskFinish()
      if haveRes then
        UIHelper.OpenPage("SettlementPage", param)
      else
        local isAuto = settlementExeManager:IsAutoExe()
        if isAuto then
          settlementExeManager:AutoExecute()
        else
          settlementExeManager:Execute(State.Reward)
        end
      end
    end
    if input == Input.Next then
      if curState == State.Blood then
        settlementExeManager:Execute(State.Exp)
      elseif curState == State.Exp or curState == State.Damage then
        settlementExeManager:Execute(State.Reward)
      elseif curState == State.Reward then
        settlementExeManager:Execute(State.ShowGirl)
      elseif curState == State.ShowGirl then
        local checkPlot = plotManager:CheckPlot(PlotTriggerType.fleetbattle_after_count, param.enemyFleetId)
        if checkPlot then
          curState = State.ShowAfterPlot
          plotManager:OpenPlotByType(PlotTriggerType.fleetbattle_after_count, param.enemyFleetId)
        else
          curState = nil
          DoEnd()
        end
      elseif curState == State.ShowAfterPlot then
        curState = nil
        DoEnd()
      end
    end
  end
end

function SettlementLogic:handleActivityParam(param)
  local res = {}
  if param and param.extraInfo then
    local middle = param.extraInfo
    res.merits = middle.merits
    res.dayIndex = middle.dayIndex
    res.dayTotal = middle.dayTotal
    res.percent = middle.percent
  end
  return res
end

function SettlementLogic:ShowEvaluation()
  local nenemy = self:_GetEnemyFleetNum()
  local dur = self:_GetResultDelayTime(nenemy)
  if 0 < dur then
    self:_ResetTimer()
    local timer = Timer.New(function()
      self:_ShowEvaluationImp()
    end, dur, 1, false)
    self.m_rdelayTimer = timer
    timer:Start()
  else
    self:_ShowEvaluationImp()
  end
end

function SettlementLogic:_ShowEvaluationImp()
  local state = SettlementLogic.State
  local curState = self.m_curState
  if curState and curState < state.Exp then
    local param = self:GetParam()
    UIHelper.OpenPage("EvaluationPage", {
      grade = param.grade,
      copyInfo = param.copyInfo,
      nenemy = #param.enemyFleetInfo,
      hasBattleGuard = param.hasBattleGuard
    })
  end
end

function SettlementLogic:_GetEnemyFleetNum()
  local param = self:GetParam()
  if param and param.enemyFleetInfo then
    return #param.enemyFleetInfo
  else
    return 0
  end
end

function SettlementLogic:_GetResultDelayTime(nenemy)
  local config = configManager.GetDataById("config_parameter", 316).arrValue
  local res = 0
  if nenemy <= 1 then
    res = config[1]
  else
    res = config[2]
  end
  return res
end

function SettlementLogic:GetActivityParam()
  local res = self:handleActivityParam(self:GetParam())
  return next(res) ~= nil, res
end

function SettlementLogic:HandleDataBefore(paramBefore)
  local param = {}
  local l2dResult = paramBefore.result
  local auto = paramBefore.isAuto and not paramBefore.isMissionComplete
  settlementExeManager:SetIsAuto(auto)
  local haveRes = not paramBefore.isMissionComplete
  settlementExeManager:SetInBattle(paramBefore.inBattle)
  settlementExeManager:SetTaskFinish(paramBefore.isMissionComplete)
  local userData = Data.userData:GetUserData()
  param.userName = userData.Uname
  param.userOldExp = userData.Exp
  param.userOldLv = userData.Level
  param.copyInfo = configManager.GetDataById("config_copy_display", paramBefore.copyId)
  param.shouldAddShipExp = self:_shouldAddShipExp(paramBefore.copyId)
  local chapterId = Logic.copyLogic:GetCopyChapter(paramBefore.copyId).id
  local fleetType = Logic.copyLogic:GetTacticType(chapterId)
  local myFleetId = Logic.fleetLogic:GetBattleFleetId(fleetType)
  param.myFleetId = myFleetId
  param.myFleetName = Data.fleetData:GetFleetDataById(myFleetId, fleetType).tacticName
  local shipList = SettlementHelper.ReadOldToGenShipList(myFleetId, fleetType)
  param.myShipList = shipList
  param.myFleetList = {
    [1] = shipList
  }
  if 1 < #param.copyInfo.split_team then
    param.myFleetList = Logic.fleetLogic:GetSplitFleets(param.copyInfo.split_team, shipList)
  end
  param.exitFunc = paramBefore.exitFunc
  param.hasBattleGuard = l2dResult.hasBattleGuard
  if haveRes then
    param.grade = l2dResult.grade
    local myInfos = SettlementHelper.GetMyFleetInfos(l2dResult)
    param.enemyFleetInfo = SettlementHelper.GetEnemyFleetInfos(l2dResult)
    local infos = param.enemyFleetInfo
    param.enemyFleetShipsInfo = SettlementHelper.GetEnemyFleetShipsList(param.enemyFleetInfo)
    local enemyInfo = SettlementHelper.GetEnemyFleetInfos(l2dResult)[1]
    local enemyFleetId = paramBefore.enemyFleetId
    param.enemyFleetId = enemyFleetId
    local enemyList = {}
    SettlementHelper.HandleEnemyListFormL2DResult(enemyList, enemyInfo)
    param.enemyShipList = enemyList
    SettlementHelper.HandleEnemyPSkillsFormL2DResult(enemyList, l2dResult)
    enemyList.percent = enemyInfo.percent
    param.bBoss = Logic.fleetLogic:IsLastFleet(enemyFleetId)
    param.matchPlayerInfos = {}
    param.matchPlayShipList = {}
    if 1 < #myInfos then
      if #param.myFleetList > 1 then
        local fleetList = param.myFleetList
        for fleetIndex, info in ipairs(myInfos) do
          SettlementHelper.HandleMyListFormL2DResult(fleetList[fleetIndex], info)
          SettlementHelper.HandleMyPSkillsFormL2DResult(fleetList[fleetIndex], l2dResult)
          fleetList[fleetIndex].percent = info.percent
        end
        self:HandleMutilFleetsMVP(fleetList)
      else
        local userMvpDamage = 0
        for i = 1, #myInfos do
          local resultFleetInfo = myInfos[i]
          local playerInfo = {}
          playerInfo.Index = i
          playerInfo.fleetUid = resultFleetInfo.fleetUid
          playerInfo.percent = resultFleetInfo.percent
          playerInfo.isPlayer = resultFleetInfo.isPlayer
          playerInfo.findNumByNPC = resultFleetInfo.findNumByNPC
          playerInfo.dictId = resultFleetInfo.dictId
          playerInfo.isGuard = resultFleetInfo.isGuard
          playerInfo.ownerPlayerUID = resultFleetInfo.ownerPlayerUID
          playerInfo.shipList = {}
          local mvpDamage = 0
          local userTotalDamage = 0
          for j = 0, resultFleetInfo.shipsInfo.Count - 1 do
            local info = resultFleetInfo.shipsInfo[j]
            local ship = {}
            ship.totalDamage = info.damage
            userTotalDamage = userTotalDamage + ship.totalDamage
            mvpDamage = mvpDamage < info.damage and info.damage or mvpDamage
            ship.gunDamage = info.gunDamage
            ship.ownerPlayerUID = playerInfo.ownerPlayerUID
            ship.torpedoDamage = info.torpedoDamage
            ship.bombDamage = info.bombDamage
            ship.carriarTorpedoDamage = info.carriarTorpedoDamage
            ship.bSelf = true
            ship.joinBattle = info.joinBattle
            ship.maxHp = info.hpMax
            ship.hp = info.hp / 10000000000 * info.hpMax
            ship.uid = info.serverUid
            local shipInfo = self:GetMatchPlayerShipData(playerInfo.ownerPlayerUID, ship.uid)
            ship.level = shipInfo and shipInfo.Level or 0
            ship.fashionId = shipInfo.Fashioning
            ship.petDictId = info.petDictId
            ship.wakeup = info.petWakeup
            ship.layer = LayerMask.NameToLayer("UI3DObject")
            table.insert(playerInfo.shipList, ship)
          end
          table.insert(param.matchPlayShipList, playerInfo.shipList)
          playerInfo.userTotalDamage = userTotalDamage
          playerInfo.mvp = false
          userMvpDamage = userMvpDamage > playerInfo.userTotalDamage and userMvpDamage or playerInfo.userTotalDamage
          table.insert(param.matchPlayerInfos, playerInfo)
        end
        for userData = 1, #param.matchPlayerInfos do
          if param.matchPlayerInfos[userData].userTotalDamage == userMvpDamage then
            param.matchPlayerInfos[userData].mvp = true
          end
          param.matchPlayerInfos[userData].teamMvpDamage = userMvpDamage
        end
        table.sort(param.matchPlayerInfos, function(l, r)
          return l.userTotalDamage > r.userTotalDamage
        end)
        local assist_fleet_num = param.copyInfo.assist_fleet_num
        local shipList = {}
        for shipIndex = 1, assist_fleet_num do
          table.insert(shipList, param.myShipList[shipIndex])
        end
        param.myShipList = shipList
        local shipInfo = myInfos[1]
        local userId = Data.userData:GetUserUid()
        for userInfoIndex = 1, #myInfos do
          if myInfos[userInfoIndex].ownerPlayerUID == userId then
            shipInfo = myInfos[userInfoIndex]
          end
        end
        SettlementHelper.HandleMyListFormL2DResult(shipList, shipInfo)
        SettlementHelper.HandleMyPSkillsFormL2DResult(shipList, l2dResult)
        shipList.percent = shipInfo.percent
        param.myFleetList = {
          [1] = shipList
        }
      end
    else
      local shipList = param.myShipList
      local shipInfo = myInfos[1]
      SettlementHelper.HandleMyListFormL2DResult(shipList, shipInfo)
      SettlementHelper.HandleMyPSkillsFormL2DResult(shipList, l2dResult)
      shipList.percent = shipInfo.percent
      param.myFleetList = {
        [1] = shipList
      }
    end
  else
    param.grade = 0
    param.enemyFleetInfo = {}
    param.enemyFleetShipsInfo = {}
    param.enemyFleetId = 0
    param.enemyShipList = {}
    param.bBoss = false
  end
  self:SetParam(param)
end

function SettlementLogic:HandleMutilFleetsMVP(fleets)
  local mvpShip = fleets[1][1]
  local mvpDamage = mvpShip.mvpDamage
  for _, shipList in ipairs(fleets) do
    for _, ship in ipairs(shipList) do
      if ship.totalDamage > mvpShip.totalDamage then
        mvpDamage = ship.totalDamage
        mvpShip.mvp = false
        ship.mvp = true
        mvpShip = ship
      else
        ship.mvp = false
      end
    end
  end
  mvpShip.mvp = true
  for _, shipList in ipairs(fleets) do
    for _, ship in ipairs(shipList) do
      ship.mvpDamage = mvpDamage
    end
  end
end

function SettlementLogic:_shouldAddUserExp(copyId)
  local cid = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  if cid == nil then
    return true
  end
  local copyType = Logic.copyLogic:GetChaperConfById(cid).class_type
  local curPassTime = Logic.copyLogic:GetCurFirstTime()
  if copyType == ChapterType.PlotCopy and curPassTime ~= 0 then
    return false
  end
  if copyType >= ChapterType.Train and copyType <= ChapterType.TrainLv then
    return false
  end
  if copyType == ChapterType.GoodsCopy then
    return false
  end
  return true
end

function SettlementLogic:_shouldAddShipExp(copyId)
  local cid = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  if cid == nil then
    return true
  end
  local copyType = Logic.copyLogic:GetChaperConfById(cid).class_type
  if copyType >= ChapterType.Train and copyType <= ChapterType.TrainLv then
    return false
  end
  return true
end

function SettlementLogic:HandleDataAfter(paramAfter)
  if paramAfter == nil then
    return
  end
  local param = self:GetParam()
  local originGrade = param.grade
  param.grade = paramAfter.Grade and paramAfter.Grade or param.grade
  self:SetCopyPassRet(param, paramAfter, originGrade)
  local fleetType = self:_GetFleetType()
  local myFleetId = Logic.fleetLogic:GetBattleFleetId()
  param.userNewLv = math.floor(Data.userData:GetUserLevel())
  local haveRes = not settlementExeManager:GetTaskFinish()
  if haveRes then
    if #param.copyInfo.split_team > 1 and 1 < #param.myFleetList then
      for _, shipList in ipairs(param.myFleetList) do
        SettlementHelper.ReadNewToGenShipList(shipList, myFleetId, param, fleetType)
      end
    else
      SettlementHelper.ReadNewToGenShipList(param.myShipList, myFleetId, param, fleetType)
    end
  end
  if paramAfter.ExtraReward and next(paramAfter.ExtraReward) ~= nil then
    param.extraReward = paramAfter.ExtraReward
  end
  if paramAfter.MissionReward and next(paramAfter.MissionReward) ~= nil then
    param.taskReward = paramAfter.MissionReward
  end
  param.userAddExp = 0
  if paramAfter.ExReward and next(paramAfter.ExReward) ~= nil then
    local middle = {}
    for i, v in ipairs(paramAfter.ExReward) do
      middle[v.Key] = v.Value
    end
    param.extraInfo = middle
    param.userAddExp = middle.UserExp or 0
  end
  local shouldAdd = self:_shouldAddUserExp(param.copyInfo.id)
  if not shouldAdd then
    param.userAddExp = 0
  end
  param.firstPass = paramAfter.FirstPass == 1
  param.rewards = paramAfter.Reward
  if #param.copyInfo.split_team > 1 and 1 < #param.myFleetList then
    for _, shipList in ipairs(param.myFleetList) do
      self:_SetHeroExp(shipList, paramAfter.ExpReward)
    end
  else
    self:_SetHeroExp(param.myShipList, paramAfter.ExpReward)
  end
end

function SettlementLogic:_SetHeroExp(myShipList, heroExp)
  local cacheMap = {}
  for _, v in ipairs(heroExp) do
    cacheMap[v.HeroId] = v.Value
  end
  for _, info in ipairs(myShipList) do
    if cacheMap[info.heroId] then
      info.addExp = cacheMap[info.heroId]
    end
  end
end

function SettlementLogic:SetCopyPassRet(param, ret, originGrade)
  if ret == nil then
    self.copyPassRet = nil
    return
  end
  local copyId = param.copyInfo.id
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  if chapterId then
    local chapter = configManager.GetDataById("config_chapter", chapterId)
    local keepRet = chapter.class_type == ChapterType.GoodsCopy and param.bBoss and param.grade < EvaGradeType.F or chapter.class_type == ChapterType.WalkDog and originGrade and originGrade == EvaGradeType.F or chapter.class_type == ChapterType.EquipTestCopy or chapter.class_type == ChapterType.EquipNewTestCopy or chapter.class_type == ChapterType.ActivitySecretCopy and param.bBoss or chapter.class_type == ChapterType.TrainAdvance or chapter.class_type == ChapterType.TrainLv or chapter.class_type == ChapterType.BossCopy
    if keepRet then
      self.copyPassRet = ret
    end
  end
end

function SettlementLogic:GetCopyPassRet()
  return self.copyPassRet
end

function SettlementLogic:CheckHasShip(sm_id)
  local heroArr = self.preHerodata
  local si_id = Logic.shipLogic:GetShipInfoId(sm_id)
  local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
  if self.preHerodata[sf_id] ~= nil then
    local quality = Logic.shipLogic:GetQualityByInfoId(si_id)
    if quality == HeroRarityType.SR or quality == HeroRarityType.SSR then
      return false
    else
      return true
    end
  else
    return false
  end
end

function SettlementLogic:CheckShowShip(sm_id)
  if sm_id == nil then
    return false
  end
  local si_id = Logic.shipLogic:GetShipInfoId(sm_id)
  local isNew = Logic.illustrateLogic:IsFirstGetHero(si_id)
  local qualityCheck = false
  local quality = Logic.shipLogic:GetQualityByInfoId(si_id)
  if quality == HeroRarityType.SR or quality == HeroRarityType.SSR then
    qualityCheck = true
  end
  return isNew or qualityCheck
end

function SettlementLogic.GetNeedShowGirl(rewards)
  for i, reward in ipairs(rewards) do
    if reward.Type == GoodsType.SHIP then
      return reward.ConfigId, reward.Id
    end
  end
  return nil, nil
end

function SettlementLogic:GetUserExpProgress(lv, exp)
  lv = lv or Data.userData:GetLevel()
  exp = exp or Data.userData:GetUserExp()
  local maxExp = Logic.userLogic:GetLvExp(lv)
  if maxExp ~= 0 then
    return exp / maxExp
  end
  return 0
end

function SettlementLogic.CheckOilEnougth(exist, total)
  local x = exist / total
  local YellowWarnRatio = configManager.GetDataById("config_parameter", WarningYellowId).value / 10000
  local RedWarnRatio = configManager.GetDataById("config_parameter", WarningRedId).value / 10000
  if x > YellowWarnRatio then
    return SettlementLogic.WarningType.Safe
  elseif x > RedWarnRatio then
    return SettlementLogic.WarningType.Normal
  else
    return SettlementLogic.WarningType.Emergency
  end
end

function SettlementLogic.CheckBulletEnougth(exist, total)
  local x = exist / total
  local YellowWarnRatio = configManager.GetDataById("config_parameter", WarningYellowId).value / 10000
  local RedWarnRatio = configManager.GetDataById("config_parameter", WarningRedId).value / 10000
  if x > YellowWarnRatio then
    return SettlementLogic.WarningType.Safe
  elseif x > RedWarnRatio then
    return SettlementLogic.WarningType.Normal
  else
    return SettlementLogic.WarningType.Emergency
  end
end

function SettlementLogic.GetMVPShipInfo(shipList)
  local shipinfo, maxDamage = shipList[1], 0
  for i, v in ipairs(shipList) do
    if v.totalDamage ~= nil and maxDamage < v.totalDamage then
      shipinfo = v
      maxDamage = v.totalDamage
    end
  end
  return shipinfo
end

function SettlementLogic.GetMVPDamage(shipList)
  local shipList = shipList
  local maxDamage = 0
  for i, v in ipairs(shipList) do
    if maxDamage < v.totalDamage then
      maxDamage = v.totalDamage
    end
  end
  return maxDamage
end

function SettlementLogic:DOTSettlementInfo(myShipList)
  local names, levels, powers, attacks, totalDamages, towerPoints = {}, {}, {}, {}, {}, {}
  local fleetType = self:_GetFleetType()
  for _, info in ipairs(myShipList) do
    local heroInfo = Data.heroData:GetHeroById(info.heroId)
    local si_id = Logic.shipLogic:GetShipInfoId(heroInfo.TemplateId)
    local name = Logic.shipLogic:GetName(si_id)
    local power = Logic.attrLogic:GetBattlePower(info.heroId, fleetType)
    local attack = Logic.attrLogic:GetHeroFinalShowAttrById(info.heroId, fleetType)[AttrType.ATTACK_GRADE]
    local towerPoint = info.preTowerPoint
    table.insert(names, name)
    table.insert(levels, heroInfo.Lvl)
    table.insert(powers, power)
    table.insert(attacks, attack)
    table.insert(totalDamages, info.totalDamage)
    table.insert(towerPoints, towerPoint)
  end
  return {
    info = "myshipgirls_battleinfo",
    myshipgirls = names,
    myshipgirls_level = levels,
    myshipgirls_power = powers,
    myshipgirls_attack = attacks,
    myshipgirls_damage = totalDamages,
    tower_point = towerPoints
  }
end

function SettlementLogic:GetTowerPoint(sm_id, fleetType)
  if Logic.towerLogic:IsTowerType(fleetType) then
    return Logic.towerLogic:CalTowerHurtPer(sm_id, fleetType)
  else
    return 100
  end
end

function SettlementLogic:GetMatchPlayerShipData(uid, shipUid)
  local matchPlayerData = Data.copyData:GetMatchPlayerTempData()
  if 1 <= #matchPlayerData then
    for _, info in ipairs(matchPlayerData) do
      if info.Uid == uid and 1 <= #info.FleetInfo.Ships then
        for _, shipInfo in ipairs(info.FleetInfo.Ships) do
          if shipInfo.HeroId == shipUid then
            return shipInfo
          end
        end
      end
    end
  end
  return nil
end

function SettlementLogic:GetMatchPlayerUserName(uid)
  local matchPlayerData = Data.copyData:GetMatchPlayerTempData()
  if 1 < #matchPlayerData then
    for _, info in ipairs(matchPlayerData) do
      if info.Uid == uid then
        return info.Uname
      end
    end
  end
  return uid
end

function SettlementLogic:_GetFleetType()
  local param = self:GetParam()
  local chapterId = Logic.copyLogic:GetCopyChapter(param.copyInfo.id).id
  return Logic.copyLogic:GetTacticType(chapterId)
end

function SettlementLogic:DOTSettlementMood(myShipList)
  local names, oldMoods, newMoods = {}, {}, {}
  for _, info in ipairs(myShipList) do
    local heroInfo = Data.heroData:GetHeroById(info.heroId)
    local si_id = Logic.shipLogic:GetShipInfoId(heroInfo.TemplateId)
    local name = Logic.shipLogic:GetName(si_id)
    local oldMood = info.oldMood or 0
    local newMood = info.newMood or 0
    table.insert(names, name)
    table.insert(oldMoods, oldMood)
    table.insert(newMoods, newMood)
  end
  return {
    info = "ui_settlement_mood",
    ship_name = names,
    before = oldMoods,
    after = newMoods
  }
end

function SettlementLogic:DOTSettlementLove(myShipList)
  local names, oldMoods, newMoods, flagships, mvps = {}, {}, {}, {}, {}
  for index, info in ipairs(myShipList) do
    local heroInfo = Data.heroData:GetHeroById(info.heroId)
    local si_id = Logic.shipLogic:GetShipInfoId(heroInfo.TemplateId)
    local name = Logic.shipLogic:GetName(si_id)
    local oldLove = info.oldLove or 0
    local newLove = info.newLove or 0
    local flag = index == 1 and 1 or 0
    local mvp = info.mvp and 1 or 0
    table.insert(names, name)
    table.insert(oldMoods, oldLove)
    table.insert(newMoods, newLove)
    table.insert(flagships, flag)
    table.insert(mvps, mvp)
  end
  return {
    info = "ui_settlement_affection",
    ship_name = names,
    before = oldLoves,
    after = newLoves,
    flagship = flagships,
    mvp = mvps
  }
end

function SettlementLogic:SkipSkillEffect()
  eventManager:SendEvent(LuaEvent.SettlementEvaluation)
end

function SettlementLogic:GetSkillBaseTime(id)
  return Logic.shipLogic:GetPSkillDisplayConfigById(id).trigger_stay_duration
end

function SettlementLogic:GetSkillName(id)
  return Logic.shipLogic:GetPSkillDisplayConfigById(id).trigger_wenzi_uri
end

function SettlementLogic:GetSkillHeroIcon(ss_id)
  return configManager.GetDataById("config_ship_show", ss_id).ship_icon5
end

function SettlementLogic:GetSkillDisplayType(id)
  return Logic.shipLogic:GetPSkillDisplayConfigById(id).trigger_display_type
end

function SettlementLogic:InitFastFlowCtrl(param)
  local DoEnd = function()
    settlementExeManager:StopExeAndClear()
    self.m_bInSettle = false
    if not IsNil(param.exitFunc) then
      param.exitFunc()
      param.exitFunc = nil
    end
  end
  self.m_bInSettle = true
  local State = SettlementLogic.State
  local rewards = param.rewards
  local ok, executer = settlementExeManager:GenExecuter(State.Reward, function(args)
    UIHelper.ClosePage("CrusadeSuccessPage")
    if #args.Rewards > 0 then
      self:_dotBaseRewards("safearea_get", param)
      UIHelper.OpenPage("GetRewardsPage", args)
    else
      DoEnd()
    end
  end, {
    Rewards = rewards,
    callBack = function()
      Logic.settlementLogic:Execute(SettlementLogic.State.ShowGirl)
    end
  })
  if ok then
    settlementExeManager:RegisterExecuter(executer)
  end
  local sm_id, heroId = Logic.settlementLogic.GetNeedShowGirl(rewards)
  local show = Logic.settlementLogic:CheckShowShip(sm_id)
  local si_id
  if sm_id and show then
    si_id = Logic.shipLogic:GetShipInfoId(sm_id)
  end
  local ok, executer = settlementExeManager:GenExecuter(State.ShowGirl, function(args)
    UIHelper.ClosePage("GetRewardsPage")
    if args.girlId then
      args.battleOpen = true
      
      function args.callback()
        eventManager:FireEventToCSharp(LuaCSharpEvent.SettlementTurnOnOffCamera, true)
      end
      
      eventManager:FireEventToCSharp(LuaCSharpEvent.SettlementTurnOnOffCamera, false)
      UIHelper.OpenPage("ShowGirlPage", args)
    else
      DoEnd()
    end
  end, {
    girlId = si_id,
    HeroId = heroId,
    getWay = GetGirlWay.battle,
    callback = function()
      DoEnd()
    end
  })
  if ok then
    settlementExeManager:RegisterExecuter(executer)
  end
end

function SettlementLogic:Execute(state)
  local State = SettlementLogic.State
  if state == State.Reward then
    settlementExeManager:Execute(State.Reward)
  elseif state == State.ShowGirl then
    settlementExeManager:Execute(State.ShowGirl)
  else
    logError("\230\151\160\230\179\149\230\137\190\229\136\176\230\137\167\232\161\140\229\153\168,state:" .. state)
  end
end

function SettlementLogic:FastResetAndExit()
  settlementExeManager:StopExeAndClear()
  UIHelper.ClosePage("CrusadeSuccessPage")
  UIHelper.ClosePage("GetRewardsPage")
  UIHelper.ClosePage("ShowGirlPage")
  self.m_bInSettle = false
end

function SettlementLogic:IsInSettle()
  return self.m_bInSettle
end

function SettlementLogic:_OnShareStart()
  settlementExeManager:PauseAutoExe()
end

function SettlementLogic:_OnShareOver()
  settlementExeManager:ResumeAutoExe()
end

function SettlementLogic:ShowAEquipPointTip()
  local equips = self:GetBattleAEquip()
  if #equips == 0 then
    return 0, {}
  end
  local total = 0
  for _, id in pairs(equips) do
    total = total + Data.equipactivityData:GetPointAddById(id)
  end
  return total, equips
end

function SettlementLogic:GetBattleAEquip()
  local settle = self:GetParam()
  if settle == nil or settle.myShipList == nil then
    return {}
  end
  local type = self:_GetFleetType()
  local equips, tid = {}, 0
  for _, info in ipairs(settle.myShipList) do
    local temp = Data.heroData:GetEquipsByType(info.heroId, type)
    for _, v in ipairs(temp) do
      if 0 < v.EquipsId then
        tid = Logic.equipLogic:GetEquipTidByEquipId(v.EquipsId)
        if 0 < tid and Logic.equipLogic:IsAEquip(tid) then
          table.insert(equips, v.EquipsId)
        end
      end
    end
  end
  return equips
end

function SettlementLogic:_TryCleanUpData()
  settlementExeManager:StopExeAndClear()
  self.m_bInSettle = false
end

function SettlementLogic:GetDefaultParam()
  local temp = {
    myShipList = {
      [1] = {
        name = "\229\165\165\229\133\139\229\133\176",
        gunDamage = 0,
        totalDamage = 0,
        bSelf = true,
        addExp = 225.0,
        torpedoDamage = 0,
        joinBattle = true,
        status = 0,
        bombDamage = 0,
        carriarTorpedoDamage = 0,
        hp = 298,
        si_id = 1021051,
        mvp = false,
        maxHp = 298,
        oldExp = 900.0,
        heroId = 1.0,
        sm_id = 1.0210511E7,
        mvpDamage = 0,
        oldLevel = 6,
        PSkillList = {},
        cacheHp = 0,
        oldMood = 0,
        oldLove = 0,
        newLove = 10,
        newMood = 10,
        preTowerPoint = 100,
        petDictId = -1,
        wakeup = false
      },
      percent = 1.0
    },
    enemyShipList = {
      [1] = {
        name = "\231\169\134\228\188\175\194\183\233\169\177\233\128\144",
        joinBattle = true,
        totalDamage = 0,
        si_id = 9011011,
        maxHp = 101,
        bSelf = false,
        heroId = 9,
        status = 4,
        uid = 9,
        hp = 0,
        PSkillList = {},
        cacheHp = 0
      },
      percent = 0
    },
    rewards = {
      [1] = {
        Num = 1,
        Id = 25,
        ConfigId = 30121,
        Type = 2
      },
      [2] = {
        Num = 18,
        Id = 0,
        ConfigId = 1,
        Type = 5
      }
    },
    copyInfo = {
      name = "\228\184\141\233\128\159\228\185\139\229\174\162",
      copy_display_type = 1.0,
      copy_thumbnail_after = "uipic_ui_copy_bg_guanqianzhuangtai_di_clear",
      thumbnail = "uipic_ui_copy_bg_guankahaiyu_ditu",
      support_fleet_unlock_id = 160001,
      title = "\228\184\128",
      choice_boss = "",
      description = "\229\135\186\229\135\187\239\188\129\230\137\171\233\153\164\232\191\156\230\150\185\230\181\183\229\159\159\231\154\132\229\168\129\232\131\129\239\188\129",
      copy_thumbnail_before = "uipic_ui_copy_bg_guanqianzhuangtai_di_weiclear",
      support_fleet_battle_ratio = 10000,
      battle_boss_hp_uri = "",
      assist_fleet = {},
      big_activity_copy_display_id = 0,
      training_tips = "",
      id = 5011,
      sea_area_unlock = 13,
      drop_info_id = {
        [1] = 1101,
        [2] = 1102,
        [3] = 1103,
        [4] = 1104,
        [5] = 1105,
        [6] = 1106,
        [7] = 1107
      },
      support_fleet_count_max = 1.0,
      first_reward = {},
      assist_fleet_lock = 0,
      details_boss = "",
      supple_cost_argu = 20000,
      training_open_limit = 0,
      random_factor_sets = {},
      search_boss_hp_uri = "",
      support_fleet_target_and_effect = {
        [1] = {
          [1] = 140001,
          [2] = 10
        },
        [2] = {
          [1] = 120010,
          [2] = 2.0
        },
        [3] = {
          [1] = 170001,
          [2] = 3
        }
      },
      training_teacher_modle = 0,
      assist_fleet_num = 6.0,
      support_fleet_average_level_min = 1.0,
      battle_time = 360,
      three_star_reward = {
        [1] = {
          [1] = 5.0,
          [2] = 5.0,
          [3] = 1000
        }
      },
      fail_cost = 10000,
      supply_basic_cost = 0,
      star_require = {
        [1] = 1.0,
        [2] = 2.0,
        [3] = 3
      },
      training_strategy = {},
      is_boss_copy = 0,
      str_index = "1-1",
      level_limit = 1.0
    },
    userAddExp = 12,
    userOldExp = 48.0,
    userOldLv = 1,
    userNewLv = 3,
    grade = 1.0,
    myFleetId = 1.0,
    exitFunc = function()
      UIHelper.CloseCurrentPage()
    end,
    bBoss = false,
    myFleetName = "\231\172\172\228\184\128\232\136\176\233\152\159",
    enemyFleetId = 1101,
    userName = "4000004534",
    shouldAddShipExp = true,
    firstPass = false
  }
  return temp
end

function SettlementLogic:GetFastDefaultParam()
  local res = {
    result = 1,
    rewards = {
      [1] = {
        Type = 2,
        ConfigId = 30531,
        Num = 1,
        Id = 583
      },
      [2] = {
        Type = 3,
        ConfigId = 10210511,
        Num = 1,
        Id = 2
      },
      [3] = {
        Type = 5,
        ConfigId = 1,
        Num = 70,
        Id = 0
      }
    },
    isAuto = false,
    userAddExp = 0,
    exitFunc = function()
    end,
    heroAddExp = {
      [1] = 10
    },
    fleets = {
      [1] = 1
    }
  }
  return res
end

return SettlementLogic
