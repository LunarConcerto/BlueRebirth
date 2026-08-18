local BattleAutoChatLogic = class("logic.BattleAutoChatLogic")

function BattleAutoChatLogic:initialize()
  self:ResetData()
end

function BattleAutoChatLogic:ResetData()
end

function BattleAutoChatLogic:IsCanSend()
  local lastSendTime = Data.battleAutoChatData:GetSendMsgTime()
  local currentTime = time.getSvrTime()
  local _, cdTime = Data.battleAutoChatData:GetSendChatCDTime()
  return currentTime >= _ + lastSendTime, _ + lastSendTime
end

return BattleAutoChatLogic
