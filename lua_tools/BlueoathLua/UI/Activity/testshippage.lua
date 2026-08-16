local TestShipPage = class("UI.Activity.TestShipPage", LuaUIPage)

function TestShipPage:DoOpen()
  local activities = Logic.activityLogic:GetOpenActivityByType(ActivityType.TestShip)
  if #activities <= 0 then
    logError("TestShip Activity not open")
    return
  end
  local widgets = self:GetWidgets()
  self.activityCfg = activities[1]
  local periodInfo = configManager.GetDataById("config_period", self.activityCfg.period)
  local startTime = PeriodManager:GetPeriodTime(self.activityCfg.period, self.activityCfg.period_area)
  local startTimeFormat = time.formatTimerToMDH(startTime)
  local endTimeFormat = time.formatTimerToMDH(startTime + periodInfo.duration)
  UIHelper.SetText(widgets.txt_period, string.format("%s~%s", startTimeFormat, endTimeFormat))
  UIHelper.SetLocText(widgets.txt_desc, 7200015)
  self:InitHeroList()
end

function TestShipPage:InitHeroList()
  local widgets = self:GetWidgets()
  local testShips = self.activityCfg.test_ship
  local buffs = self.activityCfg.test_buff_show
  local txtShows = self.activityCfg.test_show
  UIHelper.CreateSubPart(widgets.obj_heroitem, widgets.trans_herolist, #testShips, function(index, tabPart)
    local id = testShips[index]
    local shipShow = configManager.GetDataById("config_ship_show", id)
    local shipInfo = configManager.GetDataById("config_ship_info", id)
    UIHelper.SetText(tabPart.txt_name, shipInfo.ship_name)
    local buffDesc = buffs[index]
    UIHelper.SetText(tabPart.txt_buff, buffDesc)
    UIHelper.SetText(tabPart.txt_show, UIHelper.GetString(txtShows[index]))
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[shipInfo.quality])
    local icon = Logic.shipLogic:GetHeroSquareIcon(shipShow.ss_id)
    UIHelper.SetImage(tabPart.img_hero, icon)
  end)
  if Logic.redDotLogic.TestShip(self.activityCfg.id) then
    self:WriteOpenedFlag()
  end
end

function TestShipPage:WriteOpenedFlag()
  local startTime = PeriodManager:GetPeriodTime(self.activityCfg.period, self.activityCfg.period_area)
  local userId = Data.userData:GetUserUid()
  PlayerPrefs.SetString(string.format("tstshp%s%s", userId, startTime), "tstshp")
end

function TestShipPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_battle, self.OnBattle, self)
end

function TestShipPage:OnBattle()
  if moduleManager:CheckFunc(FunctionID.GoodsCopy, true) then
    UIHelper.OpenPage("GoodsCopyPage")
  end
end

return TestShipPage
