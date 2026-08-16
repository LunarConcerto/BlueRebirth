local AutoBattleSelectPage = class("UI.Copy.AutoBattleSelectPage", LuaUIPage)
local ImageInfo = {
  "uipic_ui_store_bu_jiahao",
  "uipic_ui_store_bu_jianhao"
}

function AutoBattleSelectPage:DoInit()
  self.sweepCopyTimes = 0
  self.m_maxSweepNum = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function AutoBattleSelectPage:DoOnOpen()
  self:OpenTopPage("AutoBattleSelectPage", 2, UIHelper.GetString(920000179), self, true)
  self.param = self:GetParam()
  self:InitParam(self.param)
end

function AutoBattleSelectPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.leftButton, self._ClickLeftBtn, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.rightButton, self._ClickRightBtn, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_true, self._ClickBeginSweep, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, self._ClickCancle, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeTip, self._ClickClose, self)
end

function AutoBattleSelectPage:DoOnClose()
end

function AutoBattleSelectPage:DoOnHide()
end

function AutoBattleSelectPage:_ClickClose()
  UIHelper.ClosePage("AutoBattleSelectPage")
end

function AutoBattleSelectPage:ShowMsg(ShowText)
  noticeManager:OpenTipPage(self, ShowText)
end

function AutoBattleSelectPage:_ClickBeginSweep()
  if not self:CheckSupply() then
    self:ShowMsg(string.format(UIHelper.GetString(960000021)))
    return
  end
  local info = Data.copyData:GetSweepCopyInfo()
  if info ~= nil and #info >= Data.copyData:GetMaxFleetNum() then
    self:ShowMsg(string.format(UIHelper.GetString(960000022)))
    return
  end
  local isSweeping = Logic.copyLogic:CurrentCopyIsSweeping(self.param.CopyId)
  if isSweeping then
    self:ShowMsg(string.format(UIHelper.GetString(960000023)))
    return
  end
  if self.param.IsActivityCopy then
    local activityConfig = configManager.GetMultiDataByKeyValue("config_activity", "audobattle_chapter", self.param.ChapterId)
    local openActivityId, activityPeriodId
    for i = 1, #activityConfig do
      if activityConfig[i].type == 29 and PeriodManager:IsInPeriod(activityConfig[i].period) then
        openActivityId = activityConfig[i].id
        activityPeriodId = activityConfig[i].period
      end
    end
    if activityPeriodId ~= nil then
      local _, activityEndTime = PeriodManager:GetStartAndEndPeriodTime(activityPeriodId)
      local count = tonumber(self.m_tabWidgets.sweepTimes_num.text)
      if activityEndTime < count * self.param.SweepCopyCostTime + time.getSvrTime() then
        self:ShowMsg(string.format(UIHelper.GetString(960000025)))
        return
      end
    end
  end
  local config = {
    fleetId = self.param.FleetId,
    copyId = self.param.CopyId,
    sweepCounts = tonumber(self.m_tabWidgets.sweepTimes_num.text)
  }
  config = dataChangeManager:LuaToPb(config, mopUp_pb.TMOPUPARG)
  Service.copyService:StartSweepCopy(config)
  self:_ClickClose()
end

function AutoBattleSelectPage:CheckSupply()
  local supply = Data.userData:GetCurrency(CurrencyType.SUPPLY)
  if supply >= tonumber(self.m_tabWidgets.supply_num.text) then
    return true
  end
  return false
end

function AutoBattleSelectPage:_ClickCancle()
  UIHelper.ClosePage("AutoBattleSelectPage")
end

function AutoBattleSelectPage:_ClickLeftBtn()
  if self.sweepCopyTimes > 1 then
    self.sweepCopyTimes = self.sweepCopyTimes - 1
    self:SetSweepPara(self.sweepCopyTimes)
  end
end

function AutoBattleSelectPage:_ClickRightBtn()
  if self.m_maxSweepNum > self.sweepCopyTimes then
    self.sweepCopyTimes = self.sweepCopyTimes + 1
    self:SetSweepPara(self.sweepCopyTimes)
  end
end

function AutoBattleSelectPage:InitParam(params)
  self.sweepCopyTimes = params.SweepCopyTimes
  self.m_maxSweepNum = params.SweepCopyMaxTimes
  self:SetSweepPara(params.SweepCopyTimes)
end

function AutoBattleSelectPage:SetSweepPara(arg)
  self.m_tabWidgets.sweepTimes_num.text = arg
  self.m_tabWidgets.num.text = UIHelper.GetCountDownStr(self.param.SweepCopyCostTime * arg)
  self.m_tabWidgets.supply_num.text = self.param.SweepCopyCostSupply * arg
  self:SetBtnImage(arg)
end

function AutoBattleSelectPage:SetBtnImage(count)
  local imgRightPathInfo = count >= self.m_maxSweepNum and ImageInfo[2] or ImageInfo[1]
  UIHelper.SetImage(self.m_tabWidgets.img_rightButton, imgRightPathInfo)
  local imgLeftPathInfo = 1 < count and ImageInfo[1] or ImageInfo[2]
  UIHelper.SetImage(self.m_tabWidgets.img_leftButton, imgLeftPathInfo)
end

return AutoBattleSelectPage
