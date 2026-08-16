local PlayerHeadFrameService = class("servic.PlayerHeadFrameService", Service.BaseService)

function PlayerHeadFrameService:initialize()
  self:_InitHandlers()
end

function PlayerHeadFrameService:_InitHandlers()
  self:BindEvent("playerheadframe.RefreshPlayerHeadFrame", self._RefreshPlayerHeadFrame, self)
end

function PlayerHeadFrameService:_RefreshPlayerHeadFrame(ret, state, err, errmsg)
  if err ~= 0 then
    logError(" _Refresh PlayerHeadFrame  err : " .. errmsg)
    return
  end
  local info = dataChangeManager:PbToLua(ret, playerheadframe_pb.TPLAYERHEADFRAMERET)
  Data.playerHeadFrameData:SetData(info)
end

return PlayerHeadFrameService
