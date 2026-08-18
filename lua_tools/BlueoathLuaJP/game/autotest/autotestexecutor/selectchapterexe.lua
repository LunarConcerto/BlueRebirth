local SelectChapterExe = class("game.AutoTest.AutoTestExecutor.SelectChapterExe", GR.requires.Executor)

function SelectChapterExe:init(param)
  self.strName = "SelectChapterExe"
  self.nChapterId = param[1]
  self.nBaseId = param[2]
  self.nTargetFrame = 20
  self.nWaitFrame = 0
  self.bClickChapter = false
  self.bClickSeaCopy = false
end

function SelectChapterExe:tick()
  if not self.bClickSeaCopy and UIPageManager:IsExistPage("CopyPage") then
    local bClick = GR.autoTestManager:clickToggle("MainRoot/CopyPage/Bottom/button/Viewport/Content/Btn_haiyu")
    if bClick then
      self.bClickSeaCopy = true
    end
  end
  if self.bClickSeaCopy then
    if self.nWaitFrame < self.nTargetFrame then
      self.nWaitFrame = self.nWaitFrame + 1
    else
      local bClick = GR.autoTestManager:clickBtn("MainRoot/SeaCopyPage/Middle/obj_rightMainLine/LevelSelect/Viewport/Content/1/bu_one")
      if bClick then
        self:stop()
      end
    end
  end
end

function SelectChapterExe:resetImp()
  self.bClickChapter = false
  self.nWaitFrame = 0
end

return SelectChapterExe
