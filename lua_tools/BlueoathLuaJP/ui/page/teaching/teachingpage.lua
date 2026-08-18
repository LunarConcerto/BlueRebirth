local TeachingPage = class("UI.Teaching.TeachingPage", LuaUIPage)
local togTeacherText = {
  {2200027},
  {
    2200037,
    {73}
  },
  {
    2200038,
    {75}
  },
  {2200039},
  {2200040}
}
local togStudentText = {
  {2200025},
  {
    2200041,
    {71, 72}
  },
  {
    2200038,
    {74}
  },
  {2200042},
  {2200040}
}
local OpenStudentPage = {
  "TeachingUserPage",
  "TeachingMissionPage",
  "TeachingUserPage",
  "TeachingSeekPage",
  "TeachingRankPage"
}
local OpenTeacherPage = {
  "TeachingUserPage",
  "TeachingLifePage",
  "TeachingUserPage",
  "TeachingSeekPage",
  "TeachingRankPage"
}

function TeachingPage:DoInit()
  self.isTeacher = false
  self.pageTab = nil
  self.selectTog = 0
  if Logic.teachingLogic:OpenedTeachingSystem() then
    local userData = Data.userData:GetUserData()
    PlayerPrefs.SetBool("OpenedTeachingSystem" .. userData.Uid, true)
    eventManager:SendEvent(LuaEvent.TeachingOpened)
  end
end

function TeachingPage:DoOnOpen()
  self.isTeacher = Logic.teachingLogic:CheckIsTeacher()
  self.pageTab = self.isTeacher and OpenTeacherPage or OpenStudentPage
  self:_LoadTogGroup()
  self.tab_Widgets.tog_group:SetActiveToggleIndex(self.selectTog)
end

function TeachingPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.TeacherCheckTask, self._TeacherCheckTask, self)
  self:RegisterEvent(LuaEvent.TeacherCloseCheckTask, self._CloseCheckTask, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_shop, self._OpenShop, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._OpenHelp, self)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
end

function TeachingPage:_LoadTogGroup()
  local togTable = self.isTeacher and togTeacherText or togStudentText
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_togGroup, #togTeacherText, function(nIndex, tabPart)
    tabPart.txt_name.text = UIHelper.GetString(togTable[nIndex][1])
    if togTable[nIndex][2] ~= nil then
      self:RegisterRedDotById(tabPart.redDot, togTable[nIndex][2])
    end
    self.tab_Widgets.tog_group:RegisterToggle(tabPart.tog_item)
  end)
end

function TeachingPage:_SwitchTogs(index)
  self.selectTog = index
  if self.isTeacher then
    UIHelper.ClosePage("TeachingMissionPage")
  end
  if index == TeachingIndex.Apply then
    Data.teachingData:SetApplyRedState()
  end
  local param = {index = index}
  self:OpenSubPage(self.pageTab[index + 1], param)
end

function TeachingPage:_OpenShop()
  moduleManager:JumpToFunc(FunctionID.Shop, ShopId.TeachingShop)
end

function TeachingPage:_TeacherCheckTask()
  self:CloseSubPage(self.pageTab[self.selectTog + 1])
end

function TeachingPage:_CloseCheckTask()
  if self.selectTog == 0 then
    self:OpenSubPage(self.pageTab[self.selectTog + 1], {
      index = self.selectTog
    })
  end
end

function TeachingPage:_OpenHelp()
  UIHelper.OpenPage("HelpPage", {content = 2200066})
end

function TeachingPage:DoOnHide()
  self.tab_Widgets.tog_group:ClearToggles()
end

function TeachingPage:DoOnClose()
  if self.isTeacher then
    UIHelper.ClosePage("TeachingMissionPage")
  end
  self.tab_Widgets.tog_group:ClearToggles()
end

return TeachingPage
