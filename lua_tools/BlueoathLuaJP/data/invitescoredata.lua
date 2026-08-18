local InviteScoreData = class("data.InviteScoreData", Data.BaseData)
InviteScoreSign = {notScore = 0, Scored = 1}
InviteScoreChooseType = {ClickNoMore = 1, ClickGo = 2}

function InviteScoreData:initialize()
  self:ResetData()
end

function InviteScoreData:ResetData()
  self.m_isScored = 0
  self.m_haveGotSSR = 0
  self.m_haveGotFaishon = 0
  self.m_haveFirstBattleWin = 0
  self.m_recordInviteScoreVersion = 0
end

function InviteScoreData:SetData(data)
  if data then
    self.m_haveGotSSR = data.haveGotSSR
    self.m_haveGotFaishon = data.haveGotFaishon
    self.m_haveFirstBattleWin = data.haveFirstBattleWin
    self.m_recordInviteScoreVersion = data.recordInviteScoreVersion
  end
  log("haveGotSSR:", self.m_haveGotSSR, "haveGotFaishon:", self.m_haveGotFaishon, "haveFirstBattleWin:", self.m_haveFirstBattleWin, "self.m_recordInviteScoreVersion", self.m_recordInviteScoreVersion)
end

function InviteScoreData:IsFirstSSR()
  return self.m_haveGotSSR == 0 and true or false
end

function InviteScoreData:IsFirstFaishon()
  return self.m_haveGotFaishon == 0 and true or false
end

function InviteScoreData:IsFirstBattleWin()
  return self.m_haveFirstBattleWin == 0 and true or false
end

function InviteScoreData:GetIsInviteScored()
  return self.m_isScored == 1 and true or false
end

function InviteScoreData:SetIsScored(scoreRate)
  self.m_isScored = scoreRate
end

function InviteScoreData:GetrecordInviteScoreVersion()
  return self.m_recordInviteScoreVersion or 0
end

return InviteScoreData
