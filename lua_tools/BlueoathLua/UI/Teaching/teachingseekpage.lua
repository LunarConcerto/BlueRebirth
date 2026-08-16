local TeachingSeekPage = class("UI.Teaching.TeachingSeekPage", LuaUIPage)

function TeachingSeekPage:DoInit()
  self.m_type2img = {
    "uipic_ui_teaching_im_xunzhaodaoshi",
    "uipic_ui_teaching_im_xunzhaoxueyuan"
  }
end

function TeachingSeekPage:DoOnOpen()
  local index = self.param.index
  self:_Refresh()
end

function TeachingSeekPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_info, self._OnClickInfo, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_find, self._OnClickFind, self)
end

function TeachingSeekPage:_Refresh()
  local widgets = self:GetWidgets()
  local state = Logic.teachingLogic:GetUserCanTeachState()
  local str = state == ETeachingState.TEACHER and self.m_type2img[2] or self.m_type2img[1]
  UIHelper.SetImage(widgets.im_find, str)
end

function TeachingSeekPage:_OnClickInfo()
  UIHelper.OpenPage("TeachingInfoPage")
end

function TeachingSeekPage:_OnClickFind()
  local state = Logic.teachingLogic:GetUserCanTeachState()
  local ok, msg
  if state == ETeachingState.NONE then
    noticeManager:ShowTip(UIHelper.GetString(2200084))
    return
  elseif state == ETeachingState.TEACHER then
    ok, msg = Logic.teachingLogic:CheckFindStudent()
  else
    ok, msg = Logic.teachingLogic:CheckFindTeacher()
  end
  if ok then
    UIHelper.OpenPage("TeachingFindPage")
  else
    noticeManager:ShowTip(msg)
  end
end

function TeachingSeekPage:_FindTeacher()
end

function TeachingSeekPage:_FindStudent()
end

function TeachingSeekPage:DoOnHide()
end

function TeachingSeekPage:DoOnClose()
end

return TeachingSeekPage
