local ManagerPage = class("UI.Guild.ManagerPage", LuaUIPage)

function ManagerPage:DoInit()
end

function ManagerPage:DoOnOpen()
  local tabParam = self:GetParam()
  self.mMember = tabParam.Member
  local member = self.mMember
  local isMe = Data.userData:GetUserUid() == member.UserInfo.Uid
  if isMe then
    logError("can not manage myself")
    return
  end
  local myGuildData = Data.guildData:getMyGuildInfo()
  local myPost = myGuildData:getPost()
  local otPost = member.Post
  local rightlist = Data.guildData:GetPostRightByPostRelation(myPost, otPost)
  local rightmap = {}
  for _, rt in ipairs(rightlist) do
    rightmap[rt] = true
  end
  local isShow_btnTransLeader = false
  local isShow_btnRisepost = false
  local isShow_btnDemotepost = false
  local isShow_btnKickout = false
  if rightmap[Post_Right.RIGHT_TRANSFER] then
    isShow_btnTransLeader = true
  end
  if rightmap[Post_Right.RIGHT_APPOINT] then
    if otPost == Post.Deputy then
      isShow_btnDemotepost = true
    else
      isShow_btnRisepost = true
    end
  end
  if rightmap[Post_Right.RIGHT_REMOVE_MEMBER] then
    isShow_btnKickout = true
  end
  self.tab_Widgets.btnTransLeader.gameObject:SetActive(isShow_btnTransLeader)
  self.tab_Widgets.btnRisepost.gameObject:SetActive(isShow_btnRisepost)
  self.tab_Widgets.btnDemotepost.gameObject:SetActive(isShow_btnDemotepost)
  self.tab_Widgets.btnKickout.gameObject:SetActive(isShow_btnKickout)
  UIHelper.SetText(self.tab_Widgets.txtName, member.UserInfo.Uname)
end

function ManagerPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.btnCloseOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnTransLeader, self.btnTransLeaderOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnRisepost, self.btnRisepostOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnDemotepost, self.btnDemotepostOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnKickout, self.btnKickoutOnClick, self)
end

function ManagerPage:DoOnHide()
end

function ManagerPage:DoOnClose()
end

function ManagerPage:btnCloseOnClick()
  self:closeMe()
end

function ManagerPage:CheckBossActivity()
  local res = false
  if Logic.bossCopyLogic:IsInBossBattleStage() then
    noticeManager:ShowTipById(4300029)
    res = true
  end
  return res
end

function ManagerPage:btnTransLeaderOnClick()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.guildService:SendTransfer({
          Uid = self.mMember.UserInfo.Uid
        })
      end
    end
  }
  local content = UIHelper.GetLocString(710067, self.mMember.UserInfo.Uname)
  noticeManager:ShowMsgBox(content, tabParams)
  self:closeMe()
end

function ManagerPage:btnRisepostOnClick()
  local ourGuildData = Data.guildData:getOurGuildInfo()
  local deputynum = ourGuildData:getDeputyNum()
  if 2 <= deputynum then
    noticeManager:ShowTipById(710056, 2)
    return
  end
  Service.guildService:SendAppoint({
    Uid = self.mMember.UserInfo.Uid,
    Post = Post.Deputy,
    Uname = self.mMember.UserInfo.Uname
  })
  self:closeMe()
end

function ManagerPage:btnDemotepostOnClick()
  Service.guildService:SendAppoint({
    Uid = self.mMember.UserInfo.Uid,
    Post = Post.Member,
    Uname = self.mMember.UserInfo.Uname
  })
  self:closeMe()
end

function ManagerPage:btnKickoutOnClick()
  if self:CheckBossActivity() then
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.guildService:SendRemove({
          Uid = self.mMember.UserInfo.Uid
        })
        self:closeMe()
      end
    end
  }
  noticeManager:ShowMsgBox(UIHelper.GetLocString(710054, self.mMember.UserInfo.Uname), tabParams)
end

function ManagerPage:closeMe()
  UIHelper.ClosePage("ManagerPage")
end

return ManagerPage
