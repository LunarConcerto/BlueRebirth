local SeaModeChoose = class("UI.Copy.SeaModeChoose")
local BgSize = {
  [2] = 187,
  [4] = 287
}

function SeaModeChoose:Init(owner, widgets)
  self.page = owner
  self.widgetsTab = widgets
  self.battleModeInfo = {}
  self:RegisterAllEvent()
end

function SeaModeChoose:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_modeClose, self._CloseModeChoose, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_showMode, self._OpenModelChoose, self)
end

function SeaModeChoose:ShowChooseMode(chapterId, copyType)
  self.chapterId = chapterId
  self.copyType = copyType
  self.copySerData = Data.copyData:GetCopyInfo()
  local configInfoTab = Logic.copyLogic:GetChapterBelong(chapterId)
  self.widgetsTab.obj_modeTog:SetActive(configInfoTab ~= nil)
  if configInfoTab == nil then
    Logic.copyLogic:SetCurrBattleMode(self.copyType, SeaCopyStage.Day)
    self.page:_SwitchTogs(0)
    return
  end
  self.battleModeInfo = {}
  for _, info in pairs(configInfoTab) do
    table.insert(self.battleModeInfo, info)
  end
  self:_CloseModeChoose()
  self:_CreateChooseTog()
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
    if nIndex == Logic.copyLogic:GetCurrBattleMode(self.copyType) then
      UIHelper.SetImage(self.widgetsTab.img_selectModeC, typeConfig.check_image)
    end
    table.insert(self.page.togPart, tabPart)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.widgetsTab.tog_modeGroup, self.page, "", self.page._SwitchTogs)
  self.widgetsTab.tog_modeGroup:SetActiveToggleIndex(Logic.copyLogic:GetCurrBattleMode(self.copyType) - 1)
  self:_SetActiveTog(self.chapterId)
end

function SeaModeChoose:_ClearToggle()
  for i, _ in ipairs(self.battleModeInfo) do
    self.widgetsTab.tog_modeGroup:RemoveToggleUnActive(i - 1)
  end
  self.widgetsTab.tog_modeGroup:ClearToggles()
end

function SeaModeChoose:_SetActiveTog(chapterId)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  for i, v in ipairs(chapterConfig.belong_chapter_list) do
    if not self:_CheckChapterOpen(v) then
      self.widgetsTab.tog_modeGroup:ResigterToggleUnActive(i - 1, function()
        self:_StopToggle(v)
      end)
    else
      self.widgetsTab.tog_modeGroup:RemoveToggleUnActive(i - 1)
    end
  end
end

function SeaModeChoose:_CheckChapterOpen(chapterId)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  return self.copySerData[chapterConfig.level_list[1]] ~= nil
end

function SeaModeChoose:_StopToggle(id)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(id)
  local currName = chapterConfig.title
  local nameStr = ""
  for _, v in ipairs(chapterConfig.open_chapter) do
    local conf = Logic.copyLogic:GetChaperConfById(v)
    if nameStr == "" then
      nameStr = conf.title
    else
      nameStr = nameStr .. "\227\128\129" .. conf.title
    end
  end
  local str = string.format(UIHelper.GetString(100028), nameStr, currName)
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

return SeaModeChoose
