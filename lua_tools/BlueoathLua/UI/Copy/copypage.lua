local CopyPage = class("UI.Copy.CopyPage", LuaUIPage)
local tabOpenPageName = {
  "PlotCopyMainPage",
  "SeaCopyPage",
  "ChallengePage",
  "DailyCopyPage"
}
local togIndex2FuncId = {
  FunctionID.PlotCopyMainPage,
  FunctionID.SeaCopy,
  FunctionID.GoodsCopy,
  FunctionID.DailyCopy
}

function CopyPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function CopyPage:RegisterAllEvent()
  self.tabLeftTogs = {
    self.m_tabWidgets.tog_plot,
    self.m_tabWidgets.tog_copy,
    self.m_tabWidgets.tog_support,
    self.m_tabWidgets.tog_everyDay
  }
  for i, tog in pairs(self.tabLeftTogs) do
    self.m_tabWidgets.tog_togGroup:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_togGroup, self, "", self._SwitchTogs)
  self:RegisterEvent(LuaEvent.GetCopyData, self._checkFunc, self)
  self:RegisterEvent(LuaEvent.ChangeCopyToggle, self._ChangeCopyToggle, self)
  self:RegisterEvent(LuaEvent.OpenPlotCopyPage, self._OpenPlotCopyPage, self)
end

function CopyPage:DoOnOpen()
  self:OpenTopPage("CopyPage", 2, "\230\181\183\229\159\159", self, true)
  SoundManager.Instance:PlayMusic("System|Expedition")
  local param = self:GetParam()
  self.paramConfig = param
  self:_checkFunc()
  local _, plotCopyId = Logic.copyLogic:GetCurPlotChapterSection()
  local copyInfo = Data.copyData:GetPlotCopyDataCopyId(plotCopyId)
  self.userInfo = Data.userData:GetUserData()
  self.uid = tostring(self.userInfo.Uid)
  local index = PlayerPrefs.GetInt(self.uid .. "NewCopyButtomIndex", 0)
  if type(param) == "number" then
    self.m_tabWidgets.tog_togGroup:SetActiveToggleIndex(param)
  elseif param ~= nil then
    if param.chapterId ~= nil then
      Logic.copyLogic:SetSelectChapter(param.selectCopy, param.chapterId)
    end
    self.m_tabWidgets.tog_togGroup:SetActiveToggleIndex(param.selectCopy)
  elseif not copyInfo or copyInfo.FirstPassTime == 0 and index == -1 then
    self.m_tabWidgets.tog_togGroup:SetActiveToggleIndex(0)
  else
    index = index == -1 and Logic.copyLogic.SelectCopyType.SeaCopy or index
    self.m_tabWidgets.tog_togGroup:SetActiveToggleIndex(index)
  end
  eventManager:SendEvent(LuaEvent.ShowOpenModule)
end

function CopyPage:_checkFunc()
  for index, funcId in pairs(togIndex2FuncId) do
    if not moduleManager:CheckFunc(funcId, false) then
      self.m_tabWidgets.tog_togGroup:ResigterToggleUnActive(index - 1, self._stopToggle)
    else
      self.m_tabWidgets.tog_togGroup:RemoveToggleUnActive(index - 1)
    end
  end
end

function CopyPage._stopToggle(index)
  moduleManager:CheckFunc(togIndex2FuncId[index + 1], true)
end

function CopyPage:_SwitchTogs(index)
  for _, pageName in pairs(tabOpenPageName) do
    if UIPageManager:IsExistPage(pageName) then
      UIHelper.ClosePage(pageName)
    end
  end
  PlayerPrefs.SetInt(self.uid .. "NewCopyButtomIndex", index)
  if self.paramConfig ~= nil then
    self:OpenSubPage(tabOpenPageName[index + 1], self.paramConfig)
  else
    self:OpenSubPage(tabOpenPageName[index + 1])
  end
end

function CopyPage:_OpenPlotCopyPage(param)
  UIHelper.OpenPage("PlotCopyPage", param)
end

function CopyPage:_ChangeCopyToggle(index)
  self.m_tabWidgets.tog_togGroup:SetActiveToggleIndex(index)
  self:_SwitchTogs(index)
end

function CopyPage:DoOnHide()
  self.m_tabWidgets.tog_togGroup:ClearToggles()
end

function CopyPage:DoOnClose()
  self.m_tabWidgets.tog_togGroup:ClearToggles()
end

return CopyPage
