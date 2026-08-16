local GoodsCopyService = class("servic.GoodsCopyService", Service.BaseService)

function GoodsCopyService:initialize()
  self:BindEvent("goodscopy.UpdateData", self._UpdateData, self)
end

function GoodsCopyService:_UpdateData(ret, state, err, errmsg)
  if err ~= 0 then
    logError("GoodsCopyService _UpdateData error " .. errmsg)
    return
  end
  local GetInfo = dataChangeManager:PbToLua(ret, goodscopy_pb.TGETGOODSCOPYINFO)
  Data.goodsCopyData:SetData(GetInfo.InfoList)
  self:SendLuaEvent(LuaEvent.GoodsCopyBattle)
end

return GoodsCopyService
