local RankLogic = class("logic.RankLogic")

function RankLogic:initialize()
end

function RankLogic:IsOpenById(rankId, isShowTip)
  local rankConfig = configManager.GetDataById("config_rank", rankId)
  local periodId = rankConfig.period
  local conditionPeriod = true
  if 0 < periodId then
    conditionPeriod = PeriodManager:IsInPeriodArea(periodId, rankConfig.period_area)
  end
  if not conditionPeriod and isShowTip then
    noticeManager:ShowTipById(270022)
  end
  return conditionPeriod
end

return RankLogic
