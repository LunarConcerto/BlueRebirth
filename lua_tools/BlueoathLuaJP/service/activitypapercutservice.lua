local ActivityPaperCutService = class("service.ActivityPaperCutService", Service.BaseService)

function ActivityPaperCutService:initialize()
  self:_InitHandlers()
end

function ActivityPaperCutService:_InitHandlers()
  self:BindEvent("activitypapercut.MakePaperCut", self._ReceiveMakePaperCut, self)
  self:BindEvent("activitypapercut.UpdateActivityPaperCutInfo", self._ReceiveUpdateActivityPaperCutInfo, self)
end

function ActivityPaperCutService:checkErr(name, err, errmsg, callback)
  logDebug("on ", name, err, errmsg)
  if err ~= 0 then
    if 0 < err then
      local str = UIHelper.GetString(err)
      noticeManager:ShowTip(str)
    end
    if err < 0 then
      logError(name .. " error", tostring(errmsg))
      return true
    end
    if callback ~= nil then
      callback()
    end
    return true
  end
  return false
end

function ActivityPaperCutService:SendMakePaperCut(arg)
  local data = {}
  data.Materials = arg.Materials
  local msg = dataChangeManager:LuaToPb(data, activitypapercut_pb.TAPCMAKEPAPERCUTARG)
  self:SendNetEvent("activitypapercut.MakePaperCut", msg, arg)
end

function ActivityPaperCutService:_ReceiveMakePaperCut(ret, state, err, errmsg)
  if self:checkErr("_ReceiveMakePaperCut", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, activitypapercut_pb.TAPCMAKEPAPERCUTRET)
  eventManager:SendEvent(LuaEvent.ActivityPaperCut_MakePaperCut, data)
end

function ActivityPaperCutService:_ReceiveUpdateActivityPaperCutInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateActivityPaperCutInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, activitypapercut_pb.TACTIVITYPAPERCUTINFORET)
  Data.activitypapercutData:UpdateData(data)
  eventManager:SendEvent(LuaEvent.ActivityPaperCut_RefreshData)
end

return ActivityPaperCutService
