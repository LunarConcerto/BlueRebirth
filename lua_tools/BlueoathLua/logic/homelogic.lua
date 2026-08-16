local HomeLogic = class("logic.HomeLogic")
HomeLogic.HomeBrowseId = {
  [InnerBrowseType.MobielPhone] = {107},
  [InnerBrowseType.Question] = {114}
}

function HomeLogic:initialize()
  self:RegisterAllEvent()
  self:ResetData()
end

function HomeLogic:ResetData()
  self.guideModelClick = false
  self.guideModelAnimEnd = false
  self.guideDragCamEnd = false
  self.leftIsOpen = false
  self.questionOpen = false
  self.curQuestionId = nil
  self.changeGirl = false
  self.questionIds = nil
end

function HomeLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.UpdateActivity, self.ResetRefreshTime, self)
end

function HomeLogic:GetIsLeft(functionId)
  local tabData = configManager.GetDataById("config_home_page", "1")
  for k, v in pairs(tabData.function_id) do
    if v == tostring(functionId) then
      return true
    end
  end
  return false
end

function HomeLogic:SetBrowseActiveInfo()
  announcementManager:SetBrowseActiveInfo()
end

function HomeLogic:GetActiveBrowseList()
  return announcementManager:GetActiveBrowseList()
end

function HomeLogic:GetAnswerQuestion()
  if not self.questionIds then
    self.questionIds = {}
    local setValue = Data.guideData:GetSettingByKey("sdk_question")
    if setValue then
      local tblValue = Unserialize(setValue)
      self.questionIds = tblValue
    end
  end
  return self.questionIds
end

function HomeLogic:QuestionAnswerOver(id)
  if not self.questionIds then
    self.questionIds = {}
  end
  local has = false
  for k, v in pairs(self.questionIds) do
    if v == id then
      has = true
      break
    end
  end
  if not has then
    table.insert(self.questionIds, id)
  end
end

function HomeLogic:SetLeftPageState(state)
  self.leftIsOpen = state
end

function HomeLogic:GetLeftPageState()
  return self.leftIsOpen
end

function HomeLogic:SetModelClick()
  self.guideModelClick = true
end

function HomeLogic:SetModelAnimEnd()
  self.guideModelAnimEnd = true
end

function HomeLogic:GetModelClick()
  return self.guideModelClick
end

function HomeLogic:GetModelAnimEnd()
  return self.guideModelAnimEnd
end

function HomeLogic:SetDragCamEnd()
  self.guideDragCamEnd = true
end

function HomeLogic:GetDragCamEnd()
  return self.guideDragCamEnd
end

function HomeLogic:ChangeEnd(secretaryId)
  local heroInfo = Data.heroData:GetHeroById(secretaryId)
  local shipShow = Logic.shipLogic:GetShipInfoByHeroId(secretaryId)
  self.quitMainId = heroInfo.TemplateId
  self.quitMainName = shipShow.ship_name
end

function HomeLogic:EntryChange(secretaryId)
  local heroInfo = Data.heroData:GetHeroById(secretaryId)
  local shipShow = Logic.shipLogic:GetShipInfoByHeroId(secretaryId)
  self.entryMainId = heroInfo.TemplateId
  self.entryName = shipShow.ship_name
end

function HomeLogic:GetSecretaryInfo()
  if self.entryMainId == nil then
    return
  end
  local info = {
    quit_mainID = self.quitMainId,
    quit_name = self.quitMainName,
    entry_mainID = self.entryMainId,
    entry_name = self.entryName
  }
  return info
end

function HomeLogic:SetChangeGirl(state)
  self.changeGirl = state
end

function HomeLogic:GetChangeGirl()
  return self.changeGirl
end

function HomeLogic:FilterShowBtn(funIdTab)
  local function checkFunc(tab)
    local showTab = {}
    
    for _, v in ipairs(tab) do
      if type(v) == "table" then
        local temp = checkFunc(v)
        table.insert(showTab, temp)
      elseif moduleManager:CheckFuncCanShow(v) then
        table.insert(showTab, v)
      end
    end
    return showTab
  end
  
  return checkFunc(funIdTab)
end

function HomeLogic:GetDefaultScene()
  local defaultSceneType = configManager.GetDataById("config_parameter", 173).value
  local sceneType = PlayerPrefs.GetInt("HomeSceneType", Mathf.ToInt(defaultSceneType))
  return sceneType
end

function HomeLogic:ResetRefreshTime()
  self.refreshTime = nil
end

function HomeLogic:UserRefresh()
  if Logic.loginLogic:GetLoginState() then
    local serverTime = time.getSvrTime()
    if not self.refreshTime or serverTime - self.refreshTime >= 60 then
      self.refreshTime = serverTime
      Service.userService:SendRefresh()
    end
  end
end

return HomeLogic
