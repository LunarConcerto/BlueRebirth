local BuildOpen = class("game.guide.guideTrigger.BuildOpen", GR.requires.GuideTriggerBase)

function BuildOpen:initialize(nType)
  self.type = nType
  self.nTarget = FunctionID.Building
end

function BuildOpen:tick()
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

return BuildOpen
