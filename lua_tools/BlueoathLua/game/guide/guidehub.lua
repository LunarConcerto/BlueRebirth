local GuideHub = class("game.guide.guidehub")
local strDoningKey = "GUIDE_DOING_STAGE"
require("game.Guide.Guidedefine")

function GuideHub:initialize()
  self.guideTriggermananger = nil
  self.behaviourManager = nil
  self.conditionCheck = nil
  self.userPermitObj = nil
  self.userOpeElementConfig = nil
  self.dynamicUserOpeElement = nil
  self.tblGuideBattle = nil
  self:init()
end

function GuideHub:init()
  self.tblGuideStepConfig = require("config.ClientConfig.guideStepConfig")
  self.stepBeginState = require("game.Guide.GuideStepStates.StepBeginState")
  self.waitOperateState = require("game.Guide.GuideStepStates.WaitOperateState")
  self.waitOperateEnd = require("game.Guide.GuideStepStates.waitOperateEnd")
  self.requireTriggerListner = require("Game.Guide.Kits.GuideTriggerListner")
  self.guideTriggermananger = require("game.guide.guidetrigger.guidetriggermanager"):new()
  self.behaviourManager = require("game.guide.GuideBehaviours.guideBehaviourManager"):new()
  self.conditionCheck = require("game.guide.GuideConditionCheckHelper"):new()
  self.pageController = require("game.guide.GuidePageController"):new()
  self.userPermitObj = require("game.guide.Kits.GuideUserPermit"):new()
  self.userOpeElementConfig = require("config.ClientConfig.UserOpeElementConfig")
  self.guideCacheData = require("game.guide.GuideCacheData"):new()
  self.dynamicUserOpeElement = require("game.guide.Kits.DynamicUserOpeElement"):new()
end

function GuideHub:CanLoginToMain()
  local bCanToMain = GR.guideManager:curStepCanToMain()
  return bCanToMain
end

function GuideHub:addTrigger(nkey, objParam)
  self.guideTriggermananger:AddTriggerKey(nkey, objParam)
  GR.luaInteraction:addCSharpTrigger(nkey, objParam)
end

function GuideHub:removeTrigger(nkey)
  self.guideTriggermananger:RemoveTriggerKey(nkey)
  GR.luaInteraction:removeCSharpTrigger(nkey)
end

function GuideHub:buildBehaviour(tblHehaviour, objHolder)
  local nType = tblHehaviour[1]
  local objParam = tblHehaviour[2]
  local result = self.behaviourManager:buildBehaviour(nType, objHolder, objParam)
  return result
end

function GuideHub:ismeetOneCondition(nConditionId, objParam, bOpposite)
  local strType = type(nConditionId)
  if strType == "number" then
    return self.conditionCheck.isMeetCondition(nConditionId, objParam, bOpposite)
  elseif strType == "table" then
    local tblCondition = nConditionId
    return self.conditionCheck.isMeetCondition(tblCondition[1], tblCondition[2], tblCondition[3])
  end
end

function GuideHub:logError(strContent)
end

function GuideHub:doCSharpInstrument(nType, objParam)
  GR.luaInteraction:doCSharpBehaviour(nType, objParam)
end

function GuideHub:isInGuide()
  return GR.guideManager:isPlayingGuide()
end

function GuideHub:isInFleetHeroGuide()
  local bInGuide = self:isInGuide()
  if not bInGuide then
    return false
  else
    local tblCurStage = GR.guideManager:getCurStage()
    local nId = tblCurStage.nId
    return nId == 120000
  end
end

function GuideHub:isInGuideBattle()
  local copyInfo = Logic.copyLogic:GetAttackCopyInfo()
  if copyInfo == nil then
    return false
  end
  local nCopyDisplayId = copyInfo.CopyId
  if self.tblGuideBattle == nil then
    self.tblGuideBattle = configManager.GetDataById("config_parameter", 305).arrValue
  end
  for k, v in pairs(self.tblGuideBattle) do
    if v == nCopyDisplayId then
      return true
    end
  end
  return false
end

function GuideHub:ShowGuidePausePage()
  local bInGuide = self:isInGuide()
  if not bInGuide then
    return false
  else
    local tblCurStage = GR.guideManager:getCurStage()
    local nId = tblCurStage.nId
    if ShowGuidePausePageStages[nId] ~= nil then
      return true
    else
      return false
    end
  end
end

function GuideHub:onPageOpen(objPage)
  self.pageController:onPageOpen(objPage)
  GR.guideManager.guidePage = objPage
end

function GuideHub:getGuidePage()
  return self.pageController:getGuidePage()
end

function GuideHub:closeGuidePage()
  self.pageController:closePage()
end

function GuideHub:onStageStart()
  self.pageController:onStageStart()
end

function GuideHub:onStageDone()
  self.pageController:onStageDone()
end

function GuideHub:clearGuide()
  GR.guideManager:resetAndRemoveEvent()
  self:closeGuidePage()
  GR.luaInteraction:clearTrigger()
  self.guideTriggermananger:Clear()
  GR.luaInteraction:clearGuideInfluenceData()
  UIHelper.ClosePage("PlotPage")
  self.guideCacheData:ResetData()
end

function GuideHub:onLoginOK()
  GR.guideManager:init()
  eventManager:SendEvent(LuaEvent.GuideTriggerPoint, TRIGGER_TYPE.LOGIN_END)
  local bCanToMain = self:CanLoginToMain()
  return bCanToMain
end

function GuideHub:enableElement(nElementId, bCanSelfCtrl)
  local objGuidePage = self:getGuidePage()
  if objGuidePage ~= nil then
    objGuidePage:EnableElement(nElementId, bCanSelfCtrl)
  else
    logError("guidePage is nil when enableElement")
  end
end

function GuideHub:disableElement()
  local objGuidePage = self:getGuidePage()
  if objGuidePage ~= nil then
    objGuidePage:DisableElement(nElementId, bCanSelfCtrl)
  else
    logError("guidePage is nil when disableElement")
  end
end

function GuideHub:exceptionCheck()
  eventManager:RegisterEvent(LuaEvent.GuideInfoReceive, self.__onReceiveGuideInfo, self)
end

function GuideHub:__onReceiveGuideInfo()
  if not self:isInGuide() then
    return
  end
  eventManager:UnregisterEventByHandler(self)
  local curDoingParam = GR.guideManager.tblDoingStage
  if curDoingParam == nil then
    return
  end
  local setValue = Data.guideData:GetSettingByKey(strDoningKey)
  if setValue then
    local tblDoingStage = Unserialize(setValue)
    if tblDoingStage == nil then
      return
    end
    if not self:__isDoingStageSame(tblDoingStage, curDoingParam) then
      excMgr:_BackLogin()
    end
  end
end

function GuideHub:__isDoingStageSame(tblDoing1, tblDoing2)
  if tblDoing1.stageId ~= tblDoing2.stageId or tblDoing1.paraId ~= tblDoing2.paraId or tblDoing1.tblstepId ~= tblDoing2.tblstepId then
    return false
  end
  return true
end

function GuideHub:setGuideInfluenceData(type, nData)
  GR.luaInteraction:setGuideInfluenceData(type, nData)
end

function GuideHub:userPermit(objStage)
  return self.userPermitObj:userPermit(objStage)
end

function GuideHub:getUserOpeElementConfig(nId)
  local bDynamic = self.dynamicUserOpeElement:isDynamic(nId)
  if bDynamic then
    return self.dynamicUserOpeElement:getDynamicUserOpeConfig(nId)
  else
    if self.userOpeElementConfig == nil then
      return nil
    end
    return self.userOpeElementConfig[nId]
  end
end

function GuideHub:getGuideCachedata()
  return self.guideCacheData
end

function GuideHub:TestSetDoingParam()
  local tblParam = {
    stageId = 10000,
    paraId = 181,
    stepId = 1
  }
  local strParam = Serialize(tblParam)
  GR.guideManager:saveParamToNet("GUIDE_DOING_STAGE", strParam)
end

return GuideHub
