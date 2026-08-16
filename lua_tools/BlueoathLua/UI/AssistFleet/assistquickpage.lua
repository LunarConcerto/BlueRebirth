local AssistQuickpage = class("UI.AssistFleet.AssistQuickpage", LuaUIPage)
local CommonItem = require("ui.page.CommonItem")

function AssistQuickpage:DoInit()
  self.m_timers = {}
end

function AssistQuickpage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._ClsoeSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._ClsoeSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_oil, self._ReceiveOil, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_gold, self._ReceiveGold, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_oilLock, self._LockTip, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_goldLock, self._LockTip, self)
  self:RegisterEvent(LuaEvent.UpdateAssistList, self._Refresh, self)
  self:RegisterEvent(LuaEvent.CompleteCrusade, self._OpenReward, self)
  self:RegisterEvent(LuaEvent.SupportAgain, self._OnSupportAgain, self)
  self:RegisterEvent(LuaEvent.BuildingRefreshData, self.DoResourceTick, self)
  self:RegisterEvent(LuaEvent.BuildingReceiveResult, self._OnReceiveResult, self)
end

function AssistQuickpage:_SetTween()
  local widgets = self:GetWidgets()
  widgets.twnp_bg:AddOnFinished(function()
    local reserve = self:_getTweenReserve()
    if reserve then
      UIHelper.ClosePage("AssistQuickpage")
      self:_setTweenReserve(false)
    end
  end)
end

function AssistQuickpage:DoOnOpen()
  self:_Refresh()
  self:StartResourceTimer()
  self:_ShowResourceLv()
end

function AssistQuickpage:_Refresh()
  self:_ShowAssistList()
end

function AssistQuickpage:_OnSupportAgain(ret)
  self:_ClsoeSelf()
  Logic.assistNewLogic:SetShowDetail(true)
  UIHelper.OpenPage("AssistNewPage")
end

function AssistQuickpage:_OpenReward(ret)
  local param = Logic.assistNewLogic:FormatFinishArgs(ret)
  Logic.assistNewLogic:ResetAssistDataById(ret.Id)
  UIHelper.OpenPage("CrusadeSuccessPage", param, 1, false)
  self:_Refresh()
end

function AssistQuickpage:_ShowAssistList()
  local widgets = self:GetWidgets()
  local assistlist = Logic.assistNewLogic:RefreshGetAssistData()
  self:_StopTimers()
  UIHelper.CreateSubPart(widgets.obj_assist, widgets.trans_assist, #assistlist, function(index, tabPart)
    local assist = assistlist[index]
    local have = assist.SupportId > 0
    tabPart.obj_extra:SetActive(have)
    tabPart.obj_waikuang:SetActive(have)
    tabPart.obj_waikuang_xiao:SetActive(not have)
    if have then
      local reward = Logic.assistNewLogic:FormatSupportById(assist.SupportId)
      local item = CommonItem:new()
      item:Init(index, reward, tabPart)
    else
      UIHelper.SetText(tabPart.txt_name, "\231\169\186\233\151\178\228\184\173...")
    end
    local state = Logic.assistNewLogic:GetAssistState(assist.SupportId, assist.StartTime)
    tabPart.obj_time:SetActive(state == AssistFleetState.DOING)
    if state == AssistFleetState.DOING then
      local duration = Logic.assistNewLogic:GetAssistRemainTime(assist.SupportId, assist.StartTime)
      UIHelper.SetText(tabPart.tx_time, UIHelper.GetCountDownStr(duration))
      local timer = self:CreateTimer(function()
        self:_TickAssist(tabPart.tx_time, assist)
      end, 1, -1, false)
      table.insert(self.m_timers, timer)
      self:StartTimer(timer)
    end
    tabPart.obj_di_yellow:SetActive(state == AssistFleetState.FINISH)
    tabPart.obj_di_blue:SetActive(state == AssistFleetState.DOING)
    tabPart.btn_goto.gameObject:SetActive(state == AssistFleetState.TODO)
    tabPart.btn_fast.gameObject:SetActive(state == AssistFleetState.DOING)
    tabPart.btn_get.gameObject:SetActive(state == AssistFleetState.FINISH)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_goto, self._OnGotoAssist, self, {data = assist, index = index})
    UGUIEventListener.AddButtonOnClick(tabPart.btn_fast, self._OnFastFinish, self, {data = assist, index = index})
    UGUIEventListener.AddButtonOnClick(tabPart.btn_get, self._OnFinishAssist, self, {data = assist, index = index})
    self:RegisterRedDotById(tabPart.reddot, {27})
  end)
end

function AssistQuickpage:_StopTimers()
  self:StopAllTimer()
  self.m_timers = {}
end

function AssistQuickpage:_TickAssist(tx_time, data)
  local duration = Logic.assistNewLogic:GetAssistRemainTime(data.SupportId, data.StartTime)
  UIHelper.SetText(tx_time, UIHelper.GetCountDownStr(duration))
  if duration <= 0 then
    self:_Refresh()
  end
end

function AssistQuickpage:StartResourceTimer()
  self:StopResourceTimer()
  self.resourceTimer = self:CreateTimer(function()
    self:DoResourceTick()
  end, 1, -1, false)
  self:DoResourceTick()
end

function AssistQuickpage:DoResourceTick()
  local widgets = self:GetWidgets()
  local gold, idling1 = Logic.buildingLogic:GetResourceCount(CurrencyType.GOLD)
  UIHelper.SetText(widgets.tx_gold, gold)
  local oil, idling2 = Logic.buildingLogic:GetResourceCount(CurrencyType.SUPPLY)
  UIHelper.SetText(widgets.tx_oil, oil)
  if idling1 and idling2 then
    self:StopResourceTimer()
  end
end

function AssistQuickpage:StopResourceTimer()
  if self.resourceTimer then
    self:StopTimer(self.resourceTimer)
    self.resourceTimer = nil
  end
end

function AssistQuickpage:_ReceiveOil()
  local _, errMsg = Logic.buildingLogic:CheckResourceLimit(CurrencyType.SUPPLY)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  local oil = Logic.buildingLogic:GetResourceCount(CurrencyType.SUPPLY)
  if 0 < oil then
    Service.buildingService:ReceiveResource(CurrencyType.SUPPLY)
  end
end

function AssistQuickpage:_ReceiveGold()
  local _, errMsg = Logic.buildingLogic:CheckResourceLimit(CurrencyType.GOLD)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  local gold = Logic.buildingLogic:GetResourceCount(CurrencyType.GOLD)
  if 0 < gold then
    Service.buildingService:ReceiveResource(CurrencyType.GOLD)
  end
end

function AssistQuickpage:_OnFinishAssist(go, param)
  Logic.assistNewLogic:SetCurIndex(param.index)
  local ok, msg = Logic.assistNewLogic:CheckNormalFinish(param.data)
  if not ok then
    logError(msg)
    return
  end
  Logic.assistNewLogic:SetLastFinish(param.data)
  Service.assistNewService:SendAssistFinish(param.data.Id, AssistCompleteType.NORMAL)
end

function AssistQuickpage:_OnFastFinish(go, param)
  Logic.assistNewLogic:SetCurIndex(param.index)
  local ok, msg = Logic.assistNewLogic:CheckFastFinishRPC(param.data)
  if not ok then
    logError(msg)
    return
  end
  UIHelper.OpenPage("AssistFastTip", param.data)
end

function AssistQuickpage:_OnGotoAssist(go, param)
  Logic.assistNewLogic:SetCurIndex(param.index)
  self:_ClsoeSelf()
  if not moduleManager:CheckFunc(FunctionID.SupportFleet, true) then
    return
  end
  UIHelper.OpenPage("AssistNewPage")
end

function AssistQuickpage:_ClsoeSelf()
  local widgets = self:GetWidgets()
  self:_SetTween()
  self:_setTweenReserve(true)
  widgets.twnp_bg:Play(false)
end

function AssistQuickpage:_setTweenReserve(isOn)
  self.m_tweenR = isOn
end

function AssistQuickpage:_getTweenReserve()
  return self.m_tweenR or false
end

function AssistQuickpage:_ShowResourceLv()
  local widgets = self:GetWidgets()
  widgets.oilLock:SetActive(true)
  widgets.goldLock:SetActive(true)
  widgets.tx_oilLv.text = "Lv." .. 0
  widgets.tx_goldLv.text = "Lv." .. 0
  local cfg
  local buildingData = Data.buildingData:GetBuildingData()
  local bIsOpen = moduleManager:CheckFunc(FunctionID.Building, false)
  for k, v in pairs(buildingData) do
    cfg = configManager.GetDataById("config_buildinginfo", v.Tid)
    if cfg.type == MBuildingType.OilFactory and bIsOpen then
      widgets.oilLock:SetActive(false)
      widgets.tx_oilLv.text = "Lv." .. cfg.level
    end
    if cfg.type == MBuildingType.ResourceFactory and bIsOpen then
      widgets.goldLock:SetActive(false)
      widgets.tx_goldLv.text = "Lv." .. cfg.level
    end
  end
end

function AssistQuickpage:_LockTip()
  noticeManager:ShowTip(UIHelper.GetString(3001001))
end

function AssistQuickpage:_OnReceiveResult(result)
  if result and result.ItemInfo and next(result.ItemInfo) ~= nil then
    Logic.rewardLogic:ShowCommonReward(result.ItemInfo, "AssistQuickpage")
  end
end

function AssistQuickpage:DoOnHide()
end

function AssistQuickpage:DoOnClose()
end

return AssistQuickpage
