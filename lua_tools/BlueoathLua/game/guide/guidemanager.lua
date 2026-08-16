local GuideManager = class("Game.Guide.GuideManager")
local strDoneStagesKey = "GUIDE_DONE_STAGES"
local strDoingStageKey = "GUIDE_DOING_STAGE"
local requireStage = require("Game.Guide.GuideStage")
local guideStageConfig = require("config.ClientConfig.guideStageConfig")
local guideStepConfig = require("config.ClientConfig.guideStepConfig")

function GuideManager:initialize()
  self.tabCanTriggerStages = nil
  self.tabDoneStages = nil
  self.tblDoingStage = nil
  self.mCurStage = nil
  self.bCanTrigger = LuaMacro.bCanGuideTrigger
  self.guidePage = nil
  self.objNetCache = require("Game.Guide.Kits.GuideNetCache"):new()
  self.tblTriggerHolder = {}
  self.tblSameFrameTriggeredStages = {}
  LateUpdateBeat:Add(self.__tick, self)
end

function GuideManager:init()
  if not self.bCanTrigger then
    return
  end
  self:getDoingStageParam()
  self:getDoneStages()
  self:__getUntriggerdStages()
  self:registerAllTirgger()
  self.objEnterGameListner = GR.guideHub.requireTriggerListner:new(self.onTrigger, self)
  self.objEnterGameListner:register(TRIGGER_TYPE.LOGIN_END)
  eventManager:RegisterEvent(LuaCSharpEvent.GuideUserOpe, function(self, param)
    eventManager:SendEvent(LuaEvent.GuideUserOpe, param)
  end, self)
  GR.guideHub:logError(printTable(self.tblDoingStage))
  GR.guideHub:logError(printTable(self.tabDoneStages))
end

function GuideManager:registerAllTirgger()
  for strId, stage in pairs(self.tabCanTriggerStages) do
    local stageConfig = stage.config
    self.tblTriggerHolder[strId] = GR.guideHub.requireTriggerListner:new(self.onTrigger, self)
    self.tblTriggerHolder[strId]:register(stageConfig.triggerType)
  end
end

function GuideManager:resetAndRemoveEvent()
  self:reset()
  self:removeEvent()
end

function GuideManager:reset()
  if self.mCurStage ~= nil then
    self.mCurStage:interrupt()
    self.mCurStage = nil
  end
  self.tblDoingStage = nil
  self.tabDoneStages = nil
end

function GuideManager:removeEvent()
  eventManager:UnregisterEventByHandler(self)
  for k, v in pairs(self.tblTriggerHolder) do
    v:unRegister()
  end
  self.tblTriggerHolder = {}
  if self.objEnterGameListner ~= nil then
    self.objEnterGameListner:unRegister()
    self.objEnterGameListner = nil
  end
end

function GuideManager:__tick()
  local maxWeightStage
  for k, v in pairs(self.tblSameFrameTriggeredStages) do
    if maxWeightStage == nil then
      maxWeightStage = v
    elseif v.config.weight > maxWeightStage.config.weight then
      maxWeightStage = v
    end
  end
  if maxWeightStage ~= nil then
    self.tblSameFrameTriggeredStages = {}
    self:startStage(maxWeightStage)
  end
end

function GuideManager:__getUntriggerdStages()
  local tabAllStagesConfig = guideStageConfig.stages
  local tabDoingStageParam = self.tblDoingStage
  local nDoingStageId
  if tabDoingStageParam ~= nil then
    nDoingStageId = tabDoingStageParam.stageId
  end
  self.tabCanTriggerStages = {}
  local tabAllDoneStages = self.tabDoneStages
  local nCount = #tabAllStagesConfig
  for i = 1, nCount do
    local stageConfig = tabAllStagesConfig[i]
    local strId = tostring(stageConfig.id)
    local bDone = false
    if tabAllDoneStages ~= nil and tabAllDoneStages[strId] ~= nil then
      bDone = true
    end
    if nDoingStageId ~= nil and nDoingStageId == stageConfig.id then
      bDone = true
    end
    if not bDone then
      self.tabCanTriggerStages[strId] = requireStage:new(stageConfig)
    end
  end
end

function GuideManager:onTrigger(nTriggerType)
  local handlerFunc = self.tabTriggerTypeToHandler[nTriggerType]
  if handlerFunc ~= nil then
    handlerFunc(self, nTriggerType)
  else
    self:__handlerDefaultTrigger(nTriggerType)
  end
end

function GuideManager:getCurStep()
  if self.mCurStage ~= nil then
    return self.mCurStage:getCurStep()
  end
end

function GuideManager:isPlayingGuide()
  return self.mCurStage ~= nil
end

function GuideManager:__getTriggerdStage(nTriggerType)
  if self.tabCanTriggerStages == nil then
    return
  end
  local triggerStage
  for strId, stage in pairs(self.tabCanTriggerStages) do
    local stageConfig = stage.config
    if stage:canTrigger(nTriggerType) then
      if triggerStage == nil then
        triggerStage = stage
      elseif stageConfig.weight > triggerStage.config.weight then
        triggerStage = stage
      end
    end
  end
  return triggerStage
end

function GuideManager:startStage(guideStage, param)
  if not self.bCanTrigger then
    return
  end
  if self.mCurStage ~= nil then
    return
  end
  GR.guideHub:onStageStart()
  self.mCurStage = guideStage
  guideStage:start(param)
end

function GuideManager:onGuideStageDone(guideStage)
  GR.guideHub:logError("guidemanager node done")
  if guideStage == self.mCurStage then
    self:saveDoneStage(guideStage)
    self.mCurStage = nil
    GR.guideHub:onStageDone()
  end
end

function GuideManager:saveDoneStage(guideStage)
  if guideStage == nil or guideStage.config == nil then
    logError("param illegal")
    return
  end
  self.tblDoingStage = nil
  local strKey = tostring(guideStage.config.id)
  if self.tabCanTriggerStages[strKey] ~= nil then
    self.tabCanTriggerStages[strKey] = nil
  end
  self.tabDoneStages = self.tabDoneStages or {}
  if self.tabDoneStages[strKey] == nil then
    self.tabDoneStages[strKey] = 1
  else
    self.tabDoneStages[strKey] = self.tabDoneStages[strKey] + 1
  end
  local strDoneStages = Serialize(self.tabDoneStages)
  self:saveParamToNet(strDoneStagesKey, strDoneStages)
  self:saveParamToNet(strDoingStageKey, "")
end

function GuideManager:saveDoingStage()
  if self.mCurStage == nil then
    return
  end
  param = self.mCurStage:getDoingParam()
  local mParam = {
    stageId = param[1],
    paraId = param[2],
    stepId = param[3]
  }
  GR.guideHub:logError("saveDoingStage " .. printTable(mParam))
  local strParam = Serialize(mParam)
  self:saveParamToNet(strDoingStageKey, strParam)
  self.tblDoingStage = mParam
end

function GuideManager:saveParamToNet(strKey, strValue)
  self.objNetCache:sentNet(strKey, strValue)
end

function GuideManager:getDoingStageParam()
  if self.tblDoingStage == nil then
    local setValue = Data.guideData:GetSettingByKey(strDoingStageKey)
    if setValue then
      local tblValue = Unserialize(setValue)
      self.tblDoingStage = tblValue
    end
  end
  return self.tblDoingStage
end

function GuideManager:getDoneStages()
  if self.tabDoneStages == nil then
    local setValue = Data.guideData:GetSettingByKey(strDoneStagesKey)
    if setValue then
      local tblValue = Unserialize(setValue)
      self.tabDoneStages = tblValue
    end
  end
end

function GuideManager:getCurStage()
  return self.mCurStage
end

function GuideManager:__handlerMainStage(nTriggerType)
  local lastStage = stageMgr:GetCurStageType()
  if lastStage == EStageType.eStageLogin then
    self:__handlerCheckDoingTrigger(nTriggerType)
  end
end

function GuideManager:__handlerCheckDoingTrigger(nTriggerType)
  local param = self.tblDoingStage
  local bHaveDoingParam = true
  local nConfigId, stageConfig
  if param == nil then
    bHaveDoingParam = false
  else
    nConfigId = param.stageId
    if nConfigId == nil or nConfigId == -1 then
      bHaveDoingParam = false
    end
    stageConfig = self:__getStageConfigById(nConfigId)
    if stageConfig ~= nil then
    else
      bHaveDoingParam = false
    end
    local bDoingStageIsDone = self:__isStageDone(nConfigId)
    if bDoingStageIsDone then
      bHaveDoingParam = false
      self:__clearDoingParam()
    end
  end
  if not bHaveDoingParam then
    self:__handlerDefaultTrigger(nTriggerType)
    return
  end
  local stageParam = {
    param.paraId,
    param.stepId
  }
  if stageConfig == nil then
    logError("dont have doing stage " .. tostring(nConfigId))
    return
  end
  local nCondition = stageConfig.condition
  if nCondition ~= nil and not GR.guideHub:ismeetOneCondition(nCondition) then
    return
  end
  local doingStage = requireStage:new(stageConfig)
  if doingStage ~= nil then
    self:startStage(doingStage, stageParam)
  end
end

function GuideManager:__clearDoingParam()
  self.tblDoingStage = nil
  self:saveParamToNet(strDoingStageKey, "")
end

function GuideManager:__isStageDone(nStageId)
  if self.tabDoneStages == nil then
    return false
  end
  local strKey = tostring(nStageId)
  return self.tabDoneStages[strKey] ~= nil
end

function GuideManager:__getStageConfigById(nId)
  local nCount = #guideStageConfig.stages
  for i = 1, nCount do
    local config = guideStageConfig.stages[i]
    if config.id == nId then
      return config
    end
  end
end

function GuideManager:__handlerDefaultTrigger(nTriggerType)
  local triggerStage = self:__getTriggerdStage(nTriggerType)
  if triggerStage ~= nil then
    if nTriggerType == TRIGGER_TYPE.LOGIN_END then
      self:startStage(triggerStage)
    else
      table.insert(self.tblSameFrameTriggeredStages, triggerStage)
    end
  end
end

function GuideManager:curStepHaveJMPBeh()
  if self.mCurStage ~= nil then
    local curStep = self.mCurStage:getCurStep()
    local tblBehaviours = curStep.config.BeginBehaviour
    if tblBehaviours ~= nil and next(tblBehaviours) ~= nil then
      for i = 1, #tblBehaviours do
        if tblBehaviours[i][1] == GUIDE_BEHAVIOUR.ENTER_BATTLE then
          return true
        end
      end
    end
  end
end

GuideManager.tabTriggerTypeToHandler = {
  [TRIGGER_TYPE.ENTER_GAME] = GuideManager.__handlerMainStage,
  [TRIGGER_TYPE.LOGIN_END] = GuideManager.__handlerCheckDoingTrigger
}

function GuideManager:curStepCanToMain()
  if self.mCurStage ~= nil then
    local curStep = self.mCurStage:getCurStep()
    if curStep == nil then
      return true
    end
    local nId = curStep.nId
    local bCan = CanNotLoginToMainSteps[nId] == nil
    return bCan
  end
  return true
end

return GuideManager
