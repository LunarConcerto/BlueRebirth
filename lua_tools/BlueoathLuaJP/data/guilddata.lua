Post = {
  Leader = 1,
  Deputy = 2,
  Member = 100
}
Skill = {
  Open = 1,
  Upgrade = 2,
  Close = 3,
  Max = 4
}
QuitReason = {
  Quit = 1,
  Kick = 2,
  Dismiss = 3,
  Dismissed = 4
}
GuildPostCfgID = {
  [Post.Leader] = 1,
  [Post.Deputy] = 2,
  [Post.Member] = 3
}
Post_Right = {
  RIGHT_TRANSFER = 1,
  RIGHT_REVIEW_APPLY = 2,
  RIGHT_REMOVE_MEMBER = 3,
  RIGHT_UPGRADE = 4,
  RIGHT_DISMISS = 5,
  RIGHT_MODIFY = 6,
  RIGHT_APPOINT = 7
}
Rule_Post_Right = {
  [Post.Leader] = {
    [Post_Right.RIGHT_TRANSFER] = true,
    [Post_Right.RIGHT_REVIEW_APPLY] = true,
    [Post_Right.RIGHT_REMOVE_MEMBER] = true,
    [Post_Right.RIGHT_UPGRADE] = true,
    [Post_Right.RIGHT_DISMISS] = true,
    [Post_Right.RIGHT_MODIFY] = true,
    [Post_Right.RIGHT_APPOINT] = true
  },
  [Post.Deputy] = {
    [Post_Right.RIGHT_REVIEW_APPLY] = true,
    [Post_Right.RIGHT_REMOVE_MEMBER] = true,
    [Post_Right.RIGHT_UPGRADE] = true,
    [Post_Right.RIGHT_MODIFY] = true
  }
}
Rule_PostRelation = {
  [Post.Leader] = {
    [Post.Deputy] = {
      Post_Right.RIGHT_TRANSFER,
      Post_Right.RIGHT_REMOVE_MEMBER,
      Post_Right.RIGHT_APPOINT
    },
    [Post.Member] = {
      Post_Right.RIGHT_TRANSFER,
      Post_Right.RIGHT_REMOVE_MEMBER,
      Post_Right.RIGHT_APPOINT
    }
  },
  [Post.Deputy] = {
    [Post.Member] = {
      Post_Right.RIGHT_REMOVE_MEMBER
    }
  }
}
GUILD_PARAM_DEFAULT = 1
local gShowingExitTip = false
local BaseGuildInfo = class("BaseGuildInfo")

function BaseGuildInfo:initialize(data)
  self:updateData(data)
end

function BaseGuildInfo:updateData(data)
  if data.GuildId ~= nil then
    self.mGuildId = data.GuildId
  end
  if data.Name ~= nil then
    self.mName = data.Name
  end
  if data.Emblem ~= nil then
    self.mEmblem = data.Emblem
  end
  if data.Frame ~= nil then
    self.mFrame = data.Frame
  end
  if data.Enounce ~= nil then
    self.mEnounce = data.Enounce
  end
  if data.Level ~= nil then
    self.mLevel = data.Level
  end
  if data.MemberNum ~= nil then
    self.mMemberNum = data.MemberNum
  end
  if data.Power ~= nil then
    self.mPower = data.Power
  end
  if data.LeaderId ~= nil then
    self.mLeaderId = data.LeaderId
  end
  if data.LeaderName ~= nil then
    self.mLeaderName = data.LeaderName
  end
end

function BaseGuildInfo:getPower()
  return self.mPower
end

function BaseGuildInfo:getGuildId()
  return self.mGuildId
end

function BaseGuildInfo:getName()
  return self.mName
end

function BaseGuildInfo:getLeaderId()
  return self.mLeaderId
end

function BaseGuildInfo:getLeaderName()
  return self.mLeaderName
end

function BaseGuildInfo:getEmblem()
  return self.mEmblem
end

function BaseGuildInfo:getFrame()
  return self.mFrame
end

function BaseGuildInfo:getEnounce()
  return self.mEnounce
end

function BaseGuildInfo:getLevel()
  return self.mLevel
end

function BaseGuildInfo:getMemberNum()
  return self.mMemberNum
end

local GuildApplyInfo = class("GuildApplyInfo")

function GuildApplyInfo:initialize(data)
  self:updateData(data)
end

function GuildApplyInfo:updateData(data)
  if data.Time ~= nil then
    self.mTime = data.Time
  end
  local userInfo = data.UserInfo
  if userInfo.Uid ~= nil then
    self.mUid = userInfo.Uid
  end
  if userInfo.Uname ~= nil then
    self.mName = userInfo.Uname
  end
  if userInfo.Head ~= nil then
    self.mHead = userInfo.Head
  end
  if userInfo.Level ~= nil then
    self.mLevel = userInfo.Level
  end
  if userInfo.VipLevel ~= nil then
    self.mVipLevel = userInfo.VipLevel
  end
  if userInfo.Power ~= nil then
    self.mPower = userInfo.Power
  end
end

function GuildApplyInfo:getPower()
  return self.mPower or 0
end

function GuildApplyInfo:getTime()
  return self.mTime or 0
end

function GuildApplyInfo:getUid()
  return self.mUid or 0
end

function GuildApplyInfo:getName()
  return self.mName or ""
end

function GuildApplyInfo:getHead()
  return self.mHead or 0
end

function GuildApplyInfo:getLevel()
  return self.mLevel or 0
end

function GuildApplyInfo:getVipLevel()
  return self.mVipLevel or 0
end

local MyGuildData = class("MyGuildData")

function MyGuildData:initialize(data)
  self.mApplyList = {}
  self.mFirstReward = {}
  self:updateData(data)
end

function MyGuildData:getFirstReward()
  return self.mFirstReward
end

function MyGuildData:getDailyRewardTime()
  return self.mDailyRewardTime or 0
end

function MyGuildData:getLastAtkTime()
  return self.mLastAtkTime or 0
end

function MyGuildData:updateData(data)
  if data.GuildId ~= nil then
    self.mGuildId = data.GuildId
  end
  if data.JoinGuildTime ~= nil then
    self.mJoinGuildTime = data.JoinGuildTime
  end
  if data.MessageCount ~= nil then
    self.mMessageCount = data.MessageCount
  end
  if data.QuitTime ~= nil then
    self.mQuitTime = data.QuitTime
  end
  if data.LastAtkTime ~= nil then
    self.mLastAtkTime = data.LastAtkTime
  end
  if data.Post ~= nil then
    self.mPost = data.Post
  end
  if data.GuildLevelOfShow ~= nil then
    self.mGuildLevelOfShow = data.GuildLevelOfShow
  end
  if data.SacrificeTime ~= nil then
    self.mSacrificeTime = data.SacrificeTime
  end
  if data.SacrificeBox ~= nil then
    self.mSacrificeBox = data.SacrificeBox
  end
  if data.SacrificeReward ~= nil then
    self.mSacrificeReward = data.SacrificeReward
  end
  if data.SacrificeMode ~= nil then
    self.mSacrificeMode = data.SacrificeMode
  end
  if data.ShowDaily ~= nil then
    self.mDailyRewardStatus = data.ShowDaily
  end
  if data.QuitReason ~= nil then
    self.mQuitReason = data.QuitReason
    self:doNoticeProcess()
  end
  if data.FirstReward ~= nil and #data.FirstReward > 0 then
    local temp = {}
    for _, v in ipairs(data.FirstReward) do
      table.insert(temp, v)
    end
    self.mFirstReward = temp
  end
  if data.DailyRewardTime ~= nil then
    self.mDailyRewardTime = data.DailyRewardTime
  end
  if data.SkillList ~= nil and 0 < #data.SkillList then
    self.mSkill = {}
    for i = 1, #data.SkillList do
      local skillId = data.SkillList[i].SkillId
      local skillLv = data.SkillList[i].Level
      if skillId ~= nil then
        table.insert(self.mSkill, {id = skillId, lv = skillLv})
      end
    end
  end
  if data.Apply ~= nil and 0 < #data.Apply then
    self.mApplyList = data.Apply
  end
  if data.GuildId ~= nil then
    self:doWhenGuildIdChange(data.GuildId)
  end
  if data.GuildId == nil or data.GuildId <= 0 then
  end
  if data.Event ~= nil and data.Event.Type and data.Event.Type ~= 1 then
    Data.guildData:GetGuildBoxData():ResetGuildBoxData()
  end
end

function MyGuildData:doNoticeProcess()
  if self.mQuitReason == QuitReason.Kick then
    noticeManager:ShowTip(UIHelper.GetString(920000040))
  elseif self.mQuitReason == QuitReason.Dismiss or self.mQuitReason == QuitReason.Dismissed then
    noticeManager:ShowTip(UIHelper.GetString(920000041))
  elseif self.mQuitReason == QuitReason.Quit then
  else
    noticeManager:ShowTip(UIHelper.GetString(920000042))
  end
end

INGUILDMOTO_CHECK_LIST = {"GuildPage"}
CLEARSTACK_CHECK_LIST = {}

function MyGuildData:GetJoinDay()
  local joinTime = self.mJoinGuildTime
  local now = time.getSvrTime()
  local nowtime = os.date("*t", now)
  local jontime = os.date("*t", joinTime)
  local nowt = os.time({
    year = nowtime.year,
    month = nowtime.month,
    day = nowtime.day,
    hour = 0,
    min = 0,
    sec = 0
  })
  local jont = os.time({
    year = jontime.year,
    month = jontime.month,
    day = jontime.day,
    hour = 0,
    min = 0,
    sec = 0
  })
  local duration = nowt - jont
  local dtDay = duration / 86400
  return dtDay
end

function MyGuildData:checkCurMotoStackInGuild()
  for _, pagename in ipairs(INGUILDMOTO_CHECK_LIST) do
    if UIHelper.IsExistPage(pagename) then
      return true
    end
  end
  return false
end

function MyGuildData:checkClearStack()
  for _, pagename in ipairs(CLEARSTACK_CHECK_LIST) do
    if UIHelper.IsExistPage(pagename) then
      return true
    end
  end
  return false
end

function MyGuildData:doNoGuildProcess()
  if not self:checkCurMotoStackInGuild() then
    return
  end
  local isClearStack = self:checkClearStack()
  logDebug("gShowingExitTip", gShowingExitTip)
  if gShowingExitTip == true then
    return
  end
  gShowingExitTip = true
  if self.mQuitReason == QuitReason.Kick then
    local tabParams = {
      msgType = NoticeType.OneButton,
      callback = function(bool)
        gShowingExitTip = false
        UIHelper.OpenPage("HomePage")
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(920000040), tabParams)
  elseif self.mQuitReason == QuitReason.Dismiss or self.mQuitReason == QuitReason.Dismissed then
    local tabParams = {
      msgType = NoticeType.OneButton,
      callback = function(bool)
        gShowingExitTip = false
        UIHelper.OpenPage("HomePage")
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(920000041), tabParams)
  elseif self.mQuitReason == QuitReason.Quit then
  else
    local tabParams = {
      msgType = NoticeType.OneButton,
      callback = function(bool)
        gShowingExitTip = false
        UIHelper.OpenPage("HomePage")
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(920000042), tabParams)
  end
end

function MyGuildData:doWhenGuildIdChange(changeGuildId)
  local isInGuild = 0 < changeGuildId
  Logic.chatLogic:ModifyChatChannelStatus(ChatChannel.Guild, isInGuild)
end

function MyGuildData:getDailyRewardStatus()
  return self.mDailyRewardStatus
end

function MyGuildData:getApplyTime(guildId)
  local paramRec = configManager.GetDataById("config_guildparam", GUILD_PARAM_DEFAULT)
  local curTime = time.getSvrTime()
  for i, apply in ipairs(self.mApplyList) do
    if guildId == apply.GuildId then
      if curTime > apply.Time + paramRec.applytime then
        return 0
      else
        return apply.Time
      end
    end
  end
  return 0
end

function MyGuildData:isBoxTaken(id)
  if bit:_and(self.mSacrificeReward, 2 ^ id) > 0 then
    return true
  end
  return false
end

function MyGuildData:getPost()
  return self.mPost
end

function MyGuildData:getGuildLevelOfShow()
  return self.mGuildLevelOfShow or 100
end

function MyGuildData:getSkillLevel(skillId)
  for i = 1, #(self.mSkill or {}) do
    if skillId == self.mSkill[i].id then
      return self.mSkill[i].lv
    end
  end
  return 0
end

local OurGuildData = class("OurGuildData")

function OurGuildData:initialize(data)
  self.mTipList = {}
  self.mMemberList = {}
  self:updateData(data)
end

function OurGuildData:updateData(data)
  if data.Name ~= nil then
    self.mName = data.Name
  end
  if data.Emblem ~= nil then
    self.mEmblem = data.Emblem
  end
  if data.Frame ~= nil then
    self.mFrame = data.Frame
  end
  if data.Enounce ~= nil then
    self.mEnounce = data.Enounce
  end
  if data.Notice ~= nil then
    self.mNotice = data.Notice
  end
  if data.Limit ~= nil then
    self.mLimit = {}
    self.mLimit.Level = data.Limit.Level
  end
  if data.MemberNum ~= nil then
    self.mMemberNum = data.MemberNum
  end
  if data.LeaderName ~= nil then
    self.mLeaderName = data.LeaderName
  end
  if data.LeaderId ~= nil then
    self.mLeaderId = data.LeaderId
  end
  if data.Deputy ~= nil and #data.Deputy > 0 then
    self.mDeputy = {}
    self.mDeputyCount = 0
    for i = 1, #data.Deputy do
      local uid = tonumber(data.Deputy[i])
      if 0 < uid then
        self.mDeputy[uid] = true
        self.mDeputyCount = self.mDeputyCount + 1
      end
    end
  end
  if data.Level ~= nil then
    self.mLevel = data.Level
  end
  if data.Exp ~= nil then
    self.mExp = data.Exp
  end
  if data.TodayExp ~= nil then
    self.mTodayExp = data.TodayExp
  end
  if data.Post ~= nil then
    self.mPost = data.Post
  end
  if data.TipList ~= nil then
    for i = 1, #data.TipList do
      logDebug("updateData", i, data.TipList[i].DictId)
      if data.TipList[i] == nil or 0 >= data.TipList[i].DictId then
        self.mTipList = {}
        logDebug("nil tip")
      else
        logDebug("#data.TipList[i].Param", #data.TipList[i].Param)
        table.insert(self.mTipList, data.TipList[i])
      end
    end
  end
  if data.Post ~= nil then
    self.mPost = data.Post
  end
  if data.Process ~= nil then
    self.mProcess = data.Process
  end
  if data.SacrificeInfo ~= nil then
    self.mSacrificeInfo = data.SacrificeInfo
  end
  if data.CreateTime ~= nil then
    self.mCreateTime = data.CreateTime
  end
  if data.SkillList ~= nil and 0 < #data.SkillList then
    self.mSkill = {}
    for i = 1, #data.SkillList do
      local skillId = data.SkillList[i].SkillId
      local skillLv = data.SkillList[i].Level
      if skillId ~= nil then
        table.insert(self.mSkill, {id = skillId, lv = skillLv})
      end
    end
  end
  if data.ApplyNum ~= nil then
    self.mApplyNum = data.ApplyNum
    Data.guildData:setApplyFlagOfShow(true)
    eventManager:SendEvent(LuaEvent.Flag_Update_HaveApply)
  end
  if data.ChatRoom ~= nil then
    self.mChatRoom = data.ChatRoom
  end
  if data.PublicityTime ~= nil then
    self.mPublicityTime = data.PublicityTime
  end
  if data.ImpeachStartTime ~= nil then
    self.mImpeachStartTime = data.ImpeachStartTime
  end
  if data.GuildWarGradeId ~= nil then
    self.mGuildWarGradeId = data.GuildWarGradeId
  end
  logDebug("OurGuildData ->", self)
end

function OurGuildData:updateGradeId(data)
  if data.GradeId ~= nil then
    self.mGuildWarGradeId = data.GradeId
  end
end

function OurGuildData:updateMemberData(data)
  local msg = data or {}
  local memberList = msg.sMember or {}
  for _, v in pairs(memberList) do
    if v.UserInfo ~= nil and self.mMemberList[v.UserInfo.Uid] == nil then
      self.mMemberList[v.UserInfo.Uid] = v.UserInfo
    end
  end
end

function OurGuildData:checkMemberName()
  return next(self.mMemberList) == nil
end

function OurGuildData:getName()
  return self.mName
end

function OurGuildData:getEmblem()
  return self.mEmblem
end

function OurGuildData:getFrame()
  return self.mFrame
end

function OurGuildData:getEnounce()
  return self.mEnounce
end

function OurGuildData:getNotice()
  return self.mNotice
end

function OurGuildData:getLimit()
  return self.mLimit
end

function OurGuildData:getMemberNum()
  return self.mMemberNum or 0
end

function OurGuildData:getLeaderName()
  return self.mLeaderName or ""
end

function OurGuildData:getLeaderId()
  return self.mLeaderId
end

function OurGuildData:getDeputy()
  return self.mDeputy or {}
end

function OurGuildData:getDeputyNum()
  return self.mDeputyCount or 0
end

function OurGuildData:getLevel()
  return self.mLevel or 1
end

function OurGuildData:getExp()
  return self.mExp or 0
end

function OurGuildData:getTodayExp()
  return self.mTodayExp or 0
end

function OurGuildData:getTipList()
  local paramRec = configManager.GetDataById("config_guildparam", GUILD_PARAM_DEFAULT)
  logDebug("getTipList paramRec.InfoNum\239\188\140 #self.mTipList", paramRec.infonum, #self.mTipList)
  for i = 1, #self.mTipList - paramRec.infonum do
    table.remove(self.mTipList, 1)
  end
  logDebug("getTipList paramRec.InfoNum\239\188\140 #self.mTipList", paramRec.infonum, #self.mTipList)
  return self.mTipList
end

function OurGuildData:getProcess()
  return self.mProcess
end

function OurGuildData:getSacrificeInfo()
  return self.mSacrificeInfo
end

function OurGuildData:getSkillLevel(skillId)
  for i = 1, #(self.mSkill or {}) do
    if skillId == self.mSkill[i].id then
      return self.mSkill[i].lv
    end
  end
  return 0
end

function OurGuildData:getChatRoom()
  return self.mChatRoom or ""
end

function OurGuildData:getPublicityTime()
  return self.mPublicityTime or 0
end

function OurGuildData:getImpeachStartTime()
  return self.mImpeachStartTime or 0
end

function OurGuildData:getGuildWarGradeId()
  return self.mGuildWarGradeId or GuildWarGrade.F
end

function OurGuildData:GetGuildMemberNameByUid(uid)
  if self.mMemberList[uid] ~= nil then
    return self.mMemberList[uid].Uname
  end
  return ""
end

local GuildMember = class("GuildMember")

function GuildMember:initialize(data)
  self:updateData(data)
end

function GuildMember:updateData(data)
  if data.UserInfo ~= nil then
    if data.UserInfo.Uid ~= nil then
      self.mUid = data.UserInfo.Uid
    end
    if data.UserInfo.Uname ~= nil then
      self.mName = data.UserInfo.Uname
    end
    if data.UserInfo.Head ~= nil then
      self.mHead = data.UserInfo.Head
    end
    if data.UserInfo.Level ~= nil then
      self.mLevel = data.UserInfo.Level
    end
    if data.UserInfo.VipLevel ~= nil then
      self.mVipLevel = data.UserInfo.VipLevel
    end
    if data.UserInfo.Power ~= nil then
      self.mPower = data.UserInfo.Power
    end
    if data.UserInfo.DailyRewardStatus ~= nil then
      self.mDailyRewardStatus = data.UserInfo.DailyRewardStatus
    end
  end
  if data.LogoffTime ~= nil then
    self.mLogoffTime = data.LogoffTime
  else
    self.mLogoffTime = 0
  end
  if data.Contribute ~= nil then
    self.mContribute = data.Contribute
  end
  if data.TodayContribute ~= nil then
    self.mTodayContribute = data.TodayContribute
  end
  if data.SacrificeTime ~= nil then
    self.mSacrificeTime = data.SacrificeTime
  end
  if data.SacrificeReward ~= nil then
    self.mSacrificeReward = data.SacrificeReward
  end
  if data.Post ~= nil then
    self.mPost = data.Post
  end
end

local GuildWarData = class("GuildWarData")

function GuildWarData:initialize()
  self.pointInfos = {}
  self.maxChallengeCount = 0
  self.curChallangeCount = 0
  self.report = {}
  self.playerRankListData = {}
  self.selfRankData = nil
  self.personRankList = {}
  self.haveKillReward = false
  self.offerRankList = {}
  self.offerSelfRank = {}
  self.offerGuildRankList = {}
  self.offerSelfGuildRank = {}
end

function GuildWarData:updateInfo(data)
  if data.List ~= nil then
    for _, pointInfo in pairs(data.List) do
      self.pointInfos[pointInfo.BaseId] = pointInfo
    end
  end
  if data.TotalTickCount ~= nil then
    self.maxChallengeCount = data.TotalTickCount
  end
  if data.RemainingTickCount ~= nil then
    self.curChallangeCount = data.RemainingTickCount
  end
end

function GuildWarData:updateBaseInfo(data)
  if data == nil then
    logError("GuildWarPart:updateBaseInfo data is nil")
    return
  end
  if self.pointInfos[data.BaseId] == nil then
    logError("GuildWarPart:updateBaseInfo self.pointInfos[data.BaseId] is nil. data.BaseId..", data.BaseId)
    return
  end
  self.pointInfos[data.BaseId].CurStageId = data.CurStageId
  self.pointInfos[data.BaseId].CurSectionId = data.CurSectionId
end

function GuildWarData:updateOfferRankList(data)
  if data.List ~= nil then
    for _, info in pairs(data.List) do
      local rankInfo = {}
      rankInfo.rankNo = info.RankNo
      rankInfo.uid = info.Uid
      rankInfo.userInfo = info.UserInfo
      rankInfo.points = info.Points
      self.offerRankList[rankInfo.rankNo] = rankInfo
    end
  end
  if data.MyRank ~= nil and data.MyRank.RankNo ~= nil and data.MyRank.Uid ~= nil then
    self.offerSelfRank.rankNo = data.MyRank.RankNo
    self.offerSelfRank.uid = data.MyRank.Uid
    self.offerSelfRank.userInfo = data.MyRank.UserInfo
    self.offerSelfRank.points = data.MyRank.Points
  end
end

function GuildWarData:updateOfferGuildRankList(data)
  if data.List ~= nil then
    for _, info in pairs(data.List) do
      local rankInfo = {}
      rankInfo.rankNo = info.RankNo
      rankInfo.guildId = info.GuildId
      rankInfo.level = info.Level
      rankInfo.points = info.Points
      rankInfo.name = info.Name
      rankInfo.serverId = info.ServerId
      self.offerGuildRankList[rankInfo.rankNo] = rankInfo
    end
  end
  if data.MyGuildRank ~= nil then
    self.offerSelfGuildRank.rankNo = data.MyGuildRank.RankNo
    self.offerSelfGuildRank.guildId = data.MyGuildRank.GuildId
    self.offerSelfGuildRank.level = data.MyGuildRank.Level
    self.offerSelfGuildRank.points = data.MyGuildRank.Points
    self.offerSelfGuildRank.name = data.MyGuildRank.Name
    self.offerSelfGuildRank.serverId = data.MyGuildRank.ServerId
  end
end

function GuildWarData:updateReportListData(data)
  self.report = {}
  local reportMaxNum = configManager.GetDataById("config_parameter", 467).value
  if data.List ~= nil then
    for _, info in pairs(data.List) do
      local reportInfo = {}
      reportInfo.type = info.ReportType
      reportInfo.playerName = info.Name
      reportInfo.baseId = info.BaseId
      reportInfo.sectionId = info.SectionID
      reportInfo.damage = info.Damage
      reportInfo.time = info.ReportTime
      reportInfo.score = info.Score
      table.insert(self.report, reportInfo)
    end
  end
  table.sort(self.report, function(v1, v2)
    return v1.time < v2.time
  end)
  if reportMaxNum < table.nums(self.report) then
    while reportMaxNum < table.nums(self.report) do
      table.remove(self.report, 1)
      if table.nums(self.report) <= 0 then
        break
      end
    end
  end
end

function GuildWarData:updateReportOneData(data)
  local reportMaxNum = configManager.GetDataById("config_parameter", 467).value
  local reportInfo = {}
  reportInfo.type = data.ReportType
  reportInfo.playerName = data.Name
  reportInfo.baseId = data.BaseId
  reportInfo.sectionId = data.SectionID
  reportInfo.damage = data.Damage
  reportInfo.time = data.ReportTime
  reportInfo.score = data.Score
  table.insert(self.report, reportInfo)
  if reportMaxNum < table.nums(self.report) then
    while reportMaxNum < table.nums(self.report) do
      table.remove(self.report, 1)
      if table.nums(self.report) <= 0 then
        break
      end
    end
  end
end

function GuildWarData:updateRankData(data)
  if data.List ~= nil then
    for _, info in pairs(data.List) do
      self.playerRankListData[info.Rank] = info
    end
    table.sort(self.playerRankListData, function(v1, v2)
      return v1.Rank < v2.Rank
    end)
    local paramterConf = configManager.GetDataById("config_parameter", 466)
    local maxRankNum = paramterConf.arrValue[1]
    while maxRankNum < table.nums(self.playerRankListData) do
      table.remove(self.playerRankListData)
      if self.playerRankListData == nil or #self.playerRankListData == 0 then
        break
      end
    end
  end
  if data.SelfRank ~= nil then
    self.selfRankData = data.SelfRank
  end
end

function GuildWarData:updatePersonRankData(data)
  if data.List ~= nil then
    for _, info in pairs(data.List) do
      self.personRankList[info.BaseID] = info.List
    end
  end
end

function GuildWarData:updateHaveGuildWarReward(data)
  if data.Have ~= nil then
    self.haveKillReward = data.Have
  end
end

local GuildBoxData = class("GuildBoxData")

function GuildBoxData:initialize()
  self.anonymous = 0
  self.scoreProgress = 0
  self.pointsBoxCount = 0
  self.shareBoxList = {}
  self.taskBoxList = {}
end

function GuildBoxData:ResetGuildBoxData()
  self.scoreProgress = 0
  self.pointsBoxCount = 0
  self.shareBoxList = {}
  self.taskBoxList = {}
end

function GuildBoxData:updateGuildBoxScoreData(data)
  if data.Progress ~= nil then
    self.scoreProgress = data.Progress
  end
end

function GuildBoxData:GetScoreProgress()
  return self.scoreProgress
end

function GuildBoxData:updateGuildBoxUserData(data)
  if data.Anonymous ~= nil then
    self.anonymous = data.Anonymous
  end
  if data.PointsBoxCount ~= nil then
    self.pointsBoxCount = data.PointsBoxCount
  end
end

function GuildBoxData:GetAnonymous()
  return self.anonymous
end

function GuildBoxData:GetPointsBoxCount()
  return self.pointsBoxCount
end

function GuildBoxData:updateGuildBoxUserAllList(data)
  if data.ShareBoxList ~= nil then
    self.shareBoxList = {}
    for _, info in pairs(data.ShareBoxList) do
      local boxInfo = {}
      boxInfo.boxId = info.BoxId
      boxInfo.endTime = info.EndTime
      boxInfo.boxUid = info.BoxUid
      boxInfo.isPick = info.IsPick
      boxInfo.rewardName = info.RechargeName
      boxInfo.type = 1
      table.insert(self.shareBoxList, boxInfo)
    end
  end
  if data.TaskBoxList ~= nil then
    self.taskBoxList = {}
    for _, info in pairs(data.TaskBoxList) do
      local boxInfo = {}
      boxInfo.boxId = info.BoxId
      boxInfo.endTime = info.EndTime
      boxInfo.boxUid = info.BoxUid
      boxInfo.isPick = info.IsPick
      boxInfo.rewardName = info.ItemInfoName
      boxInfo.type = 2
      table.insert(self.taskBoxList, boxInfo)
    end
  end
end

function GuildBoxData:GetShareBoxList()
  return self.shareBoxList
end

function GuildBoxData:GetTaskBoxList()
  return self.taskBoxList
end

function GuildBoxData:CheckCanGetTaskBox()
  for _, info in pairs(self.taskBoxList) do
    if not info.isPick then
      return true
    end
  end
  return false
end

function GuildBoxData:updateGuildBoxShareAdd(data)
  if data.AddList ~= nil then
    for _, info in pairs(data.AddList) do
      local boxInfo = {}
      boxInfo.boxId = info.BoxId
      boxInfo.endTime = info.EndTime
      boxInfo.boxUid = info.BoxUid
      boxInfo.isPick = info.IsPick
      boxInfo.rewardName = info.RechargeName
      boxInfo.type = 1
      local isExist = false
      for _, curInfo in pairs(self.shareBoxList) do
        if curInfo.boxId == info.BoxId then
          curInfo = boxInfo
          isExist = true
          break
        end
      end
      if not isExist then
        table.insert(self.shareBoxList, boxInfo)
      end
    end
  end
end

function GuildBoxData:updateGuildBoxTaskAdd(data)
  if data.AddList ~= nil then
    for _, info in pairs(data.AddList) do
      local boxInfo = {}
      boxInfo.boxId = info.BoxId
      boxInfo.endTime = info.EndTime
      boxInfo.boxUid = info.BoxUid
      boxInfo.isPick = info.IsPick
      boxInfo.rewardName = info.ItemInfoName
      boxInfo.type = 2
      local isExist = false
      for _, curInfo in pairs(self.taskBoxList) do
        if curInfo.boxId == info.BoxId then
          curInfo = boxInfo
          isExist = true
          break
        end
      end
      if not isExist then
        table.insert(self.taskBoxList, boxInfo)
      end
    end
  end
end

function GuildBoxData:updateGuildBoxState(data)
  if data.BoxId ~= nil then
    for _, v in pairs(self.shareBoxList) do
      if v.boxId == data.BoxId then
        v.isPick = true
        eventManager:SendEvent(LuaEvent.UpdateGuildBoxShareState)
        return
      end
    end
    for _, v in pairs(self.taskBoxList) do
      if v.boxId == data.BoxId then
        v.isPick = true
        eventManager:SendEvent(LuaEvent.UpdateGuildBoxTaskState)
        return
      end
    end
  end
end

function GuildBoxData:updateGuildTaskBBoxState()
  for _, v in pairs(self.taskBoxList) do
    v.isPick = true
  end
  eventManager:SendEvent(LuaEvent.UpdateGuildBoxTaskState)
end

function GuildBoxData:updatePointsGuildBoxState()
  self.pointsBoxCount = 0
  eventManager:SendEvent(LuaEvent.UpdateGuildBoxUserData)
end

function GuildBoxData:sortGuildBoxList(list)
  table.sort(list, function(data1, data2)
    if data1.isPick ~= data2.isPick then
      return not data1.isPick
    end
    if data1.endTime ~= data2.endTime then
      return data1.endTime < data2.endTime
    end
    return data1.boxId < data2.boxId
  end)
end

function GuildBoxData:RefreshRewardList(refreshType)
  if refreshType == 1 then
    self:ResortGuildBoxList(self.shareBoxList)
  elseif refreshType == 2 then
    self:ResortGuildBoxList(self.taskBoxList)
  else
    self:ResortGuildBoxList(self.shareBoxList)
    self:ResortGuildBoxList(self.taskBoxList)
  end
end

function GuildBoxData:ResortGuildBoxList(guildBoxList)
  local nowTime = time.getSvrTime()
  for i = #guildBoxList, 1, -1 do
    if nowTime >= guildBoxList[i].endTime then
      table.remove(guildBoxList, i)
    end
  end
  self:sortGuildBoxList(guildBoxList)
end

function GuildBoxData:CheckCanGetBox()
  if self.pointsBoxCount > 0 then
    return true
  end
  local nowTime = time.getSvrTime()
  for _, v in pairs(self.shareBoxList) do
    if not v.isPick and nowTime < v.endTime then
      return true
    end
  end
  for _, v in pairs(self.taskBoxList) do
    if not v.isPick and nowTime < v.endTime then
      return true
    end
  end
  return false
end

local GuildBigActivityData = class("GuildBigActivityData")

function GuildBigActivityData:initialize()
  self.points = 0
  self.itemNum = 0
  self.guildRateData = {}
  self.guildRankList = {}
  self.selfRankData = {}
  self.periodTastData = {}
end

function GuildBigActivityData:updateUserData(data)
  if data.Points then
    self.points = data.Points
    eventManager:SendEvent(LuaEvent.UpdateGuildBigActPointsData)
  end
  if data.ItemNum then
    self.itemNum = data.ItemNum
    eventManager:SendEvent(LuaEvent.UpdateGuildBigActItemsData)
  end
end

function GuildBigActivityData:GetUserPoints()
  return self.points
end

function GuildBigActivityData:GetItemNum()
  return self.itemNum
end

function GuildBigActivityData:updateGuildRateData(data)
  self.guildRateData.currentRate = data.CurrentRate
  self.guildRateData.nextRate = data.NextRate
  self.guildRateData.nextItemNum = data.NextItemNum
  self.guildRateData.nextItemAllNum = data.NextItemAllNum
  eventManager:SendEvent(LuaEvent.UpdateGuildBigActRateData)
end

function GuildBigActivityData:GetGuildCurrentRate()
  if self.guildRateData.currentRate then
    return self.guildRateData.currentRate
  end
  return 0
end

function GuildBigActivityData:GetGuildNextRate()
  if self.guildRateData.nextRate then
    return self.guildRateData.nextRate
  end
  return 0
end

function GuildBigActivityData:GetGuildNextItemNum()
  if self.guildRateData.nextItemNum then
    return self.guildRateData.nextItemNum
  end
  return 0
end

function GuildBigActivityData:GetGuildNextItemAllNum()
  if self.guildRateData.nextItemAllNum then
    return self.guildRateData.nextItemAllNum
  end
  return 0
end

function GuildBigActivityData:updateGuildRankList(data)
  if next(data.List) then
    local maxNo = 0
    for _, v in pairs(data.List) do
      local reData = self:resetGuildRankList(v)
      if maxNo < reData.rankNo then
        maxNo = reData.rankNo
      end
      self.guildRankList[reData.rankNo] = reData
    end
    for k, _ in pairs(self.guildRankList) do
      if k > maxNo then
        table.remove(self.guildRankList, k)
      end
    end
    eventManager:SendEvent(LuaEvent.UpdateGuildBigActRankData)
  end
  if next(data.MyGuildRank) then
    self.selfRankData = self:resetGuildRankList(data.MyGuildRank)
    eventManager:SendEvent(LuaEvent.UpdateGuildBigActSelfData)
  end
end

function GuildBigActivityData:resetGuildRankList(data)
  local rankData = {}
  rankData.rankNo = data.RankNo
  rankData.guildId = data.GuildId
  rankData.points = data.Points
  rankData.level = data.Level
  rankData.name = data.Name
  rankData.serverId = data.ServerId
  rankData.currentRate = data.CurrentRate
  return rankData
end

function GuildBigActivityData:GetGuildAllRankData()
  return self.guildRankList
end

function GuildBigActivityData:GetGuildSelfRankData()
  return self.selfRankData
end

function GuildBigActivityData:ResetTaskList()
  local taskList = Data.taskData:GetTaskDataByType(TaskType.GuildBigAct)
  if taskList == nil then
    return nil
  end
  self.periodTastData = {}
  for _, v in pairs(taskList) do
    local bigTaskCfg = configManager.GetDataById("config_guildactivitytask", v.TaskId)
    if bigTaskCfg ~= nil then
      if self.periodTastData[bigTaskCfg.belong] == nil then
        self.periodTastData[bigTaskCfg.belong] = {}
      end
      v.Config = bigTaskCfg
      table.insert(self.periodTastData[bigTaskCfg.belong], v)
    else
      logError("GuildBigActivityData guildactivitytask TaskId[%d] is error", v.TaskId)
    end
  end
  for _, v in pairs(self.periodTastData) do
    table.sort(v, function(data1, data2)
      if (data1.RewardTime == 0 or data2.RewardTime == 0) and data1.RewardTime ~= data2.RewardTime then
        return data2.RewardTime ~= 0
      end
      if (data1.FinishTime == 0 or data2.FinishTime == 0) and data1.FinishTime ~= data2.FinishTime then
        return data2.FinishTime == 0
      end
      if data1.Config.order ~= data2.Config.order then
        return data1.Config.order < data2.Config.order
      end
      if data1.TaskId ~= data2.TaskId then
        return data1.TaskId < data2.TaskId
      end
      return false
    end)
  end
end

function GuildBigActivityData:GetTaskListByIdx(index)
  if self.periodTastData[index] == nil then
    return {}
  end
  return self.periodTastData[index]
end

function GuildBigActivityData:CheckHaveTaskReward()
  local taskList = Data.taskData:GetTaskDataByType(TaskType.GuildBigAct)
  for _, v in pairs(taskList) do
    if v.FinishTime > 0 and 0 >= v.RewardTime then
      return true
    end
  end
  return false
end

function GuildBigActivityData:CheckHavePeriodTaskReward(index)
  local taskList = Data.taskData:GetTaskDataByType(TaskType.GuildBigAct)
  for _, v in pairs(taskList) do
    local bigTaskCfg = configManager.GetDataById("config_guildactivitytask", v.TaskId)
    if bigTaskCfg ~= nil and bigTaskCfg.belong == index and v.FinishTime > 0 and 0 >= v.RewardTime then
      return true
    end
  end
  return false
end

local GuildData = class("GuildData")

function GuildData:initialize()
  self.mGuildWarData = GuildWarData:new()
  self.mGuildBoxData = GuildBoxData:new()
  self.mGuildBigActData = GuildBigActivityData:new()
end

function GuildData:init()
end

function GuildData:getHaveApply()
  local haveApply = self:innerGetHaveApply()
  logDebug("GuildData:getHaveApply haveApply:", haveApply, self:getApplyFlagOfShow())
  if self:getApplyFlagOfShow() == false then
    return 0
  end
  if haveApply <= 0 then
    return 0
  else
    return 1
  end
end

function GuildData:innerGetHaveApply()
  logDebug("GuildData:innergetHaveApply")
  if self == nil then
    return -1
  end
  local ourGuildInfo = self:getOurGuildInfo()
  if ourGuildInfo == nil then
    return -2
  end
  if not self:inGuild() then
    return -3
  end
  local post = self.mMyGuildInfo:getPost()
  local haveRight = post == Post.Leader or post == Post.Deputy
  if not haveRight then
    return -4
  end
  if ourGuildInfo.mApplyNum == nil or ourGuildInfo.mApplyNum <= 0 then
    return -5
  end
  return 1
end

function GuildData:updateTmpSearchInfo(data)
  self.mTmpSearchInfo = BaseGuildInfo:new(data)
end

function GuildData:getTmpSearchInfo()
  return self.mTmpSearchInfo
end

function GuildData:updateOurGuildInfo(data)
  if data == nil then
    return
  end
  local sOurGuildInfo = self.mOurGuildInfo
  if sOurGuildInfo == nil then
    sOurGuildInfo = OurGuildData:new(data)
  else
    sOurGuildInfo:updateData(data)
  end
  self.mOurGuildInfo = sOurGuildInfo
  eventManager:SendEvent(LuaEvent.Update_OurGuildInfo)
end

function GuildData:updateGuildMemberData(data)
  if data == nil or next(data) == nil then
    return
  end
  if self.mOurGuildInfo == nil then
    return
  end
  self.mOurGuildInfo:updateMemberData(data)
end

function GuildData:updateGuildWarGradeId(data)
  if data == nil then
    return
  end
  if self.mOurGuildInfo == nil then
    return
  end
  self.mOurGuildInfo:updateGradeId(data)
  eventManager:SendEvent(LuaEvent.UpdateGuildWarGradeId)
end

function GuildData:updateMyGuildInfo(data)
  logDebug("updateMyGuildInfo")
  logDebug("updateMyGuildInfo")
  if data == nil then
    return
  end
  local sMyGuildInfo = self.mMyGuildInfo
  if sMyGuildInfo == nil then
    sMyGuildInfo = MyGuildData:new(data)
  else
    sMyGuildInfo:updateData(data)
  end
  self.mMyGuildInfo = sMyGuildInfo
  eventManager:SendEvent(LuaEvent.Update_MyGuildInfo)
end

function GuildData:getMyGuildInfo()
  return self.mMyGuildInfo
end

function GuildData:hasEverApply(guild)
  if self.mMyGuildInfo == nil then
    logWarning("hasEverApply self.mMyGuildInfo  == nil ")
    return false
  end
  return self.mMyGuildInfo:hasAlreadyApply(guild)
end

function GuildData:getOurGuildInfo()
  return self.mOurGuildInfo
end

function GuildData:clearOurGuildInfo()
  self.mOurGuildInfo = nil
end

function GuildData:getGuildId()
  if self:inGuild() then
    local myGuild = self:getMyGuildInfo()
    if myGuild == nil then
      return 0
    end
    return myGuild.mGuildId
  end
  return 0
end

function GuildData:getGuildName()
  if self:inGuild() then
    local ourGuild = self:getOurGuildInfo()
    return ourGuild:getName()
  end
  return ""
end

function GuildData:inGuild(trueCallback, falseCallback)
  local myGuild = self:getMyGuildInfo()
  local ourGuild = self:getOurGuildInfo()
  local isIn = true
  if myGuild == nil or ourGuild == nil or myGuild.mGuildId == nil or myGuild.mQuitTime == nil then
    isIn = false
  end
  isIn = isIn and myGuild.mGuildId > 0 and myGuild.mQuitTime <= 0
  if isIn and trueCallback ~= nil then
    trueCallback()
  end
  if not isIn and falseCallback ~= nil then
    falseCallback()
  end
  return isIn
end

function GuildData:getSkillStr(skillId, skillLv)
  if skillLv <= 0 then
    skillLv = 0
  end
  local skillRec = Meta.Get(MetaAlias.GUILD_SKILL, skillId)
  local power = ConfFunc:RunCmd(skillRec.AffixPowerScript, skillRec.AffixPowerParam, skillLv)
  logDebug("GuildData:getSkillStr skillId, skillLv, power", skillId, skillLv, power)
  local affixStr = self:getAffixStr(skillRec.Affix, power)
  return affixStr
end

function GuildData:getAffixStr(affixId, affixPower)
  local affixTable = Power:MakeAffixUnit(affixId, affixPower)
  local ret = Power:GetDisplayAttrFromAffix(affixTable)
  logDebug("GuildData:getAffixStr affixTable, ret", affixTable, ret)
  for k, v in pairs(ret) do
    logDebug("GuildData:getAffixStr ret pairs", k, v)
    local attrInfo = Meta.Get(MetaAlias.COMBAT_ATTR, k)
    local str = Lang.GetDictStringById(attrInfo.Name)
    return str .. "+" .. v
  end
end

function GuildData:updateGuildSkillState(skillState)
  local ourGuild = self:getOurGuildInfo()
  local newSkillState = {}
  for i, skill in ipairs(skillState) do
    local skillRec = Meta.Get(MetaAlias.GUILD_SKILL, skill.id)
    skill.lv = ourGuild:getSkillLevel(skill.id)
    skill.state = self:getOneSkillState(skillRec, skill.lv, ourGuild:getLevel())
    table.insert(newSkillState, skill)
  end
  return newSkillState
end

function GuildData:getOneSkillState(skillRec, skillLv, guildLv)
  if skillLv == skillRec.AffixLvMaxParam[#skillRec.AffixLvMaxParam] then
    return Skill.Max
  end
  if guildLv < skillRec.Skilllv then
    return Skill.Close
  elseif skillLv == 0 then
    return Skill.Open
  else
    local state = Skill.Upgrade
    local skillLvLimit = ConfFunc:RunCmd(skillRec.AffixLvMaxScript, skillRec.AffixLvMaxParam, guildLv)
    if skillLv >= skillLvLimit then
      state = Skill.Close
    end
    return state
  end
end

function GuildData:getGuildSkillState()
  local ourGuild = self:getOurGuildInfo()
  local skillState = {}
  local allSkillRec = Meta.GetAllSorted(MetaAlias.GUILD_SKILL)
  for i, skillRec in ipairs(allSkillRec) do
    local skill = {}
    skill.id = skillRec.Id
    skill.lv = ourGuild:getSkillLevel(skillRec.Id)
    skill.state = self:getOneSkillState(skillRec, skill.lv, ourGuild:getLevel())
    table.insert(skillState, skill)
  end
  table.sort(skillState, sortSkillState)
  return skillState
end

function sortSkillState(s1, s2)
  if s1.state == s2.state then
    return s1.id > s2.id
  end
  return s1.state < s2.state
end

local PersonSkillState = {
  CanLearn = 1,
  NotOpen = 2,
  GotoUpgrade = 3
}

function GuildData:getOnePersonSkillState(skillRec, skill)
  if skill.guildLv == 0 then
    return PersonSkillState.NotOpen
  elseif skill.lv >= skill.guildLv then
    return PersonSkillState.GotoUpgrade
  else
    return PersonSkillState.CanLearn
  end
end

function GuildData:getMySkillState()
  local ourGuild = self:getOurGuildInfo()
  local myGuild = self:getMyGuildInfo()
  if ourGuild == nil or myGuild == nil then
    return {}
  end
  local skillState = {}
  local allSkillRec = Meta.GetAllSorted(MetaAlias.GUILD_SKILL)
  for i, skillRec in ipairs(allSkillRec) do
    local guildLv = ourGuild:getSkillLevel(skillRec.Id)
    local skill = {}
    skill.id = skillRec.Id
    skill.guildLv = guildLv
    skill.lv = myGuild:getSkillLevel(skillRec.Id)
    table.insert(skillState, skill)
    skill.state = self:getOnePersonSkillState(skillRec, skill)
  end
  table.sort(skillState, sortMySkillState)
  return skillState
end

function sortMySkillState(s1, s2)
  if s1.state == s2.state then
    return s1.id > s2.id
  end
  return s1.state < s2.state
end

function GuildData:calculateAttr()
  if not self:inGuild() then
    return {}
  end
  local ourGuild = self:getOurGuildInfo()
  local skillState = PlayerData.guildData:getMySkillState()
  local affixTable = {}
  for i, skill in ipairs(skillState) do
    local guildSkillLv = ourGuild:getSkillLevel(skill.id)
    local validSkillLv = skill.lv
    if guildSkillLv < skill.lv then
      validSkillLv = guildSkillLv
    end
    if 0 < validSkillLv then
      local skillRec = Meta.Get(MetaAlias.GUILD_SKILL, skill.id)
      local power = ConfFunc:RunCmd(skillRec.AffixPowerScript, skillRec.AffixPowerParam, validSkillLv)
      local affixUnit = Power:MakeAffixUnit(skillRec.Affix, power)
      table.insert(affixTable, affixUnit)
    end
  end
  local attrData = Power:AttrFromAffix(unpack(affixTable))
  return attrData
end

function GuildData:getApplyFlagOfShow()
  if self.mApplyFlagOfShow == nil then
    self.mApplyFlagOfShow = true
  end
  logDebug("GuildData:getApplyFlagOfShow", self.mApplyFlagOfShow)
  return self.mApplyFlagOfShow
end

function GuildData:setApplyFlagOfShow(show)
  logDebug("GuildData:setApplyFlagOfShow", show)
  self.mApplyFlagOfShow = show
end

function GuildData:canApply()
  local paramRec = configManager.GetDataById("config_guildparam", GUILD_PARAM_DEFAULT)
  local myGuildInfo = self:getMyGuildInfo()
  if myGuildInfo == nil then
    return true
  end
  local applyList = myGuildInfo.mApplyList or {}
  local applyNum = 0
  for idx, val in ipairs(applyList) do
    if val.GuildId ~= nil then
      applyNum = applyNum + 1
    end
  end
  if applyNum >= paramRec.applymax then
    return false, 710035
  end
  local nowTime = time.getSvrTime()
  local quitTime = myGuildInfo.mQuitTime or 0
  if 0 < quitTime and nowTime < quitTime + paramRec.quittime then
    return false, 710028
  end
  return true, 0
end

function GuildData:getMaxGuildLevel()
  local paramRec = configManager.GetDataById("config_guildparam", GUILD_PARAM_DEFAULT)
  return paramRec.guildlv
end

function GuildData:GetPostRightByPostRelation(post1, post2)
  local ruletab = Rule_PostRelation[post1] or {}
  local rightlist = ruletab[post2] or {}
  return rightlist
end

function GuildData:getPublicityCD()
  local cfg = configManager.GetDataById("config_guildparam", GUILD_PARAM_DEFAULT)
  local cd = cfg.announcencdtime
  local now = time.getSvrTime() - 1
  local ourGuildData = self:getOurGuildInfo()
  local mPublicityTime = ourGuildData:getPublicityTime()
  if mPublicityTime == nil or mPublicityTime <= 0 then
    return -1
  end
  local retcd = mPublicityTime - now + cd
  return retcd
end

function GuildData:CanPublicity()
  local publicitycd = self:getPublicityCD()
  if 0 < publicitycd then
    local remaintime = time.getTimeStringFontDynamic(math.floor(publicitycd))
    return false, remaintime
  end
  return true
end

function GuildData:GetPostByUid(uid)
  local ourGuildData = self:getOurGuildInfo()
  if ourGuildData:getLeaderId() == uid then
    return Post.Leader
  end
  local deputy = ourGuildData:getDeputy()
  if deputy[uid] then
    return Post.Deputy
  end
  return Post.Member
end

function GuildData:updateGuildWarInfo(data)
  self.mGuildWarData:updateInfo(data)
end

function GuildData:updateGuildWarReportList(data)
  self.mGuildWarData:updateReportListData(data)
end

function GuildData:updateGuildWarReportOne(data)
  self.mGuildWarData:updateReportOneData(data)
end

function GuildData:updateRankData(data)
  self.mGuildWarData:updateRankData(data)
end

function GuildData:updatePersonRankData(data)
  self.mGuildWarData:updatePersonRankData(data)
end

function GuildData:updateHaveGuildWarReward(data)
  self.mGuildWarData:updateHaveGuildWarReward(data)
end

function GuildData:updateGuildWarBaseInfo(data)
  self.mGuildWarData:updateBaseInfo(data)
end

function GuildData:updateGuildWarOfferRankList(data)
  self.mGuildWarData:updateOfferRankList(data)
end

function GuildData:updateGuildWarOfferGuildRankList(data)
  self.mGuildWarData:updateOfferGuildRankList(data)
end

function GuildData:GetGuildWarData()
  return self.mGuildWarData
end

function GuildData:updateGuildBoxScoreData(data)
  self.mGuildBoxData:updateGuildBoxScoreData(data)
end

function GuildData:updateGuildBoxUserData(data)
  self.mGuildBoxData:updateGuildBoxUserData(data)
end

function GuildData:updateGuildBoxUserAllList(data)
  self.mGuildBoxData:updateGuildBoxUserAllList(data)
end

function GuildData:updateGuildBoxShareAdd(data)
  self.mGuildBoxData:updateGuildBoxShareAdd(data)
end

function GuildData:updateGuildBoxTaskAdd(data)
  self.mGuildBoxData:updateGuildBoxTaskAdd(data)
end

function GuildData:updateGuildBoxState(data)
  self.mGuildBoxData:updateGuildBoxState(data)
end

function GuildData:updateGuildTaskBBoxState(data)
  self.mGuildBoxData:updateGuildTaskBBoxState(data)
end

function GuildData:updatePointsGuildBoxState(data)
  self.mGuildBoxData:updatePointsGuildBoxState(data)
end

function GuildData:ShowGuildBoxRewardList(data)
  if #data.RewardList <= 0 then
    return
  end
  local res = {}
  for _, v in pairs(data.RewardList) do
    local temp = {}
    temp.Type = v.Type
    temp.ConfigId = v.ConfigId
    temp.Num = v.Num
    temp.Id = v.Id
    table.insert(res, temp)
  end
  UIHelper.OpenPage("GetRewardsPage", {Rewards = res})
end

function GuildData:GetGuildBoxData()
  return self.mGuildBoxData
end

function GuildData:updateGuildBigActivityUserData(data)
  self.mGuildBigActData:updateUserData(data)
end

function GuildData:updateGuildBigActivityGuildRateData(data)
  self.mGuildBigActData:updateGuildRateData(data)
end

function GuildData:updateGuildBigActivityGuildRankList(data)
  self.mGuildBigActData:updateGuildRankList(data)
end

function GuildData:GetGuildBigActivityData()
  return self.mGuildBigActData
end

return GuildData
