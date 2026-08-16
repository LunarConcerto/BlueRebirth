local GuideStep = class("Game.Guide.GuideStep")
local tblInsert = table.insert

function GuideStep:initialize(nId, objGuidePara, nIndex)
  self.mGuidePara = nil
  self.nId = nil
  self.config = nil
  self.index = nil
  self.tblStates = nil
  self.objCurState = nil
  self:init(nId, objGuidePara, nIndex)
end

function GuideStep:init(nId, objGuidePara, nIndex)
  self.mGuidePara = objGuidePara
  self.nId = nId
  self.config = GR.guideHub.tblGuideStepConfig.GuideItemList[nId]
  self.index = nIndex
  self.tblStates = {}
  tblInsert(self.tblStates, GR.guideHub.stepBeginState:new(self))
  tblInsert(self.tblStates, GR.guideHub.waitOperateState:new(self))
  tblInsert(self.tblStates, GR.guideHub.waitOperateEnd:new(self))
end

function GuideStep:reset()
  for k, v in pairs(self.tblStates) do
    v:interrupt()
  end
end

function GuideStep:start(param)
  self:changeState(GUIDESTEP_STATE.BEGIN)
end

function GuideStep:changeState(nIndex)
  local state = self.tblStates[nIndex]
  if state == self.objCurState then
    return
  end
  state:start()
  self.objCurState = state
end

function GuideStep:interrupt()
  if self.objCurState ~= nil then
    self.objCurState:interrupt()
    self.objCurState = nil
  end
end

function GuideStep:notifyStepDone()
  self.mGuidePara:onStepDone(self)
end

return GuideStep
