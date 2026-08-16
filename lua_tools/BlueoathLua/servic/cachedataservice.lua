local CacheDataService = class("servic.CacheDataService", Service.BaseService)

function CacheDataService:initialize()
  self:_InitHandlers()
  self.lastModuleName = ""
  self.lastCacheId = ""
end

function CacheDataService:_InitHandlers()
  self:BindEvent("cachedata.CacheData", self._CacheDataRet, self)
end

function CacheDataService:IsLocalCacheId()
  return tonumber(configManager.GetDataById("config_battle_config", 285).data) == 1
end

function CacheDataService:GenCacheId(moduleName)
  if moduleName ~= self.lastModuleName then
    local now = os.time()
    self.lastCacheId = tostring(now)
    self.lastModuleName = moduleName
  end
  return self.lastCacheId
end

function CacheDataService:ClearLocalCacheId()
  self.lastCacheId = ""
  self.lastModuleName = ""
  logWarning("clear cacheId locally ")
end

function CacheDataService:SendCacheData(info, moduleName)
  if self.IsLocalCacheId() and info == "copy.StartBase" then
    local cacheId = self:GenCacheId(moduleName)
    logWarning("gen cacheId locally ", cacheId)
    self:SendLuaEvent(LuaEvent.CacheDataRet, cacheId)
    return
  end
  local arg = {Key = info}
  arg = dataChangeManager:LuaToPb(arg, cachedata_pb.TCACHEDATAARG)
  self:SendNetEvent("cachedata.CacheData", arg)
end

function CacheDataService:_CacheDataRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("CacheDataRet failed: " .. err)
  else
    local info = dataChangeManager:PbToLua(ret, cachedata_pb.TCACHEDATARET)
    self:SendLuaEvent(LuaEvent.CacheDataRet, info.Ret)
  end
end

return CacheDataService
