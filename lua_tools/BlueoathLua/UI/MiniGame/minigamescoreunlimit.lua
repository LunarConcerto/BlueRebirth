local MiniGameScoreUnLimit = class("UI.MiniGame.MiniGameScoreUnLimit")

function MiniGameScoreUnLimit:DoOnOpenCustom(page)
  local widgets = page:GetWidgets()
  widgets.tx_score_total.gameObject:SetActive(true)
  widgets.tx_score_history.gameObject:SetActive(true)
  widgets.obj_total:SetActive(true)
  widgets.obj_history:SetActive(true)
  local params = page:GetParam()
  local isSuccess = params.isSuccess
  local chapterId = params.chapterId
  local gameId = params.gameId
  UIHelper.SetText(widgets.tx_score_total, string.format("%011d", Logic2d:GetScoreSum()))
  local score_history = Data.miniGameData:GetScore(chapterId)
  UIHelper.SetText(widgets.tx_score_history, string.format("%011d", score_history))
  local config = configManager.GetDataById("config_minigame_copy", gameId)
  widgets.btn_next.gameObject:SetActive(isSuccess and config.next_copy > 0)
  widgets.im_victory:SetActive(isSuccess and config.next_copy <= 0)
  local attackedCount = GameManager2d:GetAttackedCount()
  local skillCount = SkillManager2d:GetSkillCount()
  local timeCount = GameManager2d:GetTime()
  local itemTemplateMap = ItemManager2d:GetItemTemplateMap()
  local itemCommonPickMap = GameManager2d:GetPickCommonItemMap()
  local tbl = Logic2d:GetScoreTbl()
  Service.userService:SetMiniGameScore({
    ChapterId = chapterId,
    Score = tbl,
    IsPassAll = isSuccess,
    IsNoHurt = attackedCount <= 0,
    IsNoSkill = skillCount <= 0,
    TimeCount = timeCount,
    ItemTemplate = itemTemplateMap,
    ItemCommonPick = itemCommonPickMap
  })
end

function MiniGameScoreUnLimit:btn_stop(page)
  UIHelper.ClosePage("MiniGameScorePage")
  eventManager:SendEvent(LuaEvent.Stop2d)
end

return MiniGameScoreUnLimit
