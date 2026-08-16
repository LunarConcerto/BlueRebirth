local SearchGoodsService = class("servic.SearchGoodsService", Service.BaseService)

function SearchGoodsService:initialize()
  self:_InitHandlers()
end

function SearchGoodsService:_InitHandlers()
  self:BindEvent("searchgoods.UpdateSearchGoodsData", self._UpdateSearchGoodsInfo, self)
  self:BindEvent("searchgoods.FindGoods", self._FindItemRet, self)
  self:BindEvent("searchgoods.SendRefresh", self._SendRefreshRet, self)
end

function SearchGoodsService:FindItem(arg, state)
  arg = dataChangeManager:LuaToPb(arg, searchgoods_pb.TSEARCHGOODSARG)
  self:SendNetEvent("searchgoods.FindGoods", arg, state)
end

function SearchGoodsService:_FindItemRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("SearchGoodsService _MakeCake failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.UpdateSearchGoodsInfo, state)
  end
end

function SearchGoodsService:SendRefresh(arg, state)
  self:SendNetEvent("searchgoods.SendRefresh")
end

function SearchGoodsService:_SendRefreshRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_SendRefreshRet _MakeCake failed " .. errmsg)
  else
  end
end

function SearchGoodsService:_UpdateSearchGoodsInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError(" _UpdateSearchGoodsInfo failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, searchgoods_pb.TSEARCHGOODSINFO)
    Data.searchGoodsData:SetData(info)
    self:SendLuaEvent(LuaEvent.UpdateSearchGoodsInfo)
  end
end

return SearchGoodsService
