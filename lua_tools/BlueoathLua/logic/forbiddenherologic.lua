local ForbiddenHeroLogic = class("logic.ForbiddenHeroLogic")
ForbiddenType = {
  Battle = 1,
  Building = 2,
  Bath = 3,
  Secretary = 4,
  Marry = 5,
  PersonalPlot = 6
}

function ForbiddenHeroLogic:initialize()
  self:_RegisterAllEvent()
end

function ForbiddenHeroLogic:ResetData()
end

function ForbiddenHeroLogic:_RegisterAllEvent()
end

function ForbiddenHeroLogic.ForbiddenConditionCopy(condition)
  local copyData = Data.copyData:GetCopyInfo()
  local startCopyId = condition[2]
  local endCopyId = condition[3]
  if endCopyId == 0 and copyData[startCopyId] ~= nil and 0 < copyData[startCopyId].FirstPassTime then
    return true
  end
  if endCopyId ~= 0 and copyData[startCopyId] ~= nil and 0 < copyData[startCopyId].FirstPassTime and (copyData[endCopyId] == nil or copyData[endCopyId].FirstPassTime == 0) then
    return true
  end
  return false
end

local ForbiddenCondition = {
  [1] = {
    func = ForbiddenHeroLogic.ForbiddenConditionCopy
  }
}

function ForbiddenHeroLogic:GetForbiddenConfById(id)
  local forbbidenConf = configManager.GetDataById("config_ship_forbidden", id)
  return forbbidenConf
end

function ForbiddenHeroLogic:GetHeroForbiddenSystem(heroId)
  local sfConfig = Logic.shipLogic:GetShipFleetByHeroId(heroId)
  if #sfConfig.forbidden_id == 0 then
    return false
  end
  local forbiddenSystem = {}
  for _, forbbidenId in ipairs(sfConfig.forbidden_id) do
    local forbbidenConf = self:GetForbiddenConfById(forbbidenId)
    local conditonType = forbbidenConf.forbidden_condition[1]
    local fun = ForbiddenCondition[conditonType].func
    local meetCondition = fun(forbbidenConf.forbidden_condition)
    if meetCondition then
      for i, v in ipairs(forbbidenConf.forbidden_type) do
        forbiddenSystem[v] = forbbidenConf.forbidden_tips[i]
      end
    end
  end
  return next(forbiddenSystem) ~= 0, forbiddenSystem
end

function ForbiddenHeroLogic:CheckForbiddenInSystem(heroId, forbiddenType)
  local isforbidden, forbiddenSystem = self:GetHeroForbiddenSystem(heroId)
  if not isforbidden then
    return false
  end
  if forbiddenSystem[forbiddenType] ~= nil then
    if forbiddenSystem[forbiddenType] ~= -1 then
      noticeManager:ShowTipById(forbiddenSystem[forbiddenType])
    end
    return true
  end
  return false
end

function ForbiddenHeroLogic:CheckForbiddenHeroInTab(heroTab, forbiddenType)
  for _, heroId in pairs(heroTab) do
    local forbidden = self:CheckForbiddenInSystem(heroId, forbiddenType)
    if forbidden then
      return true
    end
  end
  return false
end

return ForbiddenHeroLogic
