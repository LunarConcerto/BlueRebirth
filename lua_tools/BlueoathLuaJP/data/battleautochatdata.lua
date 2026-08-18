local BattleAutoChatData = class("data.BattleAutoChatData", Data.BaseData)

function BattleAutoChatData:initialize()
  self:ResetData()
end

function BattleAutoChatData:ResetData()
  self.lastTime = 0
  self.allMatchUids = {}
  self.userOrder = {}
  self.matchUserData = {}
end

function BattleAutoChatData:GetSendChatCDTime()
  local cdTime = configManager.GetDataById("config_parameter", 435).value
  return cdTime, cdTime * 1000
end

function BattleAutoChatData:RecordSendMsgTime()
  self.lastTime = time.getSvrTime()
end

function BattleAutoChatData:GetSendMsgTime()
  return self.lastTime or 0
end

function BattleAutoChatData:SetMatchUserInfoData(uid, data)
  self.matchUserData[uid] = data
end

function BattleAutoChatData:GetMatchUserInfoData()
  return self.matchUserData
end

function BattleAutoChatData:GetAllMatchPlayerUID()
  local matchPlayerData = Data.copyData:GetMatchPlayerTempData()
  if matchPlayerData ~= nil and 1 < #matchPlayerData then
    for i = 1, #matchPlayerData do
      if matchPlayerData[i].Uid ~= nil then
        table.insert(self.allMatchUids, matchPlayerData[i].Uid)
        self.userOrder[matchPlayerData[i].Uid] = i
      end
    end
  end
  return self.allMatchUids
end

function BattleAutoChatData:GetMatchUserOrder(uid)
  if self.userOrder == nil or #self.userOrder < 1 then
    self:GetAllMatchPlayerUID()
  end
  return self.userOrder[uid]
end

return BattleAutoChatData
