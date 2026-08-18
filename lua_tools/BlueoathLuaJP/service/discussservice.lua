local DiscussService = class("servic.DiscussService", Service.BaseService)

function DiscussService:initialize()
  self:_InitHandlers()
end

function DiscussService:_InitHandlers()
  self:BindEvent("discuss.GetDiscuss", self._GetDiscussCallBack, self)
  self:BindEvent("discuss.Discuss", self._SendDiscussCallBack, self)
  self:BindEvent("discuss.HeroLike", self._GetHeroLikeNum, self)
end

function DiscussService:SendLikeHero(htid)
  local args = {Htid = htid}
  args = dataChangeManager:LuaToPb(args, discuss_pb.THEROLIKEARG)
  self:SendNetEvent("discuss.HeroLike", args)
end

function DiscussService:_GetHeroLikeNum(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get hero like num err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local likeNum = dataChangeManager:PbToLua(ret, discuss_pb.THEROLIKERET)
    Data.discussData:SetHeroLikeNum(likeNum.HeroLikeNum)
    self:SendLuaEvent("GetDiscussMsg")
  end
end

function DiscussService:SendGetDiscuss(htid)
  local args = {Htid = htid}
  args = dataChangeManager:LuaToPb(args, discuss_pb.TGETDISCUSSARG)
  self:SendNetEvent("discuss.GetDiscuss", args, htid)
end

function DiscussService:_GetDiscussCallBack(ret, state, err, errmsg)
  if err == 0 then
    if ret ~= nil then
      local discuss = dataChangeManager:PbToLua(ret, discuss_pb.TGETDISCUSSRET)
      Data.discussData:SetStartDiscussData(discuss)
      Data.discussData:SetCacheData(state, discuss)
      self:SendLuaEvent("GetDiscussMsg")
    end
  else
    logError(errmsg)
  end
end

function DiscussService:SendDiscuss(htid, msg)
  local args = {Htid = htid, Msg = msg}
  args = dataChangeManager:LuaToPb(args, discuss_pb.TDISCUSSARG)
  self:SendNetEvent("discuss.Discuss", args)
end

function DiscussService:_SendDiscussCallBack(ret, state, err, errmsg)
  local discuss = dataChangeManager:PbToLua(ret, discuss_pb.TDISCUSSRET)
  if discuss.FilterMsg == nil then
    Data.discussData:SetDiscussData(discuss)
    self:SendLuaEvent("DiscussMsg", discuss)
  else
    local maskWord = string.format(UIHelper.GetString(920000080), discuss.FilterMsg)
    eventManager:SendEvent("DiscussMaskWord", maskWord)
  end
end

function DiscussService:SendLike(htid, msgId)
  local args = {Htid = htid, MsgId = msgId}
  args = dataChangeManager:LuaToPb(args, discuss_pb.TDISCUSSLIKEARG)
  self:SendNetEvent("discuss.Like", args)
end

function DiscussService:SendDislike(htid, msgId)
  local args = {Htid = htid, MsgId = msgId}
  args = dataChangeManager:LuaToPb(args, discuss_pb.TDISCUSSLIKEARG)
  self:SendNetEvent("discuss.Dislike", args)
end

return DiscussService
