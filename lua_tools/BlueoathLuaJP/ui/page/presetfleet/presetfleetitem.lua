local PresetFleetItem = class("UI.PresetFleet.PresetFleetItem")
local presetFleetItem = require("ui.page.PresetFleet.PresetFleetCardItem")
local levelFleetPage = require("ui.page.PresetFleet.PresetFleetCardDrag")

function PresetFleetItem:initialize()
  self.m_index = 0
  self.m_page = nil
  self.m_widgets = {}
  self.m_data = {}
  self.m_recordIndex = 0
  self.m_recordData = {}
  self.m_strategyIsOn = false
  self.m_isLock = false
  self.m_fleetType = FleetType.Preset
  self.m_popObj = nil
  self.m_popShip = nil
  self.m_clickPos = nil
  self.m_rectTranArr = {}
  self.m_fleetCardItem = {}
  self.m_exRectTranArr = {}
  self.m_exFleetCardItem = {}
  self.lastPos = nil
  self.isClickCard = false
  self.m_bNeedSave = false
end

function PresetFleetItem:Init(obj, widgets, data, index, recordData, isLock, pagewidgets)
  self.m_index = index
  self.m_page = obj
  self.m_isLock = isLock
  self.pageWidgets = pagewidgets
  self:SetWidgets(widgets)
  self:SetData(data, widgets, index)
  self:SetRecordData(recordData)
  self:ShowItem()
  levelFleetPage:Init(self, self.m_fleetType)
end

function PresetFleetItem:SetWidgets(widgets)
  self.m_widgets = widgets
end

function PresetFleetItem:SetData(data, tabPart, index)
  self.m_data = data
  self.m_widgets = tabPart
end

function PresetFleetItem:SetRecordData(data)
  self.m_recordIndex = data.index
  self.m_recordData = data.fleetsInfo
  self.m_recordType = data.fleetType
end

function PresetFleetItem:GetWidgets()
  return self.m_widgets
end

function PresetFleetItem:GetData()
  return self.m_data
end

function PresetFleetItem:SetStrategyIsOn(isOn)
  self.m_strategyIsOn = isOn
end

function PresetFleetItem:ShowItem()
  self:_ShowBase()
  self:_ShowHeroCards()
  self:ShowSubmarineCards()
end

function PresetFleetItem:_ShowBase()
  self:_ShowTxt()
  self:_ShowButton()
end

function PresetFleetItem:_ShowTxt()
  local widgets = self.m_widgets
  local data = self.m_data
  local index = self.m_index
  if data then
    if data.Name then
      UIHelper.SetText(widgets.tx_jianduiming, data.Name)
    else
    end
    local strategyId = data.strategyId
    widgets.Txt_tactic.gameObject:SetActive(true)
    widgets.tx_weibushu:SetActive(false)
    widgets.bg_weisheding:SetActive(false)
    widgets.bg_jianduiming:SetActive(true)
    if strategyId and 0 < strategyId then
      local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
      UIHelper.SetText(widgets.tx_Tactic, strategyConfig.strategy_name)
      local conditionRes = Logic.strategyLogic:CheckConditionByFleet(self.m_index, FleetType.Preset, strategyId)
      widgets.tactic_Off.gameObject:SetActive(0 < strategyId and not conditionRes)
      widgets.tactic_On.gameObject:SetActive(0 < strategyId and conditionRes)
    else
      UIHelper.SetText(widgets.tx_Tactic, UIHelper.GetString(980011))
      widgets.tactic_Off.gameObject:SetActive(false)
      widgets.tactic_On.gameObject:SetActive(false)
    end
  else
    widgets.bg_weisheding:SetActive(true)
    widgets.bg_jianduiming:SetActive(false)
    widgets.Txt_tactic.gameObject:SetActive(false)
    widgets.tx_weibushu:SetActive(true)
    widgets.tactic_Off.gameObject:SetActive(false)
    widgets.tactic_On.gameObject:SetActive(false)
  end
end

function PresetFleetItem:_ShowButton()
  local widgets = self.m_widgets
  local data = self.m_data
  if data ~= nil and next(data) ~= nil then
    widgets.btn_delete.gameObject:SetActive(true)
    widgets.btn_shangzhen.gameObject:SetActive(true)
    widgets.btn_resettactic.gameObject:SetActive(true)
    widgets.btn_resetname.gameObject:SetActive(true)
  else
    widgets.btn_delete.gameObject:SetActive(false)
    widgets.btn_shangzhen.gameObject:SetActive(false)
    widgets.btn_resettactic.gameObject:SetActive(false)
    widgets.btn_resetname.gameObject:SetActive(false)
  end
  widgets.btn_jilu.gameObject:SetActive(self.m_page.openType == PresetFleetType.Fleet)
  if self.m_page.openType == PresetFleetType.Fleet then
    UGUIEventListener.AddButtonOnClick(widgets.btn_delete, self._DeletePreset, self)
    UGUIEventListener.AddButtonOnClick(widgets.btn_resetname, self._ResetName, self)
    UGUIEventListener.AddButtonOnClick(widgets.btn_resettactic, self._ResetTactic, self)
    UGUIEventListener.AddButtonOnClick(widgets.btn_jilu, self._Record, self)
    UGUIEventListener.AddButtonOnClick(widgets.btn_shangzhen, self._GoBattle, self)
  else
    UGUIEventListener.AddButtonOnClick(widgets.btn_delete, self._DeletePreset, self)
    UGUIEventListener.AddButtonOnClick(widgets.btn_resetname, self._ResetName, self)
    UGUIEventListener.AddButtonOnClick(widgets.btn_resettactic, self._ResetTactic, self)
    UGUIEventListener.AddButtonOnClick(widgets.btn_shangzhen, self._MatchTactic, self)
  end
end

function PresetFleetItem:_ShowHeroCards()
  local fleetData = self.m_data
  local index = self.m_index
  self.m_rectTranArr = {}
  UIHelper.CreateSubPart(self.m_widgets.item_HeroCard, self.m_widgets.content_Fleet, 6, function(nIndex, tabPart)
    local heroId = 0
    local herosData = {}
    if fleetData ~= nil and next(fleetData) ~= nil then
      if fleetData.heroList[nIndex] ~= nil then
        heroId = fleetData.heroList[nIndex]
      end
      herosData = fleetData.heroList
    else
      herosData = {}
    end
    local item = presetFleetItem:new()
    item:Init(self, heroId, nIndex, tabPart, self.m_widgets.obj_float, index, false, self.m_page.openType)
    self.m_rectTranArr[nIndex] = tabPart.rectTranSelf
    self.m_fleetCardItem[nIndex] = item
  end)
end

function PresetFleetItem:ShowSubmarineCards()
  local fleetData = self.m_data
  local index = self.m_index
  self.m_exRectTranArr = {}
  UIHelper.CreateSubPart(self.m_widgets.obj_attached, self.m_widgets.content_attached, 3, function(nIndex, tabPart)
    local heroId = 0
    local herosData = {}
    if fleetData ~= nil and next(fleetData) ~= nil and fleetData.exHeroList ~= nil then
      if fleetData.exHeroList[nIndex] ~= nil then
        heroId = fleetData.exHeroList[nIndex]
      end
      herosData = fleetData.exHeroList
    else
      herosData = {}
    end
    local item = presetFleetItem:new()
    item:Init(self, heroId, nIndex, tabPart, self.m_widgets.obj_float, index, true, self.m_page.openType)
    self.m_exRectTranArr[nIndex] = tabPart.rectTranSelf
    self.m_exFleetCardItem[nIndex] = item
  end)
  local strName = self:GetSubmarineStrategy()
  UIHelper.SetText(self.m_widgets.txt_tactic, strName)
end

function PresetFleetItem:GetSubmarineStrategy()
  local fleetData = self.m_data
  if fleetData == nil or fleetData.exHeroList == nil or next(fleetData.exHeroList) == nil then
    return ""
  end
  local heroId = fleetData.exHeroList[1]
  if heroId then
    local sm_id = Data.heroData:GetHeroById(heroId).TemplateId
    local pskillArr = Logic.shipLogic:GetAllPSkillArrbyShipMainId(sm_id)
    for _, pskillId in ipairs(pskillArr) do
      local showSkillId = Logic.shipLogic:GetReplaceSkillId(pskillId, heroId)
      if type(pskillId) ~= "table" then
        local id = Logic.shipLogic:GetPSkillDisplayIdByGroupId(showSkillId)
        local cfg = configManager.GetDataById("config_pskill_dict_display", id)
        if cfg.flag_skill == 1 then
          return cfg.skill_name
        end
      end
    end
    return ""
  else
    return ""
  end
end

function PresetFleetItem:_OnClickHero(param)
  Logic.presetFleetLogic:SetCurIndex(param.m_index)
  local tabShowHero = {}
  local selectCount = 6
  if param.m_isExHero then
    selectCount = 3
    tabShowHero = Logic.dockLogic:FilterShipList(DockListType.Submarine)
  else
    tabShowHero = Logic.dockLogic:FilterShipList(DockListType.Main)
  end
  UIHelper.OpenPage("CommonSelectPage", {
    CommonHeroItem.PresetFleet,
    tabShowHero,
    {
      m_selectMax = selectCount,
      m_selectedIdList = param.m_data,
      m_presetIndex = param.m_index,
      m_isExHero = param.m_isExHero
    }
  })
end

function PresetFleetItem:_DeletePreset()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      self:_ClickDeletePreset(bool)
    end
  }
  noticeManager:ShowMsgBox(UIHelper.GetString(1900005), tabParams)
end

function PresetFleetItem:_ClickDeletePreset(bool)
  if bool then
    local index = self.m_index
    Logic.presetFleetLogic:DeleteFleet(index)
  end
end

function PresetFleetItem:_ResetName()
  local data = self.m_data
  local index = self.m_index
  local name = data.Name
  UIHelper.OpenPage("ChangeNamePage", {
    index,
    name,
    name,
    ChangeNameType.PresetFleet
  })
end

function PresetFleetItem:_ResetTactic()
  Logic.presetFleetLogic:SendPresetService()
  local tempData = {}
  tempData[1] = Logic.presetFleetLogic:GenStrategyTemplate(self.m_data.strategyId)
  moduleManager:JumpToFunc(FunctionID.Strategy, {
    fleetId = self.m_index,
    fleetType = FleetType.Preset,
    fleetTempData = tempData
  })
end

function PresetFleetItem:_Record()
  local recordIndex = clone(self.m_recordIndex)
  local recordData = clone(self.m_recordData)
  local heroInfo = recordData[recordIndex].heroInfo
  local recordFleetName = clone(self.m_recordData[self.m_recordIndex].tacticName)
  if heroInfo == nil or #heroInfo == 0 then
    noticeManager:ShowTip(string.format(UIHelper.GetString(1900002), recordFleetName))
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      self:_ClickRecordPreset(bool)
    end
  }
  noticeManager:ShowMsgBox(string.format(UIHelper.GetString(1900001), recordFleetName), tabParams)
end

function PresetFleetItem:_ClickRecordPreset(bool)
  if bool then
    local recordIndex = clone(self.m_recordIndex)
    local recordData = clone(self.m_recordData)
    if self.m_data == nil then
      self.m_data = Logic.presetFleetLogic:GenPresetTemplateItem(self.m_index)
    end
    self.m_data.strategyId = recordData[recordIndex].strategyId
    self.m_data.heroList = recordData[recordIndex].heroInfo
    self.m_data.exHeroList = recordData[recordIndex].exHeroInfo
    local isRecord = true
    Logic.presetFleetLogic:SetPresetHeros(self.m_index, self.m_data.heroList, self.m_data.exHeroList, self.m_data.Name, self.m_data.strategyId, isRecord)
  end
end

function PresetFleetItem:_GoBattle()
  local fleetIsSweeping = Logic.copyLogic:GetFleetIsSweeping(self.m_recordIndex)
  if fleetIsSweeping then
    local showText = string.format(UIHelper.GetString(960000032))
    noticeManager:OpenTipPage(self, showText)
    return
  end
  local ok, repeatedHeroList, repeatedFleetList = Logic.presetFleetLogic:GetRepeatHeroList(self.m_index, self.m_recordIndex)
  if repeatedFleetList ~= nil then
    for fleetId = 1, #repeatedFleetList do
      local repaetSweeping = Logic.copyLogic:GetFleetIsSweeping(repeatedFleetList[fleetId])
      if repaetSweeping then
        local showText = string.format(UIHelper.GetString(960000032))
        noticeManager:OpenTipPage(self, showText)
        return
      end
    end
  end
  local heroNameMsg = ""
  local recordType = clone(self.m_recordType)
  local recordFleetName = clone(self.m_recordData[self.m_recordIndex].tacticName)
  local str = ""
  if ok then
    for i, v in ipairs(repeatedHeroList) do
      local strName = Logic.shipLogic:GetRealName(v)
      heroNameMsg = heroNameMsg .. strName
      if #repeatedHeroList ~= i then
        heroNameMsg = heroNameMsg .. ","
      end
    end
    str = string.format(UIHelper.GetString(1900004), heroNameMsg, recordFleetName)
  else
    str = string.format(UIHelper.GetString(1900003), recordFleetName)
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      self:_ClickBattle(bool, repeatedHeroList, repeatedFleetList)
    end
  }
  noticeManager:ShowMsgBox(str, tabParams)
end

function PresetFleetItem:_ClickBattle(bool, heroList, fleetList)
  if bool then
    local recordIndex = clone(self.m_recordIndex)
    local recordData = clone(self.m_recordData)
    local recordType = clone(self.m_recordType)
    local data = self.m_data
    if recordIndex and recordData then
      recordData[recordIndex].heroInfo = data.heroList
      recordData[recordIndex].exHeroList = data.exHeroList
      recordData[recordIndex].strategyId = data.strategyId
    end
    if recordType == FleetType.Normal and heroList and fleetList and #heroList ~= 0 and #fleetList ~= 0 then
      for i, v in ipairs(fleetList) do
        local temppos = 0
        for j, w in ipairs(recordData[v].heroInfo) do
          if w == heroList[i] then
            temppos = j
          end
        end
        if recordData[v].heroInfo[temppos] ~= nil then
          table.remove(recordData[v].heroInfo, temppos)
        end
      end
    end
    local tacticsTab = {tactics = recordData}
    self.fleetType = FleetType.Normal
    local isStrategyFuncOpen = Logic.presetFleetLogic:CheckStrategyFuncOpen()
    Service.fleetService:SendSetFleet(tacticsTab)
    if isStrategyFuncOpen then
      Service.strategyService:SendApply({
        Id = recordData[recordIndex].strategyId,
        FleetId = recordIndex,
        Level = 1,
        TacticType = recordType
      })
    end
    eventManager:SendEvent(LuaEvent.PresetGoBattle)
  end
end

function PresetFleetItem:OnDragCard(tabPart, shipInfo, clickIndex, isExHero, originObj)
  self.isClickCard = false
  levelFleetPage:OnDrag(tabPart, shipInfo, clickIndex, self.m_fleetType, self.m_index, isExHero, self, originObj)
end

function PresetFleetItem:ClickFleetCard(isExHero)
  eventManager:SendEvent(LuaEvent.PRESET_SelectHero, self.m_presetData)
  local index = self.m_index
  local fleetData = self.m_data
  local herosData = {}
  if fleetData ~= nil and next(fleetData) ~= nil then
    if isExHero then
      herosData = fleetData.exHeroList or {}
    else
      herosData = fleetData.heroList
    end
  end
  levelFleetPage:ClickCard(index, herosData, self.isClickCard, isExHero)
end

function PresetFleetItem:_CreatePresetFleetInfo()
  eventManager:SendEvent(LuaEvent.PRESET_SelectHero, self.m_presetData)
end

function PresetFleetItem:Dispose()
end

function PresetFleetItem:StrategyId2String()
end

function PresetFleetItem:_MatchTactic()
  if self.m_page.openType == PresetFleetType.Match then
    local heroInfoTab = Logic.presetFleetLogic:SendMatchTactic(self.m_data)
    Service.pveRoomService:SendUploadTactic(heroInfoTab)
    self.m_page:_ClosePage()
  else
    self.m_page:_ClosePresetFleetPage()
  end
end

return PresetFleetItem
