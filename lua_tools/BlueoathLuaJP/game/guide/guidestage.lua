local GuideStage = class("Game.Guide.GuideStage")
local requireBranch = require("Game.Guide.GuideBranch")
local requirePara = require("Game.Guide.GuideParagrapha")
local tblInsert = table.insert

function GuideStage:initialize(guideStageConfig)
  self.mTabNodes = nil
  self.mCurNode = nil
  self.config = guideStageConfig
  self.mStartNode = nil
  self.nId = guideStageConfig.id
  self.objExitTrigger = nil
  self:init()
end

function GuideStage:init()
  self.mTabNodes = {}
  local nodes = self.config.nodes
  local nCount = #nodes
  for i = 1, nCount do
    local tabConfig = nodes[i]
    local objNode
    if tabConfig.condition ~= nil then
      objNode = requireBranch:new(tabConfig, self)
    else
      objNode = requirePara:new(tabConfig, self)
    end
    self.mTabNodes[tabConfig.id] = objNode
    if self.config.firstNodeId == tabConfig.id then
      self.mStartNode = objNode
    end
  end
  self.objExitTrigger = GR.guideHub.requireTriggerListner:new(self.__onExitTrigger, self)
end

function GuideStage:start(param)
  if self.config.exitTrigger ~= nil then
    self.objExitTrigger:register(self.config.exitTrigger)
  end
  if param ~= nil then
    self:__handlerFirstEnter(param)
  else
    self:__handlerNormalStart()
  end
end

function GuideStage:getCurStep()
  if self.mCurNode ~= nil then
    return self.mCurNode:getCurStep()
  end
end

function GuideStage:__handlerFirstEnter(param)
  local paraId = tonumber(param[1])
  local paraIndex = tonumber(param[2])
  local objNode = self.mTabNodes[paraId]
  if objNode == nil then
    return
  end
  local bPassKey = objNode:havePassKeyPoint(paraIndex)
  if bPassKey then
    GR.guideHub:logError("jump " .. tostring(paraId) .. "by key")
    local objNextNode = self:__getNextNode(true, objNode)
    if objNextNode ~= nil then
      self:doNode(objNextNode)
    else
      self:__onStageDone()
    end
  elseif objNode:checkJump() then
    GR.guideHub:logError("jump " .. tostring(paraId) .. "by check")
    local objNextNode = self:__getNextNode(true, objNode)
    if objNextNode ~= nil then
      self:doNode(objNextNode)
    else
      self:__onStageDone()
    end
  else
    self:doNodeRecall(objNode)
  end
end

function GuideStage:doNodeRecall(objNode)
  local nRecallNodeId = objNode:getRecallNodeId()
  if nRecallNodeId ~= nil and nRecallNodeId ~= 0 then
    local recallNode = self.mTabNodes[nRecallNodeId]
    self:doNode(recallNode, 1)
  else
    self:doNode(objNode, 1)
  end
end

function GuideStage:__handlerNormalStart()
  local bNeedPermit = GR.guideHub:userPermit(self)
  if not bNeedPermit then
    self:doNormalStart()
  end
end

function GuideStage:doNormalStart()
  if self.mStartNode:checkJump() then
    self:__startNextNode(self.mStartNode)
  else
    self:doNode(self.mStartNode)
  end
end

function GuideStage:canTrigger(nTriggerType)
  if self.config.triggerType[1] ~= nTriggerType then
    return false
  end
  local bMeetCondition = GR.guideHub:ismeetOneCondition(self.config.condition)
  return bMeetCondition
end

function GuideStage:getCurNode()
  return self.mCurNode
end

function GuideStage:doNode(objNode, param)
  self.mCurNode = objNode
  objNode:start(param)
end

function GuideStage:onNodeDone(objNode)
  self.mCurNode = nil
  self:__startNextNode(objNode)
end

function GuideStage:__startNextNode(objNode, param)
  local objNextNode = self:__getNextNode(false, objNode)
  if objNextNode == nil then
    self:__onStageDone()
  else
    self:doNode(objNextNode, param)
  end
end

function GuideStage:__getNextNode(bFirstEnter, objCurNode)
  local nNextNodeId = objCurNode:getNextNodeId()
  if nNextNodeId == nil then
    return nil
  end
  local objNextNode
  while true do
    if nNextNodeId == nil then
      return nil
    end
    objNextNode = self.mTabNodes[nNextNodeId]
    if objNextNode:checkJump() then
      GR.guideHub:logError("jump " .. nNextNodeId .. "by check")
      nNextNodeId = objNextNode:getNextNodeId()
    elseif bFirstEnter then
      local nRecallNodeId = objNextNode:getRecallNodeId()
      if nRecallNodeId ~= nil and nRecallNodeId ~= 0 then
        local recallNode = self.mTabNodes[nRecallNodeId]
        return recallNode
      else
        return objNextNode
      end
    else
      return objNextNode
    end
  end
end

function GuideStage:getDoingParam()
  if self.mCurNode == nil then
    return nil
  end
  local tabParam = {}
  local nParaId, nStepId = self.mCurNode:getDoingParam()
  tblInsert(tabParam, self.config.id)
  tblInsert(tabParam, nParaId)
  tblInsert(tabParam, nStepId)
  return tabParam
end

function GuideStage:interrupt()
  if self.mCurNode ~= nil then
    self.mCurNode:interrupt()
  end
end

function GuideStage:__onExitTrigger()
  self:__onStageDone()
  GR.guideHub:clearGuide()
  eventManager:RegisterEvent(LuaEvent.GuideSettingReceive, self.__onReceiveUserSetting, self)
end

function GuideStage:__onReceiveUserSetting()
  eventManager:UnregisterEvent(LuaEvent.GuideSettingReceive, self.__onReceiveUserSetting, self)
  GR.guideManager:init()
end

function GuideStage:__onStageDone()
  self.objExitTrigger:unRegister()
  GR.guideManager:onGuideStageDone(self)
end

return GuideStage
