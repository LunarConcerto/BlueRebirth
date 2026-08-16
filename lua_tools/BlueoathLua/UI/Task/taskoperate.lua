local TaskOperate = class("UI.Task.TaskOperate")

function TaskOperate.TaskJumpByKind(kind, functionId, args)
  if TaskOperate.JumpFunc[kind] then
    TaskOperate.JumpFunc[kind](functionId, args)
  elseif TaskOperate.JumpFuncByFunctionID[functionId] then
    TaskOperate.JumpFuncByFunctionID[functionId](functionId, args)
  else
    TaskOperate.JumpValidModule(functionId, args)
  end
end

function TaskOperate.NewPlayerJumpByKind(functionId, args)
  if TaskOperate.JumpNewPlayerFunc[functionId] == nil then
    return false
  else
    TaskOperate.JumpNewPlayerFunc[functionId](functionId, args)
  end
end

function TaskOperate.NewPlayerIsJump(kind, functionId, args)
  if TaskOperate.JumpNewPlayerFunc[functionId] == nil then
    return false
  else
    return true
  end
end

function TaskOperate.ReturnPlayerIsJump(kind, functionId, args)
  if TaskOperate.JumpFuncByFunctionID[functionId] == nil then
    return false
  else
    return true
  end
end

function TaskOperate.ErrorJump()
  logError("\232\183\179\232\189\172\232\135\179\230\156\170\229\188\128\230\148\190\228\187\187\229\138\161")
end

function TaskOperate.NonoJump()
end

function TaskOperate.CommonJump()
  UIHelper.Back()
end

function TaskOperate.JumpFleet(functionId)
  UIHelper.Back()
  TaskOperate.JumpValidModule(functionId)
end

function TaskOperate.JumpValidModule(functionId, param)
  if moduleManager:CheckFunc(functionId, true) then
    moduleManager:JumpToFunc(functionId, param)
  end
end

function TaskOperate.JumpRetire()
  UIHelper.OpenPage("HeroRetirePage")
end

function TaskOperate.JumpChat(functionId)
  UIHelper.Back()
  TaskOperate.JumpValidModule(functionId)
end

function TaskOperate.JumpBuild(functionId)
  UIHelper.Back()
  TaskOperate.JumpValidModule(functionId)
end

function TaskOperate.JumpRepair(functionId)
  UIHelper.Back()
  TaskOperate.JumpValidModule(functionId)
end

function TaskOperate.JumpBuildShip(functionId)
  UIHelper.Back()
  TaskOperate.JumpValidModule(functionId)
end

function TaskOperate.JumpCopy(functionId)
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if not isHasFleet then
    noticeManager:OpenTipPage(self, 110007)
    return
  end
  TaskOperate.JumpValidModule(functionId)
end

function TaskOperate.JumpFriend(functionId)
  UIHelper.Back()
  TaskOperate.JumpValidModule(functionId)
end

function TaskOperate.JumpStrategy(functionId)
  UIHelper.Back()
  UIHelper.OpenPage("SuperStrategyPage", {})
end

function TaskOperate.JumpTrain(functionId)
  UIHelper.Back()
  TaskOperate.JumpValidModule(functionId)
end

TaskOperate.JumpFunc = {
  [TaskKind.LOGIN] = nil,
  [TaskKind.BATTLEWIN] = TaskOperate.JumpCopy,
  [TaskKind.PASSDAILYCOPY] = TaskOperate.JumpCopy,
  [TaskKind.PASSELITECOPY] = TaskOperate.ErrorJump,
  [TaskKind.PASSCHALLENGECOPY] = TaskOperate.ErrorJump,
  [TaskKind.FINISHCRUSADE] = TaskOperate.JumpValidModule,
  [TaskKind.SUPPORTFLEET] = TaskOperate.ErrorJump,
  [TaskKind.EXERCISE] = TaskOperate.ErrorJump,
  [TaskKind.SKILL] = TaskOperate.JumpValidModule,
  [TaskKind.STRENGTH] = TaskOperate.JumpValidModule,
  [TaskKind.RETIRE] = TaskOperate.JumpRetire,
  [TaskKind.BUILD] = TaskOperate.JumpBuild,
  [TaskKind.REPAIR] = TaskOperate.JumpRepair,
  [TaskKind.FININSHALLDAILY] = TaskOperate.NonoJump,
  [TaskKind.HITSHIP] = TaskOperate.CommonJump,
  [TaskKind.BUILDCOUNT] = TaskOperate.JumpBuild,
  [TaskKind.PASSCOPY] = TaskOperate.JumpCopy,
  [TaskKind.FULLPASSCOPY] = TaskOperate.JumpCopy,
  [TaskKind.FINISHWEEK] = TaskOperate.ErrorJump,
  [TaskKind.USERLEVEL] = TaskOperate.CommonJump,
  [TaskKind.FRIENDCOUNT] = TaskOperate.JumpFriend,
  [TaskKind.PASSTRAIN] = TaskOperate.JumpTrain,
  [TaskKind.PASSRUNFIGHT] = TaskOperate.JumpCopy,
  [TaskKind.PASSADAILYCOPY] = TaskOperate.JumpCopy,
  [TaskKind.HEROLVTEMPLATE] = TaskOperate.JumpValidModule,
  [TaskKind.HEROADTEMPLATE] = TaskOperate.JumpValidModule,
  [TaskKind.EQUIPLVTEMPLATE] = TaskOperate.JumpValidModule,
  [TaskKind.EQUIPADTEMPLATE] = TaskOperate.JumpValidModule,
  [TaskKind.BUILDSHIPQUICK] = TaskOperate.JumpBuild,
  [TaskKind.BUILDTYPE] = TaskOperate.JumpBuild,
  [TaskKind.PASSSEACOPY] = TaskOperate.JumpCopy
}
TaskOperate.JumpFuncByFunctionID = {
  [FunctionID.Fleet] = TaskOperate.JumpFleet,
  [FunctionID.BuildShip] = TaskOperate.JumpBuild,
  [FunctionID.Repaire] = TaskOperate.JumpRepair,
  [FunctionID.Dock] = TaskOperate.JumpValidModule,
  [FunctionID.Bag] = TaskOperate.JumpValidModule,
  [FunctionID.Copy] = TaskOperate.JumpCopy,
  [FunctionID.Task] = TaskOperate.NonoJump,
  [FunctionID.BathRoom] = TaskOperate.JumpValidModule,
  [FunctionID.Email] = TaskOperate.JumpValidModule,
  [FunctionID.Chat] = TaskOperate.JumpChat,
  [FunctionID.Activity] = TaskOperate.JumpValidModule,
  [FunctionID.Crusade] = TaskOperate.JumpValidModule,
  [FunctionID.Survey] = TaskOperate.JumpValidModule,
  [FunctionID.AutoFIght] = TaskOperate.JumpValidModule,
  [FunctionID.PlotCopy] = TaskOperate.JumpCopy,
  [FunctionID.SeaCopy] = TaskOperate.JumpCopy,
  [FunctionID.SupportFleet] = TaskOperate.JumpValidModule,
  [FunctionID.DailyCopy] = TaskOperate.JumpCopy,
  [FunctionID.DoubleSpeed] = TaskOperate.JumpValidModule,
  [FunctionID.TripleSpeed] = TaskOperate.JumpValidModule,
  [FunctionID.Retire] = TaskOperate.JumpValidModule,
  [FunctionID.BuildShipGirl] = TaskOperate.JumpValidModule,
  [FunctionID.Train] = TaskOperate.JumpValidModule,
  [FunctionID.Strategy] = TaskOperate.JumpValidModule,
  [FunctionID.ActPlotCopy] = TaskOperate.JumpValidModule,
  [FunctionID.ActSeaCopy] = TaskOperate.JumpValidModule,
  [FunctionID.Recharge] = TaskOperate.JumpValidModule,
  [FunctionID.TrainAdv] = TaskOperate.JumpValidModule,
  [FunctionID.ARKit] = TaskOperate.JumpValidModule,
  [FunctionID.PlotBarrage] = TaskOperate.JumpValidModule,
  [FunctionID.TrainBarrage] = TaskOperate.JumpValidModule,
  [FunctionID.GoodsCopy] = TaskOperate.JumpValidModule
}
TaskOperate.JumpNewPlayerFunc = {
  [NewPlayerType.Null] = nil,
  [NewPlayerType.Dock] = TaskOperate.JumpValidModule,
  [NewPlayerType.Copy] = TaskOperate.JumpCopy,
  [NewPlayerType.Shop] = TaskOperate.JumpValidModule,
  [NewPlayerType.Study] = TaskOperate.JumpValidModule,
  [NewPlayerType.BathRoom] = TaskOperate.JumpValidModule,
  [NewPlayerType.Crusade] = TaskOperate.JumpValidModule,
  [NewPlayerType.SeaCopy] = TaskOperate.JumpCopy,
  [NewPlayerType.SupportFleet] = TaskOperate.JumpCopy,
  [NewPlayerType.DailyCopy] = TaskOperate.JumpCopy,
  [NewPlayerType.Retire] = TaskOperate.JumpRetire,
  [NewPlayerType.BuildShipGirl] = TaskOperate.JumpBuildShip,
  [NewPlayerType.Train] = TaskOperate.JumpValidModule,
  [NewPlayerType.Strategy] = TaskOperate.JumpStrategy
}
return TaskOperate
