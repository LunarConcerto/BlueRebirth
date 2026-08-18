local JOpenService = class("servic.JOpenService", Service.BaseService)

function JOpenService:initialize()
  self:_InitHandlers()
end

function JOpenService:_InitHandlers()
  self:BindEvent("jopen.GetJopen", self.GetJopen, self)
  self:BindEvent("jopen.FetchHero", self.OnFetchHero, self)
  self:BindEvent("jopen.FetchEquip", self.OnFetchEquip, self)
end

function JOpenService:FetchHero(arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("jopen.FetchHero", arg)
end

function JOpenService:OnFetchHero(ret, state, err, errmsg)
  if err ~= 0 then
    logError("JOpenService OnFetchHero failed " .. errmsg)
  else
    local ret = dataChangeManager:PbToLua(ret, task_pb.TTASKREWARDRET)
    self:SendLuaEvent(LuaEvent.JOpenFetchHero, ret)
  end
end

function JOpenService:FetchEquip(arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("jopen.FetchEquip", arg)
end

function JOpenService:OnFetchEquip(ret, state, err, errmsg)
  if err ~= 0 then
    logError("OnFetchEquip failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.JOpenFetchEquip)
  end
end

function JOpenService:GetJopen(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetStrategy failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, jopen_pb.TJOPEN)
    Data.jOpenData:SetData(info)
    self:SendLuaEvent(LuaEvent.GetJOpen)
  end
end

return JOpenService
