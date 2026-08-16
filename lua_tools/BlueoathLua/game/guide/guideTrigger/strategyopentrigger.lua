local StrategyOpenTrigger = class("game.guide.guideTrigger.StrategyOpenTrigger", GR.requires.GuideTriggerBase)

function StrategyOpenTrigger:initialize(nType)
  self.type = nType
  self.nTarget = FunctionID.Strategy
end

function StrategyOpenTrigger:tick()
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
  self:sendTrigger()
end

return StrategyOpenTrigger
