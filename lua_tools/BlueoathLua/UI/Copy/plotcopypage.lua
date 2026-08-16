local PlotCopyPage = class("UI.Copy.PlotCopyPage", LuaUIPage)

function PlotCopyPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.selectChapter = 0
  self.plotChapter = nil
  self.m_classId = 0
  self.m_chapter_container = {}
end

function PlotCopyPage:DoOnOpen()
  self:OpenTopPage("PlotCopyPage", 1, UIHelper.GetString(920000179), self, true)
  self.m_classId = self:GetParam().classId
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = UIHelper.GetString(920000188),
    CloseFunc = nil
  })
  self.tabPlotCopyData = Data.copyData:GetPlotCopyServiceData()
  self.selectChapter = Logic.copyLogic:GetSelectChapter(Logic.copyLogic.SelectCopyType.PlotCopy)
  self:_CreateCopyPlotItem()
  local scrollPos = Logic.copyLogic:GetPlotScrollPos()
  self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition = scrollPos
  self.plotChapter = Logic.copyLogic:GetPassPlotChapterInfo()
  self:_UpdateLeftRightBtn(scrollPos)
  self:_Retention()
end

function PlotCopyPage:_Retention()
  local dotUIInfo = {
    info = "ui_copy_story"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotUIInfo)
end

function PlotCopyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_left, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_right, self._ClickRight, self)
  self:RegisterEvent(LuaEvent.UpdatePlotCopy, self.DoOnOpen, self)
  self:RegisterEvent(LuaEvent.RefreshLockCopy, self._RefreshLockCopy, self)
end

function PlotCopyPage:_RefreshLockCopy()
  if self.m_chapter_container and #self.m_chapter_container > 0 then
    local tabPassChapterInfo = Logic.copyLogic:GetPassChapterInfoByClassId(self.m_classId)
    for i = 1, #self.m_chapter_container do
      local tabPart = self.m_chapter_container[i]
      local firstDisplayId = Logic.copyLogic:GetChatperFirshCopy(tabPassChapterInfo[i].id)
      local serverCopyData = Data.copyData:GetCopyInfoById(firstDisplayId)
      if serverCopyData then
        tabPart.im_lockAndCost:SetActive(false)
      end
    end
  end
end

function PlotCopyPage:_CreateCopyPlotItem()
  local tabPassChapterInfo = Logic.copyLogic:GetPassChapterInfoByClassId(self.m_classId)
  tabPassChapterInfo = self:_GetOpenPlotChapter(tabPassChapterInfo)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_copyPlotItem, self.m_tabWidgets.trans_copyPlotContent, #tabPassChapterInfo, function(nIndex, tabPart)
    self.m_chapter_container[nIndex] = tabPart
    UIHelper.SetImage(tabPart.im_icon, tabPassChapterInfo[nIndex].plot_copy_cover)
    tabPart.txt_name.text = tabPassChapterInfo[nIndex].title .. " " .. tabPassChapterInfo[nIndex].name
    local levelLen = tabPassChapterInfo[nIndex].level_list
    local openLen = self:_ChapterOpenNum(levelLen)
    tabPart.txt_num.text = openLen .. "/" .. #levelLen
    self.selectChapter = self.selectChapter == 0 and #tabPassChapterInfo or self.selectChapter
    tabPart.obj_select:SetActive(nIndex == self.selectChapter)
    local lock = Logic.copyLogic:CheckPlotChapterLock(tabPassChapterInfo[nIndex].id)
    tabPart.obj_lock:SetActive(lock)
    Logic.copyLogic:CheckPlotChapterItemLock(tabPassChapterInfo[nIndex].id)
    self:RegisterRedDot(tabPart.redDot, tabPassChapterInfo[nIndex].id)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_plot.gameObject, function()
      self:_ClickChapter(tabPassChapterInfo, nIndex)
    end)
    local jumpDetailsId = Logic.copyLogic:CheckJumpPlotDetails()
    if jumpDetailsId ~= 0 and jumpDetailsId == tabPassChapterInfo[nIndex].id then
      self:_ClickChapter(tabPassChapterInfo, nIndex)
      Logic.copyLogic:SetJumpPlotDetails(0)
    end
  end)
end

function PlotCopyPage:_GetOpenPlotChapter(info)
  local data = info
  local dataTab = {}
  for i = 1, #data do
    if Logic.copyLogic:_CheckPlotCopyIsOpen(data[i].id) then
      table.insert(dataTab, data[i])
    end
  end
  return dataTab
end

function PlotCopyPage:_SendUnLockCopyRequest(copyId)
  Service.copyService:UnLockCopy(copyId)
end

function PlotCopyPage:_ClickChapter(tabPassChapterInfo, nIndex)
  local lock, level = Logic.copyLogic:CheckPlotChapterLock(tabPassChapterInfo[nIndex].id)
  if lock then
    local str = string.format(UIHelper.GetString(961001), level)
    noticeManager:OpenTipPage(self, str)
  else
    local tabParam = {
      ChapterConf = tabPassChapterInfo[nIndex]
    }
    Logic.copyLogic:SetPlotScrollPos(self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition)
    Logic.copyLogic:SetSelectChapter(Logic.copyLogic.SelectCopyType.PlotCopy, nIndex)
    Logic.copyLogic:SetSelectPlotDetail(tabParam)
    UIHelper.OpenPage("PlotCopyDetailPage", tabParam)
  end
end

function PlotCopyPage:_ChapterOpenNum(levelLen)
  local openNum = 0
  for i = 1, #levelLen do
    local copyCof = Data.copyData:GetCopyInfoById(levelLen[i])
    local isPass = Logic.copyLogic:IsCopyPassById(levelLen[i])
    if isPass then
      openNum = openNum + 1
    end
  end
  return openNum
end

function PlotCopyPage:_PlotCopyChapterOpenNum(levelList)
  local num = 0
  for k, v in pairs(levelList) do
    local plot = self.tabPlotCopyData[v]
    if plot ~= nil and plot.FirstPassTime ~= 0 then
      num = num + 1
    end
  end
  return num
end

function PlotCopyPage:_ClickLeft()
  local curPos = self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition
  local nextPos = curPos - 5 * (5 / #self.plotChapter)
  nextPos = nextPos < 0 and 0 or nextPos
  self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition = nextPos
  self:_UpdateLeftRightBtn(nextPos)
end

function PlotCopyPage:_ClickRight()
  local curPos = self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition
  local nextPos = curPos + 5 * (5 / #self.plotChapter)
  nextPos = 1 < nextPos and 1 or nextPos
  self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition = nextPos
  self:_UpdateLeftRightBtn(nextPos)
end

function PlotCopyPage:_UpdateLeftRightBtn(nextPos)
  if #self.plotChapter <= 5 then
    self.m_tabWidgets.btn_left.interactable = false
    self.m_tabWidgets.btn_right.interactable = false
  else
    self.m_tabWidgets.btn_left.interactable = nextPos ~= 0
    self.m_tabWidgets.btn_right.interactable = nextPos ~= 1
  end
end

return PlotCopyPage
