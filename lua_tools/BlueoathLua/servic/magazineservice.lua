local MagazineService = class("servic.MagazineService", Service.BaseService)

function MagazineService:initialize()
  self:_InitHandlers()
end

function MagazineService:_InitHandlers()
  self:BindEvent("magazine.GetMagazine", self._GetMagazine, self)
  self:BindEvent("magazine.UpdateMagazineInfo", self._UpdateMagazineInfo, self)
  self:BindEvent("magazine.AddHero", self._GetAddHero, self)
  self:BindEvent("magazine.Vote", self._Vote, self)
  self:BindEvent("magazine.FetchMagazineReward", self._SendFetchReward, self)
  self:BindEvent("magazine.UnLock", self._SendUnLock, self)
end

function MagazineService:_GetMagazine(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetMagazine failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, magazine_pb.TMAGAZINE)
    Data.magazineData:SetRewardData(info)
    self:SendLuaEvent(LuaEvent.GetMagazineMsg)
  end
end

function MagazineService:_UpdateMagazineInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetMagazine failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, magazine_pb.TRETMAGAZINEINFO)
    Data.magazineData:SetData(info)
    self:SendLuaEvent(LuaEvent.GetMagazineMsg)
  end
end

function MagazineService:SendMagazineAddHero(args)
  args = dataChangeManager:LuaToPb(args, magazine_pb.TMAGAZINEADDHERO)
  self:SendNetEvent("magazine.AddHero", args)
end

function MagazineService:_GetAddHero(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetAddHero failed " .. errmsg)
  end
end

function MagazineService:_Vote(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Vote failed " .. errmsg)
  else
    noticeManager:ShowTipById(4000018)
  end
end

function MagazineService:SendMagazineVote(args)
  args = dataChangeManager:LuaToPb(args, vote_pb.TVOTE)
  self:SendNetEvent("magazine.Vote", args)
end

function MagazineService:SendFetchReward(args)
  args = dataChangeManager:LuaToPb(args, magazine_pb.TMAGAZINEARG)
  self:SendNetEvent("magazine.FetchMagazineReward", args, args)
end

function MagazineService:_SendFetchReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_SendFetchReward failed " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.GetMagazineFetchReward, state)
  end
end

function MagazineService:SendUnLock(args)
  args = dataChangeManager:LuaToPb(args, magazine_pb.TMAGAZINEUNLOCK)
  self:SendNetEvent("magazine.UnLock", args, args)
end

function MagazineService:_SendUnLock(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_SendUnLock failed " .. errmsg)
  else
    noticeManager:ShowTipById(4000035)
  end
end

function MagazineService:SendGetMagazine(args)
  args = dataChangeManager:LuaToPb(args, magazine_pb.TMAGAZINEUNLOCK)
  self:SendNetEvent("magazine.Magazine", args)
end

return MagazineService
