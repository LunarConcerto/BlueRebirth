local BathFinishTrigger = class("game.guide.guideTrigger.BathFinishTrigger", GR.requires.GuideTriggerBase)

function BathFinishTrigger:initialize(nType)
  self.type = nType
end

function BathFinishTrigger:tick()
  local finish = Logic.repaireLogic:GetButhFinish()
  if finish then
    self:sendTrigger()
  end
end

return BathFinishTrigger
