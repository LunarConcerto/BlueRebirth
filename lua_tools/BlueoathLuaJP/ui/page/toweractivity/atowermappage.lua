local ATowerMapPage = class("UI.TowerActivity.ATowerMapPage", LuaUIPage)

function ATowerMapPage:DoInit()
  self.tablePart = {}
end

function ATowerMapPage:DoOnOpen()
  local historyMax = Data.towerActivityData:GetHistoryMax()
  local passNum = Logic.towerActivityLogic:GetPassNum()
  local dotinfo = {
    info = "limited_tower_max",
    num = math.max(passNum, historyMax)
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  local chapterConfig = self.param.chapterConfig
  self.chapterConfig = chapterConfig
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_tower_activity", towerId)
  self.chapterTowerConfig = chapterTowerConfig
  self:OpenTopPageNoTitle(chapterTowerConfig.page_name, 1, true)
  local copyMap = Logic.copyLogic:ATowerGetCopyMap(chapterConfig)
  local widgets = self:GetWidgets()
  local heroIdList = Logic.towerLogic:GetHeroIdList(FleetType.LimitTower)
  if 0 < #heroIdList then
    UIHelper.OpenPage("TowerLockedPage", {
      fleetType = FleetType.LimitTower
    })
  end
  local heroIdList = Data.towerActivityData:GetHeroIdList()
  if 0 < #heroIdList then
    Data.towerActivityData:ResetHeroIdList()
  end
  self:ShowPath()
  self:ShowArrow()
  local arrowMapPart = widgets.trans_point:GetLuaTableParts()
  for copyId, v in pairs(copyMap) do
    UIHelper.CreateSubPart(widgets.im_point, arrowMapPart[tostring(copyId)], 1, function(index, tablePart)
      tablePart.gameObject:SetActive(true)
      self:ShowPoint(copyId, tablePart)
      self.tablePart[copyId] = tablePart
    end)
  end
  self:ShowLeftTime()
  local timer = self:CreateTimer(function()
    self:ShowLeftTime()
  end, 0.5, -1)
  self:StartTimer(timer)
  self:ShowEnter()
  self:ShowHistory()
  self:bu_buff_close()
  local rate = Logic.towerActivityLogic:GetAddition() * 100
  if 0 < rate then
    rate = string.format("%.1f", rate)
    UIHelper.SetLocText(widgets.tx_tip, 2900006, rate .. "%")
  else
    UIHelper.SetLocText(widgets.tx_tip, 2900022)
  end
end

function ATowerMapPage:ShowPicture()
  local widgets = self:GetWidgets()
  local imagePart = widgets.image:GetLuaTableParts()
  local copyMap = Logic.copyLogic:ATowerGetCopyMap(self.chapterConfig)
  for copyId, v in pairs(copyMap) do
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
    if not isBuff then
      local state = Logic.towerActivityLogic:GetCopyState(copyId, self.chapterConfig.id)
      if state == TowerCopyState.Clear then
        UIHelper.SetImage(imagePart[tostring(copyId)], copyConfig.copy_thumbnail_after)
      else
        UIHelper.SetImage(imagePart[tostring(copyId)], copyConfig.copy_thumbnail_before)
      end
    end
  end
end

function ATowerMapPage:ShowPath()
  local widgets = self:GetWidgets()
  local pathMapPart = widgets.line:GetLuaTableParts()
  local pathListSrc = Data.towerActivityData:GetCopyList()
  local pathMap = {}
  if 0 < #pathListSrc then
    for i = 1, #pathListSrc do
      if i < #pathListSrc then
        local src = pathListSrc[i]
        local dst = pathListSrc[i + 1]
        self:setPathMap(pathMap, pathMapPart, src, dst)
      end
    end
  end
  for name, go in pairs(pathMapPart) do
    if name ~= "gameObject" then
      go:SetActive(pathMap[name] == true)
    end
  end
end

function ATowerMapPage:ShowArrow()
  local widgets = self:GetWidgets()
  local pathListSrc = Data.towerActivityData:GetCopyList()
  local arrowMapPart = widgets.arrow:GetLuaTableParts()
  local copyMapAttack = Logic.towerActivityLogic:GetCopyAttack(self.chapterConfig.id)
  local arrowMap = {}
  local src
  if 0 < #pathListSrc then
    src = pathListSrc[#pathListSrc]
  else
    src = 0
  end
  for dst, _ in pairs(copyMapAttack) do
    local arrow = src .. "_" .. dst
    arrowMap[arrow] = true
  end
  for name, go in pairs(arrowMapPart) do
    if name ~= "gameObject" then
      go:SetActive(arrowMap[name] == true)
    end
  end
end

function ATowerMapPage:ShowPoint(copyId, tablePart)
  local state = Logic.towerActivityLogic:GetCopyState(copyId, self.chapterConfig.id)
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
  local isClear = state == TowerCopyState.Clear
  local quickPassMax = Logic.towerActivityLogic:GetQuickPassMax(self.chapterTowerConfig)
  local quickNumber = Data.towerActivityData:GetQuickNumber()
  local times = quickNumber
  local passNum = Logic.towerActivityLogic:GetPassNum()
  times = 0 < times and times or 0
  tablePart.btn_quick_attack.gameObject:SetActive(state == TowerCopyState.Attack and 0 < times and not isBuff)
  tablePart.im_icon.gameObject:SetActive(not isBuff)
  if not isBuff then
    if state == TowerCopyState.Clear then
      UIHelper.SetImage(tablePart.im_icon, copyConfig.copy_thumbnail_after)
    else
      UIHelper.SetImage(tablePart.im_icon, copyConfig.copy_thumbnail_before)
    end
  end
  local resetCopyMap = Logic.towerActivityLogic:GetResetCopyMap(self.chapterConfig.id)
  local isResetCopy = resetCopyMap[copyId]
  tablePart.reset:SetActive(isBuff and isResetCopy)
  tablePart.im_buff_clear:SetActive(isClear and isBuff and not isResetCopy)
  tablePart.im_buff_lock:SetActive(not isClear and isBuff and not isResetCopy)
  tablePart.im_clear:SetActive(isClear and not isBuff)
  tablePart.im_lock:SetActive(not isClear and not isBuff)
  if not isBuff then
    UIHelper.SetText(tablePart.text_clear, copyConfig.copy_index)
    UIHelper.SetText(tablePart.text_lock, copyConfig.copy_index)
  end
  UIHelper.SetText(tablePart.tx_name, copyConfig.name)
  UIHelper.SetText(tablePart.tx_name_clear, copyConfig.name)
  UIHelper.SetText(tablePart.tx_buff_clear, copyConfig.name)
  UIHelper.SetText(tablePart.tx_buff_lock, copyConfig.name)
  UGUIEventListener.AddButtonOnClick(tablePart.btn_quick_attack, function()
    local periodId = self.chapterConfig.chapter_period
    if 0 < periodId then
      local isInPeriod = PeriodManager:IsInPeriodArea(periodId, self.chapterConfig.chapter_periodarea)
      if not isInPeriod then
        noticeManager:ShowTipById(270022)
        return
      end
    end
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    local isBuff = 0 < copyConfig.pskill_id or 0 < #copyConfig.special_buff
    local quickPassMax = Logic.towerActivityLogic:GetQuickPassMax(self.chapterTowerConfig)
    local times = quickNumber
    local passNum = Logic.towerActivityLogic:GetPassNum()
    times = 0 < times and times or 0
    local state = Logic.towerActivityLogic:GetCopyState(copyId, self.chapterConfig.id)
    if state == TowerCopyState.Attack and 0 < times and not isBuff then
      Service.towerActivityService:SendQuickPass({CopyId = copyId})
    end
  end)
  UGUIEventListener.AddButtonOnClick(tablePart.btn, function()
    local periodId = self.chapterConfig.chapter_period
    if 0 < periodId then
      local isInPeriod = PeriodManager:IsInPeriodArea(periodId, self.chapterConfig.chapter_periodarea)
      if not isInPeriod then
        noticeManager:ShowTipById(270022)
        return
      end
    end
    local state = Logic.towerActivityLogic:GetCopyState(copyId, self.chapterConfig.id)
    if state == TowerCopyState.Attack then
      local isNotDeadRoad = Logic.towerActivityLogic:IsNotDeadRoad()
      local result = Logic.towerActivityLogic:CheckAvailable(copyId)
      if isNotDeadRoad and not result then
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              Logic.towerActivityLogic:CopyClick(copyId)
            end
          end
        }
        local tips = string.format(UIHelper.GetString(2900015))
        noticeManager:ShowMsgBox(tips, tabParams)
      else
        Logic.towerActivityLogic:CopyClick(copyId)
      end
    elseif state == TowerCopyState.Lock then
      Logic.towerActivityLogic:CopyClick(copyId)
    elseif state == TowerCopyState.Clear then
      noticeManager:ShowTipById(1703010)
    end
  end)
end

function ATowerMapPage:_refreshQuick()
  noticeManager:ShowTipById(2900011)
  self:_refresh()
end

function ATowerMapPage:_refresh()
  local heroIdList = Logic.towerLogic:GetHeroIdList(FleetType.LimitTower)
  if 0 < #heroIdList then
    UIHelper.OpenPage("TowerLockedPage", {
      fleetType = FleetType.LimitTower
    })
  end
  local heroIdList = Data.towerActivityData:GetHeroIdList()
  if 0 < #heroIdList then
    Data.towerActivityData:ResetHeroIdList()
  end
  self:ShowPath()
  self:ShowArrow()
  for copyId, tablePart in pairs(self.tablePart) do
    self:ShowPoint(copyId, tablePart)
  end
  self:ShowLeftTime()
  local timer = self:CreateTimer(function()
    self:ShowLeftTime()
  end, 0.5, -1)
  self:StartTimer(timer)
  self:ShowEnter()
  self:ShowHistory()
  self:bu_buff_close()
  local widgets = self:GetWidgets()
  local rate = Logic.towerActivityLogic:GetAddition() * 100
  if 0 < rate then
    rate = string.format("%.1f", rate)
    UIHelper.SetLocText(widgets.tx_tip, 2900006, rate .. "%")
  else
    UIHelper.SetLocText(widgets.tx_tip, 2900022)
  end
end

function ATowerMapPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.bu_buff, self.bu_buff, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_buff_close, self.bu_buff_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_reset, self.bu_reset, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_instruction, self.bu_instruction, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_note, self.bu_note, self)
  self:RegisterEvent(LuaEvent.UpdateTowerActivityInfo, self._refresh, self)
  self:RegisterEvent(LuaEvent.TowerActivityReceiveBuff, self._refresh, self)
  self:RegisterEvent(LuaEvent.TowerActivityQuickPass, self._refreshQuick, self)
end

function ATowerMapPage:btn_close()
  UIHelper.ClosePage(self.chapterTowerConfig.page_name)
end

function ATowerMapPage:bu_reset()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.towerActivityService:SendReset()
      end
    end
  }
  noticeManager:ShowMsgBox(2900001, tabParams)
end

function ATowerMapPage:bu_buff()
  local widgets = self:GetWidgets()
  local buffDes = Logic.towerActivityLogic:GetAllBuffDes()
  widgets.buff.gameObject:SetActive(0 < #buffDes)
  if #buffDes <= 0 then
    noticeManager:ShowTipById(2900019)
    return
  end
  UIHelper.CreateSubPart(widgets.tx_buff, widgets.content_buff, #buffDes, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_buff, buffDes[index].str)
  end)
end

function ATowerMapPage:bu_buff_close()
  local widgets = self:GetWidgets()
  widgets.buff.gameObject:SetActive(false)
end

function ATowerMapPage:bu_instruction()
  UIHelper.OpenPage("ATowerHelpPage")
end

function ATowerMapPage:bu_note()
  local copyList = Data.towerActivityData:GetAllCopyList()
  table.remove(copyList, 1)
  if #copyList <= 0 then
    noticeManager:ShowTipById(2900013)
    return
  end
  UIHelper.OpenPage("ATowerCopyDetailsPage", {
    chapterConfig = self.chapterConfig
  })
end

function ATowerMapPage:setPathMap(pathMap, pathMapPart, src, dst)
  local line = src .. "_" .. dst .. "_l"
  local line_revert = dst .. "_" .. src .. "_l"
  pathMap[line] = true
  pathMap[line_revert] = true
end

function ATowerMapPage:ShowLeftTime()
  local widgets = self:GetWidgets()
  local timeLeft = Logic.towerActivityLogic:GetLeftTime()
  if timeLeft <= 0 then
    timeLeft = 0
  end
  local timeFormat = time.getTimeStringFontTwo(timeLeft)
  UIHelper.SetLocText(widgets.tx_time, 2900012, timeFormat)
  local timeResetLeft = Logic.towerActivityLogic:GetResetLeftTime()
  if timeResetLeft <= 0 then
    timeResetLeft = 0
  end
  local timeFormat = time.getTimeStringFontTwo(timeResetLeft)
  UIHelper.SetText(widgets.tx_reset_time, timeFormat)
end

function ATowerMapPage:ShowEnter()
  local widgets = self:GetWidgets()
  local activityId = self.chapterTowerConfig.activity_id
  local config = configManager.GetDataById("config_activity", activityId)
  if #config.red_dot > 0 then
    self:RegisterRedDotById(widgets.redDot, config.red_dot, activityId)
  end
  UGUIEventListener.AddButtonOnClick(widgets.activity, function()
    moduleManager:JumpToFunc(FunctionID.Activity, activityId)
  end)
end

function ATowerMapPage:ShowHistory()
  local widgets = self:GetWidgets()
  local passNum = Logic.towerActivityLogic:GetPassNum()
  local historyMax = Data.towerActivityData:GetHistoryMax()
  UIHelper.SetLocText(widgets.tx_max_now, 2900007, passNum)
  UIHelper.SetLocText(widgets.tx_max_history, 2900008, math.max(passNum, historyMax))
end

return ATowerMapPage
