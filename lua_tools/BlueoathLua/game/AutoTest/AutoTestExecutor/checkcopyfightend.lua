local CheckCopyFightEnd = class("game.AutoTest.AutoTestExecutor.CheckCopyFightEnd", GR.requires.Executor)

function CheckCopyFightEnd:init()
  self.strName = "CheckCopyFightEnd"
  self.bEnterBattle = false
end

function CheckCopyFightEnd:tick()
  local curStage = stageMgr:GetCurStageType()
  if not self.bEnterBattle then
    if curStage == EStageType.eStageSimpleBattle then
      self.bEnterBattle = true
    end
  elseif curStage == EStageType.eStageMain then
    local objParent = self
    while objParent ~= nil do
      local parent = objParent:getParent()
      if parent ~= nil then
        objParent = parent
      else
        break
      end
    end
    logError("end")
    objParent:stop()
  end
end

function CheckCopyFightEnd:resetImp()
  self.bEnterBattle = false
end

return CheckCopyFightEnd
