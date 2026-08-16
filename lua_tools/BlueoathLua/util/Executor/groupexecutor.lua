local GroupExecutor = class("util.Executor.GroupExecutor", GR.requires.Executor)
local tblInsert = table.insert

function GroupExecutor:addExecutor(objExecutor)
  tblInsert(self.tblExecutors, objExecutor)
  objExecutor:setParent(self)
end

function GroupExecutor:onStop()
  for k, v in pairs(self.tblExecutors) do
    v:stop()
  end
end

return GroupExecutor
