local SeaModeChoose = class("UI.Copy.SeaModeChoose")
local BgSize = {
  [2] = 187,
  [4] = 287
}

function SeaModeChoose:Init(owner, widgets)
  self.page = owner
  self.widgetsTab = widgets
  self.battleModeInfo = {}
  self.copySerData = Data.copyData:GetCopyInfo()
  self:RegisterAllEvent()
end

function SeaModeChoose:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_modeClose, self._CloseModeChoose, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_showMode, self._OpenModelChoose, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_day, function()
    self.page:_SwitchTogs(0, true)
  end)
  UGUIEventListener.AddOnDrag(self.widgetsTab.im_bg, self.__On2DDragCheck, self)
  UGUIEventListener.AddOnEndDrag(self.widgetsTab.im_bg, self.__OnDragEnd, self)
  eventManager:RegisterEvent(LuaEvent.UpdateActSeaCopyToggle, self._UpdateActInfo, self)
end

function SeaModeChoose:ShowChooseMode(chapterId, copyType)
  self.chapterId = chapterId
  local chapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  self.copyType = copyType
  self.widgetsTab.obj_modeTog:SetActive(false)
  self.widgetsTab.btn_new.gameObject:SetActive(false)
  self.widgetsTab.btn_day.gameObject:SetActive(false)
  self.widgetsTab.btn_new1.gameObject:SetActive(false)
  self.widgetsTab.btn_day1.gameObject:SetActive(false)
  local configInfoTab = Logic.copyLogic:GetChapterBelong(chapterId)
  if configInfoTab == nil then
    Logic.copyLogic:SetCurrBattleMode(self.copyType, SeaCopyStage.Day)
    self.page:_SwitchTogs(0, false)
    return
  end
  local initNewCopyId
  for _, info in pairs(configInfoTab) do
    if info.chapter_type == ChildChapterType.New then
      initNewCopyId = info.id
    end
  end
  self.modeAllChapter = Logic.copyLogic:GetBattleModeChapter(self.copyType, chapterConfig.chapter_type)
  self.initChapterId = #self.modeAllChapter ~= 0 and self.modeAllChapter[1] or initNewCopyId
  local uid = Data.userData:GetUserUid()
  local selectNewId = PlayerPrefs.GetInt(uid .. "SeaCopyPageByMode" .. ChildChapterType.New .. self.copyType, self.initChapterId)
  self.newBattleMode = Logic.copyLogic:GetChaperConfById(selectNewId)
  configInfoTab = Logic.copyLogic:GetChapterBelong(selectNewId)
  self.battleModeInfo = {}
  for _, info in pairs(configInfoTab) do
    if info.chapter_type ~= ChildChapterType.Day then
      table.insert(self.battleModeInfo, info)
    end
  end
  self.widgetsTab.obj_modeTog:SetActive(1 < #self.battleModeInfo)
  if #self.battleModeInfo ~= 0 then
    self:_CreateChooseTog()
    self:_CloseModeChoose()
  end
end

function SeaModeChoose:_CreateChooseTog()
  self:_ClearToggle()
  self.page.togPart = {}
  self.widgetsTab.rect_imgBG.sizeDelta = Vector2.New(BgSize[#self.battleModeInfo], 97)
  UIHelper.CreateSubPart(self.widgetsTab.obj_modeItem, self.widgetsTab.trans_modeGrid, #self.battleModeInfo, function(nIndex, tabPart)
    local chapterInfo = self.battleModeInfo[nIndex]
    local battleMode = chapterInfo.chapter_type + 1
    local typeConfig = Logic.copyLogic:GetTypeInfoById(battleMode)
    tabPart.txt_name.text = typeConfig.desc
    UIHelper.SetImage(tabPart.img_togBg, typeConfig.unchecked_image)
    UIHelper.SetImage(tabPart.img_togCheck, typeConfig.check_image)
    tabPart.img_togBg.gameObject:SetActive(self:_CheckChapterOpen(chapterInfo.id))
    tabPart.img_lock.gameObject:SetActive(not self:_CheckChapterOpen(chapterInfo.id))
    self.widgetsTab.tog_modeGroup:RegisterToggle(tabPart.tog_mode)
    if battleMode == SeaCopyStage.New then
      UIHelper.SetImage(self.widgetsTab.img_selectModeC, typeConfig.check_image)
    end
    table.insert(self.page.togPart, tabPart)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.widgetsTab.tog_modeGroup, self.page, nil, self.page.ChangeBattleMode)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(self.chapterId)
  if chapterConfig.chapter_type == ChildChapterType.Day then
    self.page:_SwitchTogs(0, false)
  elseif chapterConfig.chapter_type ~= ChildChapterType.New and Logic.copyLogic:GetCurrBattleMode(self.copyType) ~= SeaCopyStage.New then
    self.widgetsTab.tog_modeGroup:SetActiveToggleIndex(Logic.copyLogic:GetCurrBattleMode(self.copyType) - 1)
  else
    self:_ChangeNewBattle(false)
  end
  self:_SetActiveTog(self.chapterId)
end

function SeaModeChoose:_ClearToggle()
  for i, _ in ipairs(self.battleModeInfo) do
    self.widgetsTab.tog_modeGroup:RemoveToggleUnActive(i - 1)
  end
  self.widgetsTab.tog_modeGroup:ClearToggles()
end

function SeaModeChoose:_SetActiveTog()
  for i, v in ipairs(self.battleModeInfo) do
    if not self:_CheckChapterOpen(v.id) then
      self.widgetsTab.tog_modeGroup:ResigterToggleUnActive(i - 1, function()
        self:_StopToggle(v.id)
      end)
    else
      self.widgetsTab.tog_modeGroup:RemoveToggleUnActive(i - 1)
    end
  end
end

function SeaModeChoose:_CheckChapterOpen(chapterId)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  local modeAllChapter = Logic.copyLogic:GetBattleModeChapter(self.copyType, chapterConfig.chapter_type)
  if #modeAllChapter == 0 then
    return false
  end
  local initChapterId = modeAllChapter[1]
  local config = Logic.copyLogic:GetChaperConfById(initChapterId)
  return self.copySerData[config.level_list[1]] ~= nil
end

function SeaModeChoose:_StopToggle(id)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(id)
  local currName = chapterConfig.title
  local str, nameStr = "", ""
  for _, v in ipairs(chapterConfig.open_chapter) do
    local conf = Logic.copyLogic:GetChaperConfById(v)
    if nameStr == "" then
      nameStr = conf.title .. "\194\183" .. conf.name
    else
      nameStr = nameStr .. "\227\128\129" .. conf.title
    end
  end
  if chapterConfig.chapter_type == ChildChapterType.New then
    str = string.format(UIHelper.GetString(131018), nameStr)
    local userLv = Data.userData:GetUserLevel()
    local copyDisConf = Logic.copyLogic:GetCopyDConfigById(chapterConfig.level_list[1])
    if Data.userData:GetUserLevel() < copyDisConf.level_limit then
      local dayChapterConf = Logic.copyLogic:GetChaperConfById(chapterConfig.belong_chapter_list[1])
      local passAllCopy = self.copySerData[dayChapterConf.level_list[#dayChapterConf.level_list]] ~= nil
      if passAllCopy then
        str = string.format(UIHelper.GetString(130006), copyDisConf.level_limit)
      end
    end
  else
    str = string.format(UIHelper.GetString(100028), nameStr, currName)
  end
  noticeManager:OpenTipPage(self, str)
end

function SeaModeChoose:_CloseModeChoose()
  self.widgetsTab.obj_modeClose:SetActive(true)
  self.widgetsTab.obj_modelOpen:SetActive(false)
end

function SeaModeChoose:_OpenModelChoose()
  self.widgetsTab.obj_modeClose:SetActive(false)
  self.widgetsTab.obj_modelOpen:SetActive(true)
end

function SeaModeChoose:_ShowNewBattle(chapterId)
  self.chapterId = chapterId
  local chapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  if self.newBattleMode == nil or #chapterConfig.belong_chapter_list == 0 then
    return
  end
  local isDatBattle = chapterConfig.chapter_type == SeaCopyStage.Day - 1
  self.widgetsTab.btn_new.gameObject:SetActive(isDatBattle)
  self.widgetsTab.btn_new1.gameObject:SetActive(isDatBattle)
  self.widgetsTab.btn_day1.gameObject:SetActive(isDatBattle)
  local typeConfig = Logic.copyLogic:GetTypeInfoById(SeaCopyStage.New)
  local chapterOpen = self:_CheckChapterOpen(self.newBattleMode.id)
  local noRecord = Logic.copyLogic:CheckPatrolOpenRecord(self.newBattleMode.id)
  self.widgetsTab.obj_redNew:SetActive(chapterOpen and noRecord)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_new, function()
    self:_ChangeNewBattle(true)
  end)
end

function SeaModeChoose:_ChangeNewBattle(isClick)
  self.widgetsTab.tog_modeGroup:SetActiveToggleIndex(0)
  local chapterOpen = self:_CheckChapterOpen(self.newBattleMode.id)
  if chapterOpen then
    self.page:_PlayBtnAnimation(self.newBattleMode, isClick)
  end
end

function SeaModeChoose:__On2DDragCheck(go, eventData)
  if self.page.canDrag == false then
    return
  end
  local delta = eventData.delta
  local ScaleDrag = configManager.GetDataById("config_parameter", 340).arrValue
  if not IsNil(self.widgetsTab.im_bg.transform) then
    local deviceWidth = UIManager:GetUIWidth()
    local deviceHeight = UIManager:GetUIHeight()
    local targetPos = self.widgetsTab.im_bg.transform.localPosition
    if ScaleDrag[2] ~= 0 and ScaleDrag[1] ~= 0 then
      local x = targetPos.x + delta.x
      targetPos.x = Logic.girlInfoLogic:GetNumberBetween(x, deviceWidth * (ScaleDrag[2] / 10000), deviceWidth * (ScaleDrag[1] / 10000))
    end
    if ScaleDrag[4] ~= 0 and ScaleDrag[3] ~= 0 then
      local y = targetPos.y + delta.y
      targetPos.y = Logic.girlInfoLogic:GetNumberBetween(y, deviceHeight * (ScaleDrag[4] / 10000), deviceHeight * (ScaleDrag[3] / 10000))
    end
    self.widgetsTab.im_bg.transform.localPosition = Vector3.New(targetPos.x, targetPos.y, 0)
    Logic.copyLogic:SetCopyBgPos(self.chapterId, Vector3.New(targetPos.x, targetPos.y, 0))
  end
end

function SeaModeChoose:_UpdateActInfo(param)
  self.chapterId = param[1]
end

function SeaModeChoose:__OnDragEnd()
end

return SeaModeChoose
