local SyncJsonService = class("servic.SyncJsonService", Service.BaseService)

function SyncJsonService:initialize()
  self:_InitHandlers()
end

function SyncJsonService:_InitHandlers()
  self:BindEvent("syncJson.GetSyncJson", self._GetSyncJson, self)
end

function SyncJsonService:_GetSyncJson(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetSyncJson failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, syncjson_pb.TSYNCJSON)
    Data.syncJsonData:SetData(info)
  end
end

return SyncJsonService
