local FindCommonTip = class("UI.Teaching.FindCommonTip", LuaUIPage)
local teachingUserItem = require("ui.page.Teaching.TeachingUserItem")

function FindCommonTip:DoInit()
  self.m_players = {}
end

function FindCommonTip:DoOnOpen()
  self:_ShowTitle()
  self:_ChangeImp(false)
end

function FindCommonTip:_OnGetRmd()
  local ok, players, msg = Logic.teachingLogic:GetRmdPlayers(not Logic.teachingLogic:CheckIsTeacher())
  if ok then
    self:_ShowPlayerInfos(players)
    self:_ShowTitle()
    Logic.teachingLogic:SetChangeUpdateTime(time.getSvrTime())
  elseif msg then
    noticeManager:ShowTip(msg)
  elseif Logic.teachingLogic:CheckIsTeacher() then
    noticeManager:ShowTip("\230\154\130\230\151\160\230\142\168\232\141\144\231\154\132\229\173\166\229\145\152")
  else
    noticeManager:ShowTip("\230\154\130\230\151\160\230\142\168\232\141\144\231\154\132\229\175\188\229\184\136")
  end
end

function FindCommonTip:_OnGetFind(ret)
  self:_ShowPlayerInfos(ret.UserInfo)
  self:_ShowTitle()
end

function FindCommonTip:_Refresh()
  self:_ShowTitle()
  self:_ShowPlayerInfos()
end

function FindCommonTip:_ShowTitle()
  local widgets = self:GetWidgets()
  local title = Logic.teachingLogic:CheckIsTeacher() and "\229\175\187\230\137\190\229\173\166\229\145\152" or "\229\175\187\230\137\190\229\175\188\229\184\136"
  UIHelper.SetText(widgets.tx_title, title)
end

function FindCommonTip:_ShowPlayerInfos(players)
  local widgets = self:GetWidgets()
  if players then
    self.m_players = players
  end
  local fullScore = Logic.teachingLogic:GetFullStarConfig()
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #self.m_players, function(index, tabPart)
    local item = teachingUserItem:new()
    local player = self.m_players[index]
    item:Init(self, tabPart, index, player)
    local isApply = Logic.teachingLogic:HaveApply(player.UserInfo.Uid)
    tabPart.tx_btn.text = Logic.teachingLogic:CheckIsTeacher() and "\230\139\155\230\148\182\229\173\166\229\145\152" or "\231\148\179\232\175\183\229\133\165\229\173\166"
    tabPart.obj_shenqing:SetActive(not isApply)
    tabPart.obj_wancheng:SetActive(isApply)
    UGUIEventListener.AddButtonOnClick(tabPart.obj_shenqing, self._OnClickApply, self, player)
    local show = Logic.teachingLogic:CanShowEva(player.AppraiseTimes)
    tabPart.obj_score:SetActive(show)
    local score = player.Appraise or 0
    local showscore = score * 1.0E-4
    UIHelper.SetText(tabPart.tx_score, showscore)
    local star, remain = Logic.teachingLogic:Score2Star(score)
    local max = Logic.teachingLogic:GetEvaStarMax()
    UIHelper.CreateSubPart(tabPart.obj_starbg, tabPart.trans_starbg, max, function(index, parts)
    end)
    UIHelper.CreateSubPart(tabPart.obj_starfg, tabPart.trans_starfg, star, function(index, parts)
      parts.im_star.fillAmount = index == star and score < fullScore and remain or 1
    end)
  end)
end

function FindCommonTip:_OnClickChange()
  self:_ChangeImp(true)
end

function FindCommonTip:_ChangeImp(record)
  local isTeacher = Logic.teachingLogic:CheckIsTeacher()
  local ok, players, msg = Logic.teachingLogic:GetRmdPlayers(not isTeacher, record)
  if ok then
    self:_ShowPlayerInfos(players)
    self:_ShowTitle()
    if record then
      Logic.teachingLogic:SetChangeUpdateTime(time.getSvrTime())
    end
  elseif msg then
    noticeManager:ShowTip(msg)
  else
    local msg
    if isTeacher then
      ok, msg = Logic.teachingLogic:CheckFindStudent()
      if ok then
        Service.teachingService:_FindStudentList()
      end
    else
      ok, msg = Logic.teachingLogic:CheckFindTeacher()
      if ok then
        Service.teachingService:FindTeacherList()
      end
    end
    if not ok then
      noticeManager:ShowTip(msg)
    else
      Logic.teachingLogic:SetRecommendUpdatTime()
    end
  end
end

function FindCommonTip:_OnClockFind()
  local widgets = self:GetWidgets()
  local name = widgets.if_find.text
  if name == "" then
    noticeManager:OpenTipPage(self, 210005)
    return
  end
  local inCD, msg = Logic.teachingLogic:CheckInSearchCD()
  if inCD then
    noticeManager:ShowTip(msg)
    return
  end
  Logic.teachingLogic:SetSearchTime()
  Service.teachingService:SendSearch({Uname = name})
  widgets.if_find.text = ""
end

function FindCommonTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnClockFind, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_change, self._OnClickChange, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  self:RegisterEvent(LuaEvent.TEACHING_GetRmdPlayers, self._OnGetRmd, self)
  self:RegisterEvent(LuaEvent.TEACHING_GetFindPlayers, self._OnGetFind, self)
  self:RegisterEvent(LuaEvent.TEACHING_GetFindErr, self._OnGetFindErr, self)
  self:RegisterEvent(LuaEvent.TEACHING_SendApplyOk, self._OnSendApplyOk, self)
  self:RegisterEvent(LuaEvent.TEACHING_SendApplyErr, self._OnSendApplyErr, self)
end

function FindCommonTip:_OnSendApplyOk(uid)
  Logic.teachingLogic:SetApplyUsr(uid)
  self:_Refresh()
end

function FindCommonTip:_OnSendApplyErr(code)
end

function FindCommonTip:_OnGetFindErr(code)
end

function FindCommonTip:_OnClickApply(go, param)
  local isTeacher = Logic.teachingLogic:CheckIsTeacher()
  if isTeacher then
    Logic.teachingLogic:RecruitStudentWrap(param)
  else
    Logic.teachingLogic:RequesetStudyWrap(param)
  end
end

function FindCommonTip:_CloseSelf()
  UIHelper.ClosePage("TeachingFindPage")
end

function FindCommonTip:DoOnHide()
end

function FindCommonTip:DoOnClose()
  Logic.teachingLogic:ResetApplyUsr()
end

return FindCommonTip
