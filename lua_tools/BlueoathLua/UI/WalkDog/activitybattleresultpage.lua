local ActivityBattleResultPage = class("UI.WalkDog.ActivityBattleResultPage", LuaUIPage)

function ActivityBattleResultPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_skip, self._OnBtnSkip, self)
end

function ActivityBattleResultPage:DoOnOpen()
  local param = self.param
  local result = {}
  for k, v in pairs(param.result) do
    result[v.Key] = v.Value
  end
  local liveTime = result.LiveTime
  local maxLiveTime = result.MaxLiveTime
  local score = result.TotalScore
  local extraScore = result.ExtraScore
  UIHelper.SetText(self.tab_Widgets.txt_livetime, liveTime)
  UIHelper.SetText(self.tab_Widgets.txt_maxtime, maxLiveTime)
  UIHelper.SetText(self.tab_Widgets.txt_score, score)
  UIHelper.SetText(self.tab_Widgets.txt_extrascore, extraScore)
  local randomTips = configManager.GetDataById("config_parameter", 279).arrValue
  local count = #randomTips
  local index = math.random(count)
  if index < 1 or count < index then
    index = 1
  end
  local tipId = randomTips[index]
  UIHelper.SetText(self.tab_Widgets.txt_tips, UIHelper.GetString(tipId))
end

function ActivityBattleResultPage:_OnBtnSkip()
  UIHelper.ClosePage(self:GetName())
  local callback = self.param.callback
  callback()
end

return ActivityBattleResultPage
