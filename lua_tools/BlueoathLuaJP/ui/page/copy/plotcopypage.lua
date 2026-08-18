local PlotCopyPage = class("UI.Copy.PlotCopyPage", LuaUIPage)
local ZONE = 666

function PlotCopyPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.selectChapter = 0
  self.plotChapter = nil
  self.m_classId = 0
  self.m_chapter_container = {}
  self.m_partId = 1
  self.cccurSelectIndex = 1
  self.CanSlide = false
  self.m_part_toggle = {}
  self.hide_enter = false
  self.on_open = false
end

function PlotCopyPage:DoOnOpen()
  self:OpenTopPage("PlotCopyPage", 1, UIHelper.GetString(920000179), self, true)
  local List = Logic.plotCopyLogic:LoadChapterPlotTypeConfigData()
  local oriclassId = Logic.plotCopyLogic:GetPlotCID() ~= 0 and Logic.plotCopyLogic:GetPlotCID() or self:GetParam().classId
  self.m_classId = #List - oriclassId + 1
  self.m_partId = Logic.plotCopyLogic:GetPlotPartID(self.m_classId)
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = UIHelper.GetString(920000188),
    CloseFunc = nil
  })
  self.tabPlotCopyData = Data.copyData:GetPlotCopyServiceData()
  self.cccurSelectIndex = Logic.plotCopyLogic:GetSelectChapterr(self.m_classId, self.m_partId)
  local scrollPos = Logic.copyLogic:GetPlotScrollPos()
  self.plotChapter = Logic.copyLogic:GetPassPlotChapterInfo()
  self:_UpdateLeftRightBtn(scrollPos)
  self:_Retention()
  self:InitToggle()
  self.CanSlide = false
  self.on_open = true
  self.m_tabWidgets.tween_pos.gameObject:SetActive(self.hide_enter == true)
  self.tab_Widgets.obj_plottype:SetActiveToggleIndex(self.m_classId - 1)
  self:__OnSliderCard_Directly()
end

function PlotCopyPage:InitToggle()
  self:InitTogglePlotType()
  self:InitTogglePlotPart()
end

function PlotCopyPage:InitTogglePlotType()
  local widgets = self.tab_Widgets
  local rect = widgets.rect_plottype
  local obj = widgets.tog_zhuxian
  local toggleGroup = widgets.obj_plottype
  toggleGroup:ClearToggles()
  local List = Logic.plotCopyLogic:LoadChapterPlotTypeConfigData()
  UIHelper.CreateSubPart(obj, rect, #List, function(index, luaPart)
    local config = List[#List - index + 1]
    UIHelper.SetImage(luaPart.img_bg, config.image_btn)
    UIHelper.SetImage(luaPart.img_xuanzhong, config.image_btn_push)
    UIHelper.SetText(luaPart.tx_title, config.name)
    self:RegisterRedDot(luaPart.im_redflag, config.id)
    toggleGroup:RegisterToggle(luaPart.select_tog)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(toggleGroup, self, "", function(go, index)
    Logic.plotCopyLogic:SetSelectChapterr(self.m_classId, self.m_partId, self.cccurSelectIndex)
    self.m_classId = List[#List - index].id
    self.m_partId = Logic.plotCopyLogic:GetPlotPartID(self.m_classId)
    self:InitTogglePlotPart()
    self.tab_Widgets.obj_toggle:SetActiveToggleIndex(self.m_partId - 1)
  end)
end

function PlotCopyPage:InitTogglePlotPart()
  local widgets = self.tab_Widgets
  local rect = widgets.rect_toggle
  local obj = widgets.tog_title
  local toggleGroup = widgets.obj_toggle
  toggleGroup:ClearToggles()
  local data = clone(configManager.GetDataById("config_chapter_plot_type", self.m_classId))
  local List = data.chapter_list2
  self.m_part_toggle = {}
  UIHelper.CreateSubPart(obj, rect, 0, function(index, luaPart)
    self.m_part_toggle[index] = luaPart
  end)
  UIHelper.CreateSubPart(obj, rect, #List, function(index, luaPart)
    UIHelper.SetText(luaPart.tx_title, data.plot_enter_name[index])
    UIHelper.SetText(luaPart.tx_title_xz, data.plot_enter_name[index])
    self:RegisterRedDot(luaPart.im_red1, self.m_classId, index)
    self:RegisterRedDot(luaPart.im_red2, self.m_classId, index)
    toggleGroup:RegisterToggle(luaPart.select_tog)
    self.m_part_toggle[index] = luaPart
  end)
  UIHelper.AddToggleGroupChangeValueEvent(toggleGroup, self, "", function(go, index)
    self:_EffTogglePart(self.m_partId, index + 1)
    self.m_partId = index + 1
    self.cccurSelectIndex = Logic.plotCopyLogic:GetSelectChapterr(self.m_classId, self.m_partId)
    self:_EffTweenBgMask()
  end)
end

function PlotCopyPage:_EffTogglePart(oldid, newid)
  if self.m_part_toggle and #self.m_part_toggle > 0 then
    for index, luaPart in pairs(self.m_part_toggle) do
      local animatorArr = luaPart.tog_animator:GetComponentsInChildren(UnityEngine_Animator.GetClassType())
      self.m_animList = {}
      for i = 0, animatorArr.Length - 1 do
        table.insert(self.m_animList, animatorArr[i])
      end
      for _, animator in ipairs(self.m_animList) do
        if oldid == newid then
          animator:SetFloat("Float", 0)
          if index == oldid then
            animator:SetFloat("Idle", 1)
          else
            animator:SetFloat("Idle", -1)
          end
        elseif index == oldid then
          animator:SetFloat("Float", -1)
        else
          if index == newid then
            animator:SetFloat("Float", 1)
          else
          end
        end
      end
    end
  end
end

function PlotCopyPage:_EffTweenBgMask()
  local duration = 0.4
  local bgAlphaTween = self.tab_Widgets.im_bg_mask2
  if self.mBgTimer ~= nil then
    self.mBgTimer:Stop()
    self.mBgTimer = nil
  end
  if self.on_open then
    duration = 0.25
    bgAlphaTween = self.tab_Widgets.im_bg_mask2
    local iconScaleTween = self.tab_Widgets.tween_pos
    iconScaleTween:ResetToInit()
    iconScaleTween.from = Vector3.New(169, -725, 0)
    iconScaleTween.to = Vector3.New(169, -25, 0)
    iconScaleTween.duration = 0.35
    iconScaleTween:Play(true)
    self.hide_enter = false
    self.on_open = false
  else
    duration = 0.4
    bgAlphaTween = self.tab_Widgets.im_bg_mask
    local iconScaleTween = self.tab_Widgets.tween_pos
    iconScaleTween:ResetToInit()
    iconScaleTween.from = Vector3.New(169, -25, 0)
    iconScaleTween.to = Vector3.New(169, 600, 0)
    iconScaleTween.duration = 0.3
    iconScaleTween:Play(true)
    local mm = 0
    iconScaleTween:SetOnFinished(function()
      if mm == 0 then
        iconScaleTween:ResetToInit()
        iconScaleTween.from = Vector3.New(169, -725, 0)
        iconScaleTween.to = Vector3.New(169, -25, 0)
        iconScaleTween.duration = 0.3
        iconScaleTween:Play(true)
        mm = mm + 1
      end
    end)
  end
  bgAlphaTween:ResetToInit()
  bgAlphaTween.duration = duration * 2
  bgAlphaTween:Play(true)
  local maskAlphaTween = self.tab_Widgets.tween_mask
  maskAlphaTween:ResetToInit()
  maskAlphaTween.duration = duration * 2
  maskAlphaTween:Play(true)
  self.mBgTimer = self:CreateTimer(function()
    local data = clone(configManager.GetDataById("config_chapter_plot_type", self.m_classId))
    UIHelper.SetImage(self.m_tabWidgets.im_bg_dabeijing, data.image_bg[self.m_partId])
    UIHelper.SetImage(self.m_tabWidgets.im_mask, data.image_mask)
    self.m_tabWidgets.tween_pos.gameObject:SetActive(true)
    self:_CreateCopyPlotItem()
    self:__OnSliderCard_Directly()
  end, duration, 1, false)
  self.mBgTimer:Start()
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
  UGUIEventListener.AddOnDrag(self.m_tabWidgets.test_bg, self.__On2DDragCheck, self)
  UGUIEventListener.AddOnEndDrag(self.m_tabWidgets.test_bg, self.__OnDragEnd, self)
end

function PlotCopyPage:_RefreshLockCopy()
  if self.m_chapter_container and #self.m_chapter_container > 0 then
    local tabPassChapterInfo = Logic.copyLogic:GetPassChapterInfoByClassIdAndPartId(self.m_classId, self.m_partId)
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
  local tabPassChapterInfoOpen, tabPassChapterInfo = Logic.copyLogic:GetPassChapterInfoByClassIdAndPartId(self.m_classId, self.m_partId)
  tabPassChapterInfo = self:_GetOpenPlotChapter(tabPassChapterInfo)
  self.m_chapter_container = {}
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_copyPlotItem, self.m_tabWidgets.trans_copyPlotContent, #tabPassChapterInfo, function(nIndex, tabPart)
    self.m_chapter_container[nIndex] = tabPart
    UIHelper.SetImage(tabPart.im_icon, tabPassChapterInfo[nIndex].plot_copy_cover)
    if tabPassChapterInfo[nIndex].name2 == nil or tabPassChapterInfo[nIndex].name2 == "" then
      tabPart.txt_title.gameObject:SetActive(false)
      tabPart.im_titleBg.gameObject:SetActive(false)
    else
      UIHelper.SetText(tabPart.txt_title, tabPassChapterInfo[nIndex].name2)
      tabPart.txt_title.gameObject:SetActive(true)
      tabPart.im_titleBg.gameObject:SetActive(true)
    end
    tabPart.txt_name.text = tabPassChapterInfo[nIndex].name
    local levelLen = tabPassChapterInfo[nIndex].level_list
    local openLen = self:_ChapterOpenNum(levelLen)
    tabPart.txt_num.text = openLen .. "/" .. #levelLen
    local locknoData = tabPassChapterInfoOpen[nIndex] == nil
    local lock = Logic.copyLogic:CheckPlotChapterLock(tabPassChapterInfo[nIndex].id)
    tabPart.obj_lock:SetActive(lock or locknoData)
    Logic.copyLogic:CheckPlotChapterItemLock(tabPassChapterInfo[nIndex].id)
    self:RegisterRedDot(tabPart.redDot, tabPassChapterInfo[nIndex].id)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_plot.gameObject, function()
      if nIndex == self.cccurSelectIndex then
        if locknoData then
          noticeManager:OpenTipPage(self, UIHelper.GetString(920000825))
        else
          self:_ClickChapter(tabPassChapterInfo, nIndex)
        end
      else
        self:__OnClickCard(nIndex)
      end
    end)
    UGUIEventListener.AddOnDrag(tabPart.btn_plot, self.__On2DDragCheck, self)
    UGUIEventListener.AddOnEndDrag(tabPart.btn_plot, self.__OnDragEnd, self)
    local jumpDetailsId = Logic.copyLogic:CheckJumpPlotDetails()
    if jumpDetailsId ~= 0 and jumpDetailsId == tabPassChapterInfo[nIndex].id then
      self:_ClickChapter(tabPassChapterInfo, nIndex)
      Logic.copyLogic:SetJumpPlotDetails(0)
    end
  end)
  self:__CorrectCardAll()
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
    Logic.plotCopyLogic:SetPlotCID(self.m_classId)
    Logic.plotCopyLogic:SetPlotPartID(self.m_classId, self.m_partId)
    Logic.plotCopyLogic:SetSelectChapterr(self.m_classId, self.m_partId, nIndex)
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
  self.m_tabWidgets.btn_left.interactable = false
  self.m_tabWidgets.btn_right.interactable = false
end

function PlotCopyPage:__On2DDragCheck(go, eventData, param)
  local delta = eventData.delta
  if not IsNil(self.m_tabWidgets.im_bg.transform) then
    local targetPos = self.m_tabWidgets.im_bg.transform.localPosition
    local x = targetPos.x + delta.x
    targetPos.x = x
    self.m_tabWidgets.im_bg.transform.localPosition = Vector3.New(targetPos.x, targetPos.y, 0)
    for index, tabPart in pairs(self.m_chapter_container) do
      local contentx = self.m_tabWidgets.im_bg.transform.localPosition.x
      local cardx = tabPart.tran_item.localPosition.x
      if contentx + cardx < ZONE and contentx + cardx + tabPart.tran_item.rect.width > ZONE then
        self.cccurSelectIndex = index
      else
      end
    end
    self:__CorrectCardAll()
  end
end

function PlotCopyPage:__OnDragEnd()
  self:__OnSliderCard()
end

function PlotCopyPage:__OnClickCard(index)
  if index ~= nil then
    self.cccurSelectIndex = index
  end
  self:__OnSliderCard()
  self:__CorrectCardAll()
end

function PlotCopyPage:__OnSliderCard()
  if self.CanSlide == false then
    return
  end
  local index = self.cccurSelectIndex
  if self.m_chapter_container[index] == nil then
    return
  end
  local curcardx = self.m_tabWidgets.im_bg.transform.localPosition.x + self.m_chapter_container[index].tran_item.localPosition.x + self.m_chapter_container[index].tran_item.rect.width / 2
  local delta = ZONE - curcardx
  local correct = self.m_tabWidgets.im_bg.transform.localPosition.x + delta
  if self.mEffectTimer ~= nil then
    self.mEffectTimer:Stop()
    self.mEffectTimer = nil
  end
  local TIME = 20
  local miniLength = delta / TIME
  local step = 0
  self.mEffectTimer = self:CreateTimer(function()
    if step > TIME then
      self.m_tabWidgets.im_bg.transform.localPosition = Vector3.New(correct, self.m_tabWidgets.im_bg.transform.localPosition.y, 0)
      self.mEffectTimer:Stop()
      self.mEffectTimer = nil
    else
      local final_posx = self.m_tabWidgets.im_bg.transform.localPosition.x + miniLength
      self.m_tabWidgets.im_bg.transform.localPosition = Vector3.New(final_posx, self.m_tabWidgets.im_bg.transform.localPosition.y, 0)
      step = step + 1
    end
  end, 0.005, -1, false)
  self.mEffectTimer:Start()
end

function PlotCopyPage:__OnSliderCard_Directly()
  if self.mEffectTimer ~= nil then
    self.mEffectTimer:Stop()
    self.mEffectTimer = nil
  end
  local index = self.cccurSelectIndex
  if self.m_chapter_container[index] == nil then
    return
  end
  local delay = 0
  if self.m_chapter_container[index].tran_item.localPosition.x == 0 then
    delay = 0.01
  end
  self.mm = self:CreateTimer(function()
    local curcardx = self.m_tabWidgets.im_bg.transform.localPosition.x + self.m_chapter_container[index].tran_item.localPosition.x + self.m_chapter_container[index].tran_item.rect.width / 2
    local delta = ZONE - curcardx
    local correct = self.m_tabWidgets.im_bg.transform.localPosition.x + delta
    self.m_tabWidgets.im_bg.transform.localPosition = Vector3.New(correct, self.m_tabWidgets.im_bg.transform.localPosition.y, 0)
    self.CanSlide = true
  end, delay, 1, false)
  self.mm:Start()
end

function PlotCopyPage:__CorrectCard(index, tabPart)
  local scale = 1
  local scale3
  if self.cccurSelectIndex == index then
    if tabPart.tran_item.localScale.x == scale then
      SoundManager.Instance:PlayAudio("UI_Tween_PlotCopyPage_0001")
    end
    scale3 = Vector3.New(1.2 * scale, 1.2 * scale, scale)
  else
    scale3 = Vector3.New(scale, scale, scale)
  end
  tabPart.tran_item.localScale = scale3
end

function PlotCopyPage:__CorrectCardAll()
  for index, tabPart in pairs(self.m_chapter_container) do
    self:__CorrectCard(index, tabPart)
  end
end

function PlotCopyPage:_UnRegisterToggleGroup()
  local widgets = self:GetWidgets()
  widgets.obj_plottype:ClearToggles()
  widgets.obj_toggle:ClearToggles()
end

function PlotCopyPage:DoOnHide()
  self.hide_enter = true
  Logic.plotCopyLogic:SetPlotCID(self.m_classId)
  Logic.plotCopyLogic:SetPlotPartID(self.m_classId, self.m_partId)
  Logic.plotCopyLogic:SetSelectChapterr(self.m_classId, self.m_partId, self.cccurSelectIndex)
end

function PlotCopyPage:DoOnClose()
  self:_UnRegisterToggleGroup()
  Logic.plotCopyLogic:SetPlotCID(0)
  Logic.plotCopyLogic:SetPlotPartID(self.m_classId, self.m_partId)
  Logic.plotCopyLogic:SetSelectChapterr(self.m_classId, self.m_partId, self.cccurSelectIndex)
end

return PlotCopyPage
