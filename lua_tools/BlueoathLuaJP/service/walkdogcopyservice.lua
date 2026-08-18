local WalkDogCopyService = class("servic.WalkDogCopyService", Service.BaseService)

function WalkDogCopyService:initialize()
  self:BindEvent("walkdogcopy.UpdateData", self._UpdateData, self)
end

function WalkDogCopyService:_UpdateData(ret, state, err, errmsg)
  if err ~= 0 then
    logError("WalkDogCopyService _UpdateData error " .. errmsg)
    return
  end
  local copyInfo = dataChangeManager:PbToLua(ret, walkdogcopy_pb.TGETWALKDOGCOPYINFO)
  Data.walkDogCopyData:SetData(copyInfo)
end

return WalkDogCopyService
