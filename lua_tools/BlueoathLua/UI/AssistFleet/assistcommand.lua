local AssistCommand = class("UI.AssistFleet.AssistCommand", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function AssistCommand:DoInit()
  self.m_curCommand = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function AssistCommand:DoOnOpen()
  self:_ShowCommands()
end

function AssistCommand:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_use, self._UseCommand, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._ClosePage, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_close, self._ClosePage, self)
  self:RegisterEvent(LuaCSharpEvent.LoseFocus, function(self, param)
    self:_ResetUI()
  end)
end

function AssistCommand:_SwitchTogs(index, param)
  local id = param[index + 1].templateId
  self:_ShowCommandConfig(id)
end

function AssistCommand:_ResetUI()
  local widgets = self:GetWidgets()
  widgets.sv_itemlist.verticalNormalizedPosition = 1
end

function AssistCommand:_ShowCommands()
  local widgets = self:GetWidgets()
  self.m_assist = self:GetParam()
  local commands = Logic.assistNewLogic:GetUserCommandWithOutUsing()
  widgets.obj_property:SetActive(#commands ~= 0)
  if #commands == 0 then
    noticeManager:ShowTip("\230\178\161\230\156\137\230\148\175\230\143\180\228\187\164")
    return
  end
  UIHelper.CreateSubPart(widgets.obj_command, widgets.trans_command, #commands, function(index, tabParts)
    local config = Logic.assistNewLogic:GetCommandConfigById(commands[index].templateId)
    UIHelper.SetImage(tabParts.img_frame, QualityIcon[config.quality])
    UIHelper.SetImage(tabParts.img_icon, config.icon)
    UIHelper.SetText(tabParts.txt_num, "x" .. Mathf.ToInt(commands[index].num))
    widgets.toggroup:RegisterToggle(tabParts.tog_command)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.toggroup, self, commands, self._SwitchTogs)
  widgets.toggroup:SetActiveToggleIndex(0)
end

function AssistCommand:_ShowCommandConfig(id)
  self.m_curCommand = id
  self:_ShowBaseInfo(id)
  self:_ShowTeamLimit(id)
  self:_ShowTeamRmd(id)
  self:_ShowBaseReward(id)
  self:_ShowExtraReward(id)
end

function AssistCommand:_ShowBaseInfo(id)
  local widgets = self:GetWidgets()
  local config = Logic.assistNewLogic:GetCommandConfigById(id)
  UIHelper.SetText(widgets.tx_name, config.name)
  UIHelper.SetText(widgets.tx_time, UIHelper.GetCountDownStr(config.time))
end

function AssistCommand:_ShowTeamLimit(id)
  local widgets = self:GetWidgets()
  local limit = Logic.assistNewLogic:CheckAssistTeamLimit({}, id)
  widgets.trans_teamlimit.gameObject:SetActive(0 < #limit)
  UIHelper.CreateSubPart(widgets.obj_teamlimit, widgets.trans_teamlimit, #limit, function(index, tabPart)
    local v = limit[index]
    UIHelper.SetText(tabPart.tx_item, v.des)
  end)
end

function AssistCommand:_ShowTeamRmd(id)
  local widgets = self:GetWidgets()
  local info = Logic.assistNewLogic:CheckAssistTeamRmd({}, id)
  widgets.trans_teamrmd.gameObject:SetActive(0 < #info)
  UIHelper.CreateSubPart(widgets.obj_teamrmd, widgets.trans_teamrmd, #info, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_item, info[index].des)
  end)
end

function AssistCommand:_ShowBaseReward(id)
  local widgets = self:GetWidgets()
  local base = Logic.assistNewLogic:GetBaseReward(id)
  self:_ShowReward(base, widgets.obj_reward, widgets.trans_reward)
end

function AssistCommand:_ShowExtraReward(id)
  local widgets = self:GetWidgets()
  local extra = Logic.assistNewLogic:GetExtraReward(id)
  self:_ShowReward(extra, widgets.obj_extra, widgets.trans_extra)
end

function AssistCommand:_ShowReward(info, go, trans)
  UIHelper.CreateSubPart(go, trans, #info, function(index, tabParts)
    local item = CommonRewardItem:new()
    item:Init(index, info[index], tabParts)
    UGUIEventListener.AddButtonOnClick(tabParts.item, self._ShowItemInfo, self, info[index])
  end)
end

function AssistCommand:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function AssistCommand:_UseCommand(go)
  if self.m_curCommand ~= nil then
    local assist = Logic.assistNewLogic.GenAssistTemplate()
    assist.SupportId = self.m_curCommand
    local index = Logic.assistNewLogic:GetAssistContext().CurIndex
    local data = Logic.assistNewLogic:SetAssistByIndex(index, assist)
    eventManager:SendEvent(LuaEvent.SelectAssistCommand, data)
    local dotinfo = {
      info = "ui_supfleet_add",
      support_fleet_itemID = self.m_curCommand
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    self:_ClosePage()
  else
    logError("\232\175\183\233\128\137\230\139\169\230\148\175\230\143\180\228\187\164!!!")
  end
end

function AssistCommand:_ClosePage()
  UIHelper.ClosePage("AssistCommand")
end

function AssistCommand:DoOnHide()
end

function AssistCommand:DoOnClose()
  self.m_tabWidgets.toggroup:ClearToggles()
end

return AssistCommand
