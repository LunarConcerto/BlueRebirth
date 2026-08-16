local AssistNewPage = class("UI.AssistFleet.AssistNewPage", LuaUIPage)
local AssistItem = require("ui.page.AssistFleet.AssistItem")
local CLSY_AssistNewItemYBase = 175

function AssistNewPage:DoInit()
  self.m_assistItems = {}
end

function AssistNewPage:DoOnOpen()
  self:OpenTopPage("AssistNewPage", 1, "\230\148\175\230\143\180", self, true)
  self:_Refresh()
end

function AssistNewPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.obj_startTip, self._CloseStartTip, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self.ShowDetail, self, false)
  UGUIEventListener.AddButtonOnClick(widgets.btn_help, self._ShowHelp, self)
  self:RegisterEvent(LuaEvent.SelectAssistCommand, self._OnSelectCommand, self)
  self:RegisterEvent(LuaEvent.CompleteCrusade, self._OpenReward, self)
  self:RegisterEvent(LuaEvent.StartSupport, self._OnStartAssist)
  self:RegisterEvent(LuaEvent.UpdateAssistList, self._Refresh, self)
  self:RegisterEvent(LuaEvent.CancelCrusade, self._OnCancelAssist, self)
  self:RegisterEvent(LuaEvent.SupportAgain, self._OnSupportAgain, self)
end

function AssistNewPage:_OnSelectCommand(data)
  self:_Refresh(data)
  self:ShowDetail(nil, true)
end

function AssistNewPage:_OnCancelAssist()
  self:ShowDetail(nil, false)
  self:_Refresh()
end

function AssistNewPage:_OnSupportAgain(data)
  local index = Logic.assistNewLogic:GetAssistContext().CurIndex
  self.m_assistItems[index]:SetIsOn(true)
  self:_Refresh(data)
  self:ShowDetail(nil, true)
end

function AssistNewPage:_OpenReward(ret)
  local param = Logic.assistNewLogic:FormatFinishArgs(ret)
  Logic.assistNewLogic:ResetAssistDataById(ret.Id)
  local index = Logic.assistNewLogic:GetAssistContext().CurIndex
  self.m_assistItems[index]:SetIsOn(false)
  UIHelper.OpenPage("CrusadeSuccessPage", param, 1, false)
end

function AssistNewPage:_Refresh(data)
  self:_ShowFleetNum()
  self:_ShowAssistList(data)
end

function AssistNewPage:_ShowFleetNum()
  local total = Logic.assistNewLogic:GetTotalFleetNum()
  local cur = Logic.assistNewLogic:GetCurFleetNum()
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.tx_total, "(   /" .. total .. ")")
  UIHelper.SetText(widgets.tx_cur, cur)
end

function AssistNewPage:_ShowAssistList(data)
  local widgets = self:GetWidgets()
  local assistlist = data
  if data == nil then
    assistlist = Logic.assistNewLogic:GetAssistData()
  end
  self:SetDrag(true)
  local mask = false
  self.m_assistItems = self.m_assistItems or {}
  UIHelper.CreateSubPart(widgets.obj_assist, widgets.trans_assist, #assistlist, function(index, tabPart)
    local assistData = assistlist[index]
    if self.m_assistItems[index] then
      self.m_assistItems[index]:SetData(assistData)
      self.m_assistItems[index]:ShowItem()
    else
      local assistItem = AssistItem:new()
      assistItem:Init(self, tabPart, assistData, index)
      self.m_assistItems[index] = assistItem
    end
    if self.m_assistItems[index].m_isOn then
      self:SetDrag(false)
      mask = true
    end
  end)
  self:_SetMask(false)
  local detail = Logic.assistNewLogic:GetAssistContext().ShowDetail
  if detail then
    self:ShowDetail()
    Logic.assistNewLogic:SetShowDetail(false)
  end
end

function AssistNewPage:_OnStartAssist()
  self:_SetMask(false)
  self:_ShowStartTip()
end

function AssistNewPage:_ShowStartTip()
  local widgets = self:GetWidgets()
  widgets.obj_startTip:SetActive(true)
  local canCloseDur = Logic.assistNewLogic:GetStartTipCloseTime()
  local showDur = Logic.assistNewLogic:GetStartTipShowTime()
  self.startTipLock = true
  local startTimer = self:CreateTimer(function()
    self.startTipLock = false
    self:StopTimer(startTimer)
  end, canCloseDur, 1, false)
  self:StartTimer(startTimer)
  local closeTimer = self:CreateTimer(function()
    widgets.obj_startTip:SetActive(false)
    self.startTipLock = false
    self:StopTimer(closeTimer)
  end, canCloseDur, 1, false)
  self:StartTimer(closeTimer)
end

function AssistNewPage:_CloseStartTip()
  if not self.startTipLock then
    local widgets = self:GetWidgets()
    widgets.obj_startTip:SetActive(false)
  end
end

function AssistNewPage:ShowCommands(go, param)
  if Logic.assistNewLogic:CheckAssistFleetNum() then
    noticeManager:ShowTip(UIHelper.GetString(971009))
    return
  end
  local commands = Logic.assistNewLogic:GetUserCommandWithOutUsing()
  if #commands == 0 then
    local tabParam = {
      msgType = 2,
      callback = function(bool)
        if bool then
          UIHelper.OpenPage("ShopPage", {
            shopId = ShopId.Normal
          })
        end
      end,
      nameOk = "\232\180\173\228\185\176"
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(971040), tabParam)
    return
  end
  local data = Logic.assistNewLogic:ResetAllTODOAssist()
  if data then
    self:_Refresh(data)
  end
  UIHelper.OpenPage("AssistCommand", param)
end

function AssistNewPage:_OnClickHero(go, param)
  local state = Logic.assistNewLogic:GetAssistState(param.SupportId, param.StartTime)
  if state ~= AssistFleetState.TODO then
    return
  end
  local tid = param.SupportId
  local checkType, types = Logic.assistNewLogic:CheckFixTypeLimit(tid)
  local checkFix, tids = Logic.assistNewLogic:CheckFixShipLimit(tid)
  local tabShowHero = Logic.dockLogic:FilterShipList(DockListType.All)
  if checkType then
    tabShowHero = Logic.dockLogic:FilterByType(tabShowHero, types)
  end
  if checkFix then
    tabShowHero = Logic.dockLogic:FilterByTids(tabShowHero, tids)
  end
  checkType, types = Logic.assistNewLogic:CheckFixTypeRmd(tid)
  checkFix, tids = Logic.assistNewLogic:CheckFixShipRmd(tid)
  local max = Logic.assistNewLogic:SupportShipUp(tid)
  UIHelper.OpenPage("CommonSelectPage", {
    CommonHeroItem.Assist,
    tabShowHero,
    {
      m_selectMax = max,
      m_selectedIdList = param.HeroList,
      m_tids = tids,
      m_type = types
    }
  })
end

function AssistNewPage:SetDrag(isOn)
  local widgets = self:GetWidgets()
  widgets.sv_assistlist.enabled = isOn
end

function AssistNewPage:ShowDetail(go, isOn)
  local index = Logic.assistNewLogic:GetAssistContext().CurIndex
  for i, item in ipairs(self.m_assistItems) do
    if i ~= index and item.m_isOn then
      item:_ShowDetail(false)
    end
  end
  if self.m_assistItems[index] == nil then
    return
  end
  if isOn == nil then
    isOn = self.m_assistItems[index]:CheckShowDetail()
  end
  self.m_assistItems[index]:_ShowDetail(isOn)
  self:SetDrag(not isOn)
  if isOn then
    local widgets = self:GetWidgets()
    local curPos = widgets.trans_assist.localPosition
    curPos.y = (index - 1) * CLSY_AssistNewItemYBase
    widgets.trans_assist.localPosition = curPos
  end
  local total = Logic.assistNewLogic:GetTotalFleetNum()
  if total == index and isOn then
    self:_SetMask(false)
    return
  end
  self:_SetMask(isOn)
end

function AssistNewPage:TryCloseDetail()
  for i, item in ipairs(self.m_assistItems) do
    if item.m_isOn then
      item:_ShowDetail(false)
    end
  end
  self:SetDrag(true)
  self:_SetMask(false)
end

function AssistNewPage:_SetMask(enable)
  local widgets = self:GetWidgets()
  widgets.obj_detailmask:SetActive(enable)
end

function AssistNewPage:_ShowHelp()
  UIHelper.OpenPage("HelpPage", {
    content = UIHelper.GetString(971041)
  })
end

function AssistNewPage:_ForceUpdateAssistLayout()
  local widgets = self:GetWidgets()
  LayoutRebuilder.ForceRebuildLayoutImmediate(widgets.trans_assist)
end

function AssistNewPage:DoOnHide()
end

function AssistNewPage:DoOnClose()
  for i, v in ipairs(self.m_assistItems) do
    v:Dispose()
  end
  Logic.assistNewLogic:ResetLogicData()
end

return AssistNewPage
