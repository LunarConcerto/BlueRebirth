local SafeInfoPage = class("UI.Copy.SafeInfoPage", LuaUIPage)
local LBAllPoint = 10000
local HelpParamId = 188
local AllSafeStage = 7

function SafeInfoPage:DoInit()
  self.stageId = nil
  self.copySerData = nil
  self.m_tabTips = {}
  self.isDailyCopy = nil
  self.safeLv = 0
  self.selectLv = 0
  self.copyId = 0
  self.isOutBattle = true
end

function SafeInfoPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeHelp, self._ClickCloseHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_sure, self._ClickSure, self)
  UGUIEventListener.AddOnEndDrag(self.tab_Widgets.scroll_help, self._ChangeSafeInfo, self)
  for i = 1, AllSafeStage do
    self.tab_Widgets.tog_group:RegisterToggle(self.tab_Widgets["tog_select" .. tostring(i)])
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
end

function SafeInfoPage:DoOnOpen()
  local param = self:GetParam()
  self.stageId = param[1]
  local displayId = param[2]
  self.isOutBattle = param[3]
  self.copyId = Logic.copyLogic:GetCopyIdByRunningCopyId(displayId)
  if not self.copyId then
    logError("\230\178\161\230\156\137\229\175\185\229\186\148\229\137\175\230\156\172\230\149\176\230\141\174 displayId:" .. displayId)
    return
  end
  if self.stageId == 0 then
    self.stageId = Logic.copyLogic:GetCopyDesConfig(self.copyId).stageid
  end
  self.isDailyCopy = self:_CheckIsSimplePage(self.copyId)
  self.copySerData = Data.copyData:GetCopyInfoById(self.copyId)
  if self.copySerData.SfDot then
    Service.copyService:SendDotBase(self.copySerData.BaseId)
  end
  self.stageConfig = configManager.GetDataById("config_stage", self.stageId)
  self:_GetCurrentSafeInfo(self.copySerData)
  self:_DisplayInfo()
end

function SafeInfoPage:_ChangeSafeInfo()
  local intervalIndex = self.tab_Widgets.scroll_fix.CurPage
  for k, v in pairs(self.m_tabTips) do
    v:SetActive(k == intervalIndex)
  end
end

function SafeInfoPage:_DisplayInfo()
  self.tab_Widgets.obj_sea:SetActive(not self.isDailyCopy)
  self.tab_Widgets.obj_daily:SetActive(self.isDailyCopy)
  local safeInfoTab = self:_GetSafeDetails()
  local currSafe = safeInfoTab[self.currIndex]
  self.tab_Widgets.txt_title.text = string.format(UIHelper.GetString(510005), currSafe.name)
  if not self.isDailyCopy then
    for i, v in ipairs(safeInfoTab) do
      if 1 < i then
        self.tab_Widgets["txt_effect" .. tostring(i)].text = v.effect
        local color = i <= self.currIndex and "5E718A" or "A2ADBA"
        UIHelper.SetTextColor(self.tab_Widgets["txt_effect" .. tostring(i)], v.effect, color)
        local imgTogBg = i <= self.currIndex and v.imgBg or v.imgBgLock
        UIHelper.SetImage(self.tab_Widgets["img_togBg" .. tostring(i)], imgTogBg)
      end
    end
    if 1 >= self.safeLv then
      self.tab_Widgets.slider_safe.value = 0
    elseif self.safeLv >= #safeInfoTab then
      self.tab_Widgets.slider_safe.value = 1
    else
      local sliderTotal = 2 * (#safeInfoTab - 1)
      local tempValue = 0
      for i = 1, self.currIndex do
        if i < self.currIndex then
          tempValue = tempValue + 2
        elseif safeInfoTab[self.currIndex].limitFinish[1][1] < safeInfoTab[self.currIndex].limitFinish[1][2] then
          tempValue = tempValue + 1
        end
      end
      self.tab_Widgets.slider_safe.value = tempValue / sliderTotal
    end
    local limit = self.currIndex >= #safeInfoTab and safeInfoTab[self.currIndex].limit[1] or safeInfoTab[self.currIndex + 1].limit[1]
    self.tab_Widgets.obj_normal:SetActive(limit.type == 1)
    self.tab_Widgets.obj_boss:SetActive(limit.type == 4)
    if limit.type == 1 then
      UIHelper.SetImage(self.tab_Widgets.img_score, CopyScoreImage[limit.p1 + 1], true)
    end
    self.tab_Widgets.obj_special:SetActive(Logic.copyLogic:IsDirectOpenSafeArea())
    self:_CreateHelp()
    self:_SelectSafeLv(safeInfoTab)
  else
    local color = self.currIndex >= #safeInfoTab and "5E718A" or "A2ADBA"
    UIHelper.SetTextColor(self.tab_Widgets.txt_dailyEff, safeInfoTab[#safeInfoTab].effect, color)
    self.tab_Widgets.obj_dailyCon:SetActive(self.currIndex ~= #safeInfoTab)
    self.tab_Widgets.obj_dailyConFinish:SetActive(self.currIndex == #safeInfoTab)
  end
end

function SafeInfoPage:_GetCurrentSafeInfo(serInfo)
  local point = serInfo.SfPoint and serInfo.SfPoint or 0
  self.safeLv = serInfo.SfLv == 0 and 1 or serInfo.SfLv
  self.selectLv = self.copySerData.SfLvChoose ~= 0 and self.copySerData.SfLvChoose or self.safeLv
  self.currIndex, self.sliderValue = Logic.copyLogic:GetSafeCurrProgress(self.stageConfig, self.safeLv, point)
end

function SafeInfoPage:_GetSafeDetails()
  local displayInfo = {}
  for index, lv in ipairs(self.stageConfig.safe_area) do
    local safeInfo = {}
    local safeConfig = configManager.GetDataById("config_safearea", lv)
    safeInfo.name = safeConfig.desc
    safeInfo.imgBg = safeConfig.imgbackground
    safeInfo.imgBgLock = safeConfig.imglock
    safeInfo.safeValue = self.stageConfig.safe_area[#self.stageConfig.safe_area - (index - 1)]
    local effectStrId = self.stageConfig.safe_effect_desc[index]
    if effectStrId ~= 0 then
      safeInfo.effect = UIHelper.GetString(effectStrId)
    else
      safeInfo.effect = UIHelper.GetString(510002)
    end
    local limitIdTab = self.stageConfig.safe_condition[index]
    safeInfo.limit = {}
    safeInfo.limitFinish = {}
    if index ~= 1 then
      for i, v in ipairs(limitIdTab) do
        local limitConfig = configManager.GetDataById("config_safearea_condition", v)
        local totalValue, currValue = self:_GetConditionValue(limitConfig, self.copySerData)
        safeInfo.limitFinish[i] = {totalValue, currValue}
        safeInfo.limit[i] = limitConfig
      end
    end
    table.insert(displayInfo, safeInfo)
  end
  return displayInfo
end

function SafeInfoPage:_GetConditionValue(nextLimit, serInfo)
  local totalValue = 0
  local currValue = 0
  if nextLimit.type == 1 or nextLimit.type == 2 then
    totalValue = nextLimit.p2
  elseif nextLimit.type == 3 then
    totalValue = nextLimit.p1
  elseif nextLimit.type == 4 then
    totalValue = nextLimit.p1 == 0 and 100 or nextLimit.p1 / LBAllPoint
    currValue = math.floor(serInfo.LBPoint / LBAllPoint * 100)
  end
  if next(serInfo.SfInfo) == nil then
    return totalValue, currValue
  end
  for i, v in ipairs(serInfo.SfInfo) do
    if v.Type == nextLimit.type then
      for _, info in ipairs(v.Info) do
        if info.Key <= nextLimit.p1 then
          currValue = currValue + info.Value
        end
      end
    end
  end
  return totalValue, currValue
end

function SafeInfoPage:_CheckIsSimplePage(copyId)
  local isDailyCopy = Data.copyData:GetDailyCopyByCopyId(copyId)
  if isDailyCopy then
    return true
  end
  local copyDisplayConfig = Logic.copyLogic:GetCopyDesConfig(copyId)
  return copyDisplayConfig.once_seasafe == 1
end

function SafeInfoPage:_ClickClose()
  UIHelper.ClosePage("SafeInfoPage")
end

function SafeInfoPage:_ClickHelp()
  self.tab_Widgets.obj_help:SetActive(true)
end

function SafeInfoPage:_ClickCloseHelp()
  self.tab_Widgets.obj_help:SetActive(false)
end

function SafeInfoPage:_CreateHelp()
  local configInfo = configManager.GetDataById("config_parameter", HelpParamId).arrValue
  UIHelper.CreateSubPart(self.tab_Widgets.obj_helpItem, self.tab_Widgets.trans_help, #configInfo, function(index, tabPart)
    UIHelper.SetImage(tabPart.img_show, configInfo[index], true)
    tabPart.obj_arrow:SetActive(index ~= #configInfo)
    tabPart.obj_leftArrow:SetActive(1 ~= index)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_right, self._ClickHelpRight, self)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_left, self._ClickHelpLeft, self)
  end)
  self:_CreateHelpTips(configInfo)
end

function SafeInfoPage:_CreateHelpTips(configInfo)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_helpTipsItem, self.tab_Widgets.trans_helpTips, #configInfo, function(index, tabPart)
    tabPart.obj_tips:SetActive(1 == index)
    self.m_tabTips[index] = tabPart.obj_tips
  end)
  self.tab_Widgets.scroll_fix.Total = #configInfo
  self.tab_Widgets.scroll_fix.DragThreshold = 1 / #configInfo
end

function SafeInfoPage:_ClickHelpLeft()
  local currIndex = self.tab_Widgets.scroll_fix.CurPage
  self.tab_Widgets.scroll_fix.CurPage = currIndex - 1
  self:_ChangeSafeInfo()
end

function SafeInfoPage:_ClickHelpRight()
  local currIndex = self.tab_Widgets.scroll_fix.CurPage
  self.tab_Widgets.scroll_fix.CurPage = currIndex + 1
  self:_ChangeSafeInfo()
end

function SafeInfoPage:DoOnHide()
  self.tab_Widgets.tog_group:ClearToggles()
end

function SafeInfoPage:DoOnClose()
  self.tab_Widgets.tog_group:ClearToggles()
end

function SafeInfoPage:_SelectSafeLv(safeInfoTab)
  local userLv = Data.userData:GetUserLevel()
  local limitLv = configManager.GetDataById("config_parameter", 322).value
  self.tab_Widgets.txt_condition.gameObject:SetActive(userLv < limitLv)
  self.tab_Widgets.obj_difficult:SetActive(userLv >= limitLv)
  if userLv < limitLv then
    self:_SetTogUnActive(safeInfoTab)
    return
  end
  self.tab_Widgets.tog_group:SetActiveToggleIndex(self.selectLv - 1)
  if self.isOutBattle then
    self:_SetActiveTog(safeInfoTab)
  else
    self:_SetTogUnActive(safeInfoTab)
  end
end

function SafeInfoPage:_SetTogUnActive(safeInfoTab)
  for i, _ in ipairs(safeInfoTab) do
    self.tab_Widgets.tog_group:ResigterToggleUnActive(i - 1, function()
      self:_UnActive()
    end)
  end
end

function SafeInfoPage:_SetActiveTog(safeInfoTab)
  for i, _ in ipairs(safeInfoTab) do
    if i > self.safeLv then
      self.tab_Widgets.tog_group:ResigterToggleUnActive(i - 1, function()
        self:_StopTog()
      end)
    else
      self.tab_Widgets.tog_group:RemoveToggleUnActive(i - 1)
    end
  end
end

function SafeInfoPage:_StopTog()
  noticeManager:OpenTipPage(self, 510011)
end

function SafeInfoPage:_UnActive()
end

function SafeInfoPage:_SwitchTogs(index)
  self.selectLv = index + 1
  local safeConfig = configManager.GetDataById("config_safearea", self.selectLv)
  UIHelper.SetTextColor(self.tab_Widgets.txt_currDif, safeConfig.desc, safeConfig.copy_text_color)
end

function SafeInfoPage:_ClickSure()
  if self.selectLv ~= self.copySerData.SfLvChoose and self.isOutBattle then
    Service.copyService:SendChooseSafeLv(self.copyId, self.selectLv)
  end
  self:_ClickClose()
end

return SafeInfoPage
