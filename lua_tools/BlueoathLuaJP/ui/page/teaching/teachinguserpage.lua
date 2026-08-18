local TeachingUserPage = class("UI.Teaching.TeachingUserPage", LuaUIPage)
local teachingUserItem = require("ui.page.Teaching.TeachingUserItem")

function TeachingUserPage:DoInit()
  self.isTeacher = false
  self.listInfo = {}
  self.selectType = 0
  self.selectStudent = nil
  self.addBtn = {
    2200043,
    self._AddFriend,
    "uipic_ui_common_bu_fang_lan"
  }
  self.deleteBtn = {
    2200044,
    self._RelieveRelation,
    "uipic_ui_common_bu_fang_hui"
  }
  self.chatBtn = {
    2200045,
    self._Chat,
    "uipic_ui_common_bu_fang_lan"
  }
  self.taskBtn = {
    2200064,
    self._CheckTask,
    "uipic_ui_common_bu_fang_lan"
  }
  self.refuseBtn = {
    2200046,
    self._Refuse,
    "uipic_ui_common_bu_fang_hui"
  }
  self.acceptBtn = {
    2200047,
    self._Accept,
    "uipic_ui_common_bu_fang_lv"
  }
end

function TeachingUserPage:DoOnOpen()
  self.isTeacher = Logic.teachingLogic:CheckIsTeacher()
  self.selectType = self.param.index
  local mineStr = self.isTeacher and UIHelper.GetString(2200002) or UIHelper.GetString(2200001)
  local applyStr = self.isTeacher and UIHelper.GetString(2200020) or UIHelper.GetString(2200019)
  self.tab_Widgets.txt_tips.text = self.selectType == TeachingIndex.Mine and mineStr or applyStr
  self.tab_Widgets.obj_applicationTips:SetActive(self.selectType == TeachingIndex.Apply)
  self.tab_Widgets.tx_application.text = self.isTeacher and UIHelper.GetString(2200048) or UIHelper.GetString(2200049)
  self.tab_Widgets.obj_application:SetActive(self.selectType == TeachingIndex.Apply)
  local bgImg = self.selectType == TeachingIndex.Apply and "uipic_ui_teaching_bg_xiadiban_02" or "uipic_ui_teaching_bg_xiadiban_01"
  UIHelper.SetImage(self.tab_Widgets.img_bg, bgImg)
  self:_UpdateUserInfo()
end

function TeachingUserPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.TeachingRefuseApply, self._UpdateUserInfo, self)
  self:RegisterEvent(LuaEvent.TEACHING_GetApplys, self._UpdateUserInfo, self)
  self:RegisterEvent(LuaEvent.TEACHING_GetTeachOrStudyInfo, self._UpdateUserInfo, self)
  self:RegisterEvent(LuaEvent.TeachingAgreeApply, self._AgreeUpdate, self)
  self:RegisterEvent(LuaEvent.TeachingDeleteSucceed, self._DeleteUpdate, self)
  self:RegisterEvent(LuaEvent.TEACHING_AcceptErr, self._AgreeErr, self)
  self:RegisterEvent(LuaEvent.TASK_GetSTeachingTask, self._OpenMissionPage, self)
  self:RegisterEvent(LuaEvent.TeachingUpdateInfo, self._UpdateUserInfo, self)
end

function TeachingUserPage:_AgreeUpdate()
  if self.selectType ~= TeachingIndex.Mine then
    noticeManager:ShowTip(UIHelper.GetString(210008))
  end
  self:_UpdateUserInfo()
end

function TeachingUserPage:_AgreeErr(code)
end

function TeachingUserPage:_DeleteUpdate(uid)
  noticeManager:ShowTip(UIHelper.GetString(2200050))
  Logic.teachingLogic:RemoveApplyUsr(uid)
  self:_UpdateUserInfo()
end

function TeachingUserPage:_UpdateUserInfo()
  self.listInfo = self.selectType == TeachingIndex.Mine and Logic.teachingLogic:GetTeachingInfo(self.isTeacher) or Logic.teachingLogic:GetRequestList()
  self:_SetUserInfo()
  self:_SetTSpecialInfo()
end

function TeachingUserPage:_SetUserInfo()
  self.tab_Widgets.obj_tips:SetActive(#self.listInfo <= 0)
  self.tab_Widgets.obj_teachingList:SetActive(#self.listInfo > 0)
  self:_LoadUserList()
end

function TeachingUserPage:_LoadUserList()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.trans_teaching, self.tab_Widgets.obj_teachingItem, #self.listInfo, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local data = self.listInfo[nIndex]
      local item = teachingUserItem:new()
      item:Init(self, tabPart, nIndex, data)
      tabPart.obj_identity:SetActive(self.selectType == TeachingIndex.Mine)
      if data.CreateTime == 0 then
        tabPart.tx_identity.text = data.TeachingStatus == ETeachingState.STUDENT and UIHelper.GetString(2200028) or UIHelper.GetString(2200026)
      else
        tabPart.tx_identity.text = data.TeachingStatus == ETeachingState.STUDENT and UIHelper.GetString(2200027) or UIHelper.GetString(2200025)
      end
      local imgBg = data.TeachingStatus == ETeachingState.STUDENT and "uipic_ui_teaching_bg_xueyuanbiaoqian" or "uipic_ui_teaching_bg_daoshibiaoqian"
      UIHelper.SetImage(tabPart.img_identityBg, imgBg)
      local showBtn = self:GetBtnList(data)
      UIHelper.CreateSubPart(tabPart.obj_itemButton, tabPart.trans_button, #showBtn, function(nIndex, tabPart)
        local btnInfo = showBtn[nIndex]
        tabPart.txt_btntext.text = UIHelper.GetString(btnInfo[1])
        UIHelper.SetImage(tabPart.img_bg, btnInfo[3])
        UGUIEventListener.AddButtonOnClick(tabPart.btn_info, function()
          btnInfo[2](self, data)
        end)
      end)
    end
  end)
end

function TeachingUserPage:_AddFriend(info)
  Logic.teachingLogic:AddFriendWrap(info)
end

function TeachingUserPage:_RelieveRelation(info)
  Logic.teachingLogic:ReleaseWrap(info)
end

function TeachingUserPage:_Chat(info)
  Logic.teachingLogic:ChatWrap(info.UserInfo)
end

function TeachingUserPage:_Refuse(info)
  Logic.teachingLogic:RefuseWrap(info.Uid)
end

function TeachingUserPage:_Accept(info)
  Logic.teachingLogic:AcceptWrap(info)
end

function TeachingUserPage:_SetTSpecialInfo()
  if not self.isTeacher or self.selectType == TeachingIndex.Apply then
    self.tab_Widgets.obj_studentNum:SetActive(false)
    self.tab_Widgets.obj_medalNum:SetActive(false)
    return
  end
  self.tab_Widgets.obj_studentNum:SetActive(true)
  self.tab_Widgets.obj_medalNum:SetActive(true)
  local curStudentNum = Logic.teachingLogic:GetCurStudentNum()
  self.tab_Widgets.txt_studentNum.text = curStudentNum .. "/" .. Logic.teachingLogic:GetTeachingNumUp()
  local medalInfo = Logic.teachingLogic:GetTeachingMedalNumUp()
  local userData = Data.userData:GetUserData()
  local img = Logic.currencyLogic:GetSmallIcon(medalInfo.ConfigId)
  UIHelper.SetImage(self.tab_Widgets.im_medalIcon, img)
  self.tab_Widgets.tx_medalNum.text = userData.TeacherMedalLimit > medalInfo.Num and medalInfo.Num .. "/" .. medalInfo.Num or userData.TeacherMedalLimit .. "/" .. medalInfo.Num
end

function TeachingUserPage:GetBtnList(data)
  local btnList = {}
  local isFriend = Logic.friendLogic:IsMyFriend(data.Uid)
  if not isFriend then
    table.insert(btnList, self.addBtn)
  end
  if data.TeachingStatus == ETeachingState.STUDENT and self.selectType == TeachingIndex.Mine then
    table.insert(btnList, self.taskBtn)
  end
  if self.selectType == TeachingIndex.Mine then
    if data.CreateTime ~= 0 then
      table.insert(btnList, self.deleteBtn)
    end
    table.insert(btnList, self.chatBtn)
  else
    table.insert(btnList, self.refuseBtn)
    table.insert(btnList, self.chatBtn)
    table.insert(btnList, self.acceptBtn)
  end
  return btnList
end

function TeachingUserPage:_CheckTask(info)
  local meetCond, str = Logic.teachingLogic:CheckGetSTask(info)
  if not meetCond then
    noticeManager:ShowTip(str)
    return
  end
  self.selectStudent = info
  Service.taskService:SendGetTeachingTask(info.Uid)
end

function TeachingUserPage:_OpenMissionPage()
  eventManager:SendEvent(LuaEvent.TeacherCheckTask)
  UIHelper.OpenPage("TeachingMissionPage", {
    self.selectStudent
  }, nil, false)
end

function TeachingUserPage:DoOnHide()
end

function TeachingUserPage:DoOnClose()
end

return TeachingUserPage
