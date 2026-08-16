local SuperStrategyPage = class("UI.Strategy.SuperStrategyPage", LuaUIPage)
local ToggleInfo = {
  [1] = {
    type = TalentType.ALL,
    str = 980012
  },
  [2] = {
    type = TalentType.ATTACK,
    str = 980013
  },
  [3] = {
    type = TalentType.DEFEND,
    str = 980014
  },
  [4] = {
    type = TalentType.ASSIST,
    str = 980015
  }
}
local UnlockType = {UserLevel = 1, Copy = 2}

function SuperStrategyPage:DoInit()
  self.selectFleetId = -1
  self.filterType = 0
  self.selectStrategy = true
  self.fleetType = FleetType.Normal
end

function SuperStrategyPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btnReset, self._btnReset, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnLearn, self._btnLearn, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnClose, self._btnClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnHelp, self._btnHelp, self)
  self:RegisterEvent(LuaEvent.GetFleetMsg, self._refresh, self)
  self:RegisterEvent(LuaEvent.LearnStrategy, self._refresh, self)
  self:RegisterEvent(LuaEvent.GetStrategyMsg, self._refresh, self)
  self:RegisterEvent(LuaEvent.ResetStrategy, self.onResetStrategy, self)
end

function SuperStrategyPage:DoOnOpen()
  self:OpenTopPage("SuperStrategyPage", 1, "\230\136\152\230\156\175", self, true, function()
    eventManager:SendEvent(LuaEvent.CloseStrategy)
    UIHelper.Back()
  end)
  local params = self:GetParam() or {}
  self.subType = params.subType
  self.strategyData = {}
  self.fleetId = params.fleetId
  self.fleetType = params.fleetType ~= nil and params.fleetType or FleetType.Normal
  if self.subType == FleetSubType.Train then
    local strategyIdTable = params.StrategyIds
    self.fleetData = params.FleetDatas
    for strategyId, level in pairs(strategyIdTable) do
      local strategyInfo = configManager.GetDataById("config_strategy", strategyId)
      table.insert(self.strategyData, strategyInfo)
    end
    self.strategyLearn = strategyIdTable
  else
    if self.fleetType == FleetType.Preset then
      self.fleetData = params.fleetTempData
    else
      self.fleetData = Data.fleetData:GetFleetData(self.fleetType)
    end
    local strategyData = clone(configManager.GetData("config_strategy"))
    for i, v in pairs(strategyData) do
      table.insert(self.strategyData, v)
    end
    self.strategyLearn = Data.strategyData:GetStrategyData()
  end
  self:_SortStrategy()
  self.strategyId = self.strategyData[1].id
  self:_InitToggleFilter()
  self:_RegisterStrategyList()
  self:_ShowStrategyApply()
  self:_InitFleet()
  self:_ShowStrategyById()
end

function SuperStrategyPage:_InitToggleFilter()
  local widgets = self:GetWidgets()
  local len = #ToggleInfo
  UIHelper.CreateSubPart(widgets.objFilter, widgets.contentFilter, len, function(index, tabPart)
    tabPart.toggle.isOn = index == 1
    widgets.tgGroupFilter:RegisterToggle(tabPart.toggle)
    UIHelper.SetText(tabPart.LabelOn, UIHelper.GetString(ToggleInfo[index].str))
    UIHelper.SetText(tabPart.LabelOff, UIHelper.GetString(ToggleInfo[index].str))
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tgGroupFilter, self, nil, self._SwitchFilter)
end

function SuperStrategyPage:_FilterStrategy()
  local strategyData = {}
  if self.subType == FleetSubType.Train then
    for strategyId, level in pairs(strategyIdTable) do
      local strategyInfo = configManager.GetDataById("config_strategy", strategyId)
      table.insert(strategyData, strategyInfo)
    end
  else
    local strategyDataTmp = clone(configManager.GetData("config_strategy"))
    for i, v in pairs(strategyDataTmp) do
      table.insert(strategyData, v)
    end
  end
  if self.filterType == TalentType.ALL then
    self.strategyData = strategyData
    return
  end
  self.strategyData = {}
  for i, strategyInfo in ipairs(strategyData) do
    local typeList = strategyInfo.talent_type
    local isRight = false
    for i, filterType in ipairs(typeList) do
      if filterType == self.filterType then
        isRight = true
      end
    end
    if isRight then
      table.insert(self.strategyData, strategyInfo)
    end
  end
end

function SuperStrategyPage:_SortStrategy()
  table.sort(self.strategyData, function(data1, data2)
    local isLearnA = Data.strategyData:GetStrategyDataById(data1.id) ~= nil
    local isLearnB = Data.strategyData:GetStrategyDataById(data2.id) ~= nil
    if isLearnA ~= isLearnB then
      return isLearnA
    elseif data1.order ~= data2.order then
      return data1.order < data2.order
    else
      return data1.id < data2.id
    end
  end)
end

function SuperStrategyPage:_ShowStrategyById()
  local widgets = self:GetWidgets()
  local level = Data.userData:GetUserLevel()
  local playerConfig = configManager.GetDataById("config_player_levelup", level)
  local numMax = playerConfig.tactic_poin
  local numNow = numMax - math.ceil(Data.strategyData:GetCurCost())
  widgets.btnReset:SetActive(Data.strategyData:GetCurCost() > 0 and self.subType ~= FleetSubType.Train)
  local numStr = numNow .. "/" .. numMax
  UIHelper.SetText(widgets.textNum, numStr)
  local strategyConfig = configManager.GetDataById("config_strategy", self.strategyId)
  UIHelper.SetText(widgets.textName, strategyConfig.strategy_name)
  UIHelper.SetImage(widgets.imgStrategy, strategyConfig.strategy_icon)
  local desTable = Logic.strategyLogic:GetStrategyDes(self.strategyId)
  UIHelper.CreateSubPart(widgets.objDec, widgets.contentDec, #desTable, function(index, tabPart)
    UIHelper.SetText(tabPart.textDec, desTable[index])
  end)
  local isLearn = Data.strategyData:GetStrategyDataById(self.strategyId) ~= nil
  widgets.objCost:SetActive(false)
  widgets.btnLearn:SetActive(not isLearn and self.subType ~= FleetSubType.Train)
  if isLearn and self.subType ~= FleetSubType.Train then
    PlayerPrefs.SetBool(PlayerPrefsKey.Strategy .. self.strategyId, false)
    eventManager:SendEvent(LuaEvent.StrategyRedDot)
  end
  local conditionTypeList = strategyConfig.strategy_limit_type
  local conditionValueList = strategyConfig.strategy_limit_p1
  local lenType = #conditionTypeList
  local lenValue = #conditionValueList
  if lenType ~= lenValue then
    logError("strategy table strategy_limit_type and strategy_limit_p1 len is not same")
    return
  end
  widgets.objConditionAll:SetActive(not isLearn and self.subType ~= FleetSubType.Train and 0 < lenType)
  UIHelper.CreateSubPart(widgets.objCondition, widgets.contentCondition, lenType, function(index, tabPart)
    local type = conditionTypeList[index]
    local value = conditionValueList[index]
    local languageId
    if type == UnlockType.UserLevel then
      languageId = 980020
    elseif type == UnlockType.Copy then
      languageId = 980021
      local copyDisplayConfig = configManager.GetDataById("config_copy_display", value)
      local chapterInfo = Logic.copyLogic:GetChapterByCopyId(value)
      value = chapterInfo.class_name .. " " .. copyDisplayConfig.str_index .. " " .. copyDisplayConfig.name
    end
    local str = string.format(UIHelper.GetString(languageId), value)
    UIHelper.SetText(tabPart.textDec, str)
  end)
  UIHelper.SetText(widgets.textCost, strategyConfig.activation_cost)
  widgets.objDeployed:SetActive(self:IsStrategyApply(self.strategyId))
  local str = strategyConfig.num_add
  local strList = string.split(str, "|")
  local resultStrList = {}
  for i, v in ipairs(strList) do
    local id = tonumber(v)
    if 0 < id then
      table.insert(resultStrList, id)
    end
  end
  widgets.Add_content:SetActive(isLearn and 0 < #resultStrList)
  UIHelper.CreateSubPart(widgets.textAdd, widgets.contentAdd, #resultStrList, function(index, tabPart)
    local id = resultStrList[index]
    local config = configManager.GetDataById("config_value_effect", id)
    UIHelper.SetText(tabPart.textDec, config.desc)
  end)
end

function SuperStrategyPage:_ShowStrategyApplyById()
  local widgets = self:GetWidgets()
  widgets.objDeployed:SetActive(self:IsStrategyApply(self.strategyId))
end

function SuperStrategyPage:_RegisterStrategyList()
  local widgets = self:GetWidgets()
  widgets.tgGroupStrategy:ClearToggles()
  local strategyData = self.strategyData
  self.strategyTable = {}
  local toggleIndex = -1
  UIHelper.CreateSubPart(widgets.objStrategy, widgets.contentStrategy, #strategyData, function(index, tabPart)
    local strategyInfo = strategyData[index]
    local strategyId = strategyInfo.id
    UIHelper.SetImage(tabPart.imgIcon, strategyInfo.strategy_icon)
    UIHelper.SetText(tabPart.textName, strategyInfo.strategy_name)
    self:RegisterRedDot(tabPart.redDot, strategyId)
    if strategyId == self.strategyId and self.selectStrategy then
      toggleIndex = index - 1
    end
    widgets.tgGroupStrategy:RegisterToggle(tabPart.toggle)
    self.strategyTable[strategyId] = tabPart
    self:_SetDrag(tabPart, strategyId, index)
  end)
  widgets.tgGroupStrategy:SetActiveToggleIndex(toggleIndex)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tgGroupStrategy, self, nil, self._SwitchStrategy)
end

function SuperStrategyPage:_ShowStrategyApply()
  for i, strategyInfo in ipairs(self.strategyData) do
    local strategyId = strategyInfo.id
    self.strategyTable[strategyId].deployed:SetActive(self:IsStrategyApply(strategyId))
    if self.subType == FleetSubType.Train then
      self.strategyTable[strategyId].objLock:SetActive(false)
    else
      self.strategyTable[strategyId].objLock:SetActive(Data.strategyData:GetStrategyDataById(strategyId) == nil)
    end
  end
end

function SuperStrategyPage:_SwitchFilter(index)
  self:OnReleaseCard()
  self.filterType = ToggleInfo[index + 1].type
  self:_FilterStrategy()
  if #self.strategyData > 0 then
    local result = false
    for i, v in ipairs(self.strategyData) do
      if v.id == self.strategyId then
        result = true
      end
    end
    if result == false then
      self.strategyId = self.strategyData[1].id
    end
  end
  self:_refresh()
  self:_ShowStrategyApplyById()
end

function SuperStrategyPage:_SwitchStrategy(index)
  local data = self.strategyData[index + 1]
  self.strategyId = data.id
  local widgets = self:GetWidgets()
  widgets.tgGroupFleet:SetActiveToggleOff()
  self.selectFleetId = -1
  self.selectStrategy = true
  self:_ShowStrategyApply()
  self:_ShowStrategyById()
end

function SuperStrategyPage:_InitFleet()
  if self.subType == FleetSubType.Train then
    self:_InitFleetTrain()
  else
    self:_InitFleetNormal()
  end
end

function SuperStrategyPage:_ShowFleet()
  if self.subType == FleetSubType.Train then
    self:_ShowFleetTrain()
  else
    self:_ShowFleetNormal()
  end
end

function SuperStrategyPage:_InitFleetNormal()
  local widgets = self:GetWidgets()
  self.fleetTable = {}
  local fleetMax = Logic.strategyLogic:GetFleetMaxByType(self.fleetType)
  if self.fleetType == FleetType.Preset then
    fleetMax = 1
  end
  UIHelper.CreateSubPart(widgets.objFleet, widgets.contentFleet, fleetMax, function(index, tabPart)
    local strategyId = 0
    if self.fleetType == FleetType.Preset then
      strategyId = self.fleetData[1].strategyId
    else
      local fleetInfo = Data.fleetData:GetFleetDataById(index, self.fleetType)
      strategyId = fleetInfo.strategyId
    end
    if 0 < strategyId then
      local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
      UIHelper.SetImage(tabPart.imgStrategy, strategyConfig.strategy_icon)
    end
    tabPart.imgStrategy.gameObject:SetActive(0 < strategyId)
    self:_SetFleetDrag(tabPart, index)
    local fleetName = Logic.fleetLogic:GetFleetName(index, self.fleetType)
    UIHelper.SetTextColorByBool(tabPart.textName, fleetName, 107, 106, self.fleetId == index)
    table.insert(self.fleetTable, tabPart)
    widgets.tgGroupFleet:RegisterToggle(tabPart.toggle)
  end)
  local pos = widgets.contentFleet.localPosition
  local rate = self.fleetId - 4 > 0 and self.fleetId - 4 or 0
  widgets.contentFleet.localPosition = Vector3.New(pos.x, 100 * rate, pos.z)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tgGroupFleet, self, nil, self._SwitchFleet)
end

function SuperStrategyPage:_ShowFleetNormal()
  for index, tabPart in ipairs(self.fleetTable) do
    local strategyId = 0
    if self.fleetType == FleetType.Preset then
      strategyId = self.fleetData[1].strategyId
    else
      local fleetInfo = Data.fleetData:GetFleetDataById(index, self.fleetType)
      strategyId = fleetInfo.strategyId
    end
    if 0 < strategyId then
      local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
      UIHelper.SetImage(tabPart.imgStrategy, strategyConfig.strategy_icon)
    end
    tabPart.imgStrategy.gameObject:SetActive(0 < strategyId)
  end
end

function SuperStrategyPage:_InitFleetTrain()
  local widgets = self:GetWidgets()
  local fleetData = self.fleetData
  local len = #fleetData
  self.fleetTable = {}
  UIHelper.CreateSubPart(widgets.objFleet, widgets.contentFleet, len, function(index, tabPart)
    local strategyId = self:GetStrategyIdByFleet(index)
    if 0 < strategyId then
      local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
      UIHelper.SetImage(tabPart.imgStrategy, strategyConfig.strategy_icon)
    end
    tabPart.imgStrategy.gameObject:SetActive(0 < strategyId)
    self:_SetFleetDrag(tabPart, index)
    local fleetName = self:GetFleetName(index)
    UIHelper.SetText(tabPart.textName, fleetName)
    table.insert(self.fleetTable, tabPart)
    widgets.tgGroupFleet:RegisterToggle(tabPart.toggle)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tgGroupFleet, self, nil, self._SwitchFleet)
end

function SuperStrategyPage:_ShowFleetTrain()
  for index, tabPart in ipairs(self.fleetTable) do
    local strategyId = self:GetStrategyIdByFleet(index)
    if 0 < strategyId then
      local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
      UIHelper.SetImage(tabPart.imgStrategy, strategyConfig.strategy_icon)
    end
    tabPart.imgStrategy.gameObject:SetActive(0 < strategyId)
  end
end

function SuperStrategyPage:_SwitchFleet(index)
  local fleetId = index + 1
  self.selectFleetId = fleetId
  local widgets = self:GetWidgets()
  widgets.tgGroupStrategy:SetActiveToggleOff()
  self.selectStrategy = false
  local strategyId = self:GetStrategyIdByFleet(fleetId)
  self:_ShowStrategyApply()
  self:_ShowStrategyApplyById()
  if 0 < strategyId then
    self.strategyId = strategyId
    self:_ShowStrategyById()
  end
end

function SuperStrategyPage:DoOnHide()
end

function SuperStrategyPage:DoOnClose()
end

function SuperStrategyPage:_btnReset()
  if Logic.strategyLogic:CheckResetCur() then
    local curTip1 = Logic.strategyLogic:GetResetCurTip1()
    local curTip2 = Logic.strategyLogic:GetResetCurTip2()
    local str = ""
    if curTip1 then
      str = str .. curTip1
    end
    if curTip2 then
      str = str .. curTip2
    end
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          Service.strategyService:SendReset()
          local dotinfo = {
            info = "ui_strategy_reset",
            cost_num = Logic.strategyLogic:GetResetCur()
          }
          RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
        end
      end
    }
    local tips = string.format(UIHelper.GetString(980006), str)
    noticeManager:ShowMsgBox(tips, tabParams)
  end
end

function SuperStrategyPage:_btnLearn()
  if Logic.strategyLogic:CheckLearn(self.strategyId) then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          local strategyId = self.strategyId
          Service.strategyService:SendLearn({
            Id = self.strategyId,
            FleetId = 1,
            Level = 1,
            TacticType = self.fleetType
          })
          local dotinfo = {
            info = "ui_strategy_study",
            strategy_id = strategyId,
            strategy_name = Logic.strategyLogic:GetNameById(strategyId)
          }
          RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
        end
      end
    }
    local tips = UIHelper.GetString(980004)
    noticeManager:ShowMsgBox(tips, tabParams)
  end
end

function SuperStrategyPage:onResetStrategy()
  self.selectStrategy = true
  local widgets = self:GetWidgets()
  widgets.tgGroupFleet:SetActiveToggleOff()
  self.selectFleetId = -1
  self:_SortStrategy()
  self.strategyId = self.strategyData[1].id
  self:_ShowFleet()
  self:_ShowStrategyById()
  self:_RegisterStrategyList()
  self:_ShowStrategyApply()
end

function SuperStrategyPage:_refresh()
  self:_SortStrategy()
  self:_ShowFleet()
  self:_ShowStrategyById()
  self:_RegisterStrategyList()
  self:_ShowStrategyApply()
end

function SuperStrategyPage:_SetDrag(tabPart, strategyId, index)
  UGUIEventListener.AddOnDrag(tabPart.objDrag, function(go, eventData)
    if self:IsStrategyLearn(strategyId) then
      local widgets = self:GetWidgets()
      widgets.tgGroupStrategy:SetActiveToggleIndex(index - 1)
      self:_OnDragCard(go, eventData, tabPart)
    end
  end)
  UGUIEventListener.AddOnEndDrag(tabPart.objDrag, self._OnEndDrag, self, strategyId)
end

function SuperStrategyPage:_OnDragCard(go, eventData, tabPart)
  if self.floatCard == nil then
    local widgets = self:GetWidgets()
    self.floatCard = UIHelper.CreateGameObject(tabPart.objDrag, widgets.floatCard)
    self.floatCard.transform.pivot = Vector2.New(0.5, 0.5)
  end
  if self.floatCard then
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local finalPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    self.floatCard.transform.position = finalPos
  end
end

function SuperStrategyPage:_OnEndDrag(go, eventData, strategyId)
  if not self:IsStrategyLearn(strategyId) then
    return
  end
  local fleetId = self:_CheckDragFleet(eventData)
  if 0 < fleetId then
    eventManager:SendEvent(LuaEvent.StrategyEndDrag, fleetId)
    if self.subType == FleetSubType.Train or Logic.strategyLogic:CheckApply(strategyId) then
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          local widgets = self:GetWidgets()
          widgets.tgGroupFleet:SetActiveToggleIndex(fleetId - 1)
          if bool then
            if self.subType == FleetSubType.Train then
              self:SetStrategyIdByFleet(fleetId, strategyId)
              self:_refresh()
            else
              PlayerPrefs.SetBool(PlayerPrefsKey.Strategy .. strategyId, false)
              eventManager:SendEvent(LuaEvent.StrategyRedDot)
              self.strategyId = strategyId
              if self.fleetType == FleetType.Preset then
                Logic.presetFleetLogic:SetStrategyId(self.fleetId, strategyId)
                self.fleetData = Logic.presetFleetLogic:SetTacrticOver(self.fleetId)
                self.selectFleetId = 1
                self:_refresh()
              else
                Service.strategyService:SendApply({
                  Id = strategyId,
                  FleetId = fleetId,
                  Level = 1,
                  TacticType = self.fleetType
                })
              end
              local dotinfo = {
                info = "ui_strategy_use",
                strategy_id = strategyId,
                strategy_name = Logic.strategyLogic:GetNameById(strategyId),
                team_num = fleetId
              }
              RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
            end
          end
        end
      }
      local tips = UIHelper.GetString(980005)
      noticeManager:ShowMsgBox(tips, tabParams)
    end
  end
  self:OnReleaseCard()
end

function SuperStrategyPage:_CheckDragFleet(eventData)
  local fleetMax = Logic.strategyLogic:GetFleetMaxByType(self.fleetType)
  if self.subType == FleetSubType.Train then
    local fleetData = self.fleetData
    fleetMax = #fleetData
  end
  for fleetId = 1, fleetMax do
    if self:_CheckDragFleetById(eventData, fleetId) then
      return fleetId
    end
  end
  return 0
end

function SuperStrategyPage:_CheckDragFleetById(eventData, fleetId)
  local widgets = self:GetWidgets()
  local dragPos = eventData.position
  local camera = eventData.pressEventCamera
  local posWorld = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
  local pos = widgets.contentFleet:InverseTransformPoint(posWorld)
  local trans = self.fleetTable[fleetId].trans
  local rec = self.fleetTable[fleetId].recTrans
  local width = rec.rect.width
  local height = rec.rect.height
  local left = trans.localPosition.x - width / 2
  local right = trans.localPosition.x + width / 2
  local up = trans.localPosition.y + height / 2
  local down = trans.localPosition.y - height / 2
  if left >= pos.x or right <= pos.x or down >= pos.y or up <= pos.y then
    return false
  end
  return true
end

function SuperStrategyPage:OnReleaseCard()
  self:_DestroyFloatCard()
end

function SuperStrategyPage:_DestroyFloatCard()
  if self.dragStrategyId then
    self.dragStrategyId = nil
  end
  if self.floatCard then
    GameObject.Destroy(self.floatCard)
    self.floatCard = nil
  end
  if self.floatFleet then
    GameObject.Destroy(self.floatFleet)
    self.floatFleet = nil
  end
end

function SuperStrategyPage:_SetFleetDrag(tabPart, fleetId)
  UGUIEventListener.AddOnDrag(tabPart.objDrag, function(go, eventData)
    local strategyId = self:GetStrategyIdByFleet(fleetId)
    if not strategyId or strategyId <= 0 then
      return
    end
    local widgets = self:GetWidgets()
    widgets.tgGroupFleet:SetActiveToggleIndex(fleetId - 1)
    self:_OnDragFleet(go, eventData, tabPart)
  end)
  UGUIEventListener.AddOnEndDrag(tabPart.objDrag, self._OnEndDragFleet, self, fleetId)
end

function SuperStrategyPage:_OnDragFleet(go, eventData, tabPart)
  if self.floatFleet == nil then
    local widgets = self:GetWidgets()
    self.floatFleet = UIHelper.CreateGameObject(tabPart.objDrag, widgets.floatCard)
    self.floatFleet.transform.pivot = Vector2.New(0.5, 0.5)
  end
  if self.floatFleet then
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local finalPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    self.floatFleet.transform.position = finalPos
  end
end

function SuperStrategyPage:_OnEndDragFleet(go, eventData, fleetId)
  local strategyId = self:GetStrategyIdByFleet(fleetId)
  if not strategyId or strategyId <= 0 then
    return
  end
  local result = self:_CheckDragFleetOut(eventData)
  if result then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          if self.subType == FleetSubType.Train then
            self:SetStrategyIdByFleet(fleetId, 0)
            self:_refresh()
          else
            local strategyId = self:GetStrategyIdByFleet(fleetId)
            self.strategyId = strategyId
            self.selectStrategy = true
            local widgets = self:GetWidgets()
            widgets.tgGroupFleet:SetActiveToggleOff()
            self.selectFleetId = -1
            PlayerPrefs.SetBool(PlayerPrefsKey.Strategy .. strategyId, false)
            eventManager:SendEvent(LuaEvent.StrategyRedDot)
            if self.fleetType == FleetType.Preset then
              Logic.presetFleetLogic:SetStrategyId(self.fleetId, 0)
              self.fleetData = Logic.presetFleetLogic:SetTacrticOver(self.fleetId)
              self.selectFleetId = 1
              self:_refresh()
            else
              Service.strategyService:SendApply({
                Id = 0,
                FleetId = fleetId,
                Level = 1,
                TacticType = self.fleetType
              })
            end
            local dotinfo = {
              info = "ui_strategy_cancel",
              strategy_id = strategyId,
              strategy_name = Logic.strategyLogic:GetNameById(strategyId),
              team_num = fleetId
            }
            RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
          end
        end
      end
    }
    local tips = UIHelper.GetString(980008)
    noticeManager:ShowMsgBox(tips, tabParams)
  end
  self:OnReleaseCard()
end

function SuperStrategyPage:_CheckDragFleetOut(eventData)
  local widgets = self:GetWidgets()
  local dragPos = eventData.position
  local camera = eventData.pressEventCamera
  local posWorld = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
  local pos = widgets.tranTactic:InverseTransformPoint(posWorld)
  local trans = widgets.tranRemove
  local rec = widgets.recRemove
  local width = rec.rect.width
  local height = rec.rect.height
  local left = trans.localPosition.x - width / 2
  local right = trans.localPosition.x + width / 2
  local up = trans.localPosition.y + height / 2
  local down = trans.localPosition.y - height / 2
  if left >= pos.x or right <= pos.x or down >= pos.y or up <= pos.y then
    return false
  end
  return true
end

function SuperStrategyPage:IsStrategyApply(strategyId)
  local fleetInfo = self.fleetData[self.selectFleetId]
  if fleetInfo == nil then
    return false
  else
    return fleetInfo.strategyId == strategyId
  end
end

function SuperStrategyPage:GetStrategyIdByFleet(fleetId)
  if self.fleetData and self.fleetData[fleetId] then
    return self.fleetData[fleetId].strategyId
  end
  return 0
end

function SuperStrategyPage:SetStrategyIdByFleet(fleetId, strategyId)
  if self.fleetData and self.fleetData[fleetId] then
    self.fleetData[fleetId].strategyId = strategyId
  end
end

function SuperStrategyPage:GetFleetName(fleetId)
  if self.fleetData and self.fleetData[fleetId] then
    return self.fleetData[fleetId].tacticName
  end
  return ""
end

function SuperStrategyPage:IsStrategyLearn(strategyId)
  return self.strategyLearn[strategyId] ~= nil
end

function SuperStrategyPage:_btnClose()
  eventManager:SendEvent(LuaEvent.CloseStrategy)
  UIHelper.ClosePage("SuperStrategyPage")
end

function SuperStrategyPage:_btnHelp()
  UIHelper.OpenPage("HelpPage", {content = 980009})
end

function SuperStrategyPage:getStrategyIndex(strategyId)
  for i, v in ipairs(self.strategyData) do
    if v.id == strategyId then
      return i
    end
  end
end

return SuperStrategyPage
