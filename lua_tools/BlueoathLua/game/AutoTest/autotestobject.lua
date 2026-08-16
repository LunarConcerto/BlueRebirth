local AutoTestObject = class("game.AutoTest.AutoTestObject")

function AutoTestObject:initialize(tblConfig, objManager)
  self.tblConfig = tblConfig
  self.objManager = objManager
  self.objParalelExecutor = nil
  self:init()
end

function AutoTestObject:init()
  self.objParalelExecutor = GR.executorBuildHelper:buildAutoTestExecutor(self.tblConfig)
end

function AutoTestObject:play()
  local nState = self.objParalelExecutor:getState()
  if nState ~= ExecutorState.Wait then
    self.objParalelExecutor:reset()
  end
  self.objParalelExecutor:play()
end

function AutoTestObject:stop()
  self.objParalelExecutor:stop()
end

function AutoTestObject:reset()
  self.objParalelExecutor:reset()
end

function AutoTestObject:tick()
  if self.objParalelExecutor ~= nil then
    self.objParalelExecutor:tick()
    local state = self.objParalelExecutor:getState()
    if state == ExecutorState.End then
      self.objManager:onAutoTestDone(self)
    end
  end
end

return AutoTestObject
