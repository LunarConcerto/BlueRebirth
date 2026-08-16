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
end

function MyGuildData:doNoticeProcess()
  if self.mQuitReason == QuitReason.Kick then
    noticeManager:ShowTip("\230\130\168\229\183\178\232\162\171\232\136\176\233\149\191\232\184\162\229\135\186\229\164\167\232\136\176\233\152\159")
  elseif self.mQuitReason == QuitReason.Dismiss or self.mQuitReason == QuitReason.Dismissed then
    noticeManager:ShowTip("\230\130\168\231\154\132\229\164\167\232\136\176\233\152\159\229\183\178\232\162\171\232\167\163\230\149\163")
  elseif self.mQuitReason == QuitReason.Quit then
  else
    noticeManager:ShowTip("\229\175\185\228\184\141\232\181\183\239\188\140\228\189\160\231\154\132\229\164\167\232\136\176\233\152\159\229\183\178\228\184\141\229\173\152\229\156\168")
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
    noticeManager:ShowMsgBox("\230\130\168\229\183\178\232\162\171\232\136\176\233\149\191\232\184\162\229\135\186\229\164\167\232\136\176\233\152\159", tabParams)
  elseif self.mQuitReason == QuitReason.Dismiss or self.mQuitReason == QuitReason.Dismissed then
    local tabParams = {
      msgType = NoticeType.OneButton,
      callback = function(bool)
        gShowingExitTip = false
        UIHelper.OpenPage("HomePage")
      end
    }
    noticeManager:ShowMsgBox("\230\130\168\231\154\132\229\164\167\232\136\176\233\152\159\229\183\178\232\162\171\232\167\163\230\149\163", tabParams)
  elseif self.mQuitReason == QuitReason.Quit then
  else
    local tabParams = {
      msgType = NoticeType.OneButton,
      callback = function(bool)
        gShowingExitTip = false
        UIHelper.OpenPage("HomePage")
      end
    }
    noticeManager:ShowMsgBox("\229\175\185\228\184\141\232\181\183\239\188\140\228\189\160\231\154\132\229\164\167\232\136\176\233\152\159\229\183\178\228\184\141\229\173\152\229\156\168", tabParams)
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
  logDebug("OurGuildData ->", self)
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

local GuildData = class("GuildData")

function GuildData:initialize()
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

return GuildData
