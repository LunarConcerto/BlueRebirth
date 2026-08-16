BeStrongPage = class("UI.Settlement.BeStrongPage", LuaUIPage)
local pageIndexMap = {
  GirlShowPage = 1,
  Strengthen_Page = 2,
  Break_Page = 3,
  Equipment_Page = 4
}

function BeStrongPage:DoInit()
end

function BeStrongPage:DoOnOpen()
  local playerLevel = Data.userData:GetUserLevel()
  local strongCfg = configManager.GetData("config_bestrong")
  local maxOpenLevel = -1
  local openCfg
  for i, cfg in ipairs(strongCfg) do
    if maxOpenLevel < cfg.openlevel and playerLevel >= cfg.openlevel then
      maxOpenLevel = cfg.openlevel
      openCfg = {}
    end
    if cfg.openlevel == maxOpenLevel then
      table.insert(openCfg, cfg)
    end
  end
  local param = self.param
  UIHelper.CreateSubPart(self.tab_Widgets.template, self.tab_Widgets.listContent, #openCfg, function(nIndex, tabPart)
    local cfg = openCfg[nIndex]
    UIHelper.SetText(tabPart.name, cfg.title)
    UIHelper.SetImage(tabPart.icon, cfg.icon)
    UGUIEventListener.AddButtonOnClick(tabPart.button, function()
      param.onClose()
      self:Goto(cfg)
    end, self)
  end)
end

function BeStrongPage:Goto(cfg)
  UIHelper.ClosePage("BeStrongPage")
  local fleetType = self.param.fleetType
  local fleetId = Logic.fleetLogic:GetBattleFleetId(fleetType)
  local shipIds = Data.fleetData:GetShipByFleet(fleetId, fleetType)
  self:AddRetention(cfg.id)
  if cfg.gotomotoid == "Strengthen_Page" or cfg.gotomotoid == "Equipment_Page" or cfg.gotomotoid == "Break_Page" or cfg.gotomotoid == "GirlShowPage" then
    local minPowerShipId = shipIds[1]
    local minPower = Logic.attrLogic:GetBattlePower(minPowerShipId, fleetType)
    local count = #shipIds
    if 1 < count then
      for i = 2, count do
        local id = shipIds[i]
        local power = Logic.attrLogic:GetBattlePower(id, fleetType)
        if minPower > power then
          minPowerShipId = id
          minPower = power
        end
      end
    end
    Logic.girlInfoLogic:SetLastTogIndex(pageIndexMap[cfg.gotomotoid])
    Logic.beStrongLogic:SetStrongPageData({
      name = "GirlInfo",
      param = {
        minPowerShipId,
        shipIds,
        fleetType = fleetType
      }
    })
  elseif cfg.gotomotoid == "BuildShipPage" then
    Logic.beStrongLogic:SetStrongPageData({
      callback = function()
        UIHelper.OpenPage("HomePage")
        eventManager:SendEvent(LuaEvent.HomePageOtherPageOpen, 2)
        UIHelper.OpenPage("BuildShipPage")
      end
    })
  else
    Logic.beStrongLogic:SetStrongPageData({
      name = cfg.gotomotoid
    })
  end
end

function BeStrongPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.OnBtnCloseClick, self)
end

function BeStrongPage:OnBtnCloseClick()
  self:AddRetention(0)
  local param = self.param
  UIHelper.ClosePage("BeStrongPage")
  param.onClose()
end

function BeStrongPage:AddRetention(type)
  local dotInfo = {
    info = "ui_fail_goto",
    type = type
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

function BeStrongPage:DoOnClose()
end

return BeStrongPage
