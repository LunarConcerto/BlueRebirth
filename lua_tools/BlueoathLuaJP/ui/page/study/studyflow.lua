local StudyFlow = class("StudyFlow")
StudyPage = require("ui.page.Study.StudyPage")
SelectSkillPage = require("ui.page.Study.SelectSkillPage")
SelectTextbookPage = require("ui.page.Study.SelectTextbookPage")
StudyFlow.ins = nil
StudyFlow.State = {
  Any = 1,
  Main = 2,
  SelectHero = 3,
  SelectSkill = 4,
  SelectTextbook = 5,
  Confirm = 6,
  StudyResult = 7,
  CancelStudyConfirm = 8,
  None = 9
}
StudyFlow.InputType = {
  EnterMain = 1,
  AddNewStudy = 2,
  SelectHero = 3,
  SelectSkill = 4,
  SelectTextbook = 5,
  Confirm = 6,
  Cancel = 7,
  FinishStudy = 8,
  CancelStudy = 9,
  Leave = 10,
  ContinueLearn = 11
}
local MAX_SELECTNUM = 1

function StudyFlow:initialize()
  self.m_state = self.State.None
  self:RegisterEvent()
  self.data = {}
end

function StudyFlow:RegisterEvent()
end

function StudyFlow.GetInstance()
  StudyFlow.ins = StudyFlow.ins or StudyFlow:new()
  return StudyFlow.ins
end

function StudyFlow:Input(input, ...)
  local param = {
    ...
  }
  local State = self.State
  local InputType = self.InputType
  local curState = self.m_state
  if curState == State.None and input == InputType.EnterMain then
    self.m_state = State.Main
  end
  if input == InputType.Leave then
    self.m_state = State.None
  end
  if curState == State.Main and input == InputType.CancelStudy then
    local heroId = param[1]
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:Input(InputType.Confirm, heroId)
        else
          self:Input(InputType.Cancel)
        end
      end
    }
    noticeManager:ShowMsgBox(160011, tabParams)
    self.m_state = State.CancelStudyConfirm
  end
  if curState == State.CancelStudyConfirm then
    if input == InputType.Confirm then
      local heroId = param[1]
      Service.studyService:SendCancelStudy(heroId)
      self.m_state = State.Main
    elseif input == InputType.Cancel then
      self.m_state = State.Main
    end
  end
  if curState == State.Main and input == InputType.AddNewStudy then
    local textbookArr = Logic.bagLogic:GetItemArrByItemType(BagItemType.SHIP_TALENT_UPGRADE)
    if #textbookArr == 0 then
      local skillBookId = configManager.GetDataById("config_parameter", 166).value
      globalNoitceManager:ShowItemInfoPage(GoodsType.TALENT_UPGRADE_ITEM, skillBookId)
      noticeManager:ShowTipById(160012)
      return false
    end
    if not Logic.studyLogic:CheckHasSkillCanLvUp() then
      noticeManager:ShowMsgBox(UIHelper.GetString(160013))
      self.m_state = State.Main
      return
    end
    local heroIdArr = Logic.studyLogic:GetHeroArrCanStudy()
    local studyDisplayInfo = {}
    for i, heroId in ipairs(heroIdArr) do
      local hero = Data.heroData:GetHeroById(heroId)
      table.insert(studyDisplayInfo, hero)
    end
    UIHelper.OpenPage("CommonSelectPage", {
      CommonHeroItem.Study,
      studyDisplayInfo,
      {m_selectMax = MAX_SELECTNUM}
    })
    self.m_state = State.SelectHero
  end
  if curState == State.SelectHero and input == InputType.Confirm then
    local selectHeroId = param[1][1]
    self.data.heroId = selectHeroId
    local pskillArr = Logic.shipLogic:GetPSkillActiveArrbyHeroId(selectHeroId)
    UIHelper.Back()
    UIHelper.OpenPage("SelectSkillPage", SelectSkillPage.GenDisplayData(pskillArr, heroId))
    self.m_state = State.SelectSkill
  end
  if curState == State.SelectSkill and input == InputType.Confirm then
    local pskillId = param[1][1]
    self.data.pskillId = pskillId
    local textbookArr = Logic.bagLogic:GetItemArrByItemType(BagItemType.SHIP_TALENT_UPGRADE)
    UIHelper.ClosePage("SelectSkillPage")
    UIHelper.OpenPage("SelectTextbookPage", SelectTextbookPage.GenDisplayData(textbookArr, pskillId))
    self.m_state = State.SelectTextbook
  end
  if curState == State.SelectTextbook and input == InputType.Confirm then
    local textbookId = param[1][1]
    self.data.textbookId = textbookId
    UIHelper.ClosePage("SelectTextbookPage")
    local textbookName = Logic.studyLogic:GetTextBookName(self.data.textbookId)
    local si_id = Logic.shipLogic:GetShipInfoId(Data.heroData:GetHeroById(self.data.heroId).TemplateId)
    local heroName = Logic.shipLogic:GetRealName(self.data.heroId)
    local heroQuality = Logic.shipLogic:GetQualityByInfoId(si_id)
    local skillName = Logic.shipLogic:GetPSkillName(self.data.pskillId)
    local skillType = Logic.shipLogic:GetPSkillType(self.data.pskillId)
    local textbookType = Logic.studyLogic:GetTextBookType(textbookId)
    local nameColor = TalentColor[skillType]
    local qualityColor = ShipQualityColor[heroQuality]
    local textbookColor = TalentColor[textbookType]
    local duration = Logic.studyLogic:GetTextBookDuration(self.data.textbookId)
    local exp = Logic.studyLogic:GetTextBookExp(self.data.textbookId, self.data.pskillId)
    local strConfirm = string.format(UIHelper.GetString(160006), UIHelper.SetColor(textbookName, textbookColor), UIHelper.SetColor(heroName, qualityColor), UIHelper.SetColor(skillName, nameColor), duration, exp)
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:Input(InputType.Confirm)
        else
          self:Input(InputType.Cancel)
        end
      end,
      guidedefineId = 53
    }
    noticeManager:ShowMsgBox(strConfirm, tabParams)
    self.m_state = State.Confirm
  end
  if curState == State.Confirm then
    if input == InputType.Confirm then
      local data = self.data
      local heroId, pskillId, textbookId = data.heroId, data.pskillId, data.textbookId
      Service.studyService:SendStartStudy(heroId, pskillId, textbookId)
      self.m_state = State.Main
    elseif input == InputType.Cancel then
      self.m_state = State.Main
      eventManager:SendEvent(LuaEvent.StudyEndTweenFinish, self.data.heroId)
    end
  end
  if input == InputType.Cancel and curState ~= State.Confirm and curState ~= State.SelectHero then
    UIHelper.ClosePage("StudyFlow")
    self.m_state = State.Main
  end
  if input == InputType.Cancel and curState == State.SelectHero then
    UIHelper.ClosePage("StudyFlow")
    self.m_state = State.Main
  end
  if input == InputType.Cancel and curState == State.SelectHero then
    UIHelper.Back()
    self.m_state = State.Main
  end
  if input == InputType.ContinueLearn then
    self.m_state = State.SelectTextbook
    self.data.pskillId = param[1].PSkillId
    self.data.heroId = param[1].HeroId
  end
end

return StudyFlow
