local OpenMainLineExe = class("game.AutoTest.AutoTestExecutor.OpenMainLineExe", GR.requires.Executor)

function OpenMainLineExe:init()
  self.nWaitFrame = 0
  self.nTargetFrame = 5
  self.strName = "OpenMainLineExe"
end

function OpenMainLineExe:tick()
  UIHelper.OpenPage("HomePage")
  if self.nWaitFrame >= self.nTargetFrame then
    if UIPageManager:IsExistPage("HomePage") then
      local bClick = GR.autoTestManager:clickBtn("MainRoot/HomePage/objHide/right/bu_chuzhenganniu/btn_battle")
      if bClick then
        self:stop()
      end
    end
  else
    self.nWaitFrame = self.nWaitFrame + 1
  end
end

function OpenMainLineExe:resetImp()
  self.nWaitFrame = 0
end

return OpenMainLineExe
