local ClickNewGirlPage = class("game.AutoTest.AutoTestExecutor.ClickNewGirlPage", GR.requires.Executor)

function ClickNewGirlPage:init()
  self.nWaitFrame = 0
  self.nTargetFrame = 5
  self.strName = "ClickNewGirlPage"
  self.bClickNewPage = false
end

function ClickNewGirlPage:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageSimpleBattle then
    return
  end
  if UIPageManager:IsExistPage("GetRewardsPage") then
    local bClick = GR.autoTestManager:clickBtn("MainRoot/GetRewardsPage/im_bg/tx_goon")
  end
  if UIPageManager:IsExistPage("ChaseTipPage") then
    local bClick = GR.autoTestManager:clickBtn("MainRoot/ChaseTipPage/im_bg")
  end
  if not self.bClickNewPage then
    if UIPageManager:IsExistPage("ShowGirlPage") then
      local bClick = GR.autoTestManager:clickBtn("MainRoot/ShowGirlPage/shipImage")
      if bClick then
        self.bClickNewPage = true
      end
    end
  elseif self.nWaitFrame >= self.nTargetFrame then
    if UIPageManager:IsExistPage("NoticePage") then
      GR.autoTestManager:clickBtn("MainRoot/NoticePage/im_bg/obj_btnfather/btn_ok")
    end
    self.bClickNewPage = false
    self.nWaitFrame = 0
  else
    self.nWaitFrame = self.nWaitFrame + 1
  end
end

function ClickNewGirlPage:resetImp()
  self.nWaitFrame = 0
  self.bClickNewPage = false
end

return ClickNewGirlPage
