local TowerOpen = class("game.guide.guideTrigger.TowerOpen", GR.requires.GuideTriggerBase)

function TowerOpen:initialize(nType)
  self.type = nType
  self.nTarget = FunctionID.Tower
end

function TowerOpen:tick()
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

return TowerOpen
