local PresetFleetPage = class("UI.PresetFleet.PresetFleetPage", LuaUIPage)
local PresetFleetItem = require("ui.page.PresetFleet.PresetFleetItem")

function PresetFleetPage:Doinit()
  self.first = nil
  self.m_presetFleetItems = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.openType = PresetFleetType.Fleet
end

function PresetFleetPage:DoOnOpen()
  self.param = self:GetParam()
  self.openType = self.param.presetFleetType == nil and PresetFleetType.Fleet or self.param.presetFleetType
  if self.openType ~= PresetFleetType.Match then
    fleetType = self.param.fleetType
    local dot = Logic.presetFleetLogic:PresetGetRedDot()
    if dot == 0 then
      Logic.presetFleetLogic:SetRedDot(1)
      Logic.presetFleetLogic:isSetModi()
      Logic.presetFleetLogic:SendPresetService()
    end
  end
  self:_Refresh()
end

function PresetFleetPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._ClosePresetFleetPage, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_background, self._ClosePresetFleetPage, self)
  self:RegisterEvent(LuaEvent.PresetFleetInfo, self._PresetFleetInfo, self)
  self:RegisterEvent(LuaEvent.PRESET_SelectHero, self._OnSelectHeros, self)
  self:RegisterEvent(LuaEvent.PresetGoBattle, self._ClosePresetFleetPage, self)
  self:RegisterEvent(LuaEvent.ChangeFleetNameError, self.PresetChangeNameError, self)
end

function PresetFleetPage:_ClosePresetFleetPage()
  Logic.presetFleetLogic:SendPresetService()
  local isClose = Logic.presetFleetLogic:GetCorr()
  local isSendMsg = Logic.presetFleetLogic:GetSetModi()
  if isSendMsg == false then
    UIHelper.ClosePage("PresetFleetPage")
  elseif isClose then
    UIHelper.ClosePage("PresetFleetPage")
  end
end

function PresetFleetPage:_ClosePage()
  UIHelper.ClosePage("PresetFleetPage")
end

function PresetFleetPage:_PresetFleetInfo()
  self:_Refresh()
end

function PresetFleetPage:_OnSelectHeros()
  self:_Refresh()
end

function PresetFleetPage:_Refresh()
  local data = Logic.presetFleetLogic:GetData()
  data = Logic.presetFleetLogic:SortPresetData(data)
  self:_ShowPresetFleets(data)
  self:_ShowButton()
end

function PresetFleetPage:_ShowButton()
  local widgets = self:GetWidgets()
  widgets.btn_close.gameObject:SetActive(true)
end

function PresetFleetPage:_ShowPresetFleets(data)
  local widgets = self:GetWidgets()
  local presetfleetslist = data
  if data == nil then
    presetfleetslist = Logic.presetFleetLogic:GetData()
  end
  self.m_presetFleetItems = self.m_presetFleetItems or {}
  local fleetNum, nextLevel = Logic.presetFleetLogic:GetNextOpenLevel()
  UIHelper.SetInfiniteItemParam(widgets.iil_obj_fleet, widgets.item_Fleet, fleetNum, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local tabPart = part
      local presetData = presetfleetslist[index]
      if self.m_presetFleetItems[index] then
        self.m_presetFleetItems[index]:SetData(presetData, tabPart, index)
        self.m_presetFleetItems[index]:ShowItem()
      else
        local presetItem = PresetFleetItem:new()
        presetItem:Init(self, tabPart, presetData, index, self.param, false, widgets)
        self.m_presetFleetItems[index] = presetItem
      end
    end
  end)
end

function PresetFleetPage:PresetChangeNameError(err)
  if err == 1010 then
    noticeManager:ShowTip(UIHelper.GetString(1900011))
  elseif err == 1005 then
    noticeManager:ShowTip(UIHelper.GetString(1900012))
  end
end

function PresetFleetPage:DoOnClose()
  if self.openType == PresetFleetType.Fleet then
    Logic.fleetLogic:SetSelectTog(self.param.index)
  end
end

return PresetFleetPage
