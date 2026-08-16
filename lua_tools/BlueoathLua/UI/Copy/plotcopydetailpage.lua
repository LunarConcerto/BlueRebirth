local PlotCopyDetailPage = class("UI.Copy.PlotCopyDetailPage", LuaUIPage)
local PLOT_COPY_MAX = 6

function PlotCopyDetailPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.pageInfo = nil
  self.displayPage = nil
  self.currDisplayPage = nil
  self.isNew = true
  self.selectLevel = 0
  self.plotDetailId = 0
  self.displayType = 0
  self.actId = 0
  self.chapterConf = nil
end

function PlotCopyDetailPage:DoOnOpen()
  if self.param and self.param.enter == ActEnter.Memory then
    self.enter = ActEnter.Memory
    self:DoOnOpenMemory()
  else
    self.enter = ActEnter.Normal
    self:DoOnOpenNormal()
  end
end

function PlotCopyDetailPage:DoOnOpenNormal()
  local tabParam = self:GetParam()
  self.displayType = tabParam[1] or 0
  self.m_tabWidgets.obj_chapter:SetActive(self.displayType ~= CopyDisplayType.ActivityCopy)
  self.m_tabWidgets.obj_actChapter:SetActive(self.displayType == CopyDisplayType.ActivityCopy)
  self:OpenTopPage("PlotCopyDetailPage", 1, "\230\180\187\229\138\168\229\137\167\230\131\133", self, true)
  if self.displayType == CopyDisplayType.ActivityCopy then
    self.actId = tabParam[2]
    self.chapterConf = Logic.activityLogic:GetActPlotChapter(self.actId)
    eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
      TitleName = "\230\180\187\229\138\168\229\137\167\230\131\133",
      ChapterId = self.chapterConf.id
    })
  else
    self.chapterConf = tabParam.ChapterConf
    eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
      TitleName = "\229\137\167\230\131\133",
      ChapterId = self.chapterConf.id
    })
    eventManager:SendEvent(LuaEvent.ShowOpenModule)
  end
  SoundManager.Instance:PlayMusic(self.chapterConf.leveldetailsbgm)
  self:_ShowPlotItem()
end

function PlotCopyDetailPage:DoOnOpenMemory()
  self.displayType = CopyDisplayType.ActivityCopy
  self.m_tabWidgets.obj_chapter:SetActive(self.displayType ~= CopyDisplayType.ActivityCopy)
  self.m_tabWidgets.obj_actChapter:SetActive(self.displayType == CopyDisplayType.ActivityCopy)
  self:OpenTopPage("PlotCopyDetailPage", 1, "\230\180\187\229\138\168\229\137\167\230\131\133", self, true)
  local chapterId = self.param.chapterId
  self.chapterConf = configManager.GetDataById("config_chapter", chapterId)
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = "\230\180\187\229\138\168\229\137\167\230\131\133",
    ChapterId = self.chapterConf.id
  })
  SoundManager.Instance:PlayMusic(self.chapterConf.leveldetailsbgm)
  local pos = self.m_tabWidgets.obj_actChapter.transform.localPosition
  self.m_tabWidgets.obj_actChapter.transform.localPosition = Vector3.New(pos.x, 0, pos.z)
  self:_ShowPlotItem()
end

function PlotCopyDetailPage:_ShowPlotItem()
  self.isNew = true
  local isOpenNew = false
  self.pageInfo, self.displayPage, isOpenNew = Logic.copyLogic:GetPlotCopyChapter(self.chapterConf, self.displayType)
  if #self.pageInfo[self.displayPage] == PLOT_COPY_MAX and self.pageInfo[self.displayPage + 1] ~= nil and self.pageInfo[self.displayPage][PLOT_COPY_MAX] == self.plotDetailId then
    self.displayPage = self.displayPage + 1
  end
  self.currDisplayPage = Logic.copyLogic:GetCurrDisplayPlotIndex()
  if self.currDisplayPage == nil then
    self.currDisplayPage = self.displayPage
  elseif self.isNew and isOpenNew then
    self.currDisplayPage = self.displayPage
    self.isNew = false
  end
  self.m_tabWidgets.btn_left.interactable = self.currDisplayPage ~= 1
  self.m_tabWidgets.btn_right.interactable = self.currDisplayPage ~= #self.pageInfo
  Logic.copyLogic:SetCurrDisplayPlotIndex(self.currDisplayPage)
  self:_UpdateInfo()
end

function PlotCopyDetailPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_left, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_right, self._ClickRight, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeTip, self._CloseOpneTip, self)
  self:RegisterEvent(LuaEvent.GetCopyData, self._UpdateInfo, self)
  self:RegisterEvent(LuaEvent.PlotTriggerEnd, self._PlotTriggerEnd, self)
end

function PlotCopyDetailPage:_CloseOpneTip()
  self.m_tabWidgets.btn_closeTip.gameObject:SetActive(false)
end

function PlotCopyDetailPage:_PlotTriggerEnd()
  SoundManager.Instance:PlayMusic(self.chapterConf.leveldetailsbgm)
end

function PlotCopyDetailPage:_UpdateInfo()
  if self.enter == ActEnter.Memory then
    self:_MemoryCreateCopyPlotInfo()
  elseif self.displayType ~= CopyDisplayType.ActivityCopy then
    self:_CreateCopyPlotInfo()
  else
    self:_ActCreateCopyPlotInfo()
    return
  end
  local isNew, info = Logic.copyLogic:GetNewChapter()
  self.m_tabWidgets.btn_closeTip.gameObject:SetActive(isNew)
  if info then
    self.m_tabWidgets.txt_opnName.text = info.title .. " " .. info.name
  end
end

function PlotCopyDetailPage:_CreateCopyPlotInfo()
  local levelList = self.pageInfo[self.currDisplayPage]
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_copyPlotItem, self.m_tabWidgets.trans_copyPlotContent, #levelList, function(nIndex, tabPart)
    local copyDesConf = Logic.copyLogic:GetCopyDesConfig(levelList[nIndex])
    tabPart.obj_story:SetActive(copyDesConf.copy_display_type == 2 or copyDesConf.copy_display_type == Copy_Display_Type.BossCopy)
    tabPart.obj_battle:SetActive(copyDesConf.copy_display_type == 1)
    tabPart.im_game:SetActive(copyDesConf.copy_display_type == Copy_Display_Type.MiniGame)
    local copyData = Data.copyData:GetCopyInfoById(levelList[nIndex])
    tabPart.obj_clear:SetActive(copyData ~= nil and copyData.FirstPassTime ~= 0)
    tabPart.obj_lock:SetActive(copyData == nil)
    UIHelper.SetImage(tabPart.im_icon, copyDesConf.copy_thumbnail_before)
    tabPart.txt_name.text = copyDesConf.name
    UGUIEventListener.AddButtonOnClick(tabPart.btn_plot.gameObject, function()
      if copyData == nil then
        noticeManager:OpenTipPage(self, UIHelper.GetString(961002))
      else
        self.selectLevel = nIndex
        if copyDesConf.copy_display_type == Copy_Display_Type.SeaCopy then
          local isHasFleet = Logic.fleetLogic:IsHasFleet()
          if not isHasFleet then
            noticeManager:OpenTipPage(self, 110007)
            return
          end
          self:_OpenLevelPage(copyData, levelList[nIndex])
        elseif copyDesConf.copy_display_type == Copy_Display_Type.PlotCopy then
          self:_OpenPlotPage(copyData.BaseId)
        elseif copyDesConf.copy_display_type == Copy_Display_Type.MiniGame then
          UIHelper.OpenPage("MiniGamePage", {
            copyId = levelList[nIndex]
          })
        elseif copyDesConf.copy_display_type == Copy_Display_Type.BossCopy then
          moduleManager:JumpToFunc(FunctionID.BossCopy)
        end
      end
    end)
  end)
end

function PlotCopyDetailPage:_ActCreateCopyPlotInfo()
  local levelList = self.pageInfo[self.currDisplayPage]
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_actCopyPlotItem, self.m_tabWidgets.trans_actCopyPlotContent, #levelList, function(nIndex, tabPart)
    local copyDesConf = Logic.copyLogic:GetCopyDesConfig(levelList[nIndex])
    tabPart.obj_story:SetActive(copyDesConf.copy_display_type == 2)
    tabPart.obj_battle:SetActive(copyDesConf.copy_display_type == 1)
    tabPart.im_game:SetActive(copyDesConf.copy_display_type == Copy_Display_Type.MiniGame)
    local copyData = Data.copyData:GetCopyInfoById(levelList[nIndex])
    tabPart.obj_clear:SetActive(copyData ~= nil and copyData.FirstPassTime ~= 0)
    tabPart.obj_lock:SetActive(copyData == nil)
    UIHelper.SetImage(tabPart.im_icon, copyDesConf.copy_thumbnail_before)
    tabPart.txt_name.text = copyDesConf.name
    UGUIEventListener.AddButtonOnClick(tabPart.btn_plot.gameObject, function()
      if copyData == nil then
        noticeManager:OpenTipPage(self, UIHelper.GetString(961002))
        return
      end
      if not Logic.copyLogic:CheckOpenByCopyId(copyData.BaseId, true) then
        return
      end
      self.selectLevel = nIndex
      if copyDesConf.copy_display_type == 1 then
        local isHasFleet = Logic.fleetLogic:IsHasFleet()
        if not isHasFleet then
          noticeManager:OpenTipPage(self, 110007)
          return
        end
        self:_OpenLevelPage(copyData, levelList[nIndex])
      elseif copyDesConf.copy_display_type == Copy_Display_Type.PlotCopy then
        self:_OpenPlotPage(copyData.BaseId)
      elseif copyDesConf.copy_display_type == Copy_Display_Type.MiniGame then
        UIHelper.OpenPage("MiniGamePage", {
          copyId = levelList[nIndex]
        })
      end
    end)
  end)
end

function PlotCopyDetailPage:_MemoryCreateCopyPlotInfo()
  local levelList = self.pageInfo[self.currDisplayPage]
  local chapterId = self.chapterConf.id
  local achiveIndex = Data.illustrateData:GetMemoryIndexByChapterId(chapterId)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_actCopyPlotItem, self.m_tabWidgets.trans_actCopyPlotContent, #levelList, function(nIndex, tabPart)
    local copyId = levelList[nIndex]
    local copyDesConf = Logic.copyLogic:GetCopyDesConfig(levelList[nIndex])
    tabPart.obj_story:SetActive(copyDesConf.copy_display_type == 2 or copyDesConf.copy_display_type == Copy_Display_Type.BossCopy)
    tabPart.obj_battle:SetActive(copyDesConf.copy_display_type == 1)
    tabPart.im_game:SetActive(copyDesConf.copy_display_type == Copy_Display_Type.MiniGame)
    local copyData = Data.copyData:GetCopyInfoById(levelList[nIndex])
    local index = PLOT_COPY_MAX * (self.currDisplayPage - 1) + nIndex
    tabPart.obj_clear:SetActive(index <= achiveIndex)
    tabPart.obj_lock:SetActive(index > achiveIndex)
    UIHelper.SetImage(tabPart.im_icon, copyDesConf.copy_thumbnail_before)
    tabPart.txt_name.text = copyDesConf.name
    UGUIEventListener.AddButtonOnClick(tabPart.btn_plot.gameObject, function()
      if index > achiveIndex then
        noticeManager:OpenTipPage(self, UIHelper.GetString(500002))
      else
        self.selectLevel = nIndex
        if copyDesConf.copy_display_type == Copy_Display_Type.SeaCopy then
          local isHasFleet = Logic.fleetLogic:IsHasFleet()
          if not isHasFleet then
            noticeManager:OpenTipPage(self, 110007)
            return
          end
          self:_OpenLevelPageMemory(copyId, BattleMode.Memory)
        elseif copyDesConf.copy_display_type == Copy_Display_Type.PlotCopy then
          self:_OpenPlotPage(copyId, BattleMode.Memory)
        elseif copyDesConf.copy_display_type == Copy_Display_Type.MiniGame then
          UIHelper.OpenPage("MiniGamePage", {
            copyId = copyId,
            battleMode = BattleMode.Memory
          })
        end
      end
    end)
  end)
end

function PlotCopyDetailPage:_OpenLevelPageMemory(copyId, battleMode)
  local copyData = Logic.copyLogic:MakeDefaultCopyInfo(copyId)
  self:_OpenLevelPage(copyData, copyId, battleMode)
end

function PlotCopyDetailPage:_OpenLevelPage(copyData, plotCopyId, battleMode)
  local areaConfig = {
    copyType = CopyType.COMMONCOPY,
    tabSerData = copyData,
    chapterId = Logic.copyLogic:GetChapterIdByCopyId(plotCopyId),
    IsRunningFight = copyData.IsRunningFight,
    copyId = plotCopyId,
    actId = self.actId,
    battleMode = battleMode or BattleMode.Normal
  }
  Logic.copyLogic:SetEnterLevelInfo(true)
  UIHelper.OpenPage("LevelDetailsPage", areaConfig)
end

function PlotCopyDetailPage:_OpenPlotPage(baseId, battleMode)
  self.plotDetailId = baseId
  local displayId = baseId
  local prefsKey = "plotcopy_" .. tostring(displayId)
  local enterTime = PlayerPrefs.GetInt(prefsKey, 1)
  local dotInfo = {
    info = "start_plot",
    copy_displayID = displayId,
    times = tostring(enterTime)
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
  enterTime = enterTime + 1
  PlayerPrefs.SetInt(prefsKey, enterTime)
  PlayerPrefs.Save()
  plotManager:OpenPlotByType(PlotTriggerType.plot_copy_display_trigger, baseId, battleMode)
end

function PlotCopyDetailPage:_ClickLeft()
  if self.currDisplayPage == 1 then
    return
  end
  self.currDisplayPage = self.currDisplayPage - 1
  self:_UpdateItem()
  Logic.copyLogic:SetCurrDisplayPlotIndex(self.currDisplayPage)
end

function PlotCopyDetailPage:_ClickRight()
  if self.currDisplayPage == #self.pageInfo then
    return
  end
  self.currDisplayPage = self.currDisplayPage + 1
  self:_UpdateItem()
  Logic.copyLogic:SetCurrDisplayPlotIndex(self.currDisplayPage)
end

function PlotCopyDetailPage:_UpdateItem()
  self.m_tabWidgets.btn_left.interactable = self.currDisplayPage ~= 1
  self.m_tabWidgets.btn_right.interactable = self.currDisplayPage ~= #self.pageInfo
  if self.enter == ActEnter.Memory then
    self:_MemoryCreateCopyPlotInfo()
  elseif self.displayType ~= CopyDisplayType.ActivityCopy then
    self:_CreateCopyPlotInfo()
  else
    self:_ActCreateCopyPlotInfo()
  end
end

function PlotCopyDetailPage:DoOnHide()
end

function PlotCopyDetailPage:DoOnClose()
  Logic.copyLogic:SetCurrDisplayPlotIndex(nil)
end

return PlotCopyDetailPage
