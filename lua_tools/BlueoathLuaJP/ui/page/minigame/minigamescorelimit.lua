local MiniGameScoreLimit = class("UI.MiniGame.MiniGameScoreLimit")

function MiniGameScoreLimit:DoOnOpenCustom(page)
  local params = page:GetParam()
  local isSuccess = params.isSuccess
  local copyId = params.copyId
  local battleMode = params.battleMode
  local firstPass = params.firstPass
  local widgets = page:GetWidgets()
  widgets.btn_next.gameObject:SetActive(false)
  if isSuccess and firstPass and battleMode == BattleMode.Normal then
    local copyDisplay = configManager.GetDataById("config_copy_display", copyId)
    UIHelper.OpenPage("GetRewardsPage", {
      Rewards = Logic.rewardLogic:FormatRewardById(copyDisplay.first_reward[1])
    })
  end
end

function MiniGameScoreLimit:btn_stop(page)
  UIHelper.ClosePage("MiniGameScorePage")
  eventManager:SendEvent(LuaEvent.Stop2d)
end

return MiniGameScoreLimit
