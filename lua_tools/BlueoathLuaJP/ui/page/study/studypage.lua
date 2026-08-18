local StudyPage = class("UI.Study.StudyPage", LuaUIPage)
local StudyProgress = require("ui.page.Study.StudyProgress")
StudyPage.AnimType = {
  EncourageOne = 1,
  EncourageTwo = 2,
  Start = 3,
  Stop = 4
}
StudyPage.Anim = {
  [StudyPage.AnimType.EncourageOne] = "learn_click1",
  [StudyPage.AnimType.EncourageTwo] = "learn_click2",
  [StudyPage.AnimType.Start] = "learn_start",
  [StudyPage.AnimType.Stop] = "learn_complete"
}
StudyPage.StudyDressUpId = 306301101

function StudyPage:DoInit()
  self.m_tabWidgets = nil
  UIHelper.AdapteShipRT(self.tab_Widgets.trans_girl)
end

function StudyPage:DoOnOpen()
  Logic.studyLogic.emptyCheck = true
  RetentionHelper.Retention(PlatformDotType.uilog, {info = "ui_school"})
  local widgets = self:GetWidgets()
  self.param = self.param or self.GenDisplayData()
  self.m_data = self:GetParam()
  if not self.m_teachGirl then
    local model = Logic.shipLogic:GetHeroModelPath(self.m_data.displayGirl)
    local param = {
      showID = self.m_data.displayGirl
    }
    self.m_teachGirl = UIHelper.Create3DModel(param, widgets.img_girl, CamDataType.Study)
    widgets.img_girl.gameObject:SetActive(true)
  else
    self.m_teachGirl:Show()
    widgets.img_girl.gameObject:SetActive(true)
  end
  self.m_teachGirl:Get3dObj():playBehaviour("learn_loop", true)
  self:RefreshAll(self.m_data)
  self:OpenTopPage("StudyPage", 1, UIHelper.GetString(160001), self, true)
  local flow = Logic.studyLogic:GetStudyFlow()
  flow:Input(flow.InputType.EnterMain)
end

function StudyPage:RegisterAllEvent()
  self:RegisterUIEvent()
  self:RegisterServiceEvent()
  self:RegisterEvent(LuaEvent.FinishStudyCheck, function(_, heroId)
    self.m_data = self.GenDisplayData()
    if self.m_data.finishNum > 0 then
      Logic.studyLogic:SendFinshedStudyByHero(heroId)
    end
  end)
end

function StudyPage:RegisterUIEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_new, function(go)
    if not Logic.studyLogic:GetSendEnd() then
      return
    end
    local flow = Logic.studyLogic:GetStudyFlow()
    flow:Input(flow.InputType.AddNewStudy)
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_girl, function(go)
    local sType = math.random(StudyPage.AnimType.EncourageOne, StudyPage.AnimType.EncourageTwo)
    local girl3DObj = self.m_teachGirl:Get3dObj()
    girl3DObj:playBehaviour(StudyPage.Anim[sType], false, function()
      girl3DObj:playBehaviour("learn_loop", true)
    end)
  end)
  self:RegisterEvent(LuaEvent.StudyEndTweenFinish, function(self, param)
    Data.studyData:RemoveDataByHeroId(param)
    self.m_data = self.GenDisplayData()
    self:RefreshAll(self.m_data)
  end)
end

function StudyPage:RegisterServiceEvent()
  self:RegisterEvent(LuaEvent.StartStudy, self._BeginStudy)
  self:RegisterEvent(LuaEvent.FinishStudy, self._FinishStudy)
  self:RegisterEvent(LuaEvent.CancelStudy, self._StopStudy)
  self:RegisterEvent(LuaEvent.StudyUpSuccess, function()
    self.m_data = self.GenDisplayData()
    self:RefreshAll(self.m_data)
  end)
end

function StudyPage:DoOnHide()
  local widgets = self:GetWidgets()
  if self.m_teachGirl then
    self.m_teachGirl:Hide()
    widgets.img_girl.gameObject:SetActive(fasle)
  end
end

function StudyPage:DoOnClose()
  local widgets = self:GetWidgets()
  local progressArr = self.m_progressArr
  for _, progress in pairs(progressArr) do
    progress:OnClose()
  end
  local flow = Logic.studyLogic:GetStudyFlow()
  flow:Input(flow.InputType.Leave)
  if self.m_teachGirl then
    UIHelper.Close3DModel(self.m_teachGirl)
    widgets.img_girl.gameObject:SetActive(fasle)
    self.m_teachGirl = nil
  end
end

function StudyPage.GenDisplayData()
  local displayData = {
    MaxDisplayNum = Logic.studyLogic:GetStudyCapacity(),
    displayGirl = Logic.studyLogic:GetDisPlayGirl()
  }
  displayData.studyDisplayInfoArr = {}
  displayData.finishNum = 0
  local serverData = Data.studyData:GetStudyData()
  for i, studyInfo in ipairs(serverData.ArrProgress) do
    local heroInfo = Data.heroData:GetHeroById(studyInfo.HeroId)
    local displayInfo = {}
    local si_id = Logic.shipLogic:GetShipInfoId(heroInfo.TemplateId)
    local shipShow = Logic.shipLogic:GetShipShowByHeroId(heroInfo.HeroId)
    displayInfo.heroId = studyInfo.HeroId
    displayInfo.pskillLv = Mathf.ToInt(Logic.shipLogic:GetHeroPSkillLv(studyInfo.HeroId, studyInfo.PSkillId))
    displayInfo.finishTime = Logic.studyLogic:GetStudyFinish(studyInfo.HeroId, studyInfo.PSkillId)
    displayInfo.curExp = Logic.shipLogic:GetHeroPSkillExp(studyInfo.HeroId, studyInfo.PSkillId)
    displayInfo.lastLvExp, displayInfo.nextLvExp = Logic.shipLogic:GetPSkillLvLowerAndUpper(displayInfo.pskillLv)
    displayInfo.pskillName = Logic.shipLogic:GetPSkillName(studyInfo.PSkillId)
    displayInfo.pskillDesc = Logic.shipLogic:GetPSkillDesc(studyInfo.PSkillId, displayInfo.pskillLv, true)
    displayInfo.pskillType = Logic.shipLogic:GetPSkillType(studyInfo.PSkillId)
    displayInfo.pskillIcon = Logic.shipLogic:GetPSkillIcon(studyInfo.PSkillId, heroInfo.TemplateId)
    displayInfo.shipIcon = Logic.shipLogic:GetHeroCardIcon(shipShow.ss_id)
    displayInfo.shipQuality = Logic.shipLogic:GetQualityByInfoId(si_id)
    displayInfo.shipName = Logic.shipLogic:GetRealName(displayInfo.heroId)
    displayInfo.pskillId = studyInfo.PSkillId
    displayInfo.itemId = studyInfo.TextbookId
    displayInfo.beginTime = studyInfo.BeginTime
    displayInfo.bFinish = displayInfo.finishTime <= time.getSvrTime()
    if displayInfo.bFinish == true then
      displayData.finishNum = displayData.finishNum + 1
    end
    table.insert(displayData.studyDisplayInfoArr, displayInfo)
  end
  return displayData
end

function StudyPage:RefreshAll(displayData)
  self:SaveNewParam(displayData)
  self:_RefreshStudyList(displayData.studyDisplayInfoArr)
  self:_CheckAndRefreshNew(#displayData.studyDisplayInfoArr, displayData.MaxDisplayNum)
end

function StudyPage:_RefreshStudyList(displayInfoArr)
  local widgets = self:GetWidgets()
  self.m_progressArr = self.m_progressArr or {}
  UIHelper.CreateSubPart(widgets.obj_progress, widgets.trans_studyRoot, #displayInfoArr, function(index, part)
    self:_RefreshSingleProgress(index, part)
  end)
end

function StudyPage:_RefreshSingleProgress(index, part)
  local param = self.m_data
  local displayInfo = param.studyDisplayInfoArr[index]
  self.m_progressArr[index] = self.m_progressArr[index] or StudyProgress:new()
  local progress = self.m_progressArr[index]
  progress:SetData(displayInfo, part)
  progress:Display()
end

function StudyPage:_CheckAndRefreshNew(num, maxNum)
  local widgets = self:GetWidgets()
  widgets.obj_new:SetActive(num < maxNum)
end

function StudyPage:_BeginStudy()
  local girl3DObj = self.m_teachGirl:Get3dObj()
  girl3DObj:playBehaviour(StudyPage.Anim[StudyPage.AnimType.Start], false, function()
    girl3DObj:playBehaviour("learn_loop", true)
  end)
  self.m_data = self.GenDisplayData()
  self:RefreshAll(self.m_data)
end

function StudyPage:_FinishStudy(ret)
  local girl3DObj = self.m_teachGirl:Get3dObj()
  if girl3DObj:GetBehaviourName() ~= StudyPage.Anim[StudyPage.AnimType.Stop] then
    girl3DObj:playBehaviour(StudyPage.Anim[StudyPage.AnimType.Stop], false, function()
      girl3DObj:playBehaviour("learn_loop", true)
    end)
  end
  self.m_data = self.GenDisplayData()
  for i, v in ipairs(self.m_progressArr) do
    if v.m_data.heroId == ret.HeroId then
      local ok, seq = v:GenExpAddSeq(ret)
      if ok then
        seq:Play(true)
      end
    end
  end
end

function StudyPage:_ShowFinishStudyMsgBox(sm_id, pskillId, expBefore, expAfter)
  local si_id = Logic.shipLogic:GetShipInfoId(sm_id)
  local shipName = Logic.shipLogic:GetName(si_id)
  local shipQuality = Logic.shipLogic:GetQualityByInfoId(si_id)
  local skillName = Logic.shipLogic:GetPSkillName(pskillId)
  local skillQuality = Logic.shipLogic:GetPSkillType(pskillId)
  local skillColor = TalentColor[skillQuality]
  local shipColor = ShipQualityColor[shipQuality]
  local exp = expAfter - expBefore
  local beforeLv = Logic.shipLogic:GetPSkillLvByExp(expBefore)
  local afterLv = Logic.shipLogic:GetPSkillLvByExp(expAfter)
  local strRet = string.format(UIHelper.GetString(160010), UIHelper.SetColor(shipName, shipColor), UIHelper.SetColor(skillName, skillColor), Mathf.ToInt(exp), beforeLv, afterLv)
end

function StudyPage:_StopStudy()
  self.m_data = self.GenDisplayData()
  self:RefreshAll(self.m_data)
end

return StudyPage
