local BathroomService = class("servic.BathroomService", Service.BaseService)

function BathroomService:initialize()
  self:_InitHandlers()
end

function BathroomService:_InitHandlers()
  self:BindEvent("bathroom.BathStart", self._BathStartRet, self)
  self:BindEvent("bathroom.BathEnd", self._BathEndRet, self)
  self:BindEvent("bathroom.BathService", self._BathServiceRet, self)
  self:BindEvent("bathroom.BathAuto", self._BathAutoRet, self)
  self:BindEvent("bathroom.BathroomInfo", self._BathroomInfoRet, self)
  self:BindEvent("bathroom.GetBathroomInfo", self._GetBathroomInfoRet, self)
  self:BindEvent("bathroom.BathChangeHero", self._BathEndRet, self)
  self:BindEvent("bathroom.BathAllAuto", self._BathAllAutoRet, self)
  self:BindEvent("bathroom.BathStartAll", self._BathStartAllRet, self)
end

function BathroomService:SendBathStart(heroId, pos)
  local arg = {HeroId = heroId, Pos = pos}
  arg = dataChangeManager:LuaToPb(arg, bathroom_pb.TBATHSTARTARG)
  self:SendNetEvent("bathroom.BathStart", arg)
end

function BathroomService:SendBathEnd(heroId, heroInfo)
  local arg = {HeroId = heroId}
  arg = dataChangeManager:LuaToPb(arg, bathroom_pb.TBATHENDARG)
  local stage = {
    endType = BathEndType.Finish,
    hero = heroInfo
  }
  self:SendNetEvent("bathroom.BathEnd", arg, stage)
end

function BathroomService:SendBathService(heroId, giftId)
  local arg = {HeroId = heroId, GiftId = giftId}
  arg = dataChangeManager:LuaToPb(arg, bathroom_pb.TBATHSERVICEARG)
  self:SendNetEvent("bathroom.BathService", arg)
end

function BathroomService:SendBathAuto(heroId, status)
  local arg = {HeroId = heroId, Status = status}
  arg = dataChangeManager:LuaToPb(arg, bathroom_pb.TBATHAUTOARG)
  self:SendNetEvent("bathroom.BathAuto", arg)
end

function BathroomService:SendGetBathroomInfo()
  self:SendNetEvent("bathroom.GetBathroomInfo")
end

function BathroomService:SendBathReplace(oldHeroId, newHeroId, heroInfo)
  local arg = {HeroId = oldHeroId, NewHeroId = newHeroId}
  arg = dataChangeManager:LuaToPb(arg, bathroom_pb.TBATHCHANGEHEROARG)
  local stage = {
    endType = BathEndType.Replace,
    hero = heroInfo
  }
  self:SendNetEvent("bathroom.BathChangeHero", arg, stage)
end

function BathroomService:SendAllAuto(status)
  local arg = {Status = status}
  arg = dataChangeManager:LuaToPb(arg, bathroom_pb.TBATHALLAUTOARG)
  self:SendNetEvent("bathroom.BathAllAuto", arg)
end

function BathroomService:_BathStartRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("BathStart failed err:" .. err .. errmsg)
  end
end

function BathroomService:_BathEndRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("BathStart failed err:" .. err .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, bathroom_pb.TBATHENDRET)
    info.endType = state.endType
    info.heroInfo = state.hero
    self:SendLuaEvent(LuaEvent.BathEndOk, info)
  end
end

function BathroomService:_BathServiceRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("BathService failed err:" .. err .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, bathroom_pb.TBATHSERVICERET)
    self:SendLuaEvent(LuaEvent.BathGiftOk, info)
  end
end

function BathroomService:_BathAutoRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("BathStart failed err:" .. err .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.BathAutoTicket)
  end
end

function BathroomService:_BathroomInfoRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("BathStart failed err:" .. err .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, bathroom_pb.TBATHROOMINFO)
    Data.bathroomData:SetData(info)
    self:SendLuaEvent(LuaEvent.BathroomInfo)
    if Logic.loginLogic:GetLoginOK() == true then
      local noticeParam = Logic.bathroomLogic:GetPushNoticeParams(info.HeroList)
      self:SendLuaEvent(LuaEvent.PushNotice, noticeParam)
    end
  end
end

function BathroomService:_GetBathroomInfoRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("GetBathroomInfoRet failed err:" .. err .. errmsg)
  end
end

function BathroomService:_BathAllAutoRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("BathAllAutoRet failed err:" .. err .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.BathAllAuto)
  end
end

function BathroomService:SendBathStartAll(param)
  local arg = {BathStartArg = param}
  arg = dataChangeManager:LuaToPb(arg, bathroom_pb.TBATHSTARTALLARG)
  local state = param
  self:SendNetEvent("bathroom.BathStartAll", arg, state)
end

function BathroomService:_BathStartAllRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("BathStartAll failed err:" .. err .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, bathroom_pb.TBATHSTARTALLRET)
    self:SendLuaEvent(LuaEvent.BathStartAll, {
      EndHeroData = info.BathEndRet,
      AllHeroId = state
    })
  end
end

return BathroomService
