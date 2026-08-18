local BuildService = class("servic.BuildService", Service.BaseService)

function BuildService:initialize()
  self:_InitHandlers()
end

function BuildService:_InitHandlers()
  self:BindEvent("build.BuildingByFormula", self._GetBuildingByFormula, self)
  self:BindEvent("build.BuildsInfo", self._GetBuildGirlInfo, self)
  self:BindEvent("build.BuildReceive", self._GetBuildReceive, self)
  self:BindEvent("build.BuildQuicklyFinish", self._GetQuicklyFinish, self)
  self:BindEvent("buildnotes.GetNotesList", self._GetNotesList, self)
  self:BindEvent("buildnotes.GiveLike", self._GetNotesList, self)
end

function BuildService:SendBuildGirlInfo()
  self:SendNetEvent("build.BuildsInfo")
end

function BuildService:_GetBuildGirlInfo(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, build_pb.TBUILDSINFORET)
      Data.buildData:SetData(info)
      self:SendLuaEvent(LuaEvent.UpadateBuildGirlData, err)
      if Logic.loginLogic:GetLoginOK() == true then
        local noticeParam = Logic.buildLogic:GetPushNoticeParams(info)
        self:SendLuaEvent(LuaEvent.PushNotice, noticeParam)
      end
    end
  else
    logError("BuildGirlInfo err" .. errmsg)
  end
end

function BuildService:SendBuildingByFormula(arg)
  local args = {
    Project = arg.Project
  }
  args = dataChangeManager:LuaToPb(args, build_pb.TBUILDPROJECTSARG)
  self:SendNetEvent("build.BuildingByFormula", args, args)
end

function BuildService:_GetBuildingByFormula(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.GetBuildingByFormula, err)
  else
    logError("BuildingByFormula err" .. err)
  end
end

function BuildService:SendBuildReceive(arg, girlData)
  local args = {
    index = {arg}
  }
  args = dataChangeManager:LuaToPb(args, build_pb.TBUILDINDEXARG)
  self:SendNetEvent("build.BuildReceive", args, girlData)
end

function BuildService:_GetBuildReceive(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, build_pb.TBUILDRECEIVERET)
    local args = {info = info, state = state}
    self:SendLuaEvent(LuaEvent.GetBuildShipId, args)
  else
    logError("BuildReceive err" .. err)
  end
end

function BuildService:SendBuildIndex(arg)
  local args = {
    index = {arg}
  }
  args = dataChangeManager:LuaToPb(args, build_pb.TBUILDINDEXARG)
  self:SendNetEvent("build.BuildQuicklyFinish", args)
end

function BuildService:_GetQuicklyFinish(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.GetQuicklyFinish, err)
  else
    logError("BuildQuicklyFinish err" .. err)
  end
end

function BuildService:SendBuildNotesInfo()
  self:SendNetEvent("buildnotes.GetNotesList")
end

function BuildService:_GetNotesList(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local info = dataChangeManager:PbToLua(ret, notes_pb.TNOTESLISTRET)
      Data.buildData:SetNotesData(info)
      self:SendLuaEvent(LuaEvent.UpdateNotesInfo)
    end
  else
    logError("buildnotes err" .. errmsg)
  end
end

function BuildService:SendBuildHeroLike(args)
  local args = {Htid = args}
  args = dataChangeManager:LuaToPb(args, notes_pb.TNOTESHEROLIKEARG)
  self:SendNetEvent("buildnotes.GiveLike", args)
end

return BuildService
