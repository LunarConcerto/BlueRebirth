local SerialExecutor = class("util.Executor.SerialExecutor", require("util.Executor.GroupExecutor"))

function SerialExecutor:init()
  self.objCurExecutor = nil
  self.nCurIndex = nil
end

function SerialExecutor:playImp()
  self.objCurExecutor = nil
  self.nCurIndex = 1
end

function SerialExecutor:onStop()
  if self.objCurExecutor ~= nil then
    self.objCurExecutor:stop()
  end
end

function SerialExecutor:tick()
  if self.state == ExecutorState.Running then
    if self.objCurExecutor == nil then
      self.objCurExecutor = self.tblExecutors[self.nCurIndex]
    end
    if self.objCurExecutor ~= nil then
      self.objCurExecutor:tick()
    else
      logError("objExecutor is nil")
    end
    local bEnd = self.objCurExecutor:isEnd()
    if bEnd then
      self.objCurExecutor = nil
      self.nCurIndex = self.nCurIndex + 1
      if self.nCurIndex > #self.tblExecutors then
        self:stop()
      end
    end
  end
end

function SerialExecutor:resetImp()
  for k, v in pairs(self.tblExecutors) do
    v:reset()
  end
end

function SerialExecutor:tostring()
  local strResult = self.strName
  strResult = strResult .. " SerialExecutor:"
  for k, v in pairs(self.tblExecutors) do
    strResult = strResult .. " " .. v:tostring() .. ", "
  end
  strResult = strResult .. " \t\t\n"
  return strResult
end

return SerialExecutor
