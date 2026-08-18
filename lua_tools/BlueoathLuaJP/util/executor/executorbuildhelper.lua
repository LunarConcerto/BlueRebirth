local ExecutorBuildHelper = class("util.Executor.ExecutorBuildHelper")

function ExecutorBuildHelper:buildAutoTestExecutor(config)
  local objRoot = GR.requires.ParalelExecutor:new()
  objRoot.strName = "autostestParalel"
  local nCount = #config
  for i = 1, nCount do
    local tblOneConfig = config[i]
    local objSerial = self:__buildSerialExecutor(tblOneConfig)
    objRoot:addExecutor(objSerial)
  end
  return objRoot
end

function ExecutorBuildHelper:__buildSerialExecutor(tblConfig)
  local objSerial = GR.requires.SerialExecutor:new()
  objSerial.strName = "autostestSerial"
  local nCount = #tblConfig
  for i = 1, nCount do
    local tblOneConfig = tblConfig[i]
    local strExecutorName = tblOneConfig[1]
    local param = tblOneConfig[2]
    local objOneExecutor = require("game.AutoTest.AutoTestExecutor." .. tostring(strExecutorName)):new(param)
    objSerial:addExecutor(objOneExecutor)
  end
  return objSerial
end

return ExecutorBuildHelper
