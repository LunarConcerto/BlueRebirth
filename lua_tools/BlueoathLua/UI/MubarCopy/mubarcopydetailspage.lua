local MubarCopyDetailsPage = class("UI.MubarCopy.MubarCopyDetailsPage", LuaUIPage)
local homeMubarState = require("Game.GameState.Home.HomeMubarState")

function MubarCopyDetailsPage:DoInit()
  self.chapterInfo = {}
  self.pointPartTab = {}
  self.newBattlePart = {}
  self.animaLinePart = {}
end

function MubarCopyDetailsPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_back, self._ClickBack, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_outpost, self._ClickOutpost, self)
  self:RegisterEvent(LuaEvent.UpdateOutpostInfo, self._UpdateOutpostInfo, self)
end

function MubarCopyDetailsPage:DoOnOpen()
  local mubarScene = homeMubarState:GetSceneObj()
  if mubarScene == nil then
    eventManager:SendEvent(LuaEvent.HomeSwitchState, {
      HomeStateID.MUBARCOPY
    })
  end
  self.chapterInfo = self:GetParam()
  UIHelper.SetImage(self.tab_Widgets.im_chapterName, self.chapterInfo.class_name)
  self:_ShowFleetInfo()
  self:_ShowCopyInfo()
  self:GetOutpostInfo()
end

function MubarCopyDetailsPage:_UpdateOutpostInfo()
  local showReddot = Logic.mubarOutpostLogic:CheckOutpostHaveReward()
  self.tab_Widgets.obj_reddot:SetActive(showReddot)
  local outpostId = Logic.mubarOutpostLogic:GetOutPostInfoByChapterId(self.chapterInfo.id)
  local outpostData = Data.mubarOutpostData:GetOutPostDataById(outpostId)
  local levelTxt = outpostData and outpostData.Level or "0"
  UIHelper.SetText(self.tab_Widgets.tx_level, "Lv." .. levelTxt)
end

function MubarCopyDetailsPage:GetOutpostInfo()
  local canShow = Logic.copyLogic:IsChapterPassByChapterId(self.chapterInfo.id)
  self.tab_Widgets.obj_outpost:SetActive(canShow)
  if canShow then
    self:_UpdateOutpostInfo()
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

function MubarCopyDetailsPage:_ShowFleetInfo()
  local selectIndex = Logic.fleetLogic:GetSelectTog()
  local info = Data.fleetData:GetFleetDataById(selectIndex)
  fleetInfo = info.heroInfo
  UIHelper.SetText(self.tab_Widgets.tx_fleet, info.tacticName)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_left, #fleetInfo, function(nIndex, tabPart)
    local heroId = fleetInfo[nIndex]
    local heroInfo = Data.heroData:GetHeroById(heroId)
    local shipShow = Logic.shipLogic:GetShipShowById(heroInfo.TemplateId)
    local shipName = Logic.shipLogic:GetRealName(heroId)
    UIHelper.SetText(tabPart.tx_ship_name, shipName)
    UIHelper.SetText(tabPart.tx_level_value, heroInfo.Lvl)
    UIHelper.SetImage(tabPart.img_icon, shipShow.ship_icon7)
    UIHelper.CreateSubPart(tabPart.obj_star, tabPart.trans_star, heroInfo.Advance, function(i, part)
    end)
  end)
end

function MubarCopyDetailsPage:_ShowCopyInfo()
  local copyDisplayTab = Logic.copyLogic:GetAreaConfig(self.chapterInfo.id)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_copyPoint, self.tab_Widgets.trans_copyPoints, #copyDisplayTab, function(nIndex, tabPart)
    local copyDisplay = copyDisplayTab[nIndex]
    local serCopyInfo = Data.copyData:GetMubarCopyInfoById(copyDisplay.id)
    UIHelper.SetText(tabPart.tx_copyName, copyDisplay.name)
    tabPart.obj_self.transform.localPosition = Vector3.NewFromTab(copyDisplay.coordinate)
    local isLock, msg = self:_CheckCopyIsLock(copyDisplay, serCopyInfo)
    local unClear = serCopyInfo and serCopyInfo.FirstPassTime == 0
    tabPart.obj_normalBtn:SetActive(copyDisplay.unlock_next_chapter == 0)
    tabPart.obj_nextBtn:SetActive(copyDisplay.unlock_next_chapter ~= 0)
    tabPart.bt_clear.gameObject:SetActive(not isLock and not unClear)
    tabPart.btn_unlock.gameObject:SetActive(not isLock and unClear)
    tabPart.bt_notclear.gameObject:SetActive(isLock)
    tabPart.bt_nextClear.gameObject:SetActive(not isLock and not unClear)
    tabPart.btn_nextunlock.gameObject:SetActive(not isLock and unClear)
    tabPart.bt_nextnotclear.gameObject:SetActive(isLock)
    tabPart.anim_copyPoint:Play("eff_ui_copypointin")
    table.insert(self.pointPartTab, tabPart)
    if not isLock and unClear then
      local timer = self:CreateTimer(function()
        tabPart.anim_copyPoint.enabled = false
        tabPart.anim_copyPoint:Play("eff_ui_copypointnow")
        tabPart.anim_copyPoint.enabled = true
      end, 0.15, 1, false)
      self:StartTimer(timer)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.bt_clear, self._ClickDetails, self, {copyDisplay, serCopyInfo})
    UGUIEventListener.AddButtonOnClick(tabPart.btn_unlock, self._ClickDetails, self, {copyDisplay, serCopyInfo})
    UGUIEventListener.AddButtonOnClick(tabPart.bt_notclear, self._ClickDetailsLock, self, msg)
    UGUIEventListener.AddButtonOnClick(tabPart.bt_nextClear, self._ClickDetails, self, {copyDisplay, serCopyInfo})
    UGUIEventListener.AddButtonOnClick(tabPart.btn_nextunlock, self._ClickDetails, self, {copyDisplay, serCopyInfo})
    UGUIEventListener.AddButtonOnClick(tabPart.bt_nextnotclear, self._ClickDetailsLock, self, msg)
    for i, id in ipairs(copyDisplay.unlock_clear_request) do
      if Logic.mubarCopyLogic:CheckCopyInChapter(copyDisplayTab, id) then
        local soucePos = copyDisplay.coordinate
        local endPos = Logic.copyLogic:GetCopyDesConfig(id).coordinate
        local obj_line = UIHelper.CreateGameObject(self.tab_Widgets.obj_line, self.tab_Widgets.trans_line)
        local rectTrans = obj_line:GetComponent(RectTransform.GetClassType())
        obj_line.transform.localPosition = Vector3.NewFromTab(endPos)
        obj_line:SetActive(true)
        local length = math.sqrt((soucePos[1] - endPos[1]) ^ 2 + (soucePos[2] - endPos[2]) ^ 2)
        local angle = math.atan(soucePos[2] - endPos[2], soucePos[1] - endPos[1]) * 180 / math.pi
        local height = rectTrans.sizeDelta.y
        rectTrans.sizeDelta = Vector2.New(length, height)
        rectTrans.eulerAngles = Vector3.New(0, 0, angle)
        local animaLine = obj_line:GetComponent(UnityEngine_Animator.GetClassType())
        animaLine:Play("eff_ui_CopyLineIn")
        animaLine.enabled = true
        table.insert(self.animaLinePart, animaLine)
      end
    end
  end)
  self.tab_Widgets.anim_select:Play("CopyDetailsIn")
  self.tab_Widgets.anim_copyBg:Play("eff_ui_CopyBackgroundIn")
  self.tab_Widgets.anim_select.enabled = true
  self.tab_Widgets.anim_copyBg.enabled = true
  UIHelper.SetUILock(true)
  local timer = self:CreateTimer(function()
    self.tab_Widgets.anim_select.enabled = false
    UIHelper.SetUILock(false)
  end, 1.5, 1, false)
  self:StartTimer(timer)
end

function MubarCopyDetailsPage:_ClickDetailsLock(go, msg)
  noticeManager:OpenTipPage(self, msg)
end

function MubarCopyDetailsPage:_ClickDetails(go, params)
  local copyDisplay = params[1]
  local serCopyInfo = params[2]
  local areaConfig = {
    copyType = CopyType.COMMONCOPY,
    tabSerData = serCopyInfo,
    chapterId = self.chapterInfo.id,
    IsRunningFight = false,
    copyId = copyDisplay.id
  }
  Logic.copyLogic:SetEnterLevelInfo(true)
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if not isHasFleet then
    noticeManager:OpenTipPage(self, 110007)
    return
  end
  UIHelper.OpenPage("LevelDetailsPage", areaConfig)
end

function MubarCopyDetailsPage:_CheckCopyIsLock(copyDisplay)
  if Data.userData:GetUserLevel() < copyDisplay.level_limit then
    return true, string.format(UIHelper.GetString(130006), copyDisplay.level_limit)
  end
  for _, copyId in ipairs(copyDisplay.unlock_clear_request) do
    local copyInfo = Data.copyData:GetMubarCopyInfoById(copyId)
    if not copyInfo or copyInfo.FirstPassTime == 0 then
      return true, UIHelper.GetString(130007)
    end
  end
  local serCopyInfo = Data.copyData:GetMubarCopyInfoById(copyDisplay.id)
  if not serCopyInfo then
    return true, "\229\189\147\229\137\141\231\171\160\232\138\130\230\156\170\229\188\128\229\144\175"
  end
  return false
end

function MubarCopyDetailsPage:_ClickBack()
  UIHelper.SetUILock(true)
  for _, part in ipairs(self.pointPartTab) do
    part.anim_copyPoint.enabled = false
    part.anim_copyPoint:Play("eff_ui_copypointout")
    part.anim_copyPoint.enabled = true
  end
  for _, lineAnima in ipairs(self.animaLinePart) do
    lineAnima.enabled = false
    lineAnima:Play("eff_ui_CopyLineOut")
    lineAnima.enabled = true
  end
  self.tab_Widgets.anim_select:Play("CopyDetailsOut")
  self.tab_Widgets.anim_copyBg:Play("eff_ui_CopyBackgroundout")
  self.tab_Widgets.anim_select.enabled = true
  self.tab_Widgets.anim_copyBg.enabled = true
  local timer = self:CreateTimer(function()
    UIHelper.ClosePage(self:GetName())
    UIHelper.SetUILock(false)
  end, 1.3, 1, false)
  self:StartTimer(timer)
end

function MubarCopyDetailsPage:_ClickOutpost()
  local openParam = {
    chapterInfo = self.chapterInfo
  }
  UIHelper.OpenPage("MubarOutpostPage", openParam)
end

function MubarCopyDetailsPage:DoOnHide()
end

function MubarCopyDetailsPage:DoOnClose()
end

return MubarCopyDetailsPage
