local BattleAutoChatService = class("service.BattleAutoChatService", Service.BaseService)

function BattleAutoChatService:initialize()
  self:_InitHandlers()
end

function BattleAutoChatService:_InitHandlers()
  self:BindEvent("battle.receiveAutoMsg", self._ReceiveMatchChatMsg, self)
  self:BindEvent("battle.SendAutoMsg", self._ReceiveMatchSendChatMsg, self)
end

function BattleAutoChatService:SendMatchChatMsg(msgId, matchType)
  matchType = matchType or 0
  local info = {MsgId = msgId, MatchType = matchType}
  arg = dataChangeManager:LuaToPb(info, battle_pb.TBATTLEAUTOMSGARG)
  self:SendNetEvent("battle.SendAutoMsg", arg)
end

function BattleAutoChatService:_ReceiveMatchChatMsg(ret, state, err, errmsg)
  if err == 0 then
    local chatMsg = dataChangeManager:PbToLua(ret, battle_pb.TBATTLERECEIVEAUTOMSG)
    self:SendLuaEvent("matchChatMsg", chatMsg)
  else
  end
end

function BattleAutoChatService:_ReceiveMatchSendChatMsg(ret, state, err, errmsg)
  if err == 0 then
  end
end

return BattleAutoChatService
