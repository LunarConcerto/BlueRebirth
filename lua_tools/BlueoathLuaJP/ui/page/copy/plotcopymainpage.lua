local PlotCopyMainPage = class("UI.Copy.PlotCopyMainPage", LuaUIPage)

function PlotCopyMainPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.selectChapter = 0
  self.plotChapter = nil
  if not self.m_ChapterPlotData then
    self.m_ChapterPlotData = Logic.plotCopyLogic:LoadChapterPlotTypeConfigData()
  end
  self.tabpartContainer = {}
end

function PlotCopyMainPage:DoOnOpen()
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = UIHelper.GetString(920000188),
    CloseFunc = nil
  })
  self.tabPlotCopyData = Data.copyData:GetPlotCopyServiceData()
  self.selectChapter = Logic.copyLogic:GetSelectChapter(Logic.copyLogic.SelectCopyType.PlotMainCopy)
  self:_CreateCopyPlotItem()
  local scrollPos = Logic.copyLogic:GetPlotScrollPos()
  self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition = scrollPos
  self.plotChapter = Logic.copyLogic:GetPassPlotChapterInfo()
  self:_UpdateLeftRightBtn(scrollPos)
  self:_Retention()
  self.param = self:GetParam()
end

function PlotCopyMainPage:_Retention()
  local dotUIInfo = {
    info = "ui_copy_story"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotUIInfo)
end

function PlotCopyMainPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_left, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_right, self._ClickRight, self)
  self:RegisterEvent(LuaEvent.UpdatePlotCopy, self.DoOnOpen, self)
end

function PlotCopyMainPage:_CreateCopyPlotItem()
  local _, farestChapterId = Logic.copyLogic:GetCurPlotChapterSection()
  if self.m_ChapterPlotData then
    table.sort(self.m_ChapterPlotData, function(l, r)
      return l.show_id < r.show_id
    end)
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_copyPlotItem, self.m_tabWidgets.trans_copyPlotContent, #self.m_ChapterPlotData, function(index, tabPart)
      UIHelper.SetImage(tabPart.im_icon, self.m_ChapterPlotData[index].image)
      UIHelper.SetText(tabPart.tx_mainPlotName, self.m_ChapterPlotData[index].name)
      local tabPassChapterInfo = Logic.copyLogic:GetAllPlotChapterInfoById(self.m_ChapterPlotData[index].id)
      self.tabpartContainer[index] = tabPart
      local chapterList = #tabPassChapterInfo
      local passChapter = 0
      for i = 1, #tabPassChapterInfo do
        if tabPassChapterInfo[i].level_list then
          local pass = true
          local chapter_level_list = configManager.GetDataById("config_chapter", tabPassChapterInfo[i].id).level_list
          for j = 1, #chapter_level_list do
            local copyId = tabPassChapterInfo[i].level_list[j]
            local copyCof = Data.copyData:GetCopyInfoById(copyId)
            if not copyCof or copyCof.Pass == false or 0 >= copyCof.FirstPassTime then
              pass = false
              break
            end
          end
          if pass then
            passChapter = passChapter + 1
          end
        end
      end
      local plot_IsOpen = Logic.copyLogic:CheckPlotClassCopyIsOpen(self.m_ChapterPlotData[index].id)
      self.selectChapter = self.selectChapter == 0 and 1 or self.selectChapter
      tabPart.obj_select:SetActive(index == self.selectChapter)
      self:RegisterRedDot(tabPart.redDot, self.m_ChapterPlotData[index].id)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_plot.gameObject, function()
        if plot_IsOpen == false then
          local showText = UIHelper.GetString(931007)
          noticeManager:OpenTipPage(self, showText)
          return
        end
        Logic.copyLogic:SetSelectChapter(Logic.copyLogic.SelectCopyType.PlotMainCopy, index)
        self:SetSelectedIndex(index)
        local id = self.m_ChapterPlotData[index].id
        local param = {classId = id}
        if self.m_ChapterPlotData[index].id == 2 then
          local lastChapterId = 13
          local passLastPlotCopy, _ = Logic.copyLogic:IsChapterPassByChapterId(lastChapterId)
          if not passLastPlotCopy and not self:GetSaveReadData() then
            self:SetReadData()
            local tabParams = {
              msgType = NoticeType.OneButton,
              callback = function(bool)
                UIHelper.OpenPage("PlotCopyPage", param)
              end
            }
            noticeManager:ShowMsgBox(UIHelper.GetString(931010), tabParams)
            return
          end
        end
        UIHelper.OpenPage("PlotCopyPage", param)
      end)
    end)
  end
end

function PlotCopyMainPage:GetSaveReadData()
  local show = false
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  local state = PlayerPrefs.GetInt(uid .. "ReadPlotMainCopy", 0)
  if state == 1 then
    show = true
  end
  return show
end

function PlotCopyMainPage:SetReadData()
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  PlayerPrefs.SetInt(uid .. "ReadPlotMainCopy", 1)
end

function PlotCopyMainPage:SetSelectedIndex(index)
  if self.tabpartContainer then
    for i = 1, #self.tabpartContainer do
      if i == index then
        self.tabpartContainer[i].obj_select:SetActive(true)
      else
        self.tabpartContainer[i].obj_select:SetActive(false)
      end
    end
  end
end

function PlotCopyMainPage:GoPlotCopyPage()
  local param
  self:SendEvent(LuaEvent.OpenPlotCopyPage, param)
end

function PlotCopyMainPage:_ClickChapter(tabPassChapterInfo, nIndex)
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

function PlotCopyMainPage:_PlotCopyChapterOpenNum(levelList)
  local num = 0
  for k, v in pairs(levelList) do
    local plot = self.tabPlotCopyData[v]
    if plot ~= nil and plot.FirstPassTime ~= 0 then
      num = num + 1
    end
  end
  return num
end

function PlotCopyMainPage:_ClickLeft()
  local curPos = self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition
  local nextPos = curPos - 5 * (5 / #self.plotChapter)
  nextPos = nextPos < 0 and 0 or nextPos
  self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition = nextPos
  self:_UpdateLeftRightBtn(nextPos)
end

function PlotCopyMainPage:_ClickRight()
  local curPos = self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition
  local nextPos = curPos + 5 * (5 / #self.plotChapter)
  nextPos = 1 < nextPos and 1 or nextPos
  self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition = nextPos
  self:_UpdateLeftRightBtn(nextPos)
end

function PlotCopyMainPage:_UpdateLeftRightBtn(nextPos)
  if #self.plotChapter <= 5 then
    self.m_tabWidgets.btn_left.interactable = false
    self.m_tabWidgets.btn_right.interactable = false
  else
    self.m_tabWidgets.btn_left.interactable = nextPos ~= 0
    self.m_tabWidgets.btn_right.interactable = nextPos ~= 1
  end
end

function PlotCopyMainPage:OpenPlotCopyDetailPage()
end

return PlotCopyMainPage
