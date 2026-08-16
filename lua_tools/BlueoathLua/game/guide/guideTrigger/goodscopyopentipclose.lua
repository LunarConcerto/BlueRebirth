local GoodsCopyOpenTipClose = class("game.guide.guideTrigger.GoodsCopyOpenTipClose", GR.requires.GuideTriggerBase)

function GoodsCopyOpenTipClose:initialize(nType)
  self.type = nType
  self.nTarget = FunctionID.GoodsCopy
end

function GoodsCopyOpenTipClose:tick()
  local bIsOpen = moduleManager:CheckFunc(self.nTarget, false)
  if not bIsOpen then
    return
  end
  if not UIHelper.IsPageOpen("HomePage") then
    return
  end
  for k, v in pairs(ModuleOpenExculdePages) do
    if UIHelper.IsPageOpen(v) then
      return
    end
  end
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if not isHasFleet then
    return
  end
  self:sendTrigger()
end

return GoodsCopyOpenTipClose
