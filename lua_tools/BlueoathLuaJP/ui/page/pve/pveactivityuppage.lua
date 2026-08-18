local PveActivityUpPage = class("UI.Pve.PveActivityUpPage", LuaUIPage)

function PveActivityUpPage:DoInit()
end

function PveActivityUpPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
end

function PveActivityUpPage:DoOnOpen()
  local curActId = Logic.activityLogic:GetActivityIdByType(ActivityType.ActDropUpCard)
  self.actConfig = configManager.GetDataById("config_activity", curActId)
  local _, endTime = PeriodManager:GetPeriodTime(self.actConfig.period, self.actConfig.period_area)
  local actTime = time.formatTimeToYMDHMS(endTime)
  UIHelper.SetText(self.tab_Widgets.txt_actTime, actTime)
  self:_CreateHeroList()
end

function PveActivityUpPage:_CreateHeroList()
  local heroTab = self.actConfig.p1
  local dropUpTab = self.actConfig.p2
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_team, #heroTab, function(index, part)
    local shipInfo = Logic.shipLogic:GetShipInfoBySiId(heroTab[index])
    local showInfo = Logic.shipLogic:GetDefaultShipShowByInfoId(heroTab[index])
    UIHelper.SetImage(part.im_quality, HorizontalCardQulity[shipInfo.quality])
    UIHelper.SetImage(part.im_headIcon, tostring(showInfo.ship_icon5))
    UIHelper.SetText(part.tx_up, dropUpTab[index])
  end, self)
end

function PveActivityUpPage:_ClickClose()
  UIHelper.ClosePage("PveActivityUpPage")
end

return PveActivityUpPage
