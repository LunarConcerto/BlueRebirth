local NormalStateBase = class("game.Guide.NormalState.NormalStateBase")

function NormalStateBase:initialize(nType, objManager, tblConfig)
  self.nType = nType
  self.objManager = objManager
  self.tblBehavioursRecord = {}
  self.objStartListner = nil
  self.objEndListner = nil
  self.tblStartPointParam = tblConfig.StartPoint
  self.tblEndPointParam = tblConfig.EndPoint
  self.tblBehaviourConfigs = tblConfig.Behaviours
  self.bBehaviourEnd = false
  self.bEndListner = false
  self:__init()
end

function NormalStateBase:__init()
  if self.tblBehaviourConfigs ~= nil then
    self:buildBehaviours(self.tblBehaviourConfigs)
  end
end

function NormalStateBase:start()
  if self.tblStartPointParam ~= nil then
    self.objStartListner = GR.guideHub.requireTriggerListner:new(self.__onStartTrigger, self)
    self.objStartListner:register(self.tblStartPointParam)
  else
    self:__doBehaviourState()
  end
end

function NormalStateBase:__onStartTrigger()
  self:__clearStartListner()
  self:__doBehaviourState()
end

function NormalStateBase:__doBehaviourState()
  self:interruptAllBehaviours()
  if self.tblEndPointParam ~= nil then
    self.objEndListner = GR.guideHub.requireTriggerListner:new(self.__onEndListner, self)
    self.objEndListner:register(self.tblEndPointParam)
  else
    self.bEndListner = true
  end
  self:doAllBehaviours()
end

function NormalStateBase:buildBehaviours(tblBehaviours)
  local nCount = #tblBehaviours
  self.tblBehavioursRecord = {}
  for i = 1, nCount do
    local tblOneBehaviour = tblBehaviours[i]
    local objBehaviour = GR.guideHub:buildBehaviour(tblOneBehaviour, self)
    self.tblBehavioursRecord[objBehaviour] = false
  end
  return self.tblBehavioursRecord
end

function NormalStateBase:doAllBehaviours()
  for k, v in pairs(self.tblBehavioursRecord) do
    k:doBehaviour()
  end
end

function NormalStateBase:interruptAllBehaviours()
  for k, v in pairs(self.tblBehavioursRecord) do
    self.tblBehavioursRecord[k] = false
    k:interrupt()
  end
end

function NormalStateBase:onBehaviourDone(objBehaviour)
  local bAllDone = true
  for behaviour, bDone in pairs(self.tblBehavioursRecord) do
    if behaviour == objBehaviour then
      self.tblBehavioursRecord[behaviour] = true
    elseif not bDone then
      bAllDone = false
    end
  end
  if bAllDone then
    self:onAllBehaviourDone()
  end
end

function NormalStateBase:onAllBehaviourDone()
  self.bBehaviourEnd = true
  self:__tryEnd()
end

function NormalStateBase:__tryEnd()
  if self.bBehaviourEnd and self.bEndListner then
    self:endState()
  end
end

function NormalStateBase:__onEndListner()
  self:__clearEndListner()
  self.bEndListner = true
  self:__tryEnd()
end

function NormalStateBase:interrupt()
  self:interruptAllBehaviours()
  self:__clearStartListner()
  self:__clearEndListner()
end

function NormalStateBase:__clearStartListner()
  if self.objStartListner ~= nil then
    self.objStartListner:unRegister()
    self.objStartListner = nil
  end
end

function NormalStateBase:__clearEndListner()
  if self.objEndListner ~= nil then
    self.objEndListner:unRegister()
    self.objEndListner = nil
  end
end

function NormalStateBase:endState()
  self.bBehaviourEnd = false
  self.bEndListner = false
  self:__onEnd()
  self.objManager:onStateDone(self.nType)
end

function NormalStateBase:__onEnd()
end

return NormalStateBase
