local NVNCopyHaveRandomFactorTrigger = class("game.guide.guideTrigger.NVNCopyHaveRandomFactorTrigger", GR.requires.GuideTriggerBase)

function NVNCopyHaveRandomFactorTrigger:initialize(nType)
  self.type = nType
end

function NVNCopyHaveRandomFactorTrigger:tick()
  if UIHelper.IsPageOpen("LevelDetailsPage") then
    local copyId = Logic.copyLogic:GetCurCopyId()
    local displayData = configManager.GetDataById("config_copy_display", copyId)
    if displayData.max_fleet > 0 then
      local nvnEnemyFleets = Logic.fleetOrderLogic:GetEnemyFleets(copyId)
      for i = 1, #nvnEnemyFleets do
        local fleetId = nvnEnemyFleets[i]
        local fleetData = configManager.GetDataById("config_fleet", fleetId)
        if 0 < #fleetData.random_factor then
          self:sendTrigger()
          return
        end
      end
    end
  end
end

return NVNCopyHaveRandomFactorTrigger
