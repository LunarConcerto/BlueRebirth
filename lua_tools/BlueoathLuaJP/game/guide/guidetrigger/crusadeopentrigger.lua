local CrusadeOpenTrigger = class("game.guide.guideTrigger.CrusadeOpenTrigger", GR.requires.GuideTriggerBase)

function CrusadeOpenTrigger:initialize(nType)
  self.type = nType
  self.nTarget = FunctionID.Crusade
end

function CrusadeOpenTrigger:tick()
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

return CrusadeOpenTrigger
