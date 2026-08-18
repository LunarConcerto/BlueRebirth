DisplayLuaUtil = {}

function DisplayLuaUtil.OnAutoBattleClick(copyId)
  local copy = configManager.GetDataById("config_copy", copyId)
  local copyDisplay = configManager.GetDataById("config_copy_display", copy.copy_id)
  local isOpen = DisplayLuaUtil.CheckFuncOpen(copyDisplay.id, FunctionID.AutoFIght)
  if not isOpen then
    return false
  end
  local enabled = DisplayLuaUtil.CheckAutoBattle(copyId)
  if not enabled then
    noticeManager:ShowTip(UIHelper.GetString(copyDisplay.autobattle_opendesc))
    return false
  end
  return true
end

function DisplayLuaUtil.CheckAutoBattle(copyId)
  local copy = configManager.GetDataById("config_copy", copyId)
  local copyDisplay = configManager.GetDataById("config_copy_display", copy.copy_id)
  local isOpen = moduleManager:CheckFunc(FunctionID.AutoFIght, false)
  if not isOpen then
    return false
  end
  local autoLimitIds = copyDisplay.autobattle_gamelimit
  if autoLimitIds and 0 < #autoLimitIds then
    for i, limitId in ipairs(autoLimitIds) do
      local enabled = Logic.gameLimitLogic.CheckConditionById(limitId, copyDisplay.id)
      if not enabled then
        return false
      end
    end
  end
  return true
end

function DisplayLuaUtil.CheckDoubleSpeed(copyId)
  return DisplayLuaUtil.CheckFuncOpen(copyId, FunctionID.DoubleSpeed)
end

function DisplayLuaUtil.CheckTripleSpeed(copyId)
  return DisplayLuaUtil.CheckFuncOpen(copyId, FunctionID.TripleSpeed)
end

function DisplayLuaUtil.CheckFuncOpen(copyId, funcId)
  local funcOpen = moduleManager:CheckFunc(funcId, false)
  local conf = configManager.GetDataById("config_function_info", tostring(funcId))
  local openTip = conf.comment
  if not funcOpen then
    noticeManager:ShowTip(openTip)
  end
  return funcOpen
end

function DisplayLuaUtil.IsAutoBattleEnabled(copyDisplayId)
  local copyDisplay = configManager.GetDataById("config_copy_display", copyDisplayId)
  return copyDisplay.autobattle_isshow == 1
end

function DisplayLuaUtil.CheckTacticOpen()
  return moduleManager:CheckFunc(FunctionID.Tactic, true)
end
