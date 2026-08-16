local BathRoomOpenTrigger = class("game.guide.guideTrigger.BathRoomOpenTrigger", GR.requires.GuideTriggerBase)

function BathRoomOpenTrigger:initialize(nType)
  self.type = nType
  self.nTarget = FunctionID.BathRoom
end

function BathRoomOpenTrigger:tick()
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

return BathRoomOpenTrigger
