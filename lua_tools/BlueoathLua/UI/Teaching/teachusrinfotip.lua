local TeachUsrInfoTip = class("UI.Teaching.TeachUsrInfoTip", LuaUIPage)
local teachingUserItem = require("ui.page.Teaching.TeachingUserItem")

function TeachUsrInfoTip:DoInit()
  self.m_btnConfig = {
    {
      Name = "\232\129\138\229\164\169",
      Func = self._Chat
    },
    {
      Name = "\230\183\187\229\138\160\229\165\189\229\143\139",
      Func = self._AddFriend
    },
    {
      Name = "\231\148\179\232\175\183\229\133\165\229\173\166",
      Func = self._RequesetStudy
    }
  }
  self.m_userInfo = nil
end

function TeachUsrInfoTip:DoOnOpen()
  self.m_userInfo = self:GetParam()
  if Data.teachingData:HaveOtherInfo(self.m_userInfo.Uid) then
    self:_Refresh()
  else
    self:_ShowRoot(false)
    Service.teachingService:SendGetOtherInfo(self.m_userInfo.Uid)
  end
end

function TeachUsrInfoTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_daoshi, self._ShowTeachingInfo, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_jiandui, self._ShowGuildInfo, self)
  self:RegisterEvent(LuaEvent.TEACHING_GetOtherInfo, self._OnGetOtherInfo, self)
  self:RegisterEvent(LuaEvent.TEACHING_SendApplyErr, self._OnSendApplyErr, self)
  self:RegisterEvent(LuaEvent.TEACHING_SendApplyOk, self._OnSendApplyOk, self)
end

function TeachUsrInfoTip:_Refresh()
  self:_ShowRoot(true)
  self:_ShowUsrInfo()
  self:_ShowExInfo()
  self:_ShowBtn()
end

function TeachUsrInfoTip:_ShowRoot(show)
  local widgets = self:GetWidgets()
  widgets.obj_fg:SetActive(show)
end

function TeachUsrInfoTip:_OnGetOtherInfo()
  self:_Refresh()
end

function TeachUsrInfoTip:_OnSendApplyErr(code)
end

function TeachUsrInfoTip:_OnSendApplyOk()
  noticeManager:ShowTip(UIHelper.GetString(210012))
end

function TeachUsrInfoTip:_ShowUsrInfo()
  local widgets = self:GetWidgets()
  local teachData = Data.teachingData:GetOtherInfo(self.m_userInfo.Uid)
  if teachData then
    local item = teachingUserItem:new()
    item:Init(self, widgets, 1, teachData)
  else
    logError("TEACHING FATAL:can not find other usr teaching info,uid:" .. self.m_userInfo.Uid)
  end
end

function TeachUsrInfoTip:_ShowExInfo()
  local widgets = self:GetWidgets()
  local teachData = Data.teachingData:GetOtherInfo(self.m_userInfo.Uid)
  local teachStr = "\230\154\130\230\151\160\230\173\164\228\191\161\230\129\175"
  local haveR = self:_haveRelation(teachData)
  if haveR then
    local data = teachData.Relation[1]
    local state = data.TeachingStatus == ETeachingState.TEACHER and "\229\173\166\229\145\152" or "\229\175\188\229\184\136"
    local name = Logic.teachingLogic:DisposeUname(data.UserInfo.Uname) or ""
    teachStr = name .. "\231\154\132" .. state
  end
  widgets.obj_teach:SetActive(haveR)
  UIHelper.SetText(widgets.tx_daoshi, teachStr)
  local usrData = self.m_userInfo
  local guildStr = "\230\154\130\230\151\160\230\173\164\228\191\161\230\129\175"
  if usrData.GuildId > 0 then
    guildStr = usrData.GuildName
  end
  UIHelper.SetText(widgets.tx_jiandui, guildStr)
  widgets.obj_guild:SetActive(usrData.GuildId > 0)
end

function TeachUsrInfoTip:_haveRelation(data)
  return data and data.UserInfo.Uid and #data.Relation > 0 and data.Relation[1].Uid
end

function TeachUsrInfoTip:_ShowBtn()
  local btn_config = clone(self.m_btnConfig)
  local mf = Logic.friendLogic:IsMyFriend(self.m_userInfo.Uid)
  if mf then
    table.remove(btn_config, 2)
  end
  local mid = Data.userData:GetUserUid()
  if mid == self.m_userInfo.Uid then
    btn_config = {}
  end
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.obj_btn, widgets.trans_btn, #btn_config, function(index, tabPart)
    local config = btn_config[index]
    UIHelper.SetText(tabPart.tx_btn, config.Name)
    UGUIEventListener.AddButtonOnClick(tabPart.obj_btn, config.Func, self)
  end)
end

function TeachUsrInfoTip:_CloseSelf()
  UIHelper.ClosePage("TeachingMessagePage")
end

function TeachUsrInfoTip:_ShowTeachingInfo()
  local teachData = Data.teachingData:GetOtherInfo(self.m_userInfo.Uid)
  if self:_haveRelation(teachData) then
    UIHelper.OpenPage("TeachingDetailsPage", {
      Usr = self.m_userInfo,
      Teach = teachData
    })
  else
    logError("TEACHING FATAL:can not find other teach data,uid:" .. self.m_userInfo.Uid)
  end
end

function TeachUsrInfoTip:_ShowGuildInfo()
  if not moduleManager:CheckFunc(FunctionID.Guild, true) then
    noticeManager:ShowTip(string.format(UIHelper.GetString(210024), "\229\133\172\228\188\154"))
    return
  end
  if self.m_userInfo.GuildId > 0 then
    UIHelper.OpenPage("TeachingFamilyPage", self.m_userInfo)
  else
    noticeManager:ShowTip("\230\154\130\230\151\160\230\173\164\228\191\161\230\129\175")
  end
end

function TeachUsrInfoTip:_Chat()
  Logic.teachingLogic:ChatWrap(self.m_userInfo)
end

function TeachUsrInfoTip:_AddFriend()
  local info = Data.teachingData:GetOtherInfo(self.m_userInfo.Uid)
  Logic.teachingLogic:AddFriendWrap(info)
end

function TeachUsrInfoTip:_RequesetStudy()
  local info = Data.teachingData:GetOtherInfo(self.m_userInfo.Uid)
  Logic.teachingLogic:RequesetStudyWrap(info)
end

function TeachUsrInfoTip:DoOnHide()
end

function TeachUsrInfoTip:DoOnClose()
end

return TeachUsrInfoTip
