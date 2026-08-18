local GuideStepState = class("game.Guide.GuideStepStates.GuideStepState", require("util.behaviour.behaviourHolder"))

function GuideStepState:initialize(objStep)
  self.step = objStep
  self.mEvents = {}
  self.tblBehavioursRecord = {}
end

function GuideStepState:start()
  self:onStart()
end

function GuideStepState:endState()
  self:removeAllEvents()
  self:onEnd()
end

function GuideStepState:onStart()
end

function GuideStepState:onEnd()
end

function GuideStepState:interrupt()
end

function GuideStepState:registerEvent(nEventID, funcCB)
  table.insert(self.mEvents, {nEventID, funcCB})
  eventManager:RegisterEvent(nEventID, funcCB, self)
end

function GuideStepState:removeEvent(nEventID, funcCB)
  eventManager:UnregisterEvent(nEventID, funcCB)
  local nCount = #self.mEvents
  for i = 1, nCount do
    local event = self.mEvents[i]
    if event[1] == nEventID and event[2] == funcCB then
      table.remove(self.mEvents, i)
      return
    end
  end
end

function GuideStepState:removeAllEvents()
  local nCount = #self.mEvents
  for i = 1, nCount do
    local event = self.mEvents[i]
    eventManager:UnregisterEvent(event[1], event[2])
  end
  self.mEvents = {}
end

function GuideStepState:buildBehaviours(tblBehaviours)
  local nCount = #tblBehaviours
  self.tblBehavioursRecord = {}
  for i = 1, nCount do
    local tblOneBehaviour = tblBehaviours[i]
    local objBehaviour = GR.guideHub:buildBehaviour(tblOneBehaviour, self)
    self.tblBehavioursRecord[objBehaviour] = false
  end
  return self.tblBehavioursRecord
end

function GuideStepState:doAllBehaviours()
  for k, v in pairs(self.tblBehavioursRecord) do
    k:doBehaviour()
  end
end

function GuideStepState:onBehaviourDone(objBehaviour)
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

function GuideStepState:onAllBehaviourDone()
end

return GuideStepState
