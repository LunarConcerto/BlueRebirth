local MiniGameService = class("service.MiniGameService", Service.BaseService)
local Socket_net = require("socket_net")

function MiniGameService:initialize()
  self:_InitHandlers()
end

function MiniGameService:_InitHandlers()
  self:BindEvent("miniGame.StartMiniGame", self._StartMiniGame, self)
end

function MiniGameService:StartMiniGame(arg)
  arg = dataChangeManager:LuaToPb(arg, minigame_pb.TMINIGAME)
  self:SendNetEvent("miniGame.StartMiniGame", arg)
end

function MiniGameService:_StartMiniGame(ret, state, err, errmsg)
  if err == 0 then
  else
    logError("_StartMiniGame err" .. err)
  end
end

return MiniGameService
