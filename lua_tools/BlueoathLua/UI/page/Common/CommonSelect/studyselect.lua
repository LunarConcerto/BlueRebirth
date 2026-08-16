local StudySelect = class("ui.page.Common.CommonSelect.StudySelect")

function StudySelect:initialize()
  self.m_page = nil
  self.m_widgets = nil
  self.m_tabParams = nil
end

function StudySelect:Init(page, tabParams)
  self.m_page = page
  self.m_widgets = page.m_tabWidgets
  self.m_tabParams = tabParams
  self.m_page:OpenTopPage("CommonSelectPage", 1, "\232\136\185\229\157\158", self, true, self._StudyCancel)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_ok, self._StudyConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_cancal, self._StudyCancel, self)
  local dotinfo = {
    info = "ui_shipyard",
    type = "school_shipyard"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  self.m_page.m_tabSelectShip = tabParams.m_selectedIdList or {}
end

function StudySelect:_StudyConfirm()
  local flow = Logic.studyLogic:GetStudyFlow()
  local heroIdArr = self.m_page.m_tabSelectShip
  if #heroIdArr == 0 then
    noticeManager:OpenTipPage(self, "\232\175\183\233\128\137\230\139\169\230\136\152\229\167\172")
    return
  end
  flow:Input(flow.InputType.Confirm, heroIdArr)
end

function StudySelect:_StudyCancel()
  local flow = Logic.studyLogic:GetStudyFlow()
  flow:Input(flow.InputType.Cancel)
end

return StudySelect
