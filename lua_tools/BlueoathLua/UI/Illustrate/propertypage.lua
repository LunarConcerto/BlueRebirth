local PropertyPage = class("UI.Illustrate.PropertyPage", LuaUIPage)
local open_state = {
  [false] = 0,
  [true] = 1
}
local ship_2d3d_state = {
  [false] = 1,
  [true] = 2
}

function PropertyPage:DoInit()
  self.m_tabWidgets = nil
  self.m_select = 1
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.ssId = 0
  self.m_selectContainer = {}
end

function PropertyPage:DoOnOpen()
  local ss_id = self:GetParam()
  self.ssId = ss_id
  self:_ShowProperty(ss_id)
end

function PropertyPage:_ShowProperty(ss_id)
  local iid = Logic.illustrateLogic:Ssid2Sfid(ss_id)
  self:_ShowBaseInfo(iid)
  self:_ShowTitle(ss_id)
  self:_ShowFashion(iid)
end

function PropertyPage:_ShowBaseInfo(illustrateId)
  local widgets = self:GetWidgets()
  local infoConfig = Data.illustrateData:GetIllustrateById(illustrateId)
  local cv = Logic.illustrateLogic:GetCvConfig(illustrateId)
  UIHelper.SetText(widgets.tx_name, cv)
  local countryConfig = configManager.GetDataById("config_country_info", infoConfig.shipCountry)
  UIHelper.SetText(widgets.tx_country, countryConfig.country_name)
end

function PropertyPage:_ShowTitle(ss_id)
  local widgets = self:GetWidgets()
  local illustrateId = Logic.illustrateLogic:Ssid2Sfid(ss_id)
  local subActionConfig = Logic.illustrateLogic:GetSubActions(ss_id)
  self:_ShowSubTitle(illustrateId, subActionConfig, widgets.obj_subaction, widgets.trans_subaction)
  local subtitleConfig = Logic.illustrateLogic:GetSubTitleIndex(ss_id)
  self:_ShowSubTitle(illustrateId, subtitleConfig, widgets.obj_subtitle, widgets.trans_subtitle)
end

function PropertyPage:_ShowSubTitle(illustrateId, subtitleConfig, obj, trans)
  local widgets = self:GetWidgets()
  local indexName = 1
  UIHelper.CreateSubPart(obj, trans, #subtitleConfig, function(index, tabPart)
    local config = Logic.illustrateLogic:GetSubTitleConfig(subtitleConfig[index])
    local unlock = Logic.illustrateLogic:IsUnLockBehaviour(illustrateId, config.behaviour_name)
    tabPart.obj_weidianji:SetActive(not unlock)
    tabPart.obj_dianji:SetActive(unlock)
    if config.special_name == "" then
      UIHelper.SetText(tabPart.tx_subtitle, config.ship_dialogue)
      UIHelper.SetText(tabPart.tx_subtitle_wei, config.ship_dialogue)
    else
      UIHelper.SetText(tabPart.tx_subtitle, config.special_name .. indexName)
      UIHelper.SetText(tabPart.tx_subtitle_wei, config.special_name .. indexName)
      indexName = indexName + 1
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_subtitle, function()
      local shipName = Data.illustrateData:GetIllustrateById(illustrateId).Name
      local dotinfo = {
        info = "ui_handbook_dialogue",
        ship_name = shipName,
        behavior_name = config.behaviour_name,
        open_state = open_state[unlock],
        type = ship_2d3d_state[Logic.illustrateLogic:GetIs3D()]
      }
      RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
      if not unlock then
        noticeManager:ShowTip(UIHelper.GetString(500000))
      else
        local param = {
          behName = config.behaviour_name,
          id = subtitleConfig[index]
        }
        eventManager:SendEvent(LuaEvent.PlayBehaviour, param)
      end
    end)
  end)
end

function PropertyPage:_ShowFashion(illustrateId)
  local widgets = self:GetWidgets()
  local sf_id = illustrateId
  local fashionDatas = Logic.fashionLogic:GetFashionConfigData(sf_id)
  self:_ResetSelectContainer()
  UIHelper.CreateSubPart(widgets.obj_dress, widgets.trans_dress, #fashionDatas, function(index, tabPart)
    local data = fashionDatas[index]
    local have = Logic.fashionLogic:CheckFashionOwn(data.id)
    tabPart.obj_weidianji:SetActive(not have)
    tabPart.obj_dianji:SetActive(have)
    UIHelper.SetText(tabPart.tx_subtitle, data.name)
    UIHelper.SetText(tabPart.tx_subtitle_wei, data.name)
    self.m_selectContainer[index] = tabPart.obj_select
    UGUIEventListener.AddButtonOnClick(tabPart.btn_subtitle, function()
      if not have then
        noticeManager:ShowTip(UIHelper.GetString(910016))
      else
        eventManager:SendEvent(LuaEvent.FASHION_SwitchFashion, data)
        self:_SetFashionSelect(index)
        local iid = Logic.illustrateLogic:Ssid2Sfid(data.ship_show_id)
        self:_ShowBaseInfo(iid)
        self:_ShowTitle(data.ship_show_id)
      end
    end)
    if self.ssId == data.ship_show_id then
      self:_SetFashionSelect(index)
    end
  end)
end

function PropertyPage:_showSelect(index)
  for i, obj in ipairs(self.m_selectContainer) do
    if index == i then
      obj:SetActive(true)
    else
      obj:SetActive(false)
    end
  end
end

function PropertyPage:_SetFashionSelect(index)
  self.m_select = index
  self:_showSelect(index)
end

function PropertyPage:RegisterAllEvent()
end

function PropertyPage:DoOnHide()
  self.m_tabWidgets.tween_PropertyPage:Stop()
end

function PropertyPage:DoOnClose()
end

function PropertyPage:_ResetSelectContainer()
  for i, obj in ipairs(self.m_selectContainer) do
    obj:SetActive(false)
  end
  self.m_selectContainer = {}
end

return PropertyPage
