local AssistNewService = class("service.AssistNewService", Service.BaseService)

function AssistNewService:initialize()
  self:BindEvent("supportfleet.SupportFleetInfo", self._OnGetSupportInfo, self)
  self:BindEvent("supportfleet.StartSupport", self._OnStartSupport, self)
  self:BindEvent("supportfleet.CompleteSupport", self._OnCompleteSupport, self)
  self:BindEvent("supportfleet.CancelSupport", self._OnCancelSupport, self)
end

function AssistNewService:_OnGetSupportInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get support info err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, supportfleet_pb.TSUPPORTFLEETINFO)
    Data.assistNewData:SetAssistData(args.SupportFleetList)
    self:SendLuaEvent(LuaEvent.UpdateAssistList, nil)
    if Logic.loginLogic:GetLoginOK() == true then
      local noticeParam = Logic.assistNewLogic:GetPushNoticeParams(args.SupportFleetList)
      self:SendLuaEvent(LuaEvent.PushNotice, noticeParam)
    end
  end
end

function AssistNewService:_OnStartSupport(ret, state, err, errmsg)
  if err ~= 0 then
    logError("start support err:" .. errmsg)
    return
  end
  self:SendLuaEvent(LuaEvent.StartSupport)
end

function AssistNewService:_OnCompleteSupport(ret, state, err, errmsg)
  if err ~= 0 then
    logError("complete support err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, supportfleet_pb.TCOMPLETESUPPORTRET)
    args.Id = state
    self:SendLuaEvent(LuaEvent.CompleteCrusade, args)
  end
end

function AssistNewService:_OnCancelSupport(ret, state, err, errmsg)
  if err ~= 0 then
    logError("cancel support err:" .. errmsg)
    return
  else
    Logic.assistNewLogic:ResetAssistDataById(state)
    self:SendLuaEvent(LuaEvent.CancelCrusade)
  end
end

function AssistNewService:SendAssistStart(supportId, heroList)
  local args = {SupportId = supportId, HeroList = heroList}
  args = dataChangeManager:LuaToPb(args, supportfleet_pb.TSTARTSUPPORTARG)
  self:SendNetEvent("supportfleet.StartSupport", args)
end

function AssistNewService:SendAssistFinish(id, type)
  local args = {Id = id, Type = type}
  args = dataChangeManager:LuaToPb(args, supportfleet_pb.TCOMPLETESUPPORTARG)
  self:SendNetEvent("supportfleet.CompleteSupport", args, id)
end

function AssistNewService:SendAssistCancel(id, type)
  local args = {Id = id, Type = type}
  args = dataChangeManager:LuaToPb(args, supportfleet_pb.TCOMPLETESUPPORTARG)
  self:SendNetEvent("supportfleet.CancelSupport", args, id)
end

return AssistNewService
