local TrainLevelPage = class("UI.Train.TrainLevelPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
TrainLevelPage.AnimType = {EncourageOne = 1, EncourageTwo = 2}
TrainLevelPage.Anim = {
  [TrainLevelPage.AnimType.EncourageOne] = "learn_click1",
  [TrainLevelPage.AnimType.EncourageTwo] = "learn_click2"
}
TrainLevelPage.StudyDressUpId = 102401103

function TrainLevelPage:DoInit()
  UIHelper.AdapteShipRT(self.tab_Widgets.trans_girl)
  self.subToggles = {}
  self.activeColor = Color.white
  self.unactiveColor = Color.New(0.3686274509803922, 0.44313725490196076, 0.5411764705882353, 255)
end

function TrainLevelPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnStart, self._OnStartTrain, self)
end

function TrainLevelPage:DoOnOpen()
  self:OpenTopPage("TrainLevelPage", 1, UIHelper.GetString(1000002), self, true)
  self.modelMap = {}
  self.curModelId = nil
  self.tweenList = {}
  self.openIndex = -1
  local params = self.param
  self.chapter = params.chapter
  self.index = params.index
  self.isAdvance = self.chapter.class_type == ChapterType.TrainAdvance
  self.levelParts = {}
  self.toggleIndex = 0
  self.selectedIndex = nil
  self.selectedSubIndex = nil
  self.pageNum = 8
  if self.isAdvance then
    self.pageNum = 7
  end
  if self.isAdvance then
    self:RegisterRedDot(self.tab_Widgets.redDot, self.chapter.id)
  end
  self.tab_Widgets.levelStars:SetActive(false)
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = UIHelper.GetString(1000002),
    ChapterId = self.chapter.id,
    CloseFunc = function()
      Logic.copyLogic:SetTrainIndex(nil)
      UIHelper.Back()
    end
  })
  if self.isAdvance or self.chapter.class_type == ChapterType.Train then
    self:_UpdateLeftTop()
    self.tab_Widgets.normalList:SetActive(true)
    self.tab_Widgets.doubleList:SetActive(false)
    self.levelDatas = Logic.copyLogic:GetTrainLevels(self.chapter.id)
    self:_CreateLeft()
    self:_SelectDefault()
  elseif self.chapter.class_type == ChapterType.TrainLv then
    self.tab_Widgets.normalList:SetActive(false)
    self.tab_Widgets.doubleList:SetActive(true)
    self.levelDatas = Logic.copyLogic:GetTrainLvLevels(self.chapter.id)
    self:_CreateLeftDouble()
    self:_SelectDefaultGroup()
  end
end

function TrainLevelPage:_UpdateLeftTop()
  local chapterData = Data.copyData:GetChapterDataById(self.chapter.id)
  local curStars = chapterData and chapterData.StarNum or 0
  local targetStars = Logic.copyLogic:GetTargetStars(self.chapter.id, curStars)
  UIHelper.SetText(self.tab_Widgets.starCount, string.format("%d/%d", curStars, targetStars))
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnChest, function()
    UIHelper.OpenPage("TrainRewardPage", {
      chapterId = self.chapter.id
    })
  end)
end

function TrainLevelPage:_CreateLeft()
  self.tab_Widgets.chestObj:SetActive(self.isAdvance)
  local levelCount = #self.levelDatas
  UIHelper.CreateSubPart(self.tab_Widgets.listItem, self.tab_Widgets.content, levelCount, function(nIndex, tabPart)
    local levelData = self.levelDatas[nIndex]
    UIHelper.SetText(tabPart.txt_level, levelData.str_index)
    UIHelper.SetText(tabPart.txt_name, levelData.name)
    tabPart.img_lock:SetActive(levelData.locked)
    tabPart.txt_level.color = self.unactiveColor
    tabPart.txt_name.color = self.unactiveColor
    tabPart.txt_pass.gameObject:SetActive(levelData.Pass and not self.isAdvance)
    tabPart.obj_stars:SetActive(self.isAdvance)
    tabPart.bg_selected:SetActive(false)
    if self.isAdvance then
      for i = 1, 3 do
        tabPart["obg_star" .. i]:SetActive(i <= levelData.StarNum)
      end
    end
    table.insert(self.levelParts, tabPart)
    if levelData.locked then
      UGUIEventListener.AddButtonOnClick(tabPart.btn_item, function()
        noticeManager:ShowTip(UIHelper.GetString(1000006))
      end)
    else
      UGUIEventListener.AddButtonOnClick(tabPart.btn_item, function()
        self:_SelectLevel(nIndex)
      end)
    end
  end)
end

function TrainLevelPage:_CreateLeftDouble()
  self.tab_Widgets.chestObj:SetActive(false)
  local levelCount = #self.levelDatas
  self.toggleIndex = 0
  UIHelper.CreateSubPart(self.tab_Widgets.listItem2, self.tab_Widgets.content2, levelCount, function(nIndex, tabPart)
    local levelData = self.levelDatas[nIndex]
    UIHelper.SetText(tabPart.tx_name, levelData.Name)
    UIHelper.SetText(tabPart.pass_num, string.format("%s/%s", levelData.PassCount, #levelData.CopyList))
    tabPart.obj_lock:SetActive(false)
    table.insert(self.tweenList, tabPart.twn_section)
    UGUIEventListener.AddButtonToggleChanged(tabPart.tog_chapter, function()
      self:_SelectLevelDouble(nIndex)
    end, self)
    self:_CreateSubSection(nIndex, tabPart)
  end)
end

function TrainLevelPage:_CreateSubSection(pIndex, tabPart)
  local group = self.levelDatas[pIndex]
  local copyCount = #group.CopyList
  UIHelper.CreateSubPart(tabPart.obj_section, tabPart.trans_section, copyCount, function(sIndex, subPart)
    local copyData = group.CopyList[sIndex]
    subPart.obj_lock:SetActive(copyData.Locked)
    UIHelper.SetText(subPart.tx_name, copyData.name)
    subPart.tx_name.color = self.unactiveColor
    subPart.img_pass:SetActive(copyData.Pass)
    self.tab_Widgets.copygroup:RegisterToggle(subPart.tog_section)
    self.subToggles[pIndex] = self.subToggles[pIndex] or {}
    self.subToggles[pIndex][sIndex] = subPart
    self.toggleIndex = self.toggleIndex + 1
    if copyData.Locked then
      self.tab_Widgets.copygroup:ResigterToggleUnActive(self.toggleIndex - 1, function()
        noticeManager:ShowTip(UIHelper.GetString(130001))
      end)
    else
      UGUIEventListener.AddButtonToggleChanged(subPart.tog_section, function()
        self:_SelectSubSection(pIndex, sIndex)
      end, self)
    end
  end)
end

function TrainLevelPage:_SelectLevelDouble(nIndex)
  local tweenSizeDelta = self.tweenList[nIndex]
  local copyCount = #self.levelDatas[nIndex].CopyList
  local duration = 0.1
  local itemHeight = 78
  if nIndex == self.openIndex then
    tweenSizeDelta:ResetToInit()
    tweenSizeDelta.from = Vector2.New(370, copyCount * itemHeight)
    tweenSizeDelta.to = Vector2.New(370, 0)
    tweenSizeDelta.duration = duration
    tweenSizeDelta:Play(true)
    self.openIndex = -1
  else
    if self.openIndex > 0 then
      local old = self.tweenList[self.openIndex]
      old:ResetToInit()
      old.from = Vector2.New(370, copyCount * itemHeight)
      old.to = Vector2.New(370, 0)
      old.duration = duration
      old:Play(true)
    end
    tweenSizeDelta:ResetToInit()
    tweenSizeDelta.from = Vector2.New(370, 0)
    tweenSizeDelta.to = Vector2.New(370, copyCount * itemHeight)
    tweenSizeDelta.duration = duration
    tweenSizeDelta:Play(true)
    self.openIndex = nIndex
  end
  self:PerformDelay(duration, function()
    self:_RefreshListSize()
  end)
  self:_SelectDefaultSubSection(nIndex)
end

function TrainLevelPage:_SelectDefaultSubSection(pIndex)
  local sIndex = self:_GetDefaultSubSection(pIndex)
  self:_SelectSubSection(pIndex, sIndex)
end

function TrainLevelPage:_SelectDefaultGroup()
  local defaultGroup = self:_GetDefaultGroup()
  local defaultSection = self:_GetDefaultSubSection(defaultGroup)
  local group = self.levelDatas[defaultGroup]
  local copyData = group.CopyList[defaultSection]
  self.selectedCopyId = copyData.id
  self:_InitModel()
  self:_SelectLevelDouble(defaultGroup)
end

function TrainLevelPage:_GetDefaultGroup()
  local pIndex = 1
  local lastGroupIndex = Logic.copyLogic:GetTrainLvGroup()
  if lastGroupIndex then
    pIndex = lastGroupIndex
  else
    local groups = self.levelDatas
    local breakOut = false
    for i, group in ipairs(groups) do
      for k, copyData in ipairs(group.CopyList) do
        if not copyData.Pass and not copyData.Locked then
          pIndex = i
          breakOut = true
          break
        end
      end
      if breakOut then
        break
      end
    end
  end
  return pIndex
end

function TrainLevelPage:_GetDefaultSubSection(pIndex)
  local group = self.levelDatas[pIndex]
  local sIndex = 1
  for i, copyData in ipairs(group.CopyList) do
    if not copyData.Pass and not copyData.Locked then
      sIndex = i
      break
    end
  end
  return sIndex
end

function TrainLevelPage:_RefreshListSize()
  local funcCB = function()
    self.tab_Widgets.vLayout.enabled = false
    self.tab_Widgets.vLayout.enabled = true
    self:FixDoubleListPos()
  end
  if self.m_refreshTimer == nil then
    self.m_refreshTimer = self:CreateTimer(funcCB, 0.01, 1, false)
  else
    self:ResetTimer(self.m_refreshTimer, funcCB, 0.01, 1, false)
  end
  self:StartTimer(self.m_refreshTimer)
end

function TrainLevelPage:GetDoubleContentSize(groupCount, subCount)
  local groupHeight = groupCount * 76 + (groupCount - 1) * 2
  local subHeight = subCount * 78
  return groupHeight, subHeight
end

function TrainLevelPage:FixDoubleListPos()
  local groupCount = #self.levelDatas
  local group = self.levelDatas[self.selectedIndex]
  local subCount = #group.CopyList
  local totalCount = groupCount + subCount
  local defaultSubIndex = self:_GetDefaultSubSection(self.selectedIndex)
  local lastIndex = self.selectedIndex + subCount
  local content = self.tab_Widgets.content2
  local pos = content.anchoredPosition
  local groupHeight, subHeight = self:GetDoubleContentSize(groupCount, subCount)
  local viewPortSize = content.parent.rect.size
  local delta = groupHeight - viewPortSize.y
  if self.openIndex > -1 then
    if 1 <= lastIndex and lastIndex < self.pageNum then
      content.anchoredPosition = Vector3.New(pos.x, 0, pos.z)
    elseif lastIndex == self.pageNum then
      content.anchoredPosition = Vector3.New(pos.x, delta, pos.z)
    elseif lastIndex > self.pageNum and totalCount >= lastIndex then
      content.anchoredPosition = Vector3.New(pos.x, 78 * (lastIndex - self.pageNum) + 6 + delta, pos.z)
    end
  end
end

function TrainLevelPage:_SelectSubSection(pIndex, sIndex)
  if self.selectedIndex and self.selectedSubIndex and (self.selectedIndex ~= pIndex or self.selectedSubIndex ~= sIndex) then
    local oldPart = self.subToggles[self.selectedIndex][self.selectedSubIndex]
    oldPart.tx_name.color = self.unactiveColor
  end
  self.selectedSubIndex = sIndex
  self.selectedIndex = pIndex
  Logic.copyLogic:SetTrainLvGroup(pIndex)
  local subPart = self.subToggles[pIndex][sIndex]
  if subPart then
    subPart.tog_section.isOn = true
    subPart.tx_name.color = self.activeColor
  end
  local group = self.levelDatas[pIndex]
  local copyData = group.CopyList[sIndex]
  self.selectedCopyId = copyData.id
  self:_InitModel()
  self:_UpdateRight(copyData.id, copyData.Pass)
end

function TrainLevelPage:_SelectLevel(nIndex)
  if self.selectedIndex and self.selectedIndex ~= nIndex then
    local oldPart = self.levelParts[self.selectedIndex]
    oldPart.bg_selected:SetActive(false)
    oldPart.txt_level.color = self.unactiveColor
    oldPart.txt_name.color = self.unactiveColor
  end
  self.selectedIndex = nIndex
  local tabPart = self.levelParts[nIndex]
  tabPart.bg_selected:SetActive(true)
  tabPart.txt_level.color = self.activeColor
  tabPart.txt_name.color = self.activeColor
  local delay = FrameTimer.New(function()
    self:_FixScrollPos(nIndex)
  end, 1, 1)
  delay:Start()
  local copyData = self.levelDatas[nIndex]
  local copyId = self.chapter.level_list[nIndex]
  self.selectedCopyId = copyId
  self:_InitModel()
  self:_UpdateRight(copyId, copyData.Pass)
end

function TrainLevelPage:GetOffsetByIndex(index, isLast)
  if isLast then
    return 72.4 * index
  end
  return 77.4 * index
end

function TrainLevelPage:_FixScrollPos(nIndex)
  local count = #self.levelDatas
  local itemHeight = 72.4
  local content = self.tab_Widgets.content
  local pos = content.anchoredPosition
  local viewPortSize = content.parent.rect.size
  local deltaY = self:GetOffsetByIndex(self.pageNum) + 10 - viewPortSize.y
  local lessTwoPage = count < self.pageNum * 2
  if lessTwoPage then
    if 1 <= nIndex and nIndex < self.pageNum then
      content.anchoredPosition = Vector3.New(pos.x, 0, pos.z)
    elseif nIndex >= self.pageNum and nIndex <= count then
      content.anchoredPosition = Vector3.New(pos.x, deltaY + self:GetOffsetByIndex(count - self.pageNum, true), pos.z)
    end
  elseif 1 <= nIndex and nIndex < self.pageNum then
    content.anchoredPosition = Vector3.New(pos.x, 0, pos.z)
  elseif nIndex == self.pageNum then
    content.anchoredPosition = Vector3.New(pos.x, deltaY, pos.z)
  elseif nIndex > self.pageNum and nIndex <= count - self.pageNum then
    content.anchoredPosition = Vector3.New(pos.x, self:GetOffsetByIndex(nIndex - self.pageNum + 3) + deltaY, pos.z)
  elseif nIndex > count - self.pageNum and nIndex <= count then
    content.anchoredPosition = Vector3.New(pos.x, self:GetOffsetByIndex(count - self.pageNum, true) + deltaY, pos.z)
  end
end

function TrainLevelPage:_SelectDefault()
  local copyDatas = self.levelDatas
  local lastIndex = Logic.copyLogic:GetTrainIndex()
  local index = lastIndex
  if not lastIndex then
    index = 1
    for i, copyData in ipairs(copyDatas) do
      if not copyData.Pass then
        index = i
        break
      end
    end
  end
  self:_SelectLevel(index)
end

function TrainLevelPage:_UpdateRight(copyId, passed)
  local copyDisplay = configManager.GetDataById("config_copy_display", copyId)
  self.tab_Widgets.levelStars:SetActive(self.isAdvance)
  if self.isAdvance then
    for i, evaluateId in ipairs(copyDisplay.star_require) do
      local evaluate = configManager.GetDataById("config_evaluate", evaluateId)
      UIHelper.SetText(self.tab_Widgets["starDesc" .. i], evaluate.description)
    end
  end
  UIHelper.SetText(self.tab_Widgets.levelDesc, copyDisplay.description)
  local rewards = Logic.rewardLogic:FormatRewardById(copyDisplay.first_reward[1])
  local rewardCount = #rewards
  if 3 < rewardCount then
    rewardCount = 3
  end
  UIHelper.CreateSubPart(self.tab_Widgets.rewardItem, self.tab_Widgets.rewards, rewardCount, function(nIndex, tabPart)
    local reward = rewards[nIndex]
    local display = ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId)
    UIHelper.SetImage(tabPart.icon, display.icon)
    UIHelper.SetImage(tabPart.bg, QualityIcon[display.quality])
    UIHelper.SetText(tabPart.desc, "x" .. tostring(reward.Num))
    tabPart.received:SetActive(passed)
    UGUIEventListener.AddButtonOnClick(tabPart.btn, function()
      self:_ShowItemInfo(display)
    end)
  end)
end

function TrainLevelPage:_ShowItemInfo(displayData)
  UIHelper.OpenPage("ItemInfoPage", displayData)
end

function TrainLevelPage:_InitModel()
  local widgets = self.tab_Widgets
  local copyDisplay = configManager.GetDataById("config_copy_display", self.selectedCopyId)
  local modelId = copyDisplay.training_teacher_modle
  if self.curModelId and self.curModelId == modelId then
    return
  end
  local curModel = self.modelMap[self.curModelId]
  if curModel then
    curModel:Hide()
  end
  self.curModelId = modelId
  local model = self.modelMap[modelId]
  if not model then
    local param = {
      showID = self.curModelId,
      dressID = TrainLevelPage.StudyDressUpId
    }
    model = UIHelper.Create3DModel(param, widgets.img_girl, CamDataType.Study)
    self.modelMap[modelId] = model
  else
    model:Show()
  end
  widgets.img_girl.transform.localScale = Vector3.New(-1, 1, 1)
  widgets.img_girl.gameObject:SetActive(true)
  model:Get3dObj():playBehaviour("learn_loop", true)
  UGUIEventListener.AddButtonOnClick(widgets.btn_girl, function(go)
    local sType = math.random(TrainLevelPage.AnimType.EncourageOne, TrainLevelPage.AnimType.EncourageTwo)
    local currModel = self.modelMap[self.curModelId]
    local girl3DObj = currModel:Get3dObj()
    girl3DObj:playBehaviour(TrainLevelPage.Anim[sType], false, function()
      girl3DObj:playBehaviour("learn_loop", true)
    end)
  end)
end

function TrainLevelPage:_OnStartTrain()
  Logic.copyLogic:SetTrainIndex(self.selectedIndex)
  local ctype = self.chapter.class_type
  if ctype == ChapterType.Train or ctype == ChapterType.TrainAdvance then
    UIHelper.OpenPage("FleetPage", {
      subType = 2,
      copyId = self.selectedCopyId,
      chapterId = self.chapter.id
    })
  else
    UIHelper.OpenPage("FleetPage", {
      subType = 3,
      copyId = self.selectedCopyId,
      chapterId = self.chapter.id
    })
  end
end

function TrainLevelPage:DoOnHide()
  for k, model in pairs(self.modelMap) do
    UIHelper.Close3DModel(model)
    model = nil
  end
  self.tab_Widgets.img_girl.gameObject:SetActive(false)
end

function TrainLevelPage:DoOnClose()
  for k, model in pairs(self.modelMap) do
    UIHelper.Close3DModel(model)
    model = nil
  end
  self.tab_Widgets.img_girl.gameObject:SetActive(false)
end

return TrainLevelPage
