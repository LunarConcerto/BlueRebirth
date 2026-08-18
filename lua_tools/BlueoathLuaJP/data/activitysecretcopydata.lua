local ActivitysecretcopyData = class("data.ActivitysecretcopyData")

function ActivitysecretcopyData:initialize()
  self.mInfo = {}
  self.mInfo.GetRewardInfo = {}
end

function ActivitysecretcopyData:UpdateData(TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  if TRet.PassTimePerfect ~= nil then
    self.mInfo.PassTimePerfect = TRet.PassTimePerfect
  end
  if TRet.GetRewardInfo ~= nil and #TRet.GetRewardInfo > 0 then
    for _, info in ipairs(TRet.GetRewardInfo) do
      if info.RateIndex == nil or 0 >= info.RateIndex then
        self.mInfo.GetRewardInfo = {}
      else
        self.mInfo.GetRewardInfo[info.RateIndex] = info
      end
    end
  end
end

function ActivitysecretcopyData:GetPassTimePerfect()
  return self.mInfo.PassTimePerfect or 0
end

function ActivitysecretcopyData:IsGetRewardByRate(rateIndex)
  local info = self.mInfo.GetRewardInfo[rateIndex] or {}
  local get = info.GetReward or 0
  return 0 < get
end

return ActivitysecretcopyData
