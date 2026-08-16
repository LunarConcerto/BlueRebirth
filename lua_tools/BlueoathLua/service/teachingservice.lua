local TeachingService = class("service.TeachingService", Service.BaseService)

function TeachingService:initialize()
  self:_InitHandlers()
  self.m_errcodes = nil
end

function TeachingService:_InitHandlers()
  self:BindEvent("teachingsvr.TeachingInfo", self._TeachingInfoRet, self)
  self:BindEvent("teachingsvr.MyTeacher", self._MyTeacherRet, self)
  self:BindEvent("teachingsvr.TeacherList", self._FindTeacherListRet, self)
  self:BindEvent("teachingsvr.Apply", self._ApplyRet, self)
  self:BindEvent("teachingsvr.Agree", self._AgreeRet, self)
  self:BindEvent("teachingsvr.Refuse", self._RefuseRet, self)
  self:BindEvent("teachingsvr.Delete", self._DeleteRet, self)
  self:BindEvent("user.TeacherRank", self._TeacherRankRet, self)
  self:BindEvent("teachingsvr.Appraise", self._AppraiseRet, self)
  self:BindEvent("teachingsvr.MyStudent", self._MyStudentRet, self)
  self:BindEvent("teachingsvr.StudentList", self._FindStudentListRet, self)
  self:BindEvent("teachingsvr.PersonalInfo", self._PersonalInfoRet, self)
  self:BindEvent("teachingsvr.Search", self._SearchRet, self)
  self:BindEvent("teachingsvr.ApplyList", self._ApplyListRet, self)
  self:BindEvent("teachingsvr.GetOtherInfo", self._OnGetOtherInfo, self)
  self:BindEvent("teachingsvr.TaskReward", self._GetDailyReward, self)
end

function TeachingService:_TeachingInfoRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.Search Error:", errmsg, "err: ", err)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGINFO)
    Data.teachingData:SetData(info)
    self:SendLuaEvent(LuaEvent.TeachingUpdateInfo)
  end
end

function TeachingService:GetMyTeacher()
  self:SendNetEvent("teachingsvr.MyTeacher")
end

function TeachingService:_MyTeacherRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.MyTeacher Error:", errmsg, "err: ", err)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGUSERINFO)
    Data.teachingData:SetMyTeacher(info)
    self:SendLuaEvent(LuaEvent.TEACHING_GetTeachOrStudyInfo, true)
  end
end

function TeachingService:FindTeacherList()
  self:SendNetEvent("teachingsvr.TeacherList")
end

function TeachingService:_FindTeacherListRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.TeacherList Error:", errmsg, "err: ", err)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGLISTRET)
    Data.teachingData:SetRmdPlayers(info.UserInfo, true)
    self:SendLuaEvent(LuaEvent.TEACHING_GetRmdPlayers)
  end
end

function TeachingService:SendTeachingApply(param)
  local uid = param.applyUid
  local arg = dataChangeManager:LuaToPb(param, teaching_pb.TTEACHINGAPPLYARG)
  self:SendNetEvent("teachingsvr.Apply", arg, uid)
end

function TeachingService:_ApplyRet(ret, state, err, errmsg)
  if err ~= 0 then
    if not self:_CommonErrHandler(err) then
      logError("teachingsvr.Apply Error:", errmsg, "err: ", err)
    end
    self:SendLuaEvent(LuaEvent.TEACHING_SendApplyErr, err)
  else
    self:SendLuaEvent(LuaEvent.TEACHING_SendApplyOk, state)
  end
end

function TeachingService:_CommonErrHandler(err)
  if self.m_errcodes == nil then
    self.m_errcodes = {
      [ErrorCode.ErrNoUsr] = UIHelper.GetString(210005),
      [ErrorCode.ErrSelfUsr] = "\231\148\168\230\136\183\230\156\172\232\186\171",
      [ErrorCode.ErrHadTeacher] = UIHelper.GetString(2200076),
      [ErrorCode.ErrApplyFull] = UIHelper.GetString(2200077),
      [ErrorCode.ErrStudentFull] = UIHelper.GetString(2200074),
      [ErrorCode.ErrTeachInPunish] = UIHelper.GetString(2200080),
      [ErrorCode.ErrStudentFinish] = UIHelper.GetString(2200079),
      [ErrorCode.ErrTeachApplyFull] = UIHelper.GetString(2200077),
      [ErrorCode.ErrStudentMonthFull] = UIHelper.GetString(2200078),
      [ErrorCode.ErrTeachGraduate] = UIHelper.GetString(2200079),
      [ErrorCode.ErrFunNotOpen] = UIHelper.GetString(110025),
      [ErrorCode.ErrTeachMeInPunish] = UIHelper.GetString(2200083),
      [ErrorCode.ErrAgreeInPunishTime] = UIHelper.GetString(2200087),
      [ErrorCode.ErrSearchName] = UIHelper.GetString(420020)
    }
  end
  if self.m_errcodes[err] then
    noticeManager:ShowTip(self.m_errcodes[err])
    return true
  end
  return false
end

function TeachingService:SendTeachingAgree(param)
  local arg = dataChangeManager:LuaToPb(param, teaching_pb.TTEACHINGAPPLYARG)
  local state = param
  self:SendNetEvent("teachingsvr.Agree", arg, state)
end

function TeachingService:_AgreeRet(ret, state, err, errmsg)
  if err ~= 0 then
    if not self:_CommonErrHandler(err) then
      logError("teachingsvr.Agree Error:", errmsg, "err: ", err)
    end
    self:SendLuaEvent(LuaEvent.TEACHING_AcceptErr, err)
  else
    Data.teachingData:DeleteApplyByUid(state)
    self:SendLuaEvent(LuaEvent.TeachingAgreeApply)
  end
end

function TeachingService:SendTeachingRefuse(param)
  local arg = dataChangeManager:LuaToPb(param, teaching_pb.TTEACHINGAPPLYARG)
  local state = param
  self:SendNetEvent("teachingsvr.Refuse", arg, state)
end

function TeachingService:_RefuseRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.Refuse Error:", errmsg, "err: ", err)
  else
    Data.teachingData:DeleteApplyByUid(state)
    Data.teachingData:DeleteApplyInfoByUid(state)
    self:SendLuaEvent(LuaEvent.TeachingRefuseApply)
  end
end

function TeachingService:SendTeachingDelete(param)
  local arg = dataChangeManager:LuaToPb(param, teaching_pb.TTEACHINGAPPLYARG)
  self:SendNetEvent("teachingsvr.Delete", arg, param.applyUid)
end

function TeachingService:_DeleteRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.Delete Error:", errmsg, "err: ", err)
  else
    self:SendLuaEvent(LuaEvent.TeachingDeleteSucceed, state)
  end
end

function TeachingService:GetTeacherRank(param)
  local args = dataChangeManager:LuaToPb(param, teaching_pb.TTEACHINGRANKARG)
  self:SendNetEvent("user.TeacherRank", args)
end

function TeachingService:_TeacherRankRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.TeacherRank Error:", errmsg, "err: ", err)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGRANKRET)
    Data.teachingData:SetRanks(info.UserInfo)
    self:SendLuaEvent(LuaEvent.TEACHING_GetTeachRank)
  end
end

function TeachingService:SendTeachingAppraise(param)
  local arg = dataChangeManager:LuaToPb(param, teaching_pb.TTEACHINGAPPRAISEARG)
  self:SendNetEvent("teachingsvr.Appraise", arg)
end

function TeachingService:_AppraiseRet(ret, state, err, errmsg)
  if err ~= 0 then
    if not self:_CommonErrHandler(err) then
      self:SendLuaEvent(LuaEvent.TeachingAppraiseErr, err)
    end
  else
    self:SendLuaEvent(LuaEvent.TeachingAppraise)
  end
end

function TeachingService:GetMyStudent()
  self:SendNetEvent("teachingsvr.MyStudent")
end

function TeachingService:_MyStudentRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("teachingsvr.MyStudent Error:", errmsg, "err: ", err)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGLISTRET)
    Data.teachingData:SaveStudents(info.UserInfo)
    self:SendLuaEvent(LuaEvent.TEACHING_GetTeachOrStudyInfo, false)
  end
end

function TeachingService:_FindStudentList(param)
  self:SendNetEvent("teachingsvr.StudentList")
end

function TeachingService:_FindStudentListRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.PersonalInfo Error:", errmsg, "err: ", err)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGLISTRET)
    Data.teachingData:SetRmdPlayers(info.UserInfo, false)
    self:SendLuaEvent(LuaEvent.TEACHING_GetRmdPlayers)
  end
end

function TeachingService:SendPersonalInfo(param)
  local arg = dataChangeManager:LuaToPb(param, teaching_pb.TTEACHINGPERSONALARG)
  self:SendNetEvent("teachingsvr.PersonalInfo", arg)
end

function TeachingService:_PersonalInfoRet(ret, state, err, errmsg)
  if err ~= 0 then
    if err == ErrorCode.ErrChatMask then
      self:SendLuaEvent(LuaEvent.ChatMsgMask)
    elseif not self:_CommonErrHandler(err) then
      logError("teachingsvr.PersonalInfo Error:", errmsg, "err: ", err)
    end
  else
    self:SendLuaEvent(LuaEvent.TEACHING_SetInfoOk)
  end
end

function TeachingService:SendSearch(param)
  local arg = dataChangeManager:LuaToPb(param, teaching_pb.TTEACHINGSEARCHARG)
  self:SendNetEvent("teachingsvr.Search", arg)
end

function TeachingService:_SearchRet(ret, state, err, errmsg)
  if err ~= 0 then
    if not self:_CommonErrHandler(err) then
      logError("teachingsvr.Search Error:", errmsg, "err: ", err)
    end
    self:SendLuaEvent(LuaEvent.TEACHING_GetFindErr, err)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGSEARCHRET)
    self:SendLuaEvent(LuaEvent.TEACHING_GetFindPlayers, info)
  end
end

function TeachingService:GetApplyList()
  self:SendNetEvent("teachingsvr.ApplyList")
end

function TeachingService:_ApplyListRet(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.ApplyList Error:", errmsg, "err: ", err)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGLISTRET)
    Data.teachingData:SetApplyDetails(info.UserInfo)
    self:SendLuaEvent(LuaEvent.TEACHING_GetApplys)
  end
end

function TeachingService:SendGetOtherInfo(uid)
  local args = {Uid = uid}
  args = dataChangeManager:LuaToPb(args, teaching_pb.TTEACHINGGETOTHERINFOARG)
  self:SendNetEvent("teachingsvr.GetOtherInfo", args, uid)
end

function TeachingService:_OnGetOtherInfo(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.get other info err:" .. err .. " errmsg:" .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGOTHERUSERINFO)
    Data.teachingData:SetOtherInfo(state, info)
    self:SendLuaEvent(LuaEvent.TEACHING_GetOtherInfo, state)
  end
end

function TeachingService:SendDailyReward(taskId)
  local args = {TaskId = taskId}
  args = dataChangeManager:LuaToPb(args, teaching_pb.TTEACHINGTASKREWARDARG)
  self:SendNetEvent("teachingsvr.TaskReward", args)
end

function TeachingService:_GetDailyReward(ret, state, err, errmsg)
  if err ~= 0 then
    self:_CommonErrHandler(err)
    logError("teachingsvr.get other info err:" .. err .. " errmsg:" .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, teaching_pb.TTEACHINGTASKREWARDRET)
    self:SendLuaEvent(LuaEvent.TeachingGetDailyReward, info)
  end
end

return TeachingService
