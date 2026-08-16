local ParalelExecutor = class("util.Executor.ParalelExecutor", require("util.Executor.GroupExecutor"))

function ParalelExecutor:playImp()
  for k, v in pairs(self.tblExecutors) do
    v:play()
  end
end

function ParalelExecutor:onStop()
  for k, v in pairs(self.tblExecutors) do
    v:stop()
  end
end

function ParalelExecutor:tick()
  if self.state == ExecutorState.Running then
    local bAllEnd = true
    for k, v in pairs(self.tblExecutors) do
      local bEnd = v:isEnd()
      if not bEnd then
        v:tick()
        bAllEnd = false
      end
    end
    if bAllEnd then
      self.state = ExecutorState.End
    end
  end
end

function ParalelExecutor:resetImp()
  for k, v in pairs(self.tblExecutors) do
    v:reset()
  end
end

function ParalelExecutor:tostring()
  local strResult = tostring(self.strName)
  strResult = strResult .. " ParalelExecutor: \n"
  for k, v in pairs(self.tblExecutors) do
    strResult = strResult .. " " .. v:tostring()
  end
  strResult = strResult .. " \t\t"
  return strResult
end

return ParalelExecutor
