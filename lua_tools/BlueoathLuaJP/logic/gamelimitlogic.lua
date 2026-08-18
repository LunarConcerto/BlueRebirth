local cls = class("logic.GameLimitLogic")
cls.LimitType = {
  ADVANCE = 1,
  INTENSIFY = 2,
  LV = 3,
  DURABILITY = 4,
  EQUIP = 5,
  Manual = 6,
  FETTERS = 7,
  SHIPTYPE = 8,
  CONSTELLATION = 9,
  COUNTRY = 10,
  FIXEDSHIP = 11,
  ASSISFLEETLEVEL = 12,
  ASSISFLEETEQUIP = 13,
  ASSISTFLEET = 14,
  USESPCOMMAND = 15,
  PASSSECTION = 16,
  ASSISTFLEETTYPE = 17,
  ASSISTFLEETBREAKLV = 18,
  AUTOBATTLE = 20,
  SCRIPT = 1000
}
local OperateType = {
  NONE = -1,
  EQUAL = 0,
  GREATER = 1,
  LESS = 2,
  GREATER_AND_EQUAL = 3,
  LESS_AND_EQUAL = 4,
  NOT_EQUAL = 5,
  CONTAIN = 7,
  BELONG = 8,
  SET_EQUAL = 9,
  SET_NOT_EQUAL = 10,
  SET_INTERSECT = 11,
  SET_NOT_INTERSECT = 12
}

function cls:initialize()
end

function cls.CheckConditionByIdGroup(limitIdGroup, ...)
  if #limitIdGroup == 0 then
    return true, nil
  end
  local logical = limitIdGroup[1]
  local bFinalRet, finalMsg = cls.CheckConditionById(limitIdGroup[2], ...)
  for i = 3, #limitIdGroup do
    local limitId = limitIdGroup[i]
    local bRet, msg = cls.CheckConditionById(limitId, ...)
    if logical == 1 then
      bFinalRet = bFinalRet and bRet
    elseif logical ~= 2 or not bFinalRet then
    end
    finalMsg = finalMsg and msg
  end
  return bFinalRet, finalMsg
end

function cls.CheckConditionById(limitId, ...)
  if not limitId then
    return true, nil, 1
  end
  local limitConfig = configManager.GetDataById("config_game_limits", limitId)
  local limitType = limitConfig.limit_type
  local limitParam = {}
  limitParam.param = clone(limitConfig.limit_param)
  limitParam.desc = limitConfig.desc
  limitParam.operation = limitConfig.operation
  limitParam.script = limitConfig.script_name
  return cls.CheckConditionByType(limitType, limitParam, ...)
end

function cls.CheckConditionByArrId(arrLimitId)
  for _, limitId in ipairs(arrLimitId) do
    local ret, _ = cls.CheckConditionById(limitId)
    if not ret then
      local limitConfig = configManager.GetDataById("config_game_limits", limitId)
      return ret, limitConfig.desc
    end
  end
  return true, ""
end

function cls.CheckConditionByType(limitType, limitParam, ...)
  return cls.LimitFunc[limitType](limitParam, ...)
end

function cls._CheckLv(limitParam, ...)
  local lv = Data.heroData:GetHeroById(...).Lvl
  local result = cls.CheckOperate(lv, limitParam.operation, limitParam.param[1], ...)
  if result then
    return true, nil, 1
  else
    return false, limitParam.desc
  end
end

function cls.AlwaysTrue()
  return true, nil, 1
end

function cls._CheckType(limitParam, ...)
  local heroInfo = Data.heroData:GetHeroById(...)
  local shipType = heroInfo.type
  local result = cls.CheckOperate(shipType, limitParam.operation, limitParam.param[1], ...)
  if result then
    return true, nil, 1
  else
    return false, limitParam.desc
  end
end

function cls._CheckConstellation(limitParam, ...)
  return true, nil
end

function cls._CheckCountry(limitParam, ...)
  local heroInfo = Data.heroData:GetHeroById(...)
  local country = heroInfo.shipCountry
  local result = cls.CheckOperate(country, limitParam.operation, limitParam.param[1], ...)
  if result then
    return true, nil, 1
  else
    return false, limitParam.desc
  end
end

function cls._CheckFixShip(limitParam, ...)
  local heroInfo = Data.heroData:GetHeroById(...)
  local Tid = heroInfo.TemplateId
  local result = cls.CheckOperate(Tid, limitParam.operation, limitParam.param, ...)
  if result then
    return true, nil, 1
  else
    return false, limitParam.desc
  end
end

function cls._CheckAdvance(limitParam, ...)
  local advance
  if type(...) == "table" then
    local info = (...)
    advance = info.Advance
  else
    advance = Data.heroData:GetHeroById(...).Advance
  end
  local result = cls.CheckOperate(advance, limitParam.operation, limitParam.param[1], ...)
  if result then
    return true, nil, 1
  else
    return false, limitParam.desc
  end
end

function cls._CheckAssisFleetAverageLevel(limitParam, ...)
  local info = (...)
  if #info == 0 then
    return false, limitParam.desc
  end
  local totalLv = 0
  for _, v in ipairs(info) do
    local lv = Data.heroData:GetHeroById(v).Lvl
    totalLv = lv + totalLv
  end
  local averageLv = totalLv / #info
  local result = cls.CheckOperate(averageLv, limitParam.operation, limitParam.param[1], ...)
  if result then
    return true, nil, 1
  end
  return false, limitParam.desc
end

function cls._CheckAssisEquip(limitParam, ...)
  local info = (...)
  local total = 0
  for _, v in ipairs(info) do
    local equips = Data.heroData:GetHeroById(v).Equips
    for _, id in pairs(equips) do
      if id ~= 0 then
        local tid = Data.equipData:GetEquipDataById(id).TemplateId
        if tid == limitParam.param[1] or tid == limitParam.param[2] then
          total = total + 1
        end
      end
    end
    local result = cls.CheckOperate(total, limitParam.operation, limitParam.param[3], ...)
    if result then
      return true, nil, count
    end
  end
  return false, nil
end

function cls._CheckAssistFleet(limitParam, ...)
  local info = (...)
  local heroListNum = #info
  local result = 0 < heroListNum
  result = cls.CheckOperate(result, limitParam.operation, limitParam.param, ...)
  if result then
    return true, nil, 1
  end
  return false, limitParam.desc
end

function cls._CheckSPCommand(limitParam, ...)
  local supportId = (...)
  local result = cls.CheckOperate({supportId}, limitParam.operation, limitParam.param, ...)
  if result then
    return true, nil, 1
  end
  return false, limitParam.desc
end

function cls._CheckSection(limitParam, ...)
  local copyId = (...)
  local lock = Logic.copyLogic:IsCopyPassById(copyId, ChapterType.SeaCopy)
  local result = cls.CheckOperate(lock, limitParam.operation, limitParam.param[1], ...)
  if not result then
    return true, nil, 1
  end
  return false, limitParam.desc
end

function cls._CheckFleetAverageBreakLevel(limitParam, ...)
  local info = (...)
  local totalLv = 0
  for _, v in ipairs(info) do
    local lv = Data.heroData:GetHeroById(v).Advance
    totalLv = lv + totalLv
  end
  local averageLv = totalLv / #info
  local result = cls.CheckOperate(averageLv, limitParam.operation, limitParam.param[1], ...)
  if result then
    return true, nil, 1
  end
  return false, limitParam.desc
end

function cls._CheckAssisShipType(limitParam, ...)
  local info = (...)
  if #info == 0 then
    return false, limitParam.desc
  end
  local types = {}
  for _, heroId in pairs(info) do
    local typ = Data.heroData:GetHeroById(heroId).type
    table.insert(types, typ)
  end
  local result = cls.CheckOperate(types, limitParam.operation, limitParam.param, ...)
  if result then
    return true, nil, 1
  end
  return false, limitParam.desc
end

function cls._CheckManual(limitParam, ...)
  for _, limitId in pairs(limitParam.param) do
    local state = Logic.illustrateLogic:GetIllustrateState(limitId)
    if state ~= IllustrateState.UNLOCK then
      return false, limitParam.desc
    end
  end
  return true
end

function cls._CheckAutoBattle(limitParam, ...)
  local isPass = Logic.copyLogic:IsCopyPassById(...)
  return isPass
end

function cls._And(limitParam, ...)
  for _, limitId in pairs(limitParam[1]) do
    local result, desc = cls.CheckConditionById(limitId, ...)
    if not result then
      return false, desc
    end
  end
  return true, nil
end

function cls._Or(limitParam, ...)
  for _, limitId in pairs(limitParam[1]) do
    local result, desc = cls.CheckConditionById(limitId, ...)
    if result then
      return true
    end
  end
  return true, limitParam.desc
end

function cls._Add(limitParam, ...)
  local result = 0
  for _, limitId in pairs(limitParam[1]) do
    local num, desc = cls.CheckConditionById(limitId, ...)
    result = result + num
  end
  return result
end

function cls._Script(limitParam, ...)
  return ScriptManager:RunCmd(limitParam.script, limitParam.param, ...)
end

function cls.GetLimitParam(limitId)
  return configManager.GetDataById("config_game_limits", limitId).limit_param
end

function cls.GetLimitNumParam(limitId)
  local limitType = configManager.GetDataById("config_game_limits", limitId).limit_type
  if limitType == cls.LimitType.ASSISFLEETEQUIP then
    local param = configManager.GetDataById("config_game_limits", limitId).limit_param
    return param[#param]
  else
    return 1
  end
end

function cls.GetLimitConfig(limitId)
  local config = configManager.GetDataById("config_game_limits", limitId)
  if config == nil then
    logError("can't find game limit condition about :" .. limitId)
    return
  end
  return config
end

function cls.CheckOperate(value, operateion, limitParam, ...)
  if operateion == OperateType.NONE then
    return value
  elseif operateion == OperateType.EQUAL then
    return value == limitParam
  elseif operateion == OperateType.GREATER then
    return limitParam < value
  elseif operateion == OperateType.LESS then
    return value < limitParam
  elseif operateion == OperateType.GREATER_AND_EQUAL then
    return limitParam <= value
  elseif operateion == OperateType.LESS_AND_EQUAL then
    return value <= limitParam
  elseif operateion == OperateType.NOT_EQUAL then
    return value ~= limitParam
  elseif operateion == OperateType.CONTAIN then
    return cls.SetContain(value, limitParam)
  elseif operateion == OperateType.BELONG then
    return cls.SetContain(limitParam, value)
  elseif operateion == OperateType.SET_EQUAL then
    return cls.SetEqual(value, limitParam)
  elseif operateion == OperateType.SET_NOT_EQUAL then
    return not cls.SetEqual(value, limitParam)
  elseif operateion == OperateType.SET_INTERSECT then
    return cls.SetIntersect(value, limitParam)
  elseif operateion == OperateType.SET_NOT_INTERSECT then
    return not cls.SetIntersect(value, limitParam)
  end
end

function cls.SetContain(listAa, listBb)
  local listA = listAa
  if type(listAa) ~= "table" then
    listA = {listAa}
  end
  local listB = listBb
  if type(listBb) ~= "table" then
    listB = {listBb}
  end
  local mapA = {}
  for _, value in ipairs(listA) do
    mapA[value] = true
  end
  for _, value in ipairs(listB) do
    if mapA[value] ~= true then
      return false
    end
  end
  return true
end

function cls.SetEqual(listAa, listBb)
  local listA = listAa
  if type(listAa) ~= "table" then
    listA = {listAa}
  end
  local listB = listBb
  if type(listBb) ~= "table" then
    listB = {listBb}
  end
  if #listA ~= #listB then
    return false
  end
  local mapA = {}
  for _, value in ipairs(listA) do
    mapA[value] = true
  end
  for _, value in ipairs(listB) do
    if mapA[value] ~= true then
      return false
    end
  end
  return true
end

function cls.SetIntersect(listAa, listBb)
  local listA = listAa
  if type(listAa) ~= "table" then
    listA = {listAa}
  end
  local listB = listBb
  if type(listBb) ~= "table" then
    listB = {listBb}
  end
  if #listA == 0 or #listB == 0 then
    logError("SetIntersect listA or listB length is 0")
    return true
  end
  local mapA = {}
  for _, value in ipairs(listA) do
    mapA[value] = true
  end
  for _, value in ipairs(listB) do
    if mapA[value] ~= true then
      return true
    end
  end
  return false
end

function cls.CheckEquipNum(limitParam, ...)
  local param = {
    ...
  }
  local heroId = param[1]
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    logError("Data.heroData:GetHeroById err. heroId:" .. heroId)
    return false
  end
  local equipTbl = heroInfo.Equips
  local result = cls.CheckOperate(equipTbl, limitParam.operation, limitParam[1], ...)
  if result then
    return true, nil, 1
  end
  return false, limitParam.desc
end

cls.LimitFunc = {
  [cls.LimitType.ADVANCE] = cls._CheckAdvance,
  [cls.LimitType.INTENSIFY] = cls.AlwaysTrue,
  [cls.LimitType.LV] = cls._CheckLv,
  [cls.LimitType.DURABILITY] = cls.AlwaysTrue,
  [cls.LimitType.EQUIP] = cls.AlwaysTrue,
  [cls.LimitType.Manual] = cls._CheckManual,
  [cls.LimitType.FETTERS] = cls.AlwaysTrue,
  [cls.LimitType.SHIPTYPE] = cls._CheckType,
  [cls.LimitType.CONSTELLATION] = cls._CheckConstellation,
  [cls.LimitType.COUNTRY] = cls._CheckCountry,
  [cls.LimitType.FIXEDSHIP] = cls._CheckFixShip,
  [cls.LimitType.ASSISFLEETLEVEL] = cls._CheckAssisFleetAverageLevel,
  [cls.LimitType.ASSISFLEETEQUIP] = cls._CheckAssisEquip,
  [cls.LimitType.ASSISTFLEET] = cls._CheckAssistFleet,
  [cls.LimitType.USESPCOMMAND] = cls._CheckSPCommand,
  [cls.LimitType.PASSSECTION] = cls._CheckSection,
  [cls.LimitType.ASSISTFLEETBREAKLV] = cls._CheckFleetAverageBreakLevel,
  [cls.LimitType.ASSISTFLEETTYPE] = cls._CheckAssisShipType,
  [cls.LimitType.AUTOBATTLE] = cls._CheckAutoBattle,
  [cls.LimitType.SCRIPT] = cls._Script
}
return cls
