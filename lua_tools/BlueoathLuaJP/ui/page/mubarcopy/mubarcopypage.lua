local MubarCopyPage = class("UI.MubarCopy.MubarCopyPage", LuaUIPage)
local homeMubarState = require("Game.GameState.Home.HomeMubarState")
local ChapterLinePath = "scenes/cj_mb_line"
local ShowChapterTime = 0.05
local LevelStatusImg = {
  "uipic_ui_mubar_im_unknown",
  "uipic_ui_mubar_im_exploring",
  "uipic_ui_mubar_im_clear"
}

function MubarCopyPage:DoInit()
  self.selectChapter = {}
  self.beforeChapter = {}
  self.tabLine = {}
  self.date = nil
  self.enterAnimTimer = nil
  self.changeChpterTimer1 = nil
  self.changeChpterTimer2 = nil
  self.clickSkip = false
  self.chapterTogTab = {}
  self.count = 0
  self.openMapTimer = nil
  self.openLevel = false
end

function MubarCopyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_back, self._ClickBack, self)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._ChangeChapter)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_go, self._ClickGo, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_skip, self._ClickSkip, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_unselect, self._UnselectChapter, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_showdetails, self._ShowCentralDetails, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeDetails, self._CloseCentralDetails, self)
  self:RegisterEvent(LuaEvent.UpdateOutpostInfo, self._ShowMubarOutpostDetail, self)
end

function MubarCopyPage:DoOnOpen()
  self.openLevel = false
  local mubarScene = homeMubarState:GetSceneObj()
  if mubarScene == nil then
    eventManager:SendEvent(LuaEvent.HomeSwitchState, {
      HomeStateID.MUBARCOPY
    })
  end
  self.chapterInfo = Logic.mubarCopyLogic:GetOpenChapter()
  self.date = self:TimerToYearMonth(time.getSvrTime())
  local selectedChapter = Logic.mubarCopyLogic:GetSelectChapter()
  CS.PostProcessHud.Instance:EnableBlur(false)
  if not selectedChapter then
    self.tab_Widgets.obj_starup:SetActive(true)
    self.tab_Widgets.anim_select:Play("StarUp")
    self.tab_Widgets.anim_select.enabled = true
    self.enterAnimTimer = self:CreateTimer(function()
      if self.enterAnimTimer ~= nil then
        self.enterAnimTimer:Stop()
        self.enterAnimTimer = nil
      end
      self.tab_Widgets.anim_select.enabled = false
      self.tab_Widgets.obj_starup:SetActive(false)
      self.tab_Widgets.obj_rightTips:SetActive(true)
      self:_CreateLeftTitle()
    end, 7.07, 1, false)
    self:StartTimer(self.enterAnimTimer)
    self.openMapTimer = self:CreateTimer(function()
      if self.openMapTimer ~= nil then
        self.openMapTimer:Stop()
        self.openMapTimer = nil
      end
      self:PlayMapAnim()
    end, 5.9, 1, false)
    self:StartTimer(self.openMapTimer)
  else
    self.tab_Widgets.obj_rightTips:SetActive(true)
    self:_CreateLeftTitle()
  end
end

function MubarCopyPage:TimerToYearMonth(m_time)
  time.checkInit()
  local temp = os.date("*t", m_time)
  local timeString = temp.year .. string.format("/%02d", temp.month)
  return timeString
end

function MubarCopyPage:_CreateLeftTitle()
  self.tabLine = {}
  self.count = 0
  self.chapterTogTab = {}
  local chapterDetailsTab = {}
  local selectChapterIndex = Logic.mubarCopyLogic:GetMubarSChapterIndex()
  local objScene = homeMubarState:GetSceneObj()
  self.tab_Widgets.btn_go.gameObject:SetActive(false)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_leftTag1, self.tab_Widgets.trans_leftTag1, #self.chapterInfo, function(nIndex, tabPart)
    local config = self.chapterInfo[nIndex]
    UIHelper.SetImage(tabPart.im_chapterName, config.class_name, true)
    UIHelper.SetImage(tabPart.im_chapterDetail, config.name, true)
    self.tab_Widgets.tog_group:RegisterToggle(tabPart.tog_one)
    local chapterLineObj = GR.objectPoolManager:LuaGetGameObject(ChapterLinePath)
    table.insert(self.tabLine, chapterLineObj)
    chapterLineObj.transform:SetParent(objScene.transform, false)
    chapterLineObj.transform.position = Vector3.NewFromTab(config.coordinate)
    chapterLineObj:SetActive(false)
    tabPart.tog_one.gameObject:SetActive(false)
    tabPart.im_chapterDetail.gameObject:SetActive(false)
    table.insert(self.chapterTogTab, tabPart.tog_one)
    table.insert(chapterDetailsTab, tabPart.im_chapterDetail)
    local levelNum, openNum = Logic.mubarCopyLogic:GetChapterProgress(config)
    tabPart.im_chapterClear:SetActive(levelNum == openNum)
    local progress = openNum .. "/" .. levelNum
    UIHelper.SetText(tabPart.tx_progressbar, progress)
    local selectedChapter = Logic.mubarCopyLogic:GetSelectChapter()
    if selectChapterIndex ~= 0 and selectedChapter then
      self.tab_Widgets.tog_group:SetActiveToggleIndex(selectChapterIndex - 1)
    end
  end)
  table.insertto(self.chapterTogTab, chapterDetailsTab)
  local selectedChapter = Logic.mubarCopyLogic:GetSelectChapter()
  if not selectedChapter and not self.clickSkip then
    local timer2 = self:CreateTimer(function()
      self:_ShowChapterTog()
    end, ShowChapterTime, #self.chapterTogTab, false)
    self:StartTimer(timer2)
    self:_LoadMubarOutpost()
    return
  end
  self.clickSkip = false
  UIHelper.SetUILock(true)
  self.tab_Widgets.anim_select:Play("BackToCopy")
  self.tab_Widgets.anim_select.enabled = true
  local timer = self:CreateTimer(function()
    local timer2 = self:CreateTimer(function()
      self:_ShowChapterTog()
    end, ShowChapterTime, #self.chapterTogTab, false)
    self:StartTimer(timer2)
    self:_LoadMubarOutpost()
    UIHelper.SetUILock(false)
  end, 1.1, 1, false)
  self:StartTimer(timer)
end

function MubarCopyPage:_LoadMubarOutpost()
  local chapterId = self.chapterInfo[1].id
  local isPass = Logic.copyLogic:IsChapterPassByChapterId(chapterId)
  self:_ShowMubarOutpostBtn(isPass)
  if isPass then
    self:_ShowMubarOutpostDetail()
    local timeNow = 0
    local timer = self:CreateTimer(function()
      timeNow = timeNow + 1
      if timeNow % 60 == 0 then
        Service.mubarOutpostService:GetOutpostInfo()
      end
    end, 1, -1, false)
    self:StartTimer(timer)
  end
end

function MubarCopyPage:_ShowMubarOutpostDetail()
  local chapterId = self.chapterInfo[1].id
  local mubarOutpostSelectedChapterId = Logic.copyLogic:GetMubarCopyOutpostSelectedIndex()
  mubarOutpostSelectedChapterId = mubarOutpostSelectedChapterId or chapterId
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_outpost, function()
    local clicked = Logic.copyLogic:GetMubarCopyOutpostSelectedIndex()
    if clicked then
      mubarOutpostSelectedChapterId = clicked
    end
    local param = {
      chapterInfo = {id = mubarOutpostSelectedChapterId}
    }
    Logic.mubarCopyLogic:SetSelectChapter(true)
    UIHelper.OpenPage("MubarOutpostPage", param)
  end, self)
  local showReddot = Logic.mubarOutpostLogic:CheckOutpostHaveReward()
  self.tab_Widgets.im_reddot:SetActive(showReddot)
  local outpostId = Logic.mubarOutpostLogic:GetOutPostInfoByChapterId(mubarOutpostSelectedChapterId)
  local outpostData = Data.mubarOutpostData:GetOutPostDataById(outpostId)
  local levelTxt = outpostData and outpostData.Level or "0"
  UIHelper.SetText(self.tab_Widgets.tx_level, "Lv." .. levelTxt)
end

function MubarCopyPage:_ShowMubarOutpostBtn(show)
  self.tab_Widgets.obj_outpost:SetActive(show)
end

function MubarCopyPage:_ShowChapterTog()
  self.count = self.count + 1
  if self.count <= #self.chapterTogTab then
    self.chapterTogTab[self.count].gameObject:SetActive(true)
  end
end

function MubarCopyPage:_UnselectChapter()
  if self.openLevel == true then
    return
  end
  self.selectChapter = {}
  self:ResetDetailsPart()
  local selectChapterIndex = Logic.mubarCopyLogic:GetMubarSChapterIndex()
  if next(self.tabLine) ~= nil and selectChapterIndex ~= 0 then
    self.tabLine[selectChapterIndex]:SetActive(false)
  end
  Logic.mubarCopyLogic:SetMubarSChapterIndex(0)
  self.tab_Widgets.tog_group:SetActiveToggleOff()
  CS.PostProcessHud.Instance:EnableBlur(false)
  homeMubarState:ChangeCamera(self.beforeChapter.coordinate, self.selectChapter.coordinate, 0.5, true)
  self.beforeChapter = {}
end

function MubarCopyPage:_ChangeChapter(nIndex)
  self:ResetDetailsPart()
  if self.playMapAnimTimer ~= nil then
    self.playMapAnimTimer:Stop()
    self.playMapAnimTimer = nil
  end
  local selectChapterIndex = Logic.mubarCopyLogic:GetMubarSChapterIndex()
  if selectChapterIndex ~= 0 then
    self.tabLine[selectChapterIndex]:SetActive(false)
  end
  self.selectChapter = self.chapterInfo[nIndex + 1]
  Logic.mubarCopyLogic:SetMubarSChapterIndex(nIndex + 1)
  UIHelper.SetImage(self.tab_Widgets.im_chaptername, self.selectChapter.class_name, true)
  UIHelper.SetText(self.tab_Widgets.tx_time, self.date)
  local tempTab = configManager.GetDataById("config_parameter", 401).arrValue
  local temp = math.random(tempTab[1], tempTab[2])
  UIHelper.SetText(self.tab_Widgets.tx_temp, temp)
  local wheatherTab = configManager.GetDataById("config_parameter", 402).arrValue
  local index = math.random(#wheatherTab)
  UIHelper.SetText(self.tab_Widgets.tx_wheather, wheatherTab[index])
  UIHelper.SetImage(self.tab_Widgets.im_pic_1, self.selectChapter.mubarcopy_chapter_image01)
  UIHelper.SetImage(self.tab_Widgets.im_pic_2, self.selectChapter.mubarcopy_chapter_image02)
  local copyDisplayTab = Logic.copyLogic:GetAreaConfig(self.selectChapter.id)
  local textDataTab = self.selectChapter.mubarcopy_data
  UIHelper.CreateSubPart(self.tab_Widgets.obj_text, self.tab_Widgets.trans_list, #textDataTab, function(nIndex, tabPart)
    local textTab = textDataTab[nIndex]
    for i, text in ipairs(textTab) do
      UIHelper.SetText(tabPart["text" .. i], text)
    end
    local serCopyInfo = Data.copyData:GetMubarCopyInfoById(copyDisplayTab[nIndex].id)
    local isLock, _ = Logic.mubarCopyLogic:CheckCopyIsLock(copyDisplayTab[nIndex])
    local unClear = serCopyInfo and serCopyInfo.FirstPassTime == 0
    local img = ""
    if isLock then
      img = LevelStatusImg[1]
    elseif not isLock and unClear then
      img = LevelStatusImg[2]
    else
      img = LevelStatusImg[3]
    end
    UIHelper.SetImage(tabPart.im_status, img)
  end)
  homeMubarState:ChangeCamera(self.beforeChapter.coordinate, self.selectChapter.coordinate, 0.5, false)
  self.tabLine[nIndex + 1]:SetActive(true)
  self.beforeChapter = next(self.selectChapter) == nil and self.chapterInfo[nIndex + 1] or self.selectChapter
  self.changeChpterTimer1 = self:CreateTimer(function()
    self.tab_Widgets.anim_select:Play("ChapterSelect", 0, 0)
    self.tab_Widgets.anim_select.enabled = true
    self.tab_Widgets.btn_go.gameObject:SetActive(true)
    self:StopTimer(self.changeChpterTimer1)
    self.changeChpterTimer1 = nil
    self.changeChpterTimer2 = self:CreateTimer(function()
      self.tab_Widgets.anim_select.enabled = false
      self:StopTimer(self.changeChpterTimer2)
      self.changeChpterTimer2 = nil
    end, 1.4, 1, false)
    self:StartTimer(self.changeChpterTimer2)
  end, 0.5, 1, false)
  self:StartTimer(self.changeChpterTimer1)
end

function MubarCopyPage:_ClickBack()
  UIHelper.ClosePage(self:GetName())
end

function MubarCopyPage:_ClickGo()
  if next(self.selectChapter) == nil then
    logError("\230\178\161\230\156\137\233\128\137\230\139\169\231\171\160\232\138\130")
    return
  end
  self.openLevel = true
  if self.changeChpterTimer1 ~= nil then
    self:StopTimer(self.changeChpterTimer1)
    self.changeChpterTimer1 = nil
  end
  if self.changeChpterTimer2 ~= nil then
    self:StopTimer(self.changeChpterTimer2)
    self.changeChpterTimer2 = nil
  end
  self.tab_Widgets.anim_select.enabled = false
  Logic.mubarCopyLogic:SetSelectChapter(true)
  self.tab_Widgets.obj_centralParts:SetActive(false)
  self.tab_Widgets.obj_coordParts:SetActive(false)
  homeMubarState:ChangeCamera(self.selectChapter.coordinate, {
    self.selectChapter.coordinate[1],
    self.selectChapter.coordinate[2],
    self.selectChapter.coordinate[3]
  }, 0.7, true)
  UIHelper.SetUILock(true)
  self:_PageShowEnd()
  self.tab_Widgets.anim_select:Play("InToCopyDetails")
  self.tab_Widgets.anim_select.enabled = true
  local timer = self:CreateTimer(function()
    self.tab_Widgets.anim_select.enabled = false
    UIHelper.OpenPage("MubarCopyDetailsPage", self.selectChapter)
    UIHelper.SetUILock(false)
  end, 1, 1, false)
  self:StartTimer(timer)
end

function MubarCopyPage:DoOnHide()
  self:_ShowMubarOutpostBtn(false)
  self:_PageShowEnd()
end

function MubarCopyPage:DoOnClose()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN,
    HomeStateID.MUBARCOPY
  })
  Logic.mubarCopyLogic:SetSelectChapter(false)
  self:_ShowMubarOutpostBtn(false)
  self:_PageShowEnd()
end

function MubarCopyPage:_PageShowEnd()
  UIHelper.SetUILock(false)
  self.tab_Widgets.tog_group:ClearToggles()
  if self.tabLine then
    for _, v in ipairs(self.tabLine) do
      GR.objectPoolManager:LuaUnspawnAndDestory(v)
    end
  end
  if self.enterAnimTimer ~= nil then
    self.enterAnimTimer:Stop()
    self.enterAnimTimer = nil
  end
  if self.openMapTimer ~= nil then
    self.openMapTimer:Stop()
    self.openMapTimer = nil
  end
  if self.changeChpterTimer1 ~= nil then
    self:StopTimer(self.changeChpterTimer1)
    self.changeChpterTimer1 = nil
  end
  if self.changeChpterTimer2 ~= nil then
    self:StopTimer(self.changeChpterTimer2)
    self.changeChpterTimer2 = nil
  end
end

function MubarCopyPage:_ClickSkip()
  if self.enterAnimTimer ~= nil then
    self.enterAnimTimer:Stop()
    self.enterAnimTimer = nil
  end
  if self.openMapTimer ~= nil then
    self.openMapTimer:Stop()
    self.openMapTimer = nil
  end
  self.clickSkip = true
  self.tab_Widgets.anim_select.enabled = false
  self.tab_Widgets.obj_rightTips:SetActive(true)
  self.tab_Widgets.obj_starup:SetActive(false)
  self:PlayMapAnim()
  self:_CreateLeftTitle()
end

function MubarCopyPage:_ShowCentralDetails()
  self.tab_Widgets.obj_centralDetails:SetActive(true)
  UIHelper.SetImage(self.tab_Widgets.im_pic, self.selectChapter.mubarcopy_chapter_image01)
  UIHelper.SetText(self.tab_Widgets.tx_chapterDetails, self.selectChapter.chapter_details)
end

function MubarCopyPage:_CloseCentralDetails()
  self.tab_Widgets.obj_centralDetails:SetActive(false)
end

function MubarCopyPage:ResetDetailsPart()
  self.tab_Widgets.obj_centralParts:SetActive(false)
  self.tab_Widgets.obj_coordParts:SetActive(false)
  self.tab_Widgets.btn_go.gameObject:SetActive(false)
  if self.changeChpterTimer1 ~= nil then
    self:StopTimer(self.changeChpterTimer1)
    self.changeChpterTimer1 = nil
  end
  if self.changeChpterTimer2 ~= nil then
    self:StopTimer(self.changeChpterTimer2)
    self.changeChpterTimer2 = nil
  end
  self.tab_Widgets.anim_select.enabled = false
end

function MubarCopyPage:PlayMapAnim()
  homeMubarState:PlaySceneAnim()
  self.playMapAnimTimer = self:CreateTimer(function()
    if self.playMapAnimTimer ~= nil then
      self.playMapAnimTimer:Stop()
      self.playMapAnimTimer = nil
    end
    local selectChapterIndex = Logic.mubarCopyLogic:GetMubarSChapterIndex()
    if selectChapterIndex ~= 0 then
      self.tab_Widgets.tog_group:SetActiveToggleIndex(selectChapterIndex - 1)
    else
      self.tab_Widgets.tog_group:SetActiveToggleIndex(#self.chapterInfo - 1)
    end
  end, 3.1, 1, false)
  self:StartTimer(self.playMapAnimTimer)
end

return MubarCopyPage
