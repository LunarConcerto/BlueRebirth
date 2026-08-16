local ActivityBirthdayLogic = class("logic.ActivityBirthdayLogic")

function ActivityBirthdayLogic:initialize()
  self:ResetData()
end

function ActivityBirthdayLogic:ResetData()
  self.mActivityId = 103
  self.noOpenPage = true
end

function ActivityBirthdayLogic:SetBirthdayCakeDot(_bool)
  self.noOpenPage = _bool
end

function ActivityBirthdayLogic:GetMakeReward(state)
  local formulaId = state.CakeFormula
  local config = configManager.GetDataById("config_activity", self.mActivityId).p4
  for i, v in pairs(config) do
    if i == formulaId then
      local res = {}
      local temp = {}
      temp.Type = GoodsType.ITEM
      temp.ConfigId = v[3]
      temp.Num = 1
      table.insert(res, temp)
      UIHelper.OpenPage("GetRewardsPage", {Rewards = res})
    end
  end
end

function ActivityBirthdayLogic:GetFeedReward(state)
  local tcake = state.trueCake
  local cake = state.Cake
  if cake == tcake then
  else
  end
end

function ActivityBirthdayLogic:GetAffairReward(state)
  local stage = state.Level
  local config = configManager.GetDataById("config_activity", self.mActivityId).p5
  for i, v in pairs(config) do
    if v[1] == stage then
      UIHelper.OpenPage("GetRewardsPage", {
        Rewards = Logic.rewardLogic:FormatRewardById(v[2])
      })
    end
  end
end

function ActivityBirthdayLogic:_ShowReward(rewardID)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = Logic.rewardLogic:FormatRewardById(rewardID)
  })
end

function ActivityBirthdayLogic:IsCanShowRedDot(...)
  local firstLoginToday = Data.userData:IsFirstLoginToday()
  return self.noOpenPage and firstLoginToday
end

return ActivityBirthdayLogic
