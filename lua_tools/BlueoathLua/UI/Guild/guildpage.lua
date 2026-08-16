local GuildPage = class("UI.Guild.GuildPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function GuildPage:DoInit()
  self.m_tab_Tags = {
    {
      toggle = self.tab_Widgets.tgHall,
      tween = self.tab_Widgets.tweenHall,
      objselect = self.tab_Widgets.objSelectHall,
      objModule = self.tab_Widgets.objMain
    },
    {
      toggle = self.tab_Widgets.tgMember,
      tween = self.tab_Widgets.tweenMember,
      objselect = self.tab_Widgets.objSelectMember,
      objModule = self.tab_Widgets.objMember
    },
    {
      toggle = self.tab_Widgets.tgApply,
      tween = self.tab_Widgets.tweenApply,
      objselect = self.tab_Widgets.objSelectApply,
      objModule = self.tab_Widgets.objApllication
    },
    {
      toggle = self.tab_Widgets.tgTask,
      tween = self.tab_Widgets.tweenTask,
      objselect = self.tab_Widgets.objSelectTask,
      objModule = self.tab_Widgets.objTask
    }
  }
  self.m_tab_Tags_Type = {
    Hall_1 = 1,
    Member_2 = 2,
    Apply_3 = 3,
    Task_4 = 4
  }
  self.mMemberList = {}
  self.mApplyList = {}
  self.mTaskPartial = require("ui.page.Guild.GuildTaskPartial")
  self.mTaskPartial:DoInit(self)
end

function GuildPage:DoOnOpen()
  self:OpenTopPage("GuildPage", 1, "\229\164\167\232\136\176\233\152\159", self, false)
  local tabParam = {
    isShow = true,
    CurrencyInfo = configManager.GetDataById("config_currency", CurrencyType.CONTRIBUTE)
  }
  eventManager:SendEvent(LuaEvent.TopAddItem, tabParam)
  self.mTaskPartial:DoOnOpen(self)
  self:ShowTabTog()
  self:CheckLevelShow()
  self.tab_Widgets.tggroupRight:SetActiveToggleIndex(self:GetSelectToggleIndex())
end

function GuildPage:RegisterAllEvent()
  self.tab_Widgets.tggroupRight:ClearToggles()
  for _, tabTag in ipairs(self.m_tab_Tags) do
    self.tab_Widgets.tggroupRight:RegisterToggle(tabTag.toggle)
  end
  self.tab_Widgets.tggroupRight:RemoveToggleUnActive(0)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tggroupRight, self, "", self._SwitchTogs)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnManage, self.onBtnManageGuildClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnQuitGuild, self.onBtnQuitGuildClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnRejectAll, self.onBtnRejectAllClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnAcceptAll, self.onBtnAcceptAllClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnGuildShop, self.onBtnGuildShopClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnMemberSort, function()
    UIHelper.OpenPage("GuildMemberSortPage")
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnHelpMemberList, function()
    UIHelper.OpenPage("HelpPage", {content = 710091})
  end)
  self:RegisterEvent(LuaEvent.Update_OurGuildInfo, self.updateMoto, self)
  self:RegisterEvent(LuaEvent.Update_MyGuildInfo, self.updateMoto, self)
  self:RegisterEvent(LuaEvent.Update_GuildPage, self.updateMoto, self)
  self:RegisterEvent(LuaEvent.MOTO_APPLY_LIST, self.updateApply, self)
  self:RegisterEvent(LuaEvent.MOTO_MEMBER_LIST, self.updateMember, self)
  self.mTaskPartial:RegisterAllEvent()
end

function GuildPage:DoOnHide()
end

function GuildPage:DoOnClose()
  self.mTaskPartial = nil
end

function GuildPage:CheckBossActivity()
  local res = false
  if Logic.bossCopyLogic:IsInBossBattleStage() then
    noticeManager:ShowTipById(4300028)
    res = true
  end
  return res
end

function GuildPage:updateMoto()
  if not Data.guildData:inGuild() then
    logDebug("GuildPage:updateMoto not in guild")
    UIHelper.ClosePage("GuildPage")
    UIHelper.OpenPage("GuildMainPage")
    return
  end
  self:CheckLevelShow()
  self.mNeedUpdate = true
  self:ShowPage()
end

function GuildPage:_SwitchTogs(index)
  for tabindex, objTab in ipairs(self.m_tab_Tags) do
    local isSelect = tabindex == index + 1
    objTab.tween:Play(isSelect)
    objTab.objselect:SetActive(isSelect)
    objTab.objModule:SetActive(isSelect)
  end
  self:SetSelectToggleIndex(index)
  self:ShowPage()
end

function GuildPage:GetSelectToggleIndex()
  return Logic.guildLogic.cache_GuildPageToggleIndex
end

function GuildPage:SetSelectToggleIndex(index)
  Logic.guildLogic.cache_GuildPageToggleIndex = index
end

function GuildPage:ShowTabTog()
  local myGuild = Data.guildData:getMyGuildInfo()
  local post = myGuild:getPost()
  local isShow = post == Post.Leader or post == Post.Deputy
  self.tab_Widgets.tgApply.gameObject:SetActive(isShow)
  if not isShow then
    local curSelectIndex = self:GetSelectToggleIndex() + 1
    if curSelectIndex == self.m_tab_Tags_Type.Apply_3 then
      self:SetSelectToggleIndex(0)
    end
  end
end

function GuildPage:ShowPage()
  self:ShowTabTog()
  self:CloseSubPage("ChatPage")
  local curSelectIndex = self:GetSelectToggleIndex() + 1
  if curSelectIndex == self.m_tab_Tags_Type.Hall_1 then
    local temp = ResolutionHelper.unsafeRadio
    ResolutionHelper.unsafeRadio = 0
    self:OpenSubPage("ChatPage")
    ResolutionHelper.unsafeRadio = temp
    self:ShowHallPartial()
  elseif curSelectIndex == self.m_tab_Tags_Type.Member_2 then
    self:SendGetMemberList()
    self:ShowMemberPartial()
  elseif curSelectIndex == self.m_tab_Tags_Type.Apply_3 then
    Service.guildService:SendGetApplyList()
    self:ShowApplyPartial()
  elseif curSelectIndex == self.m_tab_Tags_Type.Task_4 then
    self.mTaskPartial:ShowPartial()
  else
    logError("Undefined index")
  end
  self.tab_Widgets.btnGuildShop.gameObject:SetActive(curSelectIndex ~= self.m_tab_Tags_Type.Apply_3 and curSelectIndex ~= self.m_tab_Tags_Type.Member_2)
end

local CD_SendGetMem = 60

function GuildPage:SendGetMemberList()
  local curTime = time.getSvrTime()
  local bNeedUpdate = self.mNeedUpdate or false
  if bNeedUpdate then
    self.mLastSendGetMemberListTime = curTime
    Service.guildService:SendGetMemberList()
    self.mNeedUpdate = false
    return
  end
  local lastTime = self.mLastSendGetMemberListTime or 0
  local deltaT = curTime - lastTime
  if lastTime == 0 or deltaT > CD_SendGetMem then
    self.mLastSendGetMemberListTime = curTime
    Service.guildService:SendGetMemberList()
  end
end

function GuildPage:updateMember(data)
  local msg = data or {}
  self.mMemberList = msg.sMember or {}
  self:ShowMemberPartial()
end

function GuildPage:updateApply(data)
  local msg = data or {}
  self.mApplyList = msg.ApplyList or {}
  self:ShowApplyPartial()
end

function GuildPage:ShowHallPartial()
  local ourGuild = Data.guildData:getOurGuildInfo()
  local levelRec = configManager.GetDataById("config_guildlevel", ourGuild:getLevel())
  UIHelper.SetText(self.tab_Widgets.txtGuildName, ourGuild:getName() or "")
  UIHelper.SetText(self.tab_Widgets.txtLeaderName, ourGuild:getLeaderName() or "")
  local enounce = ourGuild:getEnounce()
  if enounce == nil or enounce == "" then
    local paramRec = Logic.guildLogic:GetGuildParamConfig()
    enounce = UIHelper.GetString(paramRec.acqnote)
  end
  UIHelper.SetText(self.tab_Widgets.txtGuildNote, enounce)
  UIHelper.SetText(self.tab_Widgets.txtMemberNum, ourGuild:getMemberNum() .. "/" .. levelRec.playernum)
  UIHelper.SetText(self.tab_Widgets.txtLevel, "lv." .. ourGuild:getLevel())
  local curexp = ourGuild:getExp()
  local levelupexp = levelRec.guildlevelupexp
  self.tab_Widgets.sliderLevel.value = curexp / levelupexp
  UIHelper.SetText(self.tab_Widgets.txtSliderLevel, curexp .. "/" .. levelupexp)
  local todayexp = ourGuild:getTodayExp()
  local todayexpmax = levelRec.max_exp
  self.tab_Widgets.sliderTodayExp.value = todayexp / todayexpmax
  UIHelper.SetText(self.tab_Widgets.textTodayExpPer, todayexp .. "/" .. todayexpmax)
  local myGuild = Data.guildData:getMyGuildInfo()
  local post = myGuild:getPost()
  local isShow = post == Post.Leader or post == Post.Deputy
  self.tab_Widgets.btnManage.gameObject:SetActive(isShow)
  self:showTips()
end

function GuildPage:showTips()
  local ourGuild = Data.guildData:getOurGuildInfo() or {}
  local tipList = ourGuild:getTipList()
  logDebug("HallMoto:showTip tip num:", #tipList)
  if #tipList <= 0 then
    return
  end
  self.mTipList = self:addDayTime(tipList)
  logDebug("HallMoto:showTip self.mTipList:", #self.mTipList, self.mTipList)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentMessage, self.tab_Widgets.itemMessage, #self.mTipList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateMessagePart(index, part)
    end
  end)
end

local TimeInfoType = {DayTime = 1}

function GuildPage:addDayTime(tipList)
  local res = {}
  local dayTime = ""
  for idx = 1, #tipList do
    local tip = tipList[#tipList - idx + 1]
    logDebug("HallMoto:addDayTime idx", idx)
    local newDayTime = os.date("%Y.%m.%d", tip.Time)
    if newDayTime ~= dayTime then
      local dayTimeInfo = {
        typ = TimeInfoType.DayTime,
        text = newDayTime .. ":"
      }
      logDebug("HallMoto:addDayTime dayTimeInfo", dayTimeInfo)
      table.insert(res, dayTimeInfo)
      dayTime = newDayTime
    end
    table.insert(res, tip)
  end
  return res
end

function GuildPage:updateMessagePart(index, part)
  local tip = self.mTipList[index]
  if tip.typ ~= nil and tip.typ == TimeInfoType.DayTime then
    part.txtTime.gameObject:SetActive(false)
    part.txtMessage.gameObject:SetActive(false)
    part.txtDayTime.gameObject:SetActive(true)
    UIHelper.SetText(part.txtDayTime, tip.text or "")
    return
  end
  part.txtTime.gameObject:SetActive(true)
  part.txtMessage.gameObject:SetActive(true)
  part.txtDayTime.gameObject:SetActive(false)
  local data = {}
  for i = 1, #tip.Param do
    table.insert(data, tip.Param[i].Data)
  end
  UIHelper.SetText(part.txtTime, os.date("%H:%M", tip.Time))
  UIHelper.SetLocText(part.txtMessage, tip.DictId, table.unpack(data))
end

function GuildPage:ShowMemberPartial()
  self:sortMemberList()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentMember, self.tab_Widgets.itemMember, #self.mMemberList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateMemberPart(index, part)
    end
  end)
  local myGuild = Data.guildData:getMyGuildInfo()
  local post = myGuild:getPost()
  local isLeader = post == Post.Leader
  self.tab_Widgets.btnQuitGuild.gameObject:SetActive(not isLeader)
end

function GuildPage:updateMemberPart(index, part)
  local member = self.mMemberList[index]
  if member == nil then
    logError("member is nil, index ", index)
    return
  end
  local icon, quality = Logic.meritLogic:GetUserHead(member.UserInfo)
  UIHelper.SetImage(part.imgQuality, quality)
  UIHelper.SetImage(part.imgHead, icon)
  UGUIEventListener.AddButtonOnClick(part.btnHead, self.btnHeadOnClick, self, {
    Uid = member.UserInfo.Uid
  })
  local cfg = configManager.GetDataById("config_guildpost", GuildPostCfgID[member.Post])
  UIHelper.SetText(part.txtPost, cfg.post)
  UIHelper.SetText(part.txtName, member.UserInfo.Uname)
  UIHelper.SetText(part.txtLevel, "Lv." .. (member.UserInfo.Level or 0))
  UIHelper.SetText(part.txtTotalNum, member.Contribute or 0)
  UIHelper.SetText(part.txtDayNum, member.TodayContribute or 0)
  UIHelper.SetText(part.txtStatus, self:getStatusDesc(member.LogoffTime))
  local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(member.UserInfo)
  part.imgKuang.gameObject:SetActive(true)
  UIHelper.SetImage(part.imgKuang, headFrameInfo.icon)
  local isMe = Data.userData:GetUserUid() == member.UserInfo.Uid
  part.objImgSelf:SetActive(isMe)
  local myGuildData = Data.guildData:getMyGuildInfo()
  local myPost = myGuildData:getPost()
  local otPost = member.Post
  local rightlist = Data.guildData:GetPostRightByPostRelation(myPost, otPost)
  if isMe or #rightlist == 0 then
    part.btnManage.gameObject:SetActive(false)
  else
    part.btnManage.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btnManage, self.btnManageOnClick, self, {Member = member})
  end
  if otPost == Post.Leader then
    local ourGuildData = Data.guildData:getOurGuildInfo()
    local impeachStartTime = ourGuildData:getImpeachStartTime()
    if 0 < impeachStartTime then
      local myMem = self:getMyMemInfo()
      if 0 < myMem.ImpeachTime then
        part.btnFollowImpeach.gameObject:SetActive(false)
        part.objImgAlreadyImpeach:SetActive(true)
      else
        part.btnFollowImpeach.gameObject:SetActive(true)
        part.objImgAlreadyImpeach:SetActive(false)
      end
      part.btnImpeach.gameObject:SetActive(false)
    else
      local cfg = Logic.guildLogic:GetGuildParamConfig()
      if member.LogoffTime >= cfg.headoutlinetime then
        part.btnImpeach.gameObject:SetActive(true)
      else
        part.btnImpeach.gameObject:SetActive(false)
      end
      part.btnFollowImpeach.gameObject:SetActive(false)
      part.objImgAlreadyImpeach:SetActive(false)
    end
    local impeachFunc = function()
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            Service.guildService:SendImpeach()
          end
        end
      }
      noticeManager:ShowMsgBox(710088, tabParams)
    end
    UGUIEventListener.AddButtonOnClick(part.btnImpeach, function()
      impeachFunc()
    end)
    UGUIEventListener.AddButtonOnClick(part.btnFollowImpeach, function()
      impeachFunc()
    end)
  else
    part.btnImpeach.gameObject:SetActive(false)
    part.btnFollowImpeach.gameObject:SetActive(false)
    part.objImgAlreadyImpeach:SetActive(false)
  end
end

function GuildPage:getMyMemInfo()
  local myUid = Data.userData:GetUserUid()
  for _, member in ipairs(self.mMemberList) do
    if member.UserInfo.Uid == myUid then
      return member
    end
  end
  return nil
end

function GuildPage:getStatusDesc(logOffTime)
  local cfg = configManager.GetDataById("config_parameter", 200)
  if logOffTime <= 0 then
    local retstr = "\229\156\168\231\186\191"
    return UIHelper.SetColor(retstr, cfg.arrValue[1])
  elseif logOffTime < 3600 then
    local retstr = "\231\166\187\231\186\191" .. math.floor(logOffTime / 60) + 1 .. "\229\136\134\233\146\159"
    return UIHelper.SetColor(retstr, cfg.arrValue[2])
  elseif logOffTime < 86400 then
    local retstr = "\231\166\187\231\186\191" .. math.floor(logOffTime / 3600) + 1 .. "\229\176\143\230\151\182"
    return UIHelper.SetColor(retstr, cfg.arrValue[2])
  elseif logOffTime < 604800 then
    local retstr = "\231\166\187\231\186\191" .. math.floor(logOffTime / 86400) .. "\229\164\169"
    return UIHelper.SetColor(retstr, cfg.arrValue[2])
  else
    local retstr = "\231\166\187\231\186\191\232\182\133\232\191\135\228\184\128\229\145\168"
    return UIHelper.SetColor(retstr, cfg.arrValue[2])
  end
end

function GuildPage:getApplyStatusDesc(applyTime)
  local nowtime = time.getSvrTime()
  local delta = nowtime - applyTime
  if delta < 0 then
    delta = 0
  end
  if delta <= 60 then
    return delta .. "\231\167\146\229\137\141"
  elseif delta < 3600 then
    return math.floor(delta / 60) + 1 .. "\229\136\134\233\146\159\229\137\141"
  elseif delta < 86400 then
    return math.floor(delta / 3600) + 1 .. "\229\176\143\230\151\182\229\137\141"
  else
    return math.floor(delta / 86400) + 1 .. "\229\164\169\229\137\141"
  end
end

function GuildPage:btnHeadOnClick(go, param)
  local uid = Data.userData:GetUserUid()
  if uid == param.Uid then
    return
  end
  local paramTab = {
    Position = go.transform.position,
    Uid = param.Uid
  }
  UIHelper.OpenPage("UserInfoTip", paramTab)
end

function GuildPage:btnManageOnClick(go, param)
  local uid = param.Uid
  local paramTab = {
    Uid = uid,
    Position = go.transform.position,
    Member = param.Member
  }
  UIHelper.OpenPage("ManagerPage", paramTab)
end

function GuildPage:ShowApplyPartial()
  self.tab_Widgets.objApplyEmpty:SetActive(#self.mApplyList == 0)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentApply, self.tab_Widgets.itemApply, #self.mApplyList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateApplyPart(index, part)
    end
  end)
end

function GuildPage:updateApplyPart(index, part)
  local apply = self.mApplyList[index]
  if apply == nil then
    logError("apply is nil, index ", index)
    return
  end
  local icon, quality = Logic.meritLogic:GetUserHead(apply.UserInfo)
  UIHelper.SetImage(part.imgQuality, quality)
  UIHelper.SetImage(part.imgHead, icon)
  UGUIEventListener.AddButtonOnClick(part.btnHead, self.btnHeadOnClick, self, {
    Uid = apply.UserInfo.Uid
  })
  UIHelper.SetText(part.txtName, apply.UserInfo.Uname)
  UIHelper.SetText(part.txtLevel, "Lv." .. (apply.UserInfo.Level or 0))
  UIHelper.SetText(part.txtTime, self:getApplyStatusDesc(apply.Time))
  local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(apply.UserInfo)
  part.imgKuang.gameObject:SetActive(true)
  UIHelper.SetImage(part.imgKuang, headFrameInfo.icon)
  UGUIEventListener.AddButtonOnClick(part.btnAgree, self.btnAgreeOnClick, self, {
    Uid = apply.UserInfo.Uid
  })
  UGUIEventListener.AddButtonOnClick(part.btnReject, self.btnRejectOnClick, self, {
    Uid = apply.UserInfo.Uid
  })
end

function GuildPage:btnAgreeOnClick(go, param)
  Service.guildService:SendVerify({
    uid = param.Uid,
    mode = VerifyType.ApplyAccept
  })
end

function GuildPage:btnRejectOnClick(go, param)
  Service.guildService:SendVerify({
    uid = param.Uid,
    mode = VerifyType.ApplyReject
  })
end

function GuildPage:onBtnManageGuildClick()
  UIHelper.OpenPage("ManageGuildPage")
end

function GuildPage:onBtnQuitGuildClick()
  if self:CheckBossActivity() then
    return
  end
  local myGuild = Data.guildData:getMyGuildInfo()
  local post = myGuild:getPost()
  local isLeader = post == Post.Leader
  if isLeader then
    noticeManager:ShowTipById(710015)
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.guildService:SendQuit()
      else
      end
    end
  }
  noticeManager:ShowMsgBox(710012, tabParams)
end

function GuildPage:onBtnRejectAllClick()
  Service.guildService:SendRejectAll()
end

function GuildPage:onBtnAcceptAllClick()
  local ourGuild = Data.guildData:getOurGuildInfo()
  local levelRec = configManager.GetDataById("config_guildlevel", ourGuild:getLevel())
  if ourGuild:getMemberNum() >= levelRec.playernum then
    noticeManager:ShowTipById(710060)
    return
  end
  Service.guildService:SendAcceptAll()
end

function GuildPage:sortMemberList()
  if #self.mMemberList <= 0 then
    return
  end
  local myUid = Data.userData:GetUserUid()
  local SortType = {Up = 0, Down = 1}
  local SortRet = {
    Equal = 1,
    Bigger = 2,
    Less = 3
  }
  local sortByPost = function(m1, m2)
    if m1.Post ~= m2.Post then
      return m1.Post < m2.Post and SortRet.Less or SortRet.Bigger
    end
    return SortRet.Equal
  end
  local sortByTotalCon = function(m1, m2)
    if m1.Contribute ~= m2.Contribute then
      return m1.Contribute > m2.Contribute and SortRet.Less or SortRet.Bigger
    end
    return SortRet.Equal
  end
  local sortByTodayCon = function(m1, m2)
    if m1.TodayContribute ~= m2.TodayContribute then
      return m1.TodayContribute > m2.TodayContribute and SortRet.Less or SortRet.Bigger
    end
    return SortRet.Equal
  end
  local sortByLevel = function(m1, m2)
    if m1.UserInfo.Level ~= m2.UserInfo.Level then
      return m1.UserInfo.Level > m2.UserInfo.Level and SortRet.Less or SortRet.Bigger
    end
    return SortRet.Equal
  end
  local sortByStatus = function(m1, m2)
    if m1.LogoffTime ~= m2.LogoffTime then
      return m1.LogoffTime < m2.LogoffTime and SortRet.Less or SortRet.Bigger
    end
    return SortRet.Equal
  end
  local SortFuncType = {
    Post = 0,
    TotalCon = 1,
    TodayCon = 2,
    Level = 3,
    Status = 4
  }
  local SortFunc = {sortByPost, sortByStatus}
  local cacheMemberSort_Sort = Logic.guildLogic.cache_GuildMemberSort_Index or SortFuncType.Post
  if cacheMemberSort_Sort == SortFuncType.Post then
    SortFunc = {sortByPost, sortByStatus}
  elseif cacheMemberSort_Sort == SortFuncType.TotalCon then
    SortFunc = {
      sortByTotalCon,
      sortByPost,
      sortByStatus
    }
  elseif cacheMemberSort_Sort == SortFuncType.TodayCon then
    SortFunc = {
      sortByTodayCon,
      sortByPost,
      sortByStatus
    }
  elseif cacheMemberSort_Sort == SortFuncType.Level then
    SortFunc = {
      sortByLevel,
      sortByPost,
      sortByStatus
    }
  elseif cacheMemberSort_Sort == SortFuncType.Status then
    SortFunc = {sortByStatus, sortByPost}
  else
    logError("Undefined SortFuncType", cacheMemberSort_Sort)
  end
  local cacheMemberSort_Sort = Logic.guildLogic.cache_GuildMemberSort_Sort or SortType.Up
  local SortReturnTrue = cacheMemberSort_Sort == SortType.Up and true or false
  table.sort(self.mMemberList, function(m1, m2)
    for _, sortFunc in ipairs(SortFunc) do
      local ret = sortFunc(m1, m2)
      if ret == SortRet.Less then
        return SortReturnTrue
      elseif ret == SortRet.Bigger then
        return not SortReturnTrue
      end
    end
    if m1.UserInfo.Uid ~= m2.UserInfo.Uid then
      if m1.UserInfo.Uid == myUid then
        return true
      end
      if m2.UserInfo.Uid == myUid then
        return false
      end
      return m1.UserInfo.Uid > m2.UserInfo.Uid
    end
    return false
  end)
end

function GuildPage:onBtnGuildShopClick()
  UIHelper.OpenPage("ShopPage", {shopId = 27})
end

function GuildPage:CheckLevelShow()
  local myGuildData = Data.guildData:getMyGuildInfo()
  local ourGuildData = Data.guildData:getOurGuildInfo()
  local levelPre = myGuildData:getGuildLevelOfShow()
  local levelNow = ourGuildData:getLevel()
  if levelPre >= levelNow then
    return
  end
  local paramTab = {LevelPre = levelPre, LevelNow = levelNow}
  UIHelper.OpenPage("GuildLevelUpPage", paramTab)
  Service.guildService:SendSetGuildLevelOfShow({Level = levelNow})
end

return GuildPage
