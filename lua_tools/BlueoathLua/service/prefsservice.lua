local PrefsService = class("service.PrefsService", Service.BaseService)

function PrefsService:initialize()
  self:_InitHandlers()
end

function PrefsService:_InitHandlers()
  self:BindEvent("prefs.SavePrefs", self._ReceiveSavePrefs, self)
  self:BindEvent("prefs.UpdatePrefsInfo", self._ReceiveUpdatePrefsInfo, self)
end

function PrefsService:checkErr(name, err, errmsg, callback)
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

function PrefsService:SendSavePrefs(arg)
  local data = {}
  data.PrefsDataStr = arg.PrefsDataStr
  local msg = dataChangeManager:LuaToPb(data, prefs_pb.TSAVEPREFSARG)
  self:SendNetEvent("prefs.SavePrefs", msg, arg)
end

function PrefsService:_ReceiveSavePrefs(ret, state, err, errmsg)
  if self:checkErr("_ReceiveSavePrefs", err, errmsg) then
    return
  end
end

function PrefsService:_ReceiveUpdatePrefsInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdatePrefsInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, prefs_pb.TPREFSRET)
  Data.prefsData:UpdateData(data)
end

return PrefsService
