local GuidePageController = class("Game.Guide.GuidePageController")

function GuidePageController:initialize()
  self.nInternal = 5
  self.objTimer = nil
  self.objPage = nil
end

function GuidePageController:onPageOpen(objPage)
  self.objPage = objPage
end

function GuidePageController:getGuidePage()
  return self.objPage
end

function GuidePageController:onStageStart()
  if self.objTimer ~= nil then
    self.objTimer:Stop()
  end
  if self.objPage == nil then
    UIHelper.OpenPage("GuidePage", nil, 2, false)
  end
  SoundManager.Instance:PreLoadSingle("CV_guide_CN_bank")
end

function GuidePageController:onStageDone()
  local funcCB = function()
    self:onTimerEnd()
  end
  if self.objTimer == nil then
    self.objTimer = Timer.New(funcCB, self.nInternal, 1)
  else
    self.objTimer:Reset(funcCB, self.nInternal, 1)
  end
  self.objTimer:Start()
end

function GuidePageController:onTimerEnd()
  self:closePage()
end

function GuidePageController:closePage()
  SoundManager.Instance:UnLoad("CV_guide_CN_bank")
  UIHelper.ClosePage("GuidePage")
  self.objPage = nil
end

return GuidePageController
