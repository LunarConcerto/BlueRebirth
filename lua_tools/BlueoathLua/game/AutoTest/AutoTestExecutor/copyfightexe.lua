local CopyFightExe = class("game.AutoTest.AutoTestExecutor.CopyFightExe", GR.requires.Executor)

function CopyFightExe:init()
  self.nWaitFrame = 0
  self.nTargetFrame = 5
  self.strName = "CopyFightExe"
end

function CopyFightExe:tick()
  if self.nWaitFrame >= self.nTargetFrame then
    if UIPageManager:IsExistPage("LevelDetailsPage") then
      local bClick = GR.autoTestManager:clickBtn("MainRoot/LevelDetailsPage/Right/bu_chuzhenganniu")
      if bClick then
        self:stop()
      end
    end
  else
    self.nWaitFrame = self.nWaitFrame + 1
  end
end

function CopyFightExe:resetImp()
  self.nWaitFrame = 0
end

return CopyFightExe
