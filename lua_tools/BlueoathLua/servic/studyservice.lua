local StudyService = class("servic.StudyService", Service.BaseService)
require("net.protobuflua.module_pb")
require("net.protobuflua.study_pb")

function StudyService:initialize()
  self:_InitHandlers()
  self.temp = {}
end

function StudyService:_InitHandlers()
  self:BindEvent("study.StartStudyPSkill", self._ReceiveStartStudy, self)
  self:BindEvent("study.GetStudyInfo", self._ReceiveGetStudyInfo, self)
  self:BindEvent("study.CancelStudyPSkill", self._ReceiveCancelStudy, self)
  self:BindEvent("study.EndStudyPSkill", self._ReceiveStopStudy, self)
  self:BindEvent("study.SpeedUpStudy", self._FinishSpeedUp, self)
end

function StudyService:SendSpeedUp(heroId, pskillId, items)
  local args = {
    HeroId = heroId,
    PSkillId = pskillId,
    arrItem = items
  }
  args = dataChangeManager:LuaToPb(args, study_pb.TSPEEDUPSTUDYARG)
  self:SendNetEvent("study.SpeedUpStudy", args)
end

function StudyService:_FinishSpeedUp(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_FinishSpeedUp err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local data = dataChangeManager:PbToLua(ret, study_pb.TSTUDYINFO)
    Data.studyData:SetData(data)
    self:SendLuaEvent(LuaEvent.StudyUpSuccess)
  end
end

function StudyService:SendGetStudyInfo()
  local args = {}
  args = dataChangeManager:LuaToPb(args, module_pb.TEMPTYARG)
  self:SendNetEvent("study.GetStudyInfo", args)
end

function StudyService:_ReceiveGetStudyInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError(err)
    return
  else
    self:SendLuaEvent(LuaEvent.GetStudyInfo, dataChangeManager:PbToLua(ret, study_pb.TSTUDYINFO))
  end
end

function StudyService:SendStartStudy(heroId, pskillId, textbookId)
  local args = {
    HeroId = heroId,
    PSkillId = pskillId,
    TextbookId = textbookId
  }
  args = dataChangeManager:LuaToPb(args, study_pb.TSTARTSTUDYARG)
  self:SendNetEvent("study.StartStudyPSkill", args)
  self.temp.startStudyInfo = {
    HeroId = heroId,
    PSkillId = pskillId,
    TextbookId = textbookId,
    BeginTime = 0
  }
end

function StudyService:_ReceiveStartStudy(ret, state, err, errmsg)
  if err ~= 0 then
    logError(err)
    return
  end
  local info = self.temp.startStudyInfo
  info.BeginTime = time.getSvrTime()
  Data.studyData:AddDataManual(info)
  self:SendLuaEvent(LuaEvent.StartStudy, info)
end

function StudyService:SendCancelStudy(heroId)
  local args = {HeroId = heroId}
  self.temp.cancelHeroId = heroId
  args = dataChangeManager:LuaToPb(args, study_pb.TSTOPSTUDYPSKILLARG)
  self:SendNetEvent("study.CancelStudyPSkill", args)
end

function StudyService:_ReceiveCancelStudy(ret, state, err, errmsg)
  if err ~= 0 then
    logError(err)
    return
  end
  local cancelHeroId = self.temp.cancelHeroId
  Data.studyData:RemoveDataByHeroId(cancelHeroId)
  self:SendLuaEvent(LuaEvent.CancelStudy, cancelHeroId)
end

function StudyService:SendStopStudy(heroId)
  local args = {HeroId = heroId}
  args = dataChangeManager:LuaToPb(args, study_pb.TSTOPSTUDYPSKILLARG)
  self:SendNetEvent("study.EndStudyPSkill", args)
end

function StudyService:_ReceiveStopStudy(ret, state, err, errmsg)
  if err ~= 0 then
    logError(err)
    return
  else
    local data = dataChangeManager:PbToLua(ret, study_pb.TSTOPSTUDYPSKILLRET)
    self:SendLuaEvent(LuaEvent.FinishStudy, data)
  end
end

function StudyService:TestStudy()
  coroutine.start(function()
    self:SendGetStudyInfo()
    coroutine.wait(1)
    self:SendStartStudy(1, 1, 1)
    coroutine.wait(1)
    self:SendGetStudyInfo()
    coroutine.wait(1)
    self:SendCancelStudy(1)
    coroutine.wait(1)
    self:SendGetStudyInfo()
  end)
end

return StudyService
