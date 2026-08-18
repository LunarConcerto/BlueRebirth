local FirstPlayNVNTrigger = class("game.guide.guideTrigger.FirstPlayNVNTrigger", GR.requires.GuideTriggerBase)

function FirstPlayNVNTrigger:initialize(nType)
  self.type = nType
end

function FirstPlayNVNTrigger:tick()
  if UIHelper.IsPageOpen("LevelDetailsPage") then
    local copyId = Logic.copyLogic:GetCurCopyId()
    local displayData = configManager.GetDataById("config_copy_display", copyId)
    if displayData.max_fleet > 0 then
      self:sendTrigger()
    end
  end
end

return FirstPlayNVNTrigger
