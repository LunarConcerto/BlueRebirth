local TrainStarPage = class("UI.Train.TrainStarPage", LuaUIPage)

function TrainStarPage:DoInit()
end

function TrainStarPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_skip, self._OnSkip, self)
end

function TrainStarPage:DoOnOpen()
  UIHelper.ClosePage("BattlePage")
  local copyId = self.param.copyId
  local starLevel = self.param.starLevel
  local evaluate = self.param.evaluate
  local battleCostTime = 0
  local searchRemainTime = 0
  local battleRemainTime = 0
  for k, pair in pairs(evaluate) do
    if pair.Value then
      if pair.Type == Evaluate.BATTLE_BOSS_TIME then
        battleCostTime = math.round(pair.Value / 1000)
      end
      if pair.Type == Evaluate.BATTLE_REST_TIME then
        battleRemainTime = math.ceil(pair.Value / 1000)
      end
      if pair.Type == Evaluate.BATTLE_RUN_TIME then
        searchRemainTime = math.ceil(pair.Value / 1000)
      end
    end
  end
  local starCount = 0
  if starLevel & 7 == 7 then
    starCount = 3
  elseif starLevel & 3 == 3 then
    starCount = 2
  elseif starLevel & 1 == 1 then
    starCount = 1
  end
  local copyRec = configManager.GetDataById("config_copy_display", copyId)
  for i = 1, 3 do
    self.tab_Widgets["star" .. i]:SetActive(i <= starCount)
  end
  local evaluateRec
  local evaIds = copyRec.star_require
  for i = 1, 3 do
    evaluateRec = configManager.GetDataById("config_evaluate", evaIds[i])
    UIHelper.SetText(self.tab_Widgets["condition" .. i], evaluateRec.description)
    local complete = starCount >= i
    for k = 1, i do
      self.tab_Widgets["star" .. i .. k]:SetActive(complete)
    end
    if i == 3 and evaluateRec then
      if evaluateRec.require_condition == 1 then
        UIHelper.SetText(self.tab_Widgets.time_condition, UIHelper.GetString(1000017))
        UIHelper.SetText(self.tab_Widgets.time_cost, string.format("%ss", battleCostTime))
      elseif evaluateRec.require_condition == 6 then
        UIHelper.SetText(self.tab_Widgets.time_condition, UIHelper.GetString(1000018))
        UIHelper.SetText(self.tab_Widgets.time_cost, string.format("%ss", battleRemainTime))
      elseif evaluateRec.require_condition == 9 then
        UIHelper.SetText(self.tab_Widgets.time_condition, UIHelper.GetString(1000019))
        UIHelper.SetText(self.tab_Widgets.time_cost, string.format("%ss", searchRemainTime))
      else
        UIHelper.SetText(self.tab_Widgets.time_condition, UIHelper.GetString(1000017))
        UIHelper.SetText(self.tab_Widgets.time_cost, string.format("%ss", battleCostTime))
      end
    end
  end
end

function TrainStarPage:_OnSkip()
  UIHelper.ClosePage(self:GetName())
  local callback = self.param.callback
  callback()
end

function TrainStarPage:DoOnHide()
end

function TrainStarPage:DoOnClose()
end

return TrainStarPage
