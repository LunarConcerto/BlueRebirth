local TeachingLogic = class("logic.TeachingLogic")
local HaveTeacherMax = 1

function TeachingLogic:initialize()
  self:ResetData()
  self:RegisterAllEvent()
end

function TeachingLogic:ResetData()
  self.m_teachingPersonInfoConfig = nil
  self:_HandleConfig()
  self.m_showContent = {
    CareerIndex = 1,
    RankUpdateTime = 0,
    StudyUpdateTime = 0,
    TeachUpdateTime = 0,
    ChangeUpdateTime = 0,
    SearchTime = 0,
    RecommendUpdatTime = 0
  }
  self.m_applyLock = false
  self.m_applyUsr = {}
end

function TeachingLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.TEACHING_GetApplys, self._OnGetApplys, self)
end

function TeachingLogic:_OnGetApplys()
  self.m_applyLock = true
end

function TeachingLogic:SetApplyUsr(uid)
  self.m_applyUsr[uid] = true
end

function TeachingLogic:RemoveApplyUsr(uid)
  self.m_applyUsr[uid] = nil
end

function TeachingLogic:ResetApplyUsr()
  self.m_applyUsr = {}
end

function TeachingLogic:HaveApply(uid)
  return self.m_applyUsr[uid]
end

function TeachingLogic:GetCareerIndex()
  return self.m_showContent.CareerIndex
end

function TeachingLogic:SetCareerIndex(index)
  self.m_showContent.CareerIndex = index
end

function TeachingLogic:SetRankUpdateTime(time)
  self.m_showContent.RankUpdateTime = time
end

function TeachingLogic:SetChangeUpdateTime(time)
  self.m_showContent.ChangeUpdateTime = time
end

function TeachingLogic:SetStudyUpdateTime(time)
  self.m_showContent.StudyUpdateTime = time
end

function TeachingLogic:SetTeachUpdateTime(time)
  self.m_showContent.TeachUpdateTime = time
end

function TeachingLogic:SetSearchTime()
  self.m_showContent.SearchTime = time.getSvrTime()
end

function TeachingLogic:SetRecommendUpdatTime()
  self.m_showContent.RecommendUpdatTime = time.getSvrTime()
end

function TeachingLogic:_HandleConfig()
  self:_HandleTeachingPersonalInfoConfig()
end

function TeachingLogic:_HandleTeachingPersonalInfoConfig()
  local configs = configManager.GetData("config_teaching_personal_info")
  local res = {}
  for id, config in pairs(configs) do
    if res[config.group] then
      res[config.group][config.order] = config
    else
      res[config.group] = {
        [config.order] = config
      }
    end
  end
  self.m_teachingPersonInfoConfig = res
end

function TeachingLogic._getParamConfigById(id)
  return configManager.GetDataById("config_parameter", id).value
end

function TeachingLogic._getTeachingCareerConfig()
  return configManager.GetData("config_teaching_achievement")
end

function TeachingLogic:GetTeachingCareerConfigById(id)
  return configManager.GetDataById("config_teaching_achievement", id)
end

function TeachingLogic:GetStudentLvDown()
  return TeachingLogic._getParamConfigById(233)
end

function TeachingLogic:GetStudentLvUp()
  return TeachingLogic._getParamConfigById(234)
end

function TeachingLogic:GetTeacherLvDwon()
  return TeachingLogic._getParamConfigById(235)
end

function TeachingLogic:GetTeachingNumUp()
  return TeachingLogic._getParamConfigById(236)
end

function TeachingLogic:GetTeachingMedalNumUp()
  local config = configManager.GetDataById("config_parameter", 270).arrValue
  return {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.TEACHINGMERITS,
    Num = config[1]
  }
end

function TeachingLogic:GetSignUp()
  return TeachingLogic._getParamConfigById(269)
end

function TeachingLogic:GetEvaUp()
  return TeachingLogic._getParamConfigById(271)
end

function TeachingLogic:GetDefaultEvaluateStar()
  return 3
end

function TeachingLogic:GetEvaStarMax()
  return 3
end

function TeachingLogic:GetDefaultEvaluateStr()
  return "\232\176\162\232\176\162\229\175\188\229\184\136\231\154\132\230\130\137\229\191\131\230\140\135\229\175\188!"
end

function TeachingLogic:GetDefaultSignStr()
  return UIHelper.GetString(2200060)
end

function TeachingLogic:GetRecruitNumUp()
  return TeachingLogic._getParamConfigById(250)
end

function TeachingLogic:GetRequestNumUp()
  return TeachingLogic._getParamConfigById(244)
end

function TeachingLogic:GetReleaseDownTime()
  return TeachingLogic._getParamConfigById(246) * 60 * 60
end

function TeachingLogic:GetTeachAgainDownTime()
  return TeachingLogic._getParamConfigById(247) * 60 * 60
end

function TeachingLogic:GetStudyAgainDownTime()
  return TeachingLogic._getParamConfigById(248) * 60 * 60
end

function TeachingLogic:GetRankNumUp()
  return TeachingLogic._getParamConfigById(242)
end

function TeachingLogic:GetChangeDown()
  return TeachingLogic._getParamConfigById(272)
end

function TeachingLogic:GetSelfInfoConfig()
  return self.m_teachingPersonInfoConfig
end

function TeachingLogic:GetSelfInfoById(groupId, value)
  return self.m_teachingPersonInfoConfig[groupId][value + 1]
end

function TeachingLogic:GetRankRefreshConfig()
  return TeachingLogic._getParamConfigById(241) * 24 * 60 * 60
end

function TeachingLogic:GetScoreStarConvertConfig()
  return configManager.GetDataById("config_parameter", 237).arrValue
end

function TeachingLogic:GetPunishTimeUp()
  return TeachingLogic._getParamConfigById(249) * 60 * 60
end

function TeachingLogic:GetStarEvaId(starNum)
  local starStrTab = configManager.GetDataById("config_parameter", 263).arrValue
  return starStrTab[starNum]
end

function TeachingLogic:GetRankUpdateDelta()
  return 10
end

function TeachingLogic:GetTeachUpdateDelta()
  return 10
end

function TeachingLogic:GetShowEvaNumDown()
  return TeachingLogic._getParamConfigById(240)
end

function TeachingLogic:GetDailyTaskUp(stage)
  return self:GetExamConfig(stage).task_daily_limit
end

function TeachingLogic:GetRecommendCacheTime()
  return TeachingLogic._getParamConfigById(286)
end

function TeachingLogic:GetUserTeachingState()
  return ETeachingState.NONE
end

function TeachingLogic:GetUserCanTeachState(lv)
  lv = lv or Data.userData:GetUserLevel()
  if lv < self:GetStudentLvDown() then
    return ETeachingState.NONE
  elseif lv >= self:GetTeacherLvDwon() then
    return ETeachingState.TEACHER
  else
    return ETeachingState.STUDENT
  end
end

function TeachingLogic:GetTeachingInfo(isTeacher)
  if not self:CheckGetDataCondition() then
    return {}
  end
  local info = isTeacher and self:_TryGetStudy() or self:_TryGetTeach()
  return info
end

function TeachingLogic:_TryGetTeach()
  local info = {}
  if not self:NeedGetTeach(true) then
    info = Data.teachingData:GetMyTeacher()
  else
    Service.teachingService:GetMyTeacher()
    self:SetTeachUpdateTime(time.getSvrTime())
  end
  return info
end

function TeachingLogic:_TryGetStudy()
  local info = {}
  if not self:NeedGetTeach(false) then
    info = Data.teachingData:GetMyStudent()
  else
    Service.teachingService:GetMyStudent()
    self:SetStudyUpdateTime(time.getSvrTime())
  end
  return info
end

function TeachingLogic:GetLocalTeachInfo(isTeacher)
  local info = isTeacher and Data.teachingData:GetMyStudent() or Data.teachingData:GetMyTeacher()
  return info
end

function TeachingLogic:HaveGetTeach()
  local state = self:GetUserCanTeachState()
  local have
  if state == ETeachingState.STUDENT then
    have = Data.teachingData:HaveSetTeach()
    return have, true
  elseif state == ETeachingState.TEACHER then
    have = Data.teachingData:HaveSetStudy()
    return have, true
  else
    return false, false
  end
end

function TeachingLogic:ForceGetTeach()
  local state = self:GetUserCanTeachState()
  if state == ETeachingState.STUDENT then
    Service.teachingService:GetMyTeacher()
  elseif state == ETeachingState.TEACHER then
    Service.teachingService:GetMyStudent()
  else
    return false, "\229\176\157\232\175\149\229\143\150\229\183\178\228\189\142\228\186\142\230\156\128\228\189\142\229\173\166\231\148\159\231\173\137\231\186\167\231\154\132\231\142\169\229\174\182\231\154\132\229\175\188\229\184\136\228\191\161\230\129\175"
  end
  return true, ""
end

function TeachingLogic:GetExamTask()
  local stage = self:GetExamStage()
  local tasks = Logic.taskLogic:GetTeachExamTasks()
  return tasks, stage
end

function TeachingLogic:GetExamStage()
  local stage = Data.taskData:GetTeachStage()
  if stage == 0 then
    stage = TeachingLogic.STARTEXAMID
  end
  return stage
end

function TeachingLogic:GetExamedMaxStage()
  local data = Data.taskData:GetTeachDoneStage()
  local max = 0
  if 0 < #data then
    table.sort(data)
    max = data[#data]
  end
  return max
end

function TeachingLogic:IsMyStudent(uid)
  local data = Data.teachingData:GetMyStudent()
  for _, info in ipairs(data) do
    if info.Uid == uid then
      return true
    end
  end
  return false
end

function TeachingLogic:IsMyTeacher(uid)
  local data = Data.teachingData:GetMyTeacher()
  return data.Uid == uid
end

function TeachingLogic:GetSExamTask()
  return self:GetExamTask()
end

function TeachingLogic:GetSExamStage()
  return self:GetExamStage()
end

function TeachingLogic:GetSExamedMaxStage()
  return self:GetExamedMaxStage()
end

function TeachingLogic:GetSDailyTask()
  return self:GetDailyTask()
end

function TeachingLogic:GetExamRewards(stage, usrLv)
  local group = self:GetExamConfig(stage)
  local param = {
    group.rewards,
    group.rewards_for_teacher
  }
  local rewards = self:DisposeReward(param, usrLv, stage)
  return rewards
end

function TeachingLogic:GetExamConfig(stage)
  local group = configManager.GetDataById("config_task_teaching_group", stage)
  return group
end

function TeachingLogic:DisposeReward(param, usrLv, stage)
  local soreward = Logic.rewardLogic:FormatRewardById(param[1])
  local toreward = Logic.rewardLogic:FormatRewardById(param[2])
  local disposeTReward = {}
  for _, v in ipairs(toreward) do
    v.isTReward = true
    table.insert(disposeTReward, v)
  end
  table.insertto(soreward, disposeTReward)
  return soreward
end

function TeachingLogic:GetDailyTask()
  return Logic.taskLogic:GetTaskListByType(TaskType.TeachingDaily)
end

function TeachingLogic:GetStudentRewardsTip(usrLv, stage)
  return self:GetRewardFactor(usrLv, stage).tips
end

function TeachingLogic:GetCareerReward(id)
  local config = self:GetTeachingCareerConfigById(id)
  local rewards = Logic.rewardLogic:FormatRewardById(config.rewards)
  return rewards or {}
end

function TeachingLogic:GetMyTeachRewards()
  local res = {}
  local user = Data.userData:GetUserData()
  local merits, pops = user.TeacherMedal, user.TeacherPrestige
  table.insert(res, {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.TEACHINGMERITS,
    Num = merits or 0
  })
  table.insert(res, {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.TEACHINGPOP,
    Num = pops or 0
  })
  return res
end

function TeachingLogic:GetTeachPop()
  return Data.userData:GetUserData().TeacherPrestige or 0
end

function TeachingLogic:GetTeachCareerLv()
  local pop = self:GetTeachPop()
  local configs = self:GetTeacherCareer()
  local len = #configs
  for i = 1, len - 1 do
    if pop >= configs[i].prestige and pop < configs[i + 1].prestige then
      return configs[i].level, configs[i].id
    end
  end
  return configs[len].level, configs[len].id
end

function TeachingLogic:GetTeachCareerMax()
  local configs = TeachingLogic._getTeachingCareerConfig()
  for _, config in pairs(configs) do
    if config.next_id == -1 then
      return config.level
    end
  end
  return 8
end

function TeachingLogic:GetSubLvPt(smallLv, bigLv)
  if bigLv < smallLv then
    return 0
  end
  local maxLv = self:GetTeachCareerMax()
  if bigLv > maxLv then
    return 0
  end
  local smallNum, bigNum = 0, 0
  local configs = TeachingLogic._getTeachingCareerConfig()
  for _, config in pairs(configs) do
    if config.level == smallLv then
      smallNum = config.prestige
    end
    if config.level == bigLv then
      bigNum = config.prestige
    end
  end
  return bigNum - smallNum
end

function TeachingLogic:GetSubNextLvPt(nextLv)
  local pop = self:GetTeachPop()
  local nextNum = 0
  local configs = TeachingLogic._getTeachingCareerConfig()
  for _, config in pairs(configs) do
    if config.level == nextLv then
      nextNum = config.prestige
    end
  end
  return nextNum - pop
end

function TeachingLogic:GetTeacherCareer()
  local res = {}
  local configs = TeachingLogic._getTeachingCareerConfig()
  for _, config in pairs(configs) do
    table.insert(res, config)
  end
  return res
end

function TeachingLogic:GetShowTCareer()
  local res = {}
  local configs = TeachingLogic._getTeachingCareerConfig()
  for id, config in pairs(configs) do
    if id ~= 1 then
      table.insert(res, config)
    end
  end
  return res
end

function TeachingLogic:SortTeacherCareer(career)
  local gotfunc = function(id)
    return self:HaveGetCareerReward(id) and 0 or 1
  end
  local default = function(id)
    return id == 1 and 0 or 1
  end
  local got1, got2, dft1, dft2
  table.sort(career, function(data1, data2)
    got1 = gotfunc(data1.id)
    got2 = gotfunc(data2.id)
    dft1 = default(data1.id)
    dft2 = default(data2.id)
    if dft1 ~= dft2 then
      return dft1 > dft2
    elseif got1 ~= got2 then
      return got1 > got2
    else
      return data1.level < data2.level
    end
  end)
  return career
end

function TeachingLogic:HaveGetCareerReward(id)
  local data = Data.taskData:GetTeachPtRewardMap()
  return data[id] ~= nil
end

function TeachingLogic:CanGetCareerRewardById(id)
  local _, curId = self:GetTeachCareerLv()
  return not self:HaveGetCareerReward(id) and id <= curId
end

function TeachingLogic:GetTeacherList()
  return Data.teachingData:GetRanks()
end

function TeachingLogic:GetRequestList()
  local info = {}
  if self.m_applyLock then
    info = Data.teachingData:GetApplyDetails()
  else
    Service.teachingService:GetApplyList()
    self.m_applyLock = true
  end
  return info
end

function TeachingLogic:CheckInSearchCD()
  local min = self:GetChangeDown()
  local cd = time.getSvrTime() - self.m_showContent.SearchTime
  if min > cd then
    return true, string.format("%d\231\167\146\229\144\142\229\134\141\230\172\161\232\191\155\232\161\140\230\144\156\231\180\162", min - cd)
  end
  return false
end

function TeachingLogic:GetRankRefreshRemain()
  local _, endTime = PeriodManager:GetStartAndEndPeriodTime(108)
  local delta = endTime - time.getSvrTime()
  return 0 < delta and delta or 0
end

function TeachingLogic:CheckIsTeacher(userLv)
  userLv = userLv or Data.userData:GetUserLevel()
  return userLv > self:GetStudentLvUp()
end

function TeachingLogic:IsMyTeacher(uid)
  local info = Data.teachingData:GetMyTeacher()[1]
  return info and info.UserInfo.Uid == uid
end

function TeachingLogic:NeedGetRank()
  local last = self.m_showContent.RankUpdateTime
  local delta = self:GetRankUpdateDelta()
  return delta < time.getSvrTime() - last
end

function TeachingLogic:NeedGetTeach(isTeacher)
  local delta = self:GetRankUpdateDelta()
  local last
  if isTeacher then
    last = self.m_showContent.TeachUpdateTime
  else
    last = self.m_showContent.StudyUpdateTime
  end
  return delta < time.getSvrTime() - last
end

function TeachingLogic:MyPosInRank()
  local uid = Data.userData:GetUserUid()
  local ranks = Data.teachingData:GetRanks()
  for i, user in ipairs(ranks) do
    if uid == user.Uid then
      return i
    end
  end
  return 0
end

function TeachingLogic:CheckGetDataCondition(userLv)
  userLv = userLv or Data.userData:GetUserLevel()
  return userLv >= self:GetStudentLvDown()
end

function TeachingLogic:Score2Star(score)
  local configs = self:GetScoreStarConvertConfig()
  local len = #configs
  if score >= self:GetFullStarConfig() then
    return len, 0
  end
  for i = len, 2, -1 do
    if score <= configs[i] and score > configs[i - 1] then
      local remain = (score - configs[i - 1]) / (configs[i] - configs[i - 1])
      return i, remain
    end
  end
  return 1, score / configs[1]
end

function TeachingLogic:GetFullStarConfig()
  return 90000
end

function TeachingLogic:GetRewardFactor(usrLv, stage)
  usrLv = usrLv or Data.userData:GetUserLevel()
  stage = stage or self:GetExamStage()
  local stageLv = self:GetExamConfig(stage).level
  local delta = usrLv - stageLv
  local configs = configManager.GetData("config_teaching_assess")
  local min = 1000000
  for id, config in pairs(configs) do
    if id < min then
      min = id
    end
    if delta >= config.range[1] and delta <= config.range[2] then
      return config
    end
  end
  return configs[min]
end

function TeachingLogic:CanShowEva(curNum)
  curNum = curNum or 0
  local down = self:GetShowEvaNumDown()
  return curNum > down
end

function TeachingLogic:GetSelfInfo()
  local data = Data.teachingData:GetData()
  if data.Sign == nil or data.Sign == "" then
    data.Sign = self:GetDefaultSignStr()
  end
  return {
    [ETeachingIntroGroupId.SEX] = data.Sex or 0,
    [ETeachingIntroGroupId.TIME] = data.Active or 0,
    [ETeachingIntroGroupId.ATTR] = data.Interest or 0,
    Sign = data.Sign
  }
end

function TeachingLogic:RequesetStudyWrap(teachInfo)
  local ok, err = self:ChechRequestStudy(teachInfo)
  if not ok then
    noticeManager:ShowTip(err)
    return
  end
  Service.teachingService:SendTeachingApply({
    applyUid = teachInfo.UserInfo.Uid
  })
end

function TeachingLogic:RStudyBaseWrap(user)
  local ok, err = self:ChechRequestStudyBase(user)
  if not ok then
    noticeManager:ShowTip(err)
    return
  end
  Service.teachingService:SendTeachingApply({
    applyUid = user.Uid
  })
end

function TeachingLogic:RecruitStudentWrap(teachInfo)
  local ok, err = self:CheckRecruitStudent(teachInfo)
  if not ok then
    noticeManager:ShowTip(err)
    return
  end
  Service.teachingService:SendTeachingApply({
    applyUid = teachInfo.UserInfo.Uid
  })
end

function TeachingLogic:RTeachBaseWrap(user)
  local ok, err = self:CheckRecruitStudentBase(user)
  if not ok then
    noticeManager:ShowTip(err)
    return
  end
  Service.teachingService:SendTeachingApply({
    applyUid = user.Uid
  })
end

function TeachingLogic:RequesetAddGuildWrap(guildId)
  if not moduleManager:CheckFunc(FunctionID.Guild, true) then
    noticeManager:ShowTip(string.format(UIHelper.GetString(210024), "\229\133\172\228\188\154"))
    return
  end
  if Data.guildData:inGuild() then
    noticeManager:ShowTip(UIHelper.GetString(2200081))
    return
  end
  local can, dictId = Data.guildData:canApply()
  if not can then
    noticeManager:ShowTipById(dictId)
    return
  end
  Service.guildService:SendApply({GuildId = guildId})
end

function TeachingLogic:AddFriendWrap(info)
  logError(info)
  local uid = info.Uid
  local mid = Data.userData:GetUserUid()
  if uid == mid then
    noticeManager:ShowTip("\228\184\141\232\131\189\230\183\187\229\138\160\232\135\170\229\183\177\228\184\186\229\165\189\229\143\139")
    return
  end
  if not moduleManager:CheckFunc(FunctionID.Friend, true) then
    noticeManager:ShowTip("\229\165\189\229\143\139\229\138\159\232\131\189\230\156\170\229\188\128\229\144\175")
    return
  end
  if not info.CanAddFriend then
    noticeManager:ShowTip(UIHelper.GetString(2200088))
    return
  end
  local checkResule = Logic.friendLogic:CheckApplyReq(uid)
  if checkResule then
    noticeManager:OpenTipPage(self, "\229\183\178\230\143\144\228\186\164\232\191\135\231\148\179\232\175\183")
  else
    Logic.friendLogic:ClickApplyLogic(uid, self)
  end
end

function TeachingLogic:ReleaseWrap(param)
  local str = string.format(UIHelper.GetString(2200021), self:DisposeUname(param.UserInfo.Uname))
  local ok, msg = self:CheckRelease(param)
  if not ok then
    noticeManager:ShowTip(msg)
    return
  end
  local needtip = self:_NeedShowCDTip(param)
  local punishTime = self:CheckIsTeacher() and self._getParamConfigById(247) or self._getParamConfigById(248)
  local custom = needtip and string.format(UIHelper.GetString(2200022), punishTime) or string.format(UIHelper.GetString(2200061), self._getParamConfigById(249))
  local DeleteFun = function()
    Service.teachingService:SendTeachingDelete({
      applyUid = param.UserInfo.Uid
    })
  end
  noticeManager:ShowSuperNotice(str, "", false, false, DeleteFun, nil, nil, nil, "\232\167\163\233\153\164\230\137\167\230\149\153\229\133\179\231\179\187", custom)
end

function TeachingLogic:_NeedShowCDTip(param)
  local cdup = self:GetPunishTimeUp()
  return cdup >= param.UserInfo.OfflineTime
end

function TeachingLogic:ChatWrap(userInfo)
  local uid = Data.userData:GetUserUid()
  if uid == userInfo.Uid then
    noticeManager:ShowTip("\228\184\141\232\131\189\229\146\140\232\135\170\229\183\177\232\129\138\229\164\169")
    return
  end
  if Logic.friendLogic:IsMyFriend(userInfo.Uid) then
    Data.chatData:SetChatChannel(ChatChannel.Friend)
  else
    Data.chatData:SetChatChannel(ChatChannel.Personal)
  end
  if Data.chatData:GetChatOpen() then
    eventManager:SendEvent(LuaEvent.SwitchChatChannel, userInfo)
  else
    userInfo.Uname = self:DisposeUname(userInfo.Uname)
    UIHelper.OpenPage("ChatPage", userInfo)
  end
end

function TeachingLogic:AcceptWrap(data)
  local isTeacher = self:CheckIsTeacher()
  local info = self:GetLocalTeachInfo(isTeacher)
  if isTeacher then
    if self:CheckIsTeacher(data.UserInfo.Level) then
      noticeManager:ShowTip("\232\175\165\231\142\169\229\174\182\229\183\178\232\182\133\229\135\186\229\173\166\229\145\152\231\173\137\231\186\167")
      return
    end
    local curMax = self:GetTeachingNumUp()
    local student = self:GetCurStudentNum()
    if curMax <= student then
      noticeManager:ShowTip(UIHelper.GetString(2200014))
      return
    end
    local monthMax = self:GetRecruitNumUp()
    local curmonthMax = Data.teachingData:GetData().GotStuCount or 0
    if monthMax <= curmonthMax then
      noticeManager:ShowTip("\230\130\168\229\183\178\232\182\133\229\135\186\230\175\143\230\156\136\229\143\175\230\137\167\230\149\153\228\184\138\233\153\144")
      return
    end
  else
    if not self:CheckIsTeacher(data.UserInfo.Level) then
      noticeManager:ShowTip("\232\175\165\231\142\169\229\174\182\231\173\137\231\186\167\229\164\170\228\189\142 \228\184\141\232\131\189\229\129\154\229\175\188\229\184\136")
      return
    end
    local data = Data.teachingData:GetData()
    local lv = Data.userData:GetUserLevel()
    if self:HaveFinish(data, lv) then
      noticeManager:ShowTip(UIHelper.GetString(2200086))
      return
    end
    if #info >= HaveTeacherMax then
      noticeManager:ShowTip(UIHelper.GetString(2200012))
      return
    end
  end
  Service.teachingService:SendTeachingAgree({
    applyUid = data.Uid
  })
end

function TeachingLogic:RefuseWrap(uid)
  Service.teachingService:SendTeachingRefuse({applyUid = uid})
end

function TeachingLogic:CheckShowApplyStudy(user)
  local uteacher = self:CheckIsTeacher(user.Level)
  local mcheck = self:ChechRequestStudyBase(user)
  local mteacher = self:CheckIsTeacher()
  local info = self:GetLocalTeachInfo(mteacher)
  return uteacher and mcheck and next(info) == nil
end

function TeachingLogic:CheckShowRecruitNew(user)
  local uteacher = self:CheckIsTeacher(user.Level)
  local mcheck = self:CheckRecruitStudentBase(user)
  local mteacher = self:CheckIsTeacher()
  local max = self:GetTeachingNumUp()
  local student = self:GetCurStudentNum()
  return not uteacher and mcheck and max > student
end

function TeachingLogic:GetTeacherRewards()
  local isTeacher = self:CheckIsTeacher()
  if not isTeacher then
    local teacher = Data.teachingData:GetMyTeacher()[1]
    if teacher then
      local res = {}
      local merits, pops = teacher.UserInfo.TeacherMedal, teacher.UserInfo.TeacherPrestige
      table.insert(res, {
        Type = GoodsType.CURRENCY,
        ConfigId = CurrencyType.TEACHINGMERITS,
        Num = merits or 0
      })
      table.insert(res, {
        Type = GoodsType.CURRENCY,
        ConfigId = CurrencyType.TEACHINGPOP,
        Num = pops or 0
      })
      return res
    else
      return nil
    end
  else
    return nil
  end
end

function TeachingLogic:GetStudentRewards(uid)
  local isTeacher = self:CheckIsTeacher()
  if isTeacher then
    local teacher = Data.teachingData:GetStudentById(uid)
    if teacher then
      local res = {}
      local merits, pops = teacher.UserInfo.TeacherMedal, teacher.UserInfo.TeacherPrestige
      table.insert(res, {
        Type = GoodsType.CURRENCY,
        ConfigId = CurrencyType.TEACHINGMERITS,
        Num = merits or 0
      })
      table.insert(res, {
        Type = GoodsType.CURRENCY,
        ConfigId = CurrencyType.TEACHINGPOP,
        Num = pops or 0
      })
      return res
    else
      return nil
    end
  else
    return nil
  end
end

function TeachingLogic:GetUserStatus(offline)
  local res
  if offline == 0 then
    res = "\229\156\168\231\186\191"
  else
    local time = 0
    local dayline = self:_GetDayLine()
    if offline <= 3600 then
      time = offline / 60 - offline / 60 % 1 + 1
      res = string.format("%s\229\136\134\233\146\159\229\137\141", math.tointeger(time))
    elseif 3600 < offline and offline < dayline then
      time = offline / 3600 - offline / 3600 % 1 + 1
      res = string.format("%s\229\176\143\230\151\182\229\137\141", math.tointeger(time))
    elseif offline >= dayline then
      time = offline / 86400 - offline / 86400 % 1 + 1
      res = string.format("%s\229\164\169\229\137\141", math.tointeger(time))
    end
  end
  return res
end

function TeachingLogic:_GetDayLine()
  return self:GetPunishTimeUp()
end

function TeachingLogic:GetCurStudentNum()
  local student = self:GetLocalTeachInfo(true)
  local count = 0
  for _, teach in pairs(student) do
    if not self:HaveFinishByMyS(teach) then
      count = count + 1
    end
  end
  return count
end

function TeachingLogic:HaveFinishByMyS(teach)
  return teach.CreateTime == 0 or teach.UserInfo.Level > self:GetStudentLvUp()
end

function TeachingLogic:HaveFinish(teach, lv)
  return teach.GraduationTime > 0 or lv > self:GetStudentLvUp()
end

function TeachingLogic:CheckRelease(param)
  local down = self:GetReleaseDownTime()
  local data = Data.teachingData:GetData()
  local last = param.CreateTime
  local name = self:DisposeUname(param.UserInfo.Uname)
  if down > time.getSvrTime() - last then
    return false, string.format(UIHelper.GetString(2200023), name)
  end
  local isteacher = self:CheckIsTeacher()
  local teacherData = self:GetLocalTeachInfo(isteacher)
  local bStudent = false
  if teacherData then
    for _, info in ipairs(teacherData) do
      if not isteacher then
        if info.UserInfo.Uid ~= param.UserInfo.Uid then
          return false, "\232\175\165\231\142\169\229\174\182\228\184\141\230\152\175\228\189\160\231\154\132\229\175\188\229\184\136 \230\151\160\230\179\149\232\167\163\233\153\164\229\133\179\231\179\187"
        end
      elseif info.UserInfo.Uid == param.UserInfo.Uid then
        bStudent = true
        break
      end
    end
    if isteacher and not bStudent then
      return false, "\232\175\165\231\142\169\229\174\182\228\184\141\230\152\175\228\189\160\231\154\132\229\173\166\229\145\152 \230\151\160\230\179\149\232\167\163\233\153\164\229\133\179\231\179\187"
    end
  end
  return true, ""
end

function TeachingLogic:CheckFindTeacher()
  if self:TeachFinish() then
    return false, UIHelper.GetString(2200086)
  end
  local isTeacher = self:CheckIsTeacher()
  if isTeacher then
    return false, "\231\173\137\231\186\167\229\164\170\233\171\152 \228\184\141\232\131\189\229\129\154\229\173\166\229\145\152"
  end
  local teacher = self:GetLocalTeachInfo(isTeacher)
  if next(teacher) ~= nil then
    return false, UIHelper.GetString(2200012)
  end
  return true, ""
end

function TeachingLogic:CheckFindStudent()
  local isTeacher = self:CheckIsTeacher()
  if not isTeacher then
    return false, "\231\173\137\231\186\167\229\164\170\228\189\142 \228\184\141\232\131\189\229\129\154\229\175\188\229\184\136"
  end
  local monthMax = self:GetRecruitNumUp()
  local curMax = self:GetTeachingNumUp()
  local student = self:GetCurStudentNum()
  if curMax <= student then
    return false, UIHelper.GetString(2200014)
  end
  local curmonthMax = Data.teachingData:GetData().GotStuCount or 0
  if monthMax <= curmonthMax then
    return false, "\232\182\133\229\135\186\230\175\143\230\156\136\229\143\175\230\137\167\230\149\153\228\184\138\233\153\144"
  end
  return true, ""
end

function TeachingLogic:ChechRequestStudy(teachInfo)
  local ok, msg = self:ChechRequestStudyBase(teachInfo.UserInfo)
  if not ok then
    return ok, msg
  end
  local last = teachInfo.PunishTime
  if last > time.getSvrTime() then
    return false, UIHelper.GetString(2200080)
  end
  local data = Data.teachingData:GetData().ApplyInfo or {}
  local applyMax = self:GetRequestNumUp()
  if applyMax < #data then
    return false, "\230\130\168\231\154\132\231\148\179\232\175\183\229\136\151\232\161\168\229\183\178\230\187\161 \230\151\160\230\179\149\229\133\165\229\173\166"
  end
  local monthMax = self:GetRecruitNumUp()
  local curMax = self:GetTeachingNumUp()
  local curmonthMax = teachInfo.GotStuCount or 0
  if monthMax <= curmonthMax then
    return false, "\229\175\185\230\150\185\232\182\133\229\135\186\230\175\143\230\156\136\229\143\175\230\137\167\230\149\153\228\184\138\233\153\144"
  end
  return true, ""
end

function TeachingLogic:ChechRequestStudyBase(userInfo)
  local mid = Data.userData:GetUserUid()
  if mid == userInfo.Uid then
    return false, "\228\184\141\232\131\189\229\129\154\232\135\170\229\183\177\231\154\132\229\173\166\231\148\159"
  end
  local lv = Data.userData:GetUserLevel()
  local state = self:GetUserCanTeachState(lv)
  if state ~= ETeachingState.STUDENT then
    return false, "\229\189\147\229\137\141\231\173\137\231\186\167\228\184\139 \230\130\168\228\184\141\232\131\189\229\129\154\229\173\166\229\145\152"
  end
  isTeacher = self:CheckIsTeacher(userInfo.Level)
  if not isTeacher then
    return false, string.format(UIHelper.GetString(2200016), self:DisposeUname(userInfo.Uname))
  end
  local teacher = self:GetLocalTeachInfo(false)
  if next(teacher) ~= nil then
    return false, "\230\130\168\229\183\178\230\156\137\229\175\188\229\184\136 \228\184\141\232\131\189\229\134\141\230\172\161\231\148\179\232\175\183\229\133\165\229\173\166"
  end
  local data = Data.teachingData:GetData()
  if self:HaveFinish(data, lv) then
    return false, UIHelper.GetString(2200086)
  end
  local last = data.PunishTime or 0
  if last > time.getSvrTime() then
    return false, "\230\130\168\229\156\168\229\134\183\229\141\180\230\151\182\233\151\180\229\134\133,\228\184\141\232\131\189\229\134\141\230\172\161\231\148\179\232\175\183\229\133\165\229\173\166"
  end
  return true, ""
end

function TeachingLogic:CheckRecruitStudent(teachInfo)
  local ok, msg = self:CheckRecruitStudentBase(teachInfo.UserInfo)
  if not ok then
    return ok, msg
  end
  if self:HaveFinish(teachInfo, teachInfo.UserInfo.Level) then
    return false, "\229\175\185\230\150\185\229\183\178\230\175\149\228\184\154 \228\184\141\232\131\189\231\187\167\231\187\173\229\173\166\228\185\160"
  end
  local last = teachInfo.PunishTime
  if last > time.getSvrTime() then
    return false, UIHelper.GetString(2200073)
  end
  if teachInfo.TeachingStatus ~= ETeachingState.NONE then
    return false, "\229\175\185\230\150\185\229\183\178\231\187\143\230\156\137\229\175\188\229\184\136\228\186\134"
  end
  local applyMax = self:GetRequestNumUp()
  local curApply = teachInfo.ApplyInfo or {}
  if applyMax < #curApply then
    return false, "\229\175\185\230\150\185\231\148\179\232\175\183\229\136\151\232\161\168\229\183\178\230\187\161"
  end
  return true, ""
end

function TeachingLogic:CheckRecruitStudentBase(userInfo)
  local mid = Data.userData:GetUserUid()
  if mid == userInfo.Uid then
    return false, "\228\184\141\232\131\189\229\129\154\232\135\170\229\183\177\231\154\132\229\173\166\229\145\152"
  end
  local isTeacher = self:CheckIsTeacher()
  if not isTeacher then
    return false, "\231\173\137\231\186\167\229\164\170\228\189\142 \228\184\141\232\131\189\229\129\154\229\175\188\229\184\136"
  end
  local name = self:DisposeUname(userInfo.Uname)
  local state = self:GetUserCanTeachState(userInfo.Level)
  if state == ETeachingState.NONE then
    return false, string.format(UIHelper.GetString(2200017), name)
  elseif state == ETeachingState.TEACHER then
    return false, string.format(UIHelper.GetString(2200085), name)
  end
  local last = Data.teachingData:GetData().PunishTime or 0
  if last > time.getSvrTime() then
    return false, "\230\130\168\229\156\168\229\134\183\229\141\180\230\151\182\233\151\180\229\134\133,\228\184\141\232\131\189\229\134\141\230\172\161\230\139\155\230\148\182\229\173\166\229\145\152"
  end
  local monthMax = self:GetRecruitNumUp()
  local curMax = self:GetTeachingNumUp()
  local student = self:GetCurStudentNum()
  if curMax <= student then
    return false, UIHelper.GetString(2200014)
  end
  local curmonthMax = Data.teachingData:GetData().GotStuCount or 0
  if monthMax <= curmonthMax then
    return false, "\230\130\168\229\183\178\232\182\133\229\135\186\230\175\143\230\156\136\229\143\175\230\137\167\230\149\153\228\184\138\233\153\144"
  end
  local applyMax = self:GetRequestNumUp()
  local applys = Data.teachingData:GetData().ApplyInfo or {}
  local curApply = #applys
  if applyMax < curApply then
    return false, "\230\130\168\231\154\132\231\148\179\232\175\183\228\186\186\230\149\176\232\190\190\229\136\176\228\184\138\233\153\144,\230\151\160\230\179\149\231\187\167\231\187\173\230\139\155\230\148\182\229\173\166\229\145\152"
  end
  return true, ""
end

function TeachingLogic:CheckEvalation(uid, star, eva)
  local lv = Data.userData:GetUserLevel()
  if lv > self:GetStudentLvUp() then
    return false, "\232\182\133\229\135\186\229\173\166\229\145\152\231\173\137\231\186\167\232\166\129\230\177\130\228\184\138\233\153\144"
  end
  if not self:IsMyTeacher(uid) then
    return false, "\232\191\153\228\184\141\230\152\175\228\189\160\231\154\132\229\175\188\229\184\136"
  end
  if type(eva) ~= "string" or eve == "" then
    eve = self:GetDefaultEvaluateStr()
  end
  if utf8.len(eva) > self:GetEvaUp() then
    return false, "\232\175\132\228\187\183\229\173\151\230\149\176\232\182\133\229\135\186\228\184\138\233\153\144"
  end
  if star <= 0 or star > self:GetEvaStarMax() then
    star = self:GetDefaultEvaluateStar()
  end
  if not self:IsExamTaskFinish(self:GetExamStage()) then
    return false, "\230\156\170\229\174\140\230\136\144\229\133\168\233\131\168\232\128\131\230\160\184\228\187\187\229\138\161"
  end
  if self:EvaTFinish(self:GetExamStage()) then
    return false, "\232\175\165\232\128\131\230\160\184\228\187\187\229\138\161\233\152\182\230\174\181\229\183\178\232\175\132\228\187\183"
  end
  Service.teachingService:SendTeachingAppraise({
    TeacherUid = uid,
    Star = star,
    Message = eva
  })
  return true, ""
end

TeachingLogic.ENDEXAMID = 108
TeachingLogic.STARTEXAMID = 101

function TeachingLogic:IsExamTaskFinish(stage)
  local tasks = self:GetExamTask()
  tasks = tasks[stage]
  if tasks then
    for _, task in pairs(tasks) do
      if task.Data.FinishTime == 0 then
        return false
      end
    end
    return true
  end
  return false
end

function TeachingLogic:EvaTFinish(stage)
  local maxTaskStage = Logic.teachingLogic:GetExamedMaxStage()
  if stage <= maxTaskStage then
    return true
  end
  return false
end

function TeachingLogic:TeachFinish()
  return self:EvaTFinish(self:_getExamEndStageId())
end

function TeachingLogic:_getExamEndStageId()
  local configs = configManager.GetData("config_task_teaching_group")
  for id, config in pairs(configs) do
    if config.next_group_id < 0 then
      return id
    end
  end
  return TeachingLogic.ENDEXAMID
end

function TeachingLogic:CheckSendIntro(args)
  if type(args.Sign) ~= "string" or args.Sign == "" then
    return false, UIHelper.GetString(2200075)
  end
  if utf8.len(args.Sign) > self:GetSignUp() then
    return false, "\232\182\133\229\135\186\229\173\151\230\149\176\228\184\138\233\153\144"
  end
  local config = self:GetSelfInfoConfig()
  local sex = config[ETeachingIntroGroupId.SEX]
  local time = config[ETeachingIntroGroupId.TIME]
  local attr = config[ETeachingIntroGroupId.ATTR]
  local setAssert = function(args, max)
    return type(args) == "number" and 0 <= args and args <= max
  end
  if not setAssert(args.Sex, #sex) then
    return false, "\232\175\183\232\190\147\229\133\165\230\128\167\229\136\171"
  end
  if not setAssert(args.Active, #time) then
    return false, "\232\175\183\232\190\147\229\133\165\230\180\187\232\183\131\230\151\182\233\151\180"
  end
  if not setAssert(args.Interest, #attr) then
    return false, "\232\175\183\232\190\147\229\133\165\229\133\180\232\182\163"
  end
  Service.teachingService:SendPersonalInfo(args)
  return true, ""
end

function TeachingLogic:CheckGetRank()
  Service.teachingService:GetTeacherRank({
    Begin = 0,
    Offset = self:GetRankNumUp() - 1
  })
  self:SetRankUpdateTime(time.getSvrTime())
  return true, ""
end

function TeachingLogic:CheckGetSTask(userInfo)
  if not self:IsMyStudent(userInfo.Uid) then
    return false, "\232\175\165\231\142\169\229\174\182\228\184\141\230\152\175\228\189\160\231\154\132\229\173\166\229\145\152 \230\151\160\230\179\149\230\159\165\231\156\139\232\128\131\230\160\184\232\191\155\229\186\166"
  end
  return true, ""
end

function TeachingLogic:CheckHaveTeacher()
  local teachData = Data.teachingData:GetData()
  return next(teachData) ~= nil and teachData.TeacherUid ~= 0
end

function TeachingLogic:GetRmdPlayers(isTeacher, record)
  local min = self:GetChangeDown()
  local cd = time.getSvrTime() - self.m_showContent.ChangeUpdateTime
  if min > cd and record then
    return false, nil, string.format(UIHelper.GetString(2200072), min - cd)
  end
  local updateMin = self:GetRecommendCacheTime()
  local updateCD = time.getSvrTime() - self.m_showContent.RecommendUpdatTime
  if updateMin > updateCD then
    return Data.teachingData:GetRmdPlayers(isTeacher)
  else
    return false, nil, nil
  end
end

function TeachingLogic:DisposeUname(uname)
  local name = uname
  if uname ~= nil then
    local nameTab = string.split(uname, ".")
    name = nameTab[1]
  end
  return name
end

function TeachingLogic:CanEvaTeacher()
  if self:OpenedTeachingSystem() then
    return false
  end
  if self:CheckIsTeacher() then
    return false
  end
  if not self:CheckHaveTeacher() then
    return false
  end
  local taskFinish = self:IsExamTaskFinish(self:GetExamStage())
  local evaTFinish = self:EvaTFinish(self:GetExamStage())
  return taskFinish and not evaTFinish
end

function TeachingLogic:CanGetDailyTaskReward()
  if self:OpenedTeachingSystem() then
    return false
  end
  if self:CheckIsTeacher() then
    return false
  end
  if not self:CheckHaveTeacher() then
    return false
  end
  local tasks = self:GetDailyTask()
  if tasks == nil or next(tasks) == nil then
    return false
  end
  for _, task in ipairs(tasks) do
    if task.Data.FinishTime > 0 and task.Data.RewardTime == 0 then
      return true
    end
  end
  return false
end

function TeachingLogic:GetApplyInfo()
  if self:OpenedTeachingSystem() then
    return false
  end
  local teachingData = Data.teachingData:GetData()
  if next(teachingData) == nil then
    return false
  end
  local applyInfo = teachingData.ApplyInfo
  return applyInfo ~= nil and 0 < #applyInfo
end

function TeachingLogic:CanGetCareerReward()
  if self:OpenedTeachingSystem() then
    return false
  end
  local _, curId = self:GetTeachCareerLv()
  local configs = TeachingLogic._getTeachingCareerConfig()
  for id, config in pairs(configs) do
    if id <= curId and config.rewards > 0 and not self:HaveGetCareerReward(id) then
      return true
    end
  end
  return false
end

function TeachingLogic:OpenedTeachingSystem()
  local userData = Data.userData:GetUserData()
  local isOpen = moduleManager:CheckFunc(FunctionID.Teaching, false)
  local opened = PlayerPrefs.GetBool("OpenedTeachingSystem" .. userData.Uid, false)
  return isOpen and not opened
end

return TeachingLogic
